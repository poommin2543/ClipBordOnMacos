import SwiftUI

enum ClipboardPanelPresentation {
    case menuBar
    case overlay

    var panelWidth: CGFloat {
        switch self {
        case .menuBar:
            390
        case .overlay:
            390
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
    @ObservedObject var retentionSettings: RetentionSettings
    @ObservedObject var themeSettings: ThemeSettings
    @ObservedObject var updateChecker: GitHubUpdateChecker
    let presentation: ClipboardPanelPresentation
    let onShortcutChange: (HotKeyConfiguration) -> Void
    let onSelectItem: (ClipboardItem) -> Void
    let onClose: (() -> Void)?
    let onQuit: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme
    @State private var searchText = ""
    @State private var selectedDetailItem: ClipboardItem?

    private var effectiveColorScheme: ColorScheme {
        themeSettings.theme.resolvedColorScheme(systemScheme: colorScheme)
    }

    private var palette: ClipBordPalette {
        ClipBordPalette(scheme: effectiveColorScheme)
    }

    private var normalizedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var filteredItems: [ClipboardItem] {
        let query = normalizedSearchText
        guard !query.isEmpty else {
            return store.items
        }

        return store.items.filter {
            $0.searchableText.localizedCaseInsensitiveContains(query)
        }
    }

    private var isShowingDetail: Bool {
        selectedDetailItem != nil
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

                if let detailItem = selectedDetailItem {
                    let currentItem = store.items.first(where: { $0.id == detailItem.id }) ?? detailItem
                    ClipboardDetailView(
                        item: currentItem,
                        imageURL: store.imageURL(for: currentItem),
                        onRestore: {
                            onSelectItem(currentItem)
                            selectedDetailItem = nil
                        },
                        onTogglePin: {
                            store.togglePin(currentItem)
                        },
                        onDelete: {
                            store.delete(currentItem)
                            selectedDetailItem = nil
                        },
                        onClose: {
                            selectedDetailItem = nil
                        }
                    )
                } else if store.items.isEmpty {
                    EmptyStateView()
                } else if filteredItems.isEmpty {
                    noMatchesView
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(filteredItems) { item in
                                ClipboardCardView(
                                    item: item,
                                    imageURL: store.imageURL(for: item),
                                    onRestore: {
                                        onSelectItem(item)
                                    },
                                    onShowDetails: {
                                        selectedDetailItem = item
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
                        .minimumScaleFactor(0.65)

                    Text(AppVersion.displayLabel)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(palette.secondaryText.opacity(0.9))
                }
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 0)

                headerActions
            }

            updateBanner

            if !store.items.isEmpty, !isShowingDetail {
                searchField
            }

            if !isShowingDetail {
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
        }
        .padding(.bottom, 2)
    }

    private var headerActions: some View {
        HStack(alignment: .center, spacing: 8) {
            retentionMenu

            themeMenu

            Button("Clear all") {
                store.clearAllVisibleItems()
            }
            .buttonStyle(.plain)
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundStyle(store.hasItemsToClear ? palette.primaryText : palette.secondaryText.opacity(0.55))
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
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
        .fixedSize(horizontal: true, vertical: false)
    }

    private var searchField: some View {
        HStack(spacing: 7) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(palette.secondaryText)

            TextField("Search history", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(palette.primaryText)

            if !normalizedSearchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(palette.secondaryText)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            Rectangle()
                .fill(palette.subtleFill)
        )
        .overlay(
            Rectangle()
                .stroke(palette.separator, lineWidth: 1)
        )
    }

    private var noMatchesView: some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 24, weight: .light))
                .foregroundStyle(Color.accentColor)
            Text("No matches")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(palette.primaryText)
            Text("Try another search term.")
                .font(.callout)
                .foregroundStyle(palette.secondaryText)
        }
        .frame(maxWidth: .infinity, minHeight: 220)
        .padding(22)
        .background(
            Rectangle()
                .fill(palette.cardBackground)
                .overlay(
                    Rectangle()
                        .stroke(palette.separator, lineWidth: 1)
                )
        )
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
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 14, weight: .light))
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(.teal)
                Text("Update available \(versionLabel)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Spacer(minLength: 0)
                if ClipBordReleaseInstaller.isRunningFromAppBundle {
                    Button("Update now") {
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

    private var retentionMenu: some View {
        Menu {
            Picker("Max recent items", selection: $retentionSettings.maximumUnpinnedItems) {
                ForEach(RetentionSettings.countOptions, id: \.value) { option in
                    Text(option.title).tag(option.value)
                }
            }

            Picker("Max age", selection: $retentionSettings.maximumUnpinnedAgeDays) {
                ForEach(RetentionSettings.ageOptions, id: \.value) { option in
                    Text(option.title).tag(option.value)
                }
            }

            Divider()

            Text("Pinned items are always kept")
            Text(retentionSettings.summary)
        } label: {
            Image(systemName: "slider.horizontal.3")
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
        .accessibilityLabel("Retention settings")
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
