import SwiftUI

/// Free for team leads, market center leaders and admins: promote the
/// brokerage, office or team, spotlight agents, and recruit.
struct PromoteView: View {
    @Environment(CinemaStore.self) private var store

    @State private var tagline = "Tampa Bay's most connected real estate office."
    @State private var hiring = true
    @State private var kind: PromoKind = .teamWin
    @State private var text = ""
    @State private var alsoToSocials = true
    @State private var identity: PostingIdentity = .office

    enum PromoKind: String, CaseIterable, Identifiable {
        case teamWin = "Team win"
        case recruiting = "Recruiting"
        case event = "Office event"

        var id: String { rawValue }

        var postKind: CommunityPostKind {
            switch self {
            case .teamWin: return .win
            case .recruiting: return .lesson
            case .event: return .idea
            }
        }

        var placeholder: String {
            switch self {
            case .teamWin: return "Celebrate a closing, a record month or a milestone..."
            case .recruiting: return "Why agents love working here, and who you're looking for..."
            case .event: return "Training, open house tour, happy hour. Date, time and where..."
            }
        }

        var starter: String {
            switch self {
            case .teamWin: return "Huge month for our team: 14 closings and 3 new listings. Proud of every agent who showed up on camera this month."
            case .recruiting: return "We're growing. Every agent here gets a content team: daily ideas, edited videos and pro shoots through #Cinema. DM us to learn more."
            case .event: return "Content day at the office this Thursday at 10 AM. Bring your phone, we'll film 4 videos each and send them to editing."
            }
        }
    }

    private var org: String { store.profile.role.orgWord(store.lex) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                showcase
                NavigationLink(value: Route.officeContent) {
                    IconRow(icon: "arrow.triangle.2.circlepath", title: "Remix agent content", subtitle: "\(store.officeAssets.count) listing videos, photos and posters shared by your agents")
                        .cardStyle()
                }
                .buttonStyle(.plain)
                spotlightSection
                composer
                recentSection
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Promote")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if !store.postingIdentities.contains(identity), let first = store.postingIdentities.last {
                identity = first
            }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Promote your \(org)")
                    .font(.cinema(26, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Pill(text: "Free for leaders", icon: "checkmark.seal.fill", color: Theme.red, textColor: .white)
            }
            Text("Show off your agents, celebrate wins and recruit. Featured posts reach agents across the #Cinema community. Still selling? Post as yourself too.")
                .font(.cinema(15))
                .foregroundStyle(Theme.textSecondary)
        }
    }

    // MARK: Showcase

    private var showcase: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Your showcase page")

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 52)
                        .background(Theme.red, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(store.profile.brokerage)
                            .font(.cinema(18, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                        Text("\(store.profile.market) · \(store.brokerageMembers.count) agents on #Cinema")
                            .font(.cinema(13))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer(minLength: 0)
                }

                TextField("Tagline", text: $tagline)
                    .inputStyle()

                Toggle(isOn: $hiring) {
                    Label("Show \"Now hiring agents\"", systemImage: "person.badge.plus")
                        .font(.cinema(15, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                }
                .tint(Theme.red)

                HStack(spacing: 8) {
                    Pill(text: "\(store.brokerageMembers.reduce(0) { $0 + $1.postsThisMonth }) videos this month", icon: "video.fill")
                    if hiring {
                        Pill(text: "Now hiring", icon: "sparkles", color: Theme.redSoft, textColor: Theme.red)
                    }
                }

                Button("Publish showcase") {
                    store.showToast("Showcase is live in Community")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .cardStyle()
        }
    }

    // MARK: Spotlight

    private var spotlightSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Spotlight an agent")
            Text("A featured post that celebrates one of your agents. They get the shout out, you get the recruiting proof.")
                .font(.cinema(13))
                .foregroundStyle(Theme.textSecondary)

            ForEach(store.brokerageMembers.filter { $0.postsThisMonth > 0 }.sorted { $0.postsThisMonth > $1.postsThisMonth }) { member in
                HStack(spacing: 12) {
                    Avatar(initials: initials(member.name), size: 40, paletteIndex: member.name.count)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(member.name)
                            .font(.cinema(15, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Text("\(member.postsThisMonth) videos · \(member.leads) leads this month")
                            .font(.cinema(12))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    Button("Spotlight") { store.spotlight(member) }
                        .font(.cinema(13, weight: .semibold))
                        .foregroundStyle(Theme.red)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Theme.redSoft, in: Capsule())
                        .buttonStyle(.plain)
                }
                .cardStyle(padding: 12)
            }
        }
    }

    // MARK: Composer

    private var composer: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Post for your \(org)")

            if store.postingIdentities.count > 1 {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Post as")
                        .font(.cinema(13, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                    Picker("Post as", selection: $identity) {
                        ForEach(store.postingIdentities) { option in
                            Text(option == .me ? "Me" : store.identityName(option)).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    if identity == .me {
                        Text("Posting as yourself goes to your own socials, so you still market your listings while you lead.")
                            .font(.cinema(12))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
            }

            Picker("Type", selection: $kind) {
                ForEach(PromoKind.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)

            TextField(kind.placeholder, text: $text, axis: .vertical)
                .lineLimit(4...8)
                .inputStyle()

            HStack {
                Button {
                    text = kind.starter
                } label: {
                    Label("Write it for me", systemImage: "sparkles")
                        .font(.cinema(14, weight: .semibold))
                }
                .foregroundStyle(Theme.red)
                Spacer()
            }

            Toggle(isOn: $alsoToSocials) {
                Text(identity == .me ? "Also post to my connected socials" : "Also post to the \(org)'s connected socials")
                    .font(.cinema(14))
                    .foregroundStyle(Theme.textPrimary)
            }
            .tint(Theme.red)

            Button {
                let body = text.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !body.isEmpty else { return }
                store.promote(kind: kind.postKind, body: body, alsoToSocials: alsoToSocials, as: identity)
                text = ""
            } label: {
                Label("Feature it", systemImage: "megaphone.fill")
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
        }
    }

    // MARK: Recent

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !store.promotions.isEmpty {
                SectionHeader(title: "Your featured posts")
                ForEach(store.promotions) { post in
                    CommunityPostCard(post: post)
                }
            }
        }
    }

    private func initials(_ name: String) -> String {
        String(name.split(separator: " ").prefix(2).compactMap { $0.first }).uppercased()
    }
}
