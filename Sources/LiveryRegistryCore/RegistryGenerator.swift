//
//  RegistryGenerator.swift
//  LiveryRegistryCore
//
//  El `aapt` de Livery. Encuentra los `@Roles` y `@Theme` de un módulo y escribe lo que un macro
//  no puede escribir porque vive fuera del tipo que decora: la extensión de `Theme` con una
//  propiedad por conjunto de roles (`theme.color`) y un acceso estático por tema (`.light`).
//
//      extension Livery.Theme {
//          var color: Colors.Values { values(Colors.self) }
//          static var light: Livery.Theme { Light().resolvedTheme }
//      }
//
//  Lo ejecuta el build-tool plugin `LiveryRegistry` antes de compilar cada módulo.
//

import SwiftParser
import SwiftSyntax

public struct RegistryGenerator {

    public init() {}

    /// Un fuente a analizar.
    public struct Source {
        public var path: String
        public var text: String
        public init(path: String, text: String) {
            self.path = path
            self.text = text
        }
    }

    /// Lo que el generador produce: el archivo y los problemas encontrados.
    public struct Output: Equatable {
        public var code: String
        public var diagnostics: [Diagnostic]
        public var hasErrors: Bool { diagnostics.contains { $0.severity == .error } }
    }

    /// Un problema en el formato que Xcode y SwiftPM entienden: `ruta:línea:columna: error: mensaje`.
    public struct Diagnostic: Equatable, CustomStringConvertible {
        public enum Severity: String { case error, warning }
        public var path: String
        public var line: Int
        public var column: Int
        public var severity: Severity
        public var message: String
        public var description: String { "\(path):\(line):\(column): \(severity.rawValue): \(message)" }
    }

    public func generate(sources: [Source]) -> Output {
        var roles: [RoleSetDecl] = []
        var themes: [ThemeDecl] = []
        for source in sources {
            let tree = Parser.parse(source: source.text)
            let visitor = RegistryVisitor(path: source.path, converter: SourceLocationConverter(fileName: source.path, tree: tree))
            visitor.walk(tree)
            roles.append(contentsOf: visitor.roles)
            themes.append(contentsOf: visitor.themes)
        }

        var diagnostics: [Diagnostic] = []
        var seen: [RoleCategory: RoleSetDecl] = [:]
        var members: [String] = []

        for role in roles {
            if let previous = seen[role.category] {
                diagnostics.append(Diagnostic(
                    path: role.path, line: role.line, column: role.column, severity: .error,
                    message: "La categoría \(role.category.rawValue) ya está declarada por `\(previous.qualifiedName)` en \(previous.path):\(previous.line). Solo puede haber un conjunto de roles por categoría en el módulo."))
                continue
            }
            seen[role.category] = role
            members.append("    \(role.access)var \(role.category.property): \(role.qualifiedName).Values { values(\(role.qualifiedName).self) }")
        }

        for theme in themes {
            guard theme.isConstructible else {
                members.append("    // `\(theme.qualifiedName)` necesita argumentos: aplícalo con `.theme(\(theme.qualifiedName)(…))`.")
                continue
            }
            members.append("    \(theme.access)static var \(theme.accessorName): Livery.Theme { \(theme.qualifiedName)().resolvedTheme }")
        }

        var code = """
        // Generado por Livery (plugin LiveryRegistry). No editar.
        // Una propiedad por conjunto de roles @Roles y un acceso estático por tema @Theme del módulo.
        import Livery
        import SwiftUI

        """
        if members.isEmpty {
            code += "// (ningún @Roles ni @Theme en este módulo)\n"
        } else {
            code += "extension Livery.Theme {\n" + members.joined(separator: "\n") + "\n}\n"
        }
        return Output(code: code, diagnostics: diagnostics)
    }
}

// MARK: - Modelo

/// Las categorías que Livery conoce. Debe coincidir con `RoleCategory` en LiveryMacros.
enum RoleCategory: String, CaseIterable {
    case color = "ColorRoles"
    case type = "TypeRoles"
    case space = "SpaceRoles"
    case shape = "ShapeRoles"

    /// Nombre de la propiedad generada en `Theme`.
    var property: String { String(describing: self) }
}

struct RoleSetDecl {
    var qualifiedName: String
    var category: RoleCategory
    var access: String
    var path: String
    var line: Int
    var column: Int
}

struct ThemeDecl {
    var qualifiedName: String
    var accessorName: String
    var access: String
    var isConstructible: Bool
}

// MARK: - Visitor

final class RegistryVisitor: SyntaxVisitor {
    var roles: [RoleSetDecl] = []
    var themes: [ThemeDecl] = []

    private let path: String
    private let converter: SourceLocationConverter
    private var scope: [String] = []

    init(path: String, converter: SourceLocationConverter) {
        self.path = path
        self.converter = converter
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        if hasAttribute("Roles", in: node.attributes) {
            collectRoles(node)
        }
        return enter(node.name.text)
    }

