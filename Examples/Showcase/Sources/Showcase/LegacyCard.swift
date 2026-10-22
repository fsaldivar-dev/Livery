//
//  LegacyCard.swift
//  Showcase
//
//  Una vista escrita contra el sistema anterior y todavía no migrada. Compila y se ve con el
//  tema nuevo gracias al puente; cada rol viejo es un warning con fix-it. Los warnings de este
//  archivo son intencionales: así se ve una migración a medias.
//

import DesignSystem
import Livery
import SwiftUI

struct LegacyCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionTitle(text: "Migración · vista sin migrar (ColorsV1)")
            HStack(spacing: 0) {
                Text("Leída con `theme.color.primary`")
                    .font(theme.type.body)
                    .foregroundStyle(theme.color.primary)
                Rectangle()
                    .fill(theme.color.divider)
                    .frame(width: 1, height: 20)
                    .padding(.horizontal, theme.space.md)
                Text("y `theme.color.cardBackground`")
                    .font(theme.type.body)
                    .foregroundStyle(theme.color.onSurface)
                    .padding(theme.space.sm)
                    .background(theme.color.cardBackground, cornerRadius: theme.shape.small)
            }
            .padding(.top, theme.space.sm)
        }
    }
}
