import SwiftUI

struct ListingsView: View {
    @Environment(CinemaStore.self) private var store
    @State private var showAdd = false
    @State private var filter: ListingStatus?

    private var shown: [Listing] {
        guard let filter else { return store.listings }
        return store.listings.filter { $0.status == filter }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Every listing gets a marketing plan: shoot, posters, video, open house and the description, all in one place.")
                    .font(.cinema(14))
                    .foregroundStyle(Theme.textSecondary)

                HStack(spacing: 12) {
                    NavigationLink(value: Route.deals) {
                        quickTile("Pending", value: "\(store.deals.filter { !$0.isClosed }.count)", icon: "doc.text.fill")
                    }
                    .buttonStyle(.plain)
                    NavigationLink(value: Route.tours) {
                        quickTile("Tours", value: "\(store.tours.count)", icon: "car.fill")
                    }
                    .buttonStyle(.plain)
                    NavigationLink(value: Route.buyers) {
                        quickTile("Buyers", value: "\(store.buyers.count)", icon: "heart.text.square")
                    }
                    .buttonStyle(.plain)
                }

                NavigationLink(value: Route.listingPhotos(nil)) {
                    IconRow(icon: "square.and.arrow.down.on.square.fill", title: "Import a listing from the MLS", subtitle: "Type the MLS number to pull in the details and photos")
                        .cardStyle()
                }
                .buttonStyle(.plain)

                NavigationLink(value: Route.agentNetwork) {
                    IconRow(icon: "point.3.connected.trianglepath.dotted", title: "Agent network", subtitle: "\(store.networkListings.filter { $0.status != .active }.count) homes not on the portals · \(store.buyerNeeds.count) buyers looking")
                        .cardStyle()
                }
                .buttonStyle(.plain)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        chip("All \(store.listings.count)", isOn: filter == nil) { filter = nil }
                        ForEach(ListingStatus.allCases) { status in
                            let count = store.listings.filter { $0.status == status }.count
                            chip("\(status.title) \(count)", isOn: filter == status) { filter = status }
                        }
                    }
                }

                if shown.isEmpty {
                    EmptyStateView(title: "No listings here", message: "Add a listing and we'll build its marketing plan.", icon: "house")
                }

                ForEach(shown) { listing in
                    NavigationLink(value: Route.listing(listing.id)) {
                        ListingCard(listing: listing)
                    }
                    .buttonStyle(.plain)
                }

                NavigationLink(value: Route.paymentCalculator) {
                    IconRow(icon: "function", title: "Payment calculator", subtitle: "Monthly payment with Florida taxes and insurance, shareable")
                        .cardStyle()
                }
                .buttonStyle(.plain)
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("My listings")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAdd = true
                } label: {
                    Label("Add listing", systemImage: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            AddListingView()
        }
    }

    private func quickTile(_ title: String, value: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(Theme.red)
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.cinema(18, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text(title)
                    .font(.cinema(12))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .cardStyle(padding: 14)
    }

    private func chip(_ title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.cinema(13, weight: .semibold))
                .foregroundStyle(isOn ? Color.white : Theme.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isOn ? Theme.red : Theme.surface, in: Capsule())
                .overlay(Capsule().stroke(Theme.stroke, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct ListingCard: View {
    let listing: Listing

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Theme.gradient(listing.paletteIndex)
                if let cover = ListingPhotoStore.cover(listing.id) {
                    Image(uiImage: cover)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 78, height: 78)
                        .clipped()
                } else {
                    Image(systemName: listing.symbol)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            .frame(width: 78, height: 78)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Pill(text: listing.status.title, icon: listing.status.icon, color: listing.status == .sold ? Theme.success.opacity(0.15) : Theme.redSoft, textColor: listing.status == .sold ? Theme.success : Theme.red)
                Text(listing.address)
                    .font(.cinema(16, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                Text("\(listing.priceLabel) · \(listing.specsLine)")
                    .font(.cinema(12))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
                if let open = listing.nextOpenHouse {
                    Label("Open house \(open.label)", systemImage: "door.left.hand.open")
                        .font(.cinema(11, weight: .semibold))
                        .foregroundStyle(Theme.textTertiary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
            ProgressRing(progress: listing.progress, lineWidth: 4, size: 42)
        }
        .cardStyle(padding: 12)
    }
}

struct AddListingView: View {
    @Environment(CinemaStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var address = ""
    @State private var city: FloridaCity?
    @State private var showCityPicker = false
    @State private var price = ""
    @State private var beds = 3
    @State private var baths = 2.0
    @State private var squareFeet = ""
    @State private var status: ListingStatus = .comingSoon
    @State private var features: Set<ListingFeature> = []

    private var priceValue: Int { Int(price.filter(\.isNumber)) ?? 0 }
    private var bathsLabel: String {
        baths.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(baths)) : String(format: "%.1f", baths)
    }
    private var canSave: Bool { !address.trimmingCharacters(in: .whitespaces).isEmpty && priceValue > 0 }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    TextField("Street address", text: $address)
                        .textContentType(.fullStreetAddress)
                        .inputStyle()
                    Button {
                        showCityPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "mappin.and.ellipse").foregroundStyle(Theme.red)
                            Text((city ?? store.homeCity).displayName).foregroundStyle(Theme.textPrimary)
                            Spacer()
                            Text("Change").foregroundStyle(Theme.red)
                        }
                        .font(.cinema(15, weight: .medium))
                        .inputStyle()
                    }
                    .buttonStyle(.plain)
                    TextField("List price", text: $price)
                        .keyboardType(.numberPad)
                        .inputStyle()
                    HStack(spacing: 10) {
                        Stepper("\(beds) bed", value: $beds, in: 0...12)
                            .cardStyle(padding: 12)
                        Stepper("\(bathsLabel) bath", value: $baths, in: 0...12, step: 0.5)
                            .cardStyle(padding: 12)
                    }
                    .font(.cinema(15, weight: .medium))
                    TextField("Square feet (optional)", text: $squareFeet)
                        .keyboardType(.numberPad)
                        .inputStyle()
                    Picker("Status", selection: $status) {
                        ForEach(ListingStatus.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    Text("Features")
                        .font(.cinema(15, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    FlowLayout(spacing: 8) {
                        ForEach(ListingFeature.allCases) { feature in
                            let isOn = features.contains(feature)
                            Button {
                                if isOn { features.remove(feature) } else { features.insert(feature) }
                            } label: {
                                Text(feature.title)
                                    .font(.cinema(13, weight: .semibold))
                                    .foregroundStyle(isOn ? Color.white : Theme.textPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(isOn ? Theme.red : Theme.surface, in: Capsule())
                                    .overlay(Capsule().stroke(Theme.stroke, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    Text("We use these to write the description and captions.")
                        .font(.cinema(12))
                        .foregroundStyle(Theme.textTertiary)
                }
                .padding(Theme.gutter)
            }
            .background(Theme.background.ignoresSafeArea())
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("New listing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.addListing(Listing(
                            address: address.trimmingCharacters(in: .whitespaces),
                            cityID: (city ?? store.homeCity).id,
                            price: priceValue,
                            beds: beds,
                            baths: baths,
                            squareFeet: Int(squareFeet.filter(\.isNumber)),
                            status: status,
                            features: ListingFeature.allCases.filter { features.contains($0) },
                            listedAt: Date()
                        ))
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
            .sheet(isPresented: $showCityPicker) {
                CityPickerView(title: "Listing city", selectedIDs: [(city ?? store.homeCity).id]) { picked in
                    city = picked
                }
            }
        }
    }
}
