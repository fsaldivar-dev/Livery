//
//  Lint.swift
//  LiveryRegistryCore
//
//  Vigila los targets de UI: un valor suelto en una vista es una decisión de diseño que se tomó
//  fuera del sistema. Se aplica a los fuentes de un target con el plugin activo que no declara
//  roles, temas ni primitivos; los módulos del sistema de diseño quedan exentos por definición.
//
//  Marca como warning, con archivo y línea:
//  - Colores construidos a mano (`Color(red:…)`, `Color("nombre")`, `Color(hex:)`) y colores del
//    sistema (`Color.red`, `.foregroundStyle(.blue)`).
//  - Fuentes fuera del tema: `Font.system(size:)` y estilos de texto directos (`.font(.title)`).
//  - Medidas sueltas distintas de cero en `padding`, `spacing:` y `cornerRadius:`.
//

import SwiftParser
import SwiftSyntax

public struct Lint {
    public init() {}

    public func check(sources: [RegistryGenerator.Source]) -> [RegistryGenerator.Diagnostic] {
        sources.flatMap { source in
            let tree = Parser.parse(source: source.text)
            let visitor = LintVisitor(path: source.path, converter: SourceLocationConverter(fileName: source.path, tree: tree))
            visitor.walk(tree)
            return visitor.findings.sorted { ($0.line, $0.column) < ($1.line, $1.column) }
        }
    }
}

final class LintVisitor: SyntaxVisitor {
    var findings: [RegistryGenerator.Diagnostic] = []

    private let path: String
    private let converter: SourceLocationConverter

    init(path: String, converter: SourceLocationConverter) {
        self.path = path
        self.converter = converter
        super.init(viewMode: .sourceAccurate)
    }

    static let systemColors: Set<String> = [
        "red", "orange", "yellow", "green", "mint", "teal", "cyan", "blue", "indigo", "purple", "pink",
        "brown", "white", "gray", "black", "primary", "secondary", "accentColor",
    ]
    static let textStyles: Set<String> = [
        "largeTitle", "title", "title2", "title3", "headline", "subheadline", "body", "callout",
        "footnote", "caption", "caption2",
    ]
    static let styleModifiers: Set<String> = [
        "foregroundStyle", "foregroundColor", "background", "fill", "stroke", "tint", "border", "listRowBackground",
    ]
    static let lengthModifiers: Set<String> = ["padding"]
    static let lengthLabels: Set<String> = ["spacing", "cornerRadius"]

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        if let callee = node.calledExpression.as(DeclReferenceExprSyntax.self), callee.baseName.text == "Color" {
            // Color(red:…), Color("nombre"), Color(hex:), Color(.sRGB, …)
            let first = node.arguments.first
            let label = first?.label?.text
            let isLiteral = first?.expression.is(StringLiteralExprSyntax.self) == true
            if label == "red" || label == "hue" || label == "white" || label == "hex" || isLiteral || first?.expression.as(MemberAccessExprSyntax.self)?.declName.baseName.text == "sRGB" {
                report(node, "Color construido en la vista. Declara un rol y usa `.theme.color.<rol>`; los valores crudos viven en la paleta.")
            }
        }
        if let access = node.calledExpression.as(MemberAccessExprSyntax.self) {
            let name = access.declName.baseName.text
            if Self.styleModifiers.contains(name), let argument = node.arguments.first?.expression {
                if let member = argument.as(MemberAccessExprSyntax.self), member.base == nil,
                   Self.systemColors.contains(member.declName.baseName.text) {
                    report(argument, "Color del sistema `.\(member.declName.baseName.text)` en la vista. Usa `.theme.color.<rol>`.")
                }
            }
            if name == "font", let argument = node.arguments.first?.expression {
                if let member = argument.as(MemberAccessExprSyntax.self), member.base == nil, Self.textStyles.contains(member.declName.baseName.text) {
                    report(argument, "Estilo de texto `.\(member.declName.baseName.text)` fuera del tema. Usa `.theme.type.<rol>`.")
                }
                if let call = argument.as(FunctionCallExprSyntax.self),
                   let callee = call.calledExpression.as(MemberAccessExprSyntax.self), callee.declName.baseName.text == "system",
                   call.arguments.contains(where: { $0.label?.text == "size" }) {
                    report(argument, "Fuente con tamaño fijo. Usa `.theme.type.<rol>`, que escala con Dynamic Type.")
                }
            }
            if name == "system", access.base?.as(DeclReferenceExprSyntax.self)?.baseName.text == "Font",
               node.arguments.contains(where: { $0.label?.text == "size" }) {
                report(node, "Fuente con tamaño fijo. Usa `.theme.type.<rol>`, que escala con Dynamic Type.")
            }
            if Self.lengthModifiers.contains(name) {
                for argument in node.arguments where isNonZeroNumber(argument.expression) {
                    report(argument.expression, "Medida suelta en `\(name)`. Usa `.theme.space.<rol>`.")
                }
            }
        }
        if let member = node.calledExpression.as(MemberAccessExprSyntax.self),
           member.base?.as(DeclReferenceExprSyntax.self)?.baseName.text == "Color",
           Self.systemColors.contains(member.declName.baseName.text) {
            report(node, "Color del sistema `Color.\(member.declName.baseName.text)` en la vista. Usa `.theme.color.<rol>`.")
        }
        for argument in node.arguments {
            if let label = argument.label?.text, Self.lengthLabels.contains(label), isNonZeroNumber(argument.expression) {
                let hint = label == "cornerRadius" ? "`.theme.shape.<rol>`" : "`.theme.space.<rol>`"
                report(argument.expression, "Medida suelta en `\(label):`. Usa \(hint).")
            }
        }
        return .visitChildren
    }

    override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        // `Color.red` como valor, fuera de una llamada.
        if node.base?.as(DeclReferenceExprSyntax.self)?.baseName.text == "Color",
           Self.systemColors.contains(node.declName.baseName.text),
           node.parent?.as(FunctionCallExprSyntax.self) == nil {
            report(node, "Color del sistema `Color.\(node.declName.baseName.text)` en la vista. Usa `.theme.color.<rol>`.")
        }
        return .visitChildren
    }

    private func isNonZeroNumber(_ expression: ExprSyntax) -> Bool {
        if let integer = expression.as(IntegerLiteralExprSyntax.self) { return integer.literal.text != "0" }
        if let float = expression.as(FloatLiteralExprSyntax.self) { return Double(float.literal.text) != 0 }
        if let prefix = expression.as(PrefixOperatorExprSyntax.self) { return isNonZeroNumber(prefix.expression) }
        return false
    }

    private func report(_ node: some SyntaxProtocol, _ message: String) {
        let location = converter.location(for: node.positionAfterSkippingLeadingTrivia)
        findings.append(.init(path: path, line: location.line, column: location.column, severity: .warning, message: message))
    }
}
