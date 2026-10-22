//
//  Motion.swift
//  Livery
//

import SwiftUI

/// El valor de un rol de movimiento: una animación y, opcionalmente, la versión para quien
/// activó "Reducir movimiento" en el sistema.
///
/// ```swift
/// let quick = Motion(.easeOut(duration: 0.12))
/// let slide = Motion(.spring(duration: 0.35), reduced: .easeOut(duration: 0.1))
/// ```
///
/// Se resuelve al aplicar, leyendo `accessibilityReduceMotion` del entorno: sin variante
/// reducida, la animación se omite por completo cuando el ajuste está activo.
public struct Motion: Sendable {
    public var animation: Animation
    public var reduced: Animation?

    public init(_ animation: Animation, reduced: Animation? = nil) {
        self.animation = animation
        self.reduced = reduced
    }

    /// Valor de reserva: sin animación, para que un rol sin resolver se note.
    public static let unresolved = Motion(.linear(duration: 0))

    /// La animación para el entorno: la reducida, ninguna, o la normal.
    public func resolve(in environment: EnvironmentValues) -> Animation? {
        environment.accessibilityReduceMotion ? reduced : animation
    }

    /// La animación según el ajuste de accesibilidad.
    public func resolve(reduceMotion: Bool) -> Animation? {
        reduceMotion ? reduced : animation
    }
}

/// Marca un conjunto de roles de movimiento. Se expone como `theme.motion`; cada rol es un ``Motion``.
public protocol MotionRoles {}
