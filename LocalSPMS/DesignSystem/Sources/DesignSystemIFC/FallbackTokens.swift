//
//  FallbackTokens.swift
//  DesignSystem
//

import SwiftUI

// MARK: - Fallback Tokens

/// Neutral system defaults for use in SwiftUI Previews and when no brand tokens are injected.
/// Uses only platform-agnostic SwiftUI values so that every feature Preview compiles
/// and renders standalone without importing DesignSystemDefaultIMP.
public struct FallbackTokens: DesignTokensProtocol, Sendable {

    public init() {}

    // MARK: Colors

    public var primary: Color { .accentColor }
    public var secondary: Color { .secondary }
    #if canImport(UIKit)
    public var background: Color { Color(.systemBackground) }
    public var surface: Color { Color(.secondarySystemBackground) }
    #else
    public var background: Color { Color(.windowBackgroundColor) }
    public var surface: Color { Color(.controlBackgroundColor) }
    #endif
    public var error: Color { .red }
    public var onPrimary: Color { .white }
    public var onSecondary: Color { .white }
    public var onBackground: Color { .primary }
    public var onSurface: Color { .primary }
    public var onError: Color { .white }

    // MARK: Fonts

    public var headlineFont: Font { .headline }
    public var titleFont: Font { .title2 }
    public var bodyFont: Font { .body }
    public var captionFont: Font { .caption }

    // MARK: Spacings

    public var spacingSmall: CGFloat { 8 }
    public var spacingMedium: CGFloat { 16 }
    public var spacingLarge: CGFloat { 24 }

    // MARK: Corner Radii

    public var cornerRadiusSmall: CGFloat { 4 }
    public var cornerRadiusMedium: CGFloat { 8 }
    public var cornerRadiusLarge: CGFloat { 16 }
}
