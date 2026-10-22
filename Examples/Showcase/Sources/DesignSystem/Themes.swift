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

/// El tema de la app: papel y tinta, acento índigo.
@Theme public struct Daylight: Colors.Resolver, Typography.Resolver, Spacing.Resolver, Shapes.Resolver, Button.Styler {
    public init() {}

    /// El botón, en roles: sirve igual para Carbon, que solo cambia los colores.
    public var button: Button.Style {
        Button.Style(
            primary:     Button.Look(background: .accent,          foreground: .onAccent),
            secondary:   Button.Look(background: .surfaceElevated, foreground: .onSurface, border: .outline, icon: .accent),
            destructive: Button.Look(background: .surfaceElevated, foreground: .danger,    border: .danger),

            small:  Button.Metrics(font: .caption,  vertical: .xs, horizontal: .sm, radius: .small),
            medium: Button.Metrics(font: .headline, vertical: .sm, horizontal: .md, radius: .small),
            large:  Button.Metrics(font: .headline, vertical: .md, horizontal: .lg, radius: .medium),

            pressed:  Button.Effect(opacity: 0.7),
            disabled: Button.Effect(opacity: 0.4)
        )
    }

    public let surface            = Shade(light: Palette.slate50, dark: Palette.slate950)
    public let surfaceElevated    = Shade(light: Palette.white, dark: Palette.slate900)
    public let onSurface          = Shade(light: Palette.slate900, dark: Palette.slate100)
    public let onSurfaceSecondary = Shade(light: Palette.slate500, dark: Palette.slate400, darkIncreased: Palette.slate300)
    public let accent             = Shade(light: Palette.indigo600, dark: Palette.indigo400)
    public let onAccent           = Shade(light: Palette.white, dark: Palette.slate950)
    public let outline            = Shade(light: Palette.slate200, dark: Palette.slate800)
    public let danger             = Shade(light: Palette.rose600, dark: Palette.rose400)

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

/// Un rebrand completo: misma estructura, otra pintura. Grafito y ámbar. Hereda tipografía,
/// espacio y forma de Daylight porque se aplica sumado a él.
@Theme public struct Carbon: Colors.Resolver {
    public init() {}

    public let surface            = Shade(light: Palette.slate200, dark: Palette.slate950)
    public let surfaceElevated    = Shade(light: Palette.slate50, dark: Palette.slate800)
    public let onSurface          = Shade(light: Palette.slate900, dark: Palette.slate50)
    public let onSurfaceSecondary = Shade(light: Palette.slate600, dark: Palette.slate400)
    public let accent             = Shade(light: Palette.amber500, dark: Palette.amber400)
    public let onAccent           = Shade(Palette.slate950)
    public let outline            = Shade(light: Palette.slate300, dark: Palette.slate700)
    public let danger             = Shade(light: Palette.rose600, dark: Palette.rose400)
}

/// Solo espaciado: se suma al tema activo con `.environment(\.theme, adding: .dense)`.
@Theme public struct Dense: Spacing.Resolver {
    public init() {}

    public let xs = Metrics.unit / 2
    public let sm = Metrics.unit
    public let md = Metrics.unit * 2
    public let lg = Metrics.unit * 3
    public let xl = Metrics.unit * 5
}

/// Un tema con parámetros: no recibe acceso corto; se aplica con `.environment(\.theme, adding: Brand(accent:))`.
@Theme public struct Brand: Colors.Resolver {
    public init(accent: Shade) {
        self.accent = accent
    }

    public let accent: Shade
    public let surface            = Shade(light: Palette.slate50, dark: Palette.slate950)
    public let surfaceElevated    = Shade(light: Palette.white, dark: Palette.slate900)
    public let onSurface          = Shade(light: Palette.slate900, dark: Palette.slate100)
    public let onSurfaceSecondary = Shade(light: Palette.slate500, dark: Palette.slate400)
    public let onAccent           = Shade(Palette.white)
    public let outline            = Shade(light: Palette.slate200, dark: Palette.slate800)
    public let danger             = Shade(light: Palette.rose600, dark: Palette.rose400)
}

/// Un acento de marca de ejemplo, para la galería.
extension Brand {
    public static let violet = Brand(accent: Shade(light: Palette.violet500, dark: Palette.violet400))
}
