//
//  SampleCard.swift
//  Showcase
//
//  Una vista "real": habla solo en roles, por key path, sin `@Environment` ni valores sueltos.
//

import DesignSystem
import Livery
import SwiftUI

struct SampleCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Sajaru Corner")
                .font(\.type.title)
                .foregroundStyle(\.color.onSurface)
            Text("Round 3 · 2:14 · Sparring")
                .font(\.type.caption)
                .foregroundStyle(\.color.onSurfaceSecondary)
                .padding(.top, \.space.xs)
            Text("Dos golpes limpios al cuerpo en los primeros veinte segundos; la guardia baja después del clinch.")
                .font(\.type.body)
                .foregroundStyle(\.color.onSurface)
                .padding(.top, \.space.md)
            HStack(spacing: 0) {
                Label("Analizar", systemImage: "play.fill")
                    .font(\.type.headline)
                    .foregroundStyle(\.color.onAccent)
                    .padding(.vertical, \.space.sm)
                    .padding(.horizontal, \.space.md)
                    .background(\.color.accent, cornerRadius: \.shape.small)
                Label("Descartar", systemImage: "trash")
                    .font(\.type.headline)
                    .foregroundStyle(\.color.danger)
                    .padding(.vertical, \.space.sm)
                    .padding(.horizontal, \.space.md)
            }
            .padding(.top, \.space.lg)
        }
        .padding(\.space.lg)
        .frame(maxWidth: 520, alignment: .leading)
        .background(\.color.surfaceElevated, cornerRadius: \.shape.medium)
        .overlay {
            ThemeValue(keyPath: \.shape.medium) { radius in
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(\.color.outline)
            }
        }
    }
}
