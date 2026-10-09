import SwiftUI
import UIKit

/// Ask past clients for a review, save what they say, and turn it into a
/// shareable card or a client story video.
struct TestimonialsView: View {
    @Environment(CinemaStore.self) private var store
    @State private var showAdd = false
    @State private var share: PosterMakerView.ShareBundle?
    @State private var openIdea: Idea?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Client love")
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Reviews are the content that wins the next listing. Collect them here and share them as posts.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Label("Ask for a review", systemImage: "text.bubble.fill")
                        .font(.cinema(16, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(store.reviewRequestMessage)
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                        .padding(12)
                        .background(Theme.surfaceRaised, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    HStack(spacing: 10) {
                        ShareLink(item: store.reviewRequestMessage) {
                            Label("Send", systemImage: "paperplane.fill")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        Button {
                            showAdd = true
                        } label: {
                            Label("Add one", systemImage: "plus")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                }
                .cardStyle()

                if store.testimonials.isEmpty {
                    EmptyStateView(title: "No testimonials yet", message: "Send the request above to your last few clients.", icon: "heart")
                }

                ForEach(store.testimonials) { testimonial in
                    VStack(alignment: .leading, spacing: 10) {
                        StarRow(rating: testimonial.stars, size: 13)
                        Text("\u{201C}\(testimonial.quote)\u{201D}")
                            .font(.cinema(16, weight: .medium))
                            .foregroundStyle(Theme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("\(testimonial.clientName) · \(testimonial.side.title) in \(testimonial.cityName)")
                            .font(.cinema(12))
                            .foregroundStyle(Theme.textSecondary)
                        HStack(spacing: 10) {
                            Button {
                                makeCard(testimonial)
                            } label: {
                                Label("Share card", systemImage: "square.and.arrow.up")
                                    .font(.cinema(13, weight: .semibold))
                            }
                            .foregroundStyle(Theme.red)
                            Spacer()
                            Button {
                                openIdea = store.addIdea(store.testimonialIdea(testimonial), announce: false)
                            } label: {
                                Label("Make it a video", systemImage: "video.badge.plus")
                                    .font(.cinema(13, weight: .semibold))
                            }
                            .foregroundStyle(Theme.red)
                        }
                        .padding(.top, 2)
                    }
                    .cardStyle()
                }
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Testimonials")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAdd) {
            AddTestimonialView()
        }
        .sheet(item: $share) { bundle in
            ActivityView(items: [bundle.image, bundle.caption])
                .presentationDetents([.medium, .large])
        }
        .navigationDestination(item: $openIdea) { idea in
            IdeaDetailView(idea: idea)
        }
    }

    @MainActor
    private func makeCard(_ testimonial: Testimonial) {
        let renderer = ImageRenderer(content: TestimonialCanvas(
            testimonial: testimonial,
            agentName: store.profile.name,
            brokerage: store.myMarketCenter?.name ?? store.profile.brokerage,
            kit: store.brandKit
        ))
        renderer.scale = 3
        guard let image = renderer.uiImage else { return }
        let caption = "Words like these are why I do this. Thank you, \(testimonial.clientName)! Thinking about buying or selling in \(testimonial.cityName)? Comment HOME and let's talk. #clientlove #\(testimonial.cityName.filter(\.isLetter).lowercased())realestate"
        share = PosterMakerView.ShareBundle(image: image, caption: caption)
    }
}

/// Square card: big quote, stars, client and agent.
struct TestimonialCanvas: View {
    let testimonial: Testimonial
    let agentName: String
    let brokerage: String
    let kit: BrandKit

    var body: some View {
        ZStack {
            Color.white
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("CLIENT LOVE")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .kerning(2)
                        .foregroundStyle(kit.accent)
                    Spacer()
                    HStack(spacing: 3) {
                        ForEach(0..<testimonial.stars, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(Color(hex: 0xF5B301))
                        }
                    }
                }
                Text("\u{201C}")
                    .font(.system(size: 72, weight: .black, design: .serif))
                    .foregroundStyle(kit.accent)
                    .frame(height: 40, alignment: .top)
                Text(testimonial.quote)
                    .font(.system(size: 21, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(7)
                    .minimumScaleFactor(0.6)
                Text("\(testimonial.clientName), \(testimonial.side.title.lowercased()) in \(testimonial.cityName)")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                Spacer(minLength: 0)
                HStack(spacing: 10) {
                    if let headshot = kit.headshotImage {
                        Image(uiImage: headshot)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text(agentName)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                        Text([kit.phone, brokerage].filter { !$0.isEmpty }.joined(separator: "  ·  "))
                            .font(.system(size: 11, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                            .lineLimit(1)
                    }
                    .foregroundStyle(Theme.ink)
                    Spacer()
                    if let logo = kit.logoImage {
                        Image(uiImage: logo)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 70, maxHeight: 30)
                    }
                }
            }
            .padding(26)
            Rectangle()
                .fill(kit.accent)
                .frame(height: 8)
                .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .frame(width: 360, height: 360)
    }
}

struct AddTestimonialView: View {
    @Environment(CinemaStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var quote = ""
    @State private var stars = 5
    @State private var side: Testimonial.Side = .buyer
    @State private var cityName = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Client") {
                    TextField("Client name, like Maria and Luis G.", text: $name)
                    Picker("They were a", selection: $side) {
                        ForEach(Testimonial.Side.allCases) { Text($0.title).tag($0) }
                    }
                    Picker("City", selection: $cityName) {
                        ForEach(store.allMarkets) { market in
                            Text(market.name).tag(market.name)
                        }
                    }
                }
                Section("What they said") {
                    TextField("Paste their words", text: $quote, axis: .vertical)
                        .lineLimit(4...8)
                    Stepper("\(stars) star\(stars == 1 ? "" : "s")", value: $stars, in: 1...5)
                }
                Section {
                    Text("Only share reviews your client agreed to make public.")
                        .font(.cinema(12))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .navigationTitle("Add testimonial")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { if cityName.isEmpty { cityName = store.homeCity.name } }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.addTestimonial(Testimonial(clientName: name, quote: quote, stars: stars, side: side, cityName: cityName, date: Date()))
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || quote.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
