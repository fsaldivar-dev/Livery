//
//  Contrast.swift
//  Livery
//
//  Verifica el contraste WCAG entre pares de roles de color. Como el export, necesita el color
//  resuelto (la luminancia), así que es de runtime: el plugin genera `theme.contrastReport()` y
//  una app lo pone en un test, de modo que CI lo verifique.
//
//  La convención de pares es por nombre: un rol `onX` es texto sobre el fondo `X` (`onSurface`
//  sobre `surface`, `onAccent` sobre `accent`). Si el fondo con ese nombre no existe, se compara
//  contra `surface`, el fondo por defecto.
//

import SwiftUI

/// El nivel WCAG a exigir. AA es el estándar; AAA es más estricto.
public enum WCAGLevel: Sendable {
    case AA, AAA
    /// Ratio mínimo para texto normal.
    public var minimumRatio: Double { self == .AAA ? 7 : 4.5 }
}

/// Un par de roles cuyo contraste no llega al mínimo.
public struct ContrastIssue: Sendable, CustomStringConvertible {
    public var foreground: String
    public var background: String
    public var mode: TokenMode
    public var ratio: Double
    public var required: Double

    public var description: String {
        String(format: "%@ sobre %@ (%@): %.2f:1, por debajo de %.1f:1",
               foreground, background, mode.rawValue, ratio, required)
    }
}

public enum ContrastChecker {
    /// Comprueba los pares `onX`/`X` de una lista de roles de color, en claro y oscuro.
    public static func check(_ roles: [(name: String, shade: Shade)], level: WCAGLevel = .AA) -> [ContrastIssue] {
        let byName = Dictionary(roles.map { ($0.name, $0.shade) }, uniquingKeysWith: { first, _ in first })
        var issues: [ContrastIssue] = []
        for (name, foreground) in roles {
            guard let (backgroundName, background) = background(for: name, in: byName) else { continue }
            for mode in [TokenMode.light, .dark] {
                let ratio = foreground.contrastRatio(against: background, mode: mode)
                if ratio < level.minimumRatio {
                    issues.append(ContrastIssue(foreground: name, background: backgroundName, mode: mode,
                                                ratio: ratio, required: level.minimumRatio))
                }
            }
        }
        return issues.sorted { $0.ratio < $1.ratio }
    }

    /// Para un rol `onX`, su fondo: el rol `X`, o `surface` si no existe.
    private static func background(for name: String, in roles: [String: Shade]) -> (String, Shade)? {
        guard name.count > 2, name.hasPrefix("on"), let third = name.dropFirst(2).first, third.isUppercase else { return nil }
        let base = name.dropFirst(2).prefix(1).lowercased() + name.dropFirst(3)
        if let shade = roles[base] { return (base, shade) }
        if let surface = roles["surface"] { return ("surface", surface) }
        return nil
    }
}

extension Shade {
    /// El ratio de contraste WCAG contra otro color en un modo: `(L1 + 0.05) / (L2 + 0.05)`.
    public func contrastRatio(against other: Shade, mode: TokenMode) -> Double {
        let a = luminance(mode: mode)
        let b = other.luminance(mode: mode)
        let (hi, lo) = a > b ? (a, b) : (b, a)
        return (hi + 0.05) / (lo + 0.05)
    }

    /// La luminancia relativa (0…1) del color resuelto para un modo.
    public func luminance(mode: TokenMode) -> Double {
        var environment = EnvironmentValues()
        environment.colorScheme = mode == .dark ? .dark : .light
        let resolved = color(for: environment.colorScheme).resolve(in: environment)
        return 0.2126 * Double(resolved.linearRed)
             + 0.7152 * Double(resolved.linearGreen)
             + 0.0722 * Double(resolved.linearBlue)
    }
}
