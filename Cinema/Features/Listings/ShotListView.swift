import SwiftUI
import UIKit

/// One shot to film on a phone for a listing video.
struct ListingShot: Identifiable, Hashable {
    var id: String { title }
    var title: String
    var how: String
    var seconds: Int
    var icon: String
}

/// Builds a phone shot list and a voiceover from what the home has.
enum ShotListWriter {
    static func shots(for listing: Listing) -> [ListingShot] {
        var list = [
            ListingShot(title: "The hook", how: "Stand at the curb, phone vertical, and say your first line before you show the home.", seconds: 3, icon: "bolt.fill"),
            ListingShot(title: "Front of the home", how: "Walk slowly toward the front door. Keep the phone at chest height and the horizon level.", seconds: 4, icon: "house.fill"),
            ListingShot(title: "Open the door", how: "Push the door open and step through. That reveal is what makes people keep watching.", seconds: 3, icon: "door.left.hand.open")
        ]
        let f = Set(listing.features)
        if f.contains(.openFloorPlan) {
            list.append(ListingShot(title: "The big room", how: "Slow pan from the entry across the living area, kitchen and dining in one move.", seconds: 4, icon: "rectangle.split.3x1.fill"))
        }
        if f.contains(.renovatedKitchen) {
            list.append(ListingShot(title: "Kitchen details", how: "Glide along the island, then a close up of the counters and hardware.", seconds: 4, icon: "fork.knife"))
        } else {
            list.append(ListingShot(title: "Kitchen", how: "Start wide from the doorway, then push in toward the counters.", seconds: 3, icon: "fork.knife"))
        }
        list.append(ListingShot(title: "Primary suite", how: "Shoot from the doorway toward the windows so the room fills with light.", seconds: 3, icon: "bed.double.fill"))
        list.append(ListingShot(title: "Primary bath", how: "One slow push toward the vanity or shower. Toilet seat down, towels straight.", seconds: 3, icon: "shower.fill"))
        if f.contains(.homeOffice) {
            list.append(ListingShot(title: "Home office", how: "Sit at the desk spot and shoot over the shoulder toward the window.", seconds: 3, icon: "desktopcomputer"))
        }
        if f.contains(.lanai) {
            list.append(ListingShot(title: "Lanai", how: "Slide the door open and walk out. Florida buyers want to see where they'll spend their evenings.", seconds: 4, icon: "sun.horizon.fill"))
        }
        if f.contains(.pool) {
            list.append(ListingShot(title: "Pool", how: "Low angle along the pool edge, moving slowly. Best in the hour before sunset.", seconds: 4, icon: "drop.fill"))
        }
        if f.contains(.waterfront) || f.contains(.gulfAccess) {
            list.append(ListingShot(title: "The water", how: "Start on the home, then turn to reveal the water. Hold still for 2 seconds at the end.", seconds: 4, icon: "water.waves"))
        }
        if f.contains(.dock) {
            list.append(ListingShot(title: "Dock walk", how: "Walk to the end of the dock, then turn around to show the home from the water side.", seconds: 4, icon: "ferry.fill"))
        }
        if f.contains(.golfView) {
            list.append(ListingShot(title: "Golf view", how: "From the back patio, a slow pan across the fairway.", seconds: 3, icon: "figure.golf"))
        }
        if f.contains(.impactWindows) || f.contains(.newRoof) || f.contains(.solar) {
            list.append(ListingShot(title: "The upgrades", how: "Quick close ups: the impact window label, the roof line, the solar panels. Say the year if it's recent.", seconds: 3, icon: "checkmark.shield.fill"))
        }
        if f.contains(.gated) {
            list.append(ListingShot(title: "The neighborhood", how: "Film the gate opening as you drive in, then a quick shot of the clubhouse or park.", seconds: 3, icon: "lock.shield.fill"))
        }
        list.append(ListingShot(title: "Your close", how: "Back outside, face the camera and tell them how to reach you or what to comment.", seconds: 4, icon: "person.wave.2.fill"))
        return list
    }

