import SwiftUI
import Testing
@testable import Livery

// Un sistema de diseño mínimo, declarado como lo haría una app.

@Roles extension Theme {
    enum Colors: ColorRoles { case surface, onSurface, accent }
    enum Typography: TypeRoles { case title, body }
    enum Spacing: SpaceRoles { case sm, md, lg }
    enum Shapes: ShapeRoles { case small, medium }
}

@Theme struct Light: Theme.Colors.Resolver, Theme.Spacing.Resolver {
    let surface = Color.white
    let onSurface = Color.black
    let accent = Color.green
    let sm: CGFloat = 8
    let md: CGFloat = 16
    let lg: CGFloat = 24
}

@Theme struct Dense: Theme.Spacing.Resolver {
    let sm: CGFloat = 4
    let md: CGFloat = 8
    let lg: CGFloat = 12
}

@Primitives enum Palette {
    static let jade = Color.green
}

@Suite struct ThemeTests {
    @Test func resolverValuesComeFromTheme() {
        let theme = Light().resolvedTheme
        #expect(theme.color.accent == .green)
        #expect(theme.space.md == 16)
        #expect(theme.resolves(Theme.Colors.self))
        #expect(!theme.resolves(Theme.Typography.self))
    }

    @Test func unresolvedSetFallsBackToVisiblePlaceholders() {
        let theme = Light().resolvedTheme
        #expect(theme.type.title == .body)
        #expect(theme.shape.medium == 0)
        #expect(Theme.Colors.unresolved.surface == .pink)
    }

    @Test func mergingKeepsInheritedSetsAndOverridesProvided() {
        let merged = Light().resolvedTheme.merging(Dense().resolvedTheme)
        #expect(merged.color.surface == .white)
        #expect(merged.space.md == 8)
    }

    @Test func keyPathsResolveAgainstTheme() {
        let theme = Light().resolvedTheme
        let accent: KeyPath<Theme, Color> & Sendable = \.color.accent
        #expect(theme[keyPath: accent] == .green)
    }

    @Test func themeStyleResolvesFromEnvironment() {
        var environment = EnvironmentValues()
        environment.theme = Light().resolvedTheme
        #expect(ThemeStyle(\.color.onSurface).resolve(in: environment) == .black)
    }

    /// Solo comprueba que las sobrecargas compilan con la forma prometida.
    @Test @MainActor func modifiersAcceptKeyPaths() {
        let view = Text("hola")
            .font(\.type.title)
            .foregroundStyle(\.color.onSurface)
            .padding(\.space.lg)
            .padding(.horizontal, \.space.sm)
            .background(\.color.surface, cornerRadius: \.shape.medium)
            .tint(\.color.accent)
            .clipShape(cornerRadius: \.shape.small)
            .border(.theme(\.color.accent))
            .theme(Light())
            .theme(adding: Dense())
        _ = Circle().fill(\.color.accent)
        _ = Circle().stroke(\.color.accent, lineWidth: 2)
        #expect(type(of: view) != Never.self)
    }
}
