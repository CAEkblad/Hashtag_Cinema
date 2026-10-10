import SwiftUI

/// Shown once after an update, with a tap-through to each new tool.
struct WhatsNewView: View {
    @Environment(\.dismiss) private var dismiss
    var onOpen: (Route) -> Void = { _ in }

    struct Item: Identifiable {
        var id: String { title }
        var icon: String
        var title: String
        var detail: String
        var route: Route
    }

    static let items: [Item] = [
        Item(icon: "gauge.with.dots.needle.67percent", title: "Hook grader", detail: "Type the first line of your video and get a 0 to 100 score: length, a strong start, talking to the viewer, a number, your area and curiosity. Get 5 stronger versions and turn any of them into an idea.", route: .hookGrader),
        Item(icon: "person.text.rectangle.fill", title: "Profile bios", detail: "Bios for Instagram, TikTok, Facebook, YouTube and your website or Zillow profile, each sized to the platform's limit, with your city, who you help, your brokerage and a DM keyword. Tap Try another for a new version.", route: .bioWriter),
        Item(icon: "arrow.down.circle.fill", title: "Price improvement", detail: "Open an active listing and tap Price improvement. Enter the new price and CloseUp updates the listing, then writes texts for the agents who showed it and open house visitors, the post, and a seller update.", route: .listings),
        Item(icon: "storefront.fill", title: "Local spotlight", detail: "Feature a neighborhood business every week. Pick the type and CloseUp writes the ask to the owner, 5 interview questions, a shot list and the caption, then saves it as an idea to film with the teleprompter.", route: .localSpotlight),
        Item(icon: "sparkles", title: "Year in review", detail: "A thank you post or story with your year's numbers: families helped, volume, buyers and sellers, videos and reviews. Filled from CloseUp, editable, with a caption ready to paste.", route: .yearInReview),
        Item(icon: "checkmark.shield.fill", title: "Fair housing check", detail: "Paste MLS remarks, a caption or an ad. CloseUp flags wording like \"perfect for families\" or \"great schools\", explains why, and fixes what it can in one tap. Also under every listing description and in the caption writer.", route: .fairHousing("")),
        Item(icon: "square.stack.fill", title: "Carousels", detail: "Swipe posts in your brand: a cover, tip slides and a comment keyword ending. Start from 6 ready topics (first time buyer mistakes, closing costs, Florida insurance and more) and edit every slide.", route: .carousels),
        Item(icon: "rectangle.stack.fill", title: "Story pack", detail: "Open any listing for 6 ready to post Instagram stories: guess the price, the reveal, favorite part, this or that, come see it and DM me. Each one tells you which sticker to add and when to post it.", route: .listings),
        Item(icon: "envelope.fill", title: "Prospecting letters", detail: "Branded mail letters for expireds, FSBOs, just sold neighbors, absentee owners and when you have a buyer for the area. Fill in what you know, print or share the PDF, and copy the matching follow up text.", route: .prospectingLetters),
        Item(icon: "rectangle.portrait.fill", title: "Reel covers", detail: "Branded covers for reels and TikToks. Pick a photo or any frame from a video, add your title, and choose a look. A grid preview shows exactly what your profile will show, so your page looks like a series.", route: .reelCover("")),
        Item(icon: "person.crop.rectangle.stack.fill", title: "Buyer consultation", detail: "A 3 page PDF for your first buyer meeting: what you do for them, how you're paid (percent or flat fee), the buyer agreement length and next steps. Pick the services you offer and share it before or after the meeting.", route: .buyerPresentation),
        Item(icon: "doc.viewfinder.fill", title: "Scan to leads", detail: "Snap a business card or a filled in paper sign in sheet. CloseUp reads the names, phones and emails on your phone, lets you fix anything, and adds them to Leads and your 8 week plan.", route: .scanLeads),
        Item(icon: "arrowshape.turn.up.left.fill", title: "Reply helper", detail: "Paste any comment from your posts. CloseUp reads it (price question, wants a showing, thinking of selling, your keyword, a compliment or a troll) and writes the public reply and the DM. Buying and selling signals save to Leads in one tap.", route: .replyHelper),
        Item(icon: "text.bubble.fill", title: "Call scripts", detail: "8 prospecting scripts for power hour: sphere, past clients, new online leads, open house follow up, expireds, FSBOs, just sold neighbors and referral asks. Each has an opener, questions, what to say if they push back, a close, a voicemail and a text, with tally buttons while you talk.", route: .callScripts),
        Item(icon: "printer.fill", title: "Open house kit", detail: "On any open house: a printable sign in sheet with a QR backup, fold over feature cards for each room (\"Did you notice? Impact windows\"), and a what to bring checklist.", route: .listings),
        Item(icon: "person.3.sequence.fill", title: "Team huddle", detail: "A 20 minute weekly team meeting agenda built from your team page: wins, the leaderboard, a shout out, this week's video challenge, a role play and commitments. Share it or post it to the team.", route: .teamHuddle),
        Item(icon: "book.pages.fill", title: "Buyer and seller guides", detail: "3 page PDF guides in your brand: every step with a timeline, Florida costs, and a do and don't list. Send one when someone comments GUIDE.", route: .clientGuides),
        Item(icon: "stethoscope", title: "Listing check up", detail: "Every active listing gets a read on how it's doing from days on market, showings and feedback: too early, needs more eyes, buyers are close, or time for a price conversation. With next steps and what to tell your seller. Open houses can now put every visitor on your 8 week plan in one tap.", route: .listings),
        Item(icon: "gift.fill", title: "Pop bys", detail: "Two gift ideas for every month with a fun tag line, a sheet of 10 printable tags in your brand, and a checklist of past clients and sphere to drop them off to.", route: .popBys),
        Item(icon: "mail.stack.fill", title: "Neighbor blast", detail: "Open any listing for a 6 by 4 just listed or just sold postcard (front and back, ready to print or mail), door knock and call scripts, a text, a neighborhood group post and a door counter.", route: .listings),
        Item(icon: "video.badge.checkmark", title: "Film day", detail: "Pick 3 to 7 ideas and film your whole week in one sitting. We order them so you move as little as possible, tell you when to change your top, and track what you got.", route: .filmDay),
        Item(icon: "square.stack.3d.up.fill", title: "Post it everywhere", detail: "Open any idea and tap Post it everywhere for an Instagram caption, TikTok, Facebook, YouTube, LinkedIn, Google Business Profile, an email to your sphere, a text and a blog outline from the same script.", route: .trends),
        Item(icon: "flame.fill", title: "Trends", detail: "See the video formats working for agents on TikTok, Instagram and Facebook, watch real examples, and tap Make my version for a script and shot list in your city. Saw one you liked? Paste the link.", route: .trends),
        Item(icon: "square.and.arrow.down.on.square.fill", title: "Import listings and photos", detail: "Type an MLS number to pull a listing's details and every photo into CloseUp, or add photos from Photos or Files. Reels, posters and flyers use them right away. This build uses a sample MLS feed for testing.", route: .listingPhotos(nil)),
        Item(icon: "point.3.filled.connected.trianglepath.dotted", title: "Touch plans", detail: "Put new people on an 8 touch, 8 week plan and your sphere on 33 touches a year. Each touch has what to say, and Home shows who's due.", route: .touchPlans),
        Item(icon: "rectangle.split.3x1.fill", title: "Compare offers", detail: "Line up every offer on a listing with what the seller nets and how likely each one is to close, then send the comparison to your seller.", route: .offers(nil)),
        Item(icon: "dollarsign.circle.fill", title: "How much home and rent or buy", detail: "Two buyer calculators with Florida taxes and insurance built in. Send the results, or turn rent vs buy into a video script.", route: .affordability),
        Item(icon: "airplane.departure", title: "New agent launchpad", detail: "Brand new? Turn it on for a week by week plan through your first 90 days, a license announcement, a first 100 contacts tracker and milestones your team can cheer.", route: .launchpad),
        Item(icon: "hammer.fill", title: "Partners", detail: "Stagers, cleaners, movers, junk removal, handymen, transaction coordinators and more. Request a pro for yourself or your client, or save them to your trusted pros.", route: .partners),
        Item(icon: "sparkles", title: "Hidden gems", detail: "Open any buyer for homes ranked by value, price cuts, motivated sellers and listings not on the portals yet. Pick the best and send them in one text.", route: .buyers),
        Item(icon: "point.3.connected.trianglepath.dotted", title: "Agent network", detail: "Coming soon and off market homes from agents across the country, and buyers other agents are working with.", route: .agentNetwork),
        Item(icon: "person.3.fill", title: "Team pages", detail: "Join or start a team. Videos, posters, listings, closings and reviews post to the team page on their own. Roster, leaderboard, lead hand offs and a recruiting page.", route: .team),
        Item(icon: "checklist.checked", title: "Weekly scorecard", detail: "4-1-1 style weekly targets for videos, touches, appointments and leads, filled in for you. Share it with your accountability partner.", route: .scorecard),
        Item(icon: "clock.fill", title: "Time blocks", detail: "Set your daily focus blocks and get a reminder when each one starts.", route: .timeBlocks),
        Item(icon: "timer", title: "Power hour", detail: "A prospecting timer with one tap tallies for calls, texts, talks and appointments, plus a daily streak.", route: .powerHour),
        Item(icon: "person.text.rectangle.fill", title: "Digital business card", detail: "A QR code people scan to save your contact, or send it as a contact card.", route: .businessCard),
        Item(icon: "checkmark.seal.fill", title: "License and CE", detail: "Florida renewal date, hours by category and reminders 90, 30 and 7 days out.", route: .license),
        Item(icon: "map.fill", title: "Mileage that does the math", detail: "Apple Maps works out the miles, including round trips and whole showing tours. Save frequent trips and log them in one tap.", route: .expenses),
        Item(icon: "chart.pie.fill", title: "Split and cap tracker", detail: "See how close you are to capping, with company split and royalty worked out from your closings.", route: .splitTracker),
        Item(icon: "building.columns.fill", title: "Tax set aside", detail: "How much to save from every closing, and reminders before each quarterly payment.", route: .taxes),
        Item(icon: "calendar.badge.clock", title: "Listing launch plan", detail: "Open any active listing for a dated countdown with every tool one tap away.", route: .listings),
        Item(icon: "film.stack.fill", title: "Photo reel", detail: "Listing photos in, a branded vertical video out, made on your phone.", route: .photoReel),
        Item(icon: "person.crop.rectangle.stack.fill", title: "Find a photographer, now with a map", detail: "See Crew near you, pick a package with Help me choose, and chat with your shooter.", route: .findShooter),
        Item(icon: "doc.text.fill", title: "Under contract", detail: "Every Florida contract deadline, with reminders and a timeline for your client.", route: .deals),
        Item(icon: "car.fill", title: "Showing tours", detail: "Plan the route, send the schedule, then send a recap of what they loved.", route: .tours),
        Item(icon: "heart.text.square", title: "Buyer wishlists", detail: "Match buyers to your listings and build a tour in one tap.", route: .buyers),
        Item(icon: "house.and.flag.fill", title: "Past clients", detail: "Home anniversary reminders, value check-ins and a monthly newsletter.", route: .pastClients),
        Item(icon: "dollarsign.circle.fill", title: "Seller net sheet", detail: "Florida doc stamps and title, worked out for your seller.", route: .netSheet),
        Item(icon: "chart.line.uptrend.xyaxis", title: "Home value report", detail: "A branded PDF from 3 to 5 comps for every VALUE lead.", route: .homeValue),
        Item(icon: "bubble.left.and.text.bubble.right.fill", title: "Auto DM keywords", detail: "Save your comment keywords and DMs once, use them on every post.", route: .keywords),
        Item(icon: "arrow.triangle.branch", title: "Agent referrals", detail: "Send clients to trusted agents across Florida and track the fee.", route: .referralNetwork),
        Item(icon: "target", title: "Business plan", detail: "Your income goal, worked back to videos a week.", route: .businessPlan),
        Item(icon: "quote.bubble.fill", title: "What to say when", detail: "Honest answers to the 12 objections you hear most, each one a video in a tap.", route: .objections),
        Item(icon: "map.fill", title: "My farm", detail: "Own a neighborhood: log monthly touches and get video ideas for it.", route: .farm),
        Item(icon: "person.crop.square.filled.and.at.rectangle", title: "Brand shoot prep", detail: "Your story, locations and wardrobe, sent to the #Cinema producer before shoot day.", route: .brandShootPrep),
        Item(icon: "chart.bar.fill", title: "Where your leads come from", detail: "A new chart in Insights shows which keywords and open houses bring in leads.", route: .insights),
        Item(icon: "waveform", title: "Siri and Shortcuts", detail: "Say \"Log mileage in CloseUp\", \"What's my video idea in CloseUp\" or \"Check my leads in CloseUp\".", route: .expenses),
        Item(icon: "square.grid.2x2.fill", title: "All tools", detail: "Everything in one place, grouped by what you're doing.", route: .tools)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("What's new in CloseUp")
                        .font(.cinema(28, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Tap anything to try it.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.bottom, 4)
                    ForEach(Self.items) { item in
                        Button {
                            dismiss()
                            onOpen(item.route)
                        } label: {
                            HStack(alignment: .top, spacing: 14) {
                                Image(systemName: item.icon)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(Theme.red)
                                    .frame(width: 40, height: 40)
                                    .background(Theme.redSoft, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(item.title)
                                        .font(.cinema(16, weight: .semibold))
                                        .foregroundStyle(Theme.textPrimary)
                                    Text(item.detail)
                                        .font(.cinema(13))
                                        .foregroundStyle(Theme.textSecondary)
                                        .multilineTextAlignment(.leading)
                                }
                                Spacer(minLength: 0)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Theme.textTertiary)
                                    .padding(.top, 12)
                            }
                            .cardStyle(padding: 14)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(Theme.gutter)
            }
            .background(Theme.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    /// The build number this screen was last shown for.
    static let seenKey = "cinema.whatsnew.build"
    static var currentBuild: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0" }

    static var shouldShow: Bool {
        (UserDefaults.standard.string(forKey: seenKey) ?? "") != currentBuild
    }

    static func markSeen() {
        UserDefaults.standard.set(currentBuild, forKey: seenKey)
    }
}

/// The same list as a pushed screen, for the Me tab.
struct WhatsNewList: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(WhatsNewView.items) { item in
                    NavigationLink(value: item.route) {
                        IconRow(icon: item.icon, title: item.title, subtitle: item.detail)
                            .cardStyle(padding: 14)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("What's new")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// A swipeable row of the newest tools on Home.
struct NewToolsStrip: View {
    private var items: [WhatsNewView.Item] { Array(WhatsNewView.items.prefix(8)) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("New in CloseUp")
                    .font(.cinema(17, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                NavigationLink(value: Route.whatsNew) {
                    Text("See all")
                        .font(.cinema(14, weight: .semibold))
                        .foregroundStyle(Theme.red)
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(items) { item in
                        NavigationLink(value: item.route) {
                            VStack(alignment: .leading, spacing: 8) {
                                Image(systemName: item.icon)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Theme.red)
                                    .frame(width: 34, height: 34)
                                    .background(Theme.redSoft, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                                Text(item.title)
                                    .font(.cinema(13, weight: .bold))
                                    .foregroundStyle(Theme.textPrimary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(width: 112, height: 92, alignment: .topLeading)
                            .padding(12)
                            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Theme.stroke))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
}
