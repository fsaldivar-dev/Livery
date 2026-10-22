import Testing
@testable import LiveryRegistryCore

@Suite struct LintTests {
    func lint(_ text: String) -> [String] {
        Lint().check(sources: [.init(path: "View.swift", text: text)]).map { "\($0.line):\($0.column) \($0.message)" }
    }

    @Test func flagsHandMadeAndSystemColors() {
        let findings = lint("""
            let a = Color(red: 1, green: 0, blue: 0)
            let b = Color("brand")
            let c = Color(hex: 0xFF0000)
            let d = Color.red
            let v = Text("x").foregroundStyle(.blue).background(.theme.color.surface)
            """)
        #expect(findings.count == 5)
        #expect(findings[0].hasPrefix("1:9 Color construido en la vista."))
        #expect(findings[1].hasPrefix("2:9 Color construido en la vista."))
        #expect(findings[2].hasPrefix("3:9 Color construido en la vista."))
        #expect(findings[3].hasPrefix("4:9 Color del sistema `Color.red`"))
        #expect(findings[4].hasPrefix("5:35 Color del sistema `.blue`"))
    }

    @Test func flagsFontsOutsideTheTheme() {
        let findings = lint("""
            let a = Text("x").font(.system(size: 14))
            let b = Text("x").font(.title)
            let c = Font.system(size: 12, weight: .bold)
            let ok = Text("x").font(.theme.type.title)
            """)
        #expect(findings.count == 3)
        #expect(findings[0].hasPrefix("1:24 Fuente con tamaño fijo."))
        #expect(findings[1].hasPrefix("2:24 Estilo de texto `.title` fuera del tema."))
        #expect(findings[2].hasPrefix("3:9 Fuente con tamaño fijo."))
    }

    @Test func flagsLooseLengthsButNotZero() {
        let findings = lint("""
            let a = Text("x").padding(12).padding(.horizontal, 8).padding(0).padding(.theme.space.md)
            let b = VStack(spacing: 16) { Text("x") }
            let c = HStack(spacing: 0) { Text("x") }
            let d = RoundedRectangle(cornerRadius: 6)
            let e = Text("x").background(.theme.color.surface, cornerRadius: .theme.shape.small)
            """)
        #expect(findings.count == 4)
        #expect(findings[0].hasPrefix("1:27 Medida suelta en `padding`."))
        #expect(findings[1].hasPrefix("1:52 Medida suelta en `padding`."))
        #expect(findings[2].hasPrefix("2:25 Medida suelta en `spacing:`."))
        #expect(findings[3].hasPrefix("4:40 Medida suelta en `cornerRadius:`."))
    }

    @Test func designSystemModulesAreExempt() {
        let output = RegistryGenerator().generate(sources: [
            .init(path: "Palette.swift", text: "@Primitives enum Palette { static let red = Color(red: 1, green: 0, blue: 0) }"),
        ])
        #expect(output.diagnostics.isEmpty)

        let themed = RegistryGenerator().generate(sources: [
            .init(path: "Roles.swift", text: "@Roles enum Colors: ColorRoles { case a }\nlet x = Color.red"),
        ])
        #expect(themed.diagnostics.isEmpty)

        let ui = RegistryGenerator().generate(sources: [.init(path: "View.swift", text: "let x = Color.red")])
        #expect(ui.diagnostics.count == 1)
        #expect(!ui.hasErrors, "el lint avisa, no rompe el build")
    }
}
