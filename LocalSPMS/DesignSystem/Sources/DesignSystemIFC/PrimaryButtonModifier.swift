//
//  PrimaryButtonModifier.swift
//  DesignSystem
//

import SwiftUI

// MARK: - Primary Button Modifier

/// Applies primary button styling from the active design tokens.
/// Applies background color, foreground color, font, padding, and corner radius.
/// Zero hardcoded values — all styling comes from `@Environment(\.designTokens)`.
public struct PrimaryButtonModifier: ViewModifier {
    @Environment(\.designTokens) private var tokens

    public init() {}

    public func body(content: Content) -> some View {
        content
            .font(tokens.bodyFont)
            .foregroundStyle(tokens.onPrimary)
            .padding(.horizontal, tokens.spacingMedium)
            .padding(.vertical, tokens.spacingSmall)
            .background(tokens.primary)
            .clipShape(RoundedRectangle(cornerRadius: tokens.cornerRadiusMedium))
    }
}
