import AppKit
import SwiftUI

struct GrowingTextEditor: NSViewRepresentable {
    @Binding var text: String
    var isFocused: Bool
    var minHeight: CGFloat = 100

    func makeNSView(context: Context) -> TextEditorContainer {
        let textView = NSTextView()
        textView.delegate = context.coordinator
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.drawsBackground = false
        textView.font = .monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        textView.textColor = .textColor
        textView.textContainerInset = NSSize(width: 4, height: 8)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.heightTracksTextView = false
        textView.textContainer?.containerSize = NSSize(
            width: 0,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.string = text
        return TextEditorContainer(textView: textView)
    }

    func updateNSView(_ container: TextEditorContainer, context: Context) {
        let textView = container.textView

        if textView.string != text {
            textView.string = text
        }

        if isFocused, textView.window?.firstResponder != textView {
            textView.window?.makeFirstResponder(textView)
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, nsView: TextEditorContainer, context: Context) -> CGSize? {
        guard let width = proposal.width, width.isFinite, width > 0 else { return nil }

        let textView = nsView.textView
        let inset = textView.textContainerInset
        let containerWidth = width - inset.width * 2
        textView.textContainer?.containerSize = NSSize(
            width: containerWidth,
            height: CGFloat.greatestFiniteMagnitude
        )

        guard let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer else {
            return CGSize(width: width, height: minHeight)
        }

        layoutManager.ensureLayout(for: textContainer)
        let usedHeight = layoutManager.usedRect(for: textContainer).height
        let height = max(minHeight, usedHeight + inset.height * 2)
        return CGSize(width: width, height: height)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    final class TextEditorContainer: NSView {
        let textView: NSTextView
        private let scrollView: NSScrollView

        init(textView: NSTextView) {
            self.textView = textView
            self.scrollView = NSScrollView()
            super.init(frame: .zero)

            scrollView.documentView = textView
            scrollView.hasVerticalScroller = true
            scrollView.autohidesScrollers = true
            scrollView.drawsBackground = false
            scrollView.borderType = .noBorder
            addSubview(scrollView)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override var isFlipped: Bool { true }

        override func layout() {
            super.layout()
            scrollView.frame = bounds
        }

        override func mouseDown(with event: NSEvent) {
            window?.makeFirstResponder(textView)
            textView.mouseDown(with: event)
        }

        override func hitTest(_ point: NSPoint) -> NSView? {
            let localPoint = convert(point, from: superview)
            guard bounds.contains(localPoint) else { return nil }
            return super.hitTest(point) ?? self
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var text: Binding<String>

        init(text: Binding<String>) {
            self.text = text
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            text.wrappedValue = textView.string
        }
    }
}
