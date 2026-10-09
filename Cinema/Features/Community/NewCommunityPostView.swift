import SwiftUI

struct NewCommunityPostView: View {
    @Environment(CinemaStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var kind: CommunityPostKind = .win
    @State private var text = ""

    private var prompt: String {
        switch kind {
        case .win: return "Share a result: views, leads, a listing you won from video..."
        case .idea: return "Share an idea that worked so others can remix it..."
        case .question: return "Ask agents across the country..."
        case .lesson: return "What did you learn that others should know?"
        }
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Picker("Type", selection: $kind) {
                    ForEach(CommunityPostKind.allCases) { option in
                        Label(option.title, systemImage: option.icon).tag(option)
                    }
                }
                .pickerStyle(.segmented)

                TextField(prompt, text: $text, axis: .vertical)
                    .lineLimit(6...12)
                    .inputStyle()

                Text("Keep it helpful. Include your brokerage name on any listing you share and follow fair housing rules.")
                    .font(.cinema(12))
                    .foregroundStyle(Theme.textTertiary)

                Spacer()
            }
            .padding(Theme.gutter)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("New post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") {
                        store.addCommunityPost(kind: kind, body: text.trimmingCharacters(in: .whitespacesAndNewlines))
                        dismiss()
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
