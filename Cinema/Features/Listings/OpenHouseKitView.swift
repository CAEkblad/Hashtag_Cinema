import SwiftUI
import UIKit

/// Printables for an open house: a paper sign in sheet with a QR backup,
/// fold over feature cards for each room, and what to bring.
struct OpenHouseKitView: View {
    @Environment(CinemaStore.self) private var store
    let listingID: UUID

    @State private var extraCards: [String] = []
    @State private var newCard = ""
    @State private var packed: Set<Int> = []
    @State private var shareFile: ShareFile?

    private var listing: Listing? { store.listing(listingID) }

    static let bringList: [String] = [
        "Open house signs and directional arrows (check HOA and city sign rules)",
        "This sign in sheet and a pen, plus the QR code",
        "Feature cards for each room",
        "Flyers with your QR code",
        "Water and a small snack tray",
        "Shoe covers if the seller wants them",
        "Phone charger and a small speaker for soft music",
        "Business cards and your buyer guide"
    ]

    var body: some View {
        Group {
            if let listing {
                content(listing)
            } else {
                EmptyStateView(title: "Listing not found", message: "It may have been removed.", icon: "house")
            }
        }
        .cinemaScreen()
        .navigationTitle("Open house kit")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $shareFile) { file in
            ActivityView(items: [file.url])
                .presentationDetents([.medium, .large])
        }
    }

    private func cardTexts(_ listing: Listing) -> [String] {
        listing.features.map(\.title) + extraCards
    }

    private func content(_ listing: Listing) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(listing.address)
                        .font(.cinema(22, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(listing.nextOpenHouse.map { "Next open house: \($0.label)" } ?? "Schedule an open house on the listing page and the sign in sheet picks up the date.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Label("Paper sign in sheet", systemImage: "list.clipboard.fill")
                        .font(.cinema(16, weight: .bold))
                    Text("For visitors who'd rather write than scan. The QR code at the top opens the phone sign in so most people land in your Leads on their own.")
                        .font(.cinema(13))
                        .foregroundStyle(Theme.textSecondary)
                    Button {
                        share(pages: [AnyView(SignInSheetCanvas(listing: listing, agentName: store.profile.name, kit: store.brandKit, qrText: qrText(listing)))], name: "Sign-in-sheet")
                    } label: {
                        Label("Print sign in sheet", systemImage: "printer.fill")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 10) {
                    Label("Feature cards", systemImage: "rectangle.on.rectangle.angled")
                        .font(.cinema(16, weight: .bold))
                    Text("Fold over cards that sit on the counter and point out what buyers miss. Two to a page; fold on the line.")
                        .font(.cinema(13))
                        .foregroundStyle(Theme.textSecondary)
                    FlowLayout(spacing: 8) {
                        ForEach(cardTexts(listing), id: \.self) { text in
                            Text(text)
                                .font(.cinema(13, weight: .semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Theme.surfaceRaised, in: Capsule())
                        }
                    }
                    HStack {
                        TextField("Add a card, like \"New AC in 2024\"", text: $newCard)
                            .inputStyle()
                        Button {
                            let clean = newCard.trimmingCharacters(in: .whitespaces)
                            guard !clean.isEmpty, !extraCards.contains(clean) else { return }
                            extraCards.append(clean)
                            newCard = ""
                        } label: {
                            Image(systemName: "plus.circle.fill").font(.system(size: 26))
                        }
                        .tint(Theme.red)
                        .accessibilityLabel("Add card")
                    }
                    Button {
                        let texts = cardTexts(listing)
                        let pages = stride(from: 0, to: texts.count, by: 2).map { index in
                            AnyView(FeatureCardPage(top: texts[index], bottom: index + 1 < texts.count ? texts[index + 1] : nil, listing: listing, kit: store.brandKit))
                        }
                        share(pages: pages, name: "Feature-cards")
                    } label: {
                        Label("Print \(cardTexts(listing).count) feature cards", systemImage: "printer.fill")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(cardTexts(listing).isEmpty)
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 10) {
                    Label("What to bring", systemImage: "bag.fill")
                        .font(.cinema(16, weight: .bold))
                    ForEach(Array(Self.bringList.enumerated()), id: \.offset) { index, item in
                        Button {
                            if packed.contains(index) { packed.remove(index) } else { packed.insert(index) }
                        } label: {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: packed.contains(index) ? "checkmark.square.fill" : "square")
                                    .foregroundStyle(packed.contains(index) ? Theme.success : Theme.textTertiary)
                                Text(item)
                                    .font(.cinema(14))
                                    .foregroundStyle(Theme.textPrimary)
                                    .strikethrough(packed.contains(index), color: Theme.textTertiary)
                                    .multilineTextAlignment(.leading)
                                Spacer(minLength: 0)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .cardStyle()

                NavigationLink(value: Route.neighborBlast(listing.id)) {
                    IconRow(icon: "mail.stack.fill", title: "Invite the neighbors", subtitle: "Postcards, door knocks and a group post for the open house")
                        .cardStyle(padding: 14)
                }
                .buttonStyle(.plain)
            }
            .padding(Theme.gutter)
        }
    }

    private func qrText(_ listing: Listing) -> String {
        if let open = listing.nextOpenHouse { return "https://hashtagcinema.com/oh/\(open.id.uuidString.prefix(8).lowercased())" }
        return "https://hashtagcinema.com/l/\(listing.id.uuidString.prefix(8).lowercased())"
    }

    @MainActor
    private func share(pages: [AnyView], name: String) {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(name).pdf")
        var box = CGRect(origin: .zero, size: FlyerCanvas.size)
        guard let context = CGContext(url as CFURL, mediaBox: &box, nil) else { return }
        for page in pages {
            let renderer = ImageRenderer(content: page.frame(width: FlyerCanvas.size.width, height: FlyerCanvas.size.height))
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

// MARK: - Sign in sheet

struct SignInSheetCanvas: View {
    let listing: Listing
    let agentName: String
    let kit: BrandKit
    let qrText: String

    private let columns = ["Name", "Phone", "Email", "Have an agent?", "Pre-approved?"]
    private let widths: [CGFloat] = [126, 96, 144, 80, 86]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("WELCOME")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .kerning(2)
                        .foregroundStyle(kit.accent)
                    Text(listing.address)
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text([listing.cityLine, listing.nextOpenHouse?.label].compactMap { $0 }.joined(separator: "  ·  "))
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                    Text("Please sign in. Hosted by \(agentName)\(kit.phone.isEmpty ? "" : ", \(kit.phone)").")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.ink)
                        .padding(.top, 4)
                }
                Spacer()
                VStack(spacing: 4) {
                    QRCodeView(text: qrText)
                        .frame(width: 84, height: 84)
                    Text("Or scan to sign in")
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .padding(.bottom, 16)

            HStack(spacing: 0) {
                ForEach(Array(columns.enumerated()), id: \.offset) { index, title in
                    Text(title)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: widths[index], height: 24)
                        .background(kit.accent)
                }
            }
            ForEach(0..<18, id: \.self) { _ in
                HStack(spacing: 0) {
                    ForEach(Array(widths.enumerated()), id: \.offset) { _, width in
                        Rectangle()
                            .stroke(Theme.textTertiary.opacity(0.5), lineWidth: 0.6)
                            .frame(width: width, height: 30)
                    }
                }
            }
            Spacer(minLength: 0)
            Text("Your information is only used by \(agentName) to follow up about this home and others like it.")
                .font(.system(size: 9, design: .rounded))
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(40)
        .frame(width: FlyerCanvas.size.width, height: FlyerCanvas.size.height, alignment: .topLeading)
        .background(Color.white)
    }
}

// MARK: - Feature cards

/// Two fold over cards on a letter page. Each card's top half prints upside down
/// so it reads correctly once folded into a tent.
struct FeatureCardPage: View {
    let top: String
    let bottom: String?
    let listing: Listing
    let kit: BrandKit

    var body: some View {
        VStack(spacing: 0) {
            card(top)
            Rectangle().fill(Theme.textTertiary).frame(height: 0.5)
            if let bottom { card(bottom) } else { Color.white }
        }
        .frame(width: FlyerCanvas.size.width, height: FlyerCanvas.size.height)
        .background(Color.white)
    }

    private func card(_ text: String) -> some View {
        VStack(spacing: 0) {
            face(text)
                .rotationEffect(.degrees(180))
            Rectangle()
                .fill(Theme.textTertiary.opacity(0.6))
                .frame(height: 0.5)
                .overlay(Text("fold").font(.system(size: 7)).foregroundStyle(Theme.textTertiary).padding(.horizontal, 4).background(Color.white))
            face(text)
        }
        .frame(height: FlyerCanvas.size.height / 2)
    }

    private func face(_ text: String) -> some View {
        VStack(spacing: 6) {
            Text("DID YOU NOTICE?")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .kerning(2)
                .foregroundStyle(kit.accent)
            Text(text)
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.5)
            Text(listing.address)
                .font(.system(size: 10, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
