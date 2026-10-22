//
//  ButtonStyle.swift
//  DesignSystem
//
//  El adaptador a SwiftUI. Es un `ButtonStyle` de verdad, así el botón hereda teclado, VoiceOver,
//  `Button(role:)` y el estado presionado. Se usa como cualquier estilo de SwiftUI:
//
//      Button("Analizar") { … }.buttonStyle(.primary)
//      Button("Borrar", role: .destructive) { … }.buttonStyle(.secondary)   // el rol gana
//      HStack { … }.controlSize(.large)                                       // el tamaño es el de SwiftUI
//

import Livery

public struct ThemedButtonStyle: ButtonStyle {
    let variant: Button.Variant

    @Environment(\.theme) private var theme
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.controlSize) private var controlSize

    public func makeBody(configuration: Configuration) -> some View {
        // 1. Qué botón es: la variante pedida, salvo que SwiftUI diga que es destructivo.
        let variant = configuration.role == .destructive ? .destructive : self.variant
        let size = Button.Size(controlSize)
        let state = ComponentState(isEnabled: isEnabled, isPressed: configuration.isPressed)

        // 2. Qué dice el tema para ese botón.
        let look = theme.button.look(for: variant)
        let metrics = theme.button.metrics(for: size)
        let effect = theme.button.effect(for: state)

        // 3. Pintarlo con modificadores nativos.
        configuration.label
            .labelStyle(.iconTinted(look.icon.map { theme.color[$0] }))
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .font(theme.type[metrics.font])
            .foregroundStyle(theme.color[look.foreground])
            .padding(.vertical, theme.space[metrics.vertical])
            .padding(.horizontal, theme.space[metrics.horizontal])
            .frame(minHeight: size.minimumHitTarget)
            .background(theme.color[look.background], in: .rect(cornerRadius: theme.shape[metrics.radius]))
            .overlay {
                if let border = look.border {
                    RoundedRectangle(cornerRadius: theme.shape[metrics.radius]).stroke(theme.color[border])
                }
            }
            .opacity(effect.opacity)
            .contentShape(.rect(cornerRadius: theme.shape[metrics.radius]))
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == ThemedButtonStyle {
    public static var primary: ThemedButtonStyle { ThemedButtonStyle(variant: .primary) }
    public static var secondary: ThemedButtonStyle { ThemedButtonStyle(variant: .secondary) }
    public static var destructive: ThemedButtonStyle { ThemedButtonStyle(variant: .destructive) }
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

/// Tiñe el icono de un `Label` sin tocar el texto. Sin color, el icono sigue al texto.
private struct IconTintedLabelStyle: LabelStyle {
    let icon: Shade?
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            if let icon { configuration.icon.foregroundStyle(icon) } else { configuration.icon }
            configuration.title
        }
    }
}

extension LabelStyle where Self == IconTintedLabelStyle {
    static func iconTinted(_ icon: Shade?) -> IconTintedLabelStyle { IconTintedLabelStyle(icon: icon) }
}
