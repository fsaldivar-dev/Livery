//
//  ThemeRef.swift
//  Livery
//

import SwiftUI

/// Una referencia a un valor del tema, construida miembro a miembro: `theme.color.onSurface`.
///
/// `theme` es un valor global, no un miembro implícito: cada paso de la cadena tiene un tipo
/// concreto y el autocompletado lo resuelve solo, sin depender de la llamada que lo rodea. Se
/// resuelve contra el tema del subárbol al dibujar: la vista no declara `@Environment` ni sabe
/// de modos.
///
/// ```swift
/// Text(name)
///     .font(theme.type.title)
///     .foregroundStyle(theme.color.onSurface)
///     .padding(theme.space.lg)
/// ```
///
/// Un `ThemeRef<Shade>` es un `ShapeStyle`, así que vale en cualquier API nativa que acepte uno:
/// `foregroundStyle`, `background`, `fill`, `stroke`, `border`…
@dynamicMemberLookup
public struct ThemeRef<Value>: @unchecked Sendable {
    let keyPath: KeyPath<Theme, Value>

    init(_ keyPath: KeyPath<Theme, Value>) {
        self.keyPath = keyPath
    }

    public subscript<T>(dynamicMember member: KeyPath<Value, T>) -> ThemeRef<T> {
        ThemeRef<T>(keyPath.appending(path: member))
    }
}

/// La raíz de toda referencia al tema activo: `theme.color.onSurface`, `theme.type.title`,
/// `theme.space.md`, `theme.shape.medium`. Las propiedades por categoría las genera el plugin.
public let theme = ThemeRef<Theme>(\.self)

extension Theme {
    /// El valor al que apunta una referencia, en este tema.
    public subscript<Value>(_ ref: ThemeRef<Value>) -> Value { self[keyPath: ref.keyPath] }
}

extension ThemeRef: ShapeStyle where Value == Shade {
    public func resolve(in environment: EnvironmentValues) -> Color {
        environment.theme[keyPath: keyPath].resolve(in: environment)
    }
}

