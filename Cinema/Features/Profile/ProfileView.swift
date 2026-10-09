import SwiftUI

struct ProfileView: View {
    @Environment(CinemaStore.self) private var store

    var body: some View {
        NavigationStack {
            List {
                Section {
                    header
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                }

                Section("Grow") {
                    NavigationLink(value: Route.leads) {
                        IconRow(icon: "person.badge.plus", title: "Leads", subtitle: "From comment keywords", badge: store.newLeadCount > 0 ? "\(store.newLeadCount) new" : nil)
                    }
                    NavigationLink(value: Route.coach) {
                        IconRow(icon: "graduationcap.fill", title: "Coach", subtitle: "Weekly report and skill path")
                    }
                    NavigationLink(value: Route.courses) {
                        IconRow(icon: "play.rectangle.on.rectangle.fill", title: "Courses", subtitle: "\(store.courses.filter { $0.isOwned }.count) enrolled")
                    }
                    NavigationLink(value: Route.challenges) {
                        IconRow(icon: "flag.checkered", title: "Challenges", subtitle: "\(store.joinedChallenges.count) active")
                    }
                }
                .listRowBackground(Theme.surface)

                Section("Content") {
                    NavigationLink(value: Route.calendar) {
                        IconRow(icon: "calendar", title: "Content calendar", subtitle: "Scheduled and posted")
                    }
                    NavigationLink(value: Route.bookings) {
                        IconRow(icon: "camera.fill", title: "Pro shoots", subtitle: "\(store.upcomingBookings.count) upcoming")
                    }
                }
                .listRowBackground(Theme.surface)

                Section {
                    ForEach(SocialPlatform.allCases) { platform in
                        HStack(spacing: 12) {
                            Image(systemName: platform.icon)
                                .foregroundStyle(Theme.red)
                                .frame(width: 26)
                            Text(platform.name)
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            if store.connectedPlatforms.contains(platform) {
                                Button("Disconnect") { store.disconnect(platform) }
                                    .foregroundStyle(Theme.textSecondary)
                            } else {
                                Button("Connect") { store.connect(platform) }
                                    .foregroundStyle(Theme.red)
                            }
                        }
                        .font(.cinema(15, weight: .medium))
                        .buttonStyle(.borderless)
                    }
                } header: {
                    Text("Connected accounts")
                } footer: {
                    Text("Instagram needs a Business or Creator account. Facebook posts to a Page.")
                }
                .listRowBackground(Theme.surface)

                Section("Account") {
                    NavigationLink(value: Route.plans) {
                        IconRow(icon: "crown.fill", title: "Plan and credits", subtitle: "\(store.profile.plan.name) · \(store.profile.credits) credits left")
                    }
                    if store.profile.role != .agent {
                        NavigationLink(value: Route.brokerage) {
                            IconRow(icon: "building.2.fill", title: store.profile.role == .teamLead ? "Team dashboard" : "Brokerage dashboard", subtitle: "Seats, brand kit, reports")
                        }
                    } else {
                        NavigationLink(value: Route.brokerage) {
                            IconRow(icon: "building.2.fill", title: "Brokerage dashboard", subtitle: "Preview the admin view")
                        }
                    }
                    Button(role: .destructive) {
                        store.signOut()
                    } label: {
                        Text("Sign out")
                    }
                }
                .listRowBackground(Theme.surface)
            }
            .cinemaScreen()
            .navigationTitle("Me")
            .cinemaDestinations()
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Avatar(initials: store.profile.initials, size: 64)
            VStack(alignment: .leading, spacing: 4) {
                Text(store.profile.name)
                    .font(.cinema(22, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text("\(store.profile.brokerage) · \(store.profile.market)")
                    .font(.cinema(13))
                    .foregroundStyle(Theme.textSecondary)
                HStack(spacing: 6) {
                    Pill(text: store.profile.plan.name, icon: "crown.fill", color: Theme.red, textColor: .white)
                    Pill(text: "\(store.profile.streakDays) day streak", icon: "flame.fill")
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
    }
}

struct PlansView: View {
    @Environment(CinemaStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(store.profile.credits)")
                            .font(.cinema(40, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                        Text("edit credits left this month")
                            .font(.cinema(14))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    Button("+5 credits · $150") { store.buyCreditPack(5) }
                        .buttonStyle(PrimaryButtonStyle(fullWidth: false))
                }
                .cardStyle()

                Text("Instant edit (AI) is 1 credit. Pro edit (AI plus editor) is 2. Rush adds 1.")
                    .font(.cinema(13))
                    .foregroundStyle(Theme.textTertiary)

                ForEach([Plan.starter, .creator, .pro]) { plan in
                    PlanCard(plan: plan, isSelected: store.profile.plan == plan) {
                        store.changePlan(to: plan)
                    }
                }

                Text("Payments run through Stripe on the web. Brokerage seats are billed to your broker.")
                    .font(.cinema(12))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Plan")
    }
}
