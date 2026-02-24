//
//  View+DesignSystem.swift
//  DesignSystem
//

import SwiftUI

// MARK: - Design System View Extensions

public extension View {

    /// Applies headline typography from the active design tokens.
    func dsHeadline() -> some View {
        modifier(HeadlineModifier())
    }

    /// Applies body text typography from the active design tokens.
    func dsBody() -> some View {
        modifier(BodyTextModifier())
    }

    /// Applies primary button styling from the active design tokens.
    func dsPrimaryButton() -> some View {
        modifier(PrimaryButtonModifier())
    }

    /// Applies card container styling from the active design tokens.
    func dsCard() -> some View {
        modifier(CardModifier())
    }
}
