import AppKit
import CryptoKit
import Foundation
import os

struct ClipboardCapture {
    let kind: ClipboardItem.Kind
    let fingerprint: String
    let textContent: String?
    let imageData: Data?
    let imageSize: CGSize?

    static func capture(from pasteboard: NSPasteboard) -> ClipboardCapture? {
        if pasteboard.containsImage, let image = NSImage(pasteboard: pasteboard), let pngData = image.pngData {
            return ClipboardCapture(
                kind: .image,
                fingerprint: Self.fingerprint(for: pngData),
                textContent: nil,
                imageData: pngData,
                imageSize: image.pixelSize
            )
        }

        guard let text = pasteboard.string(forType: .string) else {
            return nil
        }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        return ClipboardCapture(
            kind: .text,
            fingerprint: Self.fingerprint(for: Data(text.utf8)),
            textContent: text,
            imageData: nil,
            imageSize: nil
        )
    }

    private static func fingerprint(for data: Data) -> String {
        SHA256.hash(data: data)
            .compactMap { String(format: "%02x", $0) }
            .joined()
    }
}

@MainActor
final class PasteboardMonitor {
    private let logger = Logger(subsystem: "com.sittinonthanonklang.ClipBord", category: "PasteboardMonitor")
    private let pasteboard: NSPasteboard
    private let onCapture: (ClipboardCapture) -> Void

    private var timer: Timer?
    private var lastChangeCount: Int
    private var ignoredChangeCount: Int?

    init(
        pasteboard: NSPasteboard = .general,
        onCapture: @escaping (ClipboardCapture) -> Void
    ) {
        self.pasteboard = pasteboard
        self.onCapture = onCapture
        lastChangeCount = pasteboard.changeCount
    }

    func start() {
        guard timer == nil else {
            return
        }

        let timer = Timer.scheduledTimer(withTimeInterval: 0.55, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.pollPasteboard()
            }
        }
        timer.tolerance = 0.15
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func ignoreNextChange() {
        ignoredChangeCount = pasteboard.changeCount + 1
    }

    private func pollPasteboard() {
        let currentChangeCount = pasteboard.changeCount
        guard currentChangeCount != lastChangeCount else {
            return
        }

        lastChangeCount = currentChangeCount

        if ignoredChangeCount == currentChangeCount {
            ignoredChangeCount = nil
            return
        }

        guard let capture = ClipboardCapture.capture(from: pasteboard) else {
            logger.debug("Skipped unsupported clipboard payload.")
            return
        }

        onCapture(capture)
    }
}

private extension NSPasteboard {
    var containsImage: Bool {
        guard let types else {
            return false
        }

        return types.contains(.png)
            || types.contains(.tiff)
            || types.contains { $0.rawValue.hasPrefix("public.image") }
    }
}
