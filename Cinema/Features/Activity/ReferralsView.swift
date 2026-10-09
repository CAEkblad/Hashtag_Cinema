import SwiftUI
import UIKit

/// Give 2, get 2: every agent who joins with your code gives you both 2 edit credits.
struct ReferralsView: View {
    @Environment(CinemaStore.self) private var store
    @State private var name = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                hero
                inviteCard
                if !store.referrals.isEmpty { list }
                howItWorks
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Invite agents")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "gift.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(Theme.red, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(store.creditsEarnedFromReferrals)")
                        .font(.cinema(28, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("credits earned")
                        .font(.cinema(12))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            Text("Give 2 edits, get 2 edits")
                .font(.cinema(24, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text("Every agent who joins with your code gets 2 free edit credits, and so do you. No limit.")
                .font(.cinema(14))
                .foregroundStyle(Theme.textSecondary)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Your code")
                        .font(.cinema(11, weight: .bold))
                        .foregroundStyle(Theme.textTertiary)
                    Text(store.referralCode)
                        .font(.system(size: 22, weight: .heavy, design: .monospaced))
                        .foregroundStyle(Theme.textPrimary)
                }
                Spacer()
                Button {
                    UIPasteboard.general.string = store.referralCode
                    store.showToast("Code copied")
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.cinema(14, weight: .semibold))
                }
                .foregroundStyle(Theme.red)
            }
            .padding(14)
            .background(Theme.surfaceRaised, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            ShareLink(item: store.referralMessage) {
                Label("Share my invite", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .cardStyle()
    }

    private var inviteCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Invite someone by name")
            Text("We'll track them here. Send the invite by text or DM.")
                .font(.cinema(13))
                .foregroundStyle(Theme.textSecondary)
            HStack(spacing: 10) {
                TextField("Agent's name", text: $name)
                    .textContentType(.name)
                    .inputStyle()
                Button("Invite") {
                    store.invite(name)
                    name = ""
                }
                .buttonStyle(PrimaryButtonStyle(fullWidth: false))
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            Text("Demo: invited agents join after a few seconds so you can see the reward.")
                .font(.cinema(11))
                .foregroundStyle(Theme.textTertiary)
        }
    }

    private var list: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Your invites")
            ForEach(store.referrals) { referral in
                HStack(spacing: 12) {
                    Avatar(initials: initials(referral.name), size: 38, paletteIndex: referral.name.count)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(referral.name)
                            .font(.cinema(15, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Text(referral.date.relative)
                            .font(.cinema(12))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    Spacer()
                    Pill(
                        text: referral.status.title,
                        icon: referral.status == .rewarded ? "checkmark.seal.fill" : "clock",
                        color: referral.status == .rewarded ? Theme.success.opacity(0.15) : Theme.surfaceRaised,
                        textColor: referral.status == .rewarded ? Theme.success : Theme.textSecondary
                    )
                }
                .cardStyle(padding: 12)
            }
        }
    }

    private var howItWorks: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "How it works")
            IconRow(icon: "1.circle.fill", title: "Share your code", subtitle: "Text it, DM it, or post it in your office group")
            IconRow(icon: "2.circle.fill", title: "They sign up", subtitle: "Any plan, including the free Starter plan")
            IconRow(icon: "3.circle.fill", title: "You both get 2 credits", subtitle: "Credits land after their first video is filmed")
        }
        .cardStyle()
    }

    private func initials(_ name: String) -> String {
        String(name.split(separator: " ").prefix(2).compactMap { $0.first }).uppercased()
    }
}
