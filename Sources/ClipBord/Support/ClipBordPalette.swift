import SwiftUI

struct ClipBordPalette {
    let scheme: ColorScheme

    var windowBackground: Color {
        scheme == .dark
            ? Color(red: 0.118, green: 0.118, blue: 0.128)
            : Color(red: 0.965, green: 0.965, blue: 0.975)
    }

    var elevatedBackground: Color {
        scheme == .dark
            ? Color(red: 0.155, green: 0.155, blue: 0.168)
            : Color(red: 1.000, green: 1.000, blue: 1.000)
    }

    var cardBackground: Color {
        scheme == .dark
            ? Color(red: 0.140, green: 0.145, blue: 0.155)
            : Color(red: 1.000, green: 1.000, blue: 1.000)
    }

    var hoverBackground: Color {
        Color.accentColor.opacity(scheme == .dark ? 0.18 : 0.10)
    }

    var primaryText: Color {
        Color.primary
    }

    var secondaryText: Color {
        Color.secondary
    }

    var tertiaryText: Color {
        Color.secondary.opacity(0.72)
    }

    var separator: Color {
        scheme == .dark
            ? Color.white.opacity(0.14)
            : Color.black.opacity(0.12)
    }

    var subtleFill: Color {
        Color.primary.opacity(scheme == .dark ? 0.10 : 0.055)
    }

    var accentFill: Color {
        Color.accentColor.opacity(scheme == .dark ? 0.24 : 0.14)
    }

    var accentStroke: Color {
        Color.accentColor.opacity(scheme == .dark ? 0.72 : 0.50)
    }

    var warning: Color {
        Color(nsColor: .systemRed)
    }
}
