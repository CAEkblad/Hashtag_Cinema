import SwiftUI

/// A "why join us" page a team leader sends to agents they want to recruit.
struct RecruitView: View {
    @Environment(CinemaStore.self) private var store
    @State private var perks: [String] = []
    @State private var newPerk = ""
    @State private var didLoad = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let team = store.team {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("JOIN")
                            .font(.cinema(12, weight: .heavy))
                            .kerning(2)
                            .opacity(0.85)
                        Text(team.name)
                            .font(.cinema(28, weight: .heavy))
                        Text(team.tagline)
                            .font(.cinema(14, weight: .semibold))
                            .opacity(0.9)
                        HStack(alignment: .bottom) {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(perks, id: \.self) { perk in
                                    Label(perk, systemImage: "checkmark.circle.fill")
                                        .font(.cinema(13, weight: .semibold))
                                }
                            }
                            Spacer()
                            QRCodeView(text: team.joinLink)
                                .frame(width: 84, height: 84)
                                .padding(6)
                                .background(.white, in: RoundedRectangle(cornerRadius: 10))
                        }
                        .padding(.top, 6)
                    }
                    .foregroundStyle(.white)
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(store.brandKit.accent.gradient, in: RoundedRectangle(cornerRadius: 22, style: .continuous))

                    HStack(spacing: 12) {
                        StatTile(value: "\(team.members.count)", label: store.lex.agentsTitle, icon: "person.3.fill")
                        StatTile(value: "\(team.members.reduce(0) { $0 + $1.videosThisMonth })", label: "Videos this month", icon: "video.fill")
                        StatTile(value: "\(team.members.reduce(0) { $0 + $1.closings })", label: "Closings", icon: "key.fill")
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("What you offer")
                            .font(.cinema(15, weight: .bold))
                        ForEach(perks, id: \.self) { perk in
                            HStack {
                                Text(perk).font(.cinema(14))
                                Spacer()
                                Button {
                                    perks.removeAll { $0 == perk }
                                } label: {
                                    Image(systemName: "minus.circle.fill").foregroundStyle(Theme.textTertiary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        HStack {
                            TextField("Add a perk, like 80/20 split", text: $newPerk)
                                .inputStyle()
                            Button("Add") {
                                let perk = newPerk.trimmingCharacters(in: .whitespaces)
                                if !perk.isEmpty && !perks.contains(perk) { perks.append(perk) }
                                newPerk = ""
                            }
                            .buttonStyle(PrimaryButtonStyle(fullWidth: false))
                        }
                    }
                    .foregroundStyle(Theme.textPrimary)
                    .cardStyle()

                    ShareLink(item: pitch(team)) {
                        Label("Send to an agent", systemImage: "paperplane.fill")
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button {
                        let idea = ScriptWriter.write(type: .recruiting, topic: "why agents grow faster on \(team.name)", seconds: 30, city: team.city ?? store.homeCity, agentName: store.profile.name)
                        store.saveScript(idea)
                        store.showToast("Recruiting video script saved to your ideas")
                    } label: {
                        Label("Write a recruiting video", systemImage: "video.fill")
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    Text("Agents who join with your code land on your team page with their content flowing in from day one.")
                        .font(.cinema(11))
                        .foregroundStyle(Theme.textTertiary)
                } else {
                    EmptyStateView(title: "Start your team first", message: "Create your team on the Team page, then come back to build your recruiting page.", icon: "person.3")
                }
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Recruiting page")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard !didLoad else { return }
            didLoad = true
            perks = store.team?.perks ?? Team.defaultPerks
        }
        .onChange(of: perks) { _, value in store.setTeamPerks(value) }
    }

    private func pitch(_ team: Team) -> String {
        var lines = ["Hey! I lead \(team.name) in \(team.city?.name ?? store.homeCity.name). We'd love to have you.", ""]
        lines += perks.map { "- \($0)" }
        lines += ["", "\(team.members.count) \(store.lex.agents) and \(team.members.reduce(0) { $0 + $1.videosThisMonth }) videos this month. Want to grab coffee this week?", "", "Join with code \(team.joinCode): \(team.joinLink)", store.profile.name]
        return lines.joined(separator: "\n")
    }
}
