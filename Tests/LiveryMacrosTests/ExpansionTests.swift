import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
@testable import LiveryMacros

final class ExpansionTests: XCTestCase {
    let specs: [String: MacroSpec] = [
        "Roles": MacroSpec(type: RolesMacro.self, conformances: ["RoleSet", "Sendable"]),
        "Theme": MacroSpec(type: ThemeMacro.self, conformances: ["ThemeProvider"]),
    ]

    func testRolesGeneratesResolverValuesAndConformance() {
        assertMacroExpansion(
            """
            @Roles enum Colors: ColorRoles {
                case surface, accent
            }
            """,
            expandedSource: """
            enum Colors: ColorRoles {
                case surface, accent

                /// Lo que un tema debe resolver para `Colors`. Si falta un rol, el compilador lo señala en el tema.
                protocol Resolver: Sendable {
                    var surface: Livery.Shade {
                        get
                    }
                    var accent: Livery.Shade {
                        get
                    }
                }

                /// La resolución de `Colors` que viaja en `Theme`.
                struct Values: Sendable {
                    let surface: Livery.Shade
                    let accent: Livery.Shade

                    init(_ resolver: some Resolver) {
                        self.surface = resolver.surface
                        self.accent = resolver.accent
                    }

                    init(surface: Livery.Shade, accent: Livery.Shade) {
                        self.surface = surface
                        self.accent = accent
                    }

                    /// El valor de un rol elegido en runtime, para galerías, exportadores y pruebas.
                    subscript(role: Colors) -> Livery.Shade {
                        switch role {
                        case .surface:
                            surface
                        case .accent:
                            accent
                        }
                    }
                }

                static let unresolved = Values(surface: Livery.Shade.unresolved, accent: Livery.Shade.unresolved)
            }

            extension Colors: RoleSet, Sendable {
            }
            """,
            macroSpecs: specs
        )
    }

    func testThemeRegistersEachResolver() {
        assertMacroExpansion(
            """
            @Theme public struct Light: Colors.Resolver, Spacing.Resolver, Button.Styler, Sendable {
                let surface = Color.white
            }
            """,
            expandedSource: """
            public struct Light: Colors.Resolver, Spacing.Resolver, Button.Styler, Sendable {
                let surface = Color.white
            }

            extension Light: Livery.ThemeProvider {
                public var resolvedTheme: Livery.Theme {
                    var theme = Livery.Theme()
                    theme.register(Colors.Values(self), for: Colors.self)
                    theme.register(Spacing.Values(self), for: Spacing.self)
                    theme.register(style: self.button, for: Button.self)
                    return theme
                }
            }
            """,
            macroSpecs: specs
        )
    }

    // MARK: - Diagnósticos

    func testRolesRejectsAssociatedValues() {
        assertMacroExpansion(
            """
            @Roles enum Colors: ColorRoles {
                case a(Int)
            }
            """,
            expandedSource: """
            enum Colors: ColorRoles {
                case a(Int)
            }
            """,
            diagnostics: [DiagnosticSpec(message: "Un rol no puede tener valores asociados ni raw value.", line: 2, column: 10)],
            macroSpecs: specs
        )
    }

    func testThemeRequiresResolvers() {
        assertMacroExpansion(
            "@Theme struct Light {}",
            expandedSource: "struct Light {}",
            diagnostics: [DiagnosticSpec(
                message: "@Theme necesita al menos una conformance a un `Resolver` en la declaración, por ejemplo `Colors.Resolver`.",
                line: 1, column: 1)],
            macroSpecs: specs
        )
    }
}

extension ExpansionTests {
    func testRolesRequiresCategory() {
        assertMacroExpansion(
            """
            @Roles enum Colors {
                case a
            }
            """,
            expandedSource: """
            enum Colors {
                case a
            }
            """,
            diagnostics: [DiagnosticSpec(
                message: "`Colors` debe declarar su categoría conformando exactamente a una de: ColorRoles, TypeRoles, SpaceRoles, ShapeRoles, MotionRoles, ElevationRoles.",
                line: 1, column: 13)],
            macroSpecs: specs
        )
    }
}

extension ExpansionTests {
    func testBridgeAcceptsRenamesAndComputedMembers() {
        assertMacroExpansion(
            """
            @Bridge(from: ColorsV1.self, to: Colors.self)
            enum ColorsV1toV2 {
                static let primary = Colors.brand
                static func divider(_ colors: Colors.Values) -> Shade { colors.outline }
            }
            """,
            expandedSource: """
            enum ColorsV1toV2 {
                static let primary = Colors.brand
                static func divider(_ colors: Colors.Values) -> Shade { colors.outline }
            }
            """,
            macroSpecs: ["Bridge": MacroSpec(type: BridgeMacro.self)]
        )
    }

    func testBridgeRejectsBadMembers() {
        assertMacroExpansion(
            """
            @Bridge(from: ColorsV1.self, to: Colors.self)
            enum ColorsV1toV2 {
                static let primary = Shade(.red)
                let other = Colors.brand
                case nope
            }
            """,
            expandedSource: """
            enum ColorsV1toV2 {
                static let primary = Shade(.red)
                let other = Colors.brand
                case nope
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "El valor debe ser un rol de `Colors`, por ejemplo `Colors.brand`. Para calcularlo usa `static func`.", line: 3, column: 26),
                DiagnosticSpec(message: "Un miembro del puente es `static let viejo = Colors.rol` o `static func viejo(_ values: Colors.Values) -> T`.", line: 4, column: 5),
                DiagnosticSpec(message: "Un puente no declara casos; declara `static let` o `static func` por cada rol viejo.", line: 5, column: 5),
            ],
            macroSpecs: ["Bridge": MacroSpec(type: BridgeMacro.self)]
        )
    }
}

extension ExpansionTests {
    func testComponentGeneratesStylerProtocol() {
        assertMacroExpansion(
            """
            @Component
            public enum Button {
                struct Style: Sendable {
                    let tint: Int
                }
                static let unstyled = Style(tint: 0)
            }
            """,
            expandedSource: """
            public enum Button {
                struct Style: Sendable {
                    let tint: Int
                }
                static let unstyled = Style(tint: 0)

                /// Lo que un tema promete para este componente. `@Theme` registra la conformance.
                public protocol Styler {
                    var button: Style {
                        get
                    }
                }
            }
            """,
            macroSpecs: ["Component": MacroSpec(type: ComponentMacro.self)]
        )
    }

    func testComponentNeedsAStyleType() {
        assertMacroExpansion(
            """
            @Component
            enum Chip {
                case a
            }
            """,
            expandedSource: """
            enum Chip {
                case a
            }
            """,
            diagnostics: [DiagnosticSpec(message: "`Chip` necesita un `struct Style` que describa su estilo.", line: 2, column: 6)],
            macroSpecs: ["Component": MacroSpec(type: ComponentMacro.self)]
        )
    }
}
