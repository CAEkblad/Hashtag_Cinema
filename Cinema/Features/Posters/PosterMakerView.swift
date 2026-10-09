import SwiftUI
import PhotosUI
import UIKit

/// Just Listed, Just Sold, Coming Soon, Open House, Under Contract and Price
/// Improved posters from listing photos. Fills in the agent, writes the caption
/// and shares in one tap.
struct PosterMakerView: View {
    @Environment(CinemaStore.self) private var store
    var prefill: OfficeAsset? = nil

    @State private var details = PosterDetails()
    @State private var style: PosterStyle = .classic
    @State private var size: PosterSize = .post
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var photos: [UIImage] = []
    @State private var isLoadingPhotos = false
    @State private var share: ShareBundle?
    @State private var didPrefill = false

    struct ShareBundle: Identifiable {
        let id = UUID()
        let image: UIImage
        let caption: String
    }

    private var caption: String { details.caption(cityName: store.homeCity.name) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                preview
                kindPicker
                photoPicker
                stylePicker
                listingFields
                agentFields
                captionCard
                Button {
                    makeShare()
                } label: {
                    Label("Share poster", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(PrimaryButtonStyle())
                Text(store.profile.sharesWithOffice ? "Shared posters are also added to your \(store.officeWord)'s content pool." : "Office sharing is off. Turn it on in Me > \(store.officeWord.capitalized).")
                    .font(.cinema(12))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Poster maker")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .onAppear(perform: fillDefaults)
        .onChange(of: pickerItems) { _, items in
            Task { await loadPhotos(items) }
        }
        .sheet(item: $share) { bundle in
            ActivityView(items: [bundle.image, bundle.caption])
                .presentationDetents([.medium, .large])
        }
    }

    // MARK: Preview

    private var preview: some View {
        let previewWidth: CGFloat = size == .story ? 220 : 300
        return HStack {
            Spacer()
            PosterCanvas(details: details, photos: photos, style: style, size: size)
                .scaleEffect(previewWidth / PosterCanvas.baseWidth, anchor: .topLeading)
                .frame(width: previewWidth, height: previewWidth * size.ratio, alignment: .topLeading)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: .black.opacity(0.15), radius: 14, y: 6)
                .overlay {
                    if isLoadingPhotos {
                        ProgressView().tint(Theme.red)
                    }
                }
            Spacer()
        }
        .animation(.easeInOut(duration: 0.2), value: size)
    }

    // MARK: Controls

    private var kindPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(PosterKind.allCases) { kind in
                    Button {
                        details.kind = kind
                    } label: {
                        Label(kind.shortTitle, systemImage: kind.icon)
                            .font(.cinema(13, weight: .semibold))
                            .foregroundStyle(details.kind == kind ? Color.white : Theme.textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(details.kind == kind ? Theme.red : Theme.surface, in: Capsule())
                            .overlay(Capsule().stroke(Theme.stroke, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var photoPicker: some View {
        PhotosPicker(selection: $pickerItems, maxSelectionCount: 4, matching: .images) {
            HStack(spacing: 12) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.red)
                VStack(alignment: .leading, spacing: 2) {
                    Text(photos.isEmpty ? "Add listing photos" : "\(photos.count) photo\(photos.count == 1 ? "" : "s") added")
                        .font(.cinema(15, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Up to 4. The first one is the hero shot.")
                        .font(.cinema(12))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
            }
            .cardStyle(padding: 14)
        }
        .buttonStyle(.plain)
    }

    private var stylePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("Style", selection: $style) {
                ForEach(PosterStyle.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            Picker("Size", selection: $size) {
                ForEach(PosterSize.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
        }
    }

    private var listingFields: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Listing")
            TextField("Street address", text: $details.address)
                .textContentType(.fullStreetAddress)
                .inputStyle()
            TextField("City, state", text: $details.cityLine)
                .inputStyle()
            if details.kind != .underContract {
                TextField("Price", text: $details.price)
                    .keyboardType(.numberPad)
                    .inputStyle()
            }
            HStack(spacing: 10) {
                Stepper("\(details.beds) bed", value: $details.beds, in: 0...12)
                    .font(.cinema(15, weight: .medium))
                    .cardStyle(padding: 12)
                Stepper("\(details.bathsLabel) bath", value: $details.baths, in: 0...12, step: 0.5)
                    .font(.cinema(15, weight: .medium))
                    .cardStyle(padding: 12)
            }
            TextField("Square feet (optional)", text: $details.squareFeet)
                .keyboardType(.numberPad)
                .inputStyle()
            if details.kind == .openHouse {
                DatePicker("Open house", selection: $details.openHouseDate)
                    .font(.cinema(15, weight: .medium))
                    .cardStyle(padding: 12)
            }
        }
    }

    private var agentFields: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "You")
            TextField("Your name", text: $details.agentName)
                .inputStyle()
            TextField("Phone (optional)", text: $details.agentPhone)
                .keyboardType(.phonePad)
                .inputStyle()
            TextField("Brokerage", text: $details.brokerage)
                .inputStyle()
        }
    }

    private var captionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionHeader(title: "Caption")
                Button {
                    UIPasteboard.general.string = caption
                    store.showToast("Caption copied")
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.cinema(14, weight: .semibold))
                }
                .foregroundStyle(Theme.red)
            }
            Text(caption)
                .font(.cinema(14))
                .foregroundStyle(Theme.textSecondary)
                .textSelection(.enabled)
                .cardStyle()
            Text("The comment keyword \(details.kind.keyword) turns comments into leads when you post through #Cinema.")
                .font(.cinema(12))
                .foregroundStyle(Theme.textTertiary)
        }
    }

    // MARK: Actions

    private func fillDefaults() {
        guard !didPrefill else { return }
        didPrefill = true
        details.agentName = store.profile.name
        details.brokerage = store.myMarketCenter?.name ?? store.profile.brokerage
        details.cityLine = store.homeCity.displayName
        if let prefill {
            details.address = prefill.listingAddress ?? ""
            if let status = prefill.status?.lowercased(),
               let kind = PosterKind.allCases.first(where: { $0.shortTitle.lowercased() == status }) {
                details.kind = kind
            }
            if prefill.agentName != store.profile.name {
                details.agentName = prefill.agentName
            }
            if let data = prefill.imageData, let image = UIImage(data: data) {
                photos = [image]
            }
        }
    }

    private func loadPhotos(_ items: [PhotosPickerItem]) async {
        isLoadingPhotos = true
        var loaded: [UIImage] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                loaded.append(image.downscaled(maxSide: 1800))
            }
        }
        photos = loaded
        isLoadingPhotos = false
    }

    @MainActor
    private func makeShare() {
        let canvas = PosterCanvas(details: details, photos: photos, style: style, size: size)
        let renderer = ImageRenderer(content: canvas)
        renderer.scale = 3
        guard let image = renderer.uiImage else {
            store.showToast("Could not make the poster. Try again.")
            return
        }
        store.savePoster(PosterItem(
            kind: details.kind,
            address: details.address,
            caption: caption,
            createdAt: Date(),
            imageData: image.jpegData(compressionQuality: 0.85)
        ))
        share = ShareBundle(image: image, caption: caption)
    }
}

/// System share sheet: Instagram, Messages, AirDrop, Save Image and more.
struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

extension UIImage {
    /// Keeps big camera photos from using too much memory while designing.
    func downscaled(maxSide: CGFloat) -> UIImage {
        let longest = max(size.width, size.height)
        guard longest > maxSide else { return self }
        let scale = maxSide / longest
        let target = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: target))
        }
    }
}
