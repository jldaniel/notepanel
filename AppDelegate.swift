import AppKit
import SwiftData

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    private var panelController: PanelController?
    private var hotKeyController: HotKeyController?
    private var persistenceErrorObserver: NSObjectProtocol?
    private var hotKeyObserver: NSObjectProtocol?
    private var hasShownSaveErrorAlert = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        let container = AppModel.container
        observePersistenceErrors()
        if AppModel.isInMemoryFallback {
            showPersistenceAlert(
                message: "Notes can't be saved",
                detail: "NotePanel couldn't open its notes database. You can keep using the app, "
                    + "but changes made in this session will be lost when it quits."
            )
        }

        let panelController = PanelController(modelContainer: container)
        self.panelController = panelController
        menuBarController = MenuBarController(panelController: panelController)

        hotKeyController = HotKeyController()
        applyToggleHotKey()
        hotKeyObserver = NotificationCenter.default.addObserver(
            forName: .hotKeyChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.applyToggleHotKey()
        }

        LegacyStoreMigrator.migrateIfNeeded(
            into: container,
            storeDirectory: AppModel.storeDirectoryURL
        )
        seedSampleNotesIfNeeded(container: container)
        assignColorsToUncoloredNotes(container: container)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        if AppSettings.panelOpen {
            panelController.showPanel(animated: false)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotKeyController?.unregister()
    }

    @objc private func screenParametersChanged() {
        panelController?.repositionForScreenChange()
    }

    private func applyToggleHotKey() {
        let hotKey = AppSettings.toggleHotKey
        let registered = hotKeyController?.register(hotKey) { [weak self] in
            self?.panelController?.togglePanel()
            self?.menuBarController?.syncToggleMenuTitle()
        } ?? false

        if !registered {
            NotificationCenter.default.post(name: .hotKeyRegistrationFailed, object: nil)
            if hotKey != .defaultToggle {
                AppSettings.toggleHotKey = .defaultToggle
                applyToggleHotKey()
                return
            }
        }
        menuBarController?.updateToggleShortcut()
    }

    private func observePersistenceErrors() {
        persistenceErrorObserver = NotificationCenter.default.addObserver(
            forName: .persistenceErrorOccurred,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self, !self.hasShownSaveErrorAlert else { return }
            self.hasShownSaveErrorAlert = true
            self.showPersistenceAlert(
                message: "Couldn't save your notes",
                detail: "NotePanel failed to write to its notes database. Recent changes may be lost. "
                    + "Check the system log for details."
            )
        }
    }

    private func showPersistenceAlert(message: String, detail: String) {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = message
        alert.informativeText = detail
        alert.runModal()
    }

    private func seedSampleNotesIfNeeded(container: ModelContainer) {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Note>()
        guard let count = try? context.fetchCount(descriptor), count == 0 else { return }

        let samples: [(String, String)] = [
            ("Tasks", "- [ ] Call mom\n- [ ] Pay bills"),
            ("Commands", "```\nls -al\n```\nShow files in current directory"),
        ]

        for (index, sample) in samples.enumerated() {
            let note = Note(
                title: sample.0,
                content: sample.1,
                sortIndex: index,
                colorIndex: index % NotePalette.count
            )
            context.insert(note)
        }
        context.saveOrReport()
    }

    private func assignColorsToUncoloredNotes(container: ModelContainer) {
        let context = ModelContext(container)
        guard let notes = try? context.fetch(
            FetchDescriptor<Note>(sortBy: [SortDescriptor(\.sortIndex)])
        ) else { return }

        var changed = false
        for (index, note) in notes.enumerated() where note.colorIndex == nil {
            note.colorIndex = index % NotePalette.count
            changed = true
        }
        if changed {
            context.saveOrReport()
        }
    }
}
