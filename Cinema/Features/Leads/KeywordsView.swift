import SwiftUI

/// A comment keyword and the DM that goes out when someone comments it.
struct KeywordRule: Identifiable, Hashable, Codable {
    var id = UUID()
    var keyword: String
    var message: String
    var link: String = ""
    var isOn = true

    var fullMessage: String { link.isEmpty ? message : "\(message) \(link)" }

    static func defaults(city: String) -> [KeywordRule] {
        [
            KeywordRule(keyword: "TOUR", message: "Thanks for watching! Here's the full tour and the details. Want to see it in person this week?"),
            KeywordRule(keyword: "VALUE", message: "Happy to help! I'll put together a free value report for your home. What's the address?"),
            KeywordRule(keyword: "MARKET", message: "Here's this month's \(city) market update. Thinking about buying or selling this year?"),
            KeywordRule(keyword: "GUIDE", message: "Here's my Moving to Florida guide! Where are you moving from, and when?"),
            KeywordRule(keyword: "LENDER", message: "Here's the lender I trust most. Tell them I sent you and they'll take great care of you.")
        ]
    }
}

struct KeywordsView: View {
    @Environment(CinemaStore.self) private var store
    @State private var editing: KeywordRule?
    @State private var showNew = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Auto DM keywords")
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("End a video with \"Comment TOUR\" and everyone who does gets your DM instantly. Their name lands in Leads.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                ForEach(store.keywordRules) { rule in
                    let count = store.leads.filter { $0.keyword.uppercased() == rule.keyword.uppercased() }.count
                    VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(rule.keyword.uppercased())
                                    .font(.cinema(18, weight: .heavy))
                                    .foregroundStyle(rule.isOn ? Theme.red : Theme.textTertiary)
                                Spacer()
                                Text("\(count) lead\(count == 1 ? "" : "s")")
                                    .font(.cinema(12, weight: .semibold))
                                    .foregroundStyle(Theme.textSecondary)
                                Toggle("On", isOn: Binding(get: { rule.isOn }, set: { store.setKeywordRule(rule.id, on: $0) }))
                                    .labelsHidden()
                                    .tint(Theme.red)
                            }
                            HStack(alignment: .bottom, spacing: 8) {
                                Text("Commented \(rule.keyword.uppercased())")
                                    .font(.cinema(12))
                                    .foregroundStyle(Theme.textPrimary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Theme.surfaceRaised, in: Capsule())
                                Spacer(minLength: 20)
                            }
                            HStack {
                                Spacer(minLength: 40)
                                Text(rule.fullMessage)
                                    .font(.cinema(13))
                                    .foregroundStyle(.white)
                                    .multilineTextAlignment(.leading)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 9)
                                    .background(Theme.red.opacity(rule.isOn ? 1 : 0.4), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                            Button {
                                editing = rule
                            } label: {
                                Label("Edit", systemImage: "pencil")
                                    .font(.cinema(13, weight: .semibold))
                                    .foregroundStyle(Theme.red)
                            }
                    }
                    .cardStyle()
                }

                Button {
                    showNew = true
                } label: {
                    Label("Add a keyword", systemImage: "plus")
                }
                .buttonStyle(SecondaryButtonStyle())

                Text("Auto DMs send from your Instagram and Facebook once they're connected. Pick any of these keywords when you post.")
                    .font(.cinema(11))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Keywords")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editing) { rule in
            KeywordEditor(rule: rule, isNew: false)
        }
        .sheet(isPresented: $showNew) {
            KeywordEditor(rule: KeywordRule(keyword: "", message: "Thanks for commenting! Here's what you asked for:"), isNew: true)
        }
    }
}

struct KeywordEditor: View {
    @Environment(CinemaStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State var rule: KeywordRule
    let isNew: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Keyword, like POOL", text: $rule.keyword)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                } footer: {
                    Text("One short word is easiest to comment. Avoid words people type anyway, like WOW.")
                }
                Section("The DM they get") {
                    TextField("Message", text: $rule.message, axis: .vertical)
                        .lineLimit(3...6)
                    TextField("Link (optional)", text: $rule.link)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                }
                if !isNew {
                    Section {
                        Button("Delete keyword", role: .destructive) {
                            store.deleteKeywordRule(rule.id)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(isNew ? "New keyword" : rule.keyword.uppercased())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var saved = rule
                        saved.keyword = String(saved.keyword.uppercased().filter { $0.isLetter || $0.isNumber }.prefix(16))
                        store.saveKeywordRule(saved)
                        dismiss()
                    }
                    .disabled(rule.keyword.filter { $0.isLetter || $0.isNumber }.isEmpty || rule.message.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
