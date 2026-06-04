import AppKit

final class MenuBarController: NSObject {
    private let statusItem: NSStatusItem
    private let panelController: PanelController
    private var menu: NSMenu?
    private var visibilityObserver: NSObjectProtocol?

    init(panelController: PanelController) {
        self.panelController = panelController
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()
        buildMenu()
        configureStatusItem()
        visibilityObserver = NotificationCenter.default.addObserver(
            forName: .panelVisibilityChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.syncToggleMenuTitle()
        }
    }

    deinit {
        if let visibilityObserver {
            NotificationCenter.default.removeObserver(visibilityObserver)
        }
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }
        button.image = NSImage(
            systemSymbolName: "note.text",
            accessibilityDescription: "NotePanel"
        )
        button.image?.isTemplate = true
        button.action = #selector(statusItemClicked)
        button.target = self
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    private func buildMenu() {
        let menu = NSMenu()

        let toggleItem = NSMenuItem(
            title: "Show Panel",
            action: #selector(togglePanel),
            keyEquivalent: "p"
        )
        toggleItem.keyEquivalentModifierMask = [.command, .shift]
        toggleItem.target = self
        menu.addItem(toggleItem)

        let newNoteItem = NSMenuItem(
            title: "New Note",
            action: #selector(createNote),
            keyEquivalent: "n"
        )
        newNoteItem.target = self
        menu.addItem(newNoteItem)

        menu.addItem(.separator())

        let preferencesItem = NSMenuItem(
            title: "Preferences…",
            action: #selector(openPreferences),
            keyEquivalent: ","
        )
        preferencesItem.target = self
        menu.addItem(preferencesItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit NotePanel",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        self.menu = menu
    }

    @objc private func statusItemClicked() {
        guard let event = NSApp.currentEvent, let button = statusItem.button else { return }

        if event.type == .rightMouseUp {
            menu?.popUp(
                positioning: nil,
                at: NSPoint(x: 0, y: button.bounds.height + 4),
                in: button
            )
            return
        }

        panelController.togglePanel()
        syncToggleMenuTitle()
    }

    @objc private func togglePanel() {
        panelController.togglePanel()
        syncToggleMenuTitle()
    }

    @objc private func createNote() {
        if !panelController.isVisible {
            panelController.showPanel()
            syncToggleMenuTitle()
        }
        NotificationCenter.default.post(name: .createNewNote, object: nil)
    }

    @objc private func openPreferences() {
        PreferencesWindowController.shared.show()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    func syncToggleMenuTitle() {
        guard let menu,
              let toggleItem = menu.item(at: 0) else { return }
        toggleItem.title = panelController.isVisible ? "Hide Panel" : "Show Panel"
    }
}
