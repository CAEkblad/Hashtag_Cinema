import SwiftUI

/// The agent's go-to lenders, inspectors and other pros, ready to send to a client.
struct VendorsView: View {
    @Environment(CinemaStore.self) private var store
    @State private var showAdd = false

    private var categories: [Vendor.Category] {
        Vendor.Category.allCases.filter { category in store.vendors.contains { $0.category == category } }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Trusted pros")
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Clients ask you for everyone, from lenders to pool guys. Keep your go-to list here and send it in one tap.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                ShareLink(item: store.vendorListMessage()) {
                    Label("Send my list to a client", systemImage: "paperplane.fill")
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(store.vendors.isEmpty)

                NavigationLink(value: Route.findShooter) {
                    IconRow(icon: "camera.fill", title: "Need photos or video?", subtitle: "Book a vetted #Cinema Crew photographer")
                        .cardStyle()
                }
                .buttonStyle(.plain)

                ForEach(categories) { category in
                    VStack(alignment: .leading, spacing: 10) {
                        Label(category.title, systemImage: category.icon)
                            .font(.cinema(16, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                        ForEach(store.vendors.filter { $0.category == category }) { vendor in
                            vendorRow(vendor)
                        }
                    }
                    .cardStyle()
                }

                Button {
                    showAdd = true
                } label: {
                    Label("Add a pro", systemImage: "plus")
                }
                .buttonStyle(SecondaryButtonStyle())

                Text("Recommend people you trust. RESPA rules mean you can't take fees or gifts for referring settlement services like lenders and title companies.")
                    .font(.cinema(11))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Trusted pros")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAdd = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add a pro")
            }
        }
        .sheet(isPresented: $showAdd) {
            AddVendorView()
        }
    }

    private func vendorRow(_ vendor: Vendor) -> some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(vendor.name)
                    .font(.cinema(15, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(vendor.company)
                    .font(.cinema(12))
                    .foregroundStyle(Theme.textSecondary)
                if !vendor.note.isEmpty {
                    Text(vendor.note)
                        .font(.cinema(12))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            Spacer()
            if let url = URL(string: "tel:\(vendor.phone.filter { $0.isNumber })"), !vendor.phone.isEmpty {
                Link(destination: url) {
                    Image(systemName: "phone.fill")
                        .frame(width: 34, height: 34)
                        .background(Theme.redSoft, in: Circle())
                        .foregroundStyle(Theme.red)
                }
                .accessibilityLabel("Call \(vendor.name)")
            }
            ShareLink(item: store.vendorMessage(vendor)) {
                Image(systemName: "square.and.arrow.up")
                    .frame(width: 34, height: 34)
                    .background(Theme.surfaceRaised, in: Circle())
                    .foregroundStyle(Theme.textPrimary)
            }
            .accessibilityLabel("Share \(vendor.name)")
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button(role: .destructive) {
                store.deleteVendor(vendor.id)
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
    }
}

struct AddVendorView: View {
    @Environment(CinemaStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var company = ""
    @State private var category: Vendor.Category = .lender
    @State private var phone = ""
    @State private var email = ""
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Type", selection: $category) {
                        ForEach(Vendor.Category.allCases) { Label($0.title, systemImage: $0.icon).tag($0) }
                    }
                    TextField("Name", text: $name)
                        .textContentType(.name)
                    TextField("Company", text: $company)
                        .textContentType(.organizationName)
                }
                Section("Contact") {
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                }
                Section("Why you recommend them") {
                    TextField("Like: closes on time, great with first time buyers", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Add a pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.addVendor(Vendor(name: name.trimmingCharacters(in: .whitespaces), company: company.trimmingCharacters(in: .whitespaces), category: category, phone: phone, email: email, note: note))
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
