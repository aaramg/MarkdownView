//
//  MarkdownTextMathColorTests.swift
//  MarkdownView
//

#if canImport(RichText) && ENABLE_MATH_RENDERING

import SwiftMath
import SwiftUI
import Testing

@testable import MarkdownView

@Suite("Markdown Text Math Color")
@MainActor
struct MarkdownTextMathColorTests {
    private static let textColor = Color(red: 0.8, green: 0.1, blue: 0.1)
    nonisolated private static let formulas = ["Speed is $v = d/t$ here.", "Speed is\n\n$$v = \\frac{d}{t}$$\n\nhere."]

    @Test("Colors the math of MarkdownText with the text color", .tags(.math, .rendering), arguments: formulas)
    func colorsMathWithTheTextColor(markdown: String) async throws {
        let label = try await renderedMathLabel(
            MarkdownText(markdown).markdownMathRenderingEnabled().markdownTextColor(Self.textColor)
        )
        #expect(try Self.components(of: label) == Self.components(of: Self.textColor))
    }

    @Test("Leaves the math of MarkdownText to the label color by default", .tags(.math, .rendering), arguments: formulas)
    func leavesMathToTheLabelColor(markdown: String) async throws {
        let label = try await renderedMathLabel(MarkdownText(markdown).markdownMathRenderingEnabled())
        #expect(try Self.components(of: label) != Self.components(of: Self.textColor))
    }

    @Test("Recolors the math of MarkdownText when the text color changes", .tags(.math, .rendering), arguments: formulas)
    func recolorsMathWhenTheTextColorChanges(markdown: String) async throws {
        let model = TextColorModel(color: .blue)
        let host = try await hostedMath(ColoredMarkdownText(markdown: markdown, model: model))
        defer { host.close() }

        model.color = Self.textColor
        var colors: [[Int]] = []
        for _ in 0..<100 {
            host.layout()
            colors = try host.labels().map(Self.components)
            if !colors.isEmpty, colors.allSatisfy({ $0 == (try? Self.components(of: Self.textColor)) }) { break }
            try await Task.sleep(for: .milliseconds(20))
        }

        #expect(!colors.isEmpty)
        #expect(try colors.allSatisfy { $0 == (try Self.components(of: Self.textColor)) })
    }

    private static func components(of label: MTMathUILabel) throws -> [Int] {
        try components(of: Color(try #require(label.textColor)))
    }

    /// sRGB components in hundredths, so equal colors compare equal
    private static func components(of color: Color) throws -> [Int] {
        let resolved = color.resolve(in: EnvironmentValues())
        return [resolved.red, resolved.green, resolved.blue].map { Int(($0 * 100).rounded()) }
    }

    /// A window hosting the view, with its math laid out.
    @MainActor
    private struct Host {
        let root: () -> MTView?
        let close: () -> Void

        func layout() {
            #if canImport(UIKit)
            root()?.layoutIfNeeded()
            #else
            root()?.layoutSubtreeIfNeeded()
            #endif
        }

        func labels() -> [MTMathUILabel] {
            root().map { MarkdownTextMathColorTests.mathLabels(in: $0) } ?? []
        }
    }

    private func hostedMath(_ view: some View) async throws -> Host {
        #if canImport(UIKit)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        window.rootViewController = UIHostingController(rootView: view.frame(width: 400))
        window.isHidden = false
        let host = Host(root: { window.rootViewController?.view }, close: { window.isHidden = true })
        #else
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled], backing: .buffered, defer: false
        )
        window.contentView = NSHostingView(rootView: view.frame(width: 400))
        window.orderFront(nil)
        let host = Host(root: { window.contentView }, close: { window.orderOut(nil) })
        #endif

        for _ in 0..<100 {
            host.layout()
            if !host.labels().isEmpty { return host }
            try await Task.sleep(for: .milliseconds(20))
        }
        host.close()
        Issue.record("No math label was laid out")
        throw CancellationError()
    }

    /// Waits for the view's first formula and returns its label.
    private func renderedMathLabel(_ view: some View) async throws -> MTMathUILabel {
        let host = try await hostedMath(view)
        defer { host.close() }
        return try #require(host.labels().first)
    }

    private static func mathLabels(in view: MTView) -> [MTMathUILabel] {
        (view as? MTMathUILabel).map { [$0] } ?? view.subviews.flatMap { mathLabels(in: $0) }
    }

}

@MainActor
@Observable
private final class TextColorModel {
    var color: Color

    init(color: Color) {
        self.color = color
    }
}

private struct ColoredMarkdownText: View {
    let markdown: String
    let model: TextColorModel

    var body: some View {
        MarkdownText(markdown)
            .markdownMathRenderingEnabled()
            .markdownTextColor(model.color)
    }
}

#endif
