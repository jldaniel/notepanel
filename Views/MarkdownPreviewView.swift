import MarkdownUI
import SwiftUI

struct MarkdownPreviewView: View {
    let markdown: String

    var body: some View {
        Group {
            if MarkdownPreviewView.canRender(markdown) {
                Markdown(markdown)
                    .markdownImageProvider(NoNetworkImageProvider())
                    .markdownInlineImageProvider(NoNetworkInlineImageProvider())
                    .markdownTextStyle(\.text) {
                        FontSize(.em(0.95))
                    }
                    .markdownBlockStyle(\.listItem) { configuration in
                        configuration.label
                            .markdownMargin(top: .em(0.15), bottom: .em(0.15))
                    }
            } else {
                Text(markdown)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private static func canRender(_ markdown: String) -> Bool {
        (try? AttributedString(
            markdown: markdown,
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .full
            )
        )) != nil
    }
}

/// Block images are not fetched from the network; notes stay local-only.
private struct NoNetworkImageProvider: ImageProvider {
    func makeImage(url: URL?) -> some View {
        EmptyView()
    }
}

/// Inline images show a placeholder instead of loading remote URLs.
private struct NoNetworkInlineImageProvider: InlineImageProvider {
    func image(with url: URL, label: String) async throws -> Image {
        Image(systemName: "photo")
    }
}
