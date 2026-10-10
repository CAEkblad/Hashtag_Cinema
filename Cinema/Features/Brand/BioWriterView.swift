import SwiftUI
import UIKit

/// Profile bios for every platform, sized to each one's character limit.
struct BioWriterView: View {
    @Environment(CinemaStore.self) private var store
    @State private var specialty: BioSpecialty = .buyersSellers
    @State private var years = ""
    @State private var personal = ""
    @State private var keyword = "HOME"
    @State private var style = 0
    @State private var copied: String?
    @State private var didLoad = false

    private var input: BioInput {
        BioInput(
            name: store.profile.name,
            city: store.homeCity.name,
            areas: store.homeCity.neighborhoods.prefix(2).map { $0 },
            brokerage: store.myMarketCenter?.name ?? store.profile.brokerage,
            specialty: specialty,
            years: Int(years.filter(\.isNumber)),
            personal: personal.trimmingCharacters(in: .whitespaces),
            keyword: keyword.trimmingCharacters(in: .whitespaces).uppercased(),
            style: style
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Profile bios")
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Your bio is the first thing people read after a video. Say who you help, where, and what to do next. These fit each platform's limit.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Picker("Who you help", selection: $specialty) {
                        ForEach(BioSpecialty.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.menu)
                    .tint(Theme.red)
                    TextField("Years in real estate (optional)", text: $years)
                        .keyboardType(.numberPad)
                        .inputStyle()
                    TextField("Something personal, like dog mom, Gators fan, native", text: $personal)
                        .inputStyle()
                    TextField("Comment or DM keyword", text: $keyword)
                        .textInputAutocapitalization(.characters)
                        .inputStyle()
                }
                .font(.cinema(14))
                .cardStyle()

                HStack {
                    Text("Versions")
                        .font(.cinema(15, weight: .bold))
                    Spacer()
                    Button {
                        style = (style + 1) % 3
                        copied = nil
                    } label: {
                        Label("Try another", systemImage: "arrow.triangle.2.circlepath")
                            .font(.cinema(14, weight: .semibold))
                    }
                    .tint(Theme.red)
                }

                ForEach(BioPlatform.allCases) { platform in
                    bioCard(platform)
                }

                NavigationLink(value: Route.linkInBio) {
                    IconRow(icon: "link", title: "Put your link in bio page in it", subtitle: "One link to your listings, guides and booking")
                        .cardStyle(padding: 14)
                }
                .buttonStyle(.plain)

                Text("Florida rules: include your brokerage's name wherever you advertise, including social profiles.")
                    .font(.cinema(11))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Profile bios")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            guard !didLoad else { return }
            didLoad = true
            let niche = store.profile.niche.lowercased()
            if niche.contains("luxury") { specialty = .luxury }
            else if niche.contains("first") { specialty = .firstTime }
            else if niche.contains("relocat") { specialty = .relocation }
            else if niche.contains("invest") { specialty = .investors }
            else if niche.contains("water") { specialty = .waterfront }
        }
    }

    private func bioCard(_ platform: BioPlatform) -> some View {
        let bio = BioWriter.bio(for: platform, input)
        let isCopied = copied == platform.rawValue
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(platform.title, systemImage: platform.icon)
                    .font(.cinema(14, weight: .bold))
                Spacer()
                Text("\(bio.count)/\(platform.limit)")
                    .font(.cinema(12, weight: .semibold))
                    .foregroundStyle(bio.count > platform.limit ? Theme.red : Theme.textTertiary)
            }
            Text(bio)
                .font(.cinema(14))
                .foregroundStyle(Theme.textPrimary)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                UIPasteboard.general.string = bio
                copied = platform.rawValue
                store.showToast("Copied for \(platform.title)")
            } label: {
                Label(isCopied ? "Copied" : "Copy", systemImage: isCopied ? "checkmark" : "doc.on.doc")
                    .font(.cinema(13, weight: .semibold))
            }
            .tint(Theme.red)
        }
        .cardStyle()
    }
}

enum BioSpecialty: String, CaseIterable, Identifiable {
    case buyersSellers, firstTime, luxury, relocation, investors, waterfront, newConstruction, condos
    var id: String { rawValue }
    var title: String {
        switch self {
        case .buyersSellers: return "Buyers and sellers"
        case .firstTime: return "First time buyers"
        case .luxury: return "Luxury homes"
        case .relocation: return "People moving to Florida"
        case .investors: return "Investors"
        case .waterfront: return "Waterfront homes"
        case .newConstruction: return "New construction"
        case .condos: return "Condos"
        }
    }
    var short: String {
        switch self {
        case .buyersSellers: return "buyers and sellers"
        case .firstTime: return "first time buyers get the keys"
        case .luxury: return "luxury buyers and sellers"
        case .relocation: return "people moving to Florida"
        case .investors: return "investors find deals"
        case .waterfront: return "waterfront buyers and sellers"
        case .newConstruction: return "buyers find new construction homes"
        case .condos: return "condo buyers and sellers"
        }
    }
    var emoji: String {
        switch self {
        case .buyersSellers: return "\u{1F3E1}"
        case .firstTime: return "\u{1F511}"
        case .luxury: return "\u{2728}"
        case .relocation: return "\u{1F334}"
        case .investors: return "\u{1F4C8}"
        case .waterfront: return "\u{1F30A}"
        case .newConstruction: return "\u{1F3D7}\u{FE0F}"
        case .condos: return "\u{1F3D9}\u{FE0F}"
        }
    }
}

