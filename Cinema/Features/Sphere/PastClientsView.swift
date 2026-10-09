import SwiftUI

/// Past clients and their home anniversaries, with a text ready for each one.
struct PastClientsView: View {
    @Environment(CinemaStore.self) private var store
    @State private var showAdd = false

    private var upcoming: [PastClient] {
        store.pastClients
            .filter { $0.daysUntilAnniversary() <= 30 }
            .sorted { $0.daysUntilAnniversary() < $1.daysUntilAnniversary() }
    }

    private var everyone: [PastClient] {
        store.pastClients.sorted { $0.daysUntilAnniversary() < $1.daysUntilAnniversary() }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Past clients")
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Most repeat and referral business comes from clients who hear from you every year. Home anniversaries are the easiest reason to reach out.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                HStack(spacing: 12) {
                    StatTile(value: "\(store.pastClients.count)", label: "Clients", icon: "person.2.fill")
                    StatTile(value: "\(upcoming.count)", label: "Next 30 days", icon: "calendar")
                    StatTile(value: "\(store.pastClients.filter(\.reminderOn).count)", label: "Reminders", icon: "bell.fill")
                }

                VStack(alignment: .leading, spacing: 10) {
                    Label("Ask your whole sphere for referrals", systemImage: "megaphone.fill")
                        .font(.cinema(15, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(SphereCopy.referralAsk(agentName: store.profile.name))
                        .font(.cinema(13))
                        .foregroundStyle(Theme.textSecondary)
                    ShareLink(item: SphereCopy.referralAsk(agentName: store.profile.name)) {
                        Label("Send", systemImage: "paperplane.fill")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .cardStyle()

                if !upcoming.isEmpty {
                    SectionHeader(title: "Coming up")
                    ForEach(upcoming) { client in
                        clientCard(client, highlight: true)
                    }
                }

                SectionHeader(title: "All past clients", actionTitle: "Add") { showAdd = true }
                if store.pastClients.isEmpty {
                    Text("Add the clients you've closed with. We'll remind you every year on their home anniversary.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                        .cardStyle()
                }
                ForEach(everyone) { client in
                    clientCard(client, highlight: false)
                }
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Past clients")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAdd = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add past client")
            }
        }
        .sheet(isPresented: $showAdd) {
            AddPastClientView()
        }
    }

    private func clientCard(_ client: PastClient, highlight: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Avatar(initials: String(client.name.split(separator: " ").prefix(2).compactMap(\.first)).uppercased(), size: 42, paletteIndex: client.name.count)
                VStack(alignment: .leading, spacing: 2) {
                    Text(client.name)
                        .font(.cinema(16, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("\(client.address) · \(client.cityName)")
                        .font(.cinema(12))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                    Text("\(client.side.title), closed \(client.closeDate.formatted(.dateTime.month(.abbreviated).year()))")
                        .font(.cinema(12))
                        .foregroundStyle(Theme.textTertiary)
                }
                Spacer()
                Menu {
                    Button(role: .destructive) {
                        store.deletePastClient(client.id)
                    } label: {
                        Label("Remove", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 32, height: 32)
                }
            }

            Label(client.anniversaryLine, systemImage: "house.and.flag.fill")
                .font(.cinema(13, weight: .semibold))
                .foregroundStyle(highlight ? Theme.red : Theme.textSecondary)

            HStack(spacing: 10) {
                ShareLink(item: SphereCopy.anniversary(client, agentName: store.profile.name)) {
                    Label("Anniversary text", systemImage: "gift.fill")
                }
                .buttonStyle(highlight ? AnyButtonStyle(PrimaryButtonStyle()) : AnyButtonStyle(SecondaryButtonStyle()))
                ShareLink(item: SphereCopy.valueCheckIn(client, agentName: store.profile.name)) {
                    Label("Value check-in", systemImage: "chart.line.uptrend.xyaxis")
                }
                .buttonStyle(SecondaryButtonStyle())
            }

            Toggle(isOn: Binding(get: { client.reminderOn }, set: { store.setAnniversaryReminder(client.id, on: $0) })) {
                Text("Remind me every year")
                    .font(.cinema(13))
                    .foregroundStyle(Theme.textPrimary)
            }
            .tint(Theme.red)
        }
        .cardStyle()
    }
}

/// Lets a card pick its button style at runtime.
struct AnyButtonStyle: ButtonStyle {
    private let make: (Configuration) -> AnyView

    init<S: ButtonStyle>(_ style: S) {
        make = { AnyView(style.makeBody(configuration: $0)) }
    }

    func makeBody(configuration: Configuration) -> some View {
        make(configuration)
    }
}

struct AddPastClientView: View {
    @Environment(CinemaStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var address = ""
    @State private var cityName = ""
    @State private var phone = ""
    @State private var side: Testimonial.Side = .buyer
    @State private var closeDate = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
    @State private var remind = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Client") {
                    TextField("Name, like Maria and Luis Gomez", text: $name)
                        .textContentType(.name)
                    TextField("Phone (optional)", text: $phone)
                        .keyboardType(.phonePad)
                    Picker("They were a", selection: $side) {
                        ForEach(Testimonial.Side.allCases) { Text($0.title).tag($0) }
                    }
                }
                Section("The home") {
                    TextField("Address", text: $address)
                        .textContentType(.fullStreetAddress)
                    Picker("City", selection: $cityName) {
                        ForEach(store.allMarkets) { market in
                            Text(market.name).tag(market.name)
                        }
                    }
                    DatePicker("Closing date", selection: $closeDate, in: ...Date(), displayedComponents: .date)
                }
                Section {
                    Toggle("Remind me every year", isOn: $remind)
                        .tint(Theme.red)
                } footer: {
                    Text("You'll get a notification at 9 AM on their home anniversary with a text ready to send.")
                }
            }
            .navigationTitle("Add past client")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { if cityName.isEmpty { cityName = store.homeCity.name } }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.addPastClient(PastClient(name: name.trimmingCharacters(in: .whitespaces), address: address.trimmingCharacters(in: .whitespaces), cityName: cityName, closeDate: closeDate, side: side, phone: phone, reminderOn: false), remind: remind)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || address.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
