//
//  Modifiers.swift
//  Livery
//
//  Los colores no necesitan sobrecargas: `ThemeRef<Shade>` es un `ShapeStyle` y los modificadores
//  nativos lo aceptan. Estas sobrecargas cubren lo que SwiftUI pide como valor concreto (fuente,
//  medidas) y lo resuelven contra el tema del subárbol.
//

import SwiftUI

extension View {
    /// `font` con una fuente del tema.
    public func font(_ font: ThemeRef<Font>) -> some View {
        ThemeValue(font) { self.font($0) }
    }

    /// `padding` con un espacio del tema en todos los bordes.
    public func padding(_ length: ThemeRef<CGFloat>) -> some View {
        ThemeValue(length) { padding($0) }
    }

    /// `padding` con un espacio del tema en los bordes indicados.
    public func padding(_ edges: Edge.Set, _ length: ThemeRef<CGFloat>) -> some View {
        ThemeValue(length) { padding(edges, $0) }
    }

    /// `tint` con un color del tema. (El `tint` nativo recibe un opcional y la cadena `.theme…`
    /// no se infiere a través de él.)
    public func tint(_ color: ThemeRef<Shade>) -> some View {
        tint(Optional(color))
    }

    /// `background` con un color y un radio del tema.
    public func background(
        _ color: ThemeRef<Shade>,
        cornerRadius: ThemeRef<CGFloat>,
        style: RoundedCornerStyle = .continuous
    ) -> some View {
        ThemeValue(cornerRadius) { radius in
            background(color, in: RoundedRectangle(cornerRadius: radius, style: style))
        }
    }

    /// Recorta la vista a un rectángulo redondeado con un radio del tema.
    public func clipShape(
        cornerRadius: ThemeRef<CGFloat>,
        style: RoundedCornerStyle = .continuous
    ) -> some View {
        ThemeValue(cornerRadius) { radius in
            clipShape(RoundedRectangle(cornerRadius: radius, style: style))
        }
    }
}

/// Lee un valor del tema activo y construye una vista con él.
///
/// Es la forma general de usar un rol que ningún modificador cubre todavía:
///
/// ```swift
/// ThemeValue(theme.space.md) { spacing in
///     VStack(spacing: spacing) { … }
/// }
/// ```
public struct ThemeValue<Value, Content: View>: View {
    @Environment(\.theme) private var theme
    private let ref: ThemeRef<Value>
    private let content: (Value) -> Content

    public init(_ ref: ThemeRef<Value>, @ViewBuilder content: @escaping (Value) -> Content) {
        self.ref = ref
        self.content = content
    }

    public var body: some View {
        content(theme[ref])
    }
}
