import Carbon
import Foundation

enum HotkeyManagerError: LocalizedError {
    case handlerInstallFailed(OSStatus)
    case registrationFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case let .handlerInstallFailed(status):
            return "Global hotkey handler install failed (\(status))."
        case let .registrationFailed(status):
            return "Global hotkey registration failed (\(status))."
        }
    }
}

final class HotkeyManager {
    private let signature = OSType(0x53485459)
    private let hotkeyID: UInt32 = 1
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var onCaptureRequested: (() -> Void)?

    func registerCaptureHotkey(onCaptureRequested: @escaping () -> Void) throws {
        self.onCaptureRequested = onCaptureRequested

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )

        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard
                    let userData,
                    let event
                else {
                    return noErr
                }

                let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                return manager.handleHotkeyEvent(event)
            },
            1,
            &eventType,
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            &eventHandler
        )

        guard handlerStatus == noErr else {
            throw HotkeyManagerError.handlerInstallFailed(handlerStatus)
        }

        let eventHotKeyID = EventHotKeyID(signature: signature, id: hotkeyID)
        let registrationStatus = RegisterEventHotKey(
            UInt32(kVK_ANSI_S),
            UInt32(cmdKey | shiftKey),
            eventHotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        guard registrationStatus == noErr else {
            unregister()
            throw HotkeyManagerError.registrationFailed(registrationStatus)
        }
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        if let eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }

    private func handleHotkeyEvent(_ event: EventRef) -> OSStatus {
        var eventHotKeyID = EventHotKeyID()
        let status = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &eventHotKeyID
        )

        guard status == noErr else {
            return status
        }

        guard eventHotKeyID.signature == signature, eventHotKeyID.id == hotkeyID else {
            return noErr
        }

        onCaptureRequested?()
        return noErr
    }
}
