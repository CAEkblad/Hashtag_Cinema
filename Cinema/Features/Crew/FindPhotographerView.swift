import SwiftUI
import MapKit

/// Browse #Cinema Crew photographers and videographers near the agent's city.
/// Contact details stay private: every request and booking runs through #Cinema.
struct FindPhotographerView: View {
    @Environment(CinemaStore.self) private var store
    @State private var skill: ShooterSkill?
    @State private var sort: Sort = .bestMatch
    @State private var cityID: String?
    @State private var showCityPicker = false
    @State private var onlyFavorites = false
    @State private var showMap = false
    @State private var mapPick: Shooter?

    private struct Pin: Identifiable {
        var id: UUID { shooter.id }
        var shooter: Shooter
        var coordinate: CLLocationCoordinate2D
    }

    /// Shooters in the same city get spread out a little so every pin is tappable.
    private var pins: [Pin] {
        results.enumerated().compactMap { index, shooter in
            guard let base = shooter.city?.coordinate else { return nil }
            let angle = Double(index) * 2.4
            let offset = 0.018 * Double(index % 4 + 1)
            return Pin(shooter: shooter, coordinate: CLLocationCoordinate2D(latitude: base.latitude + offset * sin(angle), longitude: base.longitude + offset * cos(angle)))
        }
    }

    enum Sort: String, CaseIterable, Identifiable {
        case bestMatch = "Best match"
        case rating = "Top rated"
        case soonest = "Soonest"
        var id: String { rawValue }
    }

    private var city: FloridaCity { FloridaMarkets.city(cityID) ?? store.homeCity }

