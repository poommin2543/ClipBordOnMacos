import AppKit
import Carbon
import SwiftUI

struct ShortcutRecorderButton: View {
    @ObservedObject var settings: HotKeySettings
    let palette: ClipBordPalette
    let onShortcutChange: (HotKeyConfiguration) -> Void

    @State private var isRecording = false
    @State private var eventMonitor: Any?
    @State private var hint: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button {
                toggleRecording()
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "keyboard")
                        .font(.system(size: 12, weight: .medium))

                    Text(isRecording ? "Press keys" : settings.configuration.displayString)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                }
                .foregroundStyle(isRecording ? Color.accentColor : palette.primaryText)
                .padding(.horizontal, 9)
                .padding(.vertical, 7)
                .background(
                    Rectangle()
                        .fill(isRecording ? palette.accentFill : palette.subtleFill)
                )
                .overlay(
                    Rectangle()
                        .stroke(isRecording ? palette.accentStroke : palette.separator, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            if let hint {
                Text(hint)
                    .font(.caption2)
                    .foregroundStyle(palette.warning)
                    .lineLimit(1)
            } else if let message = settings.message {
                Text(message)
                    .font(.caption2)
                    .foregroundStyle(palette.warning)
                    .lineLimit(1)
            }
        }
        .onDisappear {
            stopRecording()
        }
    }

    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        stopRecording()
        hint = nil
        isRecording = true

        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == UInt16(kVK_Escape) {
                stopRecording()
                return nil
            }

            guard let configuration = HotKeyConfiguration(event: event) else {
                hint = "Use a modifier key"
                return nil
            }

            onShortcutChange(configuration)
            stopRecording()
            return nil
        }
    }

    private func stopRecording() {
        isRecording = false

        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
            self.eventMonitor = nil
        }
    }
}
