import SwiftUI

/// #Cinema brand, light edition: bright white surfaces, near-black type,
/// and #Cinema red as the one accent.
enum Theme {
    static let red = Color(hex: 0xE11D2E)
    static let redDeep = Color(hex: 0xB3121F)
    /// Soft red wash for highlighted cards and selected states.
    static let redSoft = Color(hex: 0xE11D2E, opacity: 0.08)

    static let background = Color(hex: 0xF6F6F8)
    static let surface = Color.white
    static let surfaceRaised = Color(hex: 0xEFEFF3)
    static let stroke = Color.black.opacity(0.06)

    static let ink = Color(hex: 0x141416)
    static let textPrimary = Color(hex: 0x141416)
    static let textSecondary = Color(hex: 0x5C5C66)
    static let textTertiary = Color(hex: 0x9A9AA3)

    static let success = Color(hex: 0x1FA463)
    static let warning = Color(hex: 0xE08A00)

    static let corner: CGFloat = 18
    static let gutter: CGFloat = 16

    /// Placeholder thumbnail gradients until real video thumbnails load.
    static let palettes: [[Color]] = [
        [Color(hex: 0xFF4D5E), Color(hex: 0xC4101F)],
        [Color(hex: 0x5B8DEF), Color(hex: 0x2D5BBF)],
        [Color(hex: 0xD9A27A), Color(hex: 0x9C6B48)],
        [Color(hex: 0x9B8AE6), Color(hex: 0x5E4DB2)],
        [Color(hex: 0x4CC9A0), Color(hex: 0x1E8A68)],
        [Color(hex: 0xF5C04A), Color(hex: 0xC48A12)]
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
        .system(size: size, weight: weight, design: .rounded)
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
