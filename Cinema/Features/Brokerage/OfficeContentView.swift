import SwiftUI
import UIKit

/// Every listing video, photo set and poster agents shared with the office.
/// Leaders feature them as office content or turn them into posters.
struct OfficeContentView: View {
    @Environment(CinemaStore.self) private var store
    @State private var kind: OfficeAssetKind?
    @State private var posterFrom: OfficeAsset?

    private var assets: [OfficeAsset] {
        guard let kind else { return store.officeAssets }
        return store.officeAssets.filter { $0.kind == kind }
    }

    private var agentsSharing: Int { Set(store.officeAssets.map(\.agentName)).count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    StatTile(value: "\(store.officeAssets.count)", label: "Pieces shared", icon: "square.stack.3d.up.fill")
                    StatTile(value: "\(agentsSharing)", label: "Agents sharing", icon: "person.2.fill")
                    StatTile(value: "\(store.officeAssets.reduce(0) { $0 + $1.remixCount })", label: "Remixed", icon: "arrow.triangle.2.circlepath")
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        filterChip("All", icon: "square.grid.2x2.fill", isOn: kind == nil) { kind = nil }
                        ForEach(OfficeAssetKind.allCases) { option in
                            filterChip(option.title, icon: option.icon, isOn: kind == option) { kind = option }
                        }
                    }
                }

                if assets.isEmpty {
                    EmptyStateView(title: "Nothing shared yet", message: "When agents approve listing videos or share posters, they show up here.", icon: "tray")
                }

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(assets) { asset in
                        assetCard(asset)
                    }
                }
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Office content")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $posterFrom) { asset in
            PosterMakerView(prefill: asset)
        }
    }

    private func assetCard(_ asset: OfficeAsset) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                if let data = asset.imageData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Theme.gradient(asset.paletteIndex)
                    Image(systemName: asset.symbol)
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            .frame(height: 150)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(alignment: .topLeading) {
                if let status = asset.status {
                    Pill(text: status, color: Theme.red, textColor: .white)
                        .padding(8)
                }
            }

            Text(asset.title)
                .font(.cinema(14, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(2)
            Text("By \(asset.agentName) · \(asset.createdAt.relative)")
                .font(.cinema(11))
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(1)

            Menu {
                Button {
                    store.remixForOffice(asset)
                } label: {
                    Label("Feature for the office", systemImage: "megaphone.fill")
                }
                Button {
                    posterFrom = asset
                } label: {
                    Label("Make a poster", systemImage: "rectangle.portrait.on.rectangle.portrait.fill")
                }
            } label: {
                Label(asset.remixCount > 0 ? "Remixed \(asset.remixCount)x" : "Remix", systemImage: "arrow.triangle.2.circlepath")
                    .font(.cinema(13, weight: .semibold))
                    .foregroundStyle(Theme.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Theme.redSoft, in: Capsule())
            }
        }
        .cardStyle(padding: 10)
    }

    private func filterChip(_ title: String, icon: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.cinema(13, weight: .semibold))
                .foregroundStyle(isOn ? Color.white : Theme.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isOn ? Theme.red : Theme.surface, in: Capsule())
                .overlay(Capsule().stroke(Theme.stroke, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
