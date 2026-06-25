import SwiftData
import SwiftUI

struct NotesPanelView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(PanelInteractionModel.self) private var interaction
    @Query(sort: \Note.sortIndex) private var notes: [Note]

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
                        LazyVStack(spacing: 12) {
                            ForEach(notes, id: \.id) { note in
                                NoteCardView(note: note)
                                    .onDrop(
                                        of: [.plainText],
                                        delegate: NoteDropDelegate(
                                            targetNote: note,
                                            getNotes: { notes },
                                            interaction: interaction,
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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                // Clicks anywhere outside a card (header, gaps, below the list)
                // commit and end the current edit. Card gestures win over this one.
                interaction.endEditing(in: modelContext)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
        .onDrop(
            of: [.plainText],
            delegate: PanelCatchAllDropDelegate(
                interaction: interaction,
                modelContext: modelContext
            )
        )
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
            title: "",
            content: "",
            sortIndex: nextIndex,
            colorIndex: NotePalette.nextIndex(after: notes)
        )
        modelContext.insert(note)
        modelContext.saveOrReport()
        // After beginEditing: it ends any previous edit, which clears the pending focus.
        interaction.beginEditing(note, in: modelContext)
        interaction.pendingTitleFocusID = note.id
    }

    private func resetPanelWidth() {
        NotificationCenter.default.post(name: .resetPanelWidth, object: nil)
    }

    private func closePanel() {
        NotificationCenter.default.post(name: .closePanel, object: nil)
    }
}
