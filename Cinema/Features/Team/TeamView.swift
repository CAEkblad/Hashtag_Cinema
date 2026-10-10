import SwiftUI

/// The team page: everything the team makes shows up here automatically.
struct TeamView: View {
    @Environment(CinemaStore.self) private var store
    @State private var tab: Tab = .feed
    @State private var code = ""
    @State private var showCreate = false
    @State private var confirmLeave = false
    @State private var showAddMember = false

    enum Tab: String, CaseIterable, Identifiable {
        case feed = "Feed"
        case roster = "Roster"
        case board = "Leaderboard"
        var id: String { rawValue }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let team = store.team {
                    header(team)
                    if store.isTeamLeader { leaderTools(team) }
                    Toggle(isOn: Binding(get: { store.sharesWithTeam }, set: { store.setSharesWithTeam($0) })) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Share my content with the team")
                                .font(.cinema(14, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)
                            Text("Videos, posters, new listings, closings and reviews post here on their own.")
                                .font(.cinema(12))
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                    .tint(Theme.red)
                    .cardStyle()

                    Picker("View", selection: $tab) {
                        ForEach(Tab.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    switch tab {
                    case .feed: feed
                    case .roster: roster(team)
                    case .board: leaderboard(team)
                    }

                    Button(store.isTeamLeader ? "Close this team" : "Leave team", role: .destructive) { confirmLeave = true }
                        .font(.cinema(13, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                } else {
                    noTeam
                }
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Team")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCreate) { CreateTeamView() }
        .sheet(isPresented: $showAddMember) { AddTeamMemberView() }
        .confirmationDialog(store.isTeamLeader ? "Close \(store.team?.name ?? "the team")?" : "Leave \(store.team?.name ?? "the team")?", isPresented: $confirmLeave, titleVisibility: .visible) {
            Button(store.isTeamLeader ? "Close team" : "Leave team", role: .destructive) { store.leaveTeam() }
        } message: {
            Text("Your content stops posting to the team page and lead hand offs are cleared. You can join again with a code.")
        }
        .onAppear { store.refreshTeamMonth() }
    }

    private func header(_ team: Team) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(team.name)
                .font(.cinema(26, weight: .heavy))
            Text(team.tagline)
                .font(.cinema(14, weight: .semibold))
                .opacity(0.9)
            HStack(spacing: 18) {
                stat("\(team.members.count)", store.lex.agentsTitle)
                stat("\(team.members.reduce(0) { $0 + $1.videosThisMonth })", "Videos this month")
                stat("\(team.members.reduce(0) { $0 + $1.closings })", "Closings")
            }
            .padding(.top, 4)
        }
        .foregroundStyle(.white)
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(store.brandKit.accent.gradient, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(value).font(.cinema(20, weight: .heavy))
            Text(label).font(.cinema(11, weight: .semibold)).opacity(0.85)
        }
    }

    private func leaderTools(_ team: Team) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(store.lex.teamLeader) tools")
                .font(.cinema(15, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            HStack(spacing: 10) {
                ShareLink(item: "Join \(team.name) on #Cinema! Code \(team.joinCode): \(team.joinLink)") {
                    Label("Invite", systemImage: "person.badge.plus")
                }
                .buttonStyle(SecondaryButtonStyle())
                NavigationLink(value: Route.recruit) {
                    Label("Recruiting page", systemImage: "megaphone.fill")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            Toggle(isOn: Binding(get: { team.leadRoutingOn }, set: { store.setLeadRouting($0) })) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Share team marketing leads round robin")
                        .font(.cinema(14, weight: .semibold))
                    Text("New leads from team marketing go to the next \(store.lex.agents.dropLast()) in line.")
                        .font(.cinema(12))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .tint(Theme.red)
            Button {
                showAddMember = true
            } label: {
                Label("Add a member", systemImage: "plus")
                    .font(.cinema(14, weight: .semibold))
                    .foregroundStyle(Theme.red)
            }
            Text("Join code: \(team.joinCode)")
                .font(.cinema(12, weight: .semibold))
                .foregroundStyle(Theme.textTertiary)
        }
        .foregroundStyle(Theme.textPrimary)
        .cardStyle()
    }

    private var feed: some View {
        VStack(alignment: .leading, spacing: 12) {
            if store.teamFeed.isEmpty {
                Text("Nothing yet. Post a video or add a listing and it shows up here.")
                    .font(.cinema(14))
                    .foregroundStyle(Theme.textSecondary)
                    .cardStyle()
            }
            ForEach(store.teamFeed.sorted { $0.date > $1.date }) { item in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        Image(systemName: item.kind.icon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.red)
                            .frame(width: 32, height: 32)
                            .background(Theme.redSoft, in: Circle())
                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.authorName)
                                .font(.cinema(14, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)
                            Text(item.date.relative)
                                .font(.cinema(11))
                                .foregroundStyle(Theme.textTertiary)
                        }
                        Spacer()
                    }
                    Text(item.title)
                        .font(.cinema(15, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    if !item.detail.isEmpty {
                        Text(item.detail)
                            .font(.cinema(13))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    HStack(spacing: 18) {
                        Button {
                            store.cheer(item.id)
                        } label: {
                            Label("\(item.cheers)", systemImage: item.cheeredByMe ? "hands.clap.fill" : "hands.clap")
                        }
                        ShareLink(item: "\(item.authorName) on \(store.team?.name ?? "our team"): \(item.title)") {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                    }
                    .font(.cinema(13, weight: .semibold))
                    .foregroundStyle(Theme.red)
                    .buttonStyle(.plain)
                }
                .cardStyle()
            }
        }
    }

    private func roster(_ team: Team) -> some View {
        VStack(spacing: 10) {
            ForEach(team.members) { member in
                HStack(spacing: 12) {
                    Avatar(initials: member.initials, size: 40, paletteIndex: member.name.count)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(member.name + (member.isMe ? " (you)" : ""))
                            .font(.cinema(15, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Text("\(member.role.title(store.lex)) · joined \(member.joinedAt.formatted(.dateTime.month(.abbreviated).year()))")
                            .font(.cinema(12))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    if member.role == .newAgent {
                        Pill(text: "New", color: Theme.redSoft, textColor: Theme.red)
                    }
                }
                .cardStyle(padding: 12)
                .contextMenu {
                    if store.isTeamLeader && !member.isMe {
                        Button(role: .destructive) {
                            store.removeTeamMember(member.id)
                        } label: {
                            Label("Remove from team", systemImage: "person.badge.minus")
                        }
                    }
                }
            }
        }
    }

    private func leaderboard(_ team: Team) -> some View {
        VStack(spacing: 10) {
            ForEach(Array(team.members.sorted { ($0.videosThisMonth * 2 + $0.leads + $0.closings * 10) > ($1.videosThisMonth * 2 + $1.leads + $1.closings * 10) }.enumerated()), id: \.element.id) { rank, member in
                HStack(spacing: 12) {
                    Text("\(rank + 1)")
                        .font(.cinema(16, weight: .heavy))
                        .foregroundStyle(rank < 3 ? Theme.red : Theme.textTertiary)
                        .frame(width: 26)
                    Text(member.name)
                        .font(.cinema(15, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("\(member.videosThisMonth) videos · \(member.leads) leads")
                            .font(.cinema(12, weight: .semibold))
                            .foregroundStyle(Theme.textSecondary)
                        Text("\(member.closings) closings")
                            .font(.cinema(11))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
                .cardStyle(padding: 12)
            }
            Text("Score: 2 points a video, 1 a lead, 10 a closing.")
                .font(.cinema(11))
                .foregroundStyle(Theme.textTertiary)
        }
    }

    private var noTeam: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Your team, in one place")
                    .font(.cinema(26, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text("Join your team and everything you make shows up on the team page: videos, posters, listings, closings and reviews.")
                    .font(.cinema(14))
                    .foregroundStyle(Theme.textSecondary)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Have a team code?")
                    .font(.cinema(15, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                HStack(spacing: 10) {
                    TextField("Team code", text: $code)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .inputStyle()
                    Button("Join") {
                        if store.joinTeam(code: code) { code = "" }
                    }
                    .buttonStyle(PrimaryButtonStyle(fullWidth: false))
                    .disabled(code.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                Text("Demo: try code BAYTEAM.")
                    .font(.cinema(11))
                    .foregroundStyle(Theme.textTertiary)
            }
            .cardStyle()
            Button {
                showCreate = true
            } label: {
                Label("I lead a team. Start it here", systemImage: "person.3.fill")
            }
            .buttonStyle(SecondaryButtonStyle())
        }
    }
}

struct CreateTeamView: View {
    @Environment(CinemaStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var tagline = "Local experts. Real results."

    var body: some View {
        NavigationStack {
            Form {
                TextField("Team name, like The Bay Home Team", text: $name)
                TextField("Tagline", text: $tagline)
                Section {
                    Text("You'll get a join code to share. Team pages are free for \(store.lex.teamLeaders).")
                        .font(.cinema(13))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .navigationTitle("Start a team")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        store.createTeam(name: name.trimmingCharacters(in: .whitespaces), tagline: tagline)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

struct AddTeamMemberView: View {
    @Environment(CinemaStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var role: TeamMember.Role = .agent

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                    .textContentType(.name)
                Picker("Role", selection: $role) {
                    ForEach(TeamMember.Role.allCases.filter { $0 != .leader }) { Text($0.title(store.lex)).tag($0) }
                }
                Section {
                    Text("Or send them the invite with your join code so they set up their own account.")
                        .font(.cinema(13))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .navigationTitle("Add a member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        store.addTeamMember(TeamMember(name: name.trimmingCharacters(in: .whitespaces), role: role))
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
