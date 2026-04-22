import AppKit
import SwiftUI

struct ClipboardCardView: View {
    let item: ClipboardItem
    let imageURL: URL?
    let onRestore: () -> Void
    let onTogglePin: () -> Void
    let onDelete: () -> Void

    @State private var isHovered = false
    @Environment(\.colorScheme) private var colorScheme

    private var palette: ClipBordPalette {
        ClipBordPalette(scheme: colorScheme)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: onRestore) {
                HStack(alignment: .top, spacing: 12) {
                    preview

                    VStack(alignment: .leading, spacing: 7) {
                        Text(primaryText)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(palette.primaryText)
                            .multilineTextAlignment(.leading)
                            .lineLimit(item.kind == .text ? 3 : 2)

                        HStack(spacing: 8) {
                            if item.isPinned {
                                chip(title: "Pinned", systemImage: "pin.fill")
                            }

                            if let imageDimensionsLabel = item.imageDimensionsLabel {
                                chip(title: imageDimensionsLabel, systemImage: "photo")
                            } else if item.kind == .text {
                                chip(title: "\(item.textCharacterCount) chars", systemImage: "text.alignleft")
                            }

                            Text(ClipBordDateFormatting.relativeString(for: item.updatedAt))
                                .font(.caption)
                                .foregroundStyle(palette.tertiaryText)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            VStack(spacing: 8) {
                Menu {
                    Button(item.isPinned ? "Unpin" : "Pin", action: onTogglePin)
                    Button("Delete", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(palette.secondaryText)
                        .frame(width: 26, height: 26)
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

                Spacer(minLength: 4)

                actionButton(
                    systemImage: item.isPinned ? "pin.fill" : "pin",
                    tint: item.isPinned ? Color.accentColor : palette.secondaryText,
                    action: onTogglePin
                )
            }
            .opacity(isHovered ? 1 : 0.88)
        }
        .padding(14)
        .background(
            Rectangle()
                .fill(isHovered ? palette.hoverBackground : palette.cardBackground)
                .overlay(
                    Rectangle()
                        .stroke(item.isPinned ? palette.accentStroke : palette.separator, lineWidth: item.isPinned ? 1.5 : 1)
                )
        )
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.24 : 0.08), radius: isHovered ? 12 : 7, y: 4)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    @ViewBuilder
    private var preview: some View {
        switch item.kind {
        case .text:
            ZStack {
                Rectangle()
                    .fill(palette.subtleFill)
                    .overlay(
                        Rectangle()
                            .stroke(palette.separator, lineWidth: 1)
                    )

                Image(systemName: "doc.text")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }
            .frame(width: 48, height: 48)

        case .image:
            Group {
                if let imageURL, let image = NSImage(contentsOf: imageURL) {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.accentColor.opacity(colorScheme == .dark ? 0.28 : 0.18),
                                        Color(nsColor: .systemTeal).opacity(colorScheme == .dark ? 0.25 : 0.16),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                Rectangle()
                                    .stroke(palette.separator, lineWidth: 1)
                            )

                        Image(systemName: "photo.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color.accentColor)
                    }
                }
            }
            .frame(width: 48, height: 48)
            .clipped()
        }
    }

    private var primaryText: String {
        switch item.kind {
        case .text:
            return item.previewText
        case .image:
            return "Copied image"
        }
    }

    private func chip(title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption)
            .foregroundStyle(palette.secondaryText)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(
                Rectangle()
                    .fill(palette.subtleFill)
            )
            .overlay(
                Rectangle()
                    .stroke(palette.separator, lineWidth: 1)
            )
    }

    private func actionButton(systemImage: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 26, height: 26)
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
