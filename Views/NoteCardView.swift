import SwiftData
import SwiftUI

struct NoteCardView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var note: Note
    let isEditing: Bool
    let isDragging: Bool
    let onBeginEditing: () -> Void
    let onEndEditing: () -> Void
    let onDragStart: () -> Void

    @FocusState private var isTitleFocused: Bool

    private var noteColor: NotePalette.NoteColor {
        NotePalette.color(at: note.resolvedColorIndex)
    }

    private var displayTitle: String {
        note.title.isEmpty ? "Untitled" : note.title
    }

    private var shouldFocusTitle: Bool {
        note.title.isEmpty || note.title == "New Note"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            titleBar

            if !note.collapsed {
                if isEditing {
                    NoteEditorView(
                        note: note,
                        onDone: onEndEditing,
                        autoFocusContent: !shouldFocusTitle
                    )
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                } else {
                    contentBody
                        .contentShape(Rectangle())
                        .onTapGesture(perform: onBeginEditing)
                }
            }
        }
        .background(noteColor.background)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(noteColor.border, lineWidth: 1)
        )
        .opacity(isDragging ? 0.45 : 1)
        .contextMenu {
            Button("Delete", role: .destructive) { deleteNote() }
        }
        .onAppear(perform: focusTitleIfNeeded)
        .onChange(of: isEditing) { _, editing in
            guard editing else { return }
            focusTitleIfNeeded()
        }
    }

    private var titleBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "line.3.horizontal")
                .font(.caption)
                .foregroundStyle(.secondary)

            titleContent
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: toggleCollapse) {
                Image(systemName: note.collapsed ? "chevron.right" : "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)
            .help(note.collapsed ? "Expand note" : "Collapse note")

            Button(action: deleteNote) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .opacity(0.6)
            .help("Delete note")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(noteColor.header)
        .contentShape(Rectangle())
        .onDrag {
            onDragStart()
            return NSItemProvider(object: note.id.uuidString as NSString)
        }
    }

    @ViewBuilder
    private var titleContent: some View {
        if isEditing {
            TextField("Title", text: $note.title)
                .textFieldStyle(.plain)
                .font(.headline)
                .focused($isTitleFocused)
        } else {
            Text(displayTitle)
                .font(.headline)
                .lineLimit(1)
                .foregroundStyle(note.title.isEmpty ? .secondary : .primary)
                .contentShape(Rectangle())
                .onTapGesture(perform: onBeginEditing)
        }
    }

    @ViewBuilder
    private var contentBody: some View {
        Group {
            if note.content.isEmpty {
                Text("No content")
                    .foregroundStyle(.tertiary)
                    .italic()
            } else {
                MarkdownPreviewView(markdown: note.content)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
    }

    private func toggleCollapse() {
        if isEditing, !note.collapsed {
            onEndEditing()
        }
        note.collapsed.toggle()
        note.touch()
        try? modelContext.save()
    }

    private func focusTitleIfNeeded() {
        guard isEditing, shouldFocusTitle else { return }
        isTitleFocused = true
    }

    private func deleteNote() {
        if isEditing {
            onEndEditing()
        }
        modelContext.delete(note)
        try? modelContext.save()
    }
}
