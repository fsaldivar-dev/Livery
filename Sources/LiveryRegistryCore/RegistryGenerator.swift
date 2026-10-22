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
//  Y por cada `@Bridge(from: ColorsV1.self, to: Colors.self)`, los reenvíos deprecados que hacen
//  que una vista que lee `theme.color.primary` siga compilando y reciba `brand`:
//
//      extension Colors.Values {
//          @available(*, deprecated, renamed: "brand")
//          var primary: Livery.Shade { brand }
//      }
//
//  Lo ejecuta el build-tool plugin `LiveryRegistry` antes de compilar cada módulo.
//

import Foundation
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

    /// - Parameters:
    ///   - sources: los fuentes del módulo: de aquí salen las declaraciones.
    ///   - usages: fuentes de otros módulos del paquete, solo para contar usos pendientes de un puente.
    public func generate(sources: [Source], usages: [Source] = []) -> Output {
        var roles: [RoleSetDecl] = []
        var themes: [ThemeDecl] = []
        var bridges: [BridgeDecl] = []
        for source in sources {
            let tree = Parser.parse(source: source.text)
            let visitor = RegistryVisitor(path: source.path, converter: SourceLocationConverter(fileName: source.path, tree: tree))
            visitor.walk(tree)
            roles.append(contentsOf: visitor.roles)
            themes.append(contentsOf: visitor.themes)
            bridges.append(contentsOf: visitor.bridges)
        }

        var diagnostics: [Diagnostic] = []
        var members: [String] = []
        var extensions: [String] = []

        // Un conjunto que es `from` de un puente es legado: no ocupa su categoría.
        let legacy = Set(bridges.map { Self.lastComponent($0.from) })
        var seen: [RoleCategory: RoleSetDecl] = [:]
        for role in roles where !legacy.contains(Self.lastComponent(role.qualifiedName)) {
            if let previous = seen[role.category] {
                diagnostics.append(Diagnostic(
                    path: role.path, line: role.line, column: role.column, severity: .error,
                    message: "La categoría \(role.category.rawValue) ya está declarada por `\(previous.qualifiedName)` en \(previous.path):\(previous.line). Solo puede haber un conjunto de roles por categoría en el módulo. Si `\(previous.qualifiedName)` es la versión vieja, declara un @Bridge."))
                continue
            }
            seen[role.category] = role
            members.append("    \(role.access)var \(role.category.property): \(role.qualifiedName).Values { values(\(role.qualifiedName).self) }")
        }

        for theme in themes {
            guard theme.isConstructible else {
                members.append("    // `\(theme.qualifiedName)` necesita argumentos: aplícalo con `.environment(\\.theme, \(theme.qualifiedName)(…).resolvedTheme)`.")
                continue
            }
            members.append("    \(theme.access)static var \(theme.accessorName): Livery.Theme { \(theme.qualifiedName)().resolvedTheme }")
        }

        for bridge in bridges {
            if let generated = Self.expand(bridge, roles: roles, sources: sources + usages, diagnostics: &diagnostics) {
                extensions.append(generated)
            }
        }

        // Un módulo sin declaraciones es un módulo de UI: se vigila que no decida valores por su cuenta.
        if roles.isEmpty && themes.isEmpty && bridges.isEmpty && !sources.contains(where: { $0.text.contains("@Primitives") }) {
            diagnostics.append(contentsOf: Lint().check(sources: sources))
        }

        var code = """
        // Generado por Livery (plugin LiveryRegistry). No editar.
        // Una propiedad por conjunto de roles @Roles, un acceso estático por tema @Theme y los reenvíos de cada @Bridge del módulo.
        import Livery
        import SwiftUI

        """
        if members.isEmpty && extensions.isEmpty {
            code += "// (ningún @Roles, @Theme ni @Bridge en este módulo)\n"
        }
        if !members.isEmpty {
            code += "extension Livery.Theme {\n" + members.joined(separator: "\n") + "\n}\n"
        }
        for ext in extensions {
            code += "\n" + ext
        }
        return Output(code: code, diagnostics: diagnostics)
    }

    // MARK: - Puentes

    /// Verifica un puente contra los dos conjuntos y produce `extension Nuevo.Values { … }`.
    static func expand(_ bridge: BridgeDecl, roles: [RoleSetDecl], sources: [Source], diagnostics: inout [Diagnostic]) -> String? {
        func error(_ message: String, line: Int? = nil, column: Int? = nil) {
            diagnostics.append(Diagnostic(path: bridge.path, line: line ?? bridge.line, column: column ?? bridge.column, severity: .error, message: message))
        }
        guard let from = roles.first(where: { lastComponent($0.qualifiedName) == lastComponent(bridge.from) }) else {
            error("No hay ningún `@Roles enum \(bridge.from)` en este módulo."); return nil
        }
        guard let to = roles.first(where: { lastComponent($0.qualifiedName) == lastComponent(bridge.to) }) else {
            error("No hay ningún `@Roles enum \(bridge.to)` en este módulo."); return nil
        }
        guard from.category == to.category else {
            error("`\(from.qualifiedName)` es \(from.category.rawValue) y `\(to.qualifiedName)` es \(to.category.rawValue): un puente une dos conjuntos de la misma categoría."); return nil
        }

        let kept = Set(from.cases).intersection(to.cases)
        var valid = true
        for member in bridge.members {
            if kept.contains(member.name) {
                error("`\(member.name)` existe en `\(to.qualifiedName)` con el mismo nombre; no necesita puente.", line: member.line, column: member.column); valid = false
            } else if !from.cases.contains(member.name) {
                error("`\(member.name)` no es un rol de `\(from.qualifiedName)`.", line: member.line, column: member.column); valid = false
            }
            if case .rename(let target) = member.kind, !to.cases.contains(target) {
                error("`\(to.qualifiedName)` no tiene el rol `\(target)`.", line: member.line, column: member.column); valid = false
            }
        }
        let covered = Set(bridge.members.map(\.name))
        let missing = from.cases.filter { !kept.contains($0) && !covered.contains($0) }
        if !missing.isEmpty {
            error("El puente no cubre: \(missing.joined(separator: ", ")). Cada rol de `\(from.qualifiedName)` que no exista en `\(to.qualifiedName)` necesita un `static let` o un `static func`."); valid = false
        }
        guard valid else { return nil }

        // Reporte: cuántos usos `.<categoría>.<rolViejo>` quedan fuera del propio puente.
        var usesByRole: [String: Int] = [:]
        var files = Set<String>()
        for source in sources where source.path != bridge.path {
            for member in bridge.members {
                let pattern = "\\.\(to.category.property)\\.\(member.name)\\b"
                let count = source.text.ranges(of: try! Regex(pattern)).count
                if count > 0 { usesByRole[member.name, default: 0] += count; files.insert(source.path) }
            }
        }
        let total = usesByRole.values.reduce(0, +)
        let summary: String
        if total == 0 {
            summary = "Migración \(from.qualifiedName) → \(to.qualifiedName): 0 usos pendientes. Puedes borrar `\(from.qualifiedName)` y este puente."
        } else {
            let detail = bridge.members.compactMap { m in usesByRole[m.name].map { "\(m.name): \($0)" } }.joined(separator: ", ")
            summary = "Migración \(from.qualifiedName) → \(to.qualifiedName): \(total) usos pendientes en \(files.count) archivo\(files.count == 1 ? "" : "s") (\(detail))."
        }
        diagnostics.append(Diagnostic(path: bridge.path, line: bridge.line, column: bridge.column, severity: .warning, message: summary))

        var lines = ["extension \(to.qualifiedName).Values {"]
        for member in bridge.members {
            switch member.kind {
            case .rename(let target):
                lines.append("    @available(*, deprecated, renamed: \"\(target)\")")
                lines.append("    \(to.access)var \(member.name): \(to.category.valueType) { \(target) }")
            case .computed:
                let note = member.documentation.map { " \($0)" } ?? ""
                let message = "`\(member.name)` ya no existe en \(to.qualifiedName); lo calcula \(bridge.qualifiedName).\(member.name).\(note)"
                lines.append("    @available(*, deprecated, message: \"\(message.replacingOccurrences(of: "\"", with: "\\\""))\")")
                lines.append("    \(to.access)var \(member.name): \(to.category.valueType) { \(bridge.qualifiedName).\(member.name)(self) }")
            }
        }
        lines.append("}")
        return lines.joined(separator: "\n") + "\n"
    }

    static func lastComponent(_ name: String) -> String {
        name.split(separator: ".").last.map(String.init) ?? name
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

    /// Tipo de cada rol. Debe coincidir con LiveryMacros.
    var valueType: String {
        switch self {
        case .color: "Livery.Shade"
        case .type: "SwiftUI.Font"
        case .space, .shape: "CGFloat"
        }
    }
}

