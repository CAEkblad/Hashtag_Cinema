import SwiftUI

/// #Cinema brand: black background, white type, red camera mark.
enum Theme {
    static let red = Color(hex: 0xE11D2E)
    static let redDeep = Color(hex: 0x9E1220)
    static let background = Color(hex: 0x0B0B0C)
    static let surface = Color(hex: 0x17171A)
    static let surfaceRaised = Color(hex: 0x222227)
    static let stroke = Color.white.opacity(0.08)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.62)
    static let textTertiary = Color.white.opacity(0.4)
    static let success = Color(hex: 0x2ECC71)
    static let warning = Color(hex: 0xF5A623)

    static let corner: CGFloat = 16
    static let gutter: CGFloat = 16

    /// Placeholder thumbnail gradients until real video thumbnails load.
    static let palettes: [[Color]] = [
        [Color(hex: 0xE11D2E), Color(hex: 0x3B0A10)],
        [Color(hex: 0x2B5876), Color(hex: 0x0F1C2E)],
        [Color(hex: 0x8E6E53), Color(hex: 0x2A1F17)],
        [Color(hex: 0x4E4376), Color(hex: 0x1B1730)],
        [Color(hex: 0x1D976C), Color(hex: 0x0B2A20)],
        [Color(hex: 0xC9A227), Color(hex: 0x2E2508)]
    ]

    static func gradient(_ index: Int) -> LinearGradient {
        let colors = palettes[abs(index) % palettes.count]
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}

extension Font {
    static func cinema(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
}

extension Date {
    var shortDay: String {
        formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }

    var timeOnly: String {
        formatted(date: .omitted, time: .shortened)
    }

    var relative: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

extension Int {
    var compact: String {
        if self >= 1_000_000 { return String(format: "%.1fM", Double(self) / 1_000_000) }
        if self >= 1_000 { return String(format: "%.1fk", Double(self) / 1_000) }
        return "\(self)"
    }
}
