//
//  DesignTokensProtocol.swift
//  DesignSystem
//

import SwiftUI

// MARK: - Design Tokens Protocol

/// Contract defining all semantic design tokens for the application.
/// Conforming types provide concrete values for colors, fonts, spacings, and corner radii.
/// Feature views never see a concrete conformance — they read tokens from the environment.
public protocol DesignTokensProtocol: Sendable {

    // MARK: Colors

    var primary: Color { get }
    var secondary: Color { get }
    var background: Color { get }
    var surface: Color { get }
    var error: Color { get }
    var onPrimary: Color { get }
    var onSecondary: Color { get }
    var onBackground: Color { get }
    var onSurface: Color { get }
    var onError: Color { get }

    // MARK: Fonts

    var headlineFont: Font { get }
    var titleFont: Font { get }
    var bodyFont: Font { get }
    var captionFont: Font { get }

    // MARK: Spacings

    var spacingSmall: CGFloat { get }
    var spacingMedium: CGFloat { get }
    var spacingLarge: CGFloat { get }

    // MARK: Corner Radii

    var cornerRadiusSmall: CGFloat { get }
    var cornerRadiusMedium: CGFloat { get }
    var cornerRadiusLarge: CGFloat { get }
}
