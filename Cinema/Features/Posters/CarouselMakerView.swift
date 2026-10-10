import SwiftUI
import UIKit

/// Swipe carousels for Instagram and Facebook: a cover, tip slides and a
/// call to action, in the 4:5 size that takes up the most of the feed.
struct CarouselMakerView: View {
    @Environment(CinemaStore.self) private var store
    @State private var title = ""
    @State private var slides: [CarouselSlide] = []
    @State private var keyword = "GUIDE"
    @State private var dark = false
    @State private var page = 0
    @State private var share: CarouselShare?
    @State private var didLoad = false

    struct CarouselShare: Identifiable {
        let id = UUID()
        let items: [Any]
    }

    private var pageCount: Int { slides.count + 2 }

    private func canvas(_ index: Int) -> CarouselCanvas {
        CarouselCanvas(index: index, title: title, slides: slides, keyword: keyword, dark: dark, agentName: store.profile.name, kit: store.brandKit)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Carousels")
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Swipe posts get saved and shared more than almost anything else. Start from a topic, make it yours, and post the slides together.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(CarouselTopic.all(city: store.homeCity.name)) { topic in
                            Button { apply(topic) } label: {
                                Text(topic.title)
                                    .font(.cinema(12, weight: .semibold))
                                    .lineLimit(1)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(title == topic.title ? Theme.red : Theme.surfaceRaised, in: Capsule())
                                    .foregroundStyle(title == topic.title ? .white : Theme.textPrimary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                VStack(spacing: 10) {
                    canvas(min(page, pageCount - 1))
                        .scaleEffect(300 / CarouselCanvas.size.width, anchor: .topLeading)
                        .frame(width: 300, height: 300 * CarouselCanvas.size.height / CarouselCanvas.size.width, alignment: .topLeading)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .shadow(color: .black.opacity(0.15), radius: 12, y: 5)
                        .gesture(DragGesture(minimumDistance: 20).onEnded { value in
                            if value.translation.width < -30 { page = min(pageCount - 1, page + 1) }
                            if value.translation.width > 30 { page = max(0, page - 1) }
                        })
                    HStack(spacing: 18) {
                        Button { page = max(0, page - 1) } label: { Image(systemName: "chevron.left") }
                            .disabled(page == 0)
                        Text("Slide \(min(page, pageCount - 1) + 1) of \(pageCount)")
                            .font(.cinema(13, weight: .semibold))
                            .foregroundStyle(Theme.textSecondary)
                        Button { page = min(pageCount - 1, page + 1) } label: { Image(systemName: "chevron.right") }
                            .disabled(page >= pageCount - 1)
                    }
                    .tint(Theme.red)
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Cover")
                        .font(.cinema(15, weight: .bold))
                    TextField("Cover title", text: $title)
                        .inputStyle()
                    Toggle(isOn: $dark) {
                        Text("Dark slides").font(.cinema(14, weight: .semibold))
                    }
                    .tint(Theme.red)
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 10) {
                    Text("Slides")
                        .font(.cinema(15, weight: .bold))
                    ForEach(slides) { slide in
                        let binding = binding(for: slide)
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Slide \((slides.firstIndex(of: slide) ?? 0) + 2)")
                                    .font(.cinema(12, weight: .bold))
                                    .foregroundStyle(Theme.textTertiary)
                                Spacer()
                                Button {
                                    withAnimation { slides.removeAll { $0.id == slide.id } }
                                    page = min(page, slides.count + 1)
                                } label: {
                                    Image(systemName: "minus.circle.fill").foregroundStyle(Theme.textTertiary)
                                }
                                .disabled(slides.count <= 1)
                            }
                            TextField("Headline", text: binding.headline)
                                .inputStyle()
                            TextField("One or two short lines", text: binding.body, axis: .vertical)
                                .lineLimit(2...4)
                                .inputStyle()
                        }
                    }
                    if slides.count < 8 {
                        Button {
                            withAnimation { slides.append(CarouselSlide(headline: "", body: "")) }
                        } label: {
                            Label("Add a slide", systemImage: "plus")
                                .font(.cinema(14, weight: .semibold))
                        }
                        .tint(Theme.red)
                    }
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 10) {
                    Text("Last slide")
                        .font(.cinema(15, weight: .bold))
                    TextField("Keyword people comment", text: $keyword)
                        .textInputAutocapitalization(.characters)
                        .inputStyle()
                    Text("Pair it with Auto DM keywords so everyone who comments gets your guide.")
                        .font(.cinema(12))
                        .foregroundStyle(Theme.textTertiary)
                }
                .cardStyle()

                Button { export() } label: {
                    Label("Save all \(pageCount) slides", systemImage: "square.and.arrow.down.on.square")
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)

                Text("On Instagram, tap + then pick all the slides in order. The caption is copied with them.")
                    .font(.cinema(12))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Carousels")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            guard !didLoad else { return }
            didLoad = true
            if let first = CarouselTopic.all(city: store.homeCity.name).first { apply(first) }
        }
        .sheet(item: $share) { bundle in
            ActivityView(items: bundle.items)
                .presentationDetents([.medium, .large])
        }
    }

