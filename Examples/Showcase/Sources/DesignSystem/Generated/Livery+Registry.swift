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
    public var button: Button.Style { style(for: Button.self) ?? Button.unstyled }
    public static var daylight: Livery.Theme { Daylight().resolvedTheme }
    public static var carbon: Livery.Theme { Carbon().resolvedTheme }
    public static var dense: Livery.Theme { Dense().resolvedTheme }
    // `Brand` necesita argumentos: aplícalo con `.environment(\.theme, Brand(…).resolvedTheme)`.
}

extension Colors.Values {
    @available(*, deprecated, renamed: "accent")
    public var primary: Livery.Shade { accent }
    @available(*, deprecated, renamed: "surfaceElevated")
    public var cardBackground: Livery.Shade { surfaceElevated }
    @available(*, deprecated, message: "`divider` ya no existe en Colors; lo calcula ColorsV1toV2.divider. DS2 eliminó el divisor; usa `outline`.")
    public var divider: Livery.Shade { ColorsV1toV2.divider(self) }
}
