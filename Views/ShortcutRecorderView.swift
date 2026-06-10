import AppKit
import Carbon
import SwiftUI

struct ShortcutRecorderView: View {
    @State private var isRecording = false
    @State private var hotKey = AppSettings.toggleHotKey
    @State private var keyMonitor: Any?
    @State private var registrationFailed = false

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            HStack(spacing: 8) {
                if hotKey != .defaultToggle, !isRecording {
                    Button("Reset") { save(.defaultToggle) }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                        .help("Reset to \(HotKey.defaultToggle.displayString)")
                }

                Button(action: toggleRecording) {
                    Text(isRecording ? "Type shortcut…" : hotKey.displayString)
                        .frame(minWidth: 90)
                }
                .help(
                    isRecording
                        ? "Press a key combination, or Esc to cancel"
                        : "Click to record a new shortcut"
                )
            }

            if registrationFailed {
                Text("Couldn't register — shortcut may be in use by another app.")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .onDisappear(perform: stopRecording)
        .onReceive(NotificationCenter.default.publisher(for: .hotKeyRegistrationFailed)) { _ in
            registrationFailed = true
            hotKey = AppSettings.toggleHotKey
        }
    }

    private func toggleRecording() {
        isRecording ? stopRecording() : startRecording()
    }

    private func startRecording() {
        isRecording = true
        registrationFailed = false
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let bareEscape = event.keyCode == UInt16(kVK_Escape)
                && event.modifierFlags
                    .intersection([.command, .option, .control, .shift])
                    .isEmpty
            if bareEscape {
                stopRecording()
            } else if let newHotKey = HotKey(event: event) {
                save(newHotKey)
                stopRecording()
            }
            return nil
        }
    }

    private func stopRecording() {
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
        }
        keyMonitor = nil
        isRecording = false
    }

    private func save(_ newHotKey: HotKey) {
        hotKey = newHotKey
        registrationFailed = false
        AppSettings.toggleHotKey = newHotKey
        NotificationCenter.default.post(name: .hotKeyChanged, object: nil)
    }
}
