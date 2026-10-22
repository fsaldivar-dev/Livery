import SwiftUI
import Testing
@testable import Livery

// Un sistema de diseño mínimo, declarado como lo haría una app: tipos planos, sin `extension Theme`.
// `theme.color`, `.light` y `.dense` los genera el plugin LiveryRegistry, activo en este target.

@Roles enum Colors: ColorRoles { case surface, onSurface, accent }
@Roles enum Typography: TypeRoles { case title, body }
@Roles enum Spacing: SpaceRoles { case sm, md, lg }
@Roles enum Shapes: ShapeRoles { case small, medium }

@Theme struct Light: Colors.Resolver, Spacing.Resolver {
    let surface = Color.white
    let onSurface = Color.black
    let accent = Color.green
    let sm: CGFloat = 8
    let md: CGFloat = 16
    let lg: CGFloat = 24
}

@Theme struct Dense: Spacing.Resolver {
    let sm: CGFloat = 4
    let md: CGFloat = 8
    let lg: CGFloat = 12
}

/// Un tema con parámetros: sin acceso estático, se aplica con `.theme(Brand(accent:))`.
@Theme struct Brand: Colors.Resolver {
    let surface = Color.white
    let onSurface = Color.black
    let accent: Color
}

@Primitives enum Palette {
    static let jade = Color.green
}

@Suite struct ThemeTests {
    @Test func resolverValuesComeFromTheme() {
        let theme = Light().resolvedTheme
        #expect(theme.color.accent == .green)
        #expect(theme.space.md == 16)
        #expect(theme.resolves(Colors.self))
        #expect(!theme.resolves(Typography.self))
    }

    @Test func registryGeneratesStaticAccessors() {
        #expect(Theme.light.color.accent == .green)
        #expect(Theme.dense.space.sm == 4)
        #expect(Brand(accent: .red).resolvedTheme.color.accent == .red)
    }

    @Test func unresolvedSetFallsBackToVisiblePlaceholders() {
        let theme = Theme.light
        #expect(theme.type.title == .body)
        #expect(theme.shape.medium == 0)
        #expect(Colors.unresolved.surface == .pink)
    }

    @Test func mergingKeepsInheritedSetsAndOverridesProvided() {
        let merged = Theme.light.merging(.dense)
        #expect(merged.color.surface == .white)
        #expect(merged.space.md == 8)
    }

    @Test func keyPathsResolveAgainstTheme() {
        let accent: KeyPath<Theme, Color> & Sendable = \.color.accent
        #expect(Theme.light[keyPath: accent] == .green)
    }

    @Test func themeStyleResolvesFromEnvironment() {
        var environment = EnvironmentValues()
        environment.theme = .light
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
            .theme(.light)
            .theme(adding: .dense)
            .theme(Brand(accent: .red))
            .theme(adding: Dense())
        _ = Circle().fill(\.color.accent)
        _ = Circle().stroke(\.color.accent, lineWidth: 2)
        #expect(type(of: view) != Never.self)
    }
}
