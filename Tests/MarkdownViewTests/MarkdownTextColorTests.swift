//
//  MarkdownTextColorTests.swift
//  MarkdownView
//

#if canImport(RichText)

import Foundation
import Markdown
import RichText
import SwiftUI
import Testing

@testable import MarkdownView

@Suite("Markdown Text Color")
struct MarkdownTextColorTests {
    private static let textColor = Color(red: 0.29, green: 0.24, blue: 0.18)

    @Test(
        "Leaves text to the platform's label color by default",
        .tags(.textColor, .configuration)
    )
    @MainActor
    func leavesTextToTheLabelColorByDefault() {
        let textContent = MarkdownViewTestSupport.makeTextContent(markdown: "Plain words")
        let attributedString = MarkdownViewTestSupport.attributedString(in: textContent)

        #expect(MarkdownRendererConfiguration().textColor == nil)
        #expect(MarkdownViewTestSupport.foregroundColor(in: attributedString, matching: "Plain") == nil)
    }

    @Test(
        "Colors paragraphs, headings and emphasis with the text color",
        .tags(.textColor, .textConversion)
    )
    @MainActor
    func colorsParagraphsHeadingsAndEmphasis() {
        let configuration = MarkdownRendererConfiguration().with(\.textColor, Self.textColor)
        let textContent = MarkdownViewTestSupport.makeTextContent(
            markdown: "## Heading\n\nPlain and *emphasized* words",
            configuration: configuration
        )
        let attributedString = MarkdownViewTestSupport.attributedString(in: textContent)

        for words in ["Heading", "Plain", "emphasized"] {
            #expect(
                MarkdownViewTestSupport.foregroundColor(in: attributedString, matching: words)
                    == Self.textColor,
                "\(words) isn't in the text color"
            )
        }
    }

    @Test(
        "Keeps the tints of inline code and links, in paragraphs and list items",
        .tags(.textColor, .textConversion, .links, .lists)
    )
    @MainActor
    func keepsTheTintsOfInlineCodeAndLinks() {
        let codeTint = Color.orange
        let linkTint = Color.purple
        var configuration = MarkdownRendererConfiguration().with(\.textColor, Self.textColor)
        configuration.tintColors[.inlineCodeBlock] = codeTint
        configuration.tintColors[.link] = linkTint
        let textContent = MarkdownViewTestSupport.makeTextContent(
            markdown: """
            Run `make` or [read on](https://example.com).

            - Item with `code` and a [link](https://example.com)
            """,
            configuration: configuration
        )
        let attributedString = MarkdownViewTestSupport.attributedString(in: textContent)

        #expect(MarkdownViewTestSupport.foregroundColor(in: attributedString, matching: "make") == codeTint)
        #expect(MarkdownViewTestSupport.foregroundColor(in: attributedString, matching: "read on") == linkTint)
        #expect(MarkdownViewTestSupport.foregroundColor(in: attributedString, matching: "code") == codeTint)
        #expect(MarkdownViewTestSupport.foregroundColor(in: attributedString, matching: "link") == linkTint)
        #expect(MarkdownViewTestSupport.foregroundColor(in: attributedString, matching: "Item") == Self.textColor)
    }

    @Test(
        "Colors list markers with the text color",
        .tags(.textColor, .lists)
    )
    @MainActor
    func colorsListMarkers() {
        let configuration = MarkdownRendererConfiguration().with(\.textColor, Self.textColor)
        let textContent = MarkdownViewTestSupport.makeTextContent(
            markdown: "- First\n- Second",
            configuration: configuration
        )
        let attributedString = MarkdownViewTestSupport.attributedString(in: textContent)
        let marker = configuration.listConfiguration.unorderedListMarker.marker(listDepth: 0)

        #expect(MarkdownViewTestSupport.foregroundColor(in: attributedString, matching: marker) == Self.textColor)
    }

    #if ENABLE_MATH_RENDERING
    @Test(
        "Gives text between formulas the body font and text color",
        .tags(.textColor, .textConversion, .math, .regression)
    )
    @MainActor
    func givesTextBetweenFormulasTheBodyFontAndTextColor() {
        let bodyFont = PlatformFont.systemFont(ofSize: 15)
        let preprocessingResult = MarkdownMathPreprocessor()
            .preprocessingResult(for: #"Only $\frac{1}{N}$ of the keys move."#)
        let textContent = MarkdownViewTestSupport.makeTextContent(
            markdown: preprocessingResult.markdown,
            configuration: MarkdownRendererConfiguration().with(\.textColor, Self.textColor),
            mathContext: preprocessingResult.context,
            fonts: AnyMarkdownFontGroup(MarkdownViewTestSupport.FontGroupStub(bodyFont: bodyFont))
        )
        let attributedString = MarkdownViewTestSupport.attributedString(in: textContent)

        for words in ["Only", "of the keys move."] {
            #expect(
                MarkdownViewTestSupport.font(in: NSAttributedString(attributedString), matching: words)
                    == bodyFont,
                "\(words) isn't in the body font"
            )
            #expect(
                MarkdownViewTestSupport.foregroundColor(in: attributedString, matching: words)
                    == Self.textColor,
                "\(words) isn't in the text color"
            )
        }
    }

    @Test(
        "Copies a display formula as its source",
        .tags(.textConversion, .math)
    )
    @MainActor
    func copiesADisplayFormulaAsItsSource() throws {
        let preprocessingResult = MarkdownMathPreprocessor()
            .preprocessingResult(for: "The share is\n\n$$\n\\frac{K}{N}\n$$")
        let identifier = try #require(preprocessingResult.context.displayMathStorage.keys.first)
        let converter = MarkdownTextConverter(
            configuration: MarkdownRendererConfiguration(),
            mathContext: preprocessingResult.context,
            elementRenderers: [],
            fonts: AnyMarkdownFontGroup(.automatic)
        )

        #expect(
            converter.displayMathReplacement(for: identifier).map { String($0.characters) }
                == "$$\n\\frac{K}{N}\n$$"
        )
    }
    #endif
}

#endif
