import SwiftUI
import PhotosUI
import UIKit

/// Printable letter size property flyer (PDF) with photos, details, QR code and your brand.
struct FlyerView: View {
    @Environment(CinemaStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let listing: Listing

    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var photos: [UIImage] = []
    @State private var shareURL: URL?
    @State private var showShare = false

    private var canvas: FlyerCanvas {
        FlyerCanvas(
            listing: listing,
            photos: photos,
            agentName: store.profile.name,
            brokerage: store.myMarketCenter?.name ?? store.profile.brokerage,
            kit: store.brandKit,
            qrText: listing.nextOpenHouse.map { "https://hashtagcinema.com/oh/\($0.id.uuidString.prefix(8).lowercased())" } ?? "https://hashtagcinema.com/l/\(listing.id.uuidString.prefix(8).lowercased())"
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    canvas
                        .scaleEffect(300 / FlyerCanvas.size.width, anchor: .topLeading)
                        .frame(width: 300, height: 300 * FlyerCanvas.size.height / FlyerCanvas.size.width, alignment: .topLeading)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .shadow(color: .black.opacity(0.15), radius: 12, y: 5)

                    PhotosPicker(selection: $pickerItems, maxSelectionCount: 3, matching: .images) {
                        Label(photos.isEmpty ? "Add up to 3 listing photos" : "Change photos", systemImage: "photo.on.rectangle.angled")
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    Button {
                        makePDF()
                    } label: {
                        Label("Print or share PDF", systemImage: "printer.fill")
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Text(listing.nextOpenHouse == nil ? "The QR code links to the listing page once the backend is live." : "The QR code opens the open house sign in, so visitors land in your Leads.")
                        .font(.cinema(12))
                        .foregroundStyle(Theme.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(Theme.gutter)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Property flyer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onChange(of: pickerItems) { _, items in
                Task {
                    var loaded: [UIImage] = []
                    for item in items {
                        if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                            loaded.append(image.downscaled(maxSide: 1600))
                        }
                    }
                    photos = loaded
                }
            }
            .sheet(isPresented: $showShare) {
                if let shareURL {
                    ActivityView(items: [shareURL])
                        .presentationDetents([.medium, .large])
                }
            }
        }
    }

    @MainActor
    private func makePDF() {
        let renderer = ImageRenderer(content: canvas)
        let safeName = listing.address.filter { $0.isLetter || $0.isNumber || $0 == " " }.replacingOccurrences(of: " ", with: "-")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Flyer-\(safeName.isEmpty ? "listing" : safeName).pdf")
        renderer.render { size, draw in
            var box = CGRect(origin: .zero, size: size)
            guard let context = CGContext(url as CFURL, mediaBox: &box, nil) else { return }
            context.beginPDFPage(nil)
            draw(context)
            context.endPDFPage()
            context.closePDF()
        }
        shareURL = url
        showShare = true
    }
}

/// US Letter page at 72 points per inch.
struct FlyerCanvas: View {
    static let size = CGSize(width: 612, height: 792)

    let listing: Listing
    let photos: [UIImage]
    let agentName: String
    let brokerage: String
    let kit: BrandKit
    let qrText: String

    private var headline: String {
        if listing.nextOpenHouse != nil && listing.status == .active { return "OPEN HOUSE" }
        return listing.status.posterKind.title
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(headline)
                .font(.system(size: 30, weight: .black, design: .rounded))
                .kerning(3)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(kit.accent)

            photo(0)
                .frame(width: Self.size.width, height: 300)
                .clipped()

            if photos.count > 1 {
                HStack(spacing: 4) {
                    photo(1).frame(height: 120).frame(maxWidth: .infinity).clipped()
                    photo(2).frame(height: 120).frame(maxWidth: .infinity).clipped()
                }
                .padding(.top, 4)
            }

            HStack(alignment: .top, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    if listing.status != .underContract {
                        Text(listing.priceLabel)
                            .font(.system(size: 30, weight: .heavy, design: .rounded))
                            .foregroundStyle(Theme.ink)
                    }
                    Text(listing.address)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.ink)
                    Text(listing.cityLine)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                    Text(listing.specsLine)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(kit.accent)
                    if let open = listing.nextOpenHouse {
                        Label(open.label, systemImage: "calendar")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(Theme.ink)
                    }
                    if !listing.features.isEmpty {
                        Text(listing.features.prefix(6).map(\.title).joined(separator: "  ·  "))
                            .font(.system(size: 12, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if !listing.description.isEmpty {
                        Text(String(listing.description.prefix(360)))
                            .font(.system(size: 11, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                            .lineLimit(6)
                            .padding(.top, 2)
                    }
                }
                Spacer(minLength: 0)
                VStack(spacing: 6) {
                    QRCodeView(text: qrText)
                        .frame(width: 104, height: 104)
                    Text(listing.nextOpenHouse == nil ? "Scan for details" : "Scan to sign in")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 18)

            Spacer(minLength: 0)

            HStack(spacing: 12) {
                if let headshot = kit.headshotImage {
                    Image(uiImage: headshot)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 54, height: 54)
                        .clipShape(Circle())
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(agentName)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    Text([kit.phone, kit.website].filter { !$0.isEmpty }.joined(separator: "  ·  "))
                        .font(.system(size: 12, design: .rounded))
                    Text(brokerage)
                        .font(.system(size: 11, design: .rounded))
                        .opacity(0.75)
                }
                .foregroundStyle(.white)
                Spacer()
                if let logo = kit.logoImage {
                    Image(uiImage: logo)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 110, maxHeight: 44)
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 18)
            .background(Theme.ink)
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .background(Color.white)
    }

    @ViewBuilder
    private func photo(_ index: Int) -> some View {
        if index < photos.count {
            Image(uiImage: photos[index])
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                Theme.gradient(listing.paletteIndex + index)
                Image(systemName: index == 0 ? listing.symbol : "photo")
                    .font(.system(size: index == 0 ? 60 : 28, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
    }
}
