import SwiftUI
import UIKit

/// Everything to work the neighborhood around a listing: a printable postcard,
/// door knock and call scripts, a text and a group post, plus a door counter.
struct NeighborBlastView: View {
    @Environment(CinemaStore.self) private var store
    let listingID: UUID

    @State private var kind: PosterKind = .justListed
    @State private var didPickKind = false
    @State private var showBack = false
    @State private var photo: UIImage?
    @State private var shareFile: ShareFile?

    private var listing: Listing? { store.listing(listingID) }

    var body: some View {
        Group {
            if let listing {
                content(listing)
            } else {
                EmptyStateView(title: "Listing not found", message: "It may have been removed.", icon: "house")
            }
        }
        .cinemaScreen()
        .navigationTitle("Neighbor blast")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $shareFile) { file in
            ActivityView(items: [file.url])
                .presentationDetents([.medium, .large])
        }
    }

    private func copy(for listing: Listing) -> NeighborBlastCopy {
        NeighborBlastCopy(listing: listing, kind: kind, agentName: store.profile.name, phone: store.brandKit.phone)
    }

    private func postcard(_ listing: Listing, back: Bool) -> PostcardCanvas {
        PostcardCanvas(
            listing: listing,
            kind: kind,
            photo: photo,
            side: back ? .back : .front,
            message: copy(for: listing).postcardBack,
            agentName: store.profile.name,
            brokerage: store.myMarketCenter?.name ?? store.profile.brokerage,
            kit: store.brandKit,
            qrText: "https://hashtagcinema.com/l/\(listing.id.uuidString.prefix(8).lowercased())"
        )
    }

    private func content(_ listing: Listing) -> some View {
        let words = copy(for: listing)
        let today = store.prospecting(on: Date())
        return ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(listing.address)
                        .font(.cinema(22, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Neighbors are your best leads after a listing or a sale. Most of them are wondering what their own home is worth.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                Picker("What happened", selection: $kind) {
                    ForEach([PosterKind.comingSoon, .justListed, .openHouse, .underContract, .justSold], id: \.self) { option in
                        Text(option.title.capitalized).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .tint(Theme.red)
                .cardStyle(padding: 12)

                VStack(spacing: 12) {
                    Picker("Side", selection: $showBack) {
                        Text("Front").tag(false)
                        Text("Back").tag(true)
                    }
                    .pickerStyle(.segmented)

                    let preview = postcard(listing, back: showBack)
                    preview
                        .scaleEffect(330 / PostcardCanvas.size.width, anchor: .topLeading)
                        .frame(width: 330, height: 330 * PostcardCanvas.size.height / PostcardCanvas.size.width, alignment: .topLeading)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
                        .frame(maxWidth: .infinity)

                    Button {
                        makePDF(listing)
                    } label: {
                        Label("Print or share postcard", systemImage: "printer.fill")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    Text("6 by 4 inch, front and back. Send it to a print shop or USPS Every Door Direct Mail for the streets around the listing.")
                        .font(.cinema(12))
                        .foregroundStyle(Theme.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Door knocks today")
                    HStack(spacing: 10) {
                        counter(.doors, today: today)
                        counter(.conversations, today: today)
                        counter(.appointments, today: today)
                    }
                    Text("Counts toward your power hour. Knock 10 doors on each side and 20 across the street.")
                        .font(.cinema(12))
                        .foregroundStyle(Theme.textTertiary)
                }

                scriptCard("At the door", icon: "door.left.hand.open", text: words.doorKnock)
                scriptCard("On the phone", icon: "phone.fill", text: words.call)
                scriptCard("Text to neighbors you know", icon: "message.fill", text: words.text)
                scriptCard("Neighborhood group post", icon: "person.3.fill", text: words.groupPost)

                Text("Check your state's do not call rules before cold calling, and skip houses with no soliciting signs.")
                    .font(.cinema(12))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(Theme.gutter)
        }
        .onAppear {
            if photo == nil { photo = ListingPhotoStore.load(listing.id, limit: 1).first }
            guard !didPickKind else { return }
            didPickKind = true
            switch listing.status {
            case .comingSoon: kind = .comingSoon
            case .active: kind = listing.nextOpenHouse == nil ? .justListed : .openHouse
            case .underContract: kind = .underContract
            case .sold: kind = .justSold
            }
        }
    }

    private func counter(_ action: ProspectAction, today: [ProspectAction: Int]) -> some View {
        Button {
            store.tallyProspect(action)
        } label: {
            VStack(spacing: 4) {
                Text("\(today[action] ?? 0)")
                    .font(.cinema(24, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text(action.title)
                    .font(.cinema(12, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(Theme.red)
            }
            .frame(maxWidth: .infinity)
            .cardStyle(padding: 12)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add one to \(action.title)")
    }

    private func scriptCard(_ title: String, icon: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.cinema(15, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Button {
                    UIPasteboard.general.string = text
                    store.showToast("Copied")
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .tint(Theme.red)
                .accessibilityLabel("Copy \(title)")
            }
            Text(text)
                .font(.cinema(14))
                .foregroundStyle(Theme.textSecondary)
                .textSelection(.enabled)
        }
        .cardStyle()
    }

    @MainActor
    private func makePDF(_ listing: Listing) {
        let safeName = listing.address.filter { $0.isLetter || $0.isNumber || $0 == " " }.replacingOccurrences(of: " ", with: "-")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Postcard-\(safeName.isEmpty ? "listing" : safeName).pdf")
        var box = CGRect(origin: .zero, size: PostcardCanvas.size)
        guard let context = CGContext(url as CFURL, mediaBox: &box, nil) else { return }
        for back in [false, true] {
            let renderer = ImageRenderer(content: postcard(listing, back: back))
            renderer.render { _, draw in
                context.beginPDFPage(nil)
                draw(context)
                context.endPDFPage()
            }
        }
        context.closePDF()
        shareFile = ShareFile(url: url)
    }
}

// MARK: - Postcard

/// 6 by 4 inches at 72 points per inch.
struct PostcardCanvas: View {
    static let size = CGSize(width: 432, height: 288)

    enum Side { case front, back }

    let listing: Listing
    let kind: PosterKind
    let photo: UIImage?
    let side: Side
    let message: String
    let agentName: String
    let brokerage: String
    let kit: BrandKit
    let qrText: String

    var body: some View {
        Group {
            switch side {
            case .front: front
            case .back: back
            }
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .background(Color.white)
        .clipped()
    }

    private var front: some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if let photo {
                    Image(uiImage: photo).resizable().scaledToFill()
                } else {
                    ZStack {
                        Theme.gradient(listing.paletteIndex)
                        Image(systemName: listing.symbol)
                            .font(.system(size: 54, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
            }
            .frame(width: Self.size.width, height: Self.size.height)
            .clipped()

            LinearGradient(colors: [.clear, .black.opacity(0.75)], startPoint: .center, endPoint: .bottom)

            VStack(alignment: .leading, spacing: 4) {
                Text(kind.title)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .kerning(2)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(kit.accent, in: Capsule())
                Text(listing.address)
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text([kind == .justSold || kind == .underContract ? nil : listing.priceLabel, listing.specsLine].compactMap { $0 }.joined(separator: "  ·  "))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                if kind == .openHouse, let open = listing.nextOpenHouse {
                    Text(open.label)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
            .padding(18)
        }
    }

    private var back: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                Text(headline)
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Text(message)
                    .font(.system(size: 10.5, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 8) {
                    QRCodeView(text: qrText)
                        .frame(width: 54, height: 54)
                    Text("Scan for photos, price and what homes nearby are selling for.")
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer(minLength: 0)
                HStack(spacing: 8) {
                    if let headshot = kit.headshotImage {
                        Image(uiImage: headshot)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 34, height: 34)
                            .clipShape(Circle())
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text(agentName)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.ink)
                        Text([kit.phone, brokerage].filter { !$0.isEmpty }.joined(separator: "  ·  "))
                            .font(.system(size: 8.5, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                    if let logo = kit.logoImage {
                        Image(uiImage: logo).resizable().scaledToFit().frame(maxWidth: 60, maxHeight: 26)
                    }
                }
            }
            .padding(16)
            .frame(width: Self.size.width * 0.58, height: Self.size.height, alignment: .topLeading)

            Rectangle()
                .fill(Theme.stroke)
                .frame(width: 1)
                .padding(.vertical, 16)

            // Postage and mailing panel, kept clear for the printer or USPS.
            VStack(alignment: .trailing) {
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Theme.textTertiary, style: StrokeStyle(lineWidth: 0.8, dash: [3]))
                    .frame(width: 52, height: 60)
                    .overlay(Text("POSTAGE").font(.system(size: 6, weight: .bold)).foregroundStyle(Theme.textTertiary))
                Spacer()
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(0..<3, id: \.self) { _ in
                        Rectangle().fill(Theme.stroke).frame(height: 1)
                    }
                }
                .frame(width: 140)
                .padding(.bottom, 40)
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        }
    }

    private var headline: String {
        switch kind {
        case .justSold: return "Your neighbor's home just sold"
        case .underContract: return "Your neighbor's home is under contract"
        case .openHouse: return "You're invited to an open house"
        case .comingSoon: return "Coming soon on your street"
        default: return "Just listed in your neighborhood"
        }
    }
}

// MARK: - Words

struct NeighborBlastCopy {
    let listing: Listing
    let kind: PosterKind
    let agentName: String
    let phone: String

    private var first: String { agentName.split(separator: " ").first.map(String.init) ?? agentName }
    private var street: String { listing.address.split(separator: ",").first.map(String.init) ?? listing.address }
    private var callBack: String { phone.isEmpty ? "" : " You can reach me at \(phone)." }

    private var news: String {
        switch kind {
        case .justSold: return "the home at \(street) just sold"
        case .underContract: return "the home at \(street) just went under contract"
        case .openHouse: return "I'm holding an open house at \(street)\(listing.nextOpenHouse.map { " \($0.label)" } ?? "")"
        case .comingSoon: return "the home at \(street) is coming on the market soon"
        default: return "I just listed the home at \(street) for \(listing.priceLabel)"
        }
    }

    var doorKnock: String {
        switch kind {
        case .justSold, .underContract:
            return "Hi, I'm \(first), a local agent. I wanted to let you know \(news). We had more interest than homes to show, so I'm letting neighbors know first. Have you ever thought about what your home might sell for right now? I'm happy to put together a free value report for you, no pressure."
        case .openHouse:
            return "Hi, I'm \(first), a local agent. \(news.prefix(1).uppercased() + news.dropFirst()), and I wanted to invite the neighbors to come see it first. Do you know anyone who's been wanting to move into the neighborhood? And if you're ever curious what your own home is worth, I'm happy to help."
        default:
            return "Hi, I'm \(first), a local agent. I wanted to let you know \(news). Neighbors often know someone who'd love to live nearby. Do you know anyone thinking about a move? And if you've ever wondered what your own home is worth, I can put together a free value report."
        }
    }

    var call: String {
        "Hi, is this [name]? This is \(first), a local real estate agent. I'm calling a few neighbors because \(news). Quick question: are you thinking about making a move in the next year, or do you know anyone who is?\(callBack) Thanks for your time."
    }

    var text: String {
        "Hey [name], it's \(first)! Quick neighborhood news: \(news). If you or anyone you know is curious what homes nearby are worth, I'm happy to help."
    }

    var groupPost: String {
        switch kind {
        case .openHouse:
            return "Neighbors, \(news). Stop by to say hi or bring a friend who's been wanting to live in the area. Questions about the market? Happy to answer them here."
        case .justSold, .underContract:
            return "Neighborhood update: \(news). If you've been wondering what homes on our streets are worth right now, comment or message me and I'll share what I'm seeing. No sales pitch."
        default:
            return "Neighbors, \(news). If you know someone who'd love to live here, send them my way. And if you're curious what your home is worth, I'm happy to share what I'm seeing."
        }
    }

    var postcardBack: String {
        switch kind {
        case .justSold, .underContract:
            return "Hi neighbor! \(news.prefix(1).uppercased() + news.dropFirst()). We had more buyers than homes, so some of them are still looking in this neighborhood. If you've ever thought about selling, I'd love to show you what your home could sell for today. \(first)"
        case .openHouse:
            return "Hi neighbor! \(news.prefix(1).uppercased() + news.dropFirst()). Come take a look before anyone else, and bring a friend who'd love to live nearby. \(first)"
        default:
            return "Hi neighbor! \(news.prefix(1).uppercased() + news.dropFirst()). If you know someone who'd love to live on your street, send them my way. Curious what your home is worth? Scan the code or give me a call. \(first)"
        }
    }
}
