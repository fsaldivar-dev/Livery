//
//  Legacy.swift
//  DesignSystem
//
//  Una migración en curso. `ColorsV1` es el sistema anterior; las vistas que todavía lo leen
//  siguen compilando gracias al puente, con un warning y fix-it en cada uso. Cuando el plugin
//  avise "0 usos pendientes", se borra este archivo entero.
//

import Livery

@Roles public enum ColorsV1: ColorRoles {
    case primary, cardBackground, divider, onSurface
}

@Bridge(from: ColorsV1.self, to: Colors.self)
public enum ColorsV1toV2 {
    public static let primary        = Colors.accent
    public static let cardBackground = Colors.surfaceElevated
    /// DS2 eliminó el divisor; usa `outline`.
    public static func divider(_ colors: Colors.Values) -> Shade { colors.outline }
}
