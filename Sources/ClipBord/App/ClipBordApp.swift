import SwiftUI

@main
struct ClipBordApp: App {
    @StateObject private var appController: ClipBordAppController

    init() {
        _appController = StateObject(wrappedValue: ClipBordAppController())
    }

    var body: some Scene {
        MenuBarExtra("ClipBord", systemImage: "square.on.square") {
            ClipboardPanelView(
                store: appController.store,
                hotKeySettings: appController.hotKeySettings,
                themeSettings: appController.themeSettings,
                presentation: .menuBar,
                onShortcutChange: { appController.updateHotKey($0) },
                onSelectItem: { appController.store.restore($0) },
                onClose: nil,
                onQuit: { appController.quit() }
            )
            .id(appController.themeSettings.theme)
        }
        .menuBarExtraStyle(.window)
    }
}
