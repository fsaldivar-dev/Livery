//
//  Environment.swift
//  Livery
//

import SwiftUI

extension EnvironmentValues {
    /// El tema activo en el subárbol. Léelo solo cuando necesites un valor fuera de un
    /// modificador; para estilos usa referencias (`.foregroundStyle(.theme.color.onSurface)`).
    @Entry public var theme: Theme = Theme()
}

extension View {
    /// Aplica un tema a este subárbol. Reemplaza por completo el tema heredado.
    ///
    /// Con el plugin `LiveryRegistry` activo, cada `@Theme` tiene un acceso corto:
    ///
    /// ```swift
    /// ContentView().theme(.light)
    /// ```
    public func theme(_ theme: Theme) -> some View {
        environment(\.theme, theme)
    }

    /// Aplica un tema a este subárbol a partir de su proveedor, por ejemplo un `@Theme` con
    /// parámetros: `.theme(Brand(primary: .red))`.
    public func theme(_ provider: some ThemeProvider) -> some View {
        environment(\.theme, provider.resolvedTheme)
    }

    /// Añade al tema heredado los conjuntos de roles que `theme` resuelve, sin perder el resto.
    ///
    /// ```swift
    /// PlayerView().theme(adding: .playerDense)
    /// ```
    public func theme(adding theme: Theme) -> some View {
        transformEnvironment(\.theme) { $0.merge(theme) }
    }

    /// Añade al tema heredado los conjuntos de roles que `provider` resuelve, sin perder el resto.
    public func theme(adding provider: some ThemeProvider) -> some View {
        transformEnvironment(\.theme) { $0.merge(provider.resolvedTheme) }
    }
}
