import SwiftUI
import UIKit

/// Type a topic, pick a format and length, get a hook, script and shot list.
struct ScriptWriterView: View {
    @Environment(CinemaStore.self) private var store
    @State private var type: ScriptType = .marketUpdate
    @State private var topic = ""
    @State private var seconds = 30
    @State private var cityID: String?
    @State private var draft: Idea?
    @State private var filming: Idea?
    @State private var openIdea: Idea?

    private var city: FloridaCity { FloridaMarkets.city(cityID) ?? store.homeCity }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Script writer")
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Tell us the topic. We write the hook, the script and the shots, ready for the teleprompter.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("What kind of video?")
                        .font(.cinema(15, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    FlowLayout(spacing: 8) {
                        ForEach(ScriptType.allCases) { option in
                            Button {
                                type = option
                                draft = nil
                            } label: {
                                Text(option.title)
                                    .font(.cinema(14, weight: .semibold))
                                    .foregroundStyle(type == option ? Color.white : Theme.textPrimary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 9)
                                    .background(type == option ? Theme.red : Theme.surface, in: Capsule())
                                    .overlay(Capsule().stroke(Theme.stroke, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                TextField(type.placeholder, text: $topic, axis: .vertical)
                    .lineLimit(2...4)
                    .inputStyle()

                VStack(alignment: .leading, spacing: 8) {
                    Picker("Length", selection: $seconds) {
                        Text("15 sec").tag(15)
                        Text("30 sec").tag(30)
                        Text("60 sec").tag(60)
                    }
                    .pickerStyle(.segmented)

                    if store.allMarkets.count > 1 {
                        Picker("City", selection: Binding(get: { cityID ?? store.homeCity.id }, set: { cityID = $0 })) {
                            ForEach(store.allMarkets) { market in
                                Text(market.name).tag(market.id)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(Theme.red)
                    }
                }

                Button {
                    withAnimation {
                        draft = ScriptWriter.write(type: type, topic: topic, seconds: seconds, city: city, agentName: store.profile.name)
                    }
                } label: {
                    Label(draft == nil ? "Write my script" : "Write it again", systemImage: "sparkles")
                }
                .buttonStyle(PrimaryButtonStyle())

                if let draft {
                    result(draft)
                }

                if !store.savedScripts.isEmpty {
                    SectionHeader(title: "Saved scripts")
                    ForEach(store.savedScripts) { idea in
                        Button {
                            openIdea = idea
                        } label: {
                            IdeaCard(idea: idea)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Script writer")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .fullScreenCover(item: $filming) { idea in
            CameraView(idea: idea, practiceMode: false)
        }
        .navigationDestination(item: $openIdea) { idea in
            IdeaDetailView(idea: idea)
        }
    }

    private func result(_ idea: Idea) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Pill(text: "Hook", icon: "bolt.fill", color: Theme.red, textColor: .white)
            Text("\u{201C}\(idea.hook)\u{201D}")
                .font(.cinema(19, weight: .bold))
                .foregroundStyle(Theme.textPrimary)

            Divider()

            Text("Script · about \(idea.targetSeconds) seconds")
                .font(.cinema(12, weight: .bold))
                .foregroundStyle(Theme.textTertiary)
            Text(idea.script)
                .font(.cinema(15))
                .foregroundStyle(Theme.textPrimary)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)

            Text("Shots")
                .font(.cinema(12, weight: .bold))
                .foregroundStyle(Theme.textTertiary)
            ForEach(Array(idea.shots.enumerated()), id: \.offset) { index, shot in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(index + 1)")
                        .font(.cinema(12, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(Theme.red, in: Circle())
                    Text(shot)
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }
            }

            HStack(spacing: 10) {
                Button {
                    store.saveScript(idea)
                    filming = idea
                } label: {
                    Label("Film it", systemImage: "video.fill")
                }
                .buttonStyle(PrimaryButtonStyle())
                Button {
                    store.saveScript(idea)
                } label: {
                    Text("Save")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            Button {
                UIPasteboard.general.string = idea.script
                store.showToast("Script copied")
            } label: {
                Label("Copy script", systemImage: "doc.on.doc")
                    .font(.cinema(14, weight: .semibold))
            }
            .foregroundStyle(Theme.red)
        }
        .cardStyle()
    }
}
