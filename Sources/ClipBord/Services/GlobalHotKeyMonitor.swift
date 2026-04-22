import Carbon
import Foundation
import os

final class GlobalHotKeyMonitor {
    private let configuration: HotKeyConfiguration
    private let handler: @Sendable @MainActor () -> Void
    private let logger = Logger(subsystem: "com.sittinonthanonklang.ClipBord", category: "HotKey")

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private let hotKeyID = EventHotKeyID(signature: OSType(0x434C4252), id: 1)

    init(configuration: HotKeyConfiguration, handler: @escaping @Sendable @MainActor () -> Void) {
        self.configuration = configuration
        self.handler = handler
    }

    deinit {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }

        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
        }
    }

    func start() -> OSStatus {
        guard hotKeyRef == nil else {
            return noErr
        }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let userData = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        let installStatus = InstallEventHandler(
            GetEventDispatcherTarget(),
            { _, event, userData in
                guard let event, let userData else {
                    return noErr
                }

                let monitor = Unmanaged<GlobalHotKeyMonitor>.fromOpaque(userData).takeUnretainedValue()
                return monitor.handle(event)
            },
            1,
            &eventType,
            userData,
            &eventHandlerRef
        )

        guard installStatus == noErr else {
            logger.error("Could not install hotkey event handler: \(installStatus)")
            return installStatus
        }

        let registerStatus = RegisterEventHotKey(
            configuration.keyCode,
            configuration.modifiers,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )

        if registerStatus == noErr {
            logger.debug("Registered global hotkey: \(self.configuration.displayString, privacy: .public)")
        } else {
            logger.error("Could not register global hotkey \(self.configuration.displayString, privacy: .public): \(registerStatus)")

            if let eventHandlerRef {
                RemoveEventHandler(eventHandlerRef)
                self.eventHandlerRef = nil
            }
        }

        return registerStatus
    }

    private func handle(_ event: EventRef) -> OSStatus {
        var receivedHotKeyID = EventHotKeyID()
        let status = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &receivedHotKeyID
        )

        guard status == noErr else {
            return status
        }

        guard
            receivedHotKeyID.signature == hotKeyID.signature,
            receivedHotKeyID.id == hotKeyID.id
        else {
            return noErr
        }

        logger.debug("Received global hotkey event.")
        let handler = handler
        Task { @MainActor [handler] in
            handler()
        }
        return noErr
    }
}
