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

## Estado

Fase 0.1: `@Roles`, `@Theme`, `@Primitives`, `Shade`, el plugin `LiveryRegistry`, `.theme(_:)`,
`.theme(adding:)` y sobrecargas de modificadores para color, fuente, espaciado y radio.
Swift 6.2, iOS 17 / macOS 14.

El diseño completo, las fases y los riesgos están en [PLAN.md](PLAN.md).
