import SwiftSyntax
import SwiftSyntaxMacros

/// `@Component enum Button { … }`
///
/// Genera el protocolo `Styler` que un tema conforma para dar el estilo del componente. El
/// accesor `theme.button` lo escribe el plugin (extiende `Theme`, cosa que un macro no puede
/// hacer desde otro tipo). El autor escribe lo propio del diseño: los enums de variante y tamaño,
/// el struct `Style` y el `unstyled` de reserva.
public struct ComponentMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            context.error("@Component solo se aplica a un enum.", id: "component.notEnum", at: node)
            return []
        }
        let hasStyle = enumDecl.memberBlock.members.contains { member in
            member.decl.as(StructDeclSyntax.self)?.name.text == "Style"
        }
        guard hasStyle else {
            context.error("`\(enumDecl.name.text)` necesita un `struct Style` que describa su estilo.", id: "component.noStyle", at: enumDecl.name)
            return []
        }
        let access = enumDecl.modifiers.accessPrefix
        let property = ComponentMacro.propertyName(for: enumDecl.name.text)
        return [
            """
            /// Lo que un tema promete para este componente. `@Theme` registra la conformance.
            \(raw: access)protocol Styler {
                var \(raw: property): Style { get }
            }
            """
        ]
    }

    /// `Button` → `button`, `IconButton` → `iconButton`.
    static func propertyName(for name: String) -> String {
        guard let first = name.first else { return name }
        return first.lowercased() + name.dropFirst()
    }
}
