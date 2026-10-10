import SwiftUI
import PhotosUI
import UIKit

/// Snap a business card or a filled in sign in sheet and turn it into leads.
struct ScanLeadsView: View {
    @Environment(CinemaStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var mode: CardScanner.Mode = .card
    @State private var pickerItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var image: UIImage?
    @State private var contacts: [CardScanner.Contact] = []
    @State private var isReading = false
    @State private var message: String?
    @State private var addToPlan = true

    private var chosen: [CardScanner.Contact] { contacts.filter(\.include) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Scan to leads")
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Take a photo of a business card or a filled in paper sign in sheet. CloseUp reads the names, phones and emails on your phone and adds them to Leads.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                Picker("What are you scanning", selection: $mode) {
                    ForEach(CardScanner.Mode.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .onChange(of: mode) { _, _ in
                    if let image { Task { await read(image) } }
                }

                HStack(spacing: 10) {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        Button { showCamera = true } label: {
                            Label("Take photo", systemImage: "camera.fill")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        Label("From Photos", systemImage: "photo.fill")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }

                #if DEBUG
                Button("Try a sample \(mode == .card ? "card" : "sheet")") {
                    let sample = ScanSamples.image(for: mode)
                    image = sample
                    Task { await read(sample) }
                }
                .font(.cinema(13, weight: .semibold))
                .tint(Theme.red)
                #endif

                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 220)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                if isReading {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Reading...")
                            .font(.cinema(14))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }

                if let message {
                    Text(message)
                        .font(.cinema(13))
                        .foregroundStyle(Theme.textSecondary)
                }

                if !contacts.isEmpty {
                    SectionHeader(title: "Found \(contacts.count)")
                    ForEach(contacts) { item in
                        let contact = binding(for: item)
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle(isOn: contact.include) {
                                Text(item.name.isEmpty ? "No name found" : item.name)
                                    .font(.cinema(15, weight: .semibold))
                            }
                            .tint(Theme.red)
                            TextField("Name", text: contact.name)
                                .textInputAutocapitalization(.words)
                                .inputStyle()
                            TextField("Phone", text: contact.phone)
                                .keyboardType(.phonePad)
                                .inputStyle()
                            TextField("Email", text: contact.email)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .inputStyle()
                            if !item.company.isEmpty {
                                Text(item.company)
                                    .font(.cinema(12))
                                    .foregroundStyle(Theme.textTertiary)
                            }
                        }
                        .cardStyle()
                    }

                    Toggle(isOn: $addToPlan) {
                        Text("Also start their \(TouchContact.Plan.eightWeek.title(store.lex))")
                            .font(.cinema(14, weight: .semibold))
                    }
                    .tint(Theme.red)

                    Button {
                        let added = store.saveScannedLeads(chosen, source: mode == .card ? "Business card" : "Sign in sheet", startPlan: addToPlan)
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        let skipped = chosen.count - added
                        message = added == 0 ? "They're already in your Leads." : "Added \(added) to Leads." + (skipped > 0 ? " \(skipped) were already there." : "")
                        withAnimation {
                            contacts = []
                            image = nil
                        }
                    } label: {
                        Label("Add \(chosen.count) to Leads", systemImage: "person.badge.plus")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(chosen.isEmpty)
                }

                Text("Photos are read on your phone and never uploaded. Check each one before adding. Handwriting works best when it's printed clearly.")
                    .font(.cinema(12))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Scan to leads")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self), let picked = UIImage(data: data) {
                    let scaled = picked.downscaled(maxSide: 2400)
                    image = scaled
                    await read(scaled)
                }
                pickerItem = nil
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraCapture { captured in
                showCamera = false
                if let captured {
                    let scaled = captured.downscaled(maxSide: 2400)
                    image = scaled
                    Task { await read(scaled) }
                }
            }
            .ignoresSafeArea()
        }
    }

    /// A binding by id, so clearing the list never leaves a field pointing past the end.
    private func binding(for item: CardScanner.Contact) -> Binding<CardScanner.Contact> {
        Binding(
            get: { contacts.first { $0.id == item.id } ?? item },
            set: { value in
                if let index = contacts.firstIndex(where: { $0.id == item.id }) { contacts[index] = value }
            }
        )
    }

    private func read(_ image: UIImage) async {
        isReading = true
        message = nil
        defer { isReading = false }
        do {
            let lines = try await CardScanner.recognize(image)
            contacts = mode == .card ? CardScanner.parseCard(lines) : CardScanner.parseSheet(lines)
            if contacts.isEmpty {
                message = lines.isEmpty ? "Couldn't find any text. Try a closer, brighter photo." : "Found text but no phone or email. Try the other mode, or a closer photo."
            }
        } catch {
            message = "Couldn't read that photo. Try again."
        }
    }
}

/// The system camera, for one photo.
struct CameraCapture: UIViewControllerRepresentable {
    var onDone: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ controller: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onDone: onDone) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onDone: (UIImage?) -> Void
        init(onDone: @escaping (UIImage?) -> Void) { self.onDone = onDone }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            onDone(info[.originalImage] as? UIImage)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onDone(nil)
        }
    }
}

#if DEBUG
/// Rendered test images so the scanner can be tried in the simulator.
enum ScanSamples {
    static func image(for mode: CardScanner.Mode) -> UIImage {
        let size = mode == .card ? CGSize(width: 1050, height: 600) : CGSize(width: 1275, height: 900)
        return UIGraphicsImageRenderer(size: size).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            func draw(_ text: String, _ x: CGFloat, _ y: CGFloat, _ font: CGFloat, bold: Bool = false) {
                (text as NSString).draw(at: CGPoint(x: x, y: y), withAttributes: [.font: UIFont.systemFont(ofSize: font, weight: bold ? .bold : .regular), .foregroundColor: UIColor.black])
            }
            if mode == .card {
                draw("Maria Delgado", 70, 90, 64, bold: true)
                draw("Realtor Associate", 70, 175, 34)
                draw("Bayside Realty Group", 70, 230, 34)
                draw("(813) 555-0142", 70, 360, 38)
                draw("maria@baysiderealty.com", 70, 420, 38)
                draw("baysiderealty.com", 70, 480, 30)
            } else {
                draw("Name", 60, 60, 30, bold: true)
                draw("Phone", 470, 60, 30, bold: true)
                draw("Email", 800, 60, 30, bold: true)
                let rows = [("Chris Patel", "813-555-0198", "chris.patel@gmail.com"), ("Dana Brooks", "727-555-0110", "dana.b@outlook.com"), ("Sam Lee", "(941) 555-0177", "samlee@yahoo.com")]
                for (index, row) in rows.enumerated() {
                    let y = CGFloat(160 + index * 120)
                    draw(row.0, 60, y, 36)
                    draw(row.1, 470, y, 36)
                    draw(row.2, 800, y, 32)
                }
            }
        }
    }
}
#endif
