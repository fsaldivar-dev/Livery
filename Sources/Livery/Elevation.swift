//
//  Elevation.swift
//  Livery
//

import SwiftUI

/// El valor de un rol de elevación: una sombra que, como ``Shade``, se decide para claro y oscuro.
///
/// En oscuro una sombra negra casi no se ve, así que el color es un `Shade`: un tema puede usar
/// una sombra más fuerte, o incluso otro tratamiento, en modo oscuro. El modificador `.elevation`
/// la aplica resolviendo el color por el modo del entorno.
///
/// ```swift
/// let card = Elevation(color: Shade(light: .black.opacity(0.12), dark: .black.opacity(0.5)),
///                      radius: 8, y: 4)
/// SomeView().elevation(theme.elevation.card)
/// ```
public struct Elevation: Sendable, Equatable {
    public var color: Shade
    public var radius: CGFloat
    public var x: CGFloat
    public var y: CGFloat

    public init(color: Shade, radius: CGFloat, x: CGFloat = 0, y: CGFloat = 0) {
        self.color = color
        self.radius = radius
        self.x = x
        self.y = y
    }

    /// Sin sombra. Valor de reserva para un rol que el tema activo no resuelve.
    public static let unresolved = Elevation(color: Shade(.clear), radius: 0)
}

extension View {
    /// Aplica una sombra del tema. El color se resuelve por el modo del entorno.
    public func elevation(_ elevation: Elevation) -> some View {
        modifier(ElevationModifier(elevation: elevation))
    }
}

private struct ElevationModifier: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    let elevation: Elevation

    func body(content: Content) -> some View {
        content.shadow(
            color: elevation.color.color(for: scheme),
            radius: elevation.radius,
            x: elevation.x,
            y: elevation.y
        )
    }
}

/// Marca un conjunto de roles de elevación. Se expone como `theme.elevation`; cada rol es un ``Elevation``.
public protocol ElevationRoles {}
