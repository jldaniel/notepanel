import Foundation
import Observation
import SwiftData

/// Shared interaction state for the notes panel: which note is being edited,
/// which is being dragged, and which newly created note should focus its title.
@Observable
final class PanelInteractionModel {
    private(set) var editingNote: Note?
    var draggedNoteID: UUID?
    var pendingTitleFocusID: UUID?

    var editingNoteID: UUID? {
        editingNote?.id
    }

    func beginEditing(_ note: Note, in context: ModelContext) {
        guard editingNote !== note else { return }
        endEditing(in: context)
        editingNote = note
    }

    func endEditing(in context: ModelContext) {
        guard let note = editingNote else { return }
        if context.hasChanges {
            note.touch()
            context.saveOrReport()
        }
        editingNote = nil
        pendingTitleFocusID = nil
    }

    /// Discards editing state without saving — for notes that are being deleted.
    func cancelEditing(of note: Note) {
        if editingNote === note {
            editingNote = nil
            pendingTitleFocusID = nil
        }
    }

    func clearDrag(noteID: UUID) {
        if draggedNoteID == noteID {
            draggedNoteID = nil
        }
    }
}
