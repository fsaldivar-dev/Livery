//
//  ButtonsSection.swift
//  Showcase
//
//  La matriz del contrato: variante × tamaño, normal y deshabilitado. Sale sola del contrato,
//  que es lo que diseño quiere ver en una revisión.
//

import DesignSystem
import Livery
import SwiftUI

struct ButtonsSection: View {
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionTitle(text: "Botón · variante × tamaño · normal / deshabilitado")
            ForEach([ControlSize.small, .regular, .large], id: \.self) { size in
                HStack(alignment: .top, spacing: theme.space.md) {
                    Text(String(describing: size))
                        .font(theme.type.caption)
                        .foregroundStyle(theme.color.onSurfaceSecondary)
                        .frame(width: 64, alignment: .leading)
                        .padding(.top, theme.space.sm)
                    VStack(alignment: .leading, spacing: theme.space.sm) {
                        row(disabled: false)
                        row(disabled: true)
                    }
                }
                .controlSize(size)
                .padding(.top, theme.space.md)
            }
        }
    }

    private func row(disabled: Bool) -> some View {
        HStack(spacing: theme.space.sm) {
            Button { } label: { Label("Analizar", systemImage: "play.fill") }.buttonStyle(.primary)
            Button("Guardar") { }.buttonStyle(.secondary)
            Button("Borrar", role: .destructive) { }.buttonStyle(.secondary)
        }
        .disabled(disabled)
    }
}