    static func voiceover(for listing: Listing, agentName: String, keyword: String) -> String {
        let city = listing.city?.name ?? "Florida"
        let highlights = listing.features.prefix(3).map(\.phrase)
        let hook: String
        if listing.features.contains(.waterfront) || listing.features.contains(.gulfAccess) {
            hook = "Imagine coffee on the water every morning in \(city)."
        } else if listing.features.contains(.pool) {
            hook = "This \(city) home is made for pool days."
        } else {
            hook = "Wait until you see what \(listing.priceLabel) gets you in \(city)."
        }
        var lines = [hook, "Welcome to \(listing.address). \(listing.beds) bedrooms, \(listing.bathsLabel) baths\(listing.squareFeet.map { ", \($0.formatted()) square feet" } ?? "")."]
        if !highlights.isEmpty {
            lines.append("You get " + highlights.joined(separator: ", ") + ".")
        }
        lines.append("Comment \(keyword) and I'll send you the details and a private showing time. I'm \(agentName.split(separator: " ").first.map(String.init) ?? agentName).")
        return lines.joined(separator: " ")
    }
}

struct ShotListView: View {
    @Environment(CinemaStore.self) private var store
    let listing: Listing
    @State private var done: Set<String> = []

    private var shots: [ListingShot] { ShotListWriter.shots(for: listing) }
    private var keyword: String { listing.features.contains(.pool) ? "POOL" : (listing.features.contains(.waterfront) ? "WATER" : "TOUR") }
    private var script: String { ShotListWriter.voiceover(for: listing, agentName: store.profile.name, keyword: keyword) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Film it on your phone")
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("\(shots.count) shots, about \(shots.reduce(0) { $0 + $1.seconds }) seconds. Film them in order and send them to #Cinema to edit.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                ProgressView(value: Double(done.count), total: Double(max(shots.count, 1)))
                    .tint(Theme.red)

                ForEach(Array(shots.enumerated()), id: \.element.id) { index, shot in
                    Button {
                        if done.contains(shot.id) { done.remove(shot.id) } else { done.insert(shot.id) }
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(index + 1)")
                                .font(.cinema(14, weight: .heavy))
                                .foregroundStyle(done.contains(shot.id) ? .white : Theme.red)
                                .frame(width: 30, height: 30)
                                .background(done.contains(shot.id) ? Theme.success : Theme.redSoft, in: Circle())
                            VStack(alignment: .leading, spacing: 3) {
                                HStack {
                                    Label(shot.title, systemImage: shot.icon)
                                        .font(.cinema(15, weight: .semibold))
                                        .foregroundStyle(Theme.textPrimary)
                                    Spacer()
                                    Text("\(shot.seconds)s")
                                        .font(.cinema(12, weight: .semibold))
                                        .foregroundStyle(Theme.textTertiary)
                                }
                                Text(shot.how)
                                    .font(.cinema(13))
                                    .foregroundStyle(Theme.textSecondary)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                        .cardStyle()
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Label("Voiceover", systemImage: "waveform")
                        .font(.cinema(16, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(script)
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                    HStack(spacing: 10) {
                        Button {
                            UIPasteboard.general.string = script
                            store.showToast("Script copied")
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        ShareLink(item: shareText) {
                            Label("Send to shooter", systemImage: "paperplane.fill")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                }
                .cardStyle()

                Text("Tips: shoot vertical, turn on every light, open the blinds and move slowly. Comment keyword \(keyword) turns viewers into leads.")
                    .font(.cinema(11))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Shot list")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var shareText: String {
        var lines = ["Shot list for \(listing.address):", ""]
        for (index, shot) in shots.enumerated() {
            lines.append("\(index + 1). \(shot.title) (\(shot.seconds)s): \(shot.how)")
        }
        lines += ["", "Voiceover: \(script)"]
        return lines.joined(separator: "\n")
    }
}
