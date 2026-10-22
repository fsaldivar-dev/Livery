//
//  ButtonStyle.swift
//  DesignSystem
//
//  El adaptador a SwiftUI: un `ButtonStyle` de verdad, así el botón hereda teclado, VoiceOver,
//  `Button(role:)` y el estado presionado. El tamaño respeta `.controlSize`, el estado sale de
//  `isEnabled` y `configuration.isPressed`, y el área táctil mínima la garantiza el estilo.
//
//      Button("Analizar") { … }.buttonStyle(.primary)
//      Button("Borrar", role: .destructive) { … }.buttonStyle(.secondary)   // el rol gana
//      HStack { … }.controlSize(.large)
//

import Livery

public struct ThemedButtonStyle: ButtonStyle {
    let kind: Button.Kind

    @Environment(\.theme) private var theme
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.controlSize) private var controlSize

    public func makeBody(configuration: Configuration) -> some View {
        let size = Button.Size(controlSize)
        let state: ComponentState = !isEnabled ? .disabled : configuration.isPressed ? .pressed : .normal
        let kind: Button.Kind = configuration.role == .destructive ? .destructive : self.kind
        let parts = theme.button.attributes(variant: kind, size: size, state: state)
        let container = parts[.container]!.resolved(in: theme)
        let label = parts[.label]!.resolved(in: theme)
        let icon = parts[.icon]!.resolved(in: theme)

        configuration.label
            .labelStyle(ButtonLabelStyle(icon: icon.foreground))
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)   // un botón no parte su texto
            .font(label.font)
            .foregroundStyle(label.foreground ?? Shade.unresolved)
            .padding(.vertical, container.paddingVertical)
            .padding(.horizontal, container.paddingHorizontal)
            .frame(minHeight: size.minimumHitTarget)
            .background(container.background ?? Shade(.clear), in: .rect(cornerRadius: container.radius, style: .continuous))
            .overlay {
                if let border = container.border {
                    RoundedRectangle(cornerRadius: container.radius, style: .continuous).stroke(border)
                }
            }
            .opacity(container.opacity)
            .contentShape(.rect(cornerRadius: container.radius))
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == ThemedButtonStyle {
    public static var primary: ThemedButtonStyle { ThemedButtonStyle(kind: .primary) }
    public static var secondary: ThemedButtonStyle { ThemedButtonStyle(kind: .secondary) }
    public static var destructive: ThemedButtonStyle { ThemedButtonStyle(kind: .destructive) }
}

extension Button.Size {
    /// El tamaño del contrato sigue al `controlSize` de SwiftUI: ningún modificador nuevo que aprender.
    init(_ controlSize: ControlSize) {
        switch controlSize {
        case .mini, .small: self = .small
        case .large, .extraLarge: self = .large
        default: self = .medium
        }
    }
}

/// Aplica el color de la parte `icon` sin tocar el del texto.
private struct ButtonLabelStyle: LabelStyle {
    let icon: Shade?
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            if let icon { configuration.icon.foregroundStyle(icon) } else { configuration.icon }
            configuration.title
        }
    }
}
