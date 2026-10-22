//
//  Button.swift
//  DesignSystem
//
//  El botón, siguiendo las Human Interface Guidelines de Apple. Escrito a mano como prototipo de
//  lo que generará `@Component`.
//
//  Apple no tiene "primario/secundario". Tiene un TINTE (el color de la acción) y tres ESTILOS
//  que deciden cómo se pinta ese tinte, igual que `.buttonStyle(...)` en SwiftUI:
//    · prominent → relleno sólido del tinte      (como `.borderedProminent`: la acción principal)
//    · bordered  → relleno suave del tinte        (como `.bordered`: la acción estándar)
//    · plain     → solo texto, sin relleno        (como `.plain`: una acción terciaria)
//  Lo destructivo no es un estilo, es un ROL: `Button(role: .destructive)` cambia el tinte a rojo.
//

import Livery

public enum Button {
    /// Los estilos de Apple. El tinte es el mismo; cambia cómo se pinta.
    public enum Variant: ComponentVariant { case prominent, bordered, plain }

    /// Sigue a `.controlSize` de SwiftUI. HIG pide 44 pt de área táctil, se vea pequeño o no.
    public enum Size: ComponentSize {
        case small, medium, large
        public var minimumHitTarget: CGFloat { 44 }
    }

    /// Cómo se pinta el tinte en un estilo.
    public enum Treatment: Sendable {
        case solid   // relleno del tinte, texto `onTint`
        case soft    // relleno del tinte al 15 %, texto del tinte
        case text    // sin relleno, texto del tinte
    }

    /// Cuánto mide un tamaño. La forma es siempre cápsula, como en iOS.
    public struct Metrics: Sendable {
        public var font: Typography
        public var vertical: Spacing
        public var horizontal: Spacing

        public init(font: Typography, vertical: Spacing, horizontal: Spacing) {
            self.font = font
            self.vertical = vertical
            self.horizontal = horizontal
        }
    }

    /// Qué le pasa en un estado, y con qué movimiento se llega a él.
    public struct Effect: Sendable {
        public var opacity: Double
        public var scale: Double
        public var motion: Motions

        public init(opacity: Double = 1, scale: Double = 1, motion: Motions = .quick) {
            self.opacity = opacity
            self.scale = scale
            self.motion = motion
        }
    }

    /// El estilo del botón del tema: un tinte, cómo lo pinta cada estilo de Apple, y las medidas.
    public struct Style: Sendable {
        /// El color de la acción, como el `.tint()` de SwiftUI. El rol `.destructive` usa `danger`.
        public var tint: Colors
        /// El texto sobre el relleno sólido (estilo prominente).
        public var onTint: Colors

        public var prominent: Treatment
        public var bordered: Treatment
        public var plain: Treatment

        public var small: Metrics
        public var medium: Metrics
        public var large: Metrics

        public var pressed: Effect
        public var disabled: Effect

        public init(
            tint: Colors, onTint: Colors,
            small: Metrics, medium: Metrics, large: Metrics,
            prominent: Treatment = .solid, bordered: Treatment = .soft, plain: Treatment = .text,
            pressed: Effect = Effect(opacity: 0.85, scale: 0.97),
            disabled: Effect = Effect(opacity: 0.4)
        ) {
            self.tint = tint; self.onTint = onTint
            self.small = small; self.medium = medium; self.large = large
            self.prominent = prominent; self.bordered = bordered; self.plain = plain
            self.pressed = pressed; self.disabled = disabled
        }

        public func treatment(for variant: Variant) -> Treatment {
            switch variant {
            case .prominent: prominent
            case .bordered: bordered
            case .plain: plain
            }
        }

        public func metrics(for size: Size) -> Metrics {
            switch size {
            case .small: small
            case .medium: medium
            case .large: large
            }
        }

        public func effect(for state: ComponentState) -> Effect {
            switch state {
            case .pressed: pressed
            case .disabled: disabled
            default: Effect()
            }
        }
    }

    /// Lo que un tema promete para el botón. `@Theme` lo registra.
    public protocol Styler { var button: Style { get } }

    /// Reserva, deliberadamente fea, para un tema que no registra estilo de botón.
    public static let unstyled = Style(
        tint: .danger, onTint: .onAccent,
        small: Metrics(font: .caption, vertical: .xs, horizontal: .md),
        medium: Metrics(font: .headline, vertical: .sm, horizontal: .lg),
        large: Metrics(font: .headline, vertical: .md, horizontal: .xl)
    )
}

extension Theme {
    /// El estilo de botón del tema activo. Lo generará el plugin a partir de `Button.Styler`.
    public var button: Button.Style { style(for: Button.self) ?? Button.unstyled }
}
