//
//  Modifiers.swift
//  Livery
//
//  Sobrecargas de los modificadores de SwiftUI que aceptan un key path sobre `Theme` y lo
//  resuelven contra el tema del subárbol. La vista nunca declara `@Environment`.
//

import SwiftUI

// MARK: - Color

extension View {
    /// `foregroundStyle` con un color del tema.
    public func foregroundStyle(_ color: KeyPath<Theme, Color> & Sendable) -> some View {
        foregroundStyle(ThemeStyle(color))
    }

    /// `background` con un color del tema.
    public func background(
        _ color: KeyPath<Theme, Color> & Sendable,
        ignoresSafeAreaEdges edges: Edge.Set = .all
    ) -> some View {
        background(ThemeStyle(color), ignoresSafeAreaEdges: edges)
    }

    /// `background` con un color del tema recortado a una forma.
    public func background<S: Shape>(
        _ color: KeyPath<Theme, Color> & Sendable,
        in shape: S,
        fillStyle: FillStyle = FillStyle()
    ) -> some View {
        background(ThemeStyle(color), in: shape, fillStyle: fillStyle)
    }

    /// `background` con un color y un radio del tema.
    public func background(
        _ color: KeyPath<Theme, Color> & Sendable,
        cornerRadius: KeyPath<Theme, CGFloat> & Sendable,
        style: RoundedCornerStyle = .continuous
    ) -> some View {
        ThemeValue(keyPath: cornerRadius) { radius in
            background(ThemeStyle(color), in: RoundedRectangle(cornerRadius: radius, style: style))
        }
    }

    /// `tint` con un color del tema.
    public func tint(_ color: KeyPath<Theme, Color> & Sendable) -> some View {
        tint(ThemeStyle(color))
    }
}

extension Shape {
    /// `fill` con un color del tema.
    public func fill(_ color: KeyPath<Theme, Color> & Sendable, style: FillStyle = FillStyle()) -> some View {
        fill(ThemeStyle(color), style: style)
    }

    /// `stroke` con un color del tema.
    public func stroke(_ color: KeyPath<Theme, Color> & Sendable, lineWidth: CGFloat = 1) -> some View {
        stroke(ThemeStyle(color), lineWidth: lineWidth)
    }
}

// MARK: - Tipografía

extension View {
    /// `font` con una fuente del tema.
    public func font(_ font: KeyPath<Theme, Font> & Sendable) -> some View {
        ThemeValue(keyPath: font) { self.font($0) }
    }
}

// MARK: - Espaciado

extension View {
    /// `padding` con un espacio del tema en todos los bordes.
    public func padding(_ length: KeyPath<Theme, CGFloat> & Sendable) -> some View {
        ThemeValue(keyPath: length) { padding($0) }
    }

    /// `padding` con un espacio del tema en los bordes indicados.
    public func padding(_ edges: Edge.Set, _ length: KeyPath<Theme, CGFloat> & Sendable) -> some View {
        ThemeValue(keyPath: length) { padding(edges, $0) }
    }
}

// MARK: - Forma

extension View {
    /// Recorta la vista a un rectángulo redondeado con un radio del tema.
    public func clipShape(
        cornerRadius: KeyPath<Theme, CGFloat> & Sendable,
        style: RoundedCornerStyle = .continuous
    ) -> some View {
        ThemeValue(keyPath: cornerRadius) { radius in
            clipShape(RoundedRectangle(cornerRadius: radius, style: style))
        }
    }
}

// MARK: - Soporte

/// Lee un valor del tema activo y construye una vista con él.
///
/// Es la forma general de usar un rol que ningún modificador cubre todavía:
///
/// ```swift
/// ThemeValue(keyPath: \.space.md) { spacing in
///     VStack(spacing: spacing) { … }
/// }
/// ```
public struct ThemeValue<Value, Content: View>: View {
    @Environment(\.theme) private var theme
    private let keyPath: KeyPath<Theme, Value> & Sendable
    private let content: (Value) -> Content

    public init(keyPath: KeyPath<Theme, Value> & Sendable, @ViewBuilder content: @escaping (Value) -> Content) {
        self.keyPath = keyPath
        self.content = content
    }

    public var body: some View {
        content(theme[keyPath: keyPath])
    }
}
