import AppKit
import Carbon
import CoreGraphics
import Foundation
import os

@MainActor
final class AutoPasteService {
    private let logger = Logger(subsystem: "com.sittinonthanonklang.ClipBord", category: "AutoPaste")
    private var hasPromptedForAccessibility = false

    var hasAccessibilityPermission: Bool {
        AXIsProcessTrusted()
    }

    func requestAccessibilityPermissionIfNeeded() {
        guard !hasAccessibilityPermission else {
            return
        }

        guard !hasPromptedForAccessibility else {
            return
        }

        hasPromptedForAccessibility = true
        AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
        logger.warning("Accessibility permission is required for automatic paste.")
    }

    func pasteIntoPreviouslyFocusedApp(
        _ application: NSRunningApplication?,
        onPermissionMissing: @escaping () -> Void
    ) {
        guard let application else {
            logger.warning("No previous foreground application to paste into.")
            return
        }

        guard hasAccessibilityPermission else {
            requestAccessibilityPermissionIfNeeded()
            onPermissionMissing()
            return
        }

        application.activate(options: [])

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            guard self.hasAccessibilityPermission else {
                self.requestAccessibilityPermissionIfNeeded()
                onPermissionMissing()
                return
            }

            self.postCommandV()
        }
    }

    private func postCommandV() {
        guard
            let source = CGEventSource(stateID: .combinedSessionState),
            let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true),
            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false)
        else {
            logger.error("Could not create paste keyboard events.")
            return
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        keyDown.post(tap: .cgSessionEventTap)
        keyUp.post(tap: .cgSessionEventTap)
    }
}
