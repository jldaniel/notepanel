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

    private var noteColor: NotePalette.NoteColor {
        NotePalette.color(at: note.resolvedColorIndex)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isEditing {
                NoteEditorView(note: note, onDone: onEndEditing)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            } else {
                collapsedCard
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
    }

    private var collapsedCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            titleBar
            contentBody
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onBeginEditing)
    }

    private var titleBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "line.3.horizontal")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(note.title.isEmpty ? "Untitled" : note.title)
                .font(.headline)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: deleteNote) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .opacity(0.6)
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

    private func deleteNote() {
        modelContext.delete(note)
        try? modelContext.save()
    }
}
