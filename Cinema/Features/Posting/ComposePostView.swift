import SwiftUI

struct ComposePostView: View {
    let clip: Clip

    @Environment(CinemaStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var selected: Set<SocialPlatform> = []
    @State private var caption = ""
    @State private var postNow = true
    @State private var date = Date().addingTimeInterval(60 * 60 * 3)
    @State private var leadCapture = false
    @State private var keyword = "TOUR"
    @State private var dmMessage = "Thanks for reaching out! Here's the link you asked for:"
    @State private var brandedContent = false
    @State private var isPosting = false

    private var leadCaptureAvailable: Bool {
        selected.contains(where: { $0.supportsLeadCapture })
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        ClipThumbnail(clip: clip, height: 90)
                            .frame(width: 60)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(clip.title)
                                .font(.cinema(15, weight: .semibold))
                            Text("Preview shows how it posts on each platform.")
                                .font(.cinema(12))
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                }

                Section("Post to") {
                    ForEach(SocialPlatform.allCases) { platform in
                        platformRow(platform)
                    }
                }

                Section {
                    TextField("Write a caption", text: $caption, axis: .vertical)
                        .lineLimit(3...8)
                    Button {
                        caption = suggestedCaption
                    } label: {
                        Label("Write it for me", systemImage: "sparkles")
                    }
                } header: {
                    Text("Caption")
                } footer: {
                    Text("AI writes a caption and hashtags for each platform from your clip and market.")
                }

                Section {
                    Toggle("Turn comments into leads", isOn: $leadCapture)
                        .disabled(!leadCaptureAvailable)
                    if leadCapture {
                        TextField("Keyword", text: $keyword)
                            .textInputAutocapitalization(.characters)
                        TextField("Auto DM message", text: $dmMessage, axis: .vertical)
                            .lineLimit(2...4)
                    }
                } header: {
                    Text("Lead capture")
                } footer: {
                    Text(leadCaptureAvailable
                         ? "Anyone who comments \(keyword.uppercased()) gets an instant DM. Leads show up in Me > Leads."
                         : "Lead capture works on Instagram and Facebook.")
                }

                Section("When") {
                    Picker("When", selection: $postNow) {
                        Text("Post now").tag(true)
                        Text("Schedule").tag(false)
                    }
                    .pickerStyle(.segmented)
                    if !postNow {
                        DatePicker("Date and time", selection: $date, in: Date()...)
                    }
                }

                if selected.contains(.tiktok) {
                    Section {
                        Toggle("This is branded or paid content", isOn: $brandedContent)
                    } header: {
                        Text("TikTok")
                    } footer: {
                        Text("TikTok requires a disclosure choice and your OK before anything is posted.")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    Task {
                        isPosting = true
                        await store.schedulePost(
                            clip: clip,
                            platforms: SocialPlatform.allCases.filter { selected.contains($0) },
                            caption: caption,
                            date: date,
                            postNow: postNow,
                            leadKeyword: leadCapture ? keyword.uppercased() : nil
                        )
                        isPosting = false
                        dismiss()
                    }
                } label: {
                    if isPosting {
                        ProgressView().tint(.white)
                    } else {
                        Text(postNow ? "Post to \(selected.count) platform\(selected.count == 1 ? "" : "s")" : "Schedule")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(selected.isEmpty || isPosting)
                .opacity(selected.isEmpty ? 0.5 : 1)
                .padding(Theme.gutter)
                .background(.ultraThinMaterial)
            }
            .onAppear {
                selected = store.connectedPlatforms
                if caption.isEmpty { caption = suggestedCaption }
            }
        }
    }

    private func platformRow(_ platform: SocialPlatform) -> some View {
        let connected = store.connectedPlatforms.contains(platform)
        return HStack(spacing: 12) {
            Image(systemName: platform.icon)
                .foregroundStyle(Theme.red)
                .frame(width: 26)
            Text(platform.name)
            Spacer()
            if connected {
                Image(systemName: selected.contains(platform) ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected.contains(platform) ? Theme.red : Theme.textTertiary)
                    .font(.system(size: 20))
            } else {
                Button("Connect") {
                    store.connect(platform)
                    selected.insert(platform)
                }
                .font(.cinema(14, weight: .semibold))
                .buttonStyle(.borderless)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard connected else { return }
            if selected.contains(platform) { selected.remove(platform) } else { selected.insert(platform) }
        }
    }

    private var suggestedCaption: String {
        let market = store.profile.market.components(separatedBy: ",").first ?? store.profile.market
        let tag = market.replacingOccurrences(of: " ", with: "")
        let cta = leadCapture ? " Comment \(keyword.uppercased()) and I'll send you the details." : " Follow for more local real estate tips."
        return "\(clip.title).\(cta)\n\n#\(tag)RealEstate #\(tag)Homes #RealtorLife"
    }
}
