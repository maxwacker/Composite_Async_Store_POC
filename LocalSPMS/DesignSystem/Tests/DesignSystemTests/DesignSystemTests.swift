import Testing
@testable import DesignSystemIFC
@testable import DesignSystemDefaultIMP

@Test func fallbackTokensAreValid() async throws {
    let tokens: any DesignTokensProtocol = FallbackTokens()
    #expect(tokens.spacingMedium == 16)
    #expect(tokens.cornerRadiusMedium == 8)
}

@Test func brandTokensConformToProtocol() async throws {
    let tokens: any DesignTokensProtocol = BrandTokens()
    #expect(tokens.spacingMedium == 16)
    #expect(tokens.cornerRadiusMedium == 12)
}

@Test func darkBrandTokensConformToProtocol() async throws {
    let tokens: any DesignTokensProtocol = DarkBrandTokens()
    #expect(tokens.spacingMedium == 16)
    #expect(tokens.cornerRadiusMedium == 12)
}
