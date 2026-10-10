import SwiftUI
import UIKit

/// Paste listing remarks, a caption or an ad and see any wording that could
/// cause a fair housing problem, with a fix for each.
struct FairHousingView: View {
    @Environment(CinemaStore.self) private var store
    @State private var text: String
    @State private var checked = false
    @FocusState private var focused: Bool

    init(text: String = "") {
        _text = State(initialValue: text)
        _checked = State(initialValue: !text.isEmpty)
    }

    private var findings: [FairHousingCheck.Finding] { FairHousingCheck.check(text) }
    private var fixable: Int { findings.filter { ($0.replacement.map { !$0.contains("[") }) ?? false }.count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Fair housing check")
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Paste MLS remarks, a caption or an ad. CloseUp flags words that can read as a preference for or against a group of people, and suggests what to say instead. Describe the home, not who should live in it.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                VStack(alignment: .leading, spacing: 10) {
                    TextField("Paste your text here", text: $text, axis: .vertical)
                        .lineLimit(6...14)
                        .focused($focused)
                        .inputStyle()
                    HStack(spacing: 10) {
                        Button {
                            focused = false
                            checked = true
                        } label: {
                            Label("Check it", systemImage: "checkmark.shield.fill")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        #if DEBUG
                        Button("Sample") {
                            text = "Perfect for families! This exclusive neighborhood home has a master suite, a man cave and great schools, walking distance to church. Safe neighborhood. Handicap accessible ramp."
                            checked = true
                        }
                        .buttonStyle(SecondaryButtonStyle(fullWidth: false))
                        #endif
                        if let sample = sampleText {
                            Button("Use a listing") {
                                text = sample
                                checked = true
                            }
                            .buttonStyle(SecondaryButtonStyle(fullWidth: false))
                        }
                    }
                }
                .cardStyle()

                if checked && !text.isEmpty {
                    if findings.isEmpty {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 26))
                                .foregroundStyle(Theme.success)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Nothing flagged")
                                    .font(.cinema(16, weight: .bold))
                                Text("Still read it once more for anything about who the home is for.")
                                    .font(.cinema(13))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                        .cardStyle()
                    } else {
                        HStack {
                            SectionHeader(title: "\(findings.count) to look at")
                            Spacer()
                            if fixable > 0 {
                                Button {
                                    withAnimation { text = FairHousingCheck.fixAll(text) }
                                    store.showToast("Fixed \(fixable)")
                                } label: {
                                    Label("Fix \(fixable)", systemImage: "wand.and.stars")
                                        .font(.cinema(14, weight: .semibold))
                                }
                                .tint(Theme.red)
                            }
                        }
                        ForEach(findings) { finding in
                            FindingRow(finding: finding)
                        }
                        Button {
                            UIPasteboard.general.string = text
                            store.showToast("Copied")
                        } label: {
                            Label("Copy the updated text", systemImage: "doc.on.doc")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Good habits")
                        .font(.cinema(14, weight: .bold))
                    ForEach([
                        "Talk about features: rooms, yard, pool, views, updates, commute times.",
                        "Name nearby places as landmarks, not as reasons a type of person would like it.",
                        "Point buyers to public school and crime data instead of rating them yourself.",
                        "55 and over communities can say so when they legally qualify."
                    ], id: \.self) { tip in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)).foregroundStyle(Theme.red).padding(.top, 3)
                            Text(tip).font(.cinema(13)).foregroundStyle(Theme.textSecondary)
                        }
                    }
                    Text("A helper, not legal advice. Your MLS rules, your broker and HUD guidance have the final word.")
                        .font(.cinema(11))
                        .foregroundStyle(Theme.textTertiary)
                        .padding(.top, 4)
                }
                .cardStyle()
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Fair housing check")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: text) { _, _ in if text.isEmpty { checked = false } }
    }

    private var sampleText: String? {
        store.listings.first { !$0.description.isEmpty }?.description
    }
}

private struct FindingRow: View {
    let finding: FairHousingCheck.Finding

    private var color: Color {
        switch finding.level {
        case .high: return Theme.red
        case .caution: return Theme.warning
        case .style: return Theme.textTertiary
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(finding.level.title.uppercased())
                    .font(.cinema(10, weight: .heavy))
                    .kerning(1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(color.opacity(0.14), in: Capsule())
                    .foregroundStyle(color)
                Text(finding.topic)
                    .font(.cinema(12, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
            }
            Text("\u{201C}\(finding.phrase)\u{201D}")
                .font(.cinema(16, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text(finding.why)
                .font(.cinema(13))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            if let replacement = finding.replacement {
                Label("Try: \(replacement)", systemImage: "arrow.turn.down.right")
                    .font(.cinema(13, weight: .semibold))
                    .foregroundStyle(Theme.success)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}
