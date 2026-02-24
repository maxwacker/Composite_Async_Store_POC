//
//  BrandTokens.swift
//  DesignSystem
//

import SwiftUI
import DesignSystemIFC

// MARK: - Brand Tokens (Light)

/// Concrete design tokens for the light brand theme.
/// Provides real brand colors, fonts, spacing, and corner radii.
public struct BrandTokens: DesignTokensProtocol, Sendable {

    public init() {}

    // MARK: Colors

    public var primary: Color { Color(red: 0.2, green: 0.4, blue: 0.9) }
    public var secondary: Color { Color(red: 0.55, green: 0.35, blue: 0.85) }
    public var background: Color { Color(red: 0.97, green: 0.97, blue: 0.98) }
    public var surface: Color { .white }
    public var error: Color { Color(red: 0.9, green: 0.2, blue: 0.2) }
    public var onPrimary: Color { .white }
    public var onSecondary: Color { .white }
    public var onBackground: Color { Color(red: 0.1, green: 0.1, blue: 0.15) }
    public var onSurface: Color { Color(red: 0.1, green: 0.1, blue: 0.15) }
    public var onError: Color { .white }

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
