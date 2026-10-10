import SwiftUI

struct ProfileView: View {
    @Environment(CinemaStore.self) private var store
    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    header
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                }

                if let partner = store.partner {
                    Section {
                        NavigationLink(value: Route.marketCenter) {
                            HStack(spacing: 14) {
                                Text(partner.shortName)
                                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                                    .foregroundStyle(.white)
                                    .frame(width: 34, height: 34)
                                    .background(Theme.red, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(store.profile.email)
                                        .font(.cinema(15, weight: .semibold))
                                        .foregroundStyle(Theme.textPrimary)
                                    Text(store.myMarketCenter.map { "\($0.name) · \(store.profile.membership.title)" } ?? "Connect your \(partner.officeWord)")
                                        .font(.cinema(12))
                                        .foregroundStyle(store.profile.membership == .approved ? Theme.textSecondary : Theme.red)
                                }
                            }
                        }
                    } header: {
                        Text(partner.name)
                    } footer: {
                        Text("\(partner.signupDiscountPercent)% off every plan and credit pack is applied.")
                    }
                    .listRowBackground(Theme.surface)
                }

                if store.isLeader {
                    Section {
                        NavigationLink(value: Route.promote) {
                            IconRow(icon: "megaphone.fill", title: "Promote your \(store.profile.role.orgWord(store.lex))", subtitle: store.profile.alsoSells ? "Post as you, your team or your office" : "Showcase, agent spotlights, recruiting", badge: "Free")
                        }
                        NavigationLink(value: Route.officeContent) {
                            IconRow(icon: "arrow.triangle.2.circlepath", title: "Office content pool", subtitle: "Remix your agents' listing content")
                        }
                        if store.partner == nil {
                            NavigationLink(value: Route.marketCenter) {
                                IconRow(icon: "building.2.crop.circle", title: "Join requests and revenue share", subtitle: "\(store.joinRequests.count) waiting")
                            }
                        }
                    } header: {
                        Text("Leader tools")
                    } footer: {
                        Text("Free for \(store.lex.leadersList).")
                    }
                    .listRowBackground(Theme.surface)
                }

                Section("Grow") {
                    NavigationLink(value: Route.whatsNew) {
                        IconRow(icon: "sparkles", title: "What's new", subtitle: "The latest tools, one tap to try each")
                    }
                    NavigationLink(value: Route.launchpad) {
                        IconRow(icon: "airplane.departure", title: store.isNewAgent ? "Launchpad" : "I'm a brand new agent", subtitle: store.isNewAgent ? "Day \(store.launchpad.dayNumber) of 90 · \(store.launchpad.done.count) steps done" : "A 90 day plan to your first closing")
                    }
                    NavigationLink(value: Route.team) {
                        IconRow(icon: "person.3.fill", title: store.team?.name ?? "My team", subtitle: store.team == nil ? "Join your team or start one" : "\(store.team?.members.count ?? 0) \(store.lex.agents) · your content posts here")
                    }
                    NavigationLink(value: Route.money) {
                        IconRow(icon: "banknote.fill", title: "My money", subtitle: "GCI, split and cap, taxes and write offs")
                    }
                    NavigationLink(value: Route.expenses) {
                        IconRow(icon: "car.fill", title: "Mileage and expenses", subtitle: "Log trips and costs, export for taxes")
                    }
                    NavigationLink(value: Route.businessPlan) {
                        IconRow(icon: "target", title: "Business plan", subtitle: "Your income goal, worked back to videos a week")
                    }
                    NavigationLink(value: Route.insights) {
                        IconRow(icon: "chart.xyaxis.line", title: "Insights", subtitle: "Views, best days to post and top topics")
                    }
                    NavigationLink(value: Route.achievements) {
                        IconRow(icon: store.creatorLevel.icon, title: "Achievements", subtitle: "\(store.creatorLevel.title) · \(store.achievements.filter(\.isUnlocked).count) badges")
                    }
                    NavigationLink(value: Route.weekPlan) {
                        IconRow(icon: "calendar.badge.plus", title: "Plan my week", subtitle: store.weekPlan.isEmpty ? "\(store.profile.weeklyGoal) videos, planned for you" : "\(store.weekPlanDone) of \(store.weekPlan.count) filmed")
                    }
                    NavigationLink(value: Route.activity) {
                        IconRow(icon: "bell.badge.fill", title: "Activity", subtitle: "Edits, leads, bookings and rewards", badge: store.unreadActivityCount > 0 ? "\(store.unreadActivityCount) new" : nil)
                    }
                    NavigationLink(value: Route.pastClients) {
                        IconRow(icon: "house.and.flag.fill", title: "Past clients", subtitle: "Home anniversaries and value check-ins")
                    }
                    NavigationLink(value: Route.vendors) {
                        IconRow(icon: "person.2.badge.gearshape.fill", title: "Trusted pros", subtitle: "Your lenders, inspectors and more")
                    }
                    NavigationLink(value: Route.referralNetwork) {
                        IconRow(icon: "arrow.triangle.branch", title: "Agent referrals", subtitle: "Send clients to agents in other cities")
                    }
                    NavigationLink(value: Route.referrals) {
                        IconRow(icon: "gift.fill", title: "Invite agents", subtitle: "Give 2 edits, get 2 edits", badge: store.creditsEarnedFromReferrals > 0 ? "+\(store.creditsEarnedFromReferrals)" : nil)
                    }
                    NavigationLink(value: Route.market) {
                        IconRow(icon: "mappin.and.ellipse", title: "My market", subtitle: store.serviceAreas.isEmpty ? store.homeCity.displayName : "\(store.homeCity.name) plus \(store.serviceAreas.count) more")
                    }
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
                    NavigationLink(value: Route.brandKit) {
                        IconRow(icon: "paintpalette.fill", title: "Brand kit", subtitle: store.brandKit.completion >= 3 ? "Headshot, logo and color on every poster" : "Add your headshot, logo and color")
                    }
                    NavigationLink(value: Route.testimonials) {
                        IconRow(icon: "heart.text.square.fill", title: "Testimonials", subtitle: "\(store.testimonials.count) saved. Ask, share, make videos")
                    }
                    NavigationLink(value: Route.listingPitch) {
                        IconRow(icon: "doc.richtext.fill", title: "Listing presentation", subtitle: "Your marketing plan as a PDF for sellers")
                    }
                    NavigationLink(value: Route.sellerPrep) {
                        IconRow(icon: "checklist", title: "Seller prep checklist", subtitle: "Send before the shoot")
                    }
                    NavigationLink(value: Route.linkInBio) {
                        IconRow(icon: "link.circle.fill", title: "Link in bio", subtitle: "One link for your Instagram and TikTok")
                    }
                    NavigationLink(value: Route.captionWriter) {
                        IconRow(icon: "text.bubble.fill", title: "Caption writer", subtitle: "Captions and hashtags for \(store.homeCity.name)")
                    }
                    NavigationLink(value: Route.teleprompter) {
                        IconRow(icon: "text.viewfinder", title: "Teleprompter", subtitle: "Film your own script")
                    }
                    NavigationLink(value: Route.greetings) {
                        IconRow(icon: "gift.fill", title: "Holiday posts", subtitle: "Branded greetings, coming up first")
                    }
                    NavigationLink(value: Route.hooks) {
                        IconRow(icon: "bolt.fill", title: "Hook library", subtitle: "Proven first lines for your videos")
                    }
                    NavigationLink(value: Route.marketUpdate) {
                        IconRow(icon: "chart.bar.xaxis", title: "Market update graphic", subtitle: "Your numbers, branded, with a script")
                    }
                    NavigationLink(value: Route.listings) {
                        IconRow(icon: "house.and.flag.fill", title: "My listings", subtitle: "\(store.listings.filter { $0.status != .sold }.count) active · marketing plans and open houses")
                    }
                    NavigationLink(value: Route.paymentCalculator) {
                        IconRow(icon: "function", title: "Payment calculator", subtitle: "Shareable monthly payment graphic")
                    }
                    NavigationLink(value: Route.posterMaker) {
                        IconRow(icon: "rectangle.portrait.on.rectangle.portrait.fill", title: "Poster maker", subtitle: "Just listed, just sold, open house and more")
                    }
                    NavigationLink(value: Route.calendar) {
                        IconRow(icon: "calendar", title: "Content calendar", subtitle: "Scheduled and posted")
                    }
                    NavigationLink(value: Route.findShooter) {
                        IconRow(icon: "person.crop.rectangle.stack.fill", title: "Find a photographer", subtitle: "Vetted #Cinema Crew near \(store.homeCity.name)")
                    }
                    NavigationLink(value: Route.partners) {
                        IconRow(icon: "hammer.fill", title: "Partners", subtitle: "Stagers, cleaners, movers, TCs and more")
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

                Section {
                    NavigationLink(value: store.crewApplication == nil ? Route.joinCrew : Route.crewDashboard) {
                        IconRow(icon: "camera.badge.ellipsis", title: store.crewApplication == nil ? "Join #Cinema Crew" : "Crew dashboard", subtitle: store.crewApplication == nil ? "For photographers and videographers" : "Application under review")
                    }
                } header: {
                    Text("#Cinema Crew")
                }
                .listRowBackground(Theme.surface)

                Section("Account") {
                    NavigationLink(value: Route.reminders) {
                        IconRow(icon: "bell.badge.fill", title: "Reminders", subtitle: store.reminderEnabled ? "Daily idea at \(ReminderScheduler.label(hour: store.reminderHour, minute: store.reminderMinute))" : "Off")
                    }
                    NavigationLink(value: Route.help) {
                        IconRow(icon: "questionmark.circle.fill", title: "How #Cinema works", subtitle: "Steps, credits and answers")
                    }
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

                Section {
                    if let privacy = URL(string: "https://hashtagcinema.com/privacy") {
                        Link("Privacy policy", destination: privacy)
                    }
                    if let terms = URL(string: "https://hashtagcinema.com/terms") {
                        Link("Terms of use", destination: terms)
                    }
                    Button("Delete my account", role: .destructive) {
                        confirmDelete = true
                    }
                } footer: {
                    Text("Deleting removes your profile, ideas, clips, leads and settings. Stripe keeps its own payment receipts.")
                }
                .listRowBackground(Theme.surface)
            }
            .cinemaScreen()
            .navigationTitle("Me")
            .confirmationDialog("Delete your #Cinema account?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete account", role: .destructive) {
                    Task { await store.deleteAccount() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This can't be undone.")
            }
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
                    Button("+5 credits · \((150 * Double(100 - store.discountPercent) / 100).formatted(.currency(code: "USD").precision(.fractionLength(0))))") { store.buyCreditPack(5) }
                        .buttonStyle(PrimaryButtonStyle(fullWidth: false))
                }
                .cardStyle()

                Text("Instant edit (AI) is 1 credit. Pro edit (AI plus editor) is 2. Rush adds 1.")
                    .font(.cinema(13))
                    .foregroundStyle(Theme.textTertiary)

                if store.discountPercent > 0, let partner = store.partner {
                    Label("\(partner.name): \(store.discountPercent)% off is applied", systemImage: "tag.fill")
                        .font(.cinema(14, weight: .semibold))
                        .foregroundStyle(Theme.red)
                }
                if store.isLeader {
                    PlanCard(plan: .leader, isSelected: store.profile.plan == .leader) {
                        store.changePlan(to: .leader)
                    }
                    Text("Your leader account is free. Agents on your \(store.profile.role.orgWord(store.lex)) pick their own plans or use brokerage seats.")
                        .font(.cinema(13))
                        .foregroundStyle(Theme.textTertiary)
                    if store.profile.alsoSells {
                        SectionHeader(title: "For your own listings")
                        Text("Selling too? Add a personal plan for more edit credits. Your leader tools stay free.")
                            .font(.cinema(13))
                            .foregroundStyle(Theme.textSecondary)
                        ForEach([Plan.creator, .pro]) { plan in
                            PlanCard(plan: plan, isSelected: store.profile.plan == plan, discountPercent: store.discountPercent) {
                                store.changePlan(to: plan)
                            }
                        }
                    }
                } else {
                    ForEach([Plan.starter, .creator, .pro]) { plan in
                        PlanCard(plan: plan, isSelected: store.profile.plan == plan, discountPercent: store.discountPercent) {
                            store.changePlan(to: plan)
                        }
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
