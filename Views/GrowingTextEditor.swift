import AppKit
import SwiftUI

struct GrowingTextEditor: NSViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool
    var minHeight: CGFloat = 100
    var maxHeight: CGFloat = 400
    var onEscape: (() -> Void)?

    func makeNSView(context: Context) -> TextEditorContainer {
        let textView = FocusReportingTextView()
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

        let coordinator = context.coordinator
        textView.onFocusChange = { coordinator.focusDidChange($0) }

        return TextEditorContainer(textView: textView)
    }

    func updateNSView(_ container: TextEditorContainer, context: Context) {
        let coordinator = context.coordinator
        coordinator.text = $text
        coordinator.isFocused = $isFocused
        coordinator.onEscape = onEscape

        let textView = container.textView
        if textView.string != text {
            textView.string = text
        }

        // Edge-triggered only: the binding tracks the real first-responder state via
        // the coordinator, so a focus the user moved elsewhere is never re-grabbed.
        if isFocused, !coordinator.actualFocus {
            textView.window?.makeFirstResponder(textView)
        } else if !isFocused, coordinator.actualFocus {
            textView.window?.makeFirstResponder(nil)
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, nsView: TextEditorContainer, context: Context) -> CGSize? {
        guard let width = proposal.width, width.isFinite, width > 0 else { return nil }

        let cap = effectiveMaxHeight(proposal: proposal)
        let textView = nsView.textView
        let inset = textView.textContainerInset
        let containerWidth = width - inset.width * 2
        textView.textContainer?.containerSize = NSSize(
            width: containerWidth,
            height: cap
        )

        guard let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer else {
            return CGSize(width: width, height: cap)
        }

        layoutManager.ensureLayout(for: textContainer)
        let usedHeight = layoutManager.usedRect(for: textContainer).height
        let contentHeight = max(minHeight, usedHeight + inset.height * 2)
        let height = min(contentHeight, cap)
        return CGSize(width: width, height: height)
    }

    private func effectiveMaxHeight(proposal: ProposedViewSize) -> CGFloat {
        var cap = max(maxHeight, minHeight)
        if let proposedHeight = proposal.height, proposedHeight.isFinite, proposedHeight > 0 {
            cap = min(cap, proposedHeight)
        }
        return max(cap, minHeight)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, isFocused: $isFocused, onEscape: onEscape)
    }

    /// NSTextView that reports first-responder changes, so SwiftUI focus state can
    /// follow reality instead of asserting a stale wish (the old focus-steal bug).
    final class FocusReportingTextView: NSTextView {
        var onFocusChange: ((Bool) -> Void)?

        override func becomeFirstResponder() -> Bool {
            let accepted = super.becomeFirstResponder()
            if accepted {
                onFocusChange?(true)
            }
            return accepted
        }

        override func resignFirstResponder() -> Bool {
            let accepted = super.resignFirstResponder()
            if accepted {
                onFocusChange?(false)
            }
            return accepted
        }
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
        var isFocused: Binding<Bool>
        var onEscape: (() -> Void)?
        private(set) var actualFocus = false

        init(text: Binding<String>, isFocused: Binding<Bool>, onEscape: (() -> Void)?) {
            self.text = text
            self.isFocused = isFocused
            self.onEscape = onEscape
        }

        func focusDidChange(_ focused: Bool) {
            actualFocus = focused
            let binding = isFocused
            DispatchQueue.main.async {
                if binding.wrappedValue != focused {
                    binding.wrappedValue = focused
                }
            }
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            text.wrappedValue = textView.string
        }

        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
                onEscape?()
                return true
            }
            return false
        }
    }
}
