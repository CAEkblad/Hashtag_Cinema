import SwiftUI
import UIKit

/// The poster artwork. Drawn at 360 points wide and rendered at 3x (1080 pixels).
struct PosterCanvas: View {
    let details: PosterDetails
    let photos: [UIImage]
    let style: PosterStyle
    let size: PosterSize
    /// From the agent's brand kit.
    var accent: Color = Theme.red
    var headshot: UIImage? = nil
    var logo: UIImage? = nil

    static let baseWidth: CGFloat = 360

    private var width: CGFloat { Self.baseWidth }
    private var height: CGFloat { Self.baseWidth * size.ratio }

    var body: some View {
        Group {
            switch style {
            case .classic: classic
            case .bold: bold
            case .luxury: luxury
            }
        }
        .frame(width: width, height: height)
        .clipped()
    }

    // MARK: Pieces

    @ViewBuilder
    private func photo(_ index: Int) -> some View {
        if index < photos.count {
            Image(uiImage: photos[index])
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                LinearGradient(colors: [Color(hex: 0xD9DDE3), Color(hex: 0xB9C0CA)], startPoint: .topLeading, endPoint: .bottomTrailing)
                Image(systemName: index == 0 ? "house.fill" : "photo")
                    .font(.system(size: index == 0 ? 54 : 22, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
    }

    private var addressText: String { details.address.isEmpty ? "123 Your Listing Street" : details.address }
    private var agentText: String { details.agentName.isEmpty ? "Your Name" : details.agentName }

    private var extraPhotos: [Int] { photos.count > 1 ? Array(1..<min(photos.count, 4)) : [] }

    private var openHouseLine: String? {
        details.kind == .openHouse ? details.openHouseLabel : nil
    }

    // MARK: Classic: photo on top, clean white panel below

    private var classic: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                photo(0)
                    .frame(width: width, height: height * (extraPhotos.isEmpty ? 0.62 : 0.5))
                    .clipped()
                Text(details.kind.title)
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .kerning(1.5)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(accent)
                    .padding(.top, 16)
            }
            if !extraPhotos.isEmpty {
                HStack(spacing: 3) {
                    ForEach(extraPhotos, id: \.self) { index in
                        photo(index)
                            .frame(width: (width - CGFloat(extraPhotos.count - 1) * 3) / CGFloat(extraPhotos.count), height: height * 0.14)
                            .clipped()
                    }
                }
                .padding(.top, 3)
            }
            VStack(alignment: .leading, spacing: 6) {
                if let price = details.priceLabel, details.kind != .underContract {
                    Text(price)
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundStyle(Theme.ink)
                }
                Text(addressText)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                if !details.cityLine.isEmpty {
                    Text(details.cityLine)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                }
                Text(details.specsLine)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(accent)
                if let openHouseLine {
                    Label(openHouseLine, systemImage: "calendar")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.ink)
                }
                Spacer(minLength: 0)
                agentStrip(dark: false)
            }
            .padding(18)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color.white)
        }
    }

    // MARK: Bold: full bleed photo with a big headline

    private var bold: some View {
        ZStack(alignment: .bottomLeading) {
            photo(0)
                .frame(width: width, height: height)
                .clipped()
            // Starts high enough that the headline always sits on shade,
            // even over a bright white house or sky.
            LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .black.opacity(0.2), location: 0.3), .init(color: .black.opacity(0.62), location: 0.55), .init(color: .black.opacity(0.9), location: 1)], startPoint: .top, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 8) {
                Rectangle()
                    .fill(accent)
                    .frame(width: 54, height: 6)
                Text(details.kind.title)
                    .font(.system(size: size == .square ? 38 : 46, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                    .shadow(color: .black.opacity(0.5), radius: 10, y: 2)
                Text(addressText)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .shadow(color: .black.opacity(0.4), radius: 4)
                HStack(spacing: 10) {
                    if let price = details.priceLabel, details.kind != .underContract {
                        Text(price)
                            .font(.system(size: 18, weight: .heavy, design: .rounded))
                    }
                    Text(details.specsLine)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(.white.opacity(0.92))
                if let openHouseLine {
                    Text(openHouseLine)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(accent, in: Capsule())
                }
                agentStrip(dark: true)
                    .padding(.top, 6)
            }
            .padding(20)
        }
    }

    // MARK: Luxury: black frame, serif type

    private var luxury: some View {
        ZStack {
            Color(hex: 0x0E0E10)
            VStack(spacing: 14) {
                Text(details.kind.title)
                    .font(.system(size: 15, weight: .medium, design: .serif))
                    .kerning(5)
                    .foregroundStyle(.white)
                    .padding(.top, 26)
                photo(0)
                    .frame(width: width - 48, height: height * (size == .story ? 0.6 : 0.48))
                    .clipped()
                    .overlay(Rectangle().stroke(.white.opacity(0.8), lineWidth: 1).padding(-6))
                VStack(spacing: 6) {
                    Text(addressText)
                        .font(.system(size: 19, weight: .regular, design: .serif))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    if !details.cityLine.isEmpty {
                        Text(details.cityLine.uppercased())
                            .font(.system(size: 11, weight: .medium, design: .serif))
                            .kerning(2)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    if let price = details.priceLabel, details.kind != .underContract {
                        Text(price)
                            .font(.system(size: 22, weight: .regular, design: .serif))
                            .foregroundStyle(Color(hex: 0xD8B26A))
                            .padding(.top, 2)
                    }
                    Text(details.specsLine.uppercased())
                        .font(.system(size: 11, weight: .medium, design: .serif))
                        .kerning(1.5)
                        .foregroundStyle(.white.opacity(0.8))
                    if let openHouseLine {
                        Text(openHouseLine)
                            .font(.system(size: 12, weight: .medium, design: .serif))
                            .foregroundStyle(.white)
                    }
                }
                .padding(.horizontal, 24)
                Spacer(minLength: 0)
                agentStrip(dark: true)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 22)
            }
        }
    }

    private func agentStrip(dark: Bool) -> some View {
        HStack(spacing: 10) {
            if let headshot {
                Image(uiImage: headshot)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 38, height: 38)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(accent, lineWidth: 2))
            } else {
                Text(initials)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(accent, in: Circle())
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(agentText)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                Text([details.agentPhone, details.brokerage].filter { !$0.isEmpty }.joined(separator: "  ·  "))
                    .font(.system(size: 11, design: .rounded))
                    .opacity(0.8)
                    .lineLimit(1)
            }
            .foregroundStyle(dark ? Color.white : Theme.ink)
            Spacer(minLength: 0)
            if let logo {
                Image(uiImage: logo)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 70, maxHeight: 30)
            }
        }
    }

    private var initials: String {
        let letters = agentText.split(separator: " ").prefix(2).compactMap { $0.first }
        return String(letters).uppercased()
    }
}
