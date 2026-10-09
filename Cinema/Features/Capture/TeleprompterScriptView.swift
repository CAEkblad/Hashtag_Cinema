import SwiftUI
import UIKit

/// Paste or type your own script and film it with the teleprompter.
struct TeleprompterScriptView: View {
    @Environment(CinemaStore.self) private var store
    @State private var text = ""
    @State private var filming: Idea?

    private var words: Int { text.split { $0.isWhitespace || $0.isNewline }.count }
    /// About 150 spoken words a minute.
    private var seconds: Int { max(5, Int((Double(words) / 2.5).rounded())) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your own script")
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Paste anything, like a listing description or talking points, and read it on the teleprompter while you film.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                TextEditor(text: $text)
                    .font(.cinema(17))
                    .frame(minHeight: 260)
                    .scrollContentBackground(.hidden)
                    .padding(10)
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Theme.stroke, lineWidth: 1))
                    .overlay(alignment: .topLeading) {
                        if text.isEmpty {
                            Text("Start with your hook. Keep it to one idea.")
                                .font(.cinema(17))
                                .foregroundStyle(Theme.textTertiary)
                                .padding(18)
                                .allowsHitTesting(false)
                        }
                    }

                HStack {
                    Label("\(words) words", systemImage: "text.word.spacing")
                    Spacer()
                    Label("About \(seconds) seconds", systemImage: "timer")
                }
                .font(.cinema(13, weight: .semibold))
                .foregroundStyle(seconds > 90 ? Theme.warning : Theme.textSecondary)

                if seconds > 90 {
                    Text("Over 90 seconds. Short videos get watched to the end more often. Try cutting it in half.")
                        .font(.cinema(12))
                        .foregroundStyle(Theme.warning)
                }

                HStack(spacing: 10) {
                    Button {
                        if let paste = UIPasteboard.general.string { text = paste }
                    } label: {
                        Label("Paste", systemImage: "doc.on.clipboard")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    Button {
                        filming = idea()
                    } label: {
                        Label("Start filming", systemImage: "video.fill")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(words == 0)
                    .opacity(words == 0 ? 0.5 : 1)
                }
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Teleprompter")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .fullScreenCover(item: $filming) { idea in
            CameraView(idea: idea, practiceMode: false)
        }
    }

    private func idea() -> Idea {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let firstSentence = trimmed.split(whereSeparator: { ".!?\n".contains($0) }).first.map(String.init) ?? trimmed
        return Idea(
            title: String(firstSentence.prefix(60)),
            hook: firstSentence,
            category: .dayInLife,
            shots: ["Read it to the lens, phone at eye level"],
            script: trimmed,
            targetSeconds: seconds,
            whyItWorks: "Your own words, read naturally, sound the most like you.",
            cityName: store.homeCity.name
        )
    }
}
