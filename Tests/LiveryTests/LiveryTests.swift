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
        #expect(theme.type.title == TypeStyle.unresolved)
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

// Un contrato de componente mínimo, con la forma que generará @Component: un Look por variante.
enum Chip {
    enum Variant: ComponentVariant { case neutral, accent }
    enum Size: ComponentSize { case regular }
    struct Look: Sendable, Equatable { var background: Colors; var foreground: Colors }
    struct Style: Sendable {
        var neutral: Look
        var accent: Look
        func look(for variant: Variant) -> Look { variant == .neutral ? neutral : accent }
    }
}

@Suite struct ComponentTests {
    let style = Chip.Style(neutral: .init(background: .surface, foreground: .onSurface),
                           accent: .init(background: .accent, foreground: .onSurface))

    @Test func themeStoresComponentStyles() {
        var theme = Theme.light
        #expect(theme.style(for: Chip.self, as: Chip.Style.self) == nil)
        theme.register(style: style, for: Chip.self)
        let stored: Chip.Style? = theme.style(for: Chip.self)
        #expect(stored?.look(for: .accent).background == .accent)
        #expect(Theme.light.merging(theme).style(for: Chip.self, as: Chip.Style.self) != nil, "merging conserva los estilos")
    }

    @Test func looksResolveThroughTheTheme() {
        let look = style.look(for: .accent)
        #expect(Theme.light.color[look.background] == Shade(.green))
    }

    @Test func sizesDefaultToTheAccessibilityMinimum() {
        #expect(Chip.Size.regular.minimumHitTarget == 44)
        #expect(ComponentState.allCases.count == 5)
    }
}

@Suite struct ExportTests {
    @Test func shadeExportsHexPerMode() {
        let shade = Shade(light: Color(red: 1, green: 0, blue: 0), dark: Color(red: 0, green: 0, blue: 0))
        #expect(shade.hex(mode: .light) == "#FF0000")
        #expect(shade.hex(mode: .dark) == "#000000")
    }

    @Test func documentBuildsW3CTokens() throws {
        let document = W3CDocument()
        document.color("color", "accent", Shade(Color(red: 0, green: 0.5, blue: 1)), mode: .light)
        document.dimension("spacing", "md", 16)
        document.typography("font", "title", TypeStyle(.title, weight: .semibold))

        let object = try JSONSerialization.jsonObject(with: Data(document.json.utf8)) as! [String: Any]
        let color = (object["color"] as! [String: Any])["accent"] as! [String: Any]
        #expect(color["$type"] as? String == "color")
        #expect((color["$value"] as? String)?.hasPrefix("#") == true)

        let spacing = (object["spacing"] as! [String: Any])["md"] as! [String: Any]
        #expect(spacing["$value"] as? String == "16px")

        let font = ((object["font"] as! [String: Any])["title"] as! [String: Any])["$value"] as! [String: Any]
        #expect(font["fontSize"] as? String == "28px")
        #expect(font["fontWeight"] as? Int == 600)
    }

    @Test func themeExportsEveryRoleSet() throws {
        let object = try JSONSerialization.jsonObject(with: Data(Theme.light.w3cTokens(mode: .light).utf8)) as! [String: Any]
        // Light resuelve Colors y Spacing; cada rol aparece como token.
        let colors = object["color"] as! [String: Any]
        #expect(colors["accent"] != nil && colors["surface"] != nil)
        #expect((object["spacing"] as! [String: Any])["md"] != nil)
    }
}

@Suite struct ContrastTests {
    @Test func blackOnWhiteIsTheMaximumRatio() {
        let ratio = Shade(.white).contrastRatio(against: Shade(.black), mode: .light)
        #expect(abs(ratio - 21) < 0.5)
    }

    @Test func flagsLowContrastPairsButNotGoodOnes() {
        let roles: [(name: String, shade: Shade)] = [
            ("surface", Shade(.white)),
            ("onSurface", Shade(Color(white: 0.75))),              // gris claro sobre blanco → falla
            ("accent", Shade(Color(red: 0.1, green: 0.1, blue: 0.5))),
            ("onAccent", Shade(.white)),                            // blanco sobre azul oscuro → pasa
        ]
        let issues = ContrastChecker.check(roles, level: .AA)
        #expect(issues.contains { $0.foreground == "onSurface" }, "texto gris claro sobre blanco no llega a 4.5:1")
        #expect(!issues.contains { $0.foreground == "onAccent" })
    }

    @Test func checksBothModes() {
        // onSurface legible en claro pero no en oscuro (ambos fondos iguales a propósito).
        let roles: [(name: String, shade: Shade)] = [
            ("surface", Shade(light: .white, dark: .white)),
            ("onSurface", Shade(light: .black, dark: Color(white: 0.8))),
        ]
        let issues = ContrastChecker.check(roles, level: .AA)
        #expect(issues.map(\.mode) == [.dark], "solo el modo oscuro falla")
    }
}
