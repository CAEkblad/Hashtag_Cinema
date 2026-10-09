import SwiftUI

/// A dated marketing countdown for one listing, from the shoot to the first seller report.
struct LaunchPlanView: View {
    @Environment(CinemaStore.self) private var store
    let listingID: UUID
    @State private var remindersOn = false
    @State private var didLoad = false

    private var remindersKey: String { "cinema.launch.reminders.\(listingID.uuidString)" }

    enum Tool {
        case bookings, poster, shotList, reel, neighbors, openHouse, sellerReport, netSheet
    }

    struct Step: Identifiable {
        var id: String { title }
        var offset: Int
        var title: String
        var detail: String
        var icon: String
        var task: MarketingTask?
        var tool: Tool
    }

    static let steps: [Step] = [
        Step(offset: -5, title: "Book the shoot", detail: "Photos, video and drone, delivered before you go live.", icon: "camera.fill", task: .bookShoot, tool: .bookings),
        Step(offset: -3, title: "Coming soon poster", detail: "Tease it to your sphere before the portals have it.", icon: "clock.fill", task: .comingSoonPoster, tool: .poster),
        Step(offset: -2, title: "Film the sneak peek", detail: "Use the shot list. 20 seconds on your phone is enough.", icon: "video.fill", task: .listingVideo, tool: .shotList),
        Step(offset: 0, title: "Just listed reel", detail: "Turn the pro photos into a vertical video and post it everywhere.", icon: "film.stack.fill", task: .socialPost, tool: .reel),
        Step(offset: 0, title: "Just listed poster", detail: "For your story, Facebook groups and the office.", icon: "rectangle.portrait.on.rectangle.portrait.fill", task: .justListedPoster, tool: .poster),
        Step(offset: 1, title: "Invite the neighbors", detail: "Neighbors know the next buyer, and the next seller.", icon: "envelope.open.fill", task: nil, tool: .neighbors),
        Step(offset: 3, title: "Hold the open house", detail: "QR sign in turns every visitor into a lead.", icon: "door.left.hand.open", task: .openHouse, tool: .openHouse),
        Step(offset: 7, title: "First seller report", detail: "Days on market, visitors and buyer feedback in one text.", icon: "chart.bar.doc.horizontal.fill", task: nil, tool: .sellerReport),
        Step(offset: 14, title: "Price check", detail: "No offers yet? Run the net sheet before you talk price.", icon: "dollarsign.circle.fill", task: nil, tool: .netSheet)
    ]

    var body: some View {
        if let listing = store.listing(listingID) {
            content(listing)
        } else {
            EmptyStateView(title: "Listing not found", message: "It may have been removed.", icon: "house")
                .cinemaScreen()
        }
    }

    private func date(_ step: Step, _ listing: Listing) -> Date {
        Calendar.current.date(byAdding: .day, value: step.offset, to: listing.listedAt) ?? listing.listedAt
    }

