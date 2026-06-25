import Carbon
import Foundation

final class HotKeyController {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private static var handler: (() -> Void)?

    /// Registers the hot key, replacing any previous registration.
    /// Returns false when the combo could not be registered (e.g. taken by another app).
    @discardableResult
    func register(_ hotKey: HotKey, handler: @escaping () -> Void) -> Bool {
        unregister()
        Self.handler = handler

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
        guard installStatus == noErr else {
            unregister()
            return false
        }

        let hotKeyID = EventHotKeyID(signature: OSType(0x4E504C21), id: 1)
        let registerStatus = RegisterEventHotKey(
            UInt32(hotKey.keyCode),
            hotKey.carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        guard registerStatus == noErr else {
            unregister()
            return false
        }
        return true
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
