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
            502
        case .overlay:
            532
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
    @ObservedObject var updateChecker: GitHubUpdateChecker
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
            .onAppear {
                updateChecker.checkIfNeeded()
            }
        }
        .frame(width: presentation.panelWidth, height: presentation.panelHeight)
        .environment(\.colorScheme, effectiveColorScheme)
        .preferredColorScheme(themeSettings.theme.colorScheme)
        .id(themeSettings.theme)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("ClipBord")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundStyle(palette.primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Text(AppVersion.displayLabel)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(palette.secondaryText.opacity(0.9))
                }
                .layoutPriority(1)

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

            updateBanner

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

    @ViewBuilder
    private var updateBanner: some View {
        switch updateChecker.phase {
        case .checking:
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                    .scaleEffect(0.9)
                Text("Checking for updates…")
                    .font(.caption)
                    .foregroundStyle(palette.secondaryText)
                Spacer(minLength: 0)
            }
            .padding(.vertical, 2)

        case .downloading:
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                    .scaleEffect(0.9)
                Text("Downloading update…")
                    .font(.caption)
                    .foregroundStyle(palette.secondaryText)
                Spacer(minLength: 0)
            }
            .padding(.vertical, 2)

        case let .updateAvailable(versionLabel, remoteURL):
            HStack(spacing: 10) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.teal)
                Text("Update available \(versionLabel)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Spacer(minLength: 0)
                if ClipBordReleaseInstaller.isRunningFromAppBundle {
                    Button("Install & relaunch") {
                        updateChecker.beginInstallUpdate()
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(palette.primaryText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Rectangle()
                            .fill(palette.subtleFill)
                    )
                    .overlay(
                        Rectangle()
                            .stroke(palette.separator, lineWidth: 1)
                    )
                } else {
                    Button("Download") {
                        updateChecker.openReleaseDownloadPage(remoteURL)
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(palette.primaryText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Rectangle()
                            .fill(palette.subtleFill)
                    )
                    .overlay(
                        Rectangle()
                            .stroke(palette.separator, lineWidth: 1)
                    )
                }
            }
            .padding(.vertical, 2)

        default:
            EmptyView()
        }
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
        .menuIndicator(.hidden)
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
