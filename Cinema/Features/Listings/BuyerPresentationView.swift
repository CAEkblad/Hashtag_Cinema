import SwiftUI
import UIKit

/// A branded buyer consultation PDF: what you do, the process, and how you're paid
/// under the written buyer agreement buyers sign before touring.
struct BuyerPresentationView: View {
    @Environment(CinemaStore.self) private var store
    @State private var buyerName = ""
    @State private var feeKind: FeeKind = .percent
    @State private var percent: Double = 2.5
    @State private var flat = ""
    @State private var termDays = 90
    @State private var services: Set<Service> = Set(Service.allCases)
    @State private var page = 0
    @State private var shareFile: ShareFile?

    enum FeeKind: String, CaseIterable, Identifiable {
        case percent, flat
        var id: String { rawValue }
        var title: String { self == .percent ? "Percent of price" : "Flat fee" }
    }

    enum Service: String, CaseIterable, Identifiable {
        case search, offMarket, showings, video, pricing, negotiate, inspections, pros, closing
        var id: String { rawValue }
        var title: String {
            switch self {
            case .search: return "A search built around you"
            case .offMarket: return "Homes before they hit the portals"
            case .showings: return "Showings on your schedule"
            case .video: return "Video tours when you can't make it"
            case .pricing: return "Pricing every home you love"
            case .negotiate: return "Writing and negotiating your offer"
            case .inspections: return "Inspections and repair requests"
            case .pros: return "Trusted lenders, inspectors and insurance"
            case .closing: return "Every deadline to the closing table"
            }
        }
        var detail: String {
            switch self {
            case .search: return "New listings the day they hit, filtered to what you actually want."
            case .offMarket: return "Coming soon and off market homes from my agent network."
            case .showings: return "Tours planned in driving order so we see more in less time."
            case .video: return "I'll walk it on video and point out what photos hide."
            case .pricing: return "Recent sales and what the home should really sell for."
            case .negotiate: return "Terms that protect you, not just the lowest price."
            case .inspections: return "We'll read the reports together and ask for what matters."
            case .pros: return "People I've seen do great work, with no referral fees."
            case .closing: return "Deposit, inspection, appraisal and loan dates tracked with reminders."
            }
        }
        var icon: String {
            switch self {
            case .search: return "magnifyingglass"
            case .offMarket: return "eye.slash.fill"
            case .showings: return "car.fill"
            case .video: return "video.fill"
            case .pricing: return "chart.line.uptrend.xyaxis"
            case .negotiate: return "signature"
            case .inspections: return "checklist"
            case .pros: return "person.2.fill"
            case .closing: return "calendar.badge.clock"
            }
        }
    }

    private var feeLine: String {
        switch feeKind {
        case .percent: return "\(percent.formatted(.number.precision(.fractionLength(0...2))))% of the purchase price"
        case .flat:
            let digits = flat.filter(\.isNumber)
            return digits.isEmpty ? "A flat fee of $[amount]" : "A flat fee of \((Int(digits) ?? 0).formatted(.currency(code: "USD").precision(.fractionLength(0))))"
        }
    }

