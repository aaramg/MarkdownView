//
//  TextColorModifier.swift
//  MarkdownView
//

import SwiftUI

extension SwiftUI.View {
    /// Sets the color of markdown text in both `MarkdownView` and `MarkdownText`.
    ///
    /// Inline code and links keep their tint colors. Use it to color `MarkdownText`, which doesn't follow `foregroundStyle(_:)`.
    ///
    /// - parameter color: The text color, or `nil` for the platform's label color. The default value is `nil`.
    nonisolated public func markdownTextColor(_ color: Color?) -> some View {
        transformEnvironment(\.markdownRendererConfiguration) { configuration in
            configuration.textColor = color
        }
    }
}

extension SwiftUI.View {
    @ViewBuilder
    func applyingMarkdownTextColor(_ color: Color?) -> some View {
        if let color {
            foregroundStyle(color)
        } else {
            self
        }
    }
}
