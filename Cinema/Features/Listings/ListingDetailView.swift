import SwiftUI
import UIKit
import CoreImage.CIFilterBuiltins

struct ListingDetailView: View {
    @Environment(CinemaStore.self) private var store
    let listingID: UUID

    @State private var tone: ListingCopywriter.Tone = .warm
    @State private var showSchedule = false
    @State private var openHouseDate = Calendar.current.date(bySettingHour: 13, minute: 0, second: 0, of: Date().addingTimeInterval(86_400 * 2)) ?? Date()
    @State private var openHouseHours = 3
    @State private var kiosk: OpenHouse?
    @State private var showFlyer = false

    var body: some View {
        if let listing = store.listing(listingID) {
            content(listing)
        } else {
            EmptyStateView(title: "Listing not found", message: "It may have been removed.", icon: "house")
                .cinemaScreen()
        }
    }

    private func content(_ listing: Listing) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header(listing)
                NavigationLink(value: Route.listingPhotos(listing.id)) {
                    let count = ListingPhotoStore.count(listing.id)
                    IconRow(icon: "photo.stack.fill", title: count == 0 ? "Add listing photos" : "\(count) listing photo\(count == 1 ? "" : "s")", subtitle: count == 0 ? "Pull them from the MLS, Photos or Files" : listing.mlsNumber.map { "From MLS \($0) · used in reels, posters and flyers" } ?? "Used in reels, posters and flyers")
                        .cardStyle()
                }
                .buttonStyle(.plain)
                statusPicker(listing)
                if listing.status == .comingSoon || listing.status == .active {
                    NavigationLink(value: Route.launchPlan(listing.id)) {
                        IconRow(icon: "calendar.badge.clock", title: "Launch plan", subtitle: "Dated steps from the shoot to the first seller report")
                            .cardStyle()
                    }
                    .buttonStyle(.plain)
                }
                if listing.status == .active {
                    let health = ListingHealth(listing: listing, openHouseVisitors: listing.openHouses.reduce(0) { $0 + $1.visitors.count })
                    NavigationLink(value: Route.listingHealth(listing.id)) {
                        IconRow(icon: health.verdict.icon, title: "Check up: \(health.verdict.title.lowercased())", subtitle: "\(health.days) days, \(health.showings) showing\(health.showings == 1 ? "" : "s"). What to do next and what to tell your seller")
                            .cardStyle()
                    }
                    .buttonStyle(.plain)
                }
                checklist(listing)
                descriptionCard(listing)
                openHouses(listing)
                NavigationLink(value: Route.sellerReport(listing.id)) {
                    IconRow(icon: "chart.bar.doc.horizontal.fill", title: "Seller report and feedback", subtitle: listing.feedback.isEmpty ? "Weekly update for your seller" : "\(listing.feedback.count) showing\(listing.feedback.count == 1 ? "" : "s") logged")
                        .cardStyle()
                }
                .buttonStyle(.plain)
                NavigationLink(value: Route.listingNetSheet(listing.id)) {
                    IconRow(icon: "dollarsign.circle.fill", title: "Seller net sheet", subtitle: "What your seller walks away with")
                        .cardStyle()
                }
                .buttonStyle(.plain)
                NavigationLink(value: Route.offers(listing.id)) {
                    IconRow(icon: "rectangle.split.3x1.fill", title: "Compare offers", subtitle: store.offers(for: listing.id.uuidString).isEmpty ? "Net and strength of each offer, side by side" : "\(store.offers(for: listing.id.uuidString).count) offer\(store.offers(for: listing.id.uuidString).count == 1 ? "" : "s") in")
                        .cardStyle()
                }
                .buttonStyle(.plain)
                NavigationLink(value: Route.shotList(listing.id)) {
                    IconRow(icon: "video.badge.checkmark", title: "Shot list to film it yourself", subtitle: "Built from this home's features, with a voiceover")
                        .cardStyle()
                }
                .buttonStyle(.plain)
                NavigationLink(value: Route.listingReel(listing.id)) {
                    IconRow(icon: "film.stack.fill", title: "Make a photo reel", subtitle: "Turn listing photos into a vertical video")
                        .cardStyle()
                }
                .buttonStyle(.plain)
                Button {
                    showFlyer = true
                } label: {
                    IconRow(icon: "printer.fill", title: "Printable flyer", subtitle: "Letter size PDF with photos, QR code and your brand")
                        .cardStyle()
                }
                .buttonStyle(.plain)
                NavigationLink(value: Route.neighborBlast(listing.id)) {
                    IconRow(icon: "mail.stack.fill", title: "Neighbor blast", subtitle: "Postcard, door knock and call scripts for the streets around it")
                        .cardStyle()
                }
                .buttonStyle(.plain)
                NavigationLink(value: Route.listingCalculator(listing.id)) {
                    IconRow(icon: "function", title: "Payment calculator", subtitle: "What \(listing.priceLabel) costs per month")
                        .cardStyle()
                }
                .buttonStyle(.plain)
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle(listing.address)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showFlyer) {
            FlyerView(listing: listing)
        }
        .fullScreenCover(item: $kiosk) { openHouse in
            OpenHouseKioskView(listing: listing, openHouse: openHouse)
        }
        .sheet(isPresented: $showSchedule) {
            NavigationStack {
                Form {
                    DatePicker("Starts", selection: $openHouseDate, in: Date()...)
                    Stepper("\(openHouseHours) hours", value: $openHouseHours, in: 1...6)
                }
                .navigationTitle("Schedule open house")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showSchedule = false } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Schedule") {
                            store.scheduleOpenHouse(for: listing.id, start: openHouseDate, hours: openHouseHours)
                            showSchedule = false
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    // MARK: Sections

    private func header(_ listing: Listing) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .bottomLeading) {
                Theme.gradient(listing.paletteIndex)
                if let hero = ListingPhotoStore.cover(listing.id) {
                    Image(uiImage: hero)
                        .resizable()
                        .scaledToFill()
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                        .clipped()
                } else {
                    Image(systemName: listing.symbol)
                        .font(.system(size: 54, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                Pill(text: listing.status.title, icon: listing.status.icon, color: .white, textColor: Theme.ink)
                    .padding(12)
            }
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))

            Text(listing.priceLabel)
                .font(.cinema(28, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text("\(listing.address), \(listing.cityLine)")
                .font(.cinema(15, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
            Text(listing.specsLine)
                .font(.cinema(13))
                .foregroundStyle(Theme.textSecondary)
            if !listing.features.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(listing.features) { feature in
                        Pill(text: feature.title)
                    }
                }
            }
            HStack(spacing: 10) {
                StatTile(value: "\(Int(listing.progress * 100))%", label: "Marketing done", icon: "checklist")
                StatTile(value: "\(listing.visitorCount)", label: "Open house visitors", icon: "person.2.fill")
                StatTile(value: "\(store.leads.filter { $0.openHouseAddress == listing.address || $0.sourceClip == listing.address }.count)", label: "Leads", icon: "person.badge.plus")
            }
        }
    }

    private func statusPicker(_ listing: Listing) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("Status", selection: Binding(get: { listing.status }, set: { store.setStatus($0, for: listing.id) })) {
                ForEach(ListingStatus.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            NavigationLink(value: Route.listingPoster(listing.id)) {
                Label("Make the \(listing.status.posterKind.shortTitle.lowercased()) poster", systemImage: "rectangle.portrait.on.rectangle.portrait.fill")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
    }

    private func checklist(_ listing: Listing) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Marketing plan")
            VStack(spacing: 0) {
                ForEach(listing.tasks) { task in
                    let isDone = listing.done.contains(task)
                    HStack(spacing: 12) {
                        Button {
                            store.toggleTask(task, for: listing.id)
                        } label: {
                            Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 22))
                                .foregroundStyle(isDone ? Theme.success : Theme.textTertiary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(isDone ? "Mark not done" : "Mark done")
                        Label(task.title, systemImage: task.icon)
                            .font(.cinema(15, weight: .medium))
                            .foregroundStyle(isDone ? Theme.textSecondary : Theme.textPrimary)
                            .labelStyle(TintedIconLabelStyle())
                        Spacer()
                        action(for: task, listing: listing)
                    }
                    .padding(.vertical, 9)
                    Divider()
                }
            }
            .cardStyle(padding: 12)
        }
    }

    @ViewBuilder
    private func action(for task: MarketingTask, listing: Listing) -> some View {
        switch task {
        case .bookShoot:
            NavigationLink(value: Route.bookings) { actionLabel("Book") }
        case .comingSoonPoster, .justListedPoster, .justSoldPoster:
            NavigationLink(value: Route.listingPoster(listing.id)) { actionLabel("Make") }
        case .openHouse:
            Button { showSchedule = true } label: { actionLabel("Plan") }
        case .description:
            Button {
                UIPasteboard.general.string = listing.description.isEmpty ? ListingCopywriter.description(for: listing, tone: tone) : listing.description
                store.markTask(.description, for: listing.id)
                store.showToast("Description copied")
            } label: { actionLabel("Copy") }
        case .socialPost:
            Button {
                UIPasteboard.general.string = ListingCopywriter.socialCaption(for: listing)
                store.showToast("Caption copied. Post it from your Library.")
            } label: { actionLabel("Caption") }
        case .listingVideo, .website:
            EmptyView()
        }
    }

    private func actionLabel(_ text: String) -> some View {
        Text(text)
            .font(.cinema(12, weight: .semibold))
            .foregroundStyle(Theme.red)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Theme.redSoft, in: Capsule())
    }

    private func descriptionCard(_ listing: Listing) -> some View {
        let text = ListingCopywriter.description(for: listing, tone: tone)
        return VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Listing description")
            Picker("Tone", selection: $tone) {
                ForEach(ListingCopywriter.Tone.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            Text(text)
                .font(.cinema(14))
                .foregroundStyle(Theme.textPrimary)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
                .cardStyle()
            HStack(spacing: 10) {
                Button {
                    var updated = listing
                    updated.description = text
                    updated.done.insert(.description)
                    store.updateListing(updated)
                    UIPasteboard.general.string = text
                    store.showToast("Saved and copied")
                } label: {
                    Label("Use this", systemImage: "doc.on.doc")
                }
                .buttonStyle(PrimaryButtonStyle())
                ShareLink(item: text) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(SecondaryButtonStyle(fullWidth: false))
            }
            Text("Describes the home and area only, so it stays fair housing friendly. Check facts before posting to the MLS.")
                .font(.cinema(11))
                .foregroundStyle(Theme.textTertiary)
        }
    }

    private func openHouses(_ listing: Listing) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Open houses", actionTitle: "Schedule") { showSchedule = true }
            if listing.openHouses.isEmpty {
                Text("Schedule one and you get a QR sign-in sheet. Every visitor lands in Leads with a follow up text ready to send.")
                    .font(.cinema(14))
                    .foregroundStyle(Theme.textSecondary)
                    .cardStyle()
            }
            ForEach(listing.openHouses) { openHouse in
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(openHouse.label)
                                .font(.cinema(15, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)
                            Text("\(openHouse.visitors.count) signed in")
                                .font(.cinema(12))
                                .foregroundStyle(Theme.textSecondary)
                        }
                        Spacer()
                        QRCodeView(text: "https://hashtagcinema.com/oh/\(openHouse.id.uuidString.prefix(8).lowercased())")
                            .frame(width: 72, height: 72)
                    }
                    Button {
                        kiosk = openHouse
                    } label: {
                        Label("Start sign-in on this phone", systemImage: "ipad.and.iphone")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    ShareLink(item: ListingCopywriter.neighborInvite(for: listing, openHouse: openHouse, agentName: store.profile.name)) {
                        Label("Invite the neighbors", systemImage: "envelope.open.fill")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    NavigationLink(value: Route.openHouseKit(listing.id)) {
                        Label("Open house kit: sign in sheet and feature cards", systemImage: "printer.fill")
                            .font(.cinema(14, weight: .semibold))
                            .foregroundStyle(Theme.red)
                    }
                    Text("Or print the QR code so visitors sign in on their own phones (live once the backend is on).")
                        .font(.cinema(11))
                        .foregroundStyle(Theme.textTertiary)

                    ForEach(openHouse.visitors) { visitor in
                        VisitorRow(visitor: visitor, listing: listing, agentName: store.profile.name)
                    }
                    let toFollow = openHouse.visitors.filter { visitor in
                        !visitor.workingWithAgent && !store.touchContacts.contains { $0.name.caseInsensitiveCompare(visitor.name) == .orderedSame }
                    }
                    if !toFollow.isEmpty {
                        Button {
                            let added = toFollow.filter { store.startTouchPlan(name: $0.name, phone: $0.phone, plan: .eightWeek, quiet: true) }.count
                            store.showToast("\(added) visitor\(added == 1 ? "" : "s") on your \(TouchContact.Plan.eightWeek.title(store.lex))")
                        } label: {
                            Label("Put \(toFollow.count) on your \(TouchContact.Plan.eightWeek.title(store.lex))", systemImage: "point.3.filled.connected.trianglepath.dotted")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        Text("Visitors who said they already have an agent are left off.")
                            .font(.cinema(11))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
                .cardStyle()
            }
        }
    }
}

struct VisitorRow: View {
    let visitor: OpenHouseVisitor
    let listing: Listing
    let agentName: String

    private var message: String { ListingCopywriter.followUp(for: visitor, listing: listing, agentName: agentName) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(visitor.name)
                        .font(.cinema(14, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text([visitor.phone, visitor.email].filter { !$0.isEmpty }.joined(separator: " · "))
                        .font(.cinema(11))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                if visitor.preapproved { Pill(text: "Pre-approved", color: Theme.success.opacity(0.15), textColor: Theme.success) }
                if visitor.workingWithAgent { Pill(text: "Has agent") }
            }
            HStack(spacing: 8) {
                if let url = smsURL {
                    Link(destination: url) {
                        Label("Text follow up", systemImage: "message.fill")
                            .font(.cinema(12, weight: .semibold))
                    }
                    .foregroundStyle(Theme.red)
                }
                Button {
                    UIPasteboard.general.string = message
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.cinema(12, weight: .semibold))
                }
                .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(.top, 4)
    }

    private var smsURL: URL? {
        let digits = visitor.phone.filter { $0.isNumber || $0 == "+" }
        guard !digits.isEmpty, let body = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
        return URL(string: "sms:\(digits)&body=\(body)")
    }
}

/// Simple QR code from text with Core Image.
struct QRCodeView: View {
    let text: String

    var body: some View {
        if let image = Self.make(text) {
            Image(uiImage: image)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .accessibilityLabel("Open house sign-in QR code")
        } else {
            Image(systemName: "qrcode")
                .resizable()
                .scaledToFit()
        }
    }

    static func make(_ text: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 8, y: 8)) else { return nil }
        let context = CIContext()
        guard let cgImage = context.createCGImage(output, from: output.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
