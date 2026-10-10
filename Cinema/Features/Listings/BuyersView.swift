import SwiftUI

/// What a buyer is looking for, matched against the agent's listings.
struct BuyerWish: Identifiable, Hashable, Codable {
    var id = UUID()
    var name: String
    var phone: String = ""
    var cityNames: [String] = []
    var maxPrice: Int
    var minBeds: Int = 2
    var mustHaves: [ListingFeature] = []
    var notes: String = ""

    var firstName: String { name.split(separator: " ").first.map(String.init) ?? name }

    func matches(_ listing: Listing) -> Bool {
        guard listing.status == .active || listing.status == .comingSoon else { return false }
        guard listing.price <= maxPrice, listing.beds >= minBeds else { return false }
        if !cityNames.isEmpty, let city = listing.city?.name, !cityNames.contains(city) { return false }
        return mustHaves.allSatisfy { listing.features.contains($0) }
    }

    var summary: String {
        var parts = ["Up to \(maxPrice.formatted(.currency(code: "USD").precision(.fractionLength(0))))", "\(minBeds)+ beds"]
        if !cityNames.isEmpty { parts.append(cityNames.joined(separator: ", ")) }
        if !mustHaves.isEmpty { parts.append(mustHaves.map(\.title).joined(separator: ", ")) }
        return parts.joined(separator: " · ")
    }
}

struct BuyersView: View {
    @Environment(CinemaStore.self) private var store
    @State private var showAdd = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Buyer wishlists")
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Save what each buyer wants. When one of your listings fits, we'll show the match and write the text.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                Button {
                    showAdd = true
                } label: {
                    Label("Add a buyer", systemImage: "plus")
                }
                .buttonStyle(PrimaryButtonStyle())

                ForEach(store.buyers) { buyer in
                    let matches = store.listings.filter { buyer.matches($0) }
                    NavigationLink(value: Route.buyer(buyer.id)) {
                        HStack(spacing: 12) {
                            Avatar(initials: String(buyer.name.split(separator: " ").prefix(2).compactMap(\.first)).uppercased(), size: 42, paletteIndex: buyer.name.count)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(buyer.name)
                                    .font(.cinema(16, weight: .semibold))
                                    .foregroundStyle(Theme.textPrimary)
                                Text(buyer.summary)
                                    .font(.cinema(12))
                                    .foregroundStyle(Theme.textSecondary)
                                    .lineLimit(2)
                            }
                            Spacer()
                            if !matches.isEmpty {
                                Pill(text: "\(matches.count) match\(matches.count == 1 ? "" : "es")", color: Theme.redSoft, textColor: Theme.red)
                            }
                        }
                        .cardStyle()
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Buyers")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAdd) {
            AddBuyerView()
        }
    }
}

struct BuyerDetailView: View {
    @Environment(CinemaStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let buyerID: UUID

    var body: some View {
        if let buyer = store.buyers.first(where: { $0.id == buyerID }) {
            content(buyer)
        } else {
            EmptyStateView(title: "Buyer not found", message: "They may have been removed.", icon: "person")
                .cinemaScreen()
        }
    }

    private func content(_ buyer: BuyerWish) -> some View {
        let matches = store.listings.filter { buyer.matches($0) }
        return ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(buyer.name)
                        .font(.cinema(24, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(buyer.summary)
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                    if !buyer.notes.isEmpty {
                        Text(buyer.notes)
                            .font(.cinema(13))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }

                NavigationLink(value: Route.gems(buyer.id)) {
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Theme.red, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Find hidden gems for \(buyer.firstName)")
                                .font(.cinema(16, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)
                            Text("Value, motivated sellers and homes not on the portals yet")
                                .font(.cinema(12))
                                .foregroundStyle(Theme.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(Theme.textTertiary)
                    }
                    .cardStyle()
                }
                .buttonStyle(.plain)

                HStack(spacing: 10) {
                    NavigationLink(value: Route.affordability) {
                        Label("How much home", systemImage: "dollarsign.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    NavigationLink(value: Route.rentVsBuy) {
                        Label("Rent or buy", systemImage: "scale.3d")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }

                NavigationLink(value: Route.buyerPresentation) {
                    Label("Buyer consultation PDF", systemImage: "person.crop.rectangle.stack.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle())

                SectionHeader(title: matches.isEmpty ? "No matches on my listings yet" : "Matches on my listings")
                if matches.isEmpty {
                    Text("None of your active or coming soon listings fit yet. We'll show matches here as soon as you add one.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                        .cardStyle()
                }
                ForEach(matches) { listing in
                    VStack(alignment: .leading, spacing: 10) {
                        NavigationLink(value: Route.listing(listing.id)) {
                            ListingCard(listing: listing)
                        }
                        .buttonStyle(.plain)
                        ShareLink(item: "Hi \(buyer.firstName)! This one just made me think of you: \(listing.address), \(listing.priceLabel), \(listing.specsLine). Want to see it this week?") {
                            Label("Send to \(buyer.firstName)", systemImage: "paperplane.fill")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                }

                if !matches.isEmpty {
                    Button {
                        store.createTour(
                            buyerName: buyer.name,
                            start: Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date().addingTimeInterval(86_400)) ?? Date(),
                            minutesPerStop: 30,
                            stops: matches.map { TourStop(address: "\($0.address), \($0.city?.name ?? "")", price: $0.priceLabel) }
                        )
                    } label: {
                        Label("Plan a tour of these for tomorrow", systemImage: "car.fill")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }

                Button("Remove buyer", role: .destructive) {
                    store.deleteBuyer(buyer.id)
                    dismiss()
                }
                .font(.cinema(14, weight: .semibold))
                .frame(maxWidth: .infinity)
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Buyer")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AddBuyerView: View {
    @Environment(CinemaStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var phone = ""
    @State private var maxPrice: Double = 500_000
    @State private var minBeds = 3
    @State private var cities: Set<String> = []
    @State private var mustHaves: Set<ListingFeature> = []
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Buyer") {
                    TextField("Name", text: $name)
                        .textContentType(.name)
                    TextField("Phone (optional)", text: $phone)
                        .keyboardType(.phonePad)
                }
                Section("Looking for") {
                    VStack(alignment: .leading) {
                        Text("Up to \(Int(maxPrice).formatted(.currency(code: "USD").precision(.fractionLength(0))))")
                        Slider(value: $maxPrice, in: 150_000...3_000_000, step: 25_000)
                            .tint(Theme.red)
                    }
                    Stepper("\(minBeds)+ bedrooms", value: $minBeds, in: 1...6)
                }
                Section("Cities (leave blank for any)") {
                    ForEach(store.allMarkets) { city in
                        Toggle(city.name, isOn: Binding(get: { cities.contains(city.name) }, set: { if $0 { cities.insert(city.name) } else { cities.remove(city.name) } }))
                            .tint(Theme.red)
                    }
                }
                Section("Must haves") {
                    ForEach(ListingFeature.allCases) { feature in
                        Toggle(feature.title, isOn: Binding(get: { mustHaves.contains(feature) }, set: { if $0 { mustHaves.insert(feature) } else { mustHaves.remove(feature) } }))
                            .tint(Theme.red)
                    }
                }
                Section("Notes") {
                    TextField("Timeline, schools, deal breakers", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }
            }
            .navigationTitle("Add a buyer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.addBuyer(BuyerWish(name: name.trimmingCharacters(in: .whitespaces), phone: phone, cityNames: Array(cities).sorted(), maxPrice: Int(maxPrice), minBeds: minBeds, mustHaves: ListingFeature.allCases.filter { mustHaves.contains($0) }, notes: notes))
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
