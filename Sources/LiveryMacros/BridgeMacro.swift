import SwiftSyntax
import SwiftSyntaxMacros

/// `@Bridge(from: ColorsV1.self, to: Colors.self) enum ColorsV1toV2 { … }`
///
/// Solo valida la forma: cada miembro es `static let viejo = Nuevo.rol` o
/// `static func viejo(_ values: Nuevo.Values) -> T`. La cobertura y la generación las hace el
/// plugin `LiveryRegistry`, que es quien ve los dos conjuntos de roles.
public struct BridgeMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            context.error("@Bridge solo se aplica a un enum.", id: "bridge.notEnum", at: node)
            return []
        }
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self),
              let toArgument = arguments.first(where: { $0.label?.text == "to" }),
              let to = BridgeShape.typeName(of: toArgument.expression)
        else {
            context.error("@Bridge necesita `from: Viejo.self, to: Nuevo.self`.", id: "bridge.arguments", at: node)
            return []
        }

        for member in enumDecl.memberBlock.members {
            if let variable = member.decl.as(VariableDeclSyntax.self) {
                guard BridgeShape.isStatic(variable.modifiers), variable.bindingSpecifier.tokenKind == .keyword(.let),
                      variable.bindings.count == 1, let binding = variable.bindings.first,
                      let value = binding.initializer?.value
                else {
                    context.error("Un miembro del puente es `static let viejo = \(to).rol` o `static func viejo(_ values: \(to).Values) -> T`.", id: "bridge.member", at: member.decl)
                    continue
                }
                if BridgeShape.renameTarget(of: value, in: to) == nil {
                    context.error("El valor debe ser un rol de `\(to)`, por ejemplo `\(to).brand`. Para calcularlo usa `static func`.", id: "bridge.value", at: value)
                }
            } else if let function = member.decl.as(FunctionDeclSyntax.self) {
                let parameters = function.signature.parameterClause.parameters
                guard BridgeShape.isStatic(function.modifiers), parameters.count == 1, function.signature.returnClause != nil else {
                    context.error("Un `func` del puente es `static func viejo(_ values: \(to).Values) -> T`.", id: "bridge.function", at: function.name)
                    continue
                }
            } else if member.decl.is(EnumCaseDeclSyntax.self) {
                context.error("Un puente no declara casos; declara `static let` o `static func` por cada rol viejo.", id: "bridge.case", at: member.decl)
            }
        }
        return []
    }
}

/// Lectura sintáctica compartida con el generador del plugin (duplicada allí a propósito: son módulos distintos).
enum BridgeShape {
    static func isStatic(_ modifiers: DeclModifierListSyntax) -> Bool {
        modifiers.contains { $0.name.tokenKind == .keyword(.static) }
    }

    /// `Colors.self` → `Colors`; `DS.Colors.self` → `DS.Colors`.
    static func typeName(of expression: ExprSyntax) -> String? {
        guard let access = expression.as(MemberAccessExprSyntax.self), access.declName.baseName.text == "self",
              let base = access.base
        else { return nil }
        return base.trimmedDescription
    }

    /// `Colors.brand` → `brand` si la base termina en `to`.
    static func renameTarget(of expression: ExprSyntax, in to: String) -> String? {
        guard let access = expression.as(MemberAccessExprSyntax.self), let base = access.base else { return nil }
        let baseName = base.trimmedDescription.split(separator: ".").last.map(String.init)
        let toName = to.split(separator: ".").last.map(String.init)
        guard baseName == toName else { return nil }
        return access.declName.baseName.text
    }
}
