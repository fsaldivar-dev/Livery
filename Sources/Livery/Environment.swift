//
//  Environment.swift
//  Livery
//

import SwiftUI

extension EnvironmentValues {
    /// El tema activo en el subárbol. Léelo solo cuando necesites un valor fuera de un
    /// modificador; para estilos usa key paths (`.foregroundStyle(\.color.onSurface)`).
    @Entry public var theme: Theme = Theme()
}

extension View {
    /// Aplica un tema a este subárbol. Reemplaza por completo el tema heredado.
    ///
    /// ```swift
    /// ContentView().theme(Light())
    /// ```
    public func theme(_ provider: some ThemeProvider) -> some View {
        environment(\.theme, provider.resolvedTheme)
    }

    /// Añade al tema heredado los conjuntos de roles que `provider` resuelve, sin perder el resto.
    ///
    /// Es la forma de dar a una sección su propio estilo sobre el tema de la app:
    ///
    /// ```swift
    /// PlayerView().theme(adding: PlayerDense())
    /// ```
    public func theme(adding provider: some ThemeProvider) -> some View {
        transformEnvironment(\.theme) { $0.merge(provider.resolvedTheme) }
    }
}
