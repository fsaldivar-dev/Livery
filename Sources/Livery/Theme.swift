//
//  Theme.swift
//  Livery
//

import OSLog
import SwiftUI

/// El tema activo en un subárbol de vistas: la resolución de cada conjunto de roles.
///
/// `Theme` es la raíz de todos los key paths (`\.color.onSurface`, `\.space.md`). Las
/// propiedades por categoría (`color`, `type`, `space`, `shape`) las genera ``Roles()`` a partir
/// de los enums declarados dentro de `extension Theme`. El kernel solo conoce las categorías;
/// los nombres de cada rol los pone el proyecto.
public struct Theme: Sendable {
    private var storage: [ObjectIdentifier: any Sendable] = [:]

    /// Un tema vacío: ningún conjunto de roles resuelto.
    public init() {}

    /// Registra la resolución de un conjunto de roles. Reemplaza la anterior si existía.
    public mutating func register<R: RoleSet>(_ values: R.Values, for set: R.Type = R.self) {
        storage[ObjectIdentifier(set)] = values
    }

    /// Devuelve la resolución de un conjunto de roles.
    ///
    /// Si el subárbol activo no lo resuelve, en debug emite una advertencia de runtime y devuelve
    /// ``RoleSet/unresolved`` (colores rosa en ambos modos, fuente `body`, medidas `0`) para que el fallo sea
    /// visible sin tumbar la app.
    public func values<R: RoleSet>(_ set: R.Type = R.self) -> R.Values {
        if let values = storage[ObjectIdentifier(set)] as? R.Values {
            return values
        }
        #if DEBUG
        Theme.logger.fault("\(String(reflecting: set), privacy: .public) no está resuelto por el tema activo. Aplica `.theme(_:)` con un tema que lo resuelva en un ancestro de esta vista.")
        #endif
        return R.unresolved
    }

    /// Indica si el tema resuelve un conjunto de roles.
    public func resolves<R: RoleSet>(_ set: R.Type) -> Bool {
        storage[ObjectIdentifier(set)] != nil
    }

    /// Incorpora las resoluciones de otro tema. Las de `other` ganan en caso de conflicto.
    public mutating func merge(_ other: Theme) {
        storage.merge(other.storage) { _, new in new }
    }

    /// Un tema con las resoluciones de ambos. Las de `other` ganan en caso de conflicto.
    public func merging(_ other: Theme) -> Theme {
        var copy = self
        copy.merge(other)
        return copy
    }

    private static let logger = Logger(subsystem: "Livery", category: "Theme")
}

/// Un conjunto de roles: un enum con un caso por decisión de diseño.
///
/// No se conforma a mano. ``Roles()`` lo adjunta a cada enum declarado dentro de
/// `extension Theme` y genera `Resolver`, `Values` y `unresolved`.
public protocol RoleSet {
    /// La resolución del conjunto: un valor por rol.
    associatedtype Values: Sendable
    /// Valores de reserva, deliberadamente visibles, para cuando el tema activo no resuelve el conjunto.
    static var unresolved: Values { get }
}

/// Algo que produce un ``Theme`` completo: normalmente un `struct` marcado con ``Theme()``.
public protocol ThemeProvider: Sendable {
    var resolvedTheme: Theme { get }
}

extension Theme: ThemeProvider {
    public var resolvedTheme: Theme { self }
}

// MARK: - Categorías

/// Marca un conjunto de roles de color. Se expone como `theme.color`; cada rol es un ``Shade``,
/// un color decidido para claro y oscuro.
public protocol ColorRoles {}

/// Marca un conjunto de roles tipográficos. Se expone como `theme.type`; cada rol es un `Font`.
public protocol TypeRoles {}

/// Marca un conjunto de roles de espaciado. Se expone como `theme.space`; cada rol es un `CGFloat` en puntos.
public protocol SpaceRoles {}

/// Marca un conjunto de roles de forma. Se expone como `theme.shape`; cada rol es un radio en puntos.
public protocol ShapeRoles {}
