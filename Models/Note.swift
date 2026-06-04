import Foundation
import SwiftData

@Model
final class Note {
    var id: UUID
    var title: String
    var content: String
    var sortIndex: Int
    var colorIndex: Int?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String = "",
        content: String = "",
        sortIndex: Int = 0,
        colorIndex: Int? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.sortIndex = sortIndex
        self.colorIndex = colorIndex
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    func touch() {
        updatedAt = .now
    }

    var resolvedColorIndex: Int {
        colorIndex ?? 0
    }
}
