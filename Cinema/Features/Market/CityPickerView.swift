import SwiftUI

/// Search or browse every Florida city. Used for the home market and for extra cities an agent serves.
struct CityPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    var selectedIDs: Set<String> = []
    var dismissOnPick = true
    let onPick: (FloridaCity) -> Void

    @State private var query = ""
    @State private var region: FloridaRegion?

    private var results: [FloridaCity] {
        if let region {
            let inRegion = FloridaMarkets.cities(in: region)
            guard !query.isEmpty else { return inRegion }
            let ids = Set(FloridaMarkets.search(query, limit: 200).map(\.id))
            return inRegion.filter { ids.contains($0.id) }
        }
        return FloridaMarkets.search(query, limit: 60)
    }

    var body: some View {
        NavigationStack {
            List {
                if query.isEmpty && region == nil {
                    Section("Popular markets") {
                        ForEach(FloridaMarkets.all.prefix(15)) { city in
                            row(city)
                        }
                    }
                    .listRowBackground(Theme.surface)

                    Section("Browse by region") {
                        ForEach(FloridaRegion.allCases) { option in
                            Button {
                                region = option
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: option.icon)
                                        .foregroundStyle(Theme.red)
                                        .frame(width: 28)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(option.title)
                                            .font(.cinema(16, weight: .semibold))
                                            .foregroundStyle(Theme.textPrimary)
                                        Text("\(FloridaMarkets.cities(in: option).count) cities and towns")
                                            .font(.cinema(12))
                                            .foregroundStyle(Theme.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Theme.textTertiary)
                                }
                            }
                        }
                    }
                    .listRowBackground(Theme.surface)
                } else {
                    if let region {
                        Section {
                            HStack {
                                Label(region.title, systemImage: region.icon)
                                    .font(.cinema(15, weight: .semibold))
                                    .foregroundStyle(Theme.textPrimary)
                                Spacer()
                                Button("All regions") { self.region = nil }
                                    .font(.cinema(14, weight: .semibold))
                                    .foregroundStyle(Theme.red)
                                    .buttonStyle(.borderless)
                            }
                        } footer: {
                            Text(region.blurb)
                        }
                        .listRowBackground(Theme.surface)
                    }
                    Section {
                        if results.isEmpty {
                            Text("No Florida city matches \"\(query)\". Try the county name.")
                                .font(.cinema(14))
                                .foregroundStyle(Theme.textSecondary)
                        }
                        ForEach(results) { city in
                            row(city)
                        }
                    }
                    .listRowBackground(Theme.surface)
                }
            }
            .cinemaScreen()
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search \(FloridaMarkets.all.count) Florida cities")
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func row(_ city: FloridaCity) -> some View {
        Button {
            onPick(city)
            if dismissOnPick { dismiss() }
        } label: {
            CityRow(city: city, isSelected: selectedIDs.contains(city.id))
        }
    }
}

struct CityRow: View {
    let city: FloridaCity
    var isSelected = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: city.region.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.red)
                .frame(width: 32, height: 32)
                .background(Theme.redSoft, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(city.name)
                    .font(.cinema(16, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("\(city.countyLine) · \(city.region.title)")
                    .font(.cinema(12))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            if let population = city.population, population > 0 {
                Text(population.compact)
                    .font(.cinema(12, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
            }
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Theme.red)
            }
        }
        .contentShape(Rectangle())
    }
}
