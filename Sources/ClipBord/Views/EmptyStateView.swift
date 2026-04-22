import SwiftUI

struct EmptyStateView: View {
    @Environment(\.colorScheme) private var colorScheme

    private var palette: ClipBordPalette {
        ClipBordPalette(scheme: colorScheme)
    }

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Rectangle()
                    .fill(palette.subtleFill)
                    .overlay(
                        Rectangle()
                            .stroke(palette.separator, lineWidth: 1)
                    )
                    .frame(width: 72, height: 72)

                Image(systemName: "square.on.square")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }

            VStack(spacing: 8) {
                Text("Nothing copied yet")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(palette.primaryText)
                    .multilineTextAlignment(.center)

                Text("Copy text or images and they will appear here.")
                    .font(.callout)
                    .foregroundStyle(palette.secondaryText)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 240)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 260)
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
}
