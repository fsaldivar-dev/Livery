//
//  FieldView.swift
//  DesignSystem
//
//  La vista del campo. TextField de SwiftUI no deja estilizar el contorno, así que el campo es
//  una vista propia que compone etiqueta + campo + mensaje y sigue el foco con `@FocusState`.
//
//      FormField("Correo", text: $correo, prompt: "nombre@dominio.com")
//      FormField("Correo", text: $correo, error: "Falta la arroba")   // pinta el borde de error
//

import Livery

public struct FormField: View {
    private let title: String
    @Binding private var text: String
    private let prompt: String?
    private let error: String?

    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var focused: Bool

    public init(_ title: String, text: Binding<String>, prompt: String? = nil, error: String? = nil) {
        self.title = title
        self._text = text
        self.prompt = prompt
        self.error = error
    }

    public var body: some View {
        let style = theme.field
        let border = theme.color[style.borderColor(focused: focused, invalid: error != nil)]
        let radius = theme.shape[style.radius]

        VStack(alignment: .leading, spacing: theme.space[style.gap]) {
            Text(title)
                .font(theme.type[style.label])
                .foregroundStyle(theme.color[style.labelColor])

            TextField("", text: $text, prompt: promptText(style))
                .textFieldStyle(.plain)
                .font(theme.type[style.text])
                .foregroundStyle(theme.color[style.textColor])
                .focused($focused)
                .padding(.vertical, theme.space[style.vertical])
                .padding(.horizontal, theme.space[style.horizontal])
                .background(theme.color[style.fill], in: .rect(cornerRadius: radius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .stroke(border, lineWidth: focused ? 2 : 1)
                }
                .animation(theme.motion[style.focus].resolve(reduceMotion: reduceMotion), value: focused)
                .animation(theme.motion[style.focus].resolve(reduceMotion: reduceMotion), value: error != nil)

            if let error {
                Text(error)
                    .font(theme.type[style.message])
                    .foregroundStyle(theme.color[style.invalid])
            }
        }
    }

    private func promptText(_ style: Field.Style) -> Text? {
        prompt.map { Text($0).foregroundStyle(theme.color[style.placeholder]) }
    }
}
