//
//  Icon.swift
//  Livery
//

import SwiftUI

/// El valor de un rol de icono: una referencia a un símbolo, resuelta a un `Image`.
///
/// Como los colores, los iconos son semánticos: la vista pide `theme.icon.delete`, no el nombre
/// `"trash"`. Si el símbolo de borrar cambia, se cambia en el tema, no en cada vista. Sigue la HIG
/// usando SF Symbols; un símbolo propio (importado de un SVG a la plantilla de símbolo) se
/// referencia igual, indicando el bundle que lo trae.
///
/// ```swift
/// let delete = Icon("trash")                       // SF Symbol del sistema
/// let logo   = Icon("brand.logo", in: .module)     // símbolo propio empaquetado
/// ```
public struct Icon: @unchecked Sendable, Equatable {
    public enum Source: Equatable { case system, bundled(Bundle) }

    public var name: String
    public var source: Source

    /// Un SF Symbol del sistema.
    public init(_ systemName: String) {
        self.name = systemName
        self.source = .system
    }

    /// Un símbolo propio empaquetado con el sistema de diseño (`Bundle.module`).
    public init(_ name: String, in bundle: Bundle) {
        self.name = name
        self.source = .bundled(bundle)
    }

    /// El `Image` del icono, para teñir y dimensionar con los modificadores nativos.
    public var image: Image {
        switch source {
        case .system: Image(systemName: name)
        case .bundled(let bundle): Image(name, bundle: bundle)
        }
    }

    /// Reserva, deliberadamente visible, para un rol que el tema activo no resuelve.
    public static let unresolved = Icon("questionmark.square.dashed")
}

extension Image {
    /// Construye un `Image` desde un rol de icono: `Image(theme.icon.delete)`.
    public init(_ icon: Icon) {
        self = icon.image
    }
}

/// Marca un conjunto de roles de icono. Se expone como `theme.icon`; cada rol es un ``Icon``.
public protocol IconRoles {}
