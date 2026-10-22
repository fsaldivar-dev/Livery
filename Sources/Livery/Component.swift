//
//  Component.swift
//  Livery
//
//  Un componente es un contrato, no una vista: sus partes, sus variantes, sus tamaños, y los
//  estados que el kernel fija. Un estilo es una tabla que asigna roles a cada parte, en cascada:
//  base, variante, tamaño, estado. El estilo vive en el tema, como los roles, y por eso un mismo
//  estilo sirve para todos los temas: dice "el contenedor usa `accent`", no "usa índigo".
//

import SwiftUI

/// Las partes de un componente: `container`, `label`, `icon`…
public protocol ComponentPart: CaseIterable, Hashable, Sendable {}

/// Las variantes de intención de un componente: `primary`, `secondary`, `destructive`…
public protocol ComponentVariant: CaseIterable, Hashable, Sendable {}

/// Los tamaños de un componente. Cada uno declara su objetivo táctil mínimo.
public protocol ComponentSize: CaseIterable, Hashable, Sendable {
    /// Alto mínimo del área interactiva, en puntos. 44 es el mínimo de accesibilidad de Apple.
    var minimumHitTarget: CGFloat { get }
}

extension ComponentSize {
    public var minimumHitTarget: CGFloat { 44 }
}

/// Los estados que SwiftUI y la accesibilidad producen. Los fija el kernel, no cada componente.
public enum ComponentState: CaseIterable, Hashable, Sendable {
    case normal, pressed, disabled, focused, selected
}

/// Lo que una parte puede especificar. Cada componente declara el suyo con campos opcionales:
/// `nil` significa "no toca lo heredado", así las sobreescrituras son parciales.
public protocol PartAttributes: Sendable {
    /// Devuelve `self` con los campos no nulos de `other` encima.
    func overriding(with other: Self) -> Self
}

/// La tabla de estilo de un componente: una cascada cerrada.
///
/// La base es una función exhaustiva de parte a atributos, así el compilador exige que ninguna
/// parte quede sin resolver. Variantes, tamaños y estados son sobreescrituras parciales, y se
/// aplican en ese orden: el estado gana.
public struct ComponentStyle<Part: ComponentPart, Variant: ComponentVariant, Size: ComponentSize, Attributes: PartAttributes>: Sendable {
    public typealias Overrides = [Part: Attributes]

    private let base: @Sendable (Part) -> Attributes
    public var variants: [Variant: Overrides]
    public var sizes: [Size: Overrides]
    public var states: [ComponentState: Overrides]

    public init(
        base: @escaping @Sendable (Part) -> Attributes,
        variants: [Variant: Overrides] = [:],
        sizes: [Size: Overrides] = [:],
        states: [ComponentState: Overrides] = [:]
    ) {
        self.base = base
        self.variants = variants
        self.sizes = sizes
        self.states = states
    }

    /// Los atributos de cada parte para una combinación, tras aplicar la cascada.
    public func attributes(variant: Variant, size: Size, state: ComponentState) -> [Part: Attributes] {
        var result: [Part: Attributes] = [:]
        for part in Part.allCases {
            var attributes = base(part)
            for layer in [variants[variant], sizes[size], states[state]] {
                if let override = layer?[part] { attributes = attributes.overriding(with: override) }
            }
            result[part] = attributes
        }
        return result
    }
}

// MARK: - Registro en el tema

extension Theme {
    /// Registra el estilo de un componente. La clave es el tipo del contrato (`Button.self`).
    public mutating func register<Component>(style: some Sendable, for component: Component.Type) {
        register(any: style, key: ObjectIdentifier(component))
    }

    /// El estilo registrado para un componente, si el tema lo tiene.
    public func style<Component, Style: Sendable>(for component: Component.Type, as type: Style.Type = Style.self) -> Style? {
        value(key: ObjectIdentifier(component)) as? Style
    }
}
