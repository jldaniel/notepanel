import AppKit
import SwiftData
import SwiftUI

final class PanelController {
    private var panel: KeyablePanel?
    private var hostingController: NSHostingController<AnyView>?
    private let modelContainer: ModelContainer
    private let interactionModel = PanelInteractionModel()
    private(set) var isVisible = false
    private var preferencesObserver: NSObjectProtocol?
    private var widthObserver: NSObjectProtocol?
    private var resetWidthObserver: NSObjectProtocol?
    private var closeObserver: NSObjectProtocol?

    private var panelWidth: CGFloat { AppSettings.panelWidth }
    private var topInset: CGFloat { AppSettings.topInset }

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        setupPanel()
        preferencesObserver = NotificationCenter.default.addObserver(
            forName: .panelPreferencesChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.applyPanelWidth()
        }

        widthObserver = NotificationCenter.default.addObserver(
            forName: .panelWidthChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.applyPanelWidth()
        }

        resetWidthObserver = NotificationCenter.default.addObserver(
            forName: .resetPanelWidth,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            AppSettings.panelWidth = AppSettings.defaultPanelWidth
            self?.applyPanelWidth()
        }

        closeObserver = NotificationCenter.default.addObserver(
            forName: .closePanel,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.hidePanel()
        }
    }

    deinit {
        for observer in [preferencesObserver, widthObserver, resetWidthObserver, closeObserver] {
            if let observer {
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }

    private func setupPanel() {
        let panel = KeyablePanel(
            contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: 600),
            styleMask: [.fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )

        panel.level = .floating
        panel.isFloatingPanel = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isMovable = false
        panel.isMovableByWindowBackground = false
        panel.acceptsMouseMovedEvents = true

        let rootView = AnyView(
            NotesPanelView()
                .modelContainer(modelContainer)
                .environment(interactionModel)
        )
        let hosting = NSHostingController(rootView: rootView)
        hosting.view.wantsLayer = true
        panel.contentViewController = hosting

        self.panel = panel
        self.hostingController = hosting
    }

    private func panelFrame(on screen: NSScreen) -> NSRect {
        let visibleFrame = screen.visibleFrame
        let height = visibleFrame.height - topInset
        return NSRect(
            x: visibleFrame.maxX - panelWidth,
            y: visibleFrame.origin.y,
            width: panelWidth,
            height: height
        )
    }

    private func offScreenFrame(on screen: NSScreen, visible: Bool) -> NSRect {
        let visibleFrame = screen.visibleFrame
        let height = visibleFrame.height - topInset
        let x = visible ? visibleFrame.maxX - panelWidth : visibleFrame.maxX
        return NSRect(x: x, y: visibleFrame.origin.y, width: panelWidth, height: height)
    }

    func togglePanel(animated: Bool = true) {
        if isVisible {
            hidePanel(animated: animated)
        } else {
            showPanel(animated: animated)
        }
    }

    func showPanel(animated: Bool = true) {
        guard let panel, let screen = NSScreen.main else { return }

        let targetFrame = panelFrame(on: screen)
        let startFrame = offScreenFrame(on: screen, visible: false)

        if animated {
            panel.setFrame(startFrame, display: true)
            panel.orderFrontRegardless()
            NSApp.activate(ignoringOtherApps: true)
            panel.makeKeyAndOrderFront(nil)

            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.22
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                panel.animator().setFrame(targetFrame, display: true)
            }
        } else {
            panel.setFrame(targetFrame, display: true)
            panel.orderFrontRegardless()
            NSApp.activate(ignoringOtherApps: true)
            panel.makeKeyAndOrderFront(nil)
        }

        isVisible = true
        AppSettings.panelOpen = true
        NotificationCenter.default.post(name: .panelVisibilityChanged, object: nil)
    }

    func hidePanel(animated: Bool = true) {
        guard let panel, let screen = NSScreen.main else { return }

        MainActor.assumeIsolated {
            interactionModel.endEditing(in: modelContainer.mainContext)
        }

        let endFrame = offScreenFrame(on: screen, visible: false)

        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.18
                context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                panel.animator().setFrame(endFrame, display: true)
            } completionHandler: {
                panel.orderOut(nil)
            }
        } else {
            panel.orderOut(nil)
        }

        isVisible = false
        AppSettings.panelOpen = false
        NotificationCenter.default.post(name: .panelVisibilityChanged, object: nil)
    }

    func repositionForScreenChange() {
        guard isVisible, let panel, let screen = NSScreen.main else { return }
        panel.setFrame(panelFrame(on: screen), display: true)
    }

    private func applyPanelWidth() {
        guard isVisible, let panel, let screen = NSScreen.main else { return }
        panel.setFrame(panelFrame(on: screen), display: true)
    }
}
