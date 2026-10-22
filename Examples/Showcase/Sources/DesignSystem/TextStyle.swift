//
//  TextStyle.swift
//  DesignSystem
//
//  Un estilo de texto junta la fuente y el color en una decisión semántica, para no escribir
//  `.font(…)` y `.foregroundStyle(…)` en cada `Text`. No es un componente nuevo: es un modificador
//  sobre vistas nativas, así que sirve igual para `Text`, `Label` y la etiqueta de un `Toggle`.
//
//      Text("Título").textStyle(.title)
//      Label("Favorito", systemImage: "star").textStyle(.accent)
//      Toggle("Notificaciones", isOn: $on).textStyle(.body)
//

import Livery

/// Los estilos de texto del sistema: cada uno es un par (rol de tipografía, rol de color).
public enum TextRole: Sendable {
    case title, headline, body, secondary, caption, accent, danger
}

extension View {
    /// Aplica la fuente y el color de un estilo de texto, en una sola llamada.
    public func textStyle(_ role: TextRole) -> some View {
        modifier(TextStyleModifier(role: role))
    }
}

private struct TextStyleModifier: ViewModifier {
    @Environment(\.theme) private var theme
    let role: TextRole

    func body(content: Content) -> some View {
        content
            .font(theme.type[font])
            .foregroundStyle(theme.color[color])
    }

    private var font: Typography {
        switch role {
        case .title: .title
        case .headline, .accent, .danger: .headline
        case .body, .secondary: .body
        case .caption: .caption
        }
    }

    private var color: Colors {
        switch role {
        case .title, .headline, .body: .onSurface
        case .secondary, .caption: .onSurfaceSecondary
        case .accent: .accent
        case .danger: .danger
        }
    }
}