    private func apply(_ topic: CarouselTopic) {
        title = topic.title
        slides = topic.slides.map { CarouselSlide(headline: $0.0, body: $0.1) }
        keyword = topic.keyword
        page = 0
    }

    private func binding(for slide: CarouselSlide) -> Binding<CarouselSlide> {
        Binding(
            get: { slides.first { $0.id == slide.id } ?? slide },
            set: { value in
                if let index = slides.firstIndex(where: { $0.id == slide.id }) { slides[index] = value }
            }
        )
    }

    private var caption: String {
        let city = store.homeCity.name
        return "\(title) \u{1F447}\n\nSave this for later and share it with someone who needs it. Want the full guide? Comment \(keyword.uppercased()) and I'll send it to you.\n\n#\(city.filter(\.isLetter).lowercased())realestate #\(city.filter(\.isLetter).lowercased())realtor #floridahomes #realestatetips"
    }

    @MainActor
    private func export() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        var items: [Any] = (0..<pageCount).compactMap { index -> UIImage? in
            let renderer = ImageRenderer(content: canvas(index))
            renderer.scale = 1080 / CarouselCanvas.size.width
            return renderer.uiImage
        }
        guard !items.isEmpty else { return }
        UIPasteboard.general.string = caption
        items.append(caption)
        share = CarouselShare(items: items)
    }
}

struct CarouselSlide: Identifiable, Hashable {
    var id = UUID()
    var headline: String
    var body: String
}

struct CarouselTopic: Identifiable {
    let title: String
    let keyword: String
    let slides: [(String, String)]
    var id: String { title }

    static func all(city: String) -> [CarouselTopic] {
        [
            CarouselTopic(title: "5 mistakes first time buyers make", keyword: "BUYER", slides: [
                ("Shopping before pre-approval", "You'll fall for a home you can't get. Talk to a lender first."),
                ("Draining every dollar for the down payment", "Keep cash for closing costs, moving and the first repair."),
                ("Skipping the inspection", "A few hundred dollars now can save you thousands later."),
                ("Opening new credit before closing", "No new cars or furniture on credit until you have the keys."),
                ("Not checking insurance early", "In Florida, get quotes before you write the offer.")
            ]),
            CarouselTopic(title: "What closing costs really are", keyword: "COSTS", slides: [
                ("Lender fees", "Origination, appraisal and credit report."),
                ("Title and escrow", "Title insurance and the closing agent's fees."),
                ("Prepaids", "Your first insurance year, plus taxes and interest held up front."),
                ("Plan for 2 to 5%", "Of the price, on top of your down payment. Sellers can sometimes help.")
            ]),
            CarouselTopic(title: "How to sell for top dollar in \(city)", keyword: "SELL", slides: [
                ("Price it right on day one", "The first two weeks bring the most buyers. Don't waste them."),
                ("Fix the little things", "Paint, lights and caulk. Buyers notice everything."),
                ("Pro photos and video", "Most buyers decide from their phone if they'll come see it."),
                ("Make it easy to show", "Every missed showing is a buyer who sees another house.")
            ]),
            CarouselTopic(title: "Renting vs buying in \(city)", keyword: "RENT", slides: [
                ("Renting", "Flexible, no repairs, but every payment goes to your landlord."),
                ("Buying", "Payments build equity and lock in your housing cost."),
                ("The break even point", "Usually 3 to 5 years. Plan to stay that long? Buying often wins."),
                ("Run your numbers", "Every situation is different. Let's look at yours.")
            ]),
            CarouselTopic(title: "Florida home insurance, explained", keyword: "INSURE", slides: [
                ("Get quotes early", "Before you make an offer, not after."),
                ("Roof age matters", "Older roofs can mean higher rates or fewer options."),
                ("Ask for a 4 point and wind mitigation", "They can lower your premium."),
                ("Flood is separate", "Even outside a flood zone, ask what it would cost.")
            ]),
            CarouselTopic(title: "Your first 30 days in a new home", keyword: "MOVE", slides: [
                ("Change the locks", "You never know who has a key."),
                ("Find the shut offs", "Water, power and gas, before you need them."),
                ("File your homestead exemption", "In Florida it can save you a lot on taxes. Deadline is March 1."),
                ("Meet the neighbors", "Best way to learn the area fast.")
            ])
        ]
    }
}

