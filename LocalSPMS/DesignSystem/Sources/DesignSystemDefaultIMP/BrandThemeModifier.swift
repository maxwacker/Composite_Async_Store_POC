//
//  BrandThemeModifier.swift
//  DesignSystem
//

import SwiftUI
import DesignSystemIFC

// MARK: - Brand Theme Modifier

/// Automatically resolves the correct brand tokens based on the current color scheme.
/// Consumers simply apply `.brandTheme()` — light/dark resolution is internal.
public struct BrandThemeModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    public init() {}

    public func body(content: Content) -> some View {
        content
            .theme(colorScheme == .dark ? DarkBrandTokens() : BrandTokens())
    }
}

// MARK: - View Extension

public extension View {
    /// Applies the brand design tokens, automatically adapting to light/dark mode.
    func brandTheme() -> some View {
        modifier(BrandThemeModifier())
    }
}
