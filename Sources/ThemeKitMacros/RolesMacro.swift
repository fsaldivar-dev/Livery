import SwiftSyntax
import SwiftSyntaxMacros

/// `@Roles extension Theme { … }`
///
/// Adjunta `@_RoleSet` a cada enum de roles y añade a `Theme` una propiedad por categoría
/// (`color`, `type`, `space`, `shape`) que devuelve la resolución del tema activo.
public struct RolesMacro: MemberMacro, MemberAttributeMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let roleEnums = validated(declaration, node: node, in: context) else { return [] }
        return roleEnums.map { role in
            """
            \(raw: role.access)var \(raw: role.category.property): \(raw: role.name).Values { values(\(raw: role.name).self) }
            """
        }
    }

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingAttributesFor member: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AttributeSyntax] {
        guard let enumDecl = member.as(EnumDeclSyntax.self), RoleEnum(enumDecl) != nil else { return [] }
        return ["@_RoleSet"]
    }

    /// Comprueba que es una `extension Theme` y que cada enum declara una categoría, sin repetir.
    private static func validated(
        _ declaration: some DeclGroupSyntax,
        node: AttributeSyntax,
        in context: some MacroExpansionContext
    ) -> [RoleEnum]? {
        guard let ext = declaration.as(ExtensionDeclSyntax.self),
              ext.extendedType.trimmedDescription.split(separator: ".").last == "Theme"
        else {
            context.error("@Roles solo se aplica a `extension Theme`.", id: "roles.notTheme", at: node)
            return nil
        }

        var roles: [RoleEnum] = []
        var seen: [RoleCategory: String] = [:]
        var valid = true
        for member in ext.memberBlock.members {
            guard let enumDecl = member.decl.as(EnumDeclSyntax.self) else { continue }
            guard let role = RoleEnum(enumDecl) else {
                context.error(
                    "`\(enumDecl.name.text)` debe declarar su categoría conformando exactamente a una de: \(RoleCategory.list).",
                    id: "roles.noCategory", at: enumDecl.name)
                valid = false
                continue
            }
            if let previous = seen[role.category] {
                context.error(
                    "La categoría \(role.category.rawValue) ya está declarada por `\(previous)`. Solo puede haber un conjunto de roles por categoría.",
                    id: "roles.duplicateCategory", at: enumDecl.name)
                valid = false
                continue
            }
            seen[role.category] = role.name
            roles.append(role)
        }
        return valid ? roles : nil
    }
}
