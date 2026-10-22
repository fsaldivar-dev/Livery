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
    // Neutros con un punto de azul, del papel a la tinta.
    public static let slate50  = Color(hex: 0xF8FAFC)
    public static let slate100 = Color(hex: 0xF1F5F9)
    public static let slate200 = Color(hex: 0xE2E8F0)
    public static let slate300 = Color(hex: 0xCBD5E1)
    public static let slate400 = Color(hex: 0x94A3B8)
    public static let slate500 = Color(hex: 0x64748B)
    public static let slate600 = Color(hex: 0x475569)
    public static let slate700 = Color(hex: 0x334155)
    public static let slate800 = Color(hex: 0x1E293B)
    public static let slate900 = Color(hex: 0x0F172A)
    public static let slate950 = Color(hex: 0x020617)

    public static let indigo300 = Color(hex: 0xA5B4FC)
    public static let indigo400 = Color(hex: 0x818CF8)
    public static let indigo500 = Color(hex: 0x6366F1)
    public static let indigo600 = Color(hex: 0x4F46E5)

    public static let amber300 = Color(hex: 0xFCD34D)
    public static let amber400 = Color(hex: 0xFBBF24)
    public static let amber500 = Color(hex: 0xF59E0B)

    public static let violet400 = Color(hex: 0xA78BFA)
    public static let violet500 = Color(hex: 0x8B5CF6)

    public static let rose400 = Color(hex: 0xFB7185)
    public static let rose600 = Color(hex: 0xE11D48)

    public static let white = Color.white
}

@Primitives public enum Metrics {
    /// Unidad base de la escala de espaciado.
    public static let unit: CGFloat = 4
}

extension Color {
    /// `0xRRGGBB`. Solo para la paleta: las vistas nunca ven un hex.
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
