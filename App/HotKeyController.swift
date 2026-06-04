import Carbon
import Foundation

final class HotKeyController {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private static var handler: (() -> Void)?

    func registerTogglePanelHandler(_ handler: @escaping () -> Void) {
        Self.handler = handler
        unregister()

        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let installStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            Self.eventCallback,
            1,
            &eventSpec,
            nil,
            &eventHandler
        )
        guard installStatus == noErr else { return }

        let hotKeyID = EventHotKeyID(signature: OSType(0x4E504C21), id: 1)
        let registerStatus = RegisterEventHotKey(
            UInt32(kVK_ANSI_P),
            UInt32(cmdKey | shiftKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        guard registerStatus == noErr else { return }
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
        Self.handler = nil
    }

    private static let eventCallback: EventHandlerUPP = { _, event, _ -> OSStatus in
        var hotKeyID = EventHotKeyID()
        let status = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotKeyID
        )
        guard status == noErr, hotKeyID.id == 1 else { return noErr }
        DispatchQueue.main.async {
            handler?()
        }
        return noErr
    }
}
