import ObjectiveC
import SwiftData
import SwiftUI

/// Held by the drag's `NSItemProvider`; when the system releases the provider at the
/// end of the drag session (including Esc-cancel and drops outside the panel), the
/// deinit clears any leftover drag state. Backstop for the cases SwiftUI gives no
/// drag-ended callback for.
final class DragEndSentinel {
    static var associatedKey: UInt8 = 0

    private let noteID: UUID
    private let interaction: PanelInteractionModel
    private let modelContext: ModelContext

    init(noteID: UUID, interaction: PanelInteractionModel, modelContext: ModelContext) {
        self.noteID = noteID
        self.interaction = interaction
        self.modelContext = modelContext
    }

    deinit {
        let noteID = noteID
        let interaction = interaction
        let modelContext = modelContext
        DispatchQueue.main.async {
            guard interaction.draggedNoteID == noteID else { return }
            interaction.draggedNoteID = nil
            modelContext.saveOrReport()
        }
    }
}

struct NoteCardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(PanelInteractionModel.self) private var interaction
    @Bindable var note: Note

    @FocusState private var isTitleFocused: Bool
    @State private var isHovering = false
    @State private var cursorPushed = false

    private var isEditing: Bool {
        interaction.editingNoteID == note.id
    }

    private var isDragging: Bool {
        interaction.draggedNoteID == note.id
    }

    private var noteColor: NotePalette.NoteColor {
        NotePalette.color(at: note.resolvedColorIndex)
    }

    private var displayTitle: String {
        note.title.isEmpty ? "Untitled" : note.title
    }

    private var shouldFocusTitle: Bool {
        interaction.pendingTitleFocusID == note.id
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            titleBar

            if !note.collapsed {
                if isEditing {
                    NoteEditorView(
                        note: note,
                        onDone: endEditing,
                        autoFocusContent: !shouldFocusTitle
                    )
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                } else {
                    contentBody
                }
            }
        }
        .background(
            noteColor.background
                .overlay(Color.white.opacity(isHovering && !isEditing ? 0.05 : 0))
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(noteColor.border, lineWidth: 1)
        )
        .opacity(isDragging ? 0.45 : 1)
        .contentShape(Rectangle())
        .onTapGesture {
            // When already editing, this swallows the tap so it can't reach the
            // panel-level end-editing gesture.
            if !isEditing {
                beginEditing()
            }
        }
        .onHover { hovering in
            isHovering = hovering
            setPointerCursor(hovering && !isEditing)
        }
        .onExitCommand {
            if isEditing {
                endEditing()
            }
        }
        .contextMenu {
            Button("Copy Note") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(note.exportMarkdown, forType: .string)
            }
            Button("Delete", role: .destructive) { deleteNote() }
        }
        .onAppear(perform: focusTitleIfNeeded)
        .onChange(of: isEditing) { _, editing in
            if editing {
                setPointerCursor(false)
                focusTitleIfNeeded()
            }
        }
        .onDisappear {
            setPointerCursor(false)
        }
    }

    private var titleBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "line.3.horizontal")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
                .help("Drag to reorder")
                .onDrag(makeDragProvider)

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
    }

    private func makeDragProvider() -> NSItemProvider {
        interaction.draggedNoteID = note.id
        let provider = NSItemProvider(object: note.exportMarkdown as NSString)
        let sentinel = DragEndSentinel(
            noteID: note.id,
            interaction: interaction,
            modelContext: modelContext
        )
        objc_setAssociatedObject(
            provider,
            &DragEndSentinel.associatedKey,
            sentinel,
            .OBJC_ASSOCIATION_RETAIN
        )
        return provider
    }

    @ViewBuilder
    private var titleContent: some View {
        if isEditing {
            TextField("New Note", text: $note.title)
                .textFieldStyle(.plain)
                .font(.headline)
                .focused($isTitleFocused)
        } else {
            Text(displayTitle)
                .font(.headline)
                .lineLimit(1)
                .foregroundStyle(note.title.isEmpty ? .secondary : .primary)
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

    private func beginEditing() {
        interaction.beginEditing(note, in: modelContext)
    }

    private func endEditing() {
        interaction.endEditing(in: modelContext)
    }

    private func toggleCollapse() {
        if isEditing, !note.collapsed {
            endEditing()
        }
        note.collapsed.toggle()
        note.touch()
        modelContext.saveOrReport()
    }

    private func focusTitleIfNeeded() {
        guard isEditing, shouldFocusTitle else { return }
        isTitleFocused = true
        interaction.pendingTitleFocusID = nil
    }

    private func setPointerCursor(_ active: Bool) {
        guard active != cursorPushed else { return }
        cursorPushed = active
        if active {
            NSCursor.pointingHand.push()
        } else {
            NSCursor.pop()
        }
    }

    private func deleteNote() {
        interaction.cancelEditing(of: note)
        modelContext.delete(note)
        modelContext.saveOrReport()
    }
}
