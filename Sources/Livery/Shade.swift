//
//  Shade.swift
//  Livery
//

import SwiftUI

/// El valor de un rol de color: un color decidido para claro y para oscuro.
///
/// Un tema no puede resolver un rol de color con un `Color` suelto; tiene que dar un `Shade`.
/// Así la regla "todo color está decidido en ambos modos" la hace cumplir el tipo, no un lint.
///
/// ```swift
/// let surface = Shade(light: .white, dark: .black)
/// let accent  = Shade(.orange)   // el mismo en ambos, dicho a propósito
/// ```
///
/// Las variantes de contraste aumentado son opcionales y caen en la base si no se dan. El
/// `Shade` se resuelve a `Color` al dibujar, leyendo `colorScheme` y `colorSchemeContrast` del
/// entorno, por lo que las vistas siguen escribiendo `\.color.surface` sin saber de modos.
public struct Shade: Hashable, Sendable {
    public var light: Color
    public var dark: Color
    public var lightIncreased: Color?
    public var darkIncreased: Color?

    /// Un color para cada modo, con variantes opcionales para contraste aumentado.
    public init(light: Color, dark: Color, lightIncreased: Color? = nil, darkIncreased: Color? = nil) {
        self.light = light
        self.dark = dark
        self.lightIncreased = lightIncreased
        self.darkIncreased = darkIncreased
    }

    /// El mismo color en claro y oscuro. Úsalo cuando sea una decisión, no un olvido.
    public init(_ color: Color) {
        self.init(light: color, dark: color)
    }

    /// Valor de reserva, deliberadamente visible, para un rol que el tema activo no resuelve.
    public static let unresolved = Shade(.pink)

    /// El color para un modo y un nivel de contraste.
    public func color(for scheme: ColorScheme, contrast: ColorSchemeContrast = .standard) -> Color {
        switch (scheme, contrast) {
        case (.dark, .increased): darkIncreased ?? dark
        case (.dark, _): dark
        case (_, .increased): lightIncreased ?? light
        default: light
        }
    }

    /// Aplica una transformación a cada variante.
    public func map(_ transform: (Color) -> Color) -> Shade {
        Shade(light: transform(light), dark: transform(dark),
              lightIncreased: lightIncreased.map(transform), darkIncreased: darkIncreased.map(transform))
    }

    /// Todas las variantes con la opacidad dada.
    public func opacity(_ opacity: Double) -> Shade {
        map { $0.opacity(opacity) }
    }
}

extension Shade: ShapeStyle {
    /// Resuelve al color del modo y contraste del entorno. Permite usar un `Shade` directo donde
    /// SwiftUI acepta un `ShapeStyle`.
    public func resolve(in environment: EnvironmentValues) -> Color {
        color(for: environment.colorScheme, contrast: environment.colorSchemeContrast)
    }
}

#if canImport(UIKit) && !os(watchOS)
import UIKit

extension Shade {
    /// Un `UIColor` dinámico que sigue el modo y el contraste de la interfaz. Para UIKit.
    public var uiColor: UIColor {
        UIColor { traits in
            let scheme: ColorScheme = traits.userInterfaceStyle == .dark ? .dark : .light
            let contrast: ColorSchemeContrast = traits.accessibilityContrast == .high ? .increased : .standard
            return UIColor(color(for: scheme, contrast: contrast))
        }
    }
}
#elseif canImport(AppKit)
import AppKit

extension Shade {
    /// Un `NSColor` dinámico que sigue la apariencia y el contraste del sistema. Para AppKit.
    public var nsColor: NSColor {
        NSColor(name: nil) { appearance in
            let match = appearance.bestMatch(from: [
                .aqua, .darkAqua, .accessibilityHighContrastAqua, .accessibilityHighContrastDarkAqua,
            ])
            let isDark = match == .darkAqua || match == .accessibilityHighContrastDarkAqua
            let isHigh = match == .accessibilityHighContrastAqua || match == .accessibilityHighContrastDarkAqua
            return NSColor(color(for: isDark ? .dark : .light, contrast: isHigh ? .increased : .standard))
        }
    }
}
#endif
