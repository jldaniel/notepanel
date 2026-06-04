import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct NoteDropDelegate: DropDelegate {
    let targetNote: Note
    let getNotes: () -> [Note]
    @Binding var draggedNoteID: UUID?
    let modelContext: ModelContext

    func validateDrop(info: DropInfo) -> Bool {
        draggedNoteID != nil
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func dropEntered(info: DropInfo) {
        guard let draggedID = draggedNoteID,
              draggedID != targetNote.id else { return }

        let notes = getNotes()
        guard let fromIndex = notes.firstIndex(where: { $0.id == draggedID }),
              let toIndex = notes.firstIndex(where: { $0.id == targetNote.id }) else { return }

        var ordered = notes
        let item = ordered.remove(at: fromIndex)
        ordered.insert(item, at: toIndex)

        for (index, note) in ordered.enumerated() where note.sortIndex != index {
            note.sortIndex = index
            note.touch()
        }
        try? modelContext.save()
    }

    func performDrop(info: DropInfo) -> Bool {
        draggedNoteID = nil
        return true
    }

    func dropExited(info: DropInfo) {}
}
