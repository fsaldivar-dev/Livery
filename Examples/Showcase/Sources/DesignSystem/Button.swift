//
//  Button.swift
//  DesignSystem
//
//  El contrato del botón. Escrito a mano como prototipo de lo que generará `@Component`.
//
//  Un botón se describe con tres preguntas, cada una con su struct:
//    · ¿De qué color es?   → un `Look` por variante (primary, secondary, destructive)
//    · ¿Cuánto mide?       → un `Metrics` por tamaño (small, medium, large)
//    · ¿Qué le pasa?       → un `Effect` por estado (pressed, disabled…)
//  Todo en roles del sistema, nunca en valores: así el mismo estilo sirve para cualquier tema.
//

import Livery

public enum Button {
    public enum Variant: ComponentVariant { case primary, secondary, destructive }

    public enum Size: ComponentSize {
        case small, medium, large
        /// Un botón pequeño se ve pequeño, pero su área táctil sigue siendo accesible.
        public var minimumHitTarget: CGFloat { self == .large ? 52 : 44 }
    }

    /// De qué color es una variante.
    public struct Look: Sendable {
        public var background: Colors
        public var foreground: Colors
        public var border: Colors?
        public var icon: Colors?

        public init(background: Colors, foreground: Colors, border: Colors? = nil, icon: Colors? = nil) {
            self.background = background
            self.foreground = foreground
            self.border = border
            self.icon = icon
        }
    }

    /// Cuánto mide un tamaño.
    public struct Metrics: Sendable {
        public var font: Typography
        public var vertical: Spacing
        public var horizontal: Spacing
        public var radius: Shapes

        public init(font: Typography, vertical: Spacing, horizontal: Spacing, radius: Shapes) {
            self.font = font
            self.vertical = vertical
            self.horizontal = horizontal
            self.radius = radius
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

    /// El estilo completo: un `Look` por variante, un `Metrics` por tamaño, un `Effect` por estado.
    /// Si falta una variante o un tamaño, no compila. Los estados tienen valor por defecto.
    public struct Style: Sendable {
        public var primary: Look
        public var secondary: Look
        public var destructive: Look

        public var small: Metrics
        public var medium: Metrics
        public var large: Metrics

        public var pressed: Effect
        public var disabled: Effect
        public var focused: Effect
        public var selected: Effect

        public init(
            primary: Look,
            secondary: Look,
            destructive: Look,
            small: Metrics,
            medium: Metrics,
            large: Metrics,
            pressed: Effect = Effect(opacity: 0.85, scale: 0.97),
            disabled: Effect = Effect(opacity: 0.4),
            focused: Effect = Effect(),
            selected: Effect = Effect()
        ) {
            self.primary = primary; self.secondary = secondary; self.destructive = destructive
            self.small = small; self.medium = medium; self.large = large
            self.pressed = pressed; self.disabled = disabled; self.focused = focused; self.selected = selected
        }

        public func look(for variant: Variant) -> Look {
            switch variant {
            case .primary: primary
            case .secondary: secondary
            case .destructive: destructive
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
            case .normal: Effect()
            case .pressed: pressed
            case .disabled: disabled
            case .focused: focused
            case .selected: selected
            }
        }
    }

    /// Lo que un tema promete para el botón. `@Theme` lo registra.
    public protocol Styler { var button: Style { get } }

    /// Reserva, deliberadamente llamativa, para un tema que no registra estilo de botón.
    public static let unstyled = Style(
        primary: Look(background: .danger, foreground: .onAccent),
        secondary: Look(background: .danger, foreground: .onAccent),
        destructive: Look(background: .danger, foreground: .onAccent),
        small: Metrics(font: .caption, vertical: .xs, horizontal: .sm, radius: .large),
        medium: Metrics(font: .headline, vertical: .sm, horizontal: .md, radius: .large),
        large: Metrics(font: .headline, vertical: .md, horizontal: .lg, radius: .medium)
    )
}

extension Theme {
    /// El estilo de botón del tema activo. Lo generará el plugin a partir de `Button.Styler`.
    public var button: Button.Style { style(for: Button.self) ?? Button.unstyled }
}
