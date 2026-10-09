import SwiftUI
import MapKit

/// Everything local: the city, what is happening this month, ideas written for
/// it, neighborhoods to spotlight and the other cities the agent serves.
struct MarketView: View {
    @Environment(CinemaStore.self) private var store
    /// Nil shows the agent's home market.
    var cityID: String? = nil

    @State private var openIdea: Idea?
    @State private var showHomePicker = false
    @State private var showAreaPicker = false

    private var city: FloridaCity { FloridaMarkets.city(cityID) ?? store.homeCity }
    private var isHome: Bool { city.id == store.homeCity.id }
    private var month: Int { store.currentMonth }
    private var moments: [SeasonalMoment] { FloridaCalendar.moments(month: month, city: city) }
    private var pack: [Idea] { store.localIdeas(for: city, count: 6) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                mapHeader
                cityCard
                if !moments.isEmpty { thisMonth }
                ideaPack
                spotlight
                if isHome { servedCities }
                nearby
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle(isHome ? "My market" : city.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $openIdea) { idea in
            IdeaDetailView(idea: idea)
        }
        .sheet(isPresented: $showHomePicker) {
            CityPickerView(title: "Your home market", selectedIDs: [store.homeCity.id]) { picked in
                store.setHomeCity(picked)
            }
        }
        .sheet(isPresented: $showAreaPicker) {
            CityPickerView(title: "Cities you serve", selectedIDs: Set(store.profile.serviceAreaIDs), dismissOnPick: false) { picked in
                store.toggleServiceArea(picked)
            }
        }
    }

    // MARK: Header

    private var mapHeader: some View {
        Map(initialPosition: .region(MKCoordinateRegion(center: city.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.45, longitudeDelta: 0.45)))) {
            Marker(city.name, systemImage: "house.fill", coordinate: city.coordinate)
                .tint(Theme.red)
            if isHome {
                ForEach(store.serviceAreas) { area in
                    Marker(area.name, coordinate: area.coordinate)
                        .tint(Theme.ink)
                }
            }
        }
        .id(city.id)
        .frame(height: 190)
        .clipShape(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
        .allowsHitTesting(false)
        .overlay(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous).stroke(Theme.stroke, lineWidth: 1))
    }

    private var cityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(city.displayName)
                    .font(.cinema(26, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text([city.countyLine, city.region.title, city.populationLabel].compactMap { $0 }.joined(separator: " · "))
                    .font(.cinema(13))
                    .foregroundStyle(Theme.textSecondary)
            }

            if !city.chipTraits.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(city.chipTraits) { trait in
                        Pill(text: trait.title, icon: trait.icon, color: Theme.redSoft, textColor: Theme.red)
                    }
                }
            }

            if !city.highlights.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(city.highlights, id: \.self) { highlight in
                        Label(highlight, systemImage: "star.fill")
                            .font(.cinema(14))
                            .foregroundStyle(Theme.textPrimary)
                            .labelStyle(TintedIconLabelStyle())
                    }
                }
            }

            Text(city.region.blurb)
                .font(.cinema(13))
                .foregroundStyle(Theme.textTertiary)

            if isHome {
                Button {
                    showHomePicker = true
                } label: {
                    Label("Change my city", systemImage: "mappin.and.ellipse")
                }
                .buttonStyle(SecondaryButtonStyle())
            } else {
                HStack(spacing: 10) {
                    Button("Make this my market") { store.setHomeCity(city) }
                        .buttonStyle(PrimaryButtonStyle())
                    Button(store.isServiceArea(city) ? "Remove" : "I serve it") { store.toggleServiceArea(city) }
                        .buttonStyle(SecondaryButtonStyle(fullWidth: false))
                }
            }
        }
        .cardStyle()
    }

    // MARK: This month

    private var thisMonth: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "This month in \(city.name)")
            Text("Timely topics people in \(city.name) are searching for right now. Tap one to turn it into a video.")
                .font(.cinema(13))
                .foregroundStyle(Theme.textSecondary)
            ForEach(moments) { moment in
                Button {
                    openIdea = store.addIdea(LocalIdeaEngine.idea(from: moment, city: city), announce: false)
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: moment.icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Theme.red)
                            .frame(width: 38, height: 38)
                            .background(Theme.redSoft, in: Circle())
                        VStack(alignment: .leading, spacing: 4) {
                            Text(moment.title)
                                .font(.cinema(16, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)
                                .multilineTextAlignment(.leading)
                            Text(moment.detail)
                                .font(.cinema(13))
                                .foregroundStyle(Theme.textSecondary)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                            Label("Make it a video", systemImage: "video.badge.plus")
                                .font(.cinema(13, weight: .semibold))
                                .foregroundStyle(Theme.red)
                                .padding(.top, 2)
                        }
                        Spacer(minLength: 0)
                    }
                    .cardStyle()
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: Ideas

    private var ideaPack: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "\(city.name) idea pack", actionTitle: "Add all") {
                for idea in pack.reversed() { store.addIdea(idea, announce: false) }
                store.showToast("\(pack.count) \(city.name) ideas added to Create")
            }
            ForEach(pack) { idea in
                Button {
                    openIdea = store.addIdea(idea, announce: false)
                } label: {
                    IdeaCard(idea: idea)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var spotlightNames: [String] {
        if !city.neighborhoods.isEmpty { return city.neighborhoods }
        return FloridaMarkets.nearby(city, limit: 6).map(\.name)
    }

    private var spotlight: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: city.neighborhoods.isEmpty ? "Spotlight a nearby town" : "Spotlight a neighborhood")
            Text("Tap one and we will write the shot list and script.")
                .font(.cinema(13))
                .foregroundStyle(Theme.textSecondary)
            FlowLayout(spacing: 8) {
                ForEach(spotlightNames, id: \.self) { name in
                    Button {
                        openIdea = store.addIdea(LocalIdeaEngine.neighborhoodIdea(name, city: city), announce: false)
                    } label: {
                        Label(name, systemImage: "mappin")
                            .font(.cinema(14, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(Theme.surface, in: Capsule())
                            .overlay(Capsule().stroke(Theme.stroke, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: Cities

    private var servedCities: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Cities you serve", actionTitle: "Add") { showAreaPicker = true }
            if store.serviceAreas.isEmpty {
                Text("Add the other cities you sell in. Your daily ideas rotate across all of them.")
                    .font(.cinema(14))
                    .foregroundStyle(Theme.textSecondary)
                    .cardStyle()
            } else {
                ForEach(store.serviceAreas) { area in
                    NavigationLink(value: Route.city(area.id)) {
                        CityRow(city: area)
                            .cardStyle(padding: 12)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var nearby: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Nearby markets")
            ForEach(FloridaMarkets.nearby(city, limit: 5)) { other in
                NavigationLink(value: Route.city(other.id)) {
                    HStack {
                        CityRow(city: other)
                        Text("\(Int(other.distance(to: city).rounded())) mi")
                            .font(.cinema(12, weight: .semibold))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    .cardStyle(padding: 12)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// Label with a red icon and dark text.
struct TintedIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            configuration.icon
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.red)
            configuration.title
        }
    }
}
