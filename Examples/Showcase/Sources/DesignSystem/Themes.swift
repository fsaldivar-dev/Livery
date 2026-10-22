//
//  Themes.swift
//  DesignSystem
//
//  Cómo se resuelve. Cada tema conforma a los `Resolver` que cubre; si olvida un rol, el
//  compilador lo señala aquí. Un color es un `Shade`: claro y oscuro decididos siempre.
//

import Livery
import Primitives
import SwiftUI

/// El tema de la app: claro por defecto, oscuro sobrio.
@Theme public struct Daylight: Colors.Resolver, Typography.Resolver, Spacing.Resolver, Shapes.Resolver {
    public init() {}

    public let surface            = Shade(light: Palette.mist, dark: Palette.ink)
    public let surfaceElevated    = Shade(light: Palette.white, dark: Palette.graphite)
    public let onSurface          = Shade(light: Palette.ink, dark: Palette.mist)
    public let onSurfaceSecondary = Shade(light: Palette.slate, dark: Palette.fog, darkIncreased: Palette.mist)
    public let accent             = Shade(light: Palette.jade500, dark: Palette.jade300)
    public let onAccent           = Shade(light: Palette.white, dark: Palette.ink)
    public let outline            = Shade(light: Palette.fog, dark: Palette.slate)
    public let danger             = Shade(light: Palette.red500, dark: Palette.red300)

    public let title    = Font.title.weight(.semibold)
    public let headline = Font.headline
    public let body     = Font.body
    public let caption  = Font.caption

    public let xs = Metrics.unit
    public let sm = Metrics.unit * 2
    public let md = Metrics.unit * 4
    public let lg = Metrics.unit * 6
    public let xl = Metrics.unit * 10

    public let small: CGFloat  = 6
    public let medium: CGFloat = 12
    public let large: CGFloat  = 20
}

/// Un rebrand completo: misma estructura, otra pintura. Hereda tipografía, espacio y forma
/// de Daylight porque se aplica con `.theme(adding:)` sobre él.
@Theme public struct Carbon: Colors.Resolver {
    public init() {}

    public let surface            = Shade(light: Palette.fog, dark: Palette.ink)
    public let surfaceElevated    = Shade(light: Palette.mist, dark: Palette.graphite)
    public let onSurface          = Shade(light: Palette.graphite, dark: Palette.white)
    public let onSurfaceSecondary = Shade(light: Palette.slate, dark: Palette.fog)
    public let accent             = Shade(light: Palette.orange500, dark: Palette.orange300)
    public let onAccent           = Shade(Palette.ink)
    public let outline            = Shade(light: Palette.slate, dark: Palette.slate)
    public let danger             = Shade(light: Palette.red500, dark: Palette.red300)
}

/// Solo espaciado: se suma al tema activo con `.theme(adding: .dense)`.
@Theme public struct Dense: Spacing.Resolver {
    public init() {}

    public let xs = Metrics.unit / 2
    public let sm = Metrics.unit
    public let md = Metrics.unit * 2
    public let lg = Metrics.unit * 3
    public let xl = Metrics.unit * 5
}

/// Un tema con parámetros: no recibe acceso corto; se aplica con `.theme(adding: Brand(accent:))`.
@Theme public struct Brand: Colors.Resolver {
    public init(accent: Shade) {
        self.accent = accent
    }

    public let accent: Shade
    public let surface            = Shade(light: Palette.mist, dark: Palette.ink)
    public let surfaceElevated    = Shade(light: Palette.white, dark: Palette.graphite)
    public let onSurface          = Shade(light: Palette.ink, dark: Palette.mist)
    public let onSurfaceSecondary = Shade(light: Palette.slate, dark: Palette.fog)
    public let onAccent           = Shade(Palette.white)
    public let outline            = Shade(light: Palette.fog, dark: Palette.slate)
    public let danger             = Shade(light: Palette.red500, dark: Palette.red300)
}
