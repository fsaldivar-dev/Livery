import SwiftSyntax
import SwiftSyntaxMacros

/// `@Theme struct Light: Theme.Colors.Resolver, Theme.Spacing.Resolver { … }`
///
/// Lee las conformances a `Resolver` y genera `ThemeProvider.resolvedTheme` registrando la
/// resolución de cada conjunto.
public struct ThemeMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard declaration.is(StructDeclSyntax.self) || declaration.is(ClassDeclSyntax.self) || declaration.is(EnumDeclSyntax.self) else {
            context.error("@Theme solo se aplica a un struct, class o enum.", id: "theme.notNominal", at: node)
            return []
        }

        let roleSets = (declaration.inheritanceClause?.inheritedTypes ?? []).compactMap { inherited -> String? in
            let components = inherited.type.trimmedDescription.split(separator: ".").map(String.init)
            guard components.count >= 2, components.last == "Resolver" else { return nil }
            return components.dropLast().joined(separator: ".")
        }
        guard !roleSets.isEmpty else {
            context.error(
                "@Theme necesita al menos una conformance a un `Resolver` en la declaración, por ejemplo `Theme.Colors.Resolver`.",
                id: "theme.noResolvers", at: node)
            return []
        }
        guard !protocols.isEmpty else { return [] }

        let access = declaration.modifiers.accessPrefix
        let registrations = roleSets
            .map { "        theme.register(\($0).Values(self), for: \($0).self)" }
            .joined(separator: "\n")

        return [
            try ExtensionDeclSyntax(
                """
                extension \(type.trimmed): Livery.ThemeProvider {
                    \(raw: access)var resolvedTheme: Livery.Theme {
                        var theme = Livery.Theme()
                \(raw: registrations)
                        return theme
                    }
                }
                """
            )
        ]
    }
}

/// `@Primitives enum Palette { … }`: solo marca la paleta. No genera código todavía.
public struct PrimitivesMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        []
    }
}
