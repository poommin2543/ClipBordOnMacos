import AppKit
import SwiftUI

struct ClipboardDetailView: View {
    let item: ClipboardItem
    let imageURL: URL?
    let onRestore: () -> Void
    let onTogglePin: () -> Void
    let onDelete: () -> Void
    let onClose: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var palette: ClipBordPalette {
        ClipBordPalette(scheme: colorScheme)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header

            Divider()

            content

            Divider()

            actions
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(
            Rectangle()
                .fill(palette.cardBackground)
                .overlay(
                    Rectangle()
                        .stroke(palette.separator, lineWidth: 1)
                )
        )
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: item.kind == .text ? "doc" : "photo")
                .font(.system(size: 18, weight: .light))
                .foregroundStyle(Color.accentColor)
                .frame(width: 32, height: 32)
                .background(
                    Rectangle()
                        .fill(palette.subtleFill)
                )
                .overlay(
                    Rectangle()
                        .stroke(palette.separator, lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 5) {
                Text(item.title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(palette.primaryText)
                    .lineLimit(2)

                Text(metadataLine)
                    .font(.caption)
                    .foregroundStyle(palette.secondaryText)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            Button {
                onClose()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(palette.secondaryText)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
    }

    @ViewBuilder
    private var content: some View {
        switch item.kind {
        case .text:
            ScrollView {
                Text(item.textContent ?? "")
                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                    .foregroundStyle(palette.primaryText)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
            }
            .frame(minHeight: 150, maxHeight: .infinity)
            .background(
                Rectangle()
                    .fill(palette.cardBackground)
            )
            .overlay(
                Rectangle()
                    .stroke(palette.separator, lineWidth: 1)
            )

        case .image:
            ZStack {
                Rectangle()
                    .fill(palette.cardBackground)
                    .overlay(
                        Rectangle()
                            .stroke(palette.separator, lineWidth: 1)
                    )

                if let imageURL, let image = NSImage(contentsOf: imageURL) {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding(14)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 24, weight: .light))
                            .foregroundStyle(palette.warning)
                        Text("Image file is no longer available")
                            .font(.callout)
                            .foregroundStyle(palette.secondaryText)
                    }
                }
            }
            .frame(minHeight: 170, maxHeight: .infinity)
        }
    }

    private var actions: some View {
        HStack(spacing: 10) {
            Button("Copy") {
                onRestore()
            }
            .buttonStyle(.borderedProminent)

            Button(item.isPinned ? "Unpin" : "Pin") {
                onTogglePin()
            }
            .buttonStyle(.bordered)

            Spacer(minLength: 0)

            Button("Delete", role: .destructive) {
                onDelete()
            }
            .buttonStyle(.bordered)
        }
    }

    private var metadataLine: String {
        let kindDetail: String
        switch item.kind {
        case .text:
            kindDetail = "\(item.textCharacterCount) chars"
        case .image:
            kindDetail = item.imageDimensionsLabel ?? "Image"
        }

        return "\(kindDetail) • Created \(fullDateString(for: item.createdAt)) • Updated \(ClipBordDateFormatting.relativeString(for: item.updatedAt))"
    }

    private func fullDateString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
