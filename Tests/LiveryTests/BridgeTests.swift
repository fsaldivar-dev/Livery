import SwiftUI
import Testing
@testable import Livery

// Migración DS1 → DS2. `ColorsV1` es el conjunto viejo; `Colors` (en LiveryTests.swift) el nuevo.
// El plugin genera en `Colors.Values` un reenvío deprecado por cada rol viejo.

@Roles enum ColorsV1: ColorRoles { case primary, panel, divider, onSurface }

@Bridge(from: ColorsV1.self, to: Colors.self)
enum ColorsV1toV2 {
    static let primary = Colors.accent
    static let panel   = Colors.surface
    /// DS2 eliminó el divisor; usa `onSurface` con opacidad.
    static func divider(_ colors: Colors.Values) -> Shade { colors.onSurface.opacity(0.4) }
}

@Suite struct BridgeTests {
    // Los usos de roles viejos son deprecados a propósito: es lo que ve una vista sin migrar.
    @available(*, deprecated)
    @Test func oldRolesResolveThroughTheNewTheme() {
        let colors = Theme.light.color
        #expect(colors.primary == colors.accent)
        #expect(colors.panel == colors.surface)
        #expect(colors.divider == colors.onSurface.opacity(0.4))
        #expect(colors.onSurface == Shade(light: .black, dark: .white), "un rol que existe en ambos no cambia")
    }

    @available(*, deprecated)
    @Test func oldRefsWorkInModifiers() {
        let ref: ThemeRef<Shade> = theme.color.primary
        #expect(Theme.light[ref] == Theme.light.color.accent)
    }

    @Test func legacySetDoesNotOccupyTheCategory() {
        #expect(!Theme.light.resolves(ColorsV1.self))
        #expect(Theme.light.resolves(Colors.self))
    }
}
