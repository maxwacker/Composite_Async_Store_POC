//
//  DesignTokensEnvironment.swift
//  DesignSystem
//

import SwiftUI

// MARK: - Environment Key

/// Custom environment key for injecting design tokens into the SwiftUI view hierarchy.
/// Default value is `FallbackTokens()`, ensuring every view has usable tokens even
/// when no brand-specific implementation is injected at the app root.
private struct DesignTokensKey: EnvironmentKey {
    static let defaultValue: any DesignTokensProtocol = FallbackTokens()
}

// MARK: - EnvironmentValues Extension

public extension EnvironmentValues {
    /// The active design tokens for the current view hierarchy.
    /// Reads from the nearest `.theme(_:)` modifier, falling back to `FallbackTokens`.
    var designTokens: any DesignTokensProtocol {
        get { self[DesignTokensKey.self] }
        set { self[DesignTokensKey.self] = newValue }
    }
}

// MARK: - View Convenience Modifier

public extension View {
    /// Injects design tokens into the environment for the receiver and all its descendants.
    /// Typically called once at the app root with brand-specific tokens.
    func theme(_ tokens: any DesignTokensProtocol) -> some View {
        environment(\.designTokens, tokens)
    }
}