struct CarouselCanvas: View {
    static let size = CGSize(width: 360, height: 450)

    let index: Int
    let title: String
    let slides: [CarouselSlide]
    let keyword: String
    let dark: Bool
    let agentName: String
    let kit: BrandKit

    private var total: Int { slides.count + 2 }
    private var background: Color { dark ? Theme.ink : .white }
    private var ink: Color { dark ? .white : Theme.ink }
    private var soft: Color { dark ? .white.opacity(0.75) : Theme.textSecondary }

    var body: some View {
        ZStack {
            if index == 0 {
                cover
            } else if index == total - 1 {
                cta
            } else {
                tip(slides[min(index - 1, max(slides.count - 1, 0))], number: index)
            }
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .clipped()
    }

    private var footer: some View {
        HStack(spacing: 8) {
            if let headshot = kit.headshotImage {
                Image(uiImage: headshot).resizable().scaledToFill().frame(width: 26, height: 26).clipShape(Circle())
            }
            Text(agentName)
                .font(.system(size: 12, weight: .bold, design: .rounded))
            Spacer()
            Text("\(index + 1)/\(total)")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .opacity(0.7)
        }
    }

    private var cover: some View {
        ZStack {
            kit.accent
            VStack(alignment: .leading, spacing: 16) {
                Text("SAVE THIS")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .kerning(2)
                    .foregroundStyle(.white.opacity(0.85))
                Text(title.isEmpty ? "Your title here" : title)
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.5)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                HStack(spacing: 6) {
                    Text("Swipe")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundStyle(.white)
                footer.foregroundStyle(.white)
            }
            .padding(28)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private func tip(_ slide: CarouselSlide, number: Int) -> some View {
        ZStack {
            background
            VStack(alignment: .leading, spacing: 14) {
                Text("\(number)")
                    .font(.system(size: 72, weight: .black, design: .rounded))
                    .foregroundStyle(kit.accent)
                Text(slide.headline.isEmpty ? "Headline" : slide.headline)
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundStyle(ink)
                    .minimumScaleFactor(0.6)
                    .fixedSize(horizontal: false, vertical: true)
                Text(slide.body)
                    .font(.system(size: 21, weight: .medium, design: .rounded))
                    .foregroundStyle(soft)
                    .minimumScaleFactor(0.7)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                footer.foregroundStyle(ink)
            }
            .padding(28)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            Rectangle().fill(kit.accent).frame(width: 6).frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var cta: some View {
        ZStack {
            background
            VStack(spacing: 16) {
                Spacer()
                if let headshot = kit.headshotImage {
                    Image(uiImage: headshot).resizable().scaledToFill().frame(width: 90, height: 90).clipShape(Circle())
                }
                Text("Want the full guide?")
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundStyle(ink)
                    .multilineTextAlignment(.center)
                Text("Comment")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(soft)
                Text(keyword.isEmpty ? "GUIDE" : keyword.uppercased())
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .kerning(2)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)
                    .background(kit.accent, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .foregroundStyle(.white)
                Text("and I'll send it to you.")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(soft)
                Spacer()
                footer.foregroundStyle(ink)
            }
            .padding(28)
        }
    }
}
