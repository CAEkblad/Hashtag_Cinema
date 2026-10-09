import SwiftUI
import PhotosUI
import UIKit

/// Headshot, logo, color and contact line, used on every poster and graphic.
struct BrandKitView: View {
    @Environment(CinemaStore.self) private var store
    @State private var kit = BrandKit()
    @State private var loaded = false
    @State private var headshotItem: PhotosPickerItem?
    @State private var logoItem: PhotosPickerItem?

    private var sample: PosterDetails {
        var details = PosterDetails()
        details.kind = .justListed
        details.address = "123 Bayshore Blvd"
        details.cityLine = store.homeCity.displayName
        details.price = "649000"
        details.beds = 3
        details.baths = 2
        details.agentName = store.profile.name
        details.agentPhone = kit.phone
        details.brokerage = store.myMarketCenter?.name ?? store.profile.brokerage
        return details
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your brand kit")
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Set it once. Every poster, market graphic and testimonial card uses it.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                HStack {
                    Spacer()
                    PosterCanvas(details: sample, photos: [], style: .classic, size: .square, accent: kit.accent, headshot: kit.headshotImage, logo: kit.logoImage)
                        .scaleEffect(240 / PosterCanvas.baseWidth, anchor: .topLeading)
                        .frame(width: 240, height: 240, alignment: .topLeading)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .shadow(color: .black.opacity(0.12), radius: 12, y: 5)
                    Spacer()
                }

                HStack(spacing: 12) {
                    PhotosPicker(selection: $headshotItem, matching: .images) {
                        imageTile(title: "Headshot", image: kit.headshotImage, icon: "person.crop.circle.fill", round: true)
                    }
                    .buttonStyle(.plain)
                    PhotosPicker(selection: $logoItem, matching: .images) {
                        imageTile(title: "Logo", image: kit.logoImage, icon: "seal.fill", round: false)
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Accent color")
                        .font(.cinema(15, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                        ForEach(BrandKit.swatches, id: \.hex) { swatch in
                            Button {
                                kit.accentHex = swatch.hex
                            } label: {
                                VStack(spacing: 6) {
                                    Circle()
                                        .fill(Color(hex: swatch.hex))
                                        .frame(width: 40, height: 40)
                                        .overlay(Circle().stroke(Color.white, lineWidth: 3).padding(2).opacity(kit.accentHex == swatch.hex ? 1 : 0))
                                        .overlay(Circle().stroke(Theme.ink.opacity(kit.accentHex == swatch.hex ? 0.6 : 0.08), lineWidth: 1.5))
                                    Text(swatch.name)
                                        .font(.cinema(10, weight: .semibold))
                                        .foregroundStyle(Theme.textSecondary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 10) {
                    Text("Contact line")
                        .font(.cinema(15, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    TextField("Phone", text: $kit.phone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                        .inputStyle()
                    TextField("Website or booking link", text: $kit.website)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .inputStyle()
                    TextField("Tagline, like \"Your Tampa waterfront expert\"", text: $kit.tagline)
                        .inputStyle()
                }

                Text("Using your brokerage's logo? Check your brokerage's brand rules first.")
                    .font(.cinema(12))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Brand kit")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            guard !loaded else { return }
            kit = store.brandKit
            loaded = true
        }
        .onChange(of: kit) { _, newValue in
            if loaded { store.saveBrandKit(newValue) }
        }
        .onChange(of: headshotItem) { _, item in
            Task { kit.headshotData = await load(item, maxSide: 600) }
        }
        .onChange(of: logoItem) { _, item in
            Task { kit.logoData = await load(item, maxSide: 500, png: true) }
        }
    }

    private func imageTile(title: String, image: UIImage?, icon: String, round: Bool) -> some View {
        VStack(spacing: 8) {
            Group {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 30))
                        .foregroundStyle(Theme.textTertiary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Theme.surfaceRaised)
                }
            }
            .frame(width: 72, height: 72)
            .clipShape(RoundedRectangle(cornerRadius: round ? 36 : 14, style: .continuous))
            Text(image == nil ? "Add \(title.lowercased())" : "Change \(title.lowercased())")
                .font(.cinema(13, weight: .semibold))
                .foregroundStyle(Theme.red)
        }
        .frame(maxWidth: .infinity)
        .cardStyle(padding: 14)
    }

    private func load(_ item: PhotosPickerItem?, maxSide: CGFloat, png: Bool = false) async -> Data? {
        guard let item, let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) else { return nil }
        let small = image.downscaled(maxSide: maxSide)
        return png ? small.pngData() : small.jpegData(compressionQuality: 0.85)
    }
}
