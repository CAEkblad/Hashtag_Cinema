import SwiftUI
import UIKit

/// This month's pop by gift ideas, printable tags and who's getting one.
struct PopBysView: View {
    @Environment(CinemaStore.self) private var store
    @State private var month = Calendar.current.component(.month, from: Date())
    @State private var picked: PopByIdea?
    @State private var shareFile: ShareFile?

    private var ideas: [PopByIdea] { PopByLibrary.ideas(for: month) }
    private var idea: PopByIdea? { picked.flatMap { p in ideas.first { $0 == p } } ?? ideas.first }
    private var monthName: String { Calendar.current.monthSymbols[max(0, min(11, month - 1))] }
    private var isThisMonth: Bool { month == Calendar.current.component(.month, from: Date()) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Pop bys for \(monthName)")
                        .font(.cinema(24, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("A small gift and a fun tag, dropped at the door. It's the touch past clients remember, and it takes 5 minutes a stop.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                HStack {
                    Button { change(-1) } label: { Image(systemName: "chevron.left") }
                    Spacer()
                    Text(isThisMonth ? "This month" : monthName)
                        .font(.cinema(14, weight: .semibold))
                    Spacer()
                    Button { change(1) } label: { Image(systemName: "chevron.right") }
                }
                .tint(Theme.red)
                .cardStyle(padding: 12)

                ForEach(ideas) { option in
                    Button { picked = option } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: option == idea ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 22))
                                .foregroundStyle(option == idea ? Theme.red : Theme.textTertiary)
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(option.item)
                                        .font(.cinema(16, weight: .bold))
                                        .foregroundStyle(Theme.textPrimary)
                                    Spacer()
                                    Text(option.cost)
                                        .font(.cinema(12, weight: .semibold))
                                        .foregroundStyle(Theme.textTertiary)
                                }
                                Text("\u{201C}\(option.tag)\u{201D}")
                                    .font(.cinema(14, weight: .semibold))
                                    .foregroundStyle(Theme.red)
                                    .multilineTextAlignment(.leading)
                                Text(option.tip)
                                    .font(.cinema(13))
                                    .foregroundStyle(Theme.textSecondary)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                        .cardStyle()
                    }
                    .buttonStyle(.plain)
                }

                if let idea {
                    VStack(spacing: 12) {
                        PopByTag(idea: idea, agentName: store.profile.name, phone: store.brandKit.phone, kit: store.brandKit)
                            .scaleEffect(1.2)
                            .frame(width: PopByTag.size.width * 1.2, height: PopByTag.size.height * 1.2)
                            .shadow(color: .black.opacity(0.12), radius: 8, y: 3)
                        Button { makeTags(idea) } label: {
                            Label("Print 10 tags", systemImage: "printer.fill")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        Text("Letter size sheet, 2 by 3.5 inch tags. Fits Avery 5371 business card paper, or cut them out.")
                            .font(.cinema(12))
                            .foregroundStyle(Theme.textTertiary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .cardStyle()
                }

                recipients
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Pop bys")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $shareFile) { file in
            ActivityView(items: [file.url])
                .presentationDetents([.medium, .large])
        }
    }

    private var recipients: some View {
        let names = recipientNames
        let delivered = store.popBysDelivered()
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionHeader(title: "Who's getting one")
                Text("\(delivered.count) of \(names.count)")
                    .font(.cinema(13, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
            }
            if names.isEmpty {
                EmptyStateView(title: "No one on your list yet", message: "Add past clients or start a touch plan and they'll show up here.", icon: "gift")
            }
            ForEach(names, id: \.self) { name in
                Button {
                    store.togglePopBy(name)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: delivered.contains(name) ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20))
                            .foregroundStyle(delivered.contains(name) ? Theme.success : Theme.textTertiary)
                        Text(name)
                            .font(.cinema(15, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                            .strikethrough(delivered.contains(name), color: Theme.textTertiary)
                        Spacer()
                        if delivered.contains(name) {
                            Text("Dropped off")
                                .font(.cinema(12, weight: .semibold))
                                .foregroundStyle(Theme.success)
                        }
                    }
                    .cardStyle(padding: 12)
                }
                .buttonStyle(.plain)
            }
            Text("Checking someone off counts as a note in your power hour. Ring the bell or leave it at the door, and snap a selfie with the gift for your stories if they're up for it.")
                .font(.cinema(12))
                .foregroundStyle(Theme.textTertiary)
        }
    }

    /// Past clients first, then everyone on a touch plan, no repeats.
    private var recipientNames: [String] {
        var seen = Set<String>()
        return (store.pastClients.map(\.name) + store.touchContacts.map(\.name)).filter { seen.insert($0.lowercased()).inserted }
    }

    private func change(_ step: Int) {
        month = (month - 1 + step + 12) % 12 + 1
        picked = nil
    }

    @MainActor
    private func makeTags(_ idea: PopByIdea) {
        let page = PopByTagSheet(idea: idea, agentName: store.profile.name, phone: store.brandKit.phone, kit: store.brandKit)
        let renderer = ImageRenderer(content: page)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Pop-by-tags-\(idea.item.filter { $0.isLetter }).pdf")
        renderer.render { size, draw in
            var box = CGRect(origin: .zero, size: size)
            guard let context = CGContext(url as CFURL, mediaBox: &box, nil) else { return }
            context.beginPDFPage(nil)
            draw(context)
            context.endPDFPage()
            context.closePDF()
        }
        shareFile = ShareFile(url: url)
    }
}

/// One 3.5 by 2 inch tag.
struct PopByTag: View {
    static let size = CGSize(width: 252, height: 144)

    let idea: PopByIdea
    let agentName: String
    let phone: String
    let kit: BrandKit

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(idea.tag)
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.ink)
                .lineLimit(3)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            HStack(spacing: 8) {
                if let headshot = kit.headshotImage {
                    Image(uiImage: headshot).resizable().scaledToFill().frame(width: 26, height: 26).clipShape(Circle())
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text(agentName)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                    if !phone.isEmpty {
                        Text(phone).font(.system(size: 8.5, design: .rounded))
                    }
                }
                .foregroundStyle(Theme.ink)
                Spacer(minLength: 0)
                if let logo = kit.logoImage {
                    Image(uiImage: logo).resizable().scaledToFit().frame(maxWidth: 54, maxHeight: 22)
                }
            }
        }
        .padding(14)
        .frame(width: Self.size.width, height: Self.size.height)
        .background(Color.white)
        .overlay(alignment: .top) { kit.accent.frame(height: 6) }
        .overlay(RoundedRectangle(cornerRadius: 0).stroke(Theme.stroke, lineWidth: 0.5))
    }
}

/// US Letter sheet of 10 tags laid out for Avery 5371 (0.5 inch top, 0.75 inch sides).
struct PopByTagSheet: View {
    let idea: PopByIdea
    let agentName: String
    let phone: String
    let kit: BrandKit

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<5, id: \.self) { _ in
                HStack(spacing: 0) {
                    PopByTag(idea: idea, agentName: agentName, phone: phone, kit: kit)
                    PopByTag(idea: idea, agentName: agentName, phone: phone, kit: kit)
                }
            }
        }
        .padding(.top, 36)
        .padding(.horizontal, 54)
        .frame(width: 612, height: 792, alignment: .top)
        .background(Color.white)
    }
}
