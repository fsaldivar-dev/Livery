import SwiftSyntax
import SwiftSyntaxMacros

/// `@Roles enum Colors: ColorRoles { case … }`
///
/// Genera `Resolver` (un protocolo con una propiedad por rol), `Values` (la resolución
/// inmutable), `unresolved` y las conformances a `RoleSet` y `Sendable` (un enum público no
/// es `Sendable` implícito, y un tema se comparte entre vistas). La propiedad `theme.color` la
/// genera el plugin de build `LiveryRegistry`, porque un macro no puede extender `Theme`.
public struct RolesMacro: MemberMacro, ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let role = validRole(of: declaration, node: node, in: context) else { return [] }

        let access = role.access
        let type = role.category.valueType
        let requirements = role.cases.map { "    var \($0): \(type) { get }" }.joined(separator: "\n")
        let stored = role.cases.map { "    \(access)let \($0): \(type)" }.joined(separator: "\n")
        let fromResolver = role.cases.map { "        self.\($0) = resolver.\($0)" }.joined(separator: "\n")
        let memberwiseParams = role.cases.map { "\($0): \(type)" }.joined(separator: ", ")
        let memberwiseAssign = role.cases.map { "        self.\($0) = \($0)" }.joined(separator: "\n")
        let placeholders = role.cases.map { "\($0): \(role.category.placeholder)" }.joined(separator: ", ")
        let byRole = role.cases.map { "        case .\($0): \($0)" }.joined(separator: "\n")

        return [
            """
            /// Lo que un tema debe resolver para `\(raw: role.name)`. Si falta un rol, el compilador lo señala en el tema.
            \(raw: access)protocol Resolver: Sendable {
            \(raw: requirements)
            }
            """,
            """
            /// La resolución de `\(raw: role.name)` que viaja en `Theme`.
            \(raw: access)struct Values: Sendable {
            \(raw: stored)

                \(raw: access)init(_ resolver: some Resolver) {
            \(raw: fromResolver)
                }

                \(raw: access)init(\(raw: memberwiseParams)) {
            \(raw: memberwiseAssign)
                }

                /// El valor de un rol elegido en runtime, para galerías, exportadores y pruebas.
                \(raw: access)subscript(role: \(raw: role.name)) -> \(raw: type) {
                    switch role {
            \(raw: byRole)
                    }
                }
            }
            """,
            """
            \(raw: access)static let unresolved = Values(\(raw: placeholders))
            """,
        ]
    }

    /// El enum validado. Diagnostica solo cuando `context` no es nulo, para no repetir errores
    /// entre la expansión de miembros y la de extensión.
    private static func validRole(
        of declaration: some DeclGroupSyntax,
        node: AttributeSyntax,
        in context: (any MacroExpansionContext)?
    ) -> RoleEnum? {
        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            context?.error("@Roles solo se aplica a un enum.", id: "roles.notEnum", at: node)
            return nil
        }
        guard let role = RoleEnum(enumDecl) else {
            context?.error(
                "`\(enumDecl.name.text)` debe declarar su categoría conformando exactamente a una de: \(RoleCategory.list).",
                id: "roles.noCategory", at: enumDecl.name)
            return nil
        }
        for element in enumDecl.memberBlock.members
            .compactMap({ $0.decl.as(EnumCaseDeclSyntax.self) })
            .flatMap(\.elements)
        {
            if element.parameterClause != nil || element.rawValue != nil {
                context?.error("Un rol no puede tener valores asociados ni raw value.", id: "roleSet.caseShape", at: element)
                return nil
            }
        }
        guard !role.cases.isEmpty else {
            context?.error("`\(role.name)` no declara ningún rol.", id: "roleSet.empty", at: enumDecl.name)
            return nil
        }
        return role
    }

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard !protocols.isEmpty, validRole(of: declaration, node: node, in: nil) != nil else { return [] }
        // Solo las conformances que falten: el compilador omite las que el enum ya declara.
        let conformances = protocols.map(\.trimmedDescription).joined(separator: ", ")
        return [try ExtensionDeclSyntax("extension \(type.trimmed): \(raw: conformances) {}")]
    }
}
