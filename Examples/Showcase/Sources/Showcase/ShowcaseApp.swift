//
//  ShowcaseApp.swift
//  Showcase
//
//  La app solo importa DesignSystem y Livery. `Palette` no está en su alcance: una vista que
//  intente escribir `Palette.slate900` no compila.
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
    @Environment(\.theme) private var theme
    @State private var choice: ThemeChoice = .daylight
    @State private var scheme: ColorScheme = .light
    @State private var dense = false

    var body: some View {
        VStack(spacing: 0) {
            controls
            Divider()
            ScrollView {
                GalleryView()
            }
            .background(theme.color.surface)
            .environment(\.colorScheme, scheme)
        }
        .environment(\.theme, choice.theme)
        .environment(\.theme, adding: dense ? .dense : Theme())
    }

    private var controls: some View {
        Group {
            HStack(spacing: theme.space.md) {
                Picker("Tema", selection: $choice) {
                    ForEach(ThemeChoice.allCases) { Text($0.rawValue).tag($0) }
                }
                Picker("Modo", selection: $scheme) {
                    Text("Claro").tag(ColorScheme.light)
                    Text("Oscuro").tag(ColorScheme.dark)
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
                Toggle("Denso", isOn: $dense)
                Spacer()
            }
        }
        .padding(theme.space.md)
    }
}

/// La galería: una tarjeta real y las secciones de roles.
struct GalleryView: View {
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.space.xl) {
            SampleCard()
            ButtonsSection()
            ColorsSection()
            TypographySection()
            SpacingSection()
            ShapesSection()
            LegacyCard()
        }
        .padding(theme.space.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#if os(macOS)
enum Snapshot {
    @MainActor static func write(to directory: String) {
        try? FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
        for choice in ThemeChoice.allCases where choice != .none {
            for scheme in [ColorScheme.light, .dark] {
                let view = GalleryView()
                    .frame(width: 900)
                    .background(choice.theme.color.surface)
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
