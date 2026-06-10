# NotePanel — Potential Improvements

Candidate improvements (features and tech debt), roughly ordered by impact.
Items 1–4 come out of a security/robustness audit; 5–10 are product features;
11–13 come out of a UX review of the interaction code.

## 1. Move notes to an app-scoped, named data store (tech debt / security)

`AppModel` uses the default `ModelConfiguration`, so notes land in
`~/Library/Application Support/default.store` — a generic file shared by *any*
non-sandboxed SwiftData app that also uses the default configuration. Another
app could read, corrupt, or schema-collide with the notes database.
Fix: `ModelConfiguration(url:)` pointing at
`~/Library/Application Support/NotePanel/Notes.store`, with a one-time
migration that copies existing notes from the old default store.

## 2. Enable the App Sandbox (security)

`NotePanel.entitlements` is an empty dict. Hardened Runtime is on (good), but
the app runs unsandboxed despite needing no special access — it has no network
code, no file pickers, no AppleScript. Adding
`com.apple.security.app-sandbox` costs nothing functionally and contains the
blast radius of any dependency bug. (Do #1 first; sandboxing also moves the
store into the app container, which makes a clean moment for the migration.)

## 3. Developer ID signing + notarization for releases (security / distribution)

`build-release.sh` falls back to an ad-hoc signature and `make-dmg.sh` ships
that in the DMG. Users get Gatekeeper warnings, and there is no way to verify
a downloaded DMG is authentic or untampered. Sign with a Developer ID
certificate, notarize with `notarytool`, and staple the ticket. Also worth
replacing the deprecated `codesign --deep` flag while in there.

## 4. Surface persistence failures instead of swallowing them (tech debt)

Every save is `try? modelContext.save()` (NoteCardView, NotesPanelView,
NoteDropDelegate, AppDelegate), so a failing disk or corrupted store silently
loses edits. `AppModel.container` also `fatalError`s on a corrupt store,
crashing at launch with no recovery path. Centralize saving in a helper that
logs failures and alerts the user, and fall back to an in-memory store (with a
warning) rather than crashing on launch.

## 5. Undo / trash for deleted notes (feature)

Deleting a note (x button or context menu) is immediate and irreversible — one
misclick destroys content. Options: register deletions with `UndoManager`
(⌘Z), a brief "Note deleted — Undo" toast, or a soft-delete `deletedAt` field
with a Trash section that purges after N days.

## 6. Configurable global hotkey (feature)

⌘⇧P is hardcoded in `HotKeyController` (and duplicated in the menu and the
Preferences "Shortcuts" display, which is informational only). Let users
record their own shortcut in Preferences. Migrating from the legacy Carbon
hotkey API to a small wrapper (or `KeyboardShortcuts`-style recorder) would
also retire deprecated API.

## 7. Search and filter (feature)

Once you have more than a screenful of notes there's no way to find anything.
A search field in `PanelHeaderView` filtering the `@Query` by title/content,
with ⌘F focus, would keep the panel usable as the note count grows.

## 8. Export / import notes as Markdown (feature)

Notes are trapped in a SQLite store. Export-all to a folder of `.md` files
(title as filename, front-matter for color/order) and import back gives users
backup, portability, and interop with Obsidian-style tools. Pairs naturally
with #1's defined store location.

## 9. Multi-display support (feature / tech debt)

`PanelController` always positions on `NSScreen.main` (the screen with the
key window — not necessarily where the user is looking). On multi-monitor
setups the panel can appear on the wrong display. Add a preference: pin to a
chosen display, or follow the screen containing the mouse pointer.

## 10. Test suite and CI (tech debt)

There are zero tests. The logic most worth covering is pure and easy to test:
drop-reorder index math in `NoteDropDelegate`, `NotePalette.nextIndex`,
`Note.collapsed`/`resolvedColorIndex` fallbacks, and `AppSettings` defaults. A
small XCTest target plus a GitHub Actions workflow running
`xcodegen generate && xcodebuild test` would catch regressions in reordering
and migration logic, which are currently exercised only by hand.

## 11. Reliable drag-and-drop reordering (UX / bug fixes)

Reordering works in the happy path but degrades badly at the edges:

- **Stuck ghost cards.** `draggedNoteID` is set in `onDrag`
  (NoteCardView.swift:95) but only cleared in `NoteDropDelegate.performDrop`.
  Release a drag anywhere that isn't another card — the header, the empty
  space below the list, outside the panel, or Esc to cancel — and the card is
  stuck at 45 % opacity until the next successful drop.
- **The whole title bar is the drag handle**, including the collapse and
  delete buttons and the tap-to-edit title. The `≡` grip icon implies it's
  the handle, but dragging from a button or the title competes with their
  click actions and adds tap latency.
- **The drag payload is the note's UUID string** as `.plainText` — dragging a
  note into another app pastes a bare UUID.

Fix: attach `onDrag` to the grip icon only, clear the drag state when the
drag session ends (e.g. a `.onDrop` catch-all on the panel background plus
clearing in `dropExited`/on drag end), and make the payload the note's
markdown so cross-app drags do something useful.

## 12. Predictable click-to-edit model (UX / bug fixes)

Entering and leaving edit mode is the app's core interaction and currently
fights itself:

- **Clicking rendered text often doesn't enter edit mode.** The preview has
  `.textSelection(.enabled)` (MarkdownPreviewView.swift:27) *and* a tap
  gesture on the same area (NoteCardView.swift:44); the selectable text view
  swallows clicks on glyphs, so editing only triggers reliably when you click
  padding or whitespace.
- **Focus is stolen while editing the title.** `GrowingTextEditor`
  force-grabs first responder whenever `isFocused` is true
  (GrowingTextEditor.swift:40-42), and `isContentFocused` is only ever set
  `onAppear` (NoteEditorView.swift:41). Click the title field while editing
  content and the first keystroke re-renders the view, which yanks focus back
  to the content editor — titles with real names are nearly uneditable
  in-place.
- **The focus heuristic keys off the literal string "New Note"**
  (NoteCardView.swift:24), so a note actually titled "New Note" always opens
  with title focus instead of content.
- **Click-outside-to-finish only sometimes works**: it requires tapping
  another note, the Done button, Esc, or an invisible 120 pt strip below the
  list (NotesPanelView.swift:46-53). Clicking the header, the gaps between
  cards, or a collapsed note's bar leaves edit mode open.

Fix: pick one explicit model — e.g. hover affordance + single-click to edit
with selection disabled in preview, or double-click to edit with single-click
select — wire `@FocusState` to both fields properly, and end editing on any
click outside the active card.

## 13. Make new notes and shortcuts land where the user is looking (UX)

- **⌘N creates a note off-screen.** `addNote` appends at the bottom of the
  list (NotesPanelView.swift:84) and starts editing it, but nothing scrolls
  it into view — with a full panel the new note (and the focused title field
  you're now typing into) is below the fold. Wrap the list in a
  `ScrollViewReader` and scroll to the new note, or insert new notes at the
  top.
- **The advertised ⌘N shortcut is unreliable.** Preferences lists "New note:
  ⌘N", but the key equivalent lives on the status-bar menu
  (MenuBarController.swift:54-58), which is not the app's main menu — menu
  key equivalents there only match while the menu is open. Register a real
  main menu (or extend the Carbon hotkey controller) so ⌘N works whenever the
  panel has focus, and consider a global new-note hotkey to pair with ⌘⇧P.
- While in there: the panel's show/hide animation has a race —
  `hidePanel`'s 0.18 s completion handler calls `orderOut` unconditionally
  (PanelController.swift:161), so toggling quickly can hide a panel that was
  just re-shown.
