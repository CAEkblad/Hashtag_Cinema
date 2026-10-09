import SwiftUI
import Charts

/// The neighborhood an agent wants to be known for, and every touch they make there.
struct FarmArea: Identifiable, Hashable, Codable {
    enum TouchKind: String, CaseIterable, Identifiable, Codable {
        case video, postcard, doorKnock, socialAd, event
        var id: String { rawValue }
        var title: String {
            switch self {
            case .video: return "Video"
            case .postcard: return "Postcard"
            case .doorKnock: return "Door knock"
            case .socialAd: return "Social ad"
            case .event: return "Event"
            }
        }
        var icon: String {
            switch self {
            case .video: return "video.fill"
            case .postcard: return "envelope.fill"
            case .doorKnock: return "door.left.hand.closed"
            case .socialAd: return "megaphone.fill"
            case .event: return "party.popper.fill"
            }
        }
    }

    struct Touch: Identifiable, Hashable, Codable {
        var id = UUID()
        var date: Date
        var kind: TouchKind
    }

    var id = UUID()
    var cityID: String
    var neighborhood: String
    var homes: Int = 500
    var monthlyGoal: Int = 8
    var touches: [Touch] = []

    var city: FloridaCity? { FloridaMarkets.city(cityID) }

    func touches(inMonthOf date: Date) -> [Touch] {
        touches.filter { Calendar.current.isDate($0.date, equalTo: date, toGranularity: .month) }
    }
}

struct FarmView: View {
    @Environment(CinemaStore.self) private var store
    @State private var showSetup = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("My farm")
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Pick one neighborhood and show up there every month. The agent people see most is the agent they call.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                if let farm = store.farm {
                    farmContent(farm)
                } else {
                    EmptyStateView(title: "Choose your farm", message: "A neighborhood of 300 to 1,000 homes where you'd love to be the go to agent.", icon: "map.fill")
                    Button {
                        showSetup = true
                    } label: {
                        Label("Pick a neighborhood", systemImage: "mappin.and.ellipse")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Farm")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if store.farm != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Change") { showSetup = true }
                }
            }
        }
        .sheet(isPresented: $showSetup) {
            FarmSetupView()
        }
    }

    @ViewBuilder
    private func farmContent(_ farm: FarmArea) -> some View {
        let thisMonth = farm.touches(inMonthOf: Date())
        VStack(alignment: .leading, spacing: 10) {
            Text(farm.neighborhood)
                .font(.cinema(24, weight: .heavy))
            Text("\(farm.city?.displayName ?? "") · about \(farm.homes.formatted()) homes")
                .font(.cinema(13, weight: .semibold))
                .opacity(0.9)
            ProgressView(value: Double(min(thisMonth.count, farm.monthlyGoal)), total: Double(max(farm.monthlyGoal, 1)))
                .tint(.white)
            Text("\(thisMonth.count) of \(farm.monthlyGoal) touches this month")
                .font(.cinema(12, weight: .semibold))
                .opacity(0.9)
        }
        .foregroundStyle(.white)
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.red, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

        SectionHeader(title: "Log a touch")
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            ForEach(FarmArea.TouchKind.allCases) { kind in
                Button {
                    store.logFarmTouch(kind)
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: kind.icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Theme.red)
                        Text(kind.title)
                            .font(.cinema(12, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Text("\(thisMonth.filter { $0.kind == kind }.count)")
                            .font(.cinema(11))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .cardStyle(padding: 12)
                }
                .buttonStyle(.plain)
            }
        }

        SectionHeader(title: "Last 6 months")
        Chart(monthBars(farm), id: \.label) { bar in
            BarMark(x: .value("Month", bar.label), y: .value("Touches", bar.count))
                .foregroundStyle(bar.count >= farm.monthlyGoal ? Theme.red : Theme.red.opacity(0.4))
            RuleMark(y: .value("Goal", farm.monthlyGoal))
                .foregroundStyle(Theme.textTertiary)
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
        }
        .frame(height: 160)
        .cardStyle()

        SectionHeader(title: "Video ideas for \(farm.neighborhood)")
        ForEach(videoIdeas(farm), id: \.self) { topic in
            HStack(spacing: 12) {
                Text(topic)
                    .font(.cinema(14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Button {
                    if let city = farm.city {
                        let idea = ScriptWriter.write(type: .neighborhood, topic: topic, seconds: 30, city: city, agentName: store.profile.name)
                        store.saveScript(idea)
                        store.showToast("Script saved to your ideas")
                    }
                } label: {
                    Label("Script", systemImage: "text.quote")
                        .font(.cinema(12, weight: .semibold))
                        .foregroundStyle(Theme.red)
                }
                .buttonStyle(.plain)
            }
            .cardStyle(padding: 14)
        }
    }

    private struct MonthBar { var label: String; var count: Int }

    private func monthBars(_ farm: FarmArea) -> [MonthBar] {
        (0..<6).reversed().map { back in
            let date = Calendar.current.date(byAdding: .month, value: -back, to: Date()) ?? Date()
            return MonthBar(label: date.formatted(.dateTime.month(.abbreviated)), count: farm.touches(inMonthOf: date).count)
        }
    }

    private func videoIdeas(_ farm: FarmArea) -> [String] {
        let n = farm.neighborhood
        return [
            "living in \(n)",
            "what just sold in \(n) and why",
            "the best spots in \(n) only locals know",
            "what your money buys in \(n) right now"
        ]
    }
}

struct FarmSetupView: View {
    @Environment(CinemaStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var cityID = ""
    @State private var neighborhood = ""
    @State private var custom = ""
    @State private var homes = 500
    @State private var goal = 8

    private var city: FloridaCity? { FloridaMarkets.city(cityID) }

    var body: some View {
        NavigationStack {
            Form {
                Section("City") {
                    Picker("City", selection: $cityID) {
                        ForEach(store.allMarkets) { Text($0.name).tag($0.id) }
                    }
                }
                Section("Neighborhood") {
                    if let city, !city.neighborhoods.isEmpty {
                        Picker("Neighborhood", selection: $neighborhood) {
                            Text("Type my own").tag("")
                            ForEach(city.neighborhoods, id: \.self) { Text($0).tag($0) }
                        }
                    }
                    if neighborhood.isEmpty {
                        TextField("Neighborhood or subdivision", text: $custom)
                    }
                }
                Section("Plan") {
                    Stepper("About \(homes) homes", value: $homes, in: 100...3_000, step: 50)
                    Stepper("\(goal) touches a month", value: $goal, in: 2...30)
                }
            }
            .navigationTitle("My farm")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if cityID.isEmpty {
                    cityID = store.farm?.cityID ?? store.homeCity.id
                    neighborhood = store.farm?.neighborhood ?? ""
                    if let farm = store.farm, !(city?.neighborhoods.contains(farm.neighborhood) ?? false) {
                        neighborhood = ""
                        custom = farm.neighborhood
                    }
                    homes = store.farm?.homes ?? 500
                    goal = store.farm?.monthlyGoal ?? 8
                }
            }
            .onChange(of: cityID) { _, _ in
                if let city, !city.neighborhoods.contains(neighborhood) { neighborhood = "" }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let name = neighborhood.isEmpty ? custom.trimmingCharacters(in: .whitespaces) : neighborhood
                        store.setFarm(cityID: cityID, neighborhood: name, homes: homes, goal: goal)
                        dismiss()
                    }
                    .disabled((neighborhood.isEmpty ? custom.trimmingCharacters(in: .whitespaces) : neighborhood).isEmpty)
                }
            }
        }
    }
}
