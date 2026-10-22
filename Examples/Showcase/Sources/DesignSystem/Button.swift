//
//  Button.swift
//  DesignSystem
//
//  El contrato del botón y la forma de su estilo. Escrito a mano como prototipo de lo que
//  generará `@Component`: las partes, las variantes y los tamaños los declara el proyecto; los
//  estados los pone Livery. `PartStyle` dice qué puede especificar una parte, siempre en roles.
//

import Livery

public enum Button {
    public enum Part: ComponentPart { case container, label, icon }
    public enum Kind: ComponentVariant { case primary, secondary, destructive }
    public enum Size: ComponentSize {
        case small, medium, large
        /// Un botón pequeño se ve pequeño, pero su área táctil sigue siendo accesible.
        public var minimumHitTarget: CGFloat { self == .large ? 52 : 44 }
    }

    /// Lo que una parte del botón puede especificar, en roles del proyecto. `nil` hereda.
    public struct PartStyle: PartAttributes {
        public var background: Colors?
        public var foreground: Colors?
        public var border: Colors?
        public var font: Typography?
        public var paddingVertical: Spacing?
        public var paddingHorizontal: Spacing?
        public var radius: Shapes?
        public var opacity: Double?

        public init(background: Colors? = nil, foreground: Colors? = nil, border: Colors? = nil,
                    font: Typography? = nil, paddingVertical: Spacing? = nil, paddingHorizontal: Spacing? = nil,
                    radius: Shapes? = nil, opacity: Double? = nil) {
            self.background = background; self.foreground = foreground; self.border = border
            self.font = font; self.paddingVertical = paddingVertical; self.paddingHorizontal = paddingHorizontal
            self.radius = radius; self.opacity = opacity
        }

        public func overriding(with other: PartStyle) -> PartStyle {
            PartStyle(background: other.background ?? background, foreground: other.foreground ?? foreground,
                      border: other.border ?? border, font: other.font ?? font,
                      paddingVertical: other.paddingVertical ?? paddingVertical,
                      paddingHorizontal: other.paddingHorizontal ?? paddingHorizontal,
                      radius: other.radius ?? radius, opacity: other.opacity ?? opacity)
        }

        /// Los valores concretos en un tema.
        public func resolved(in theme: Theme) -> Resolved {
            Resolved(background: background.map { theme.color[$0] }, foreground: foreground.map { theme.color[$0] },
                     border: border.map { theme.color[$0] }, font: font.map { theme.type[$0] },
                     paddingVertical: paddingVertical.map { theme.space[$0] } ?? 0,
                     paddingHorizontal: paddingHorizontal.map { theme.space[$0] } ?? 0,
                     radius: radius.map { theme.shape[$0] } ?? 0, opacity: opacity ?? 1)
        }
    }

    public struct Resolved: Sendable {
        public var background: Shade?, foreground: Shade?, border: Shade?, font: Font?
        public var paddingVertical: CGFloat, paddingHorizontal: CGFloat, radius: CGFloat, opacity: Double
    }

    public typealias Style = ComponentStyle<Part, Kind, Size, PartStyle>

    /// Lo que un tema promete para el botón. El macro `@Theme` lo registra.
    public protocol Styler { var button: Style { get } }

    /// Reserva, deliberadamente fea, para un tema que no registra estilo de botón.
    public static let unstyled = Style(base: { part in
        switch part {
        case .container: PartStyle(background: .danger, paddingVertical: .sm, paddingHorizontal: .md, radius: .small)
        case .label: PartStyle(foreground: .onAccent, font: .headline)
        case .icon: PartStyle(foreground: .onAccent)
        }
    })
}

extension Theme {
    /// El estilo de botón del tema activo. Lo generará el plugin a partir de `Button.Styler`.
    public var button: Button.Style { style(for: Button.self) ?? Button.unstyled }
}
