//
//  MarkdownRendererConfigurationTests.swift
//  MarkdownView
//
//  Created by Codex on 2026/6/29.
//

import Foundation
import Testing

@testable import MarkdownView

@Suite("Markdown Renderer Configuration")
struct MarkdownRendererConfigurationTests {
    @Test(
        "Resolves relative markdown destinations against the preferred base URL",
        .tags(.configuration, .links, .rendering)
    )
    func resolvesRelativeMarkdownDestinationsAgainstPreferredBaseURL() throws {
        let baseURL = URL(string: "https://example.com/articles/")!
        let configuration = MarkdownRendererConfiguration()
            .with(\.preferredBaseURL, baseURL)

        let url = try #require(
            configuration.resolvedMarkdownURL(for: "guide")
        )

        #expect(url.absoluteString == "https://example.com/articles/guide")
    }

    @Test(
        "Leaves KaTeX compatibility and the text color off unless asked",
        .tags(.configuration, .math, .textColor)
    )
    func leavesKaTeXCompatibilityAndTheTextColorOffUnlessAsked() {
        let configuration = MarkdownRendererConfiguration()

        #expect(!configuration.mathKaTeXCompatibility)
        #expect(configuration.textColor == nil)
    }
}
