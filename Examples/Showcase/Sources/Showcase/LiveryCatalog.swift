//
//  LiveryCatalog.swift
//  Showcase
//
//  El catálogo del sistema de diseño, como lo vería una app de iPhone: un título grande, un menú
//  de categorías arriba y, debajo, SOLO la categoría elegida, con un campo de búsqueda. Todo sale
//  de los tokens del tema —color, tipografía, espacio, forma, elevación, icono—; cambia el tema y
//  el catálogo se repinta sin tocar una línea de esta vista.
//
//  Está compuesto con vistas nativas y tokens (sin `List` ni `.searchable` del sistema) para que se
//  vea igual en la ventana y en una captura (`--catalog`). El menú es un control segmentado propio,
//  tocable: cambia `category` y la parte de abajo cambia con él.
//

import DesignSystem
import Livery
import SwiftUI

public struct LiveryCatalog: View {
    public enum Category: String, CaseIterable, Identifiable {
        case colores = "Colores"
        case tipografia = "Tipografía"
        case espaciado = "Espaciado"
        case componentes = "Componentes"
        public var id: String { rawValue }
    }

    @Environment(\.theme) private var theme
    @State private var category: Category

    public init(category: Category = .colores) {
        _category = State(initialValue: category)
    }

    public var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: theme.space.md) {
                Text("Livery").textStyle(.title)

                CategoryMenu(selection: $category)
                SearchField(placeholder: "Buscar en \(category.rawValue)")

                Text(category.rawValue)
                    .textStyle(.caption)
                    .padding(.leading, theme.space.xs)

                Group {
                    switch category {
                    case .colores:     ColorList()
                    case .tipografia:  TypeList()
                    case .espaciado:   SpaceList()
                    case .componentes: ComponentList()
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, theme.space.md)
            .padding(.top, theme.space.lg)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(theme.color.surface)
            .hideNavigationBar()
            .navigationDestination(for: ShowcaseComponent.self) { component in
                ComponentShowcase(component: component)
            }
        }
        .tint(theme.color.accent)
    }
}

private extension View {
    /// Oculta la barra de navegación en iOS (en macOS no existe esa barra) para conservar el
    /// encabezado propio del catálogo; el detalle muestra su propia barra con Atrás.
    @ViewBuilder func hideNavigationBar() -> some View {
        #if os(iOS)
        self.toolbar(.hidden, for: .navigationBar)
        #else
        self
        #endif
    }
}

// MARK: - Menú de categorías (control segmentado propio)

private struct CategoryMenu: View {
    @Environment(\.theme) private var theme
    @Binding var selection: LiveryCatalog.Category

