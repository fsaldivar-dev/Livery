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
            Text("Sajaru Corner")
                .font(theme.type.title)
                .foregroundStyle(theme.color.onSurface)
            Text("Round 3 · 2:14 · Sparring")
                .font(theme.type.caption)
                .foregroundStyle(theme.color.onSurfaceSecondary)
                .padding(.top, theme.space.xs)
            Text("Dos golpes limpios al cuerpo en los primeros veinte segundos; la guardia baja después del clinch.")
                .font(theme.type.body)
                .foregroundStyle(theme.color.onSurface)
                .padding(.top, theme.space.md)
            HStack(spacing: 0) {
                Label("Analizar", systemImage: "play.fill")
                    .font(theme.type.headline)
                    .foregroundStyle(theme.color.onAccent)
                    .padding(.vertical, theme.space.sm)
                    .padding(.horizontal, theme.space.md)
                    .background(theme.color.accent, in: .rect(cornerRadius: theme.shape.small))
                Label("Descartar", systemImage: "trash")
                    .font(theme.type.headline)
                    .foregroundStyle(theme.color.danger)
                    .padding(.vertical, theme.space.sm)
                    .padding(.horizontal, theme.space.md)
            }
            .padding(.top, theme.space.lg)
        }
        .padding(theme.space.lg)
        .frame(maxWidth: 520, alignment: .leading)
        .background(theme.color.surfaceElevated, in: .rect(cornerRadius: theme.shape.medium))
        .overlay {
            RoundedRectangle(cornerRadius: theme.shape.medium, style: .continuous)
                .stroke(theme.color.outline)
        }
    }
}

#Preview {
    SampleCard()
        .padding()
        .environment(\.theme, .daylight)
}
