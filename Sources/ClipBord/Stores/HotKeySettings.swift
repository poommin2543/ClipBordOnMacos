import Foundation

@MainActor
final class HotKeySettings: ObservableObject {
    @Published private(set) var configuration: HotKeyConfiguration
    @Published private(set) var message: String?

    private let defaultsKey = "ClipBord.hotKeyConfiguration"

    init() {
        if
            let data = UserDefaults.standard.data(forKey: defaultsKey),
            let decodedConfiguration = try? JSONDecoder().decode(HotKeyConfiguration.self, from: data)
        {
            configuration = decodedConfiguration
        } else {
            configuration = .defaultShortcut
        }
    }

    func markRegistered() {
        message = nil
    }

    func markFailed() {
        message = "Shortcut is already used"
    }

    func update(_ configuration: HotKeyConfiguration) {
        self.configuration = configuration
        message = nil

        guard let data = try? JSONEncoder().encode(configuration) else {
            return
        }

        UserDefaults.standard.set(data, forKey: defaultsKey)
    }
}
