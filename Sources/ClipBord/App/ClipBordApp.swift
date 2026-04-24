import AppKit
import SwiftUI

/// `MenuBarExtra` บน macOS มักไม่นำ `.font` / `.symbolRenderingMode` ของ SwiftUI ไปใช้กับไอคอนแถบเมนู
/// จึงสร้างสัญลักษณ์ผ่าน `NSImage.SymbolConfiguration` ให้ได้น้ำหนักเส้นที่ตั้งใจ
@MainActor
private enum MenuBarExtraIcon {
    static let image: NSImage = {
        let base = NSImage(
            systemSymbolName: "square.on.square",
            accessibilityDescription: "ClipBord"
        )!
        let config = NSImage.SymbolConfiguration(pointSize: 15, weight: .ultraLight)
        let resolved = base.withSymbolConfiguration(config) ?? base
        resolved.isTemplate = true
        return resolved
    }()
}

@main
struct ClipBordApp: App {
    @StateObject private var appController: ClipBordAppController

    init() {
        _appController = StateObject(wrappedValue: ClipBordAppController())
    }

    var body: some Scene {
        MenuBarExtra {
            ClipboardPanelView(
                store: appController.store,
                hotKeySettings: appController.hotKeySettings,
                themeSettings: appController.themeSettings,
                updateChecker: appController.updateChecker,
                presentation: .menuBar,
                onShortcutChange: { appController.updateHotKey($0) },
                onSelectItem: { appController.store.restore($0) },
                onClose: nil,
                onQuit: { appController.quit() }
            )
            .id(appController.themeSettings.theme)
        } label: {
            Image(nsImage: MenuBarExtraIcon.image)
                .accessibilityLabel("ClipBord")
        }
        .menuBarExtraStyle(.window)
    }
}
