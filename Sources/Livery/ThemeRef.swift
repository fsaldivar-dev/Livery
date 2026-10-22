//
//  ThemeRef.swift
//  Livery
//

import SwiftUI

/// Una referencia a un valor del tema, construida miembro a miembro: `.theme.color.onSurface`.
///
/// Cada paso de la cadena tiene un tipo concreto, así Xcode lista exactamente los roles que
/// existen en cada nivel. Se resuelve contra el tema del subárbol al dibujar: la vista no
/// declara `@Environment` ni sabe de modos.
///
/// ```swift
/// Text(name)
///     .font(.theme.type.title)
///     .foregroundStyle(.theme.color.onSurface)
///     .padding(.theme.space.lg)
/// ```
///
/// Un `ThemeRef<Shade>` es un `ShapeStyle`, así que vale en cualquier API nativa que acepte uno:
/// `foregroundStyle`, `background`, `fill`, `stroke`, `tint`, `border`…
@dynamicMemberLookup
public struct ThemeRef<Value>: @unchecked Sendable {
    let keyPath: KeyPath<Theme, Value>

    init(_ keyPath: KeyPath<Theme, Value>) {
        self.keyPath = keyPath
    }

    /// La raíz de la cadena: `.theme.color…`, `.theme.type…`, `.theme.space…`, `.theme.shape…`.
    public static var theme: ThemeRef<Theme> { ThemeRef<Theme>(\.self) }

    public subscript<T>(dynamicMember member: KeyPath<Value, T>) -> ThemeRef<T> {
        ThemeRef<T>(keyPath.appending(path: member))
    }
}

extension Theme {
    /// El valor al que apunta una referencia, en este tema.
    public subscript<Value>(_ ref: ThemeRef<Value>) -> Value { self[keyPath: ref.keyPath] }
}

extension ThemeRef: ShapeStyle where Value == Shade {
    public func resolve(in environment: EnvironmentValues) -> Color {
        environment.theme[keyPath: keyPath].resolve(in: environment)
    }
}

extension ShapeStyle where Self == ThemeRef<Shade> {
    /// Un color del tema donde SwiftUI pide un `ShapeStyle`: `.fill(.theme.color.accent)`.
    public static var theme: ThemeRef<Theme> { ThemeRef<Theme>(\.self) }
}
