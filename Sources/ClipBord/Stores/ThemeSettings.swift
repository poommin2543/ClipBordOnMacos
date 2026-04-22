import AppKit
import Foundation

@MainActor
final class ThemeSettings: ObservableObject {
    @Published var theme: AppearanceTheme {
        didSet {
            UserDefaults.standard.set(theme.rawValue, forKey: defaultsKey)
            applyAppearance()
        }
    }

    private let defaultsKey = "ClipBord.appearanceTheme"

    init() {
        if
            let rawValue = UserDefaults.standard.string(forKey: defaultsKey),
            let savedTheme = AppearanceTheme(rawValue: rawValue)
        {
            theme = savedTheme
        } else {
            theme = .system
        }

        applyAppearance()
    }

    private func applyAppearance() {
        switch theme {
        case .system:
            NSApplication.shared.appearance = nil
        case .light:
            NSApplication.shared.appearance = NSAppearance(named: .aqua)
        case .dark:
            NSApplication.shared.appearance = NSAppearance(named: .darkAqua)
        }
    }
}
