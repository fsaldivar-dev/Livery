<p align="center">
  <img src="Assets/cover.webp" alt="Livery — A Design System framework for Swift. One airframe. Any livery." width="100%">
</p>

# Livery

**One airframe. Any livery.**

Livery es un framework para construir sistemas de diseño en Swift. No trae un look;
trae la estructura que Apple nunca dio: capas, reglas y migraciones, verificadas por
el compilador.

Una aerolínea pinta aviones idénticos con libreas distintas. Aquí la estructura es el
fuselaje y tu marca es la librea: los roles no cambian, cambia cómo se resuelven.
Cambiar de marca, de modo o de sistema de diseño entero es repintar, no reconstruir.

## Empezar

La estructura no se documenta: se genera. `theme init` crea un paquete Swift con los
primitivos en un módulo aparte, los roles y temas con el plugin activo, y un test.

```bash
swift run --package-path Livery theme init DesignSystem
```

Produce `DesignSystem/` con `DesignSystemPrimitives` (la paleta, que solo el otro módulo
importa) y `DesignSystem` (roles y temas), listo para enlazar en la app y aplicar con
`.theme(.base)`. Con `--livery <ruta>` toma Livery de una copia local.

## Cómo se ve

```swift
import Livery

// Qué existe. Los nombres los pone tu proyecto; las categorías las fija Livery.
@Roles enum Colors: ColorRoles  { case surface, onSurface, accent }
@Roles enum Spacing: SpaceRoles { case sm, md, lg }

// Cómo se resuelve. Si falta un rol, el compilador lo señala en esta línea.
// Un color es un Shade: claro y oscuro decididos, contraste aumentado opcional.
@Theme struct Carbon: Colors.Resolver, Spacing.Resolver {
    let surface   = Shade(light: .white, dark: .black)
    let onSurface = Shade(light: .black, dark: .white, darkIncreased: .white)
    let accent    = Shade(.orange)
    let sm: CGFloat = 8, md: CGFloat = 16, lg: CGFloat = 24
}

// Las vistas hablan solo en roles. Sin `@Environment`, sin primitivos, sin strings.
// Cada paso de `.theme…` autocompleta con los roles que existen.
struct Card: View {
    var body: some View {
        Text("Hola")
            .font(.theme.type.body)
            .foregroundStyle(.theme.color.onSurface)
            .padding(.theme.space.lg)
            .background(.theme.color.surface, cornerRadius: .theme.shape.medium)
    }
}

ContentView().theme(.carbon)
```

Con `import Livery` basta: Livery reexporta SwiftUI. `theme.color` y `.carbon` los genera el
plugin de build `LiveryRegistry`, el `aapt` de Livery:
recorre los fuentes del target antes de compilar y escribe la extensión de `Theme` que un macro
no puede escribir. Actívalo en el target que declara el sistema de diseño:

```swift
.target(
    name: "App",
    dependencies: [.product(name: "Livery", package: "Livery")],
    plugins: [.plugin(name: "LiveryRegistry", package: "Livery")]
)
```

Un tema con parámetros no recibe acceso corto; se aplica con `.theme(Brand(accent: .red))`.

## Verlo funcionar

`Examples/Showcase` es un sistema de diseño completo declarado con Livery, con la estructura que
el framework propone: `Primitives` en un módulo que solo `DesignSystem` importa, y una app que
no puede leer `Palette` ni queriendo. Cambia de tema, de modo y de densidad en vivo.

```bash
swift run --package-path Examples/Showcase
```

## Qué verifica el compilador

- **Tema incompleto.** Un tema que olvida un rol es un error de conformance en la línea del tema, con fix-it.
- **Modo olvidado.** Un rol de color es un `Shade`, no un `Color`: claro y oscuro se deciden siempre, y el contraste aumentado es opcional. Se resuelve al dibujar según el entorno, también para UIKit y AppKit.
- **Vistas sin primitivos.** La paleta vive en un módulo que las vistas no importan. Leer `Palette.jade500` desde una vista no compila.
- **Roles mal declarados.** Un enum sin categoría, una categoría repetida o un caso con valores asociados son diagnósticos del macro.
- **Subárbol sin tema.** En debug, una advertencia de runtime y colores rosa; nunca un fallo en silencio.
- **Valores sueltos en vistas.** Con el plugin activo en un target de UI, un `Color(red:…)`, un `.foregroundStyle(.blue)`, un `.font(.system(size: 14))` o un `.padding(12)` es un warning con archivo y línea. Los módulos que declaran roles, temas o primitivos quedan exentos.

## Migrar de un sistema a otro

Cuando llega DS2 con más tokens, menos tokens y renombres, no se tocan vistas: se escribe un
puente, una vez, y el compilador guía el resto.

```swift
@Roles enum ColorsV1: ColorRoles { case primary, cardBackground, divider }   // el viejo
@Roles enum Colors: ColorRoles { case brand, action, surfaceElevated, outline } // el nuevo

@Bridge(from: ColorsV1.self, to: Colors.self)
enum ColorsV1toV2 {
    static let primary        = Colors.brand              // renombrado: fix-it automático
    static let cardBackground = Colors.surfaceElevated
    /// DS2 eliminó el divisor; usa `outline` con opacidad.
    static func divider(_ colors: Colors.Values) -> Shade { colors.outline.opacity(0.4) }
}
```

Con eso, el plugin:

- **Verifica que el puente cubra todos los roles viejos** que no existan en el nuevo. Si falta uno, el build falla en la línea del puente.
- **Genera reenvíos deprecados** en `Colors.Values`. Una vista que lee `.theme.color.primary` sigue compilando, recibe `brand`, y muestra un warning con fix-it. Se cambia el tema de la raíz el día uno y toda la app se ve con DS2.
- **Reporta el progreso** en la línea del puente: `Migración ColorsV1 → Colors: 23 usos pendientes en 9 archivos (primary: 12, divider: 11)`. Los warnings son la barra de progreso. En cero, se borra `ColorsV1` y el puente, y lo que quedara pasa de warning a error.

## Estado

Fases 0.1 y 0.2: `@Roles`, `@Theme`, `@Primitives`, `@Bridge`, `Shade`, el plugin `LiveryRegistry`
(registro, puentes, reporte y lint), la CLI `theme init`, `.theme(_:)`, `.theme(adding:)` y
sobrecargas de modificadores para fuente, espaciado y radio.
Swift 6.2, iOS 17 / macOS 14.

El diseño completo, las fases y los riesgos están en [PLAN.md](PLAN.md).
