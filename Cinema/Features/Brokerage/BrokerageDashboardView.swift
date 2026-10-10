import SwiftUI

struct BrokerageDashboardView: View {
    @Environment(CinemaStore.self) private var store
    @State private var creditPool = 40
    @State private var seats = 25
    @State private var showChallenge = false
    @State private var showAnnouncement = false

    private var activeAgents: Int { store.brokerageMembers.filter { $0.postsThisMonth > 0 }.count }
    private var totalPosts: Int { store.brokerageMembers.reduce(0) { $0 + $1.postsThisMonth } }
    private var totalLeads: Int { store.brokerageMembers.reduce(0) { $0 + $1.leads } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(store.profile.brokerage)
                        .font(.cinema(24, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("\(store.brokerageMembers.count) of \(seats) seats used")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    StatTile(value: "\(activeAgents)", label: "Agents posting", icon: "person.2.fill")
                    StatTile(value: "\(totalPosts)", label: "Posts this month", icon: "paperplane.fill")
                    StatTile(value: "\(totalLeads)", label: "Leads from video", icon: "person.badge.plus")
                    StatTile(value: "\(creditPool)", label: "Credits in pool", icon: "ticket.fill")
                }

                Button {
                    showAnnouncement = true
                } label: {
                    Label("Post an announcement", systemImage: "megaphone.fill")
                }
                .buttonStyle(PrimaryButtonStyle())

                SectionHeader(title: "Agents")
                VStack(spacing: 0) {
                    HStack {
                        Text("Agent").frame(maxWidth: .infinity, alignment: .leading)
                        Text("Posts").frame(width: 50)
                        Text("Days").frame(width: 50)
                        Text("Leads").frame(width: 50)
                    }
                    .font(.cinema(12, weight: .bold))
                    .foregroundStyle(Theme.textTertiary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)

                    ForEach(store.brokerageMembers.sorted { $0.postsThisMonth > $1.postsThisMonth }) { member in
                        Divider().overlay(Theme.stroke)
                        HStack {
                            HStack(spacing: 8) {
                                if member.postsThisMonth == 0 {
                                    Circle().fill(Theme.warning).frame(width: 7, height: 7)
                                }
                                Text(member.name)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            Text("\(member.postsThisMonth)").frame(width: 50)
                            Text("\(member.challengeDays)").frame(width: 50)
                            Text("\(member.leads)").frame(width: 50)
                        }
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                        .contextMenu {
                            if member.postsThisMonth == 0 {
                                ShareLink(item: "Hey \(member.name.split(separator: " ").first.map(String.init) ?? member.name)! Haven't seen a video from you this month. Open CloseUp, today's idea takes 60 seconds to film. I'll share it with the office!") {
                                    Label("Nudge \(member.name)", systemImage: "hand.wave.fill")
                                }
                            } else {
                                ShareLink(item: "Great work on your videos this month, \(member.name.split(separator: " ").first.map(String.init) ?? member.name)! Keep it going.") {
                                    Label("Cheer on \(member.name)", systemImage: "hands.clap.fill")
                                }
                            }
                        }
                    }
                }
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))

                Text("Orange dot: hasn't posted this month. Press and hold an agent to send a nudge, or invite them to the office challenge.")
                    .font(.cinema(12))
                    .foregroundStyle(Theme.textTertiary)

                SectionHeader(title: "Brand kit")
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        ForEach([Theme.red, Color.white, Color(hex: 0x1F1F24)], id: \.self) { color in
                            RoundedRectangle(cornerRadius: 8)
                                .fill(color)
                                .frame(width: 44, height: 44)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.stroke, lineWidth: 1))
                        }
                        Spacer()
                    }
                    Label("Logo, colors and fonts on every edit", systemImage: "paintbrush.fill")
                    Label("Required disclaimer: brokerage name and license", systemImage: "text.badge.checkmark")
                }
                .font(.cinema(14))
                .foregroundStyle(Theme.textSecondary)
                .cardStyle()

                SectionHeader(title: "Shared credit pool")
                VStack(alignment: .leading, spacing: 12) {
                    Stepper("\(creditPool) credits", value: $creditPool, in: 0...500, step: 10)
                        .foregroundStyle(Theme.textPrimary)
                    Text("Agents draw from the pool after their own credits run out. Cap: 4 per agent per month.")
                        .font(.cinema(12))
                        .foregroundStyle(Theme.textTertiary)
                }
                .cardStyle()

                VStack(spacing: 10) {
                    NavigationLink(value: Route.promote) {
                        Label("Promote your office and agents", systemImage: "megaphone.fill")
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button {
                        showChallenge = true
                    } label: {
                        Label("Launch an office challenge", systemImage: "flag.checkered")
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    Button {
                        store.showToast("Invite link copied")
                    } label: {
                        Label("Invite agents", systemImage: "person.crop.circle.badge.plus")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Brokerage")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showChallenge) {
            CreateChallengeView()
        }
        .sheet(isPresented: $showAnnouncement) {
            ComposeAnnouncementView()
        }
    }
}
