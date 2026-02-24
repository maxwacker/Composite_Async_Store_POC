//
//  BodyTextModifier.swift
//  DesignSystem
//

import SwiftUI

// MARK: - Body Text Modifier

/// Applies body typography and color from the active design tokens.
/// Zero hardcoded values — all styling comes from `@Environment(\.designTokens)`.
public struct BodyTextModifier: ViewModifier {
    @Environment(\.designTokens) private var tokens

    public init() {}

    public func body(content: Content) -> some View {
        content
            .font(tokens.bodyFont)
            .foregroundStyle(tokens.onBackground)
    }
}
