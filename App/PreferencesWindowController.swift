import AppKit
import SwiftUI

final class PreferencesWindowController {
    static let shared = PreferencesWindowController()

    private var window: NSWindow?

    private init() {}

    func show() {
        if window == nil {
            let hosting = NSHostingController(rootView: PreferencesView())
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 440, height: 300),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "NotePanel Preferences"
            window.contentViewController = hosting
            window.center()
            window.isReleasedWhenClosed = false
            self.window = window
        }

        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}
