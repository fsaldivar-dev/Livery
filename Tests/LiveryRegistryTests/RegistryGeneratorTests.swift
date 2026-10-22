import Testing
@testable import LiveryRegistryCore

@Suite struct RegistryGeneratorTests {
    func generate(_ text: String, path: String = "DS.swift") -> RegistryGenerator.Output {
        RegistryGenerator().generate(sources: [.init(path: path, text: text)])
    }

    @Test func rolesBecomeCategoryProperties() {
        let output = generate("""
            @Roles enum Colors: ColorRoles { case surface }
            @Roles public enum Spacing: Livery.SpaceRoles { case sm }
            """)
        #expect(output.code.contains("    var color: Colors.Values { values(Colors.self) }"))
        #expect(output.code.contains("    public var space: Spacing.Values { values(Spacing.self) }"))
        #expect(output.diagnostics.isEmpty)
    }

    @Test func themesBecomeStaticAccessors() {
        let output = generate("""
            @Theme struct Light: Colors.Resolver { let surface = Color.white }
            @Theme public final class PlayerDense: Spacing.Resolver { let sm: CGFloat = 4 }
            """)
        #expect(output.code.contains("    static var light: Livery.Theme { Light().resolvedTheme }"))
        #expect(output.code.contains("    public static var playerDense: Livery.Theme { PlayerDense().resolvedTheme }"))
    }

    @Test func nestedDeclarationsAreQualified() {
        let output = generate("""
            enum DesignSystem {
                @Roles enum Colors: ColorRoles { case surface }
                @Theme struct Light: Colors.Resolver { let surface = Color.white }
            }
            extension Theme {
                @Theme struct Dark: DesignSystem.Colors.Resolver { let surface = Color.black }
            }
            """)
        #expect(output.code.contains("var color: DesignSystem.Colors.Values { values(DesignSystem.Colors.self) }"))
        #expect(output.code.contains("static var light: Livery.Theme { DesignSystem.Light().resolvedTheme }"))
        #expect(output.code.contains("static var dark: Livery.Theme { Theme.Dark().resolvedTheme }"))
    }

    @Test func themesNeedingArgumentsGetNoAccessor() {
        let output = generate("""
            @Theme struct Brand: Colors.Resolver { let primary: Color }
            @Theme struct Tinted: Colors.Resolver {
                let surface: Color
                init(surface: Color) { self.surface = surface }
            }
            @Theme struct Generic<T>: Colors.Resolver { let surface = Color.white }
            @Theme struct Defaulted: Colors.Resolver {
                let surface: Color
                init(surface: Color = .white) { self.surface = surface }
            }
            @Theme struct Nullable: Colors.Resolver { var note: String?; let surface = Color.white }
            """)
        #expect(!output.code.contains("static var brand"))
        #expect(output.code.contains("// `Brand` necesita argumentos: aplícalo con `.environment(\\.theme, Brand(…).resolvedTheme)`."))
        #expect(!output.code.contains("static var tinted"))
        #expect(!output.code.contains("static var generic"))
        #expect(output.code.contains("static var defaulted: Livery.Theme { Defaulted().resolvedTheme }"))
        #expect(output.code.contains("static var nullable: Livery.Theme { Nullable().resolvedTheme }"))
    }

    @Test func localTypesAreIgnored() {
        let output = generate("""
            func make() {
                @Theme struct Local: Colors.Resolver { let surface = Color.white }
            }
            """)
        #expect(!output.code.contains("local"))
        #expect(output.code.contains("ningún @Roles, @Theme, @Component ni @Bridge"))
    }

    @Test func duplicateCategoryIsAnError() {
        let output = RegistryGenerator().generate(sources: [
            .init(path: "A.swift", text: "@Roles enum A: ColorRoles { case a }"),
            .init(path: "B.swift", text: "\n@Roles enum B: ColorRoles { case b }"),
        ])
        #expect(output.hasErrors)
        #expect(output.diagnostics.count == 1)
        let diagnostic = try! #require(output.diagnostics.first)
        #expect(diagnostic.path == "B.swift")
        #expect(diagnostic.line == 2)
        #expect(diagnostic.column == 13)
        #expect(diagnostic.description.hasPrefix("B.swift:2:13: error: La categoría ColorRoles ya está declarada por `A` en A.swift:1."))
        #expect(output.code.contains("var color: A.Values"))
        #expect(!output.code.contains("B.Values"))
    }

