//
//  Palette.swift
//  Primitives
//
//  Los valores crudos del sistema. Nombres de pintura, no de intención: aquí no hay `accent`
//  ni `surface`, eso lo deciden los temas. Este módulo solo lo importa DesignSystem.
//

import Livery
import SwiftUI

@Primitives public enum Palette {
    public static let white    = Color.white
    public static let mist     = Color(red: 0.96, green: 0.96, blue: 0.97)
    public static let fog      = Color(red: 0.86, green: 0.87, blue: 0.90)
    public static let slate    = Color(red: 0.45, green: 0.47, blue: 0.52)
    public static let graphite = Color(red: 0.16, green: 0.17, blue: 0.20)
    public static let ink      = Color(red: 0.09, green: 0.10, blue: 0.12)

    public static let jade300   = Color(red: 0.40, green: 0.80, blue: 0.64)
    public static let jade500   = Color(red: 0.00, green: 0.60, blue: 0.40)
    public static let orange300 = Color(red: 1.00, green: 0.70, blue: 0.40)
    public static let orange500 = Color(red: 0.95, green: 0.45, blue: 0.10)
    public static let red300    = Color(red: 1.00, green: 0.55, blue: 0.55)
    public static let red500    = Color(red: 0.85, green: 0.15, blue: 0.20)
}

@Primitives public enum Metrics {
    /// Unidad base de la escala de espaciado.
    public static let unit: CGFloat = 4
}
