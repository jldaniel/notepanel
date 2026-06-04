import SwiftUI

struct PanelHeaderView: View {
    var onAdd: () -> Void
    var onResetWidth: () -> Void
    var onClose: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Text("Note Panel")
                .font(.headline)

            Spacer()

            Button(action: onResetWidth) {
                Image(systemName: "arrow.left.and.line.vertical.and.arrow.right")
                    .font(.body)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Reset panel to default width")

            Button(action: onClose) {
                Image(systemName: "sidebar.left")
                    .font(.body)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Close panel")

            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .help("New note")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
}
