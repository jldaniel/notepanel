import AppKit
import SwiftUI

struct PanelResizeHandle: View {
    var body: some View {
        PanelResizeHandleRepresentable()
            .frame(width: 24)
            .accessibilityLabel("Resize panel")
            .accessibilityAddTraits(.isButton)
    }
}

private struct PanelResizeHandleRepresentable: NSViewRepresentable {
    func makeNSView(context: Context) -> PanelResizeHandleView {
        PanelResizeHandleView()
    }

    func updateNSView(_ nsView: PanelResizeHandleView, context: Context) {}
}

private final class PanelResizeHandleView: NSView {
    private let minWidth: CGFloat = 280

    private var isDragging = false
    private var dragStartScreenX: CGFloat = 0
    private var dragStartFrame: NSRect = .zero

    private var maxWidth: CGFloat {
        let screenWidth = (window?.screen ?? NSScreen.main)?.frame.width ?? 1200
        return screenWidth * 0.5
    }

    override var isOpaque: Bool { false }

    override func resetCursorRects() {
        super.resetCursorRects()
        addCursorRect(bounds, cursor: .resizeLeftRight)
    }

    override func mouseDown(with event: NSEvent) {
        guard let window else { return }
        isDragging = true
        dragStartScreenX = NSEvent.mouseLocation.x
        dragStartFrame = window.frame
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        resizeWindow(to: clampedWidth())
    }

    override func mouseUp(with event: NSEvent) {
        let width = clampedWidth()
        resizeWindow(to: width)
        AppSettings.panelWidth = width
        isDragging = false
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        guard isDragging else { return }
        NSColor.labelColor.withAlphaComponent(0.08).setFill()
        bounds.fill()
    }

    private func clampedWidth() -> CGFloat {
        let proposed = dragStartFrame.width + (dragStartScreenX - NSEvent.mouseLocation.x)
        return min(max(proposed, minWidth), maxWidth)
    }

    private func resizeWindow(to width: CGFloat) {
        guard let window else { return }

        var frame = dragStartFrame
        frame.origin.x = dragStartFrame.maxX - width
        frame.size.width = width

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0
            context.allowsImplicitAnimation = false
            window.setFrame(frame, display: true, animate: false)
        }
    }
}
