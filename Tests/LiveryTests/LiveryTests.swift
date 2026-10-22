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

/// Un tema con parámetros: sin acceso estático, se aplica con `.environment(\\.theme, Brand(accent:).resolvedTheme)`.
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

    @Test func shadeResolvesByColorSchemeAndContrast() {
        var environment = EnvironmentValues()
        environment.theme = .light
        let style = Theme.light.color.surface

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

    /// Solo comprueba que la forma recomendada compila: valores planos en modificadores nativos.
    @Test @MainActor func valuesWorkWithNativeModifiers() {
        let theme = Theme.light
        let view = Text("hola")
            .font(theme.type.title)
            .foregroundStyle(theme.color.onSurface)
            .padding(theme.space.lg)
            .padding(.horizontal, theme.space.sm)
            .background(theme.color.surface)
            .background(theme.color.surface, in: .rect(cornerRadius: theme.shape.medium))
            .tint(theme.color.accent)
            .clipShape(.rect(cornerRadius: theme.shape.small))
            .border(theme.color.accent)
            .environment(\.theme, .light)
            .environment(\.theme, adding: .dense)
            .environment(\.theme, Brand(accent: Shade(.red)).resolvedTheme)
            .environment(\.theme, adding: Dense())
        _ = Circle().fill(theme.color.accent)
        _ = Circle().stroke(theme.color.accent, lineWidth: 2)
        #expect(type(of: view) != Never.self)
    }
}

// Un contrato de componente mínimo, como lo escribiría una app (y como lo generará @Component).
enum Chip {
    enum Part: ComponentPart { case container, label }
    enum Kind: ComponentVariant { case neutral, accent }
    enum Size: ComponentSize { case regular }

    struct Attributes: PartAttributes, Equatable {
        var background: Colors?
        var opacity: Double?
        func overriding(with other: Attributes) -> Attributes {
            Attributes(background: other.background ?? background, opacity: other.opacity ?? opacity)
        }
    }
    typealias Style = ComponentStyle<Part, Kind, Size, Attributes>
}

@Suite struct ComponentStyleTests {
    let style = Chip.Style(
        base: { part in
            switch part {
            case .container: Chip.Attributes(background: .surface, opacity: 1)
            case .label: Chip.Attributes(background: nil, opacity: 1)
            }
        },
        variants: [.accent: [.container: Chip.Attributes(background: .accent)]],
        states: [.disabled: [.container: Chip.Attributes(opacity: 0.4)], .pressed: [.container: Chip.Attributes(background: .onSurface)]]
    )

    @Test func baseCoversEveryPart() {
        let parts = style.attributes(variant: .neutral, size: .regular, state: .normal)
        #expect(Set(parts.keys) == Set(Chip.Part.allCases))
        #expect(parts[.container] == Chip.Attributes(background: .surface, opacity: 1))
    }

    @Test func cascadeAppliesVariantThenStateAndKeepsTheRest() {
        let accent = style.attributes(variant: .accent, size: .regular, state: .normal)[.container]
        #expect(accent == Chip.Attributes(background: .accent, opacity: 1))

        let disabled = style.attributes(variant: .accent, size: .regular, state: .disabled)[.container]
        #expect(disabled == Chip.Attributes(background: .accent, opacity: 0.4), "el estado solo toca lo que declara")

        let pressed = style.attributes(variant: .accent, size: .regular, state: .pressed)[.container]
        #expect(pressed?.background == .onSurface, "el estado gana sobre la variante")
    }

    @Test func themeStoresComponentStyles() {
        var theme = Theme.light
        #expect(theme.style(for: Chip.self, as: Chip.Style.self) == nil)
        theme.register(style: style, for: Chip.self)
        let stored: Chip.Style? = theme.style(for: Chip.self)
        #expect(stored?.attributes(variant: .accent, size: .regular, state: .normal)[.container]?.background == .accent)
        #expect(Theme.light.merging(theme).style(for: Chip.self, as: Chip.Style.self) != nil, "merging conserva los estilos")
    }

    @Test func sizesDefaultToTheAccessibilityMinimum() {
        #expect(Chip.Size.regular.minimumHitTarget == 44)
    }
}
