import SwiftUI
import UIKit

/// Branded 3 page buyer and seller guides for Florida, sent as PDFs.
/// Pairs with the GUIDE comment keyword.
struct ClientGuidesView: View {
    @Environment(CinemaStore.self) private var store
    @State private var kind: ClientGuide.Kind = .buyer
    @State private var clientName = ""
    @State private var page = 0
    @State private var shareFile: ShareFile?

    private func canvas(_ page: Int) -> ClientGuideCanvas {
        ClientGuideCanvas(
            guide: ClientGuide(kind: kind),
            page: page,
            clientName: clientName.trimmingCharacters(in: .whitespaces),
            city: store.homeCity,
            agentName: store.profile.name,
            brokerage: store.myMarketCenter?.name ?? store.profile.brokerage,
            kit: store.brandKit
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Buyer and seller guides")
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("A 3 page guide in your brand that walks a client through every step, with Florida costs and deadlines. Send it when someone comments GUIDE or after a first call.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                Picker("Guide", selection: $kind) {
                    ForEach(ClientGuide.Kind.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .onChange(of: kind) { _, _ in page = 0 }

                TextField("Client's name (optional)", text: $clientName)
                    .textContentType(.name)
                    .inputStyle()

                VStack(spacing: 10) {
                    canvas(page)
                        .scaleEffect(300 / FlyerCanvas.size.width, anchor: .topLeading)
                        .frame(width: 300, height: 300 * FlyerCanvas.size.height / FlyerCanvas.size.width, alignment: .topLeading)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .shadow(color: .black.opacity(0.15), radius: 12, y: 5)
                    HStack(spacing: 18) {
                        Button { page = max(0, page - 1) } label: { Image(systemName: "chevron.left") }
                            .disabled(page == 0)
                        Text("Page \(page + 1) of \(ClientGuide.pageCount)")
                            .font(.cinema(13, weight: .semibold))
                            .foregroundStyle(Theme.textSecondary)
                        Button { page = min(ClientGuide.pageCount - 1, page + 1) } label: { Image(systemName: "chevron.right") }
                            .disabled(page == ClientGuide.pageCount - 1)
                    }
                    .tint(Theme.red)
                }
                .frame(maxWidth: .infinity)

                Button {
                    makePDF()
                } label: {
                    Label("Share PDF", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(PrimaryButtonStyle())

                Text("General information for Florida, not legal, tax or lending advice. Costs and timelines vary by contract, county and loan.")
                    .font(.cinema(11))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Client guides")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .sheet(item: $shareFile) { file in
            ActivityView(items: [file.url])
                .presentationDetents([.medium, .large])
        }
    }

    @MainActor
    private func makePDF() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(kind.title)-guide.pdf".replacingOccurrences(of: " ", with: "-"))
        var box = CGRect(origin: .zero, size: FlyerCanvas.size)
        guard let context = CGContext(url as CFURL, mediaBox: &box, nil) else { return }
        for index in 0..<ClientGuide.pageCount {
            let renderer = ImageRenderer(content: canvas(index))
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

// MARK: - Content

struct ClientGuide {
    enum Kind: String, CaseIterable, Identifiable {
        case buyer, seller
        var id: String { rawValue }
        var title: String { self == .buyer ? "Buyer" : "Seller" }
    }

    static let pageCount = 3

    let kind: Kind

    struct Step { let title: String; let detail: String; let when: String }

    var headline: String { kind == .buyer ? "Your home buying guide" : "Your home selling guide" }

    var steps: [Step] {
        switch kind {
        case .buyer:
            return [
                Step(title: "Get pre-approved", detail: "Talk to a lender first so you know your budget and sellers take your offer seriously.", when: "Week 1"),
                Step(title: "Sign a buyer agreement", detail: "A short written agreement that says how we work together and how I'm paid. Required before touring.", when: "Week 1"),
                Step(title: "Tour homes", detail: "I'll set up showings, send new listings the day they hit and flag homes that aren't online yet.", when: "Weeks 1 to 4"),
                Step(title: "Make an offer", detail: "We'll look at recent sales and write a strong offer. Most Florida homes sell on the AS IS contract.", when: "When it's the one"),
                Step(title: "Escrow deposit", detail: "Your good faith deposit goes to the title company, usually within 3 days of the accepted offer.", when: "Days 1 to 3"),
                Step(title: "Inspections", detail: "A home inspection, plus wind mitigation and a 4 point on older homes. These also help lower insurance.", when: "Days 1 to 15"),
                Step(title: "Appraisal and loan approval", detail: "The lender orders the appraisal and finishes underwriting. Keep your finances exactly as they are.", when: "Days 15 to 30"),
                Step(title: "Insurance, walk through, closing", detail: "Bind homeowners insurance, do a final walk through, sign and get your keys.", when: "Days 30 to 45")
            ]
        case .seller:
            return [
                Step(title: "Price it right", detail: "We'll look at recent sales and what's competing with you now. The right price brings the most buyers in the first two weeks.", when: "Week 1"),
                Step(title: "Prep the home", detail: "Small fixes, decluttering and a deep clean make the biggest difference for the money.", when: "Weeks 1 to 2"),
                Step(title: "Photos, video and drone", detail: "Professional media is what gets buyers to book a showing. Most buyers see your home online first.", when: "Before launch"),
                Step(title: "Launch and showings", detail: "Your home goes live on the MLS and every major site, with social video and an open house.", when: "Launch week"),
                Step(title: "Offers and negotiation", detail: "I'll compare every offer on what you actually net and how likely it is to close.", when: "Weeks 1 to 4"),
                Step(title: "Inspections and appraisal", detail: "The buyer inspects and the lender appraises. I'll guide you through any repair requests.", when: "Days 1 to 30"),
                Step(title: "Closing", detail: "You sign at the title company, hand over the keys and get paid.", when: "Days 30 to 45")
            ]
        }
    }

    var costsTitle: String { kind == .buyer ? "What it costs" : "What you'll pay" }

    var costs: [(String, String)] {
        switch kind {
        case .buyer:
            return [
                ("Down payment", "As little as 3% on many conventional loans, 3.5% FHA, and 0% for VA loans."),
                ("Closing costs", "Usually about 2% to 5% of the price: lender fees, title, prepaid taxes and insurance."),
                ("Florida loan taxes", "Doc stamps on the mortgage note are $0.35 per $100 borrowed, and intangible tax is 0.2% of the loan."),
                ("Title insurance", "Who pays for the owner's policy depends on the county and the contract."),
                ("Insurance", "Homeowners insurance is required by your lender. Flood insurance is a separate policy."),
                ("After you move in", "File for homestead exemption by March 1 to save on property taxes.")
            ]
        case .seller:
            return [
                ("Deed doc stamps", "$0.70 per $100 of the sale price ($0.60 in Miami-Dade)."),
                ("Title insurance", "In many Florida counties the seller pays for the buyer's owner's policy."),
                ("Commission", "Agent compensation is negotiable and set in our listing agreement."),
                ("Mortgage payoff", "Your remaining loan balance is paid from your proceeds at closing."),
                ("Prorated taxes and HOA", "You pay your share of this year's property taxes and any HOA dues up to closing."),
                ("Repairs and credits", "Anything you agree to fix or credit after the inspection.")
            ]
        }
    }

    var checklistTitle: String { kind == .buyer ? "Until closing, please don't" : "Before photos" }

    var checklist: [String] {
        switch kind {
        case .buyer:
            return [
                "Open new credit cards or loans",
                "Change jobs or how you're paid",
                "Make large deposits you can't document",
                "Move money between accounts without telling your lender",
                "Buy furniture or a car on credit"
            ]
        case .seller:
            return [
                "Clear counters and put away personal photos",
                "Replace burned out bulbs and use the same color in every room",
                "Touch up paint and fix anything that drips, sticks or squeaks",
                "Mow, edge, mulch and pressure wash the drive and entry",
                "Open every blind and turn on every light for the shoot"
            ]
        }
    }

    var closingNote: String {
        kind == .buyer
            ? "Questions at any step? Text me. There are no dumb questions when it's this much money."
            : "Florida sellers must tell buyers about known issues that affect the home's value. When in doubt, disclose it and we'll talk it through."
    }
}

// MARK: - Page

struct ClientGuideCanvas: View {
    let guide: ClientGuide
    let page: Int
    let clientName: String
    let city: FloridaCity
    let agentName: String
    let brokerage: String
    let kit: BrandKit

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Group {
                switch page {
                case 0: stepsPage
                case 1: costsPage
                default: lastPage
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 20)
            Spacer(minLength: 0)
            footer
        }
        .frame(width: FlyerCanvas.size.width, height: FlyerCanvas.size.height)
        .background(Color.white)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(page == 0 ? (clientName.isEmpty ? "\(city.name.uppercased()) AND AREA" : "PREPARED FOR \(clientName.uppercased())") : guide.headline.uppercased())
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .kerning(2)
                .foregroundStyle(.white.opacity(0.85))
            Text(page == 0 ? guide.headline : (page == 1 ? guide.costsTitle : "Good to know"))
                .font(.system(size: page == 0 ? 32 : 24, weight: .black, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, page == 0 ? 26 : 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(kit.accent)
    }

    private var stepsPage: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Step by step")
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.ink)
            ForEach(Array(guide.steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(kit.accent, in: Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(step.title)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.ink)
                            Spacer()
                            Text(step.when)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(kit.accent)
                        }
                        Text(step.detail)
                            .font(.system(size: 13.5, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private var costsPage: some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(Array(guide.costs.enumerated()), id: \.offset) { _, item in
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.0)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.ink)
                    Text(item.1)
                        .font(.system(size: 15, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.bottom, 4)
                .overlay(alignment: .bottom) { Rectangle().fill(Theme.stroke).frame(height: 1).offset(y: 12) }
            }
            Text(guide.kind == .buyer ? "I'll send you an estimate of your cash to close before you make an offer." : "I'll send you a net sheet showing what you walk away with before you list and with every offer.")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(kit.accent)
                .padding(.top, 6)
        }
    }

    private var lastPage: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(guide.checklistTitle)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.ink)
            ForEach(guide.checklist, id: \.self) { item in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: guide.kind == .buyer ? "xmark.circle.fill" : "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(kit.accent)
                    Text(item)
                        .font(.system(size: 15, design: .rounded))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Text(guide.closingNote)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(18)
                .background(Theme.surfaceRaised, in: RoundedRectangle(cornerRadius: 10))
                .padding(.top, 8)
            if !city.neighborhoods.isEmpty {
                Text("Areas I know best: \(city.neighborhoods.prefix(5).joined(separator: ", ")).")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            if let headshot = kit.headshotImage {
                Image(uiImage: headshot)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 46, height: 46)
                    .clipShape(Circle())
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(agentName)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                Text([kit.phone, kit.website].filter { !$0.isEmpty }.joined(separator: "  ·  "))
                    .font(.system(size: 11, design: .rounded))
                Text(brokerage)
                    .font(.system(size: 10, design: .rounded))
                    .opacity(0.75)
            }
            .foregroundStyle(.white)
            Spacer()
            Text("\(page + 1)/\(ClientGuide.pageCount)")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
            if let logo = kit.logoImage {
                Image(uiImage: logo).resizable().scaledToFit().frame(maxWidth: 90, maxHeight: 36)
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 16)
        .background(Theme.ink)
    }
}
