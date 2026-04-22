import SwiftUI

enum ClipboardPanelPresentation {
    case menuBar
    case overlay

    var panelWidth: CGFloat {
        switch self {
        case .menuBar:
            360
        case .overlay:
            380
        }
    }

    var panelHeight: CGFloat {
        switch self {
        case .menuBar:
            470
        case .overlay:
            500
        }
    }

    var showsQuitButton: Bool {
        self == .menuBar
    }

    var showsCloseButton: Bool {
        self == .overlay
    }
}

struct ClipboardPanelView: View {
    @ObservedObject var store: ClipboardStore
    @ObservedObject var hotKeySettings: HotKeySettings
    @ObservedObject var themeSettings: ThemeSettings
    let presentation: ClipboardPanelPresentation
    let onShortcutChange: (HotKeyConfiguration) -> Void
    let onSelectItem: (ClipboardItem) -> Void
    let onClose: (() -> Void)?
    let onQuit: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    private var effectiveColorScheme: ColorScheme {
        themeSettings.theme.resolvedColorScheme(systemScheme: colorScheme)
    }

    private var palette: ClipBordPalette {
        ClipBordPalette(scheme: effectiveColorScheme)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(palette.windowBackground)
                .overlay(
                    Rectangle()
                        .stroke(palette.separator, lineWidth: 1)
                )

            VStack(spacing: 12) {
                header

                if store.items.isEmpty {
                    EmptyStateView()
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(store.items) { item in
                                ClipboardCardView(
                                    item: item,
                                    imageURL: store.imageURL(for: item),
                                    onRestore: {
                                        onSelectItem(item)
                                    },
                                    onTogglePin: { store.togglePin(item) },
                                    onDelete: { store.delete(item) }
                                )
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .scrollIndicators(.never)
                }
            }
            .padding(14)
        }
        .frame(width: presentation.panelWidth, height: presentation.panelHeight)
        .environment(\.colorScheme, effectiveColorScheme)
        .preferredColorScheme(themeSettings.theme.colorScheme)
        .id(themeSettings.theme)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text("Clipboard")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(palette.primaryText)

                Spacer(minLength: 0)

                themeMenu

                Button("Clear all") {
                    store.clearAllVisibleItems()
                }
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(store.hasItemsToClear ? palette.primaryText : palette.secondaryText.opacity(0.55))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(
                    Rectangle()
                        .fill(palette.subtleFill)
                )
                .overlay(
                    Rectangle()
                        .stroke(palette.separator, lineWidth: 1)
                )
                .disabled(!store.hasItemsToClear)

                if presentation.showsCloseButton {
                    iconButton(systemImage: "xmark", action: { onClose?() })
                }

                if presentation.showsQuitButton {
                    iconButton(systemImage: "power", action: { onQuit?() })
                }
            }

            HStack(spacing: 8) {
                Text("Open popup")
                    .font(.caption)
                    .foregroundStyle(palette.secondaryText)

                ShortcutRecorderButton(
                    settings: hotKeySettings,
                    palette: palette,
                    onShortcutChange: onShortcutChange
                )

                Spacer(minLength: 0)
            }
            .padding(.bottom, 2)
        }
        .padding(.bottom, 2)
    }

    private var themeMenu: some View {
        Menu {
            Picker("Theme", selection: $themeSettings.theme) {
                ForEach(AppearanceTheme.allCases) { theme in
                    Text(theme.title).tag(theme)
                }
            }
        } label: {
            Image(systemName: themeIconName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(palette.primaryText)
                .frame(width: 29, height: 29)
                .background(
                    Rectangle()
                        .fill(palette.subtleFill)
                )
                .overlay(
                    Rectangle()
                        .stroke(palette.separator, lineWidth: 1)
                )
        }
        .menuStyle(.borderlessButton)
    }

    private var themeIconName: String {
        switch themeSettings.theme {
        case .system:
            "circle.lefthalf.filled"
        case .light:
            "sun.max"
        case .dark:
            "moon"
        }
    }

    private func iconButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(palette.primaryText)
                .frame(width: 29, height: 29)
                .background(
                    Rectangle()
                        .fill(palette.subtleFill)
                )
                .overlay(
                    Rectangle()
                        .stroke(palette.separator, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
