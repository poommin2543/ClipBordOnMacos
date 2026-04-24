import AppKit
import Carbon
import Combine
import SwiftUI

@MainActor
final class ClipBordAppController: ObservableObject {
    let store: ClipboardStore
    let hotKeySettings: HotKeySettings
    let themeSettings: ThemeSettings
    let updateChecker: GitHubUpdateChecker
    let overlayController: ClipboardOverlayPanelController

    private var hotKeyMonitor: GlobalHotKeyMonitor?
    private var updatePhaseCancellable: AnyCancellable?
    private var updateAlertVersionsOfferedThisSession = Set<String>()

    init() {
        let store = ClipboardStore()
        let hotKeySettings = HotKeySettings()
        let themeSettings = ThemeSettings()
        let updateChecker = GitHubUpdateChecker()
        let overlayController = ClipboardOverlayPanelController(
            store: store,
            hotKeySettings: hotKeySettings,
            themeSettings: themeSettings,
            updateChecker: updateChecker
        )

        self.store = store
        self.hotKeySettings = hotKeySettings
        self.themeSettings = themeSettings
        self.updateChecker = updateChecker
        self.overlayController = overlayController

        overlayController.onShortcutChange = { [weak self] configuration in
            self?.updateHotKey(configuration)
        }

        updatePhaseCancellable = updateChecker.$phase
            .receive(on: RunLoop.main)
            .sink { [weak self] phase in
                self?.considerPresentingLaunchUpdateAlert(for: phase)
            }

        registerHotKey(hotKeySettings.configuration)
        updateChecker.checkOnColdLaunch()
    }

    private func considerPresentingLaunchUpdateAlert(for phase: GitHubUpdateChecker.Phase) {
        guard case let .updateAvailable(versionLabel, _) = phase else {
            return
        }

        guard !updateAlertVersionsOfferedThisSession.contains(versionLabel) else {
            return
        }

        updateAlertVersionsOfferedThisSession.insert(versionLabel)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) { [weak self] in
            guard let self else {
                return
            }

            guard case let .updateAvailable(stillLabel, _) = self.updateChecker.phase, stillLabel == versionLabel else {
                return
            }

            NSApp.activate(ignoringOtherApps: true)

            let alert = NSAlert()
            alert.messageText = "Update available"
            alert.informativeText =
                "ClipBord \(versionLabel) is ready. Download & install replaces this app in place and relaunches it. If you use a Developer ID–signed build at the same path, macOS usually keeps Accessibility; ad‑hoc signed builds may need to be allowed again."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Download & install")
            alert.addButton(withTitle: "Not now")

            if alert.runModal() == .alertFirstButtonReturn {
                self.updateChecker.beginInstallUpdate()
            }
        }
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
