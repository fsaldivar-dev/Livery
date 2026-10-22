//
//  TypeStyle.swift
//  Livery
//

import SwiftUI

/// El valor de un rol tipográfico: una fuente que escala con Dynamic Type por construcción.
///
/// Igual que ``Shade`` obliga a decidir claro y oscuro, `TypeStyle` obliga a que la fuente escale
/// con el tamaño de texto del sistema: solo se construye relativa a un estilo de texto de Apple
/// (`.title`, `.body`, `.caption`…), nunca a un tamaño fijo en puntos. Así ningún rol del tema
/// puede quedar sin escalar.
///
/// ```swift
/// let title = TypeStyle(.title, weight: .semibold)
/// let body  = TypeStyle(.body)
/// let code  = TypeStyle(.body, design: .monospaced)
/// ```
public struct TypeStyle: Sendable, Equatable {
    /// El estilo de texto del sistema con el que escala.
    public var textStyle: Font.TextStyle
    public var weight: Font.Weight?
    public var design: Font.Design?

    public init(_ textStyle: Font.TextStyle, weight: Font.Weight? = nil, design: Font.Design? = nil) {
        self.textStyle = textStyle
        self.weight = weight
        self.design = design
    }

    /// La fuente escalable. Se usa con `.font(theme.type.title)` por la sobrecarga de `View`.
    public var font: Font {
        var font = Font.system(textStyle, design: design ?? .default)
        if let weight { font = font.weight(weight) }
        return font
    }

    /// Valor de reserva, deliberadamente neutro, para un rol que el tema activo no resuelve.
    public static let unresolved = TypeStyle(.body)
}

extension View {
    /// `font` con un rol tipográfico del tema. La fuente escala con Dynamic Type.
    public func font(_ style: TypeStyle) -> some View {
        font(style.font)
    }
}

extension Text {
    /// Permite `Text("…").font(theme.type.title)` conservando el tipo `Text`.
    public func font(_ style: TypeStyle) -> Text {
        font(style.font)
    }
}
