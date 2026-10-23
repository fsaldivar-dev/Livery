//
//  PrimitivesSection.swift
//  Showcase
//
//  Los primitivos que SwiftUI ya da, tematizados sin inventar nada: `Text`, `Button`, un icono
//  (`Label` con un SF Symbol) y el switch (`Toggle`). La regla: no construimos componentes nuevos
//  para lo que el sistema ya resuelve; solo aplicamos los roles del tema y los estilos nativos.
//
//  El switch y otros controles nativos siguen el `tint` del entorno, que la galería pone al color
//  de acento del tema. Así un `Toggle` sale del color del tema sin tocarlo.
//

import DesignSystem
import Livery
import SwiftUI

struct PrimitivesSection: View {
    @Environment(\.theme) private var theme
    @State private var activo = true
    @State private var favorito = false

    var body: some View {
        VStack(alignment: .leading, spacing: theme.space.md) {
            SectionTitle(text: "Primitivos de SwiftUI, tematizados")

            // Texto: un estilo semántico junta fuente y color.
            VStack(alignment: .leading, spacing: theme.space.xs) {
                Text("Título").textStyle(.title)
                Text("Texto secundario, con su rol de color.").textStyle(.secondary)
            }

            Divider()

            // Iconos semánticos: la vista pide `theme.icon.play`, no "play.circle.fill".
            HStack(spacing: theme.space.lg) {
                Image(theme.icon.brand)   // icono propio, SVG empaquetado, teñido como cualquier símbolo
                    .foregroundStyle(theme.color.accent)
                    .font(theme.type.title)
                Label { Text("Reproducir") } icon: { Image(theme.icon.play) }.textStyle(.accent)
                Label { Text("Buscar") } icon: { Image(theme.icon.search) }.textStyle(.body)
                // Un icono animado con symbolEffect, enganchado al toque.
                Button { favorito.toggle() } label: {
                    Image(theme.icon.favorite)
                        .symbolEffect(.bounce, value: favorito)
                        .foregroundStyle(favorito ? theme.color.accent : theme.color.onSurfaceSecondary)
                }
                .buttonStyle(.plain)
                .font(theme.type.title)
            }

            Divider()

            // Botón y switch nativos. El botón usa nuestro estilo; el switch sigue el tint del tema.
            HStack(spacing: theme.space.lg) {
                Button("Acción") { }.buttonStyle(.themed(.prominent))
                Toggle("Notificaciones", isOn: $activo)
                    .toggleStyle(.switch)
                    .fixedSize()
                    .textStyle(.body)
            }
        }
    }
}
