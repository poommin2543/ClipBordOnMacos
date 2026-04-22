import Foundation

struct ClipboardItem: Identifiable, Codable, Hashable {
    enum Kind: String, Codable {
        case text
        case image
    }

    let id: UUID
    var kind: Kind
    var fingerprint: String
    var createdAt: Date
    var updatedAt: Date
    var isPinned: Bool
    var textContent: String?
    var imageFileName: String?
    var imageWidth: Double?
    var imageHeight: Double?

    var title: String {
        switch kind {
        case .text:
            return textTitle
        case .image:
            return "Copied Image"
        }
    }

    var previewText: String {
        switch kind {
        case .text:
            return normalizedText
        case .image:
            return imageDimensionsLabel ?? "Saved to your clipboard shelf"
        }
    }

    var kindLabel: String {
        switch kind {
        case .text:
            return "Text"
        case .image:
            return "Image"
        }
    }

    var searchableText: String {
        [
            title,
            previewText,
            textContent ?? "",
            kindLabel,
        ]
        .joined(separator: " ")
    }

    var textCharacterCount: Int {
        normalizedText.count
    }

    var imageDimensionsLabel: String? {
        guard let imageWidth, let imageHeight else {
            return nil
        }

        return "\(Int(imageWidth.rounded())) × \(Int(imageHeight.rounded())) px"
    }

    private var normalizedText: String {
        let text = textContent?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if text.isEmpty {
            return "Empty text clip"
        }

        return text
    }

    private var textTitle: String {
        let compact = normalizedText
            .split(whereSeparator: \.isNewline)
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? normalizedText

        if compact.count <= 42 {
            return compact
        }

        return String(compact.prefix(39)) + "..."
    }
}
