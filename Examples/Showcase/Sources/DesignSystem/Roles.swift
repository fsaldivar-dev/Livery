//
//  Roles.swift
//  DesignSystem
//
//  Qué existe. Nombres de intención: una vista pide `accent`, nunca `jade500`.
//  `CaseIterable` no lo necesita Livery; lo usa la galería para recorrer los roles.
//

import Livery

@Roles public enum Colors: ColorRoles, CaseIterable {
    case surface, surfaceElevated, onSurface, onSurfaceSecondary
    case accent, onAccent, outline, danger
}

@Roles public enum Typography: TypeRoles, CaseIterable {
    case title, headline, body, caption
}

@Roles public enum Spacing: SpaceRoles, CaseIterable {
    case xs, sm, md, lg, xl
}

@Roles public enum Shapes: ShapeRoles, CaseIterable {
    case small, medium, large
}

@Roles public enum Motions: MotionRoles, CaseIterable {
    case quick, normal, slow
}

@Roles public enum Elevations: ElevationRoles, CaseIterable {
    case card, popover
}

@Roles public enum Icons: IconRoles, CaseIterable {
    case play, delete, favorite, notification, search
}
