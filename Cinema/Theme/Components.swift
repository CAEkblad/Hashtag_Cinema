import SwiftUI

// MARK: - Brand

struct CinemaLogo: View {
    var size: CGFloat = 28

    var body: some View {
        HStack(spacing: size * 0.25) {
            Image(systemName: "video.fill")
                .font(.system(size: size * 0.8, weight: .bold))
                .foregroundStyle(Theme.red)
            Text("#Cinema")
                .font(.system(size: size, weight: .heavy))
                .foregroundStyle(Theme.textPrimary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("#Cinema")
    }
}

// MARK: - Cards and sections

struct CardModifier: ViewModifier {
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                    .stroke(Theme.stroke, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

extension View {
    func cardStyle(padding: CGFloat = 16) -> some View {
        modifier(CardModifier(padding: padding))
    }

    /// Standard dark screen background used across the app.
    func cinemaScreen() -> some View {
        self
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
    }
}

struct SectionHeader: View {
    let title: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.cinema(20, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.cinema(14, weight: .semibold))
                    .foregroundStyle(Theme.red)
            }
        }
    }
}

// MARK: - Buttons

struct PrimaryButtonStyle: ButtonStyle {
    var fullWidth = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.cinema(16, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(Theme.red.opacity(configuration.isPressed ? 0.75 : 1), in: Capsule())
            .shadow(color: Theme.red.opacity(0.25), radius: 10, x: 0, y: 5)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    var fullWidth = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.cinema(16, weight: .semibold))
            .foregroundStyle(Theme.textPrimary)
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(Theme.surface.opacity(configuration.isPressed ? 0.7 : 1), in: Capsule())
            .overlay(Capsule().stroke(Theme.red.opacity(0.35), lineWidth: 1.25))
    }
}

// MARK: - Small pieces

struct Pill: View {
    let text: String
    var icon: String? = nil
    var color: Color = Theme.surfaceRaised
    var textColor: Color = Theme.textPrimary

    var body: some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
            }
            Text(text)
                .font(.cinema(12, weight: .semibold))
        }
        .foregroundStyle(textColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color, in: Capsule())
    }
}

struct StatusBadge: View {
    let status: EditStatus

    var body: some View {
        Pill(text: status.title, icon: status.icon, color: color, textColor: .white)
    }

    private var color: Color {
        switch status {
        case .readyForReview: return Theme.red
        case .approved: return Theme.success.opacity(0.85)
        case .revisions: return Theme.warning.opacity(0.85)
        default: return Color.black.opacity(0.55)
        }
    }
}

struct Avatar: View {
    let initials: String
    var size: CGFloat = 40
    var paletteIndex: Int = 0

    var body: some View {
        Text(initials)
            .font(.system(size: size * 0.38, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(Theme.gradient(paletteIndex), in: Circle())
    }
}

struct StatTile: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.red)
                .frame(width: 30, height: 30)
                .background(Theme.redSoft, in: Circle())
            Text(value)
                .font(.cinema(22, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text(label)
                .font(.cinema(12))
                .foregroundStyle(Theme.textSecondary)
        }
        .cardStyle(padding: 14)
    }
}

struct ProgressRing: View {
    let progress: Double
    var lineWidth: CGFloat = 6
    var size: CGFloat = 56

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.surfaceRaised, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(progress, 1)))
                .stroke(Theme.red, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(progress * 100))%")
                .font(.cinema(size * 0.24, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
        }
        .frame(width: size, height: size)
    }
}

struct ClipThumbnail: View {
    let clip: Clip
    var height: CGFloat = 200

    var body: some View {
        ZStack {
            Theme.gradient(clip.paletteIndex)
            Image(systemName: clip.symbol)
                .font(.system(size: height * 0.2, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .overlay(alignment: .topLeading) {
            StatusBadge(status: clip.status)
                .padding(8)
        }
        .overlay(alignment: .bottomTrailing) {
            Text(clip.durationLabel)
                .font(.cinema(11, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(.black.opacity(0.6), in: Capsule())
                .padding(8)
        }
        .overlay(alignment: .topTrailing) {
            if clip.isFavorite {
                Image(systemName: "star.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.warning)
                    .padding(10)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct EmptyStateView: View {
    let title: String
    let message: String
    let icon: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 34))
                .foregroundStyle(Theme.textTertiary)
            Text(title)
                .font(.cinema(17, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            Text(message)
                .font(.cinema(14))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

struct IconRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    var badge: String? = nil

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.red)
                .frame(width: 34, height: 34)
                .background(Theme.redSoft, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.cinema(16, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(.cinema(13))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            Spacer()
            if let badge {
                Pill(text: badge, color: Theme.red, textColor: .white)
            }
        }
        .contentShape(Rectangle())
    }
}

/// Wraps a set of chips onto as many lines as needed.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var widest: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            widest = max(widest, x - spacing)
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: widest, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
