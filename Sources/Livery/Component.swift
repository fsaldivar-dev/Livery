//
//  Component.swift
//  Livery
//
//  Un componente es un contrato, no una vista. Su estilo responde tres preguntas por separado:
//  de qué color es (un `Look` por variante), cuánto mide (un `Metrics` por tamaño) y qué le pasa
//  (un `Effect` por estado). Las variantes y los tamaños los declara el proyecto; los estados
//  los fija el kernel. Todo habla en roles, así un estilo sirve para cualquier tema.
//

import SwiftUI

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