    private func content(_ listing: Listing) -> some View {
        let doneCount = Self.steps.filter { step in step.task.map { listing.done.contains($0) } ?? false }.count
        let trackable = Self.steps.filter { $0.task != nil }.count
        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Launch plan")
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("\(listing.address). Every step dated from go live day, with the tool to do it one tap away.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                VStack(alignment: .leading, spacing: 10) {
                    DatePicker("Go live day", selection: Binding(get: { listing.listedAt }, set: { newDate in
                        var updated = listing
                        updated.listedAt = newDate
                        store.updateListing(updated)
                        if remindersOn { scheduleReminders(updated, announce: false) }
                    }), displayedComponents: .date)
                    .font(.cinema(15, weight: .semibold))
                    ProgressView(value: Double(doneCount), total: Double(max(trackable, 1)))
                        .tint(Theme.red)
                    Toggle("Remind me the morning of each step", isOn: Binding(get: { remindersOn }, set: { on in
                        remindersOn = on
                        UserDefaults.standard.set(on, forKey: remindersKey)
                        if on { scheduleReminders(listing) } else { cancelReminders(listing) }
                    }))
                    .font(.cinema(14))
                    .tint(Theme.red)
                }
                .cardStyle()

                ForEach(Self.steps) { step in
                    stepRow(step, listing)
                }
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Launch plan")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard !didLoad else { return }
            didLoad = true
            remindersOn = UserDefaults.standard.bool(forKey: remindersKey)
        }
    }

    private func stepRow(_ step: Step, _ listing: Listing) -> some View {
        let isDone = step.task.map { listing.done.contains($0) } ?? false
        let when = date(step, listing)
        let isToday = Calendar.current.isDateInToday(when)
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                if let task = step.task {
                    Button {
                        store.toggleTask(task, for: listing.id)
                        if remindersOn, let updated = store.listing(listing.id) { scheduleReminders(updated, announce: false) }
                    } label: {
                        Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 24))
                            .foregroundStyle(isDone ? Theme.success : Theme.textTertiary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isDone ? "Mark not done" : "Mark done")
                } else {
                    Image(systemName: step.icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.red)
                        .frame(width: 24, height: 24)
                }
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(step.title)
                            .font(.cinema(15, weight: .semibold))
                            .foregroundStyle(isDone ? Theme.textSecondary : Theme.textPrimary)
                            .strikethrough(isDone)
                        Spacer()
                        Text(isToday ? "Today" : (step.offset == 0 ? "Go live" : when.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())))
                            .font(.cinema(12, weight: .bold))
                            .foregroundStyle(isToday ? Theme.red : Theme.textTertiary)
                    }
                    Text(step.detail)
                        .font(.cinema(13))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            if !isDone {
                toolLink(step, listing)
            }
        }
        .cardStyle()
    }

    @ViewBuilder
    private func toolLink(_ step: Step, _ listing: Listing) -> some View {
        let label = Label(buttonTitle(step.tool), systemImage: "arrow.right.circle.fill")
            .font(.cinema(13, weight: .semibold))
            .foregroundStyle(Theme.red)
        switch step.tool {
        case .bookings:
            NavigationLink(value: Route.bookings) { label }
        case .poster:
            NavigationLink(value: Route.listingPoster(listing.id)) { label }
        case .shotList:
            NavigationLink(value: Route.shotList(listing.id)) { label }
        case .reel:
            NavigationLink(value: Route.listingReel(listing.id)) { label }
        case .neighbors:
            if let openHouse = listing.openHouses.first {
                ShareLink(item: ListingCopywriter.neighborInvite(for: listing, openHouse: openHouse, agentName: store.profile.name)) { label }
            } else {
                Text("Schedule an open house on the listing first, then send the invite.")
                    .font(.cinema(12))
                    .foregroundStyle(Theme.textTertiary)
            }
        case .openHouse:
            NavigationLink(value: Route.listing(listing.id)) { label }
        case .sellerReport:
            NavigationLink(value: Route.sellerReport(listing.id)) { label }
        case .netSheet:
            NavigationLink(value: Route.listingNetSheet(listing.id)) { label }
        }
    }

    private func buttonTitle(_ tool: Tool) -> String {
        switch tool {
        case .bookings: return "Book it"
        case .poster: return "Make the poster"
        case .shotList: return "Open the shot list"
        case .reel: return "Make the reel"
        case .neighbors: return "Send the invite"
        case .openHouse: return "Schedule it on the listing"
        case .sellerReport: return "Write the report"
        case .netSheet: return "Open the net sheet"
        }
    }

    private func reminderID(_ step: Step, _ listing: Listing) -> String {
        let index = Self.steps.firstIndex { $0.title == step.title } ?? 0
        return "cinema.launch.\(listing.id.uuidString).\(index)"
    }

    private func scheduleReminders(_ listing: Listing, announce: Bool = true) {
        cancelReminders(listing)
        Task {
            guard await ReminderScheduler.requestPermission() else {
                store.showToast("Turn on notifications in Settings to get reminders")
                return
            }
            for step in Self.steps {
                if let task = step.task, listing.done.contains(task) { continue }
                await ReminderScheduler.scheduleOnce(id: reminderID(step, listing), title: "Today: \(step.title)", body: listing.address, on: date(step, listing))
            }
            if announce { store.showToast("Reminders set for the launch") }
        }
    }

    private func cancelReminders(_ listing: Listing) {
        ReminderScheduler.cancel(ids: Self.steps.map { reminderID($0, listing) })
    }
}
