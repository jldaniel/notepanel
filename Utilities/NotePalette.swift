import SwiftUI

enum NotePalette {
    static let count = 10

    struct NoteColor {
        let background: Color
        let header: Color
        let border: Color
    }

    static func color(at index: Int) -> NoteColor {
        palette[index % count]
    }

    static func nextIndex(after notes: [Note]) -> Int {
        let lastUsed = notes.map(\.resolvedColorIndex).max() ?? -1
        return (lastUsed + 1) % count
    }

    private static let palette: [NoteColor] = [
        NoteColor(
            background: Color(red: 0.30, green: 0.26, blue: 0.17),
            header: Color(red: 0.36, green: 0.31, blue: 0.20),
            border: Color(red: 0.72, green: 0.58, blue: 0.30).opacity(0.28)
        ),
        NoteColor(
            background: Color(red: 0.18, green: 0.28, blue: 0.22),
            header: Color(red: 0.22, green: 0.34, blue: 0.27),
            border: Color(red: 0.45, green: 0.72, blue: 0.52).opacity(0.28)
        ),
        NoteColor(
            background: Color(red: 0.17, green: 0.24, blue: 0.32),
            header: Color(red: 0.21, green: 0.29, blue: 0.39),
            border: Color(red: 0.42, green: 0.62, blue: 0.86).opacity(0.28)
        ),
        NoteColor(
            background: Color(red: 0.28, green: 0.20, blue: 0.30),
            header: Color(red: 0.34, green: 0.24, blue: 0.36),
            border: Color(red: 0.72, green: 0.48, blue: 0.78).opacity(0.28)
        ),
        NoteColor(
            background: Color(red: 0.32, green: 0.20, blue: 0.18),
            header: Color(red: 0.39, green: 0.24, blue: 0.21),
            border: Color(red: 0.86, green: 0.48, blue: 0.38).opacity(0.28)
        ),
        NoteColor(
            background: Color(red: 0.15, green: 0.26, blue: 0.28),
            header: Color(red: 0.19, green: 0.32, blue: 0.34),
            border: Color(red: 0.38, green: 0.72, blue: 0.76).opacity(0.28)
        ),
        NoteColor(
            background: Color(red: 0.30, green: 0.19, blue: 0.22),
            header: Color(red: 0.36, green: 0.23, blue: 0.27),
            border: Color(red: 0.82, green: 0.46, blue: 0.54).opacity(0.28)
        ),
        NoteColor(
            background: Color(red: 0.22, green: 0.22, blue: 0.30),
            header: Color(red: 0.27, green: 0.27, blue: 0.36),
            border: Color(red: 0.56, green: 0.56, blue: 0.82).opacity(0.28)
        ),
        NoteColor(
            background: Color(red: 0.24, green: 0.27, blue: 0.18),
            header: Color(red: 0.29, green: 0.33, blue: 0.22),
            border: Color(red: 0.62, green: 0.72, blue: 0.40).opacity(0.28)
        ),
        NoteColor(
            background: Color(red: 0.26, green: 0.21, blue: 0.15),
            header: Color(red: 0.32, green: 0.26, blue: 0.18),
            border: Color(red: 0.78, green: 0.56, blue: 0.32).opacity(0.28)
        ),
    ]
}
