import AppKit

/// NSPanel subclass that accepts keyboard focus for text editing.
final class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
