import SwiftData
import SwiftUI

struct NotesPanelView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Note.sortIndex) private var notes: [Note]
    @State private var editingNoteID: UUID?
    @State private var draggedNoteID: UUID?

    var body: some View {
        HStack(spacing: 0) {
            PanelResizeHandle()

            VStack(spacing: 0) {
                PanelHeaderView(
                    onAdd: addNote,
                    onResetWidth: resetPanelWidth,
                    onClose: closePanel
                )

                if notes.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        ZStack(alignment: .top) {
                            Color.clear
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    endEditing()
                                }
                                .allowsHitTesting(editingNoteID != nil)

                            LazyVStack(spacing: 12) {
                                ForEach(notes, id: \.id) { note in
                                    NoteCardView(
                                        note: note,
                                        isEditing: editingNoteID == note.id,
                                        isDragging: draggedNoteID == note.id,
                                        onBeginEditing: { beginEditing(note) },
                                        onEndEditing: endEditing,
                                        onDragStart: { draggedNoteID = note.id }
                                    )
                                    .onDrop(
                                        of: [.plainText],
                                        delegate: NoteDropDelegate(
                                            targetNote: note,
                                            getNotes: { notes },
                                            draggedNoteID: $draggedNoteID,
                                            modelContext: modelContext
                                        )
                                    )
                                }
                            }
                            .padding(.top, 16)
                            .padding(.trailing, 16)
                            .padding(.bottom, 16)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
        .onReceive(NotificationCenter.default.publisher(for: .createNewNote)) { _ in
            addNote()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "note.text")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No notes yet")
                .font(.headline)
            Text("Click + to add a note")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func addNote() {
        let nextIndex = (notes.map(\.sortIndex).max() ?? -1) + 1
        let note = Note(
            title: "New Note",
            content: "",
            sortIndex: nextIndex,
            colorIndex: NotePalette.nextIndex(after: notes)
        )
        modelContext.insert(note)
        try? modelContext.save()
        beginEditing(note)
    }

    private func beginEditing(_ note: Note) {
        endEditing()
        editingNoteID = note.id
    }

    private func endEditing() {
        guard editingNoteID != nil else { return }
        try? modelContext.save()
        editingNoteID = nil
    }

    private func resetPanelWidth() {
        NotificationCenter.default.post(name: .resetPanelWidth, object: nil)
    }

    private func closePanel() {
        NotificationCenter.default.post(name: .closePanel, object: nil)
    }
}
