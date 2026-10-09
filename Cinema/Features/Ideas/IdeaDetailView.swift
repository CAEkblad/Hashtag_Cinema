import SwiftUI

struct IdeaDetailView: View {
    let idea: Idea
    @State private var doneShots: Set<Int> = []
    @State private var showCamera = false
    @State private var practice = false
    @State private var showUpload = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Pill(text: idea.category.title, icon: idea.category.icon)
                        Pill(text: "\(idea.targetSeconds) seconds", icon: "timer")
                    }
                    Text(idea.title)
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    label("THE HOOK")
                    Text("\u{201C}\(idea.hook)\u{201D}")
                        .font(.cinema(20, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(idea.whyItWorks)
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 12) {
                    label("SHOT LIST")
                    ForEach(Array(idea.shots.enumerated()), id: \.offset) { index, shot in
                        Button {
                            if doneShots.contains(index) { doneShots.remove(index) } else { doneShots.insert(index) }
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: doneShots.contains(index) ? "checkmark.circle.fill" : "\(index + 1).circle")
                                    .font(.system(size: 20))
                                    .foregroundStyle(doneShots.contains(index) ? Theme.success : Theme.red)
                                Text(shot)
                                    .font(.cinema(15))
                                    .foregroundStyle(Theme.textPrimary)
                                    .strikethrough(doneShots.contains(index), color: Theme.textTertiary)
                                    .multilineTextAlignment(.leading)
                                Spacer(minLength: 0)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 8) {
                    label("SCRIPT")
                    Text(idea.script)
                        .font(.cinema(16))
                        .foregroundStyle(Theme.textPrimary)
                        .lineSpacing(4)
                    Text("Shows on the teleprompter while you film.")
                        .font(.cinema(12))
                        .foregroundStyle(Theme.textTertiary)
                }
                .cardStyle()
            }
            .padding(Theme.gutter)
            .padding(.bottom, 120)
        }
        .cinemaScreen()
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 10) {
                Button {
                    practice = false
                    showCamera = true
                } label: {
                    Label("Film with teleprompter", systemImage: "video.fill")
                }
                .buttonStyle(PrimaryButtonStyle())

                HStack(spacing: 10) {
                    Button("Practice first") {
                        practice = true
                        showCamera = true
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    Button("Upload instead") { showUpload = true }
                        .buttonStyle(SecondaryButtonStyle())
                }
            }
            .padding(Theme.gutter)
            .background(.ultraThinMaterial)
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView(idea: idea, practiceMode: practice)
        }
        .sheet(isPresented: $showUpload) {
            EditRequestView(idea: idea, recordedURL: nil, sourceLabel: "Video from your camera roll")
        }
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.cinema(12, weight: .bold))
            .foregroundStyle(Theme.red)
            .tracking(1)
    }
}
