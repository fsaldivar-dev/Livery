//
//  SampleCard.swift
//  Showcase
//
//  Una vista "real": lee el tema del entorno y habla solo en roles. `theme` es un `Theme` con
//  tipo declarado aquí mismo, así que cada paso autocompleta y todo va a modificadores nativos.
//

import DesignSystem
import Livery
import SwiftUI

struct SampleCard: View {
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Sajaru Corner").textStyle(.title)
            Text("Round 3 · 2:14 · Sparring")
                .textStyle(.caption)
                .padding(.top, theme.space.xs)
            Text("Dos golpes limpios al cuerpo en los primeros veinte segundos; la guardia baja después del clinch.")
                .textStyle(.body)
                .padding(.top, theme.space.md)
            HStack(spacing: theme.space.sm) {
                Button { } label: { Label("Analizar", systemImage: "play.fill") }
                    .buttonStyle(.themed(.prominent))
                Button(role: .destructive) { } label: { Label("Descartar", systemImage: "trash") }
                    .buttonStyle(.themed(.bordered))
            }
            .padding(.top, theme.space.lg)
        }
        .padding(theme.space.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.color.surfaceElevated, in: .rect(cornerRadius: theme.shape.medium))
        .overlay {
            RoundedRectangle(cornerRadius: theme.shape.medium, style: .continuous)
                .stroke(theme.color.outline)
        }
        .elevation(theme.elevation.popover)
    }
}

#Preview {
    SampleCard()
        .padding()
        .environment(\.theme, .daylight)
}
