//
//  ButtonStyle.swift
//  DesignSystem
//
//  El adaptador a SwiftUI. Es un `ButtonStyle` de verdad, con los nombres de Apple, así el botón
//  hereda teclado, VoiceOver y `Button(role:)`, y se usa como cualquier estilo del sistema:
//
//      Button("Guardar") { … }.buttonStyle(.themed(.prominent))         // acción principal
//      Button("Cancelar") { … }.buttonStyle(.themed(.bordered))         // acción estándar
//      Button("Más") { … }.buttonStyle(.themed(.plain))                 // acción terciaria
//      Button("Borrar", role: .destructive) { … }.buttonStyle(.themed(.prominent))  // el rol lo pinta de rojo
//      HStack { … }.controlSize(.large)                                 // el tamaño es el de SwiftUI
//
//  Se llama `.themed(_:)` y no `.bordered`/`.plain` a secas porque esos nombres ya son estilos de
//  botón de SwiftUI; la variante sí usa el vocabulario de Apple.
//

import Livery

public struct ThemedButtonStyle: ButtonStyle {
    let variant: Button.Variant

    @Environment(\.theme) private var theme
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.controlSize) private var controlSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public func makeBody(configuration: Configuration) -> some View {
        let style = theme.button
        let metrics = style.metrics(for: Button.Size(controlSize))
        let state = ComponentState(isEnabled: isEnabled, isPressed: configuration.isPressed)
        let effect = style.effect(for: state)
        let paint = paint(style, destructive: configuration.role == .destructive)

        configuration.label
            .labelStyle(.iconTinted(paint.content))
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .font(theme.type[metrics.font])
            .foregroundStyle(paint.content)
            .padding(.vertical, theme.space[metrics.vertical])
            .padding(.horizontal, theme.space[metrics.horizontal])
            .background(paint.background ?? Shade(.clear), in: .capsule)
            .opacity(effect.opacity)
            .scaleEffect(effect.scale)
            .frame(minHeight: Button.Size(controlSize).minimumHitTarget)   // HIG: área táctil de 44 pt
            .contentShape(.capsule)
            .animation(theme.motion[effect.motion].resolve(reduceMotion: reduceMotion), value: state)
    }

    /// El relleno y el color de contenido según el estilo. El tinte lo da el tema; el rol
    /// destructivo lo cambia a rojo. Cada estilo de Apple lo pinta distinto.
    private func paint(_ style: Button.Style, destructive: Bool) -> (background: Shade?, content: Shade) {
        let tint = destructive ? theme.color.danger : theme.color[style.tint]
        let onTint = theme.color[style.onTint]
        switch style.treatment(for: variant) {
        case .solid: return (tint, onTint)
        case .soft:  return (tint.opacity(0.15), tint)
        case .text:  return (nil, tint)
        }
    }
}

extension ButtonStyle where Self == ThemedButtonStyle {
    /// El botón del sistema de diseño, con el estilo de Apple que pidas:
    /// `.prominent` (acción principal), `.bordered` (estándar) o `.plain` (terciaria).
    public static func themed(_ variant: Button.Variant) -> ThemedButtonStyle {
        ThemedButtonStyle(variant: variant)
    }
}

extension Button.Size {
    /// El tamaño del contrato sigue al `controlSize` de SwiftUI: nada nuevo que aprender.
    init(_ controlSize: ControlSize) {
        switch controlSize {
        case .mini, .small: self = .small
        case .large, .extraLarge: self = .large
        default: self = .medium
        }
    }
}

extension ComponentState {
    /// El estado tal como lo reporta SwiftUI.
    init(isEnabled: Bool, isPressed: Bool) {
        self = !isEnabled ? .disabled : isPressed ? .pressed : .normal
    }
}

/// Tiñe el icono de un `Label` con el color del contenido. Para que el icono siga al texto.
private struct IconTintedLabelStyle: LabelStyle {
    let icon: Shade
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            configuration.icon.foregroundStyle(icon)
            configuration.title
        }
    }
}

extension LabelStyle where Self == IconTintedLabelStyle {
    static func iconTinted(_ icon: Shade) -> IconTintedLabelStyle { IconTintedLabelStyle(icon: icon) }
}
