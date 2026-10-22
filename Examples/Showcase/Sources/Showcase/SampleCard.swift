//
//  SampleCard.swift
//  Showcase
//
//  Una vista "real": habla solo en roles, por referencia `.theme…`, sin `@Environment` ni valores sueltos.
//

import DesignSystem
import Livery
import SwiftUI

struct SampleCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Sajaru Corner")
                .font(theme.type.title)
                .foregroundStyle(them)
            Text("This is a some text")
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
                    .background(theme.color.accent, cornerRadius: theme.shape.small)
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
        .background(theme.color.surfaceElevated, cornerRadius: theme.shape.medium)
        .overlay {
            ThemeValue(theme.shape.medium) { radius in
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(theme.color.outline)
            }
        }
    }
}
