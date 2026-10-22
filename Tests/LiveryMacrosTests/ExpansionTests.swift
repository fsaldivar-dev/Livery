import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
@testable import LiveryMacros

final class ExpansionTests: XCTestCase {
    let specs: [String: MacroSpec] = [
        "Roles": MacroSpec(type: RolesMacro.self),
        "_RoleSet": MacroSpec(type: RoleSetMacro.self, conformances: ["RoleSet"]),
        "Theme": MacroSpec(type: ThemeMacro.self, conformances: ["ThemeProvider"]),
    ]

    func testRolesAddsCategoryPropertiesAndMarksEnums() {
        assertMacroExpansion(
            """
            @Roles extension Theme {
                enum Colors: ColorRoles {
                    case surface, onSurface
                }
                public enum Spacing: SpaceRoles {
                    case sm
                }
            }
            """,
            expandedSource: """
            extension Theme {
                @_RoleSet
                enum Colors: ColorRoles {
                    case surface, onSurface
                }
                @_RoleSet
                public enum Spacing: SpaceRoles {
                    case sm
                }

                var color: Colors.Values {
                    values(Colors.self)
                }

                public var space: Spacing.Values {
                    values(Spacing.self)
                }
            }
            """,
            macroSpecs: ["Roles": MacroSpec(type: RolesMacro.self)]
        )
    }

    func testRoleSetGeneratesResolverValuesAndConformance() {
        assertMacroExpansion(
            """
            @_RoleSet enum Colors: ColorRoles {
                case surface, accent
            }
            """,
            expandedSource: """
            enum Colors: ColorRoles {
                case surface, accent

                /// Lo que un tema debe resolver para `Colors`. Si falta un rol, el compilador lo señala en el tema.
                protocol Resolver: Sendable {
                    var surface: SwiftUI.Color {
                        get
                    }
                    var accent: SwiftUI.Color {
                        get
                    }
                }

                /// La resolución de `Colors` que viaja en `Theme`.
                struct Values: Sendable {
                    let surface: SwiftUI.Color
                    let accent: SwiftUI.Color

                    init(_ resolver: some Resolver) {
                        self.surface = resolver.surface
                        self.accent = resolver.accent
                    }

                    init(surface: SwiftUI.Color, accent: SwiftUI.Color) {
                        self.surface = surface
                        self.accent = accent
                    }
                }

                static let unresolved = Values(surface: SwiftUI.Color.pink, accent: SwiftUI.Color.pink)
            }

            extension Colors: Livery.RoleSet {
            }
            """,
            macroSpecs: specs
        )
    }

    func testThemeRegistersEachResolver() {
        assertMacroExpansion(
            """
            @Theme public struct Light: Theme.Colors.Resolver, Theme.Spacing.Resolver, Sendable {
                let surface = Color.white
            }
            """,
            expandedSource: """
            public struct Light: Theme.Colors.Resolver, Theme.Spacing.Resolver, Sendable {
                let surface = Color.white
            }

            extension Light: Livery.ThemeProvider {
                public var resolvedTheme: Livery.Theme {
                    var theme = Livery.Theme()
                    theme.register(Theme.Colors.Values(self), for: Theme.Colors.self)
                    theme.register(Theme.Spacing.Values(self), for: Theme.Spacing.self)
                    return theme
                }
            }
            """,
            macroSpecs: specs
        )
    }

    // MARK: - Diagnósticos

    func testRolesRejectsNonThemeExtension() {
        assertMacroExpansion(
            """
            @Roles extension Other {
                enum Colors: ColorRoles {
                    case a
                }
            }
            """,
            expandedSource: """
            extension Other {
                @_RoleSet
                enum Colors: ColorRoles {
                    case a
                }
            }
            """,
            diagnostics: [DiagnosticSpec(message: "@Roles solo se aplica a `extension Theme`.", line: 1, column: 1)],
            macroSpecs: ["Roles": MacroSpec(type: RolesMacro.self)]
        )
    }

    func testRolesRequiresCategory() {
        assertMacroExpansion(
            """
            @Roles extension Theme {
                enum Colors {
                    case a
                }
            }
            """,
            expandedSource: """
            extension Theme {
                enum Colors {
                    case a
                }
            }
            """,
            diagnostics: [DiagnosticSpec(
                message: "`Colors` debe declarar su categoría conformando exactamente a una de: ColorRoles, TypeRoles, SpaceRoles, ShapeRoles.",
                line: 2, column: 10)],
            macroSpecs: ["Roles": MacroSpec(type: RolesMacro.self)]
        )
    }

    func testRolesRejectsDuplicateCategory() {
        assertMacroExpansion(
            """
            @Roles extension Theme {
                enum A: ColorRoles {
                    case a
                }
                enum B: ColorRoles {
                    case b
                }
            }
            """,
            expandedSource: """
            extension Theme {
                @_RoleSet
                enum A: ColorRoles {
                    case a
                }
                @_RoleSet
                enum B: ColorRoles {
                    case b
                }
            }
            """,
            diagnostics: [DiagnosticSpec(
                message: "La categoría ColorRoles ya está declarada por `A`. Solo puede haber un conjunto de roles por categoría.",
                line: 5, column: 10)],
            macroSpecs: ["Roles": MacroSpec(type: RolesMacro.self)]
        )
    }

    func testRoleSetRejectsAssociatedValues() {
        assertMacroExpansion(
            """
            @_RoleSet enum Colors: ColorRoles {
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
                message: "@Theme necesita al menos una conformance a un `Resolver` en la declaración, por ejemplo `Theme.Colors.Resolver`.",
                line: 1, column: 1)],
            macroSpecs: specs
        )
    }
}
