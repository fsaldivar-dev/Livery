//
//  ThemeStyle.swift
//  Livery
//

import SwiftUI

/// Un `ShapeStyle` que se resuelve contra el tema del subárbol en el momento de dibujar: lee el
/// `Shade` del rol y elige el color del modo y contraste del entorno.
///
/// Las sobrecargas de `foregroundStyle`, `background`, `tint`, `fill` y `stroke` lo usan por
/// debajo. Para cualquier otro modificador que acepte un `ShapeStyle`, usa `.theme(_:)`:
///
/// ```swift
/// .listRowBackground(.theme(\.color.surface))
/// ```
public struct ThemeStyle: ShapeStyle {
    private let keyPath: KeyPath<Theme, Shade> & Sendable

    public init(_ keyPath: KeyPath<Theme, Shade> & Sendable) {
        self.keyPath = keyPath
    }

    public func resolve(in environment: EnvironmentValues) -> Color {
        environment.theme[keyPath: keyPath].resolve(in: environment)
    }
}

extension ShapeStyle where Self == ThemeStyle {
    /// Un color del tema, para cualquier API que acepte un `ShapeStyle`.
    public static func theme(_ keyPath: KeyPath<Theme, Shade> & Sendable) -> ThemeStyle {
        ThemeStyle(keyPath)
    }
}