    override func visitPost(_ node: EnumDeclSyntax) { leave() }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        if hasAttribute("Theme", in: node.attributes) {
            collectTheme(name: node.name.text, modifiers: node.modifiers, members: node.memberBlock,
                         isGeneric: node.genericParameterClause != nil, implicitInit: true)
        }
        return enter(node.name.text)
    }

    override func visitPost(_ node: StructDeclSyntax) { leave() }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        if hasAttribute("Theme", in: node.attributes) {
            collectTheme(name: node.name.text, modifiers: node.modifiers, members: node.memberBlock,
                         isGeneric: node.genericParameterClause != nil, implicitInit: true)
        }
        return enter(node.name.text)
    }

    override func visitPost(_ node: ClassDeclSyntax) { leave() }

    override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind { enter(node.name.text) }
    override func visitPost(_ node: ActorDeclSyntax) { leave() }

    override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind { enter(node.extendedType.trimmedDescription) }
    override func visitPost(_ node: ExtensionDeclSyntax) { leave() }

    // Los tipos locales a funciones no se pueden referenciar desde fuera.
    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind { .skipChildren }
    override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind { .skipChildren }
    override func visit(_ node: AccessorBlockSyntax) -> SyntaxVisitorContinueKind { .skipChildren }

    // MARK: Recolección

    private func collectRoles(_ node: EnumDeclSyntax) {
        let categories = (node.inheritanceClause?.inheritedTypes ?? []).compactMap {
            RoleCategory(rawValue: lastComponent(of: $0.type.trimmedDescription))
        }
        // Sin categoría o con varias, el macro ya lo diagnostica; aquí no hay nada que generar.
        guard categories.count == 1 else { return }
        let location = converter.location(for: node.name.positionAfterSkippingLeadingTrivia)
        roles.append(RoleSetDecl(
            qualifiedName: qualified(node.name.text),
            category: categories[0],
            access: node.modifiers.accessPrefix,
            path: path, line: location.line, column: location.column))
    }

    private func collectTheme(name: String, modifiers: DeclModifierListSyntax, members: MemberBlockSyntax,
                              isGeneric: Bool, implicitInit: Bool) {
        themes.append(ThemeDecl(
            qualifiedName: qualified(name),
            accessorName: Self.accessorName(for: name),
            access: modifiers.accessPrefix,
            isConstructible: !isGeneric && Self.isConstructibleWithoutArguments(members)))
    }

    /// Un tipo se puede construir con `Nombre()` si declara un `init()` no privado, o si no
    /// declara ningún `init` y todas sus propiedades almacenadas tienen valor inicial.
    static func isConstructibleWithoutArguments(_ members: MemberBlockSyntax) -> Bool {
        var hasExplicitInit = false
        var hasEmptyInit = false
        var hasStoredWithoutValue = false
        for member in members.members {
            if let initializer = member.decl.as(InitializerDeclSyntax.self) {
                hasExplicitInit = true
                let isPrivate = initializer.modifiers.contains {
                    $0.name.tokenKind == .keyword(.private) || $0.name.tokenKind == .keyword(.fileprivate)
                }
                if !isPrivate, initializer.signature.parameterClause.parameters.allSatisfy({ $0.defaultValue != nil }) {
                    hasEmptyInit = true
                }
            } else if let variable = member.decl.as(VariableDeclSyntax.self),
                      !variable.modifiers.contains(where: { $0.name.tokenKind == .keyword(.static) }) {
                for binding in variable.bindings where binding.accessorBlock == nil && binding.initializer == nil {
                    let isOptionalVar = variable.bindingSpecifier.tokenKind == .keyword(.var)
                        && binding.typeAnnotation?.type.is(OptionalTypeSyntax.self) == true
                    if !isOptionalVar { hasStoredWithoutValue = true }
                }
            }
        }
        return hasEmptyInit || (!hasExplicitInit && !hasStoredWithoutValue)
    }

    /// `Light` → `light`, `PlayerDense` → `playerDense`, `HTTPDark` → `httpDark`, `Default` → `` `default` ``.
    static func accessorName(for typeName: String) -> String {
        let characters = Array(typeName)
        var upperRun = 0
        while upperRun < characters.count, characters[upperRun].isUppercase { upperRun += 1 }
        let lowered: String
        if upperRun == 0 {
            lowered = typeName
        } else if upperRun == characters.count || upperRun == 1 {
            lowered = String(characters[..<upperRun]).lowercased() + String(characters[upperRun...])
        } else {
            // Acrónimo seguido de palabra: baja todo menos la última mayúscula, que empieza la palabra.
            lowered = String(characters[..<(upperRun - 1)]).lowercased() + String(characters[(upperRun - 1)...])
        }
        return Self.keywords.contains(lowered) ? "`\(lowered)`" : lowered
    }

    private static let keywords: Set<String> = [
        "associatedtype", "class", "deinit", "enum", "extension", "fileprivate", "func", "import", "init",
        "inout", "internal", "let", "operator", "private", "protocol", "public", "static", "struct",
        "subscript", "typealias", "var", "break", "case", "continue", "default", "defer", "do", "else",
        "fallthrough", "for", "guard", "if", "in", "repeat", "return", "switch", "where", "while", "as",
        "any", "catch", "false", "is", "nil", "rethrows", "self", "super", "throw", "throws", "true", "try",
    ]

    // MARK: Ámbito

    private func enter(_ name: String) -> SyntaxVisitorContinueKind {
        scope.append(name)
        return .visitChildren
    }

    private func leave() { scope.removeLast() }

    private func qualified(_ name: String) -> String { (scope + [name]).joined(separator: ".") }

    private func hasAttribute(_ name: String, in attributes: AttributeListSyntax) -> Bool {
        attributes.contains { element in
            guard let attribute = element.as(AttributeSyntax.self) else { return false }
            return lastComponent(of: attribute.attributeName.trimmedDescription) == name
        }
    }

    private func lastComponent(of typeName: String) -> String {
        typeName.split(separator: ".").last.map(String.init) ?? typeName
    }
}

extension DeclModifierListSyntax {
    /// `public ` o `package ` si el declarante lo es; vacío si es interno.
    var accessPrefix: String {
        for modifier in self {
            switch modifier.name.tokenKind {
            case .keyword(.public), .keyword(.open): return "public "
            case .keyword(.package): return "package "
            default: continue
            }
        }
        return ""
    }
}
