import AppKit
import Carbon

struct HotKey: Codable, Equatable {
    var keyCode: UInt16
    /// `NSEvent.ModifierFlags` raw value — canonical storage; converted to Carbon on registration.
    var modifiers: UInt

    static let defaultToggle = HotKey(
        keyCode: UInt16(kVK_ANSI_P),
        modifiers: NSEvent.ModifierFlags([.command, .shift]).rawValue
    )

    init(keyCode: UInt16, modifiers: UInt) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }

    /// Builds a hot key from a key-down event; nil unless at least one of ⌘⌥⌃ is held
    /// (shift alone would shadow ordinary typing).
    init?(event: NSEvent) {
        let flags = event.modifierFlags.intersection([.command, .option, .control, .shift])
        guard !flags.intersection([.command, .option, .control]).isEmpty else { return nil }
        self.init(keyCode: event.keyCode, modifiers: flags.rawValue)
    }

    var modifierFlags: NSEvent.ModifierFlags {
        NSEvent.ModifierFlags(rawValue: modifiers)
            .intersection([.command, .option, .control, .shift])
    }

    var carbonModifiers: UInt32 {
        var carbon: UInt32 = 0
        if modifierFlags.contains(.command) { carbon |= UInt32(cmdKey) }
        if modifierFlags.contains(.shift) { carbon |= UInt32(shiftKey) }
        if modifierFlags.contains(.option) { carbon |= UInt32(optionKey) }
        if modifierFlags.contains(.control) { carbon |= UInt32(controlKey) }
        return carbon
    }

    var displayString: String {
        var parts = ""
        if modifierFlags.contains(.control) { parts += "⌃" }
        if modifierFlags.contains(.option) { parts += "⌥" }
        if modifierFlags.contains(.shift) { parts += "⇧" }
        if modifierFlags.contains(.command) { parts += "⌘" }
        return parts + KeyCodeFormatter.displayString(forKeyCode: keyCode)
    }
}