    @Test func rolesWithoutCategoryAreSkipped() {
        let output = generate("@Roles enum Colors { case surface }")
        #expect(output.diagnostics.isEmpty)
        #expect(output.code.contains("ningún @Roles, @Theme, @Component ni @Bridge"))
    }

    @Test func accessorNames() {
        #expect(RegistryVisitor.accessorName(for: "Light") == "light")
        #expect(RegistryVisitor.accessorName(for: "PlayerDense") == "playerDense")
        #expect(RegistryVisitor.accessorName(for: "HTTPDark") == "httpDark")
        #expect(RegistryVisitor.accessorName(for: "ABC") == "abc")
        #expect(RegistryVisitor.accessorName(for: "Default") == "`default`")
        #expect(RegistryVisitor.accessorName(for: "light") == "light")
    }
}

@Suite struct BridgeGeneratorTests {
    let roles = """
        @Roles enum ColorsV1: ColorRoles { case primary, cardBackground, divider, textSecondary }
        @Roles public enum Colors: ColorRoles { case brand, action, surfaceElevated, outline, textSecondary }
        """
    let bridge = """
        @Bridge(from: ColorsV1.self, to: Colors.self)
        enum ColorsV1toV2 {
            static let primary        = Colors.brand
            static let cardBackground = Colors.surfaceElevated
            /// DS2 eliminó el divisor; usa `outline` con opacidad.
            static func divider(_ colors: Colors.Values) -> Shade { colors.outline.opacity(0.4) }
        }
        """

    func generate(_ extra: [(String, String)] = []) -> RegistryGenerator.Output {
        var sources = [RegistryGenerator.Source(path: "Roles.swift", text: roles), .init(path: "Bridge.swift", text: bridge)]
        sources += extra.map { .init(path: $0.0, text: $0.1) }
        return RegistryGenerator().generate(sources: sources)
    }

    @Test func legacySetGivesUpItsCategoryWithoutDuplicateError() {
        let output = generate()
        #expect(!output.hasErrors)
        #expect(output.code.contains("public var color: Colors.Values { values(Colors.self) }"))
        #expect(!output.code.contains("ColorsV1.Values { values"))
    }

    @Test func bridgeGeneratesDeprecatedForwardsOnNewValues() {
        let code = generate().code
        #expect(code.contains("extension Colors.Values {"))
        #expect(code.contains("    @available(*, deprecated, renamed: \"brand\")\n    public var primary: Livery.Shade { brand }"))
        #expect(code.contains("    @available(*, deprecated, renamed: \"surfaceElevated\")\n    public var cardBackground: Livery.Shade { surfaceElevated }"))
        #expect(code.contains("`divider` ya no existe en Colors; lo calcula ColorsV1toV2.divider. DS2 eliminó el divisor; usa `outline` con opacidad."))
        #expect(code.contains("    public var divider: Livery.Shade { ColorsV1toV2.divider(self) }"))
        #expect(!code.contains("var textSecondary"), "un rol que existe en ambos no se reenvía")
    }

    @Test func reportCountsRemainingUsesOutsideTheBridge() {
        let view = """
            struct Card: View {
                var body: some View {
                    Text("x").foregroundStyle(theme.color.primary).background(theme.color.primary)
                        .border(theme.color.divider)
                }
            }
            """
        let output = generate([("Card.swift", view), ("Other.swift", "let x = theme.color.primary")])
        let report = output.diagnostics.first { $0.severity == .warning }!
        #expect(report.path == "Bridge.swift" && report.line == 2)
        #expect(report.message == "Migración ColorsV1 → Colors: 4 usos pendientes en 2 archivos (primary: 3, divider: 1).")

        let done = generate().diagnostics.first { $0.severity == .warning }!
        #expect(done.message.hasPrefix("Migración ColorsV1 → Colors: 0 usos pendientes. Puedes borrar `ColorsV1` y este puente."))

        // Los fuentes de otros módulos del paquete cuentan, pero no declaran nada.
        let app = RegistryGenerator().generate(
            sources: [.init(path: "Roles.swift", text: roles), .init(path: "Bridge.swift", text: bridge)],
            usages: [.init(path: "App/Card.swift", text: view + "\n@Roles enum Ignored: SpaceRoles { case sm }")])
        let appReport = app.diagnostics.first { $0.severity == .warning }!
        #expect(appReport.message == "Migración ColorsV1 → Colors: 3 usos pendientes en 1 archivo (primary: 2, divider: 1).")
        #expect(!app.code.contains("Ignored"))
    }

