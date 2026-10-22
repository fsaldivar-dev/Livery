//
//  Sections.swift
//  Showcase
//
//  La galería recorre los roles con `CaseIterable` y los lee con el subscript `theme.color[.accent]`.
//  Aquí sí hace falta `@Environment(\.theme)`: es lógica, no un modificador.
//

import DesignSystem
import Livery
import SwiftUI

struct SectionTitle: View {
    let text: String
    var body: some View {
        Text(text)
            .font(\.type.headline)
            .foregroundStyle(\.color.onSurfaceSecondary)
            .textCase(.uppercase)
    }
}

struct ColorsSection: View {
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionTitle(text: "Color · claro / oscuro / actual")
            ForEach(Colors.allCases, id: \.self) { role in
                let shade = theme.color[role]
                HStack(spacing: 0) {
                    Text(String(describing: role))
                        .font(\.type.body)
                        .foregroundStyle(\.color.onSurface)
                        .frame(width: 180, alignment: .leading)
                    Swatch(color: shade.light)
                    Swatch(color: shade.dark)
                        .padding(.leading, \.space.sm)
                    Swatch(color: shade.resolve(in: environmentValues))
                        .padding(.leading, \.space.sm)
                }
                .padding(.top, \.space.sm)
            }
        }
    }

    @Environment(\.self) private var environmentValues
}

private struct Swatch: View {
    let color: Color
    var body: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(color)
            .frame(width: 56, height: 28)
            .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).stroke(\.color.outline))
    }
}

struct TypographySection: View {
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionTitle(text: "Tipografía")
            ForEach(Typography.allCases, id: \.self) { role in
                Text("\(String(describing: role)) · The quick brown fox")
                    .font(theme.type[role])
                    .foregroundStyle(\.color.onSurface)
                    .padding(.top, \.space.sm)
            }
        }
    }
}

struct SpacingSection: View {
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionTitle(text: "Espaciado")
            ForEach(Spacing.allCases, id: \.self) { role in
                let value = theme.space[role]
                HStack(spacing: 0) {
                    Text("\(String(describing: role)) · \(Int(value)) pt")
                        .font(\.type.body)
                        .foregroundStyle(\.color.onSurface)
                        .frame(width: 180, alignment: .leading)
                    Rectangle()
                        .fill(\.color.accent)
                        .frame(width: value * 4, height: 12)
                }
                .padding(.top, \.space.sm)
            }
        }
    }
}

struct ShapesSection: View {
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionTitle(text: "Forma")
            HStack(spacing: 0) {
                ForEach(Shapes.allCases, id: \.self) { role in
                    let radius = theme.shape[role]
                    VStack(spacing: 0) {
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .fill(\.color.accent)
                            .frame(width: 72, height: 48)
                        Text("\(String(describing: role)) · \(Int(radius))")
                            .font(\.type.caption)
                            .foregroundStyle(\.color.onSurfaceSecondary)
                            .padding(.top, \.space.xs)
                    }
                    .padding(.trailing, \.space.lg)
                }
            }
            .padding(.top, \.space.sm)
        }
    }
}
