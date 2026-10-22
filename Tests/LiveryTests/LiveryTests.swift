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
    let surface = Shade(light: .white, dark: .black, darkIncreased: .gray)
    let onSurface = Shade(light: .black, dark: .white)
    let accent = Shade(.green)
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
    let surface = Shade(.white)
    let onSurface = Shade(.black)
    let accent: Shade
}

@Primitives enum Palette {
    static let jade = Color.green
}

@Suite struct ThemeTests {
    @Test func resolverValuesComeFromTheme() {
        let theme = Light().resolvedTheme
        #expect(theme.color.accent == Shade(.green))
        #expect(theme.space.md == 16)
        #expect(theme.resolves(Colors.self))
        #expect(!theme.resolves(Typography.self))
    }

    @Test func valuesAreIndexableByRole() {
        #expect(Theme.light.color[.accent] == Shade(.green))
        #expect(Theme.light.space[.lg] == 24)
    }

    @Test func registryGeneratesStaticAccessors() {
        #expect(Theme.light.color.accent == Shade(.green))
        #expect(Theme.dense.space.sm == 4)
        #expect(Brand(accent: Shade(.red)).resolvedTheme.color.accent == Shade(.red))
    }

    @Test func unresolvedSetFallsBackToVisiblePlaceholders() {
        let theme = Theme.light
        #expect(theme.type.title == .body)
        #expect(theme.shape.medium == 0)
        #expect(Colors.unresolved.surface == Shade(.pink))
    }

    @Test func mergingKeepsInheritedSetsAndOverridesProvided() {
        let merged = Theme.light.merging(.dense)
        #expect(merged.color.surface.light == .white)
        #expect(merged.space.md == 8)
    }

    @Test func refsResolveAgainstTheme() {
        let accent: ThemeRef<Shade> = .theme.color.accent
        #expect(Theme.light[accent] == Shade(.green))
        #expect(Theme.light[.theme.space.lg] == 24)
    }

    @Test func refResolvesByColorSchemeAndContrast() {
        var environment = EnvironmentValues()
        environment.theme = .light
        let style: ThemeRef<Shade> = .theme.color.surface

        environment.colorScheme = .light
        #expect(style.resolve(in: environment) == .white)

        environment.colorScheme = .dark
        #expect(style.resolve(in: environment) == .black)

        // `colorSchemeContrast` no se puede fijar en EnvironmentValues; se prueba en el Shade.
        let surface = Theme.light.color.surface
        #expect(surface.color(for: .dark, contrast: .increased) == .gray, "en oscuro con contraste aumentado usa darkIncreased")
        #expect(surface.color(for: .light, contrast: .increased) == .white, "sin lightIncreased cae en light")
    }

    @Test func shadeHelpersKeepEveryVariant() {
        let shade = Shade(light: .white, dark: .black, lightIncreased: .gray).opacity(0.5)
        #expect(shade.light == Color.white.opacity(0.5))
        #expect(shade.dark == Color.black.opacity(0.5))
        #expect(shade.lightIncreased == Color.gray.opacity(0.5))
        #expect(shade.darkIncreased == nil)
        #expect(Shade(.red).color(for: .dark) == .red)
    }

    @Test func shadeIsAShapeStyleAndBridgesToPlatformColors() {
        var environment = EnvironmentValues()
        environment.colorScheme = .dark
        #expect(Theme.light.color.onSurface.resolve(in: environment) == .white)
        #if canImport(UIKit) && !os(watchOS)
        _ = Theme.light.color.surface.uiColor
        #elseif canImport(AppKit)
        let dynamic = Theme.light.color.surface.nsColor
        var resolved: NSColor?
        NSAppearance(named: .darkAqua)?.performAsCurrentDrawingAppearance {
            resolved = NSColor(cgColor: dynamic.cgColor)
        }
        #expect(resolved != nil)
        #endif
    }

    /// Solo comprueba que las sobrecargas compilan con la forma prometida.
    @Test @MainActor func modifiersAcceptKeyPaths() {
        let view = Text("hola")
            .font(.theme.type.title)
            .foregroundStyle(.theme.color.onSurface)
            .padding(.theme.space.lg)
            .padding(.horizontal, .theme.space.sm)
            .background(.theme.color.surface)
            .background(.theme.color.surface, cornerRadius: .theme.shape.medium)
            .background(.theme.color.surface, in: Capsule())
            .tint(.theme.color.accent)
            .clipShape(cornerRadius: .theme.shape.small)
            .border(.theme.color.accent)
            .theme(.light)
            .theme(adding: .dense)
            .theme(Brand(accent: Shade(.red)))
            .foregroundStyle(Theme.light.color.accent)
            .theme(adding: Dense())
        _ = Circle().fill(.theme.color.accent)
        _ = Circle().stroke(.theme.color.accent, lineWidth: 2)
        _ = ThemeValue(.theme.space.md) { VStack(spacing: $0) { Text("a") } }
        #expect(type(of: view) != Never.self)
    }
}
