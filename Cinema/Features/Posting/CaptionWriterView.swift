import SwiftUI
import UIKit

/// A caption and hashtags for any video, sized for each platform.
struct CaptionWriterView: View {
    @Environment(CinemaStore.self) private var store
    @State private var topic = ""
    @State private var keyword = "HOME"
    @State private var tone: Tone = .friendly
    @State private var platform: SocialPlatform = .instagram

    enum Tone: String, CaseIterable, Identifiable {
        case friendly, expert, luxury, fun
        var id: String { rawValue }
        var title: String { rawValue.capitalized }
    }

    private var city: FloridaCity { store.homeCity }

    private var hashtags: [String] {
        let cityTag = city.name.filter(\.isLetter).lowercased()
        let countyTag = city.county.filter(\.isLetter).lowercased()
        var tags = ["#\(cityTag)realestate", "#\(cityTag)homes", "#\(countyTag)county", "#floridarealestate", "#floridahomes"]
        if city.has(.beach) { tags.append("#beachlife") }
        if city.has(.boating) { tags.append("#waterfronthomes") }
        if city.has(.luxury) { tags.append("#luxuryrealestate") }
        if city.has(.growth) { tags.append("#newconstruction") }
        tags.append("#realtor")
        return tags
    }

    private var caption: String {
        let subject = topic.trimmingCharacters(in: .whitespaces).isEmpty ? "life in \(city.name)" : topic.trimmingCharacters(in: .whitespaces)
        let opener: String
        switch tone {
        case .friendly: opener = "Let's talk about \(subject)! 🏡"
        case .expert: opener = "What you need to know about \(subject) in \(city.name)."
        case .luxury: opener = "\(subject.capitalizedFirst). Elevated living in \(city.name)."
        case .fun: opener = "POV: you just discovered \(subject) 👀"
        }
        let body: String
        switch tone {
        case .friendly: body = "I love helping families find their place in \(city.name). Save this for later and share it with someone thinking about a move."
        case .expert: body = "I break down what this means for buyers and sellers in \(city.county) County, in plain English."
        case .luxury: body = "Private showings available for qualified buyers."
        case .fun: body = "Tag the friend who needs to see this."
        }
        let cta = "Comment \(keyword.uppercased()) and I'll send you the details."
        let tags = hashtags.prefix(platform == .tiktok ? 5 : 9).joined(separator: " ")
        switch platform {
        case .youtube:
            return "\(opener) \(cta)\n\n\(tags.split(separator: " ").prefix(3).joined(separator: " "))"
        default:
            return "\(opener)\n\n\(body)\n\n\(cta)\n\n\(tags)"
        }
    }

    private var limit: Int {
        switch platform {
        case .instagram: return 2_200
        case .facebook: return 2_200
        case .tiktok: return 2_200
        case .youtube: return 100
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Caption writer")
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Caption, call to action and \(city.name) hashtags, sized for each platform.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }
                TextField("What's the video about?", text: $topic)
                    .inputStyle()
                TextField("Comment keyword", text: $keyword)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .inputStyle()
                Picker("Tone", selection: $tone) {
                    ForEach(Tone.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                Picker("Platform", selection: $platform) {
                    ForEach(SocialPlatform.allCases) { Text($0.name).tag($0) }
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading, spacing: 10) {
                    Text(caption)
                        .font(.cinema(15))
                        .foregroundStyle(Theme.textPrimary)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack {
                        Text(platform == .youtube ? "Shorts title: \(caption.count) of \(limit)" : "\(caption.count) of \(limit) characters")
                            .font(.cinema(12, weight: .semibold))
                            .foregroundStyle(caption.count > limit ? Theme.red : Theme.textTertiary)
                        Spacer()
                        Button {
                            UIPasteboard.general.string = caption
                            store.showToast("Caption copied")
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                                .font(.cinema(14, weight: .semibold))
                        }
                        .foregroundStyle(Theme.red)
                    }
                }
                .cardStyle()

                NavigationLink(value: Route.fairHousing(caption)) {
                    IconRow(icon: "checkmark.shield.fill", title: "Fair housing check", subtitle: "Make sure the wording describes the home, not the buyer")
                        .cardStyle(padding: 14)
                }
                .buttonStyle(.plain)
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Captions")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
    }
}
