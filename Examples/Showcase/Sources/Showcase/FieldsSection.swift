//
//  FieldsSection.swift
//  Showcase
//
//  El campo en sus estados: en reposo, y con error. El foco se ve al hacer clic en el campo.
//

import DesignSystem
import Livery
import SwiftUI

struct FieldsSection: View {
    @Environment(\.theme) private var theme
    @State private var name = "Francisco"
    @State private var email = "fran@"

    var body: some View {
        VStack(alignment: .leading, spacing: theme.space.md) {
            SectionTitle(text: "Campo · reposo · foco (clic) · error")
            HStack(alignment: .top, spacing: theme.space.lg) {
                FormField("Nombre", text: $name, prompt: "Tu nombre")
                FormField("Correo", text: $email, prompt: "nombre@dominio.com", error: "Falta el dominio")
            }
        }
    }
}
