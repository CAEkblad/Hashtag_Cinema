import SwiftUI
import UIKit

/// Branded mail letters for expireds, FSBOs, just sold neighbors, absentee
/// owners and buyer-in-hand circle prospecting, with a matching text.
struct ProspectingLettersView: View {
    @Environment(CinemaStore.self) private var store
    @State private var kind: ProspectLetter.Kind = .expired
    @State private var ownerName = ""
    @State private var propertyAddress = ""
    @State private var area = ""
    @State private var soldAddress = ""
    @State private var buyerNote = ""
    @State private var shareFile: ShareFile?
    @State private var copied = false

    private var letter: ProspectLetter {
        ProspectLetter(
            kind: kind,
            ownerName: ownerName.trimmingCharacters(in: .whitespaces),
            propertyAddress: propertyAddress.trimmingCharacters(in: .whitespaces),
            area: area.trimmingCharacters(in: .whitespaces).isEmpty ? store.homeCity.name : area.trimmingCharacters(in: .whitespaces),
            soldAddress: soldAddress.trimmingCharacters(in: .whitespaces),
            buyerNote: buyerNote.trimmingCharacters(in: .whitespaces),
            agentName: store.profile.name,
            phone: store.brandKit.phone
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Prospecting letters")
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("A real letter in the mailbox still gets opened. Pick who it's for, fill in what you know, and print it or send it as a PDF.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ProspectLetter.Kind.allCases) { option in
                            Button { kind = option } label: {
                                Label(option.title, systemImage: option.icon)
                                    .font(.cinema(13, weight: .semibold))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(kind == option ? Theme.red : Theme.surfaceRaised, in: Capsule())
                                    .foregroundStyle(kind == option ? .white : Theme.textPrimary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Text(kind.when)
                    .font(.cinema(13))
                    .foregroundStyle(Theme.textSecondary)

                VStack(alignment: .leading, spacing: 10) {
                    TextField("Owner's name (optional)", text: $ownerName)
                        .textContentType(.name)
                        .inputStyle()
                    if kind != .justSold && kind != .buyerInHand {
                        TextField("Their property address", text: $propertyAddress)
                            .textContentType(.fullStreetAddress)
                            .inputStyle()
                    }
                    TextField("Neighborhood, like \(store.homeCity.neighborhoods.first ?? store.homeCity.name)", text: $area)
                        .inputStyle()
                    if kind == .justSold {
                        TextField("The home you sold, like 412 Palm Ave", text: $soldAddress)
                            .inputStyle()
                    }
                    if kind == .buyerInHand || kind == .justSold {
                        TextField("About your buyer, like a family relocating from Ohio", text: $buyerNote)
                            .inputStyle()
                    }
                }
                .cardStyle()

                VStack(spacing: 10) {
                    ProspectLetterCanvas(letter: letter, brokerage: store.myMarketCenter?.name ?? store.profile.brokerage, kit: store.brandKit)
                        .scaleEffect(320 / FlyerCanvas.size.width, anchor: .topLeading)
                        .frame(width: 320, height: 320 * FlyerCanvas.size.height / FlyerCanvas.size.width, alignment: .topLeading)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .shadow(color: .black.opacity(0.15), radius: 12, y: 5)
                }
                .frame(maxWidth: .infinity)

                HStack(spacing: 10) {
                    Button { makePDF() } label: {
                        Label("Share PDF", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    Button {
                        UIPasteboard.general.string = letter.text
                        copied = true
                    } label: {
                        Label(copied ? "Copied" : "Copy text", systemImage: copied ? "checkmark" : "message.fill")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Follow up text")
                        .font(.cinema(14, weight: .bold))
                    Text(letter.text)
                        .font(.cinema(13))
                        .foregroundStyle(Theme.textSecondary)
                    Text("Only text people who gave you their number or who you're allowed to contact. Check the Do Not Call list first.")
                        .font(.cinema(11))
                        .foregroundStyle(Theme.textTertiary)
                }
                .cardStyle()

                NavigationLink(value: Route.callScripts) {
                    IconRow(icon: "text.bubble.fill", title: "Call them too", subtitle: "Matching scripts for expireds, FSBOs and neighbors")
                        .cardStyle(padding: 14)
                }
                .buttonStyle(.plain)
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Prospecting letters")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: kind) { _, _ in copied = false }
        .sheet(item: $shareFile) { file in
            ActivityView(items: [file.url])
                .presentationDetents([.medium, .large])
        }
    }

    @MainActor
    private func makePDF() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(kind.fileName)-letter.pdf")
        var box = CGRect(origin: .zero, size: FlyerCanvas.size)
        guard let context = CGContext(url as CFURL, mediaBox: &box, nil) else { return }
        let renderer = ImageRenderer(content: ProspectLetterCanvas(letter: letter, brokerage: store.myMarketCenter?.name ?? store.profile.brokerage, kit: store.brandKit))
        renderer.render { _, draw in
            context.beginPDFPage(nil)
            draw(context)
            context.endPDFPage()
        }
        context.closePDF()
        shareFile = ShareFile(url: url)
    }
}

struct ProspectLetter {
    enum Kind: String, CaseIterable, Identifiable {
        case expired, fsbo, justSold, absentee, buyerInHand
        var id: String { rawValue }
        var title: String {
            switch self {
            case .expired: return "Expired"
            case .fsbo: return "For sale by owner"
            case .justSold: return "Just sold nearby"
            case .absentee: return "Absentee owner"
            case .buyerInHand: return "I have a buyer"
            }
        }
        var icon: String {
            switch self {
            case .expired: return "clock.badge.xmark"
            case .fsbo: return "signpost.right.fill"
            case .justSold: return "checkmark.seal.fill"
            case .absentee: return "building.2.fill"
            case .buyerInHand: return "person.fill.questionmark"
            }
        }
        var when: String {
            switch self {
            case .expired: return "Mail the day it expires. Most owners still want to sell, they just lost trust in the last plan."
            case .fsbo: return "Mail in the first week. Lead with help, not a pitch to list."
            case .justSold: return "Mail to the 50 to 100 homes around every sale. Neighbors always want to know what it sold for."
            case .absentee: return "For rentals and second homes. Owners who live far away are often open to a number."
            case .buyerInHand: return "Only when you really have a buyer for the area. Specific beats generic."
            }
        }
        var fileName: String {
            switch self {
            case .expired: return "Expired"
            case .fsbo: return "FSBO"
            case .justSold: return "Just-sold"
            case .absentee: return "Absentee-owner"
            case .buyerInHand: return "Buyer-in-hand"
            }
        }
    }

    let kind: Kind
    let ownerName: String
    let propertyAddress: String
    let area: String
    let soldAddress: String
    let buyerNote: String
    let agentName: String
    let phone: String

    private var first: String { agentName.split(separator: " ").first.map(String.init) ?? agentName }
    private var street: String { propertyAddress.split(separator: ",").first.map(String.init) ?? propertyAddress }
    private var yourHome: String { street.isEmpty ? "your home" : "your home on \(street)" }
    private var callLine: String { phone.isEmpty ? "Reply to this letter or look me up online" : "Call or text me at \(phone)" }

    var greeting: String { ownerName.isEmpty ? "Hi neighbor," : "Hi \(ownerName.split(separator: " ").first.map(String.init) ?? ownerName)," }

    var headline: String {
        switch kind {
        case .expired: return "Your home didn't sell. That's not the end of the story."
        case .fsbo: return "Selling it yourself? Here's some free help."
        case .justSold: return soldAddress.isEmpty ? "A home near you just sold." : "\(soldAddress) just sold."
        case .absentee: return "Ever thought about what your \(area) property would sell for?"
        case .buyerInHand: return "I have a buyer looking in \(area)."
        }
    }

    var paragraphs: [String] {
        switch kind {
        case .expired:
            return [
                "I saw the listing for \(yourHome) came off the market. I know that's frustrating, especially after months of showings, keeping the house ready, and waiting.",
                "Homes usually don't sell for one of three reasons: the price, the presentation, or how many of the right buyers actually saw it. I'd love to show you what I'd do differently, starting with professional video that gets your home in front of buyers on Instagram, TikTok and Facebook, not just the MLS.",
                "No pressure and no long pitch. Just a 15 minute conversation and a fresh look at the numbers."
            ]
        case .fsbo:
            return [
                "I noticed \(yourHome) is for sale by owner. Good for you for taking it on. It's a lot of work, and I'm happy to make it a little easier.",
                "Here's what I can send you for free: recent sales near you so you can price it with confidence, a list of the forms and disclosures Florida sellers usually need, and a checklist for showings and offers.",
                "If a buyer's agent brings you an offer, I can also help you understand it. And if you ever decide you want help, you'll already know me."
            ]
        case .justSold:
            return [
                "\(soldAddress.isEmpty ? "A home in your neighborhood" : soldAddress) just sold, and I wanted you to hear it from me first. Homes in \(area) are getting real attention right now.",
                buyerNote.isEmpty ? "We had more interested buyers than homes, and some of them are still looking in \(area)." : "We had more interested buyers than homes, including \(buyerNote), and they're still looking in \(area).",
                "Curious what your home would sell for today? I'll send you a free, no strings value report with the recent sales on your street."
            ]
        case .absentee:
            return [
                "I help owners of homes and rentals in \(area), and I'm reaching out about \(street.isEmpty ? "your property" : street).",
                "Whether you're happy holding it, tired of managing it, or just curious, it helps to know what it's worth today. Values in \(area) have moved a lot in the last few years.",
                "I'll send you a free value estimate and what similar homes are renting for, so you can decide with real numbers. No pressure either way."
            ]
        case .buyerInHand:
            return [
                buyerNote.isEmpty ? "I'm working with a buyer who has their heart set on \(area), and there's nothing on the market right now that fits." : "I'm working with \(buyerNote) who has their heart set on \(area), and there's nothing on the market right now that fits.",
                "They're pre-approved and ready to move. If you've thought about selling in the next year, this could be a chance to sell on your timeline, with fewer showings and less hassle.",
                "Even if the answer is not now, I'd love to hear from you. Every conversation stays between us."
            ]
        }
    }

    var closing: String { "\(callLine). I'd love to help." }

    var text: String {
        let name = ownerName.isEmpty ? "" : " \(ownerName.split(separator: " ").first.map(String.init) ?? ownerName)"
        switch kind {
        case .expired: return "Hi\(name), it's \(first). I sent you a letter about \(yourHome). Would you be open to a quick 15 minute chat about what I'd do differently?"
        case .fsbo: return "Hi\(name), it's \(first), a local agent. Happy to send you the recent sales near \(street.isEmpty ? "you" : street) for free. Want them?"
        case .justSold: return "Hi\(name), it's \(first). \(soldAddress.isEmpty ? "A home near you" : soldAddress) just sold. Want to know what it went for and what yours might sell for?"
        case .absentee: return "Hi\(name), it's \(first). Want a free value estimate and rent numbers for \(street.isEmpty ? "your property" : street) in \(area)?"
        case .buyerInHand: return "Hi\(name), it's \(first). I have a buyer looking for a home in \(area). Any chance you'd consider an offer in the next year?"
        }
    }
}

struct ProspectLetterCanvas: View {
    let letter: ProspectLetter
    let brokerage: String
    let kit: BrandKit

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(letter.agentName)
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundStyle(Theme.ink)
                    Text(brokerage)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                if let logo = kit.logoImage {
                    Image(uiImage: logo).resizable().scaledToFit().frame(maxWidth: 110, maxHeight: 44)
                }
            }
            .padding(.horizontal, 54)
            .padding(.top, 44)
            .padding(.bottom, 16)

            Rectangle().fill(kit.accent).frame(height: 4).padding(.horizontal, 54)

            VStack(alignment: .leading, spacing: 18) {
                Text(Date().formatted(date: .long, time: .omitted))
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(Theme.textTertiary)
                Text(letter.headline)
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundStyle(kit.accent)
                    .fixedSize(horizontal: false, vertical: true)
                Text(letter.greeting)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                ForEach(letter.paragraphs, id: \.self) { paragraph in
                    Text(paragraph)
                        .font(.system(size: 15, design: .rounded))
                        .foregroundStyle(Theme.ink)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Text(letter.closing)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                HStack(spacing: 14) {
                    if let headshot = kit.headshotImage {
                        Image(uiImage: headshot).resizable().scaledToFill().frame(width: 64, height: 64).clipShape(Circle())
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Warmly,")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                        Text(letter.agentName)
                            .font(.system(size: 22, weight: .regular, design: .serif))
                            .italic()
                            .foregroundStyle(Theme.ink)
                    }
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 54)
            .padding(.top, 22)

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 3) {
                Text([kit.phone, kit.website].filter { !$0.isEmpty }.joined(separator: "  ·  "))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text("If your home is currently listed with a broker, please disregard this letter. It is not intended as a solicitation of listings already under contract with another broker.")
                    .font(.system(size: 8.5, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 54)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.ink)
        }
        .frame(width: FlyerCanvas.size.width, height: FlyerCanvas.size.height)
        .background(Color.white)
    }
}
