//
//  ShowcaseApp.swift
//  Showcase
//
//  La app solo importa DesignSystem y Livery. `Palette` no está en su alcance: una vista que
//  intente escribir `Palette.slate900` no compila.
//
//  El tema se aplica UNA vez, arriba, y cada vista hija lo lee con `@Environment(\.theme)`. Es el
//  patrón correcto: una vista que leyera el tema para pintarse a sí misma, en el mismo nivel donde
//  lo aplica, vería el tema de su padre (vacío), no el suyo.
//
//  `swift run --package-path Examples/Showcase -- --snapshot <carpeta>` escribe un PNG por tema
//  y modo en vez de abrir la ventana. Sirve para revisar la galería sin levantar la app.
//

import DesignSystem
import Livery
import SwiftUI
#if os(macOS)
import AppKit
#endif

@main
struct ShowcaseApp: App {
    init() {
        #if os(macOS)
        if let index = CommandLine.arguments.firstIndex(of: "--snapshot"), index + 1 < CommandLine.arguments.count {
            Snapshot.write(to: CommandLine.arguments[index + 1])
            exit(0)
        }
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
        #endif
    }

    var body: some Scene {
        WindowGroup("Livery · Showcase") {
            ShowcaseView().frame(minWidth: 820, minHeight: 640)
        }
    }
}

/// Qué tema aplicar en la raíz. Los accesos cortos (`.daylight`, `.carbon`) los generó el plugin.
enum ThemeChoice: String, CaseIterable, Identifiable {
    case daylight = "Daylight"
    case carbon = "Carbon"
    case brand = "Brand(accent:)"
    case none = "Sin tema"

    var id: String { rawValue }

    var theme: Theme {
        switch self {
        case .daylight: .daylight
        case .carbon: Theme.daylight.merging(.carbon)
        case .brand: Theme.daylight.merging(Brand.violet.resolvedTheme)
        case .none: Theme()
        }
    }
}

struct ShowcaseView: View {
    @State private var choice: ThemeChoice = .daylight
    @State private var scheme: ColorScheme = .light
    @State private var dense = false

    /// El tema activo: el elegido, más densidad si está activa. Se aplica una vez, aquí.
    private var activeTheme: Theme {
        dense ? choice.theme.merging(.dense) : choice.theme
    }

    var body: some View {
        VStack(spacing: 0) {
            ControlBar(choice: $choice, scheme: $scheme, dense: $dense)
            Divider()
            Gallery()
        }
        .environment(\.theme, activeTheme)
        .environment(\.colorScheme, scheme)
    }
}

/// La barra de controles. Lee el tema ya resuelto del entorno.
private struct ControlBar: View {
    @Environment(\.theme) private var theme
    @Binding var choice: ThemeChoice
    @Binding var scheme: ColorScheme
    @Binding var dense: Bool

    var body: some View {
        HStack(spacing: theme.space.md) {
            Picker("Tema", selection: $choice) {
                ForEach(ThemeChoice.allCases) { Text($0.rawValue).tag($0) }
            }
            .frame(width: 220)
            Picker("Modo", selection: $scheme) {
                Text("Claro").tag(ColorScheme.light)
                Text("Oscuro").tag(ColorScheme.dark)
            }
            .pickerStyle(.segmented)
            .frame(width: 160)
            Toggle("Denso", isOn: $dense)
            Spacer()
        }
        .padding(theme.space.md)
        .background(theme.color.surfaceElevated)
    }
}

/// La galería con scroll, para la app. El contenido vive en `GalleryContent`, que también usa el
/// renderizado a imagen (ahí no cabe un `ScrollView`, que sin alto colapsa a cero).
private struct Gallery: View {
    @Environment(\.theme) private var theme

    var body: some View {
        ScrollView { GalleryContent() }
            .background(theme.color.surface)
    }
}

/// Una tarjeta real y las secciones de roles, sobre el fondo del tema.
struct GalleryContent: View {
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.space.lg) {
            SampleCard()
            Panel { ButtonsSection() }
            Panel { FieldsSection() }
            Panel { ColorsSection() }
            Panel { TypographySection() }
            HStack(alignment: .top, spacing: theme.space.lg) {
                Panel { SpacingSection() }
                Panel { ShapesSection() }
            }
            Panel { LegacyCard() }
        }
        .padding(theme.space.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.color.surface)
    }
}

#if os(macOS)
enum Snapshot {
    @MainActor static func write(to directory: String) {
        try? FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
        for choice in ThemeChoice.allCases where choice != .none {
            for scheme in [ColorScheme.light, .dark] {
                let view = GalleryContent()
                    .frame(width: 900)
                    .environment(\.theme, choice.theme)
                    .environment(\.colorScheme, scheme)
                let renderer = ImageRenderer(content: view)
                renderer.scale = 2
                guard let cgImage = renderer.cgImage else { continue }
                let rep = NSBitmapImageRep(cgImage: cgImage)
                let name = "\(choice.rawValue.lowercased().filter(\.isLetter))-\(scheme == .dark ? "dark" : "light").png"
                try? rep.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: directory).appending(path: name))
                print("snapshot: \(name)")
            }
        }
    }
}
#endif