    private func canvas(_ page: Int) -> BuyerPresentationCanvas {
        BuyerPresentationCanvas(
            page: page,
            buyerName: buyerName.trimmingCharacters(in: .whitespaces),
            services: Service.allCases.filter { services.contains($0) },
            feeLine: feeLine,
            termDays: termDays,
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
                    Text("Buyer consultation")
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Walk new buyers through what you do and how you're paid before you tour. A written buyer agreement is now required before showing homes, so this makes that conversation easy.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                TextField("Buyer's name (optional)", text: $buyerName)
                    .textContentType(.name)
                    .inputStyle()

                VStack(alignment: .leading, spacing: 10) {
                    Text("How you're paid")
                        .font(.cinema(15, weight: .bold))
                    Picker("Fee", selection: $feeKind) {
                        ForEach(FeeKind.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    if feeKind == .percent {
                        Stepper("\(percent.formatted(.number.precision(.fractionLength(0...2))))%", value: $percent, in: 0.5...6, step: 0.25)
                    } else {
                        TextField("Flat fee, like 9500", text: $flat)
                            .keyboardType(.numberPad)
                            .inputStyle()
                    }
                    Stepper("Agreement length: \(termDays) days", value: $termDays, in: 1...365, step: termDays < 30 ? 1 : 15)
                    Text("Use the terms in your brokerage's buyer agreement. Compensation is always negotiable.")
                        .font(.cinema(12))
                        .foregroundStyle(Theme.textTertiary)
                }
                .font(.cinema(14))
                .cardStyle()

                VStack(alignment: .leading, spacing: 8) {
                    Text("What you do")
                        .font(.cinema(15, weight: .bold))
                    ForEach(Service.allCases) { service in
                        Button {
                            if services.contains(service) { services.remove(service) } else { services.insert(service) }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: services.contains(service) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(services.contains(service) ? Theme.red : Theme.textTertiary)
                                Text(service.title)
                                    .font(.cinema(14))
                                    .foregroundStyle(Theme.textPrimary)
                                Spacer(minLength: 0)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .cardStyle()

                VStack(spacing: 10) {
                    canvas(page)
                        .scaleEffect(300 / FlyerCanvas.size.width, anchor: .topLeading)
                        .frame(width: 300, height: 300 * FlyerCanvas.size.height / FlyerCanvas.size.width, alignment: .topLeading)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .shadow(color: .black.opacity(0.15), radius: 12, y: 5)
                    HStack(spacing: 18) {
                        Button { page = max(0, page - 1) } label: { Image(systemName: "chevron.left") }
                            .disabled(page == 0)
                        Text("Page \(page + 1) of \(BuyerPresentationCanvas.pageCount)")
                            .font(.cinema(13, weight: .semibold))
                            .foregroundStyle(Theme.textSecondary)
                        Button { page = min(BuyerPresentationCanvas.pageCount - 1, page + 1) } label: { Image(systemName: "chevron.right") }
                            .disabled(page == BuyerPresentationCanvas.pageCount - 1)
                    }
                    .tint(Theme.red)
                }
                .frame(maxWidth: .infinity)

                Button { makePDF() } label: {
                    Label("Share PDF", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(PrimaryButtonStyle())

                NavigationLink(value: Route.clientGuides) {
                    IconRow(icon: "book.pages.fill", title: "Send the buyer guide too", subtitle: "Every step, Florida costs and what not to do before closing")
                        .cardStyle(padding: 14)
                }
                .buttonStyle(.plain)
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Buyer consultation")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .sheet(item: $shareFile) { file in
            ActivityView(items: [file.url])
                .presentationDetents([.medium, .large])
        }
    }

    @MainActor
    private func makePDF() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Buyer-consultation.pdf")
        var box = CGRect(origin: .zero, size: FlyerCanvas.size)
        guard let context = CGContext(url as CFURL, mediaBox: &box, nil) else { return }
        for index in 0..<BuyerPresentationCanvas.pageCount {
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

struct BuyerPresentationCanvas: View {
    static let pageCount = 3

    let page: Int
    let buyerName: String
    let services: [BuyerPresentationView.Service]
    let feeLine: String
    let termDays: Int
    let city: FloridaCity
    let agentName: String
    let brokerage: String
    let kit: BrandKit

    private var first: String { agentName.split(separator: " ").first.map(String.init) ?? agentName }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(page == 0 ? (buyerName.isEmpty ? "BUYER CONSULTATION" : "PREPARED FOR \(buyerName.uppercased())") : "BUYER CONSULTATION")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .kerning(2)
                    .foregroundStyle(.white.opacity(0.85))
                Text(["Let's find your home", "What I do for you", "How we work together"][min(page, 2)])
                    .font(.system(size: page == 0 ? 32 : 26, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, page == 0 ? 26 : 20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(kit.accent)

            Group {
                switch page {
                case 0: cover
                case 1: servicesPage
                default: termsPage
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 22)

            Spacer(minLength: 0)
            footer
        }
        .frame(width: FlyerCanvas.size.width, height: FlyerCanvas.size.height)
        .background(Color.white)
    }

    private var cover: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 18) {
                if let headshot = kit.headshotImage {
                    Image(uiImage: headshot).resizable().scaledToFill().frame(width: 120, height: 120).clipShape(Circle())
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Hi, I'm \(agentName).")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(Theme.ink)
                    Text(kit.tagline.isEmpty ? "I help buyers find the right home in \(city.name) and get it for the right price, with no surprises along the way." : kit.tagline)
                        .font(.system(size: 15, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Text("Today we'll cover")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.ink)
                .padding(.top, 6)
            ForEach(["What you want in your next home and neighborhood", "Your budget and talking to a lender", "What I do for you, start to finish", "How I'm paid and our buyer agreement", "Next steps and your first showings"], id: \.self) { item in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(kit.accent)
                    Text(item).font(.system(size: 15, design: .rounded)).foregroundStyle(Theme.ink)
                }
            }
            if !city.neighborhoods.isEmpty {
                Text("Areas I know best: \(city.neighborhoods.prefix(5).joined(separator: ", ")).")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.top, 6)
            }
        }
    }

    private var servicesPage: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(services) { service in
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: service.icon)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(kit.accent, in: Circle())
                    VStack(alignment: .leading, spacing: 3) {
                        Text(service.title)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.ink)
                        Text(service.detail)
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private var termsPage: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("How I'm paid")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Text(feeLine)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(kit.accent)
                Text("Often the seller agrees to pay some or all of this, and we can ask for it in your offer. If they don't, we'll talk through your options before you write. You never pay more than what's in our agreement.")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Our buyer agreement")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.ink)
                ForEach([
                    "A short written agreement we sign before touring homes.",
                    "It lasts \(termDays) days and spells out what I do and how I'm paid.",
                    "Compensation is negotiable and set between us.",
                    "Questions about any part of it? Ask. I'll walk you through every line."
                ], id: \.self) { item in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "doc.text.fill").foregroundStyle(kit.accent)
                        Text(item).font(.system(size: 14, design: .rounded)).foregroundStyle(Theme.ink).fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Next steps")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.ink)
                ForEach(Array(["Sign the buyer agreement", "Talk to a lender and get pre-approved", "I set up your home search", "We book your first showings"].enumerated()), id: \.offset) { index, item in
                    HStack(spacing: 10) {
                        Text("\(index + 1)")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(width: 22, height: 22)
                            .background(kit.accent, in: Circle())
                        Text(item).font(.system(size: 14, design: .rounded)).foregroundStyle(Theme.ink)
                    }
                }
            }
            Text("This summary is for our conversation. The signed buyer agreement is what governs our work together.")
                .font(.system(size: 10, design: .rounded))
                .foregroundStyle(Theme.textTertiary)
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
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
            Text("\(page + 1)/\(Self.pageCount)")
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
