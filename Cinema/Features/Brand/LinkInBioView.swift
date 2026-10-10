import SwiftUI
import UIKit

/// The agent's link in bio page: one link for Instagram and TikTok with booking,
/// home value, listings, videos and reviews. Hosted by CloseUp once the backend is live.
struct BioPage: Codable, Equatable {
    var headline = ""
    var about = ""
    var showBookCall = true
    var showHomeValue = true
    var showListings = true
    var showVideos = true
    var showReviews = true
}

struct LinkInBioView: View {
    @Environment(CinemaStore.self) private var store
    @State private var page = BioPage()
    @State private var loaded = false

    private var slug: String {
        store.profile.name.lowercased().filter { $0.isLetter || $0 == " " }.split(separator: " ").joined(separator: "-")
    }
    private var link: String { "https://hashtagcinema.com/a/\(slug.isEmpty ? "agent" : slug)" }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Link in bio")
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("One link for your Instagram and TikTok bio. Every button sends leads to you.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                HStack {
                    Spacer()
                    BioPagePreview(page: page, store: store)
                        .frame(width: 270, height: 520)
                        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 34, style: .continuous).stroke(Theme.ink, lineWidth: 8))
                        .shadow(color: .black.opacity(0.15), radius: 16, y: 6)
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        QRCodeView(text: link)
                            .frame(width: 70, height: 70)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(link)
                                .font(.cinema(13, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)
                                .lineLimit(2)
                            Text("Goes live with the CloseUp backend")
                                .font(.cinema(11))
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                    HStack(spacing: 10) {
                        Button {
                            UIPasteboard.general.string = link
                            store.showToast("Link copied")
                        } label: {
                            Label("Copy link", systemImage: "link")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        ShareLink(item: link) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 10) {
                    Text("Your intro")
                        .font(.cinema(15, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    TextField("Headline, like \"Helping families move to \(store.homeCity.name)\"", text: $page.headline)
                        .inputStyle()
                    TextField("A sentence about you", text: $page.about, axis: .vertical)
                        .lineLimit(2...4)
                        .inputStyle()
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Buttons")
                        .font(.cinema(15, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Toggle("Book a call", isOn: $page.showBookCall)
                    Toggle("What's my home worth?", isOn: $page.showHomeValue)
                    Toggle("My listings", isOn: $page.showListings)
                    Toggle("Watch my videos", isOn: $page.showVideos)
                    Toggle("Client reviews", isOn: $page.showReviews)
                }
                .font(.cinema(15))
                .tint(Theme.red)
                .cardStyle()
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Link in bio")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            guard !loaded else { return }
            page = store.bioPage
            if page.headline.isEmpty { page.headline = store.brandKit.tagline.isEmpty ? "Your \(store.homeCity.name) real estate guide" : store.brandKit.tagline }
            loaded = true
        }
        .onChange(of: page) { _, value in
            if loaded { store.saveBioPage(value) }
        }
    }
}

/// What visitors see on their phone.
struct BioPagePreview: View {
    let page: BioPage
    let store: CinemaStore

    var body: some View {
        let kit = store.brandKit
        ScrollView {
            VStack(spacing: 12) {
                Group {
                    if let headshot = kit.headshotImage {
                        Image(uiImage: headshot)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Text(store.profile.initials)
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(kit.accent)
                    }
                }
                .frame(width: 84, height: 84)
                .clipShape(Circle())
                .padding(.top, 28)

                Text(store.profile.name)
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Text(page.headline)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                if !page.about.isEmpty {
                    Text(page.about)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 8) {
                    if page.showBookCall { button("Book a call", icon: "phone.fill", filled: true, accent: kit.accent) }
                    if page.showHomeValue { button("What's my home worth?", icon: "house.fill", filled: false, accent: kit.accent) }
                    if page.showListings { button("My listings", icon: "key.fill", filled: false, accent: kit.accent) }
                    if page.showVideos { button("Watch my videos", icon: "play.rectangle.fill", filled: false, accent: kit.accent) }
                    if page.showReviews { button("Client reviews", icon: "star.fill", filled: false, accent: kit.accent) }
                }
                .padding(.horizontal, 18)

                if page.showListings, let listing = store.listings.first(where: { $0.status != .sold }) {
                    HStack(spacing: 10) {
                        Theme.gradient(listing.paletteIndex)
                            .frame(width: 56, height: 44)
                            .overlay(Image(systemName: listing.symbol).foregroundStyle(.white))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        VStack(alignment: .leading, spacing: 1) {
                            Text(listing.priceLabel)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                            Text(listing.address)
                                .font(.system(size: 11, design: .rounded))
                                .foregroundStyle(Theme.textSecondary)
                                .lineLimit(1)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(10)
                    .background(Theme.surfaceRaised, in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 18)
                }

                if page.showReviews, let review = store.testimonials.first {
                    VStack(spacing: 4) {
                        Text("\u{201C}\(review.quote)\u{201D}")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.ink)
                            .multilineTextAlignment(.center)
                            .lineLimit(4)
                        Text(review.clientName)
                            .font(.system(size: 10, design: .rounded))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    .padding(.horizontal, 22)
                }

                Text(store.myMarketCenter?.name ?? store.profile.brokerage)
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(Theme.textTertiary)
                    .padding(.vertical, 16)
            }
            .frame(maxWidth: .infinity)
        }
        .background(Color.white)
        .allowsHitTesting(false)
    }

    private func button(_ title: String, icon: String, filled: Bool, accent: Color) -> some View {
        Label(title, systemImage: icon)
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(filled ? Color.white : accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(filled ? accent : Color.white, in: Capsule())
            .overlay(Capsule().stroke(accent, lineWidth: filled ? 0 : 1.5))
    }
}
