import SwiftData
import SwiftUI

struct NoteEditorView: View {
    @Bindable var note: Note
    var onDone: () -> Void
    var autoFocusContent = true

    @FocusState private var isContentFocused: Bool

    private static let editorMinHeight: CGFloat = 100
    private static let editorMaxHeight: CGFloat = 400

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GrowingTextEditor(
                text: $note.content,
                isFocused: isContentFocused,
                minHeight: Self.editorMinHeight,
                maxHeight: Self.editorMaxHeight
            )
            .frame(
                maxWidth: .infinity,
                minHeight: Self.editorMinHeight,
                maxHeight: Self.editorMaxHeight,
                alignment: .topLeading
            )

            HStack {
                Spacer()
                Button("Done") {
                    note.touch()
                    onDone()
                }
                .keyboardShortcut(.return, modifiers: .command)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onAppear {
            isContentFocused = autoFocusContent
        }
        .onExitCommand {
            note.touch()
            onDone()
        }
    }
}
