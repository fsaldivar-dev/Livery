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
        #expect(output.code.contains("// `Brand` necesita argumentos: aplícalo con `.theme(Brand(…))`."))
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
        #expect(output.code.contains("ningún @Roles ni @Theme"))
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
        #expect(output.code.contains("ningún @Roles ni @Theme"))
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
