import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct NoteDropDelegate: DropDelegate {
    let targetNote: Note
    let getNotes: () -> [Note]
    let interaction: PanelInteractionModel
    let modelContext: ModelContext

    func validateDrop(info: DropInfo) -> Bool {
        interaction.draggedNoteID != nil
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func dropEntered(info: DropInfo) {
        guard let draggedID = interaction.draggedNoteID,
              draggedID != targetNote.id else { return }

        let notes = getNotes()
        guard let fromIndex = notes.firstIndex(where: { $0.id == draggedID }),
              let toIndex = notes.firstIndex(where: { $0.id == targetNote.id }) else { return }

        var ordered = notes
        let item = ordered.remove(at: fromIndex)
        ordered.insert(item, at: toIndex)

        // Live reorder is visual; the single save happens at drag end.
        for (index, note) in ordered.enumerated() where note.sortIndex != index {
            note.sortIndex = index
            note.touch()
        }
    }

    func performDrop(info: DropInfo) -> Bool {
        interaction.draggedNoteID = nil
        modelContext.saveOrReport()
        return true
    }

    func dropExited(info: DropInfo) {}
}

/// Catches drops that land outside any note card (header, gaps, below the list)
/// so a cancelled or stray drop can never leave a card stuck in its dragging look.
struct PanelCatchAllDropDelegate: DropDelegate {
    let interaction: PanelInteractionModel
    let modelContext: ModelContext

    func validateDrop(info: DropInfo) -> Bool {
        interaction.draggedNoteID != nil
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        guard interaction.draggedNoteID != nil else { return false }
        interaction.draggedNoteID = nil
        modelContext.saveOrReport()
        return true
    }
}