    private var results: [Shooter] {
        var list = store.shooters(near: city, skill: skill)
        if onlyFavorites { list = list.filter { store.favoriteShooterIDs.contains($0.id) } }
        switch sort {
        case .bestMatch: return list
        case .rating: return list.sorted { $0.rating > $1.rating }
        case .soonest: return list.sorted { $0.nextOpening < $1.nextOpening }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                skillChips
                HStack {
                    Picker("Sort", selection: $sort) {
                        ForEach(Sort.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    Button {
                        onlyFavorites.toggle()
                    } label: {
                        Image(systemName: onlyFavorites ? "heart.fill" : "heart")
                            .foregroundStyle(Theme.red)
                            .frame(width: 36, height: 32)
                            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .accessibilityLabel("Show favorites only")
                    Button {
                        withAnimation { showMap.toggle() }
                    } label: {
                        Image(systemName: showMap ? "list.bullet" : "map.fill")
                            .foregroundStyle(Theme.red)
                            .frame(width: 36, height: 32)
                            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .accessibilityLabel(showMap ? "Show list" : "Show map")
                }

                if showMap && !results.isEmpty {
                    mapView
                }

                if results.isEmpty {
                    EmptyStateView(
                        title: "No shooters here yet",
                        message: "We're adding Crew in \(city.name). Request a shoot anyway and #Cinema will send someone from nearby.",
                        icon: "camera.badge.clock"
                    )
                    NavigationLink(value: Route.bookings) {
                        Text("Request a shoot")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }

                ForEach(showMap ? [] : results) { shooter in
                    NavigationLink(value: Route.shooter(shooter.id)) {
                        ShooterCard(shooter: shooter, homeCity: city, isFavorite: store.favoriteShooterIDs.contains(shooter.id))
                    }
                    .buttonStyle(.plain)
                }

                guarantee

                NavigationLink(value: Route.joinCrew) {
                    IconRow(icon: "camera.badge.ellipsis", title: "Are you a photographer or videographer?", subtitle: "Join #Cinema Crew and get booked by agents")
                        .cardStyle()
                }
                .buttonStyle(.plain)

                Text("Demo profiles. The live directory loads from #Cinema Crew.")
                    .font(.cinema(11))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Find a photographer")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCityPicker) {
            CityPickerView(title: "Shoot location", selectedIDs: [city.id]) { picked in
                cityID = picked.id
            }
        }
    }

    private var mapView: some View {
        VStack(spacing: 12) {
            Map(initialPosition: .region(MKCoordinateRegion(center: city.coordinate, span: MKCoordinateSpan(latitudeDelta: 1.1, longitudeDelta: 1.1)))) {
                ForEach(pins) { pin in
                    Annotation(pin.shooter.name, coordinate: pin.coordinate) {
                        Button {
                            mapPick = pin.shooter
                        } label: {
                            Avatar(initials: pin.shooter.initials, size: mapPick?.id == pin.shooter.id ? 44 : 34, paletteIndex: pin.shooter.name.count)
                                .overlay(Circle().stroke(mapPick?.id == pin.shooter.id ? Theme.red : .white, lineWidth: 3))
                                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .id(city.id)
            .frame(height: 380)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            if let pick = mapPick ?? results.first {
                NavigationLink(value: Route.shooter(pick.id)) {
                    ShooterCard(shooter: pick, homeCity: city, isFavorite: store.favoriteShooterIDs.contains(pick.id))
                }
                .buttonStyle(.plain)
            }
            Text("Tap a photo to see who it is. Pins show the area each shooter covers, not a home address.")
                .font(.cinema(11))
                .foregroundStyle(Theme.textTertiary)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Vetted shooters near \(city.name)")
                .font(.cinema(24, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text("Background checked, insured and rated by agents after every shoot.")
                .font(.cinema(14))
                .foregroundStyle(Theme.textSecondary)
            Button {
                showCityPicker = true
            } label: {
                Label("Shooting somewhere else? \(city.displayName)", systemImage: "mappin.and.ellipse")
                    .font(.cinema(13, weight: .semibold))
                    .foregroundStyle(Theme.red)
            }
        }
    }

    private var skillChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip("All", icon: "square.grid.2x2.fill", isOn: skill == nil) { skill = nil }
                ForEach(ShooterSkill.allCases) { option in
                    chip(option.title, icon: option.icon, isOn: skill == option) { skill = option }
                }
            }
        }
    }

    private func chip(_ title: String, icon: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.cinema(13, weight: .semibold))
                .foregroundStyle(isOn ? Color.white : Theme.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isOn ? Theme.red : Theme.surface, in: Capsule())
                .overlay(Capsule().stroke(Theme.stroke, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var guarantee: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("The #Cinema guarantee", systemImage: "checkmark.shield.fill")
                .font(.cinema(16, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text("Book through #Cinema and every shoot is insured, edited to #Cinema standards and backed by a reshoot if something is off. Shooters agree to work with #Cinema clients only through #Cinema, so your listings stay yours.")
                .font(.cinema(13))
                .foregroundStyle(Theme.textSecondary)
        }
        .cardStyle()
    }
}

struct ShooterCard: View {
    let shooter: Shooter
    let homeCity: FloridaCity
    var isFavorite = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Avatar(initials: shooter.initials, size: 52, paletteIndex: shooter.tier.paletteIndex)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(shooter.name)
                            .font(.cinema(17, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                        if isFavorite {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.red)
                        }
                    }
                    HStack(spacing: 6) {
                        TierBadge(tier: shooter.tier)
                        Label(shooter.ratingLabel, systemImage: "star.fill")
                            .font(.cinema(13, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                            .labelStyle(TintedIconLabelStyle())
                        Text("· \(shooter.jobsCompleted) shoots")
                            .font(.cinema(12))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    if let city = shooter.city {
                        Text(city.id == homeCity.id ? "Based in \(city.name)" : "\(city.name) · \(Int(city.distance(to: homeCity).rounded())) mi away")
                            .font(.cinema(12))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: 6) {
                ForEach(shooter.portfolio.prefix(4)) { item in
                    ZStack {
                        Theme.gradient(item.paletteIndex)
                        Image(systemName: item.isVideo ? "play.fill" : item.symbol)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    .frame(height: 64)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }

            FlowLayout(spacing: 6) {
                ForEach(shooter.skills.prefix(4)) { skill in
                    Pill(text: skill.title, icon: skill.icon)
                }
            }

            HStack {
                Label("Next opening \(shooter.nextOpening.shortDay)", systemImage: "calendar")
                    .font(.cinema(12, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Text("Listings from $179")
                    .font(.cinema(12, weight: .semibold))
                    .foregroundStyle(Theme.red)
            }
        }
        .cardStyle()
    }
}

struct TierBadge: View {
    let tier: CrewTier

    var body: some View {
        Label(tier.title, systemImage: tier.icon)
            .font(.cinema(11, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Theme.gradient(tier.paletteIndex), in: Capsule())
    }
}

struct StarRow: View {
    let rating: Int
    var size: CGFloat = 13

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: index <= rating ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundStyle(index <= rating ? Theme.warning : Theme.textTertiary)
            }
        }
    }
}
