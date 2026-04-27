import AppKit
import SwiftUI
import os

@MainActor
final class ClipboardOverlayPanelController {
    private let store: ClipboardStore
    private let hotKeySettings: HotKeySettings
    private let retentionSettings: RetentionSettings
    private let themeSettings: ThemeSettings
    private let updateChecker: GitHubUpdateChecker
    private let autoPasteService = AutoPasteService()
    private let logger = Logger(subsystem: "com.sittinonthanonklang.ClipBord", category: "OverlayPanel")
    private var panel: ClipboardOverlayPanel?
    private var previousApplication: NSRunningApplication?

    var onShortcutChange: ((HotKeyConfiguration) -> Void)?

    init(
        store: ClipboardStore,
        hotKeySettings: HotKeySettings,
        retentionSettings: RetentionSettings,
        themeSettings: ThemeSettings,
        updateChecker: GitHubUpdateChecker
    ) {
        self.store = store
        self.hotKeySettings = hotKeySettings
        self.retentionSettings = retentionSettings
        self.themeSettings = themeSettings
        self.updateChecker = updateChecker
    }

    func toggle() {
        if panel?.isVisible == true {
            hide()
        } else {
            show()
        }
    }

    func show() {
        previousApplication = NSWorkspace.shared.frontmostApplicationIfNotClipBord
        let panel = makePanelIfNeeded()
        position(panel)
        logger.debug("Showing clipboard overlay panel.")
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        panel.orderFrontRegardless()
    }

    func hide() {
        logger.debug("Hiding clipboard overlay panel.")
        panel?.orderOut(nil)
    }

    private func makePanelIfNeeded() -> ClipboardOverlayPanel {
        if let panel {
            return panel
        }

        let frame = NSRect(x: 0, y: 0, width: ClipboardPanelPresentation.overlay.panelWidth, height: ClipboardPanelPresentation.overlay.panelHeight)
        let panel = ClipboardOverlayPanel(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        panel.isFloatingPanel = true
        panel.level = .floating
        panel.hidesOnDeactivate = true
        panel.isReleasedWhenClosed = false
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.fullScreenAuxiliary, .transient, .moveToActiveSpace]

        let hostingController = NSHostingController(
            rootView: ClipboardPanelView(
                store: store,
                hotKeySettings: hotKeySettings,
                retentionSettings: retentionSettings,
                themeSettings: themeSettings,
                updateChecker: updateChecker,
                presentation: .overlay,
                onShortcutChange: { [weak self] configuration in
                    self?.onShortcutChange?(configuration)
                },
                onSelectItem: { [weak self] item in
                    self?.selectAndPaste(item)
                },
                onClose: { [weak self] in self?.hide() },
                onQuit: nil
            )
            .id(themeSettings.theme)
        )

        panel.contentViewController = hostingController
        panel.onEscape = { [weak self] in self?.hide() }

        self.panel = panel
        return panel
    }

    private func position(_ panel: NSPanel) {
        let size = NSSize(width: ClipboardPanelPresentation.overlay.panelWidth, height: ClipboardPanelPresentation.overlay.panelHeight)
        panel.setContentSize(size)

        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) }) ?? NSScreen.main
        let visibleFrame = screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero

        var x = mouseLocation.x + 14
        var y = mouseLocation.y - size.height - 14

        if x + size.width > visibleFrame.maxX - 10 {
            x = mouseLocation.x - size.width - 14
        }

        if y < visibleFrame.minY + 10 {
            y = mouseLocation.y + 14
        }

        x = min(max(x, visibleFrame.minX + 10), visibleFrame.maxX - size.width - 10)
        y = min(max(y, visibleFrame.minY + 10), visibleFrame.maxY - size.height - 10)
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    private func selectAndPaste(_ item: ClipboardItem) {
        guard autoPasteService.hasAccessibilityPermission else {
            autoPasteService.requestAccessibilityPermissionIfNeeded()
            store.setStatusMessage("Accessibility is still blocked. Relaunch ClipBord after allowing it.")
            return
        }

        guard store.restore(item) else {
            return
        }

        let application = previousApplication
        hide()
        autoPasteService.pasteIntoPreviouslyFocusedApp(application) { [weak self] in
            self?.store.setStatusMessage("Accessibility is still blocked. Relaunch ClipBord after allowing it.")
        }
        previousApplication = nil
    }
}

private final class ClipboardOverlayPanel: NSPanel {
    var onEscape: (() -> Void)?

    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        false
    }

    override func cancelOperation(_ sender: Any?) {
        onEscape?()
    }
}

private extension NSWorkspace {
    var frontmostApplicationIfNotClipBord: NSRunningApplication? {
        guard let application = frontmostApplication else {
            return nil
        }

        if application.bundleIdentifier == Bundle.main.bundleIdentifier {
            return nil
        }

        return application
    }
}
