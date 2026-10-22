import SwiftSyntax
import SwiftSyntaxMacros

/// `@Theme struct Light: Colors.Resolver, Spacing.Resolver { … }`
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

        let inherited = (declaration.inheritanceClause?.inheritedTypes ?? []).map {
            $0.type.trimmedDescription.split(separator: ".").map(String.init)
        }
        let roleSets = inherited.compactMap { components -> String? in
            guard components.count >= 2, components.last == "Resolver" else { return nil }
            return components.dropLast().joined(separator: ".")
        }
        // `Button.Styler` exige `var button: Button.Style`; se registra con el tipo del contrato como clave.
        let stylers = inherited.compactMap { components -> String? in
            guard components.count >= 2, components.last == "Styler" else { return nil }
            return components.dropLast().joined(separator: ".")
        }
        guard !roleSets.isEmpty else {
            context.error(
                "@Theme necesita al menos una conformance a un `Resolver` en la declaración, por ejemplo `Colors.Resolver`.",
                id: "theme.noResolvers", at: node)
            return []
        }
        guard !protocols.isEmpty else { return [] }

        let access = declaration.modifiers.accessPrefix
        let registrations = (roleSets.map { "        theme.register(\($0).Values(self), for: \($0).self)" }
            + stylers.map { "        theme.register(style: self.\(Self.propertyName(for: $0)), for: \($0).self)" })
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

extension ThemeMacro {
    /// `Button` → `button`, `DS.IconButton` → `iconButton`.
    static func propertyName(for qualifiedType: String) -> String {
        let name = qualifiedType.split(separator: ".").last.map(String.init) ?? qualifiedType
        guard let first = name.first else { return name }
        return first.lowercased() + name.dropFirst()
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
