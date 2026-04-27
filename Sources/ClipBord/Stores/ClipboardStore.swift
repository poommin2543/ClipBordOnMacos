import AppKit
import Combine
import Foundation
import os

@MainActor
final class ClipboardStore: ObservableObject {
    @Published private(set) var items: [ClipboardItem] = []
    @Published private(set) var statusMessage = "Watching your clipboard"

    private let logger = Logger(subsystem: "com.sittinonthanonklang.ClipBord", category: "ClipboardStore")
    private let fileManager = FileManager.default
    private let retentionSettings: RetentionSettings
    private let historyURL: URL
    private let imageDirectoryURL: URL
    private var cancellables = Set<AnyCancellable>()

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private var pasteboardMonitor: PasteboardMonitor?

    init(retentionSettings: RetentionSettings) {
        self.retentionSettings = retentionSettings

        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ClipBord", isDirectory: true)

        historyURL = baseURL.appendingPathComponent("history.json")
        imageDirectoryURL = baseURL.appendingPathComponent("Images", isDirectory: true)

        prepareStorage()
        loadItems()
        applyRetentionPolicy(persistWhenChanged: true)
        observeRetentionChanges()

        pasteboardMonitor = PasteboardMonitor { [weak self] capture in
            self?.ingest(capture)
        }
        pasteboardMonitor?.start()
    }

    var pinnedItems: [ClipboardItem] {
        items.filter(\.isPinned)
    }

    var recentItems: [ClipboardItem] {
        items.filter { !$0.isPinned }
    }

    var pinnedCount: Int {
        pinnedItems.count
    }

    var hasItemsToClear: Bool {
        !recentItems.isEmpty
    }

    func setStatusMessage(_ message: String) {
        statusMessage = message
    }

    @discardableResult
    func restore(_ item: ClipboardItem) -> Bool {
        let pasteboard = NSPasteboard.general
        pasteboardMonitor?.ignoreNextChange()
        pasteboard.clearContents()

        let didWrite: Bool
        switch item.kind {
        case .text:
            didWrite = pasteboard.setString(item.textContent ?? "", forType: .string)
        case .image:
            guard
                let imageURL = imageURL(for: item),
                let image = NSImage(contentsOf: imageURL)
            else {
                statusMessage = "That image file is no longer available"
                return false
            }

            didWrite = pasteboard.writeObjects([image])
        }

        guard didWrite else {
            statusMessage = "Could not copy that item back"
            return false
        }

        promote(itemID: item.id)
        statusMessage = item.kind == .text ? "Text is ready to paste" : "Image is ready to paste"
        return true
    }

    func togglePin(_ item: ClipboardItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else {
            return
        }

        items[index].isPinned.toggle()
        let isPinned = items[index].isPinned
        items = sortItems(items)
        persistItems()
        statusMessage = isPinned ? "Pinned for later" : "Moved back to recent"
    }

    func delete(_ item: ClipboardItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else {
            return
        }

        let removedItem = items.remove(at: index)
        removeAssets(for: [removedItem])
        persistItems()
        statusMessage = "Removed from clipboard history"
    }

    func clearUnpinned() {
        let pinned = items.filter(\.isPinned)
        let removed = items.filter { !$0.isPinned }

        guard !removed.isEmpty else {
            statusMessage = "Nothing to clear right now"
            return
        }

        items = sortItems(pinned)
        removeAssets(for: removed)
        persistItems()
        statusMessage = "Cleared recent clips"
    }

    func clearAllVisibleItems() {
        clearUnpinned()
    }

    func imageURL(for item: ClipboardItem) -> URL? {
        guard let fileName = item.imageFileName else {
            return nil
        }

        return imageDirectoryURL.appendingPathComponent(fileName)
    }

    private func ingest(_ capture: ClipboardCapture) {
        let now = Date()

        if let existingIndex = items.firstIndex(where: { $0.fingerprint == capture.fingerprint }) {
            items[existingIndex].updatedAt = now
            items = sortItems(items)
            persistItems()
            statusMessage = capture.kind == .text ? "Updated a saved text clip" : "Updated a saved image clip"
            return
        }

        var item = ClipboardItem(
            id: UUID(),
            kind: capture.kind,
            fingerprint: capture.fingerprint,
            createdAt: now,
            updatedAt: now,
            isPinned: false,
            textContent: capture.textContent,
            imageFileName: nil,
            imageWidth: capture.imageSize.map { Double($0.width) },
            imageHeight: capture.imageSize.map { Double($0.height) }
        )

        if let imageData = capture.imageData {
            let fileName = "\(item.id.uuidString).png"
            let destinationURL = imageDirectoryURL.appendingPathComponent(fileName)

            do {
                try imageData.write(to: destinationURL, options: .atomic)
                item.imageFileName = fileName
            } catch {
                logger.error("Failed to save clipboard image: \(error.localizedDescription, privacy: .public)")
                statusMessage = "Could not save that copied image"
                return
            }
        }

        items.insert(item, at: 0)
        applyRetentionPolicy(persistWhenChanged: false)
        items = sortItems(items)
        persistItems()
        statusMessage = capture.kind == .text ? "Saved a new text clip" : "Saved a new image clip"
    }

