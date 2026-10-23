// Generado por Livery (plugin LiveryRegistry). No editar.
// Una propiedad por conjunto de roles @Roles, un acceso estático por tema @Theme y los reenvíos de cada @Bridge del módulo.
import Livery
import SwiftUI
extension Livery.Theme {
    public var color: Colors.Values { values(Colors.self) }
    public var type: Typography.Values { values(Typography.self) }
    public var space: Spacing.Values { values(Spacing.self) }
    public var shape: Shapes.Values { values(Shapes.self) }
    public var motion: Motions.Values { values(Motions.self) }
    public var elevation: Elevations.Values { values(Elevations.self) }
    public var button: Button.Style { style(for: Button.self) ?? Button.unstyled }
    public var field: Field.Style { style(for: Field.self) ?? Field.unstyled }
    public static var daylight: Livery.Theme { Daylight().resolvedTheme }
    public static var carbon: Livery.Theme { Carbon().resolvedTheme }
    public static var dense: Livery.Theme { Dense().resolvedTheme }
    // `Brand` necesita argumentos: aplícalo con `.environment(\.theme, Brand(…).resolvedTheme)`.
}

extension Livery.Theme {
    /// Exporta este tema a W3C Design Tokens (JSON) para Penpot y Figma.
    public func w3cTokens(mode: Livery.TokenMode = .light) -> String {
        let document = Livery.W3CDocument()
        for role in Colors.allCases { document.color("color", String(describing: role), self.color[role], mode: mode) }
        for role in Typography.allCases { document.typography("font", String(describing: role), self.type[role]) }
        for role in Spacing.allCases { document.dimension("spacing", String(describing: role), self.space[role]) }
        for role in Shapes.allCases { document.dimension("radius", String(describing: role), self.shape[role]) }
        // Motions: el movimiento no tiene token W3C estándar; se omite.
        for role in Elevations.allCases { document.shadow("shadow", String(describing: role), self.elevation[role], mode: mode) }
        return document.json
    }
}

extension Livery.Theme {
    /// Pares de color `onX`/`X` que no llegan al contraste WCAG, en claro y oscuro.
    public func contrastReport(_ level: Livery.WCAGLevel = .AA) -> [Livery.ContrastIssue] {
        Livery.ContrastChecker.check(Colors.allCases.map { (String(describing: $0), self.color[$0]) }, level: level)
    }
}

extension Colors.Values {
    @available(*, deprecated, renamed: "accent")
    public var primary: Livery.Shade { accent }
    @available(*, deprecated, renamed: "surfaceElevated")
    public var cardBackground: Livery.Shade { surfaceElevated }
    @available(*, deprecated, message: "`divider` ya no existe en Colors; lo calcula ColorsV1toV2.divider. DS2 eliminó el divisor; usa `outline`.")
    public var divider: Livery.Shade { ColorsV1toV2.divider(self) }
}