enum BioPlatform: String, CaseIterable, Identifiable {
    case instagram, tiktok, facebook, youtube, website
    var id: String { rawValue }
    var title: String {
        switch self {
        case .instagram: return "Instagram"
        case .tiktok: return "TikTok"
        case .facebook: return "Facebook intro"
        case .youtube: return "YouTube"
        case .website: return "Website, Zillow and Realtor.com"
        }
    }
    var icon: String {
        switch self {
        case .instagram: return "camera.fill"
        case .tiktok: return "music.note"
        case .facebook: return "f.cursive"
        case .youtube: return "play.rectangle.fill"
        case .website: return "globe"
        }
    }
    var limit: Int {
        switch self {
        case .instagram: return 150
        case .tiktok: return 80
        case .facebook: return 101
        case .youtube: return 1000
        case .website: return 1000
        }
    }
}

struct BioInput {
    let name: String
    let city: String
    let areas: [String]
    let brokerage: String
    let specialty: BioSpecialty
    let years: Int?
    let personal: String
    let keyword: String
    let style: Int
}

enum BioWriter {
    static func bio(for platform: BioPlatform, _ input: BioInput) -> String {
        let candidates = options(for: platform, input)
        let shift = input.style % candidates.count
        let ordered: [String] = Array(candidates[shift...]) + Array(candidates[..<shift])
        let tidy: [String] = ordered.map { tidyUp($0) }
        if let fit = tidy.first(where: { $0.count <= platform.limit }) { return fit }
        return String(tidy[0].prefix(platform.limit))
    }

    private static func tidyUp(_ text: String) -> String {
        let collapsed = text.replacingOccurrences(of: "\n\n", with: "\n")
        return collapsed.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }

    private static func options(for platform: BioPlatform, _ input: BioInput) -> [String] {
        let first: String = input.name.split(separator: " ").first.map(String.init) ?? input.name
        let keyword: String = input.keyword.isEmpty ? "HOME" : input.keyword
        let city: String = input.city
        let emoji: String = input.specialty.emoji
        let short: String = input.specialty.short
        let title: String = input.specialty.title
        let lowerTitle: String = title.lowercased()
        let brokerage: String = input.brokerage
        var yearsLine = ""
        if let years = input.years, years > 0 { yearsLine = "\(years)+ years" }
        let personalLine: String = input.personal.isEmpty ? "" : "\(input.personal)\n"
        let personalDot: String = input.personal.isEmpty ? "" : "\(input.personal) · "
        let yearsDot: String = yearsLine.isEmpty ? "" : "\(yearsLine) · "

        switch platform {
        case .instagram:
            let one = "\(emoji) \(city) Realtor\u{00AE}\nHelping \(short)\n\(personalLine)\u{1F447} DM \(keyword) to start\n\(brokerage)"
            let two = "\(city) real estate, made simple \(emoji)\n\(yearsDot)\(title)\n\(personalDot)\(brokerage)\nComment \(keyword) \u{1F447}"
            let three = "I help \(short) in \(city) \(emoji)\nLocal tips daily\n\(personalLine)DM \(keyword) · \(brokerage)"
            return [one, two, three]
        case .tiktok:
            return [
                "\(city) Realtor \(emoji) DM \(keyword)",
                "\(title) in \(city) \(emoji)",
                "Your \(city) real estate friend \(emoji)"
            ]
        case .facebook:
            return [
                "\(city) Realtor with \(brokerage). Helping \(short). Message me \(keyword)!",
                "Helping \(short) in \(city). \(brokerage). Message me anytime.",
                "\(emoji) \(city) real estate. \(title). \(brokerage)."
            ]
        case .youtube:
            let areaList: String = input.areas.joined(separator: ", ")
            let areas: String = input.areas.isEmpty ? city : "\(areaList) and all of \(city)"
            let one = "Hi, I'm \(first), a Realtor with \(brokerage). This channel is everything about living in \(areas): neighborhood tours, home tours, market updates and honest advice for \(lowerTitle). New videos every week. Thinking about a move? Comment \(keyword) on any video or reach out through the link below."
            let two = "Living in \(city), explained by a local. I'm \(first) with \(brokerage), and I help \(short). Subscribe for neighborhood guides, what homes really cost, and tips you won't get anywhere else."
            let three = "\(city) real estate with \(first). Tours, market updates and straight answers for \(lowerTitle). \(brokerage)."
            return [one, two, three]
        case .website:
            var experience = ""
            if let years = input.years, years > 0 { experience = " for \(years) years" }
            let lowerPersonal: String = input.personal.lowercased()
            let personal: String = input.personal.isEmpty ? "" : " When I'm not showing homes, you'll find me being a proud \(lowerPersonal)."
            let areaPair: String = input.areas.joined(separator: " and ")
            let areas: String = input.areas.isEmpty ? "" : " I know \(areaPair) street by street."
            let one = "I'm \(input.name), a Realtor with \(brokerage), and I've helped \(short) in \(city)\(experience).\(areas) My job is to make every step clear: what homes are really worth, what to watch out for, and how to win without overpaying. I share local market updates and home tours every week, so you'll know the area before you ever see a house.\(personal) Let's talk about your plans, no pressure."
            let two = "Buying or selling in \(city) should feel exciting, not stressful. I'm \(input.name) with \(brokerage), and I focus on \(lowerTitle).\(areas) You'll get honest advice, fast answers and a plan built around your timeline.\(personal) Reach out anytime."
            let three = "\(input.name) | \(brokerage). Helping \(short) in \(city)\(experience).\(areas) Clear advice, great marketing and someone in your corner from the first showing to the closing table.\(personal)"
            return [one, two, three]
        }
    }
}
