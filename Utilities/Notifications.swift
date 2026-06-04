import Foundation

extension Notification.Name {
    static let createNewNote = Notification.Name("NotePanel.createNewNote")
    static let panelPreferencesChanged = Notification.Name("NotePanel.panelPreferencesChanged")
    static let panelWidthChanged = Notification.Name("NotePanel.panelWidthChanged")
    static let resetPanelWidth = Notification.Name("NotePanel.resetPanelWidth")
    static let closePanel = Notification.Name("NotePanel.closePanel")
    static let panelVisibilityChanged = Notification.Name("NotePanel.panelVisibilityChanged")
}
