//
//  DarkBrandTokens.swift
//  DesignSystem
//

import SwiftUI
import DesignSystemIFC

// MARK: - Dark Brand Tokens

/// Concrete design tokens for the dark brand theme.
/// Shares the same fonts, spacing, and corner radii as BrandTokens, but provides
/// dark-mode-appropriate colors.
public struct DarkBrandTokens: DesignTokensProtocol, Sendable {

    public init() {}

    // MARK: Colors

    public var primary: Color { Color(red: 0.4, green: 0.6, blue: 1.0) }
    public var secondary: Color { Color(red: 0.7, green: 0.5, blue: 0.95) }
    public var background: Color { Color(red: 0.08, green: 0.08, blue: 0.1) }
    public var surface: Color { Color(red: 0.14, green: 0.14, blue: 0.17) }
    public var error: Color { Color(red: 1.0, green: 0.4, blue: 0.4) }
    public var onPrimary: Color { Color(red: 0.05, green: 0.05, blue: 0.1) }
    public var onSecondary: Color { .white }
    public var onBackground: Color { Color(red: 0.92, green: 0.92, blue: 0.95) }
    public var onSurface: Color { Color(red: 0.92, green: 0.92, blue: 0.95) }
    public var onError: Color { Color(red: 0.05, green: 0.05, blue: 0.1) }

    // MARK: Fonts

    public var headlineFont: Font { .system(size: 28, weight: .bold, design: .rounded) }
    public var titleFont: Font { .system(size: 22, weight: .semibold, design: .rounded) }
    public var bodyFont: Font { .system(size: 16, weight: .regular, design: .default) }
    public var captionFont: Font { .system(size: 12, weight: .regular, design: .default) }

    // MARK: Spacings

    public var spacingSmall: CGFloat { 8 }
    public var spacingMedium: CGFloat { 16 }
    public var spacingLarge: CGFloat { 32 }

    // MARK: Corner Radii

    public var cornerRadiusSmall: CGFloat { 6 }
    public var cornerRadiusMedium: CGFloat { 12 }
    public var cornerRadiusLarge: CGFloat { 20 }
}
