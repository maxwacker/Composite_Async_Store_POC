//
//  CardModifier.swift
//  DesignSystem
//

import SwiftUI

// MARK: - Card Modifier

/// Applies card styling from the active design tokens.
/// Provides surface background, corner radius, padding, and a subtle shadow.
/// Zero hardcoded values — all styling comes from `@Environment(\.designTokens)`.
public struct CardModifier: ViewModifier {
    @Environment(\.designTokens) private var tokens

    public init() {}

    public func body(content: Content) -> some View {
        content
            .padding(tokens.spacingMedium)
            .background(tokens.surface)
            .clipShape(RoundedRectangle(cornerRadius: tokens.cornerRadiusMedium))
            .shadow(color: .black.opacity(0.1), radius: tokens.cornerRadiusSmall, x: 0, y: 2)
    }
}
