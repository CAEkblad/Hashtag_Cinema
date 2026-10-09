import SwiftUI

/// Sends a phone clip to the AI editing pipeline (and an editor for Pro edits).
struct EditRequestView: View {
    let idea: Idea?
    let recordedURL: URL?
    let sourceLabel: String
    var onSubmitted: (() -> Void)? = nil

    @Environment(CinemaStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var style: EditStyle = .bold
    @State private var proEdit = false
    @State private var captions = true
    @State private var music = true
    @State private var brandKit = true
    @State private var rush = false
    @State private var notes = ""

    private var request: EditRequest {
        EditRequest(
            title: title.isEmpty ? (idea?.title ?? "New clip") : title,
            ideaID: idea?.id,
            style: style,
            captions: captions,
            music: music,
            brandKit: brandKit,
            rush: rush,
            proEdit: proEdit,
            notes: notes,
            localVideoURL: recordedURL
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "film.fill")
                            .foregroundStyle(Theme.red)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(sourceLabel)
                                .font(.cinema(15, weight: .semibold))
                            if let idea {
                                Text(idea.title)
                                    .font(.cinema(13))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                    }
                    TextField("Title (optional)", text: $title)
                }

                Section {
                    Picker("Edit type", selection: $proEdit) {
                        Text("Instant (AI)").tag(false)
                        Text("Pro (AI + editor)").tag(true)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Edit type")
                } footer: {
                    Text(proEdit
                         ? "AI makes the first cut, then a #Cinema editor polishes it."
                         : "AI cuts dead air and bad takes, adds captions and branding. Ready in minutes.")
                }

                Section("Style") {
                    ForEach(EditStyle.allCases) { option in
                        Button {
                            style = option
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(option.title)
                                        .foregroundStyle(Theme.textPrimary)
                                    Text(option.detail)
                                        .font(.cinema(12))
                                        .foregroundStyle(Theme.textSecondary)
                                }
                                Spacer()
                                if style == option {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Theme.red)
                                }
                            }
                        }
                    }
                }

                Section("Options") {
                    Toggle("Captions", isOn: $captions)
                    Toggle("Music", isOn: $music)
                    Toggle("Logo and brokerage disclaimer", isOn: $brandKit)
                    Toggle("Rush delivery (+1 credit)", isOn: $rush)
                }

                Section("Notes for the editor") {
                    TextField("Anything we should know?", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }

                Section {
                    HStack {
                        Text("Cost")
                        Spacer()
                        Text("\(request.creditCost) credit\(request.creditCost == 1 ? "" : "s")")
                            .fontWeight(.semibold)
                    }
                    HStack {
                        Text("You have")
                        Spacer()
                        Text("\(store.profile.credits) credits")
                            .foregroundStyle(store.profile.credits >= request.creditCost ? Theme.textSecondary : Theme.red)
                    }
                    Text("Delivered in 9:16, 1:1 and 16:9.")
                        .font(.cinema(12))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Send to editing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    if store.submitEditRequest(request) != nil {
                        dismiss()
                        onSubmitted?()
                    }
                } label: {
                    Label("Send to #Cinema", systemImage: "paperplane.fill")
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(store.profile.credits < request.creditCost)
                .opacity(store.profile.credits < request.creditCost ? 0.5 : 1)
                .padding(Theme.gutter)
                .background(.ultraThinMaterial)
            }
        }
    }
}
