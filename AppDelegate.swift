import AppKit
import SwiftData

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    private var panelController: PanelController?
    private var hotKeyController: HotKeyController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let container = AppModel.container

        let panelController = PanelController(modelContainer: container)
        self.panelController = panelController
        menuBarController = MenuBarController(panelController: panelController)

        hotKeyController = HotKeyController()
        hotKeyController?.registerTogglePanelHandler { [weak self] in
            self?.panelController?.togglePanel()
            self?.menuBarController?.syncToggleMenuTitle()
        }

        seedSampleNotesIfNeeded(container: container)
        migrateNoteColorsIfNeeded(container: container)

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
        try? context.save()
    }

    private func migrateNoteColorsIfNeeded(container: ModelContainer) {
        let migrationKey = "didMigrateNoteColors_v1"
        guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }

        let context = ModelContext(container)
        guard let notes = try? context.fetch(
            FetchDescriptor<Note>(sortBy: [SortDescriptor(\.sortIndex)])
        ) else { return }

        for (index, note) in notes.enumerated() {
            note.colorIndex = index % NotePalette.count
        }
        try? context.save()
        UserDefaults.standard.set(true, forKey: migrationKey)
    }
}
