//
//  Export.swift
//  Livery
//
//  Exporta un tema a W3C Design Tokens (https://tr.designtokens.org), el formato que abren Penpot
//  y Figma (Tokens Studio). Swift es la fuente; el JSON es una salida.
//
//  No se puede exportar leyendo el código: el valor de un rol (el hex real) solo existe cuando el
//  tema se resuelve. Por eso el export es una API de runtime; el plugin genera `theme.w3cTokens`,
//  que recorre cada rol y llama a este constructor.
//

import Foundation
import SwiftUI

/// El modo para el que se exportan los colores. Un archivo W3C es de un modo; se exportan dos.
public enum TokenMode: String, Sendable {
    case light, dark
}

/// Acumula tokens por grupo y los serializa como W3C Design Tokens.
public final class W3CDocument {
    private var groups: [String: [String: [String: Any]]] = [:]

    public init() {}

    /// Un token de color: `{ "$type": "color", "$value": "#RRGGBB" }`.
    public func color(_ group: String, _ name: String, _ shade: Shade, mode: TokenMode) {
        put(group, name, type: "color", value: shade.hex(mode: mode))
    }

    /// Un token de medida en puntos: `{ "$type": "dimension", "$value": "16px" }`.
    public func dimension(_ group: String, _ name: String, _ points: CGFloat) {
        put(group, name, type: "dimension", value: "\(Int(points.rounded()))px")
    }

    /// Un token de tipografía compuesto, con el tamaño nominal del estilo de texto.
    public func typography(_ group: String, _ name: String, _ style: TypeStyle) {
        put(group, name, type: "typography", value: [
            "fontFamily": "system",
            "fontSize": "\(Int(style.textStyle.nominalSize.rounded()))px",
            "fontWeight": (style.weight ?? style.textStyle.nominalWeight).w3cValue,
        ])
    }

    private func put(_ group: String, _ name: String, type: String, value: Any) {
        groups[group, default: [:]][name] = ["$type": type, "$value": value]
    }

    /// El documento como JSON W3C, con claves ordenadas y legible.
    public var json: String {
        let data = (try? JSONSerialization.data(withJSONObject: groups, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])) ?? Data()
        return String(decoding: data, as: UTF8.self)
    }
}

extension Shade {
    /// El color resuelto para un modo, como `#RRGGBB`.
    public func hex(mode: TokenMode) -> String {
        var environment = EnvironmentValues()
        environment.colorScheme = mode == .dark ? .dark : .light
        let resolved = color(for: environment.colorScheme).resolve(in: environment)
        func channel(_ value: Float) -> Int { Int((max(0, min(1, value)) * 255).rounded()) }
        return String(format: "#%02X%02X%02X", channel(resolved.red), channel(resolved.green), channel(resolved.blue))
    }
}

extension Font.TextStyle {
    /// El tamaño nominal del estilo de texto a tamaño normal, en puntos. Para el token de tipografía.
    var nominalSize: CGFloat {
        switch self {
        case .largeTitle: 34
        case .title: 28
        case .title2: 22
        case .title3: 20
        case .headline: 17
        case .body: 17
        case .callout: 16
        case .subheadline: 15
        case .footnote: 13
        case .caption: 12
        case .caption2: 11
        @unknown default: 17
        }
    }

    /// El peso por defecto del estilo: los titulares vienen en semibold.
    var nominalWeight: Font.Weight {
        self == .headline ? .semibold : .regular
    }
}

extension Font.Weight {
    /// El peso en la escala numérica del formato W3C (100–900).
    var w3cValue: Int {
        switch self {
        case .ultraLight: 100
        case .thin: 200
        case .light: 300
        case .regular: 400
        case .medium: 500
        case .semibold: 600
        case .bold: 700
        case .heavy: 800
        case .black: 900
        default: 400
        }
    }
}