    @Test func missingRolesFailTheBuildAtTheBridge() {
        let partial = """
            @Bridge(from: ColorsV1.self, to: Colors.self)
            enum ColorsV1toV2 {
                static let primary = Colors.brand
            }
            """
        let output = RegistryGenerator().generate(sources: [.init(path: "Roles.swift", text: roles), .init(path: "Bridge.swift", text: partial)])
        #expect(output.hasErrors)
        let error = output.diagnostics.first { $0.severity == .error }!
        #expect(error.path == "Bridge.swift" && error.line == 2 && error.column == 6)
        #expect(error.message.hasPrefix("El puente no cubre: cardBackground, divider."))
        #expect(!output.code.contains("extension Colors.Values"))
    }

    @Test func wrongTargetsAndRedundantMembersAreErrors() {
        let wrong = """
            @Bridge(from: ColorsV1.self, to: Colors.self)
            enum ColorsV1toV2 {
                static let primary        = Colors.brand
                static let cardBackground = Colors.card
                static let divider        = Colors.outline
                static let textSecondary  = Colors.textSecondary
                static let ghost          = Colors.brand
            }
            """
        let output = RegistryGenerator().generate(sources: [.init(path: "Roles.swift", text: roles), .init(path: "Bridge.swift", text: wrong)])
        let messages = output.diagnostics.filter { $0.severity == .error }.map(\.message)
        #expect(messages.contains("`Colors` no tiene el rol `card`."))
        #expect(messages.contains("`textSecondary` existe en `Colors` con el mismo nombre; no necesita puente."))
        #expect(messages.contains("`ghost` no es un rol de `ColorsV1`."))
    }

    @Test func bridgeNeedsBothSetsInTheSameCategory() {
        let mixed = """
            @Roles enum Spacing: SpaceRoles { case sm }
            @Bridge(from: ColorsV1.self, to: Spacing.self) enum Wrong { static let primary = Spacing.sm }
            @Bridge(from: Missing.self, to: Colors.self) enum Lost {}
            """
        let output = RegistryGenerator().generate(sources: [.init(path: "Roles.swift", text: roles), .init(path: "Bridge.swift", text: mixed)])
        let messages = output.diagnostics.map(\.message)
        #expect(messages.contains { $0.hasPrefix("`ColorsV1` es ColorRoles y `Spacing` es SpaceRoles") })
        #expect(messages.contains("No hay ningún `@Roles enum Missing` en este módulo."))
    }
}

@Suite struct GeneratedFileTests {
    @Test func upToDateIgnoresWhitespaceButNotContent() {
        let output = RegistryGenerator().generate(sources: [.init(path: "Roles.swift", text: "@Roles enum Colors: ColorRoles { case a }")])
        #expect(output.isUpToDate(comparedTo: output.code))
        #expect(output.isUpToDate(comparedTo: output.code + "\n\n"))
        #expect(output.isUpToDate(comparedTo: output.code.replacingOccurrences(of: "\n", with: "  \r\n")))
        #expect(!output.isUpToDate(comparedTo: output.code.replacingOccurrences(of: "var color", with: "var colour")))
        #expect(!output.isUpToDate(comparedTo: ""))
    }
}

@Suite struct ComponentGeneratorTests {
    @Test func componentGetsAThemeAccessor() {
        let output = RegistryGenerator().generate(sources: [
            .init(path: "Button.swift", text: "@Component public enum Button { struct Style: Sendable {}; static let unstyled = Style() }"),
        ])
        #expect(output.code.contains("public var button: Button.Style { style(for: Button.self) ?? Button.unstyled }"))
        #expect(!output.hasErrors)
    }

    @Test func nestedComponentIsQualified() {
        let output = RegistryGenerator().generate(sources: [
            .init(path: "DS.swift", text: "enum DS { @Component enum IconButton { struct Style {}; static let unstyled = Style() } }"),
        ])
        #expect(output.code.contains("var iconButton: DS.IconButton.Style { style(for: DS.IconButton.self) ?? DS.IconButton.unstyled }"))
    }
}