struct BridgeDecl {
    struct Member {
        enum Kind { case rename(String), computed }
        var name: String
        var kind: Kind
        var documentation: String?
        var line: Int
        var column: Int
    }
    var qualifiedName: String
    var from: String
    var to: String
    var members: [Member]
    var path: String
    var line: Int
    var column: Int
}

struct RoleSetDecl {
    var qualifiedName: String
    var category: RoleCategory
    var cases: [String]
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
    var bridges: [BridgeDecl] = []

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
        if let bridge = attribute("Bridge", in: node.attributes) {
            collectBridge(node, attribute: bridge)
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
        let cases = node.memberBlock.members
            .compactMap { $0.decl.as(EnumCaseDeclSyntax.self) }
            .flatMap { $0.elements.map { $0.name.text } }
        roles.append(RoleSetDecl(
            qualifiedName: qualified(node.name.text),
            category: categories[0],
            cases: cases,
            access: node.modifiers.accessPrefix,
            path: path, line: location.line, column: location.column))
    }

    private func collectBridge(_ node: EnumDeclSyntax, attribute: AttributeSyntax) {
        guard let arguments = attribute.arguments?.as(LabeledExprListSyntax.self),
              let from = arguments.first(where: { $0.label?.text == "from" }).flatMap({ Self.selfTypeName($0.expression) }),
              let to = arguments.first(where: { $0.label?.text == "to" }).flatMap({ Self.selfTypeName($0.expression) })
        else { return } // el macro ya diagnostica los argumentos
        var members: [BridgeDecl.Member] = []
        for member in node.memberBlock.members {
            if let variable = member.decl.as(VariableDeclSyntax.self),
               let binding = variable.bindings.first,
               let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
               let value = binding.initializer?.value.as(MemberAccessExprSyntax.self) {
                let location = converter.location(for: binding.positionAfterSkippingLeadingTrivia)
                members.append(.init(name: name, kind: .rename(value.declName.baseName.text), documentation: nil,
                                     line: location.line, column: location.column))
            } else if let function = member.decl.as(FunctionDeclSyntax.self) {
                let location = converter.location(for: function.name.positionAfterSkippingLeadingTrivia)
                members.append(.init(name: function.name.text, kind: .computed, documentation: Self.documentation(of: function.leadingTrivia),
                                     line: location.line, column: location.column))
            }
        }
        let location = converter.location(for: node.name.positionAfterSkippingLeadingTrivia)
        bridges.append(BridgeDecl(qualifiedName: qualified(node.name.text), from: from, to: to, members: members,
                                  path: path, line: location.line, column: location.column))
    }

    /// `Colors.self` → `Colors`.
    static func selfTypeName(_ expression: ExprSyntax) -> String? {
        guard let access = expression.as(MemberAccessExprSyntax.self), access.declName.baseName.text == "self",
              let base = access.base else { return nil }
        return base.trimmedDescription
    }

    /// Las líneas `///` de un miembro, unidas en una frase.
    static func documentation(of trivia: Trivia) -> String? {
        let lines = trivia.compactMap { piece -> String? in
            if case .docLineComment(let text) = piece {
                return text.dropFirst(3).trimmingCharacters(in: .whitespaces)
            }
            return nil
        }
        return lines.isEmpty ? nil : lines.joined(separator: " ")
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
        attribute(name, in: attributes) != nil
    }

    private func attribute(_ name: String, in attributes: AttributeListSyntax) -> AttributeSyntax? {
        for element in attributes {
            guard let attribute = element.as(AttributeSyntax.self) else { continue }
            if lastComponent(of: attribute.attributeName.trimmedDescription) == name { return attribute }
        }
        return nil
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
