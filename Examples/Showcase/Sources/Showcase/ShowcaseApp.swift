//
//  ShowcaseApp.swift
//  Showcase
//
//  La app solo importa DesignSystem y Livery. `Palette` no está en su alcance: una vista que
//  intente escribir `Palette.jade500` no compila.
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
        case .brand: Theme.daylight.merging(Brand(accent: Shade(light: .purple, dark: .pink)).resolvedTheme)
        case .none: Theme()
        }
    }
}

struct ShowcaseView: View {
    @State private var choice: ThemeChoice = .daylight
    @State private var scheme: ColorScheme = .light
    @State private var dense = false

    var body: some View {
        VStack(spacing: 0) {
            controls
            Divider()
            gallery
                .theme(choice.theme)
                .theme(adding: dense ? .dense : Theme())
                .environment(\.colorScheme, scheme)
        }
    }

    private var controls: some View {
        HStack(spacing: 16) {
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
        .padding(12)
    }

    private var gallery: some View {
        ScrollView {
            ThemeValue(keyPath: \.space.xl) { gap in
                VStack(alignment: .leading, spacing: gap) {
                    SampleCard()
                    ColorsSection()
                    TypographySection()
                    SpacingSection()
                    ShapesSection()
                }
            }
            .padding(\.space.xl)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(\.color.surface)
    }
}
