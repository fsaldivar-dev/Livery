import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

/// Las categorías que el kernel conoce. El nombre de la propiedad en `Theme` y el tipo de valor
/// los fija el kernel; los roles dentro de cada una los pone el proyecto.
enum RoleCategory: String, CaseIterable {
    case color = "ColorRoles"
    case type = "TypeRoles"
    case space = "SpaceRoles"
    case shape = "ShapeRoles"

    /// Tipo de cada rol, cualificado para no chocar con tipos anidados del usuario.
    var valueType: String {
        switch self {
        case .color: "Livery.Shade"
        case .type: "SwiftUI.Font"
        case .space, .shape: "CoreFoundation.CGFloat"
        }
    }

    /// Valor de reserva, deliberadamente visible, cuando el tema activo no resuelve el conjunto.
    var placeholder: String {
        switch self {
        case .color: "Livery.Shade.unresolved"
        case .type: "SwiftUI.Font.body"
        case .space, .shape: "0"
        }
    }

    /// La categoría declarada en la cláusula de herencia de un enum, si hay exactamente una.
    static func declared(by enumDecl: EnumDeclSyntax) -> RoleCategory? {
        let names = (enumDecl.inheritanceClause?.inheritedTypes ?? []).compactMap { inherited -> RoleCategory? in
            let name = inherited.type.trimmedDescription
                .split(separator: ".").last.map(String.init) ?? ""
            return RoleCategory(rawValue: name)
        }
        return names.count == 1 ? names[0] : nil
    }

    static var list: String {
        allCases.map(\.rawValue).joined(separator: ", ")
    }
}

/// Un enum de roles ya leído: su nombre, categoría y casos.
struct RoleEnum {
    let name: String
    let category: RoleCategory
    let cases: [String]
    let access: String

    init?(_ decl: EnumDeclSyntax) {
        guard let category = RoleCategory.declared(by: decl) else { return nil }
        self.name = decl.name.text
        self.category = category
        self.cases = decl.memberBlock.members
            .compactMap { $0.decl.as(EnumCaseDeclSyntax.self) }
            .flatMap { $0.elements.map { $0.name.text } }
        self.access = decl.modifiers.accessPrefix
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

struct LiveryDiagnostic: DiagnosticMessage {
    let message: String
    let id: String
    var severity: DiagnosticSeverity = .error

    var diagnosticID: MessageID { MessageID(domain: "Livery", id: id) }
}

extension MacroExpansionContext {
    func error(_ message: String, id: String, at node: some SyntaxProtocol) {
        diagnose(Diagnostic(node: node, message: LiveryDiagnostic(message: message, id: id)))
    }
}
