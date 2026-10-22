//
//  Environment.swift
//  Livery
//

import SwiftUI

extension EnvironmentValues {
    /// El tema activo en el subárbol.
    ///
    /// Se aplica con el modificador nativo, porque eso es lo que es: un valor del entorno.
    ///
    /// ```swift
    /// ContentView().environment(\.theme, .carbon)
    /// ```
    ///
    /// Las vistas lo leen con `@Environment(\.theme) private var theme` y usan sus valores en
    /// modificadores nativos: `.font(theme.type.title)`, `.foregroundStyle(theme.color.onSurface)`.
    @Entry public var theme: Theme = Theme()
}

extension View {
    /// Añade al tema heredado los conjuntos de roles que `theme` resuelve, sin perder el resto.
    ///
    /// Es la forma de dar a una sección su propio estilo sobre el tema de la app:
    ///
    /// ```swift
    /// PlayerView().environment(\.theme, adding: .playerDense)
    /// ```
    public func environment(_ keyPath: WritableKeyPath<EnvironmentValues, Theme>, adding theme: Theme) -> some View {
        transformEnvironment(keyPath) { $0.merge(theme) }
    }

    /// Añade al tema heredado lo que resuelve un proveedor, por ejemplo un `@Theme` con parámetros:
    /// `.environment(\.theme, adding: Brand(accent: .red))`.
    public func environment(_ keyPath: WritableKeyPath<EnvironmentValues, Theme>, adding provider: some ThemeProvider) -> some View {
        transformEnvironment(keyPath) { $0.merge(provider.resolvedTheme) }
    }
}