    private func promote(itemID: UUID) {
        guard let index = items.firstIndex(where: { $0.id == itemID }) else {
            return
        }

        items[index].updatedAt = Date()
        items = sortItems(items)
        persistItems()
    }

    private func prepareStorage() {
        let applicationSupportURL = historyURL.deletingLastPathComponent()

        do {
            try fileManager.createDirectory(at: applicationSupportURL, withIntermediateDirectories: true)
            try fileManager.createDirectory(at: imageDirectoryURL, withIntermediateDirectories: true)
        } catch {
            logger.error("Failed to prepare application support: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func loadItems() {
        guard fileManager.fileExists(atPath: historyURL.path) else {
            items = []
            return
        }

        do {
            let data = try Data(contentsOf: historyURL)
            let decodedItems = try decoder.decode([ClipboardItem].self, from: data)
            let filteredItems = decodedItems.filter { item in
                guard item.kind == .image else {
                    return true
                }

                guard let imageURL = imageURL(for: item) else {
                    return false
                }

                return fileManager.fileExists(atPath: imageURL.path)
            }

            items = sortItems(filteredItems)
        } catch {
            logger.error("Failed to load clipboard history: \(error.localizedDescription, privacy: .public)")
            items = []
        }
    }

    private func persistItems() {
        do {
            let data = try encoder.encode(items)
            try data.write(to: historyURL, options: .atomic)
        } catch {
            logger.error("Failed to persist clipboard history: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func observeRetentionChanges() {
        retentionSettings.$maximumUnpinnedItems
            .dropFirst()
            .sink { [weak self] _ in
                self?.applyRetentionPolicy(persistWhenChanged: true)
            }
            .store(in: &cancellables)

        retentionSettings.$maximumUnpinnedAgeDays
            .dropFirst()
            .sink { [weak self] _ in
                self?.applyRetentionPolicy(persistWhenChanged: true)
            }
            .store(in: &cancellables)
    }

    private func applyRetentionPolicy(persistWhenChanged: Bool) {
        let pinned = items.filter(\.isPinned)
        var keptRecent = items.filter { !$0.isPinned }
        var removedItems: [ClipboardItem] = []

        let maximumAgeDays = retentionSettings.maximumUnpinnedAgeDays
        if maximumAgeDays > RetentionSettings.unlimited,
           let cutoff = Calendar.current.date(byAdding: .day, value: -maximumAgeDays, to: Date()) {
            let partition = keptRecent.partitioned { $0.updatedAt >= cutoff }
            keptRecent = partition.matching
            removedItems.append(contentsOf: partition.rejected)
        }

        let maximumItems = retentionSettings.maximumUnpinnedItems
        if maximumItems > RetentionSettings.unlimited, keptRecent.count > maximumItems {
            removedItems.append(contentsOf: keptRecent.dropFirst(maximumItems))
            keptRecent = Array(keptRecent.prefix(maximumItems))
        }

        guard !removedItems.isEmpty else {
            return
        }

        items = sortItems(pinned + keptRecent)
        removeAssets(for: removedItems)
        if persistWhenChanged {
            persistItems()
        }
    }

    private func removeAssets(for items: [ClipboardItem]) {
        for item in items {
            guard let imageURL = imageURL(for: item), fileManager.fileExists(atPath: imageURL.path) else {
                continue
            }

            do {
                try fileManager.removeItem(at: imageURL)
            } catch {
                logger.error("Failed to remove clipboard asset: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    private func sortItems(_ items: [ClipboardItem]) -> [ClipboardItem] {
        items.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned {
                return lhs.isPinned && !rhs.isPinned
            }

            return lhs.updatedAt > rhs.updatedAt
        }
    }
}

private extension Array {
    func partitioned(_ isIncluded: (Element) -> Bool) -> (matching: [Element], rejected: [Element]) {
        var matching: [Element] = []
        var rejected: [Element] = []

        for element in self {
            if isIncluded(element) {
                matching.append(element)
            } else {
                rejected.append(element)
            }
        }

        return (matching, rejected)
    }
}
