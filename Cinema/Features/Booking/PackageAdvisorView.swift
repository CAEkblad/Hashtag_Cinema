import SwiftUI

/// Four questions, one recommended package with the add-ons that fit the home.
struct PackageAdvisorView: View {
    @State private var priceBand: PriceBand = .mid
    @State private var waterfront = false
    @State private var size: HomeSize = .medium
    @State private var relocationBuyers = false
    @State private var onCamera = false
    @State private var vacant = false
    @State private var booking: Recommendation?

    enum PriceBand: String, CaseIterable, Identifiable {
        case starter = "Under $400K"
        case mid = "$400K to $900K"
        case high = "$900K to $2M"
        case luxury = "$2M+"
        var id: String { rawValue }
    }

    enum HomeSize: String, CaseIterable, Identifiable {
        case small = "Condo or small"
        case medium = "Typical home"
        case large = "Large or estate"
        var id: String { rawValue }
    }

    struct Recommendation: Identifiable {
        var id: String { package.id + addOns.map(\.id).joined() }
        var package: ShootPackage
        var addOns: [ShootAddOn]
        var reasons: [String]
        var total: Int { package.price + addOns.reduce(0) { $0 + $1.price * ($1.perPhoto ? 5 : 1) } }
    }

    private var recommendation: Recommendation {
        var reasons: [String] = []
        let packageID: String
        switch priceBand {
        case .starter:
            packageID = waterfront ? "photos-drone" : (onCamera ? "full" : "photos-drone")
            reasons.append("Photos and drone cover what buyers need at this price.")
        case .mid:
            packageID = "full"
            reasons.append("The full package gives you photos plus a video for every platform. It's the most booked option.")
        case .high:
            packageID = size == .large ? "premium" : "cinematic"
            reasons.append("At this price, a cinematic film sells the lifestyle and wins you the next listing.")
        case .luxury:
            packageID = size == .large ? "estate" : "premium"
            reasons.append("Luxury buyers expect a full production with twilight and lifestyle scenes.")
        }
        let package = ShootPackage.listing.first { $0.id == packageID } ?? ShootPackage.listing[0]

        var ids: [String] = []
        if waterfront && !package.isLuxury {
            ids.append("twilight")
            reasons.append("Waterfront homes glow at sunset, so twilight photos stop the scroll.")
        }
        if relocationBuyers {
            ids.append("matterport")
            reasons.append("Out of state buyers tour from their couch. A 3D tour brings you serious offers sight unseen.")
        }
        if size != .small {
            ids.append("floorplan")
            reasons.append("Floor plans keep buyers on the listing longer.")
        }
        if onCamera && package.id != "full" && !package.isLuxury {
            ids.append("oncamera")
            reasons.append("Putting you on camera builds your brand while you market the home.")
        }
        if vacant {
            ids.append("staging")
            reasons.append("Empty rooms look small. Virtual staging on 5 key photos helps buyers picture living there.")
        }
        let addOns = ShootAddOn.all.filter { ids.contains($0.id) }
        return Recommendation(package: package, addOns: addOns, reasons: reasons)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Help me choose")
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Tell us about the home and we'll match the package and add-ons.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                VStack(alignment: .leading, spacing: 14) {
                    question("List price")
                    Picker("List price", selection: $priceBand) {
                        ForEach(PriceBand.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.menu)
                    .tint(Theme.red)
                    question("Size")
                    Picker("Size", selection: $size) {
                        ForEach(HomeSize.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    Toggle("On the water or has a view", isOn: $waterfront)
                    Toggle("Likely buyers are moving from out of state", isOn: $relocationBuyers)
                    Toggle("I want to be on camera", isOn: $onCamera)
                    Toggle("The home is vacant", isOn: $vacant)
                }
                .font(.cinema(14))
                .tint(Theme.red)
                .cardStyle()

                let pick = recommendation
                VStack(alignment: .leading, spacing: 12) {
                    Text("We recommend")
                        .font(.cinema(13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                    HStack(alignment: .firstTextBaseline) {
                        Text(pick.package.name)
                            .font(.cinema(24, weight: .heavy))
                        Spacer()
                        Text("About $\(pick.total.formatted())\(pick.package.isStartingPrice ? "+" : "")")
                            .font(.cinema(16, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    if !pick.addOns.isEmpty {
                        Text("Plus " + pick.addOns.map(\.name).joined(separator: ", "))
                            .font(.cinema(13, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    ForEach(pick.reasons, id: \.self) { reason in
                        Label(reason, systemImage: "checkmark.circle.fill")
                            .font(.cinema(13))
                            .foregroundStyle(.white)
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.red, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

                Button {
                    booking = pick
                } label: {
                    Label("Book this", systemImage: "calendar.badge.plus")
                }
                .buttonStyle(PrimaryButtonStyle())

                NavigationLink(value: Route.findShooter) {
                    Text("Pick my own photographer first")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Help me choose")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $booking) { pick in
            BookingFormView(service: .listing, presetPackageID: pick.package.id, presetAddOnIDs: Set(pick.addOns.map(\.id)))
        }
    }

    private func question(_ text: String) -> some View {
        Text(text)
            .font(.cinema(14, weight: .semibold))
            .foregroundStyle(Theme.textPrimary)
    }
}
