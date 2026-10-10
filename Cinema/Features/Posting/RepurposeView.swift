import SwiftUI
import UIKit

/// One video, everywhere: captions, posts, an email and a text from the same script.
struct RepurposeView: View {
    @Environment(CinemaStore.self) private var store
    let idea: Idea
    @State private var shareText: ShareText?

    struct ShareText: Identifiable {
        let id = UUID()
        let text: String
    }

    var body: some View {
        content(idea)
        .cinemaScreen()
        .navigationTitle("Post it everywhere")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $shareText) { item in
            ActivityView(items: [item.text])
        }
    }

    private func content(_ idea: Idea) -> some View {
        let city = FloridaMarkets.all.first { $0.name == idea.cityName } ?? store.homeCity
        let pieces = Repurposer.pieces(for: idea, city: city, agentName: store.profile.name, brokerage: store.profile.brokerage)
        return ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(idea.title)
                        .font(.cinema(22, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("One video, \(pieces.count) ways to use it. Copy each one where it goes, or share it straight to the app.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }
                ForEach(pieces) { piece in
                    pieceCard(piece)
                }
            }
            .padding(Theme.gutter)
        }
    }

    private func pieceCard(_ piece: Repurposer.Piece) -> some View {
        let full = [piece.subject, piece.text].compactMap { $0 }.joined(separator: "\n\n")
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: piece.icon)
                    .foregroundStyle(Theme.red)
                Text(piece.title)
                    .font(.cinema(15, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                if let limit = piece.limit {
                    Text("\(full.count)/\(limit.formatted())")
                        .font(.cinema(11, weight: .semibold))
                        .foregroundStyle(full.count > limit ? Theme.red : Theme.textTertiary)
                }
            }
            if let subject = piece.subject {
                Text(subject)
                    .font(.cinema(14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
            }
            Text(piece.text)
                .font(.cinema(14))
                .foregroundStyle(Theme.textSecondary)
                .textSelection(.enabled)
            HStack(spacing: 10) {
                Button {
                    UIPasteboard.general.string = full
                    store.showToast("\(piece.title) copied")
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .buttonStyle(SecondaryButtonStyle())
                Button {
                    shareText = ShareText(text: full)
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .font(.cinema(14, weight: .semibold))
        }
        .cardStyle()
    }
}
