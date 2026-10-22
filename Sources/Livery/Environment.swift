//
//  Environment.swift
//  Livery
//

import SwiftUI

extension EnvironmentValues {
    /// El tema activo en el subárbol. Léelo solo cuando necesites un valor fuera de un
    /// modificador; para estilos usa referencias (`.foregroundStyle(theme.color.onSurface)`).
    @Entry public var theme: Theme = Theme()
}

extension View {
    /// Viste este subárbol con un tema. Reemplaza por completo el tema heredado.
    ///
    /// Con el plugin `LiveryRegistry` activo, cada `@Theme` tiene un acceso corto:
    ///
    /// ```swift
    /// ContentView().livery(.light)
    /// ```
    public func livery(_ theme: Theme) -> some View {
        environment(\.theme, theme)
    }

    /// Viste este subárbol a partir de un proveedor, por ejemplo un `@Theme` con parámetros:
    /// `.livery(Brand(primary: .red))`.
    public func livery(_ provider: some ThemeProvider) -> some View {
        environment(\.theme, provider.resolvedTheme)
    }

    /// Añade al tema heredado los conjuntos de roles que `theme` resuelve, sin perder el resto.
    ///
    /// ```swift
    /// PlayerView().livery(adding: .playerDense)
    /// ```
    public func livery(adding theme: Theme) -> some View {
        transformEnvironment(\.theme) { $0.merge(theme) }
    }

    /// Añade al tema heredado los conjuntos de roles que `provider` resuelve, sin perder el resto.
    public func livery(adding provider: some ThemeProvider) -> some View {
        transformEnvironment(\.theme) { $0.merge(provider.resolvedTheme) }
    }
}