    var body: some View {
        HStack(spacing: 0) {
            ForEach(LiveryCatalog.Category.allCases) { category in
                let active = category == selection
                Button { selection = category } label: {
                    Text(category.rawValue)
                        .font(theme.type.caption)
                        .foregroundStyle(active ? theme.color.onSurface : theme.color.onSurfaceSecondary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, theme.space.sm)
                        .background {
                            if active {
                                RoundedRectangle(cornerRadius: theme.shape.small, style: .continuous)
                                    .fill(theme.color.surfaceElevated)
                                    .elevation(theme.elevation.card)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(theme.space.xs)
        .background(theme.color.outline.opacity(0.5), in: .rect(cornerRadius: theme.shape.medium, style: .continuous))
    }
}

// MARK: - Campo de búsqueda

private struct SearchField: View {
    @Environment(\.theme) private var theme
    let placeholder: String

    var body: some View {
        HStack(spacing: theme.space.sm) {
            Image(theme.icon.search)
                .foregroundStyle(theme.color.onSurfaceSecondary)
            Text(placeholder)
                .font(theme.type.body)
                .foregroundStyle(theme.color.onSurfaceSecondary)
            Spacer(minLength: 0)
        }
        .padding(.vertical, theme.space.sm)
        .padding(.horizontal, theme.space.md)
        .background(theme.color.surfaceElevated, in: .rect(cornerRadius: theme.shape.medium, style: .continuous))
    }
}

// MARK: - Lista agrupada con inserción (contenedor + fila + separador)

/// Una lista agrupada estilo iOS: celdas de superficie con esquinas redondeadas y un borde tenue.
private struct GroupedList<Content: View>: View {
    @Environment(\.theme) private var theme
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) { content }
            .background(theme.color.surfaceElevated, in: .rect(cornerRadius: theme.shape.medium, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: theme.shape.medium, style: .continuous)
                    .stroke(theme.color.outline)
            }
    }
}

/// Un separador fino, insertado bajo el elemento de la izquierda, como en iOS.
private struct RowDivider: View {
    @Environment(\.theme) private var theme
    var inset: CGFloat = 0
    var body: some View {
        Rectangle()
            .fill(theme.color.outline)
            .frame(height: 1)
            .padding(.leading, inset)
    }
}

// MARK: - Colores

private struct ColorList: View {
    @Environment(\.theme) private var theme

    var body: some View {
        GroupedList {
            ForEach(Array(Colors.allCases.enumerated()), id: \.element) { index, role in
                if index > 0 { RowDivider(inset: 30 + theme.space.md + theme.space.md) }
                HStack(spacing: theme.space.md) {
                    RoundedRectangle(cornerRadius: theme.shape.small, style: .continuous)
                        .fill(theme.color[role])
                        .frame(width: 30, height: 30)
                        .overlay {
                            RoundedRectangle(cornerRadius: theme.shape.small, style: .continuous)
                                .stroke(theme.color.outline)
                        }
                    Text(String(describing: role))
                        .font(theme.type.body)
                        .foregroundStyle(theme.color.onSurface)
                    Spacer(minLength: 0)
                    Text(Self.purpose(role))
                        .font(theme.type.caption)
                        .foregroundStyle(theme.color.onSurfaceSecondary)
                }
                .padding(.vertical, theme.space.sm)
                .padding(.horizontal, theme.space.md)
            }
        }
    }

    /// Para qué sirve cada rol: la columna derecha, que da sentido al nombre sin repetirlo.
    static func purpose(_ role: Colors) -> String {
        switch role {
        case .surface:            "Fondo"
        case .surfaceElevated:    "Superficie"
        case .onSurface:          "Texto"
        case .onSurfaceSecondary: "Secundario"
        case .accent:             "Acción"
        case .onAccent:           "Sobre acento"
        case .outline:            "Bordes"
        case .danger:             "Peligro"
        }
    }
}

// MARK: - Tipografía

private struct TypeList: View {
    @Environment(\.theme) private var theme

    var body: some View {
        GroupedList {
            ForEach(Array(Typography.allCases.enumerated()), id: \.element) { index, role in
                if index > 0 { RowDivider(inset: theme.space.md) }
                HStack(spacing: theme.space.md) {
                    Text("El veloz zorro")
                        .font(theme.type[role])
                        .foregroundStyle(theme.color.onSurface)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Text(String(describing: role))
                        .font(theme.type.caption)
                        .foregroundStyle(theme.color.onSurfaceSecondary)
                }
                .padding(.vertical, theme.space.sm)
                .padding(.horizontal, theme.space.md)
            }
        }
    }
}

// MARK: - Espaciado

private struct SpaceList: View {
    @Environment(\.theme) private var theme

    var body: some View {
        GroupedList {
            ForEach(Array(Spacing.allCases.enumerated()), id: \.element) { index, role in
                if index > 0 { RowDivider(inset: theme.space.md) }
                let value = theme.space[role]
                HStack(spacing: theme.space.md) {
                    Text(String(describing: role))
                        .font(theme.type.body)
                        .foregroundStyle(theme.color.onSurface)
                        .frame(width: 44, alignment: .leading)
                    RoundedRectangle(cornerRadius: theme.shape.small, style: .continuous)
                        .fill(theme.color.accent)
                        .frame(width: value, height: 10)
                    Spacer(minLength: 0)
                    Text("\(Int(value)) pt")
                        .font(theme.type.caption)
                        .foregroundStyle(theme.color.onSurfaceSecondary)
                }
                .padding(.vertical, theme.space.sm)
                .padding(.horizontal, theme.space.md)
            }
        }
    }
}

// MARK: - Componentes

/// Cada componente del sistema. La lista crece sin tocar la vista: añade un caso y su cartelera.
enum ShowcaseComponent: String, CaseIterable, Identifiable {
    case boton = "Botón"
    case campo = "Campo"
    case selector = "Selector segmentado"
    case interruptor = "Interruptor"

    var id: String { rawValue }

    /// La línea de apoyo de la fila: qué resuelve el componente.
    var summary: String {
        switch self {
        case .boton:       "Prominente, con borde y plano · rol destructivo"
        case .campo:       "Etiqueta, foco y error"
        case .selector:    "Cambiar entre vistas relacionadas"
        case .interruptor: "Encendido y apagado en una fila"
        }
    }

    /// La ficha del componente, al estilo de la documentación de Apple: qué es, por qué este y no
    /// otro, cuándo sí y cuándo no, cómo se usa, y las reglas de hacer / no hacer.
    var doc: ComponentDoc {
        switch self {
        case .boton:
            ComponentDoc(
                what: "Desencadena una acción. El estilo comunica su importancia; el texto dice qué hace.",
                why: "Un botón actúa. Si solo navega, es un enlace; si solo alterna un estado, es un interruptor.",
                when: "Para la acción principal de la pantalla y las secundarias. Una sola acción prominente por pantalla.",
                how: "Jerarquiza por estilo, no por tamaño: prominente para la principal, con borde para las estándar, plano para las terciarias. El rol destructivo lo pinta de rojo.",
                dos: ["Una sola acción prominente por pantalla", "Un verbo claro: «Guardar», no «OK»", "Área táctil de 44 pt", "El rol destructivo en rojo, nunca como primario"],
                donts: ["No uses el tamaño para marcar jerarquía", "No pongas dos botones prominentes juntos", "No uses un botón para navegar entre vistas"]
            )
        case .campo:
            ComponentDoc(
                what: "Recoge texto corto del usuario, con una etiqueta que dice qué se pide.",
                why: "Para entradas breves. Para texto largo usa un editor; para elegir entre opciones, un selector.",
                when: "Formularios y búsquedas. Varios campos van apilados, del mismo ancho y bien espaciados.",
                how: "La etiqueta siempre visible, aparte del placeholder que desaparece. Teclado adecuado al dato. Valida al salir del campo y marca el error en el borde.",
                dos: ["Etiqueta separada del placeholder", "Un mensaje de error claro y accionable", "El teclado correcto (correo, número)"],
                donts: ["No uses solo el placeholder como etiqueta", "No valides en cada tecla", "No escondas el motivo del error"]
            )
        case .selector:
            ComponentDoc(
                what: "Cambia entre vistas muy relacionadas sin salir de la pantalla.",
                why: "Para subvistas de un mismo contenido. Para secciones distintas de la app usa pestañas.",
                when: "De dos a cinco opciones cortas y excluyentes. Si son muchas o largas, una lista o pestañas.",
                how: "Etiquetas de una o dos palabras, del mismo peso. El segmento activo se eleva; el resto quedan planos.",
                dos: ["Opciones cortas y paralelas", "De 2 a 5 segmentos", "Una sola selección a la vez"],
                donts: ["No metas acciones, solo cambio de vista", "No uses etiquetas largas que se corten", "No lo uses para navegar entre secciones"]
            )
        case .interruptor:
            ComponentDoc(
                what: "Activa o desactiva una opción al instante, dentro de una fila.",
                why: "Para un estado binario que aplica de inmediato. Si hay que confirmar o es parte de un formulario, usa otro control.",
                when: "Ajustes y preferencias, siempre en una fila de lista con su etiqueta a la izquierda.",
                how: "Sin etiqueta propia: la pone la fila. Efecto inmediato, sin botón de guardar. Verde (acento) por defecto.",
                dos: ["Siempre dentro de una fila de lista", "Efecto inmediato al cambiarlo", "Una etiqueta que diga qué activa"],
                donts: ["No lo uses fuera de una lista", "No esperes un «Guardar» para aplicarlo", "No lo uses para acciones, solo para estados"]
            )
        }
    }
}

/// La ficha de un componente, con las cuatro preguntas de Apple y las reglas de uso. Es dato: la
/// vista la pinta igual para cualquier componente.
struct ComponentDoc {
    let what: String      // Qué es y qué hace
    let why: String       // Por qué este y no otro parecido
    let when: String      // Cuándo sí y cuándo no
    let how: String       // Opciones, contenido y comportamiento
    let dos: [String]     // Hacer
    let donts: [String]   // No hacer
}

/// La lista de componentes: una fila por componente, con nombre, apoyo y una flecha. Tocar una
/// fila abre su cartelera. Podrían ser cientos: la lista los recorre con `CaseIterable`.
private struct ComponentList: View {
    @Environment(\.theme) private var theme

    var body: some View {
        GroupedList {
            ForEach(Array(ShowcaseComponent.allCases.enumerated()), id: \.element) { index, component in
                if index > 0 { RowDivider(inset: theme.space.md) }
                NavigationLink(value: component) {
                    HStack(spacing: theme.space.md) {
                        VStack(alignment: .leading, spacing: theme.space.xs) {
                            Text(component.rawValue)
                                .font(theme.type.body)
                                .foregroundStyle(theme.color.onSurface)
                            Text(component.summary)
                                .font(theme.type.caption)
                                .foregroundStyle(theme.color.onSurfaceSecondary)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .font(theme.type.caption)
                            .foregroundStyle(theme.color.onSurfaceSecondary)
                    }
                    .padding(.vertical, theme.space.sm)
                    .padding(.horizontal, theme.space.md)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Cartelera de un componente (detalle)

/// El detalle que abre una fila: el componente en sus variantes y estados, sobre el fondo del tema.
struct ComponentShowcase: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    let component: ShowcaseComponent

    var body: some View {
        VStack(alignment: .leading, spacing: theme.space.md) {
            // Barra Atrás propia: en macOS no hay barra de navegación del sistema, así que el
            // detalle trae su propio control, consistente con el encabezado del catálogo.
            Button { dismiss() } label: {
                HStack(spacing: theme.space.xs) {
                    Image(systemName: "chevron.left")
                    Text("Atrás")
                }
                .font(theme.type.body)
                .foregroundStyle(theme.color.accent)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, theme.space.md)

            Text(component.rawValue)
                .textStyle(.title)
                .padding(.horizontal, theme.space.md)

            ScrollView {
                ComponentShowcaseContent(component: component)
            }
        }
        .padding(.top, theme.space.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(theme.color.surface)
        .hideNavigationBar()
        .tint(theme.color.accent)
    }
}

/// El contenido de la cartelera, sin `ScrollView`, para que el renderizado a imagen lo dibuje.
/// Es la doc del componente al estilo de Apple —ficha + hacer/no hacer— y, debajo, los ejemplos.
struct ComponentShowcaseContent: View {
    @Environment(\.theme) private var theme
    let component: ShowcaseComponent

    var body: some View {
        VStack(alignment: .leading, spacing: theme.space.xl) {
            DocBlock(doc: component.doc)

            VStack(alignment: .leading, spacing: theme.space.lg) {
                Text("Ejemplos").textStyle(.caption)
                switch component {
                case .boton:       ButtonShowcase()
                case .campo:       FieldShowcase()
                case .selector:    SelectorShowcase()
                case .interruptor: SwitchShowcase()
                }
            }
        }
        .padding(theme.space.md)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// La ficha de Apple pintada: qué es (entrada), por qué / cuándo / cómo, y las columnas de hacer y
/// no hacer. Cualquier componente la reusa; solo cambia el dato `ComponentDoc`.
private struct DocBlock: View {
    @Environment(\.theme) private var theme
    let doc: ComponentDoc

    var body: some View {
        VStack(alignment: .leading, spacing: theme.space.lg) {
            Text(doc.what)
                .font(theme.type.headline)
                .foregroundStyle(theme.color.onSurface)

            field("Por qué", doc.why)
            field("Cuándo", doc.when)
            field("Cómo", doc.how)

            HStack(alignment: .top, spacing: theme.space.md) {
                guides("Hacer", doc.dos, symbol: "checkmark", color: theme.color.accent)
                guides("No hacer", doc.donts, symbol: "xmark", color: theme.color.danger)
            }
        }
    }

    private func field(_ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: theme.space.xs) {
            Text(title).textStyle(.caption)
            Text(text)
                .font(theme.type.body)
                .foregroundStyle(theme.color.onSurface)
        }
    }

    private func guides(_ title: String, _ items: [String], symbol: String, color: Shade) -> some View {
        VStack(alignment: .leading, spacing: theme.space.sm) {
            Text(title)
                .font(theme.type.caption)
                .foregroundStyle(color)
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: theme.space.sm) {
                    Image(systemName: symbol)
                        .font(theme.type.caption)
                        .foregroundStyle(color)
                    Text(item)
                        .font(theme.type.caption)
                        .foregroundStyle(theme.color.onSurface)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(theme.space.md)
        .background(color.opacity(0.12), in: .rect(cornerRadius: theme.shape.medium, style: .continuous))
    }
}

/// Un bloque de la cartelera: un título y un ejemplo en una celda de superficie.
private struct ShowcaseGroup<Content: View>: View {
    @Environment(\.theme) private var theme
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: theme.space.sm) {
            Text(title).textStyle(.caption)
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(theme.space.md)
                .background(theme.color.surfaceElevated, in: .rect(cornerRadius: theme.shape.medium, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: theme.shape.medium, style: .continuous)
                        .stroke(theme.color.outline)
                }
        }
    }
}

private struct ButtonShowcase: View {
    @Environment(\.theme) private var theme
    var body: some View {
        ShowcaseGroup(title: "Estilos de Apple") {
            VStack(alignment: .leading, spacing: theme.space.sm) {
                Button("Continuar") { }.buttonStyle(.themed(.prominent))
                Button("Guardar") { }.buttonStyle(.themed(.bordered))
                Button("Detalles") { }.buttonStyle(.themed(.plain))
                Button("Borrar", role: .destructive) { }.buttonStyle(.themed(.prominent))
            }
        }
        ShowcaseGroup(title: "Tamaños") {
            HStack(spacing: theme.space.md) {
                Button("Pequeño") { }.controlSize(.small)
                Button("Mediano") { }.controlSize(.regular)
                Button("Grande") { }.controlSize(.large)
            }
            .buttonStyle(.themed(.bordered))
        }
        ShowcaseGroup(title: "Deshabilitado") {
            HStack(spacing: theme.space.sm) {
                Button("Continuar") { }.buttonStyle(.themed(.prominent))
                Button("Guardar") { }.buttonStyle(.themed(.bordered))
            }
            .disabled(true)
        }
    }
}

private struct FieldShowcase: View {
    @Environment(\.theme) private var theme
    @State private var name = "Francisco"
    @State private var email = "fran@"
    var body: some View {
        ShowcaseGroup(title: "Reposo y foco (clic)") {
            FormField("Nombre", text: $name, prompt: "Tu nombre")
        }
        ShowcaseGroup(title: "Error") {
            FormField("Correo", text: $email, prompt: "nombre@dominio.com", error: "Falta el dominio")
        }
    }
}

private struct SelectorShowcase: View {
    @Environment(\.theme) private var theme
    @State private var mood = Mood.bien
    enum Mood: String, CaseIterable, Identifiable { case bien = "Bien", ok = "Ok", mal = "Mal"; var id: String { rawValue } }
    var body: some View {
        ShowcaseGroup(title: "¿Cómo estuvo tu día?") {
            HStack(spacing: 0) {
                ForEach(Mood.allCases) { option in
                    let active = option == mood
                    Button { mood = option } label: {
                        Text(option.rawValue)
                            .font(theme.type.body)
                            .foregroundStyle(active ? theme.color.onSurface : theme.color.onSurfaceSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, theme.space.sm)
                            .background {
                                if active {
                                    RoundedRectangle(cornerRadius: theme.shape.small, style: .continuous)
                                        .fill(theme.color.surfaceElevated)
                                        .elevation(theme.elevation.card)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(theme.space.xs)
            .background(theme.color.outline.opacity(0.5), in: .rect(cornerRadius: theme.shape.medium, style: .continuous))
        }
    }
}

private struct SwitchShowcase: View {
    @Environment(\.theme) private var theme
    @State private var notify = true
    @State private var sounds = false
    var body: some View {
        ShowcaseGroup(title: "En una fila") {
            VStack(spacing: theme.space.sm) {
                Toggle(isOn: $notify) { Text("Notificaciones").textStyle(.body) }
                Toggle(isOn: $sounds) { Text("Sonidos").textStyle(.body) }
            }
            .tint(theme.color.accent)
        }
    }
}
