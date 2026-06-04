import SwiftData
import SwiftUI

struct NoteEditorView: View {
    @Bindable var note: Note
    var onDone: () -> Void

    @FocusState private var focusedField: Field?

    private enum Field {
        case title
        case content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Title", text: $note.title)
                .textFieldStyle(.plain)
                .font(.headline)
                .focused($focusedField, equals: .title)

            GrowingTextEditor(
                text: $note.content,
                isFocused: focusedField == .content,
                minHeight: 100
            )
            .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)

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
            focusedField = note.title.isEmpty ? .title : .content
        }
        .onExitCommand {
            note.touch()
            onDone()
        }
    }
}
