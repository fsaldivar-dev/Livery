//
//  Field.swift
//  DesignSystem
//
//  El campo de texto, siguiendo la HIG de Apple: una etiqueta, el campo y un mensaje opcional.
//  Escrito a mano como prototipo de lo que generará `@Component`.
//
//  A diferencia del botón, un campo no tiene variantes: tiene ESTADOS. El borde cambia según
//  esté en reposo, con foco, o con error. Todo en roles del sistema, así sirve para cualquier tema.
//

import Livery

@Component
public enum Field {
    /// El estilo del campo: tipos, colores, bordes por estado y medidas. Lo da el tema.
    public struct Style: Sendable {
        // Tipografía de cada parte.
        public var label: Typography
        public var text: Typography
        public var message: Typography

        // Colores.
        public var labelColor: Colors
        public var textColor: Colors
        public var placeholder: Colors
        public var fill: Colors
        public var messageColor: Colors
        public var invalid: Colors

        // El borde cambia con el estado.
        public var border: Colors
        public var borderFocused: Colors

        // Medidas.
        public var radius: Shapes
        public var vertical: Spacing
        public var horizontal: Spacing
        public var gap: Spacing        // entre la etiqueta, el campo y el mensaje

        // Cómo anima la aparición del foco.
        public var focus: Motions

        public init(
            label: Typography, text: Typography, message: Typography,
            labelColor: Colors, textColor: Colors, placeholder: Colors, fill: Colors,
            messageColor: Colors, invalid: Colors, border: Colors, borderFocused: Colors,
            radius: Shapes, vertical: Spacing, horizontal: Spacing, gap: Spacing, focus: Motions
        ) {
            self.label = label; self.text = text; self.message = message
            self.labelColor = labelColor; self.textColor = textColor; self.placeholder = placeholder
            self.fill = fill; self.messageColor = messageColor; self.invalid = invalid
            self.border = border; self.borderFocused = borderFocused
            self.radius = radius; self.vertical = vertical; self.horizontal = horizontal; self.gap = gap
            self.focus = focus
        }

        /// El color del borde según el estado. El error manda sobre el foco.
        public func borderColor(focused: Bool, invalid: Bool) -> Colors {
            invalid ? self.invalid : focused ? borderFocused : border
        }
    }

    /// Reserva, deliberadamente fea, para un tema que no registra estilo de campo.
    public static let unstyled = Style(
        label: .caption, text: .body, message: .caption,
        labelColor: .onSurface, textColor: .onSurface, placeholder: .onSurfaceSecondary, fill: .surface,
        messageColor: .onSurfaceSecondary, invalid: .danger, border: .danger, borderFocused: .danger,
        radius: .small, vertical: .sm, horizontal: .md, gap: .xs, focus: .quick
    )
}
