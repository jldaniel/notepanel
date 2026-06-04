import Foundation
import SwiftData

@Model
final class Note {
    var id: UUID
    var title: String
    var content: String
    var sortIndex: Int
    var colorIndex: Int?
    /// `nil` means expanded for notes created before this field existed.
    var isCollapsed: Bool?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String = "",
        content: String = "",
        sortIndex: Int = 0,
        colorIndex: Int? = nil,
        isCollapsed: Bool? = false,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.sortIndex = sortIndex
        self.colorIndex = colorIndex
        self.isCollapsed = isCollapsed
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    func touch() {
        updatedAt = .now
    }

    var resolvedColorIndex: Int {
        colorIndex ?? 0
    }

    var collapsed: Bool {
        get { isCollapsed ?? false }
        set { isCollapsed = newValue }
    }
}
