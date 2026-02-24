//
//  HeadlineModifier.swift
//  DesignSystem
//

import SwiftUI

// MARK: - Headline Modifier

/// Applies headline typography and color from the active design tokens.
/// Zero hardcoded values — all styling comes from `@Environment(\.designTokens)`.
public struct HeadlineModifier: ViewModifier {
    @Environment(\.designTokens) private var tokens

    public init() {}

    public func body(content: Content) -> some View {
        content
            .font(tokens.headlineFont)
            .foregroundStyle(tokens.onBackground)
    }
}
