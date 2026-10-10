import SwiftUI
import UIKit

/// Paste a comment, get a reply, a DM and a one tap lead.
struct ReplyHelperView: View {
    @Environment(CinemaStore.self) private var store
    @State private var comment = ""
    @State private var name = ""
    @State private var platform: SocialPlatform = .instagram
    @State private var savedLead: UUID?

    private var suggestion: ReplyHelper.Suggestion? {
        let clean = comment.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return nil }
        return ReplyHelper.read(clean, name: name.trimmingCharacters(in: .whitespaces), keywords: store.keywordRules, agentFirstName: store.profile.firstName, city: store.homeCity.name)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Reply helper")
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Paste a comment from any post. Get a public reply, a DM, and save it to Leads when it's a buying or selling signal.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                VStack(alignment: .leading, spacing: 10) {
                    TextField("Paste the comment", text: $comment, axis: .vertical)
                        .lineLimit(2...5)
                        .inputStyle()
                    TextField("Their name or handle (optional)", text: $name)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .inputStyle()
                    Picker("Platform", selection: $platform) {
                        ForEach(SocialPlatform.allCases) { Text($0.name).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    PasteButton(payloadType: String.self) { strings in
                        if let first = strings.first { comment = first }
                    }
                    .tint(Theme.red)
                }
                .onChange(of: comment) { _, _ in savedLead = nil }

                if let suggestion {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(suggestion.kind.title, systemImage: suggestion.kind.icon)
                            .font(.cinema(16, weight: .bold))
                            .foregroundStyle(suggestion.kind.isLead ? Theme.red : Theme.textPrimary)
                        Text(suggestion.tip)
                            .font(.cinema(13))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .cardStyle()

                    replyCard("Reply in the comments", text: suggestion.publicReply)
                    if let dm = suggestion.dm {
                        replyCard("Send as a DM", text: dm)
                    }

                    if suggestion.kind.isLead {
                        if let savedLead {
                            NavigationLink(value: Route.lead(savedLead)) {
                                Label("Saved. Open the lead", systemImage: "checkmark.circle.fill")
                            }
                            .buttonStyle(SecondaryButtonStyle())
                        } else {
                            Button {
                                savedLead = store.saveCommentLead(
                                    name: name.trimmingCharacters(in: .whitespaces),
                                    platform: platform,
                                    keyword: suggestion.keyword ?? "COMMENT",
                                    comment: comment.trimmingCharacters(in: .whitespacesAndNewlines)
                                )
                            } label: {
                                Label("Save to Leads", systemImage: "person.badge.plus")
                            }
                            .buttonStyle(PrimaryButtonStyle())
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Try one")
                            .font(.cinema(13, weight: .bold))
                            .foregroundStyle(Theme.textTertiary)
                        ForEach(["How much is this one?", "Can I see it this weekend?", "TOUR", "What would my house sell for?", "Overpriced lol"], id: \.self) { sample in
                            Button { comment = sample } label: {
                                Text(sample)
                                    .font(.cinema(14))
                                    .foregroundStyle(Theme.textPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Theme.surface, in: Capsule())
                                    .overlay(Capsule().stroke(Theme.stroke, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Reply helper")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
    }

    private func replyCard(_ title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.cinema(13, weight: .bold))
                    .foregroundStyle(Theme.red)
                Spacer()
                Button {
                    UIPasteboard.general.string = text
                    store.showToast("Copied")
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.cinema(13, weight: .semibold))
                }
                .tint(Theme.red)
            }
            Text(text)
                .font(.cinema(15))
                .foregroundStyle(Theme.textPrimary)
                .textSelection(.enabled)
        }
        .cardStyle()
    }
}
