import AppKit
import Carbon
import SwiftUI

@MainActor
final class ClipBordAppController: ObservableObject {
    let store: ClipboardStore
    let hotKeySettings: HotKeySettings
    let themeSettings: ThemeSettings
    let overlayController: ClipboardOverlayPanelController

    private var hotKeyMonitor: GlobalHotKeyMonitor?

    init() {
        let store = ClipboardStore()
        let hotKeySettings = HotKeySettings()
        let themeSettings = ThemeSettings()
        let overlayController = ClipboardOverlayPanelController(
            store: store,
            hotKeySettings: hotKeySettings,
            themeSettings: themeSettings
        )

        self.store = store
        self.hotKeySettings = hotKeySettings
        self.themeSettings = themeSettings
        self.overlayController = overlayController

        overlayController.onShortcutChange = { [weak self] configuration in
            self?.updateHotKey(configuration)
        }

        registerHotKey(hotKeySettings.configuration)
    }

    func updateHotKey(_ configuration: HotKeyConfiguration) {
        guard configuration != hotKeySettings.configuration else {
            hotKeySettings.markRegistered()
            return
        }

        if registerHotKey(configuration) {
            hotKeySettings.update(configuration)
        } else {
            hotKeySettings.markFailed()
        }
    }

    func quit() {
        NSApplication.shared.terminate(nil)
    }

    @discardableResult
    private func registerHotKey(_ configuration: HotKeyConfiguration) -> Bool {
        let previousMonitor = hotKeyMonitor
        let monitor = GlobalHotKeyMonitor(configuration: configuration) { [weak overlayController] in
            overlayController?.toggle()
        }

        guard monitor.start() == noErr else {
            hotKeyMonitor = previousMonitor
            return false
        }

        hotKeyMonitor = monitor
        hotKeySettings.markRegistered()
        return true
    }
}
