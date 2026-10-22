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
@Roles extension Theme {
    enum Colors: ColorRoles  { case surface, onSurface, accent }
    enum Spacing: SpaceRoles { case sm, md, lg }
}

// Cómo se resuelve. Si falta un rol, el compilador lo señala en esta línea.
@Theme struct Carbon: Theme.Colors.Resolver, Theme.Spacing.Resolver {
    let surface = Color.black, onSurface = Color.white, accent = Color.orange
    let sm: CGFloat = 8, md: CGFloat = 16, lg: CGFloat = 24
}

// Las vistas hablan solo en roles. Sin `@Environment`, sin primitivos, sin strings.
struct Card: View {
    var body: some View {
        Text("Hola")
            .foregroundStyle(\.color.onSurface)
            .padding(\.space.lg)
            .background(\.color.surface, cornerRadius: \.shape.medium)
    }
}

ContentView().theme(Carbon())
```

## Qué verifica el compilador

- **Tema incompleto.** Un tema que olvida un rol es un error de conformance en la línea del tema, con fix-it.
- **Vistas sin primitivos.** La paleta vive en un módulo que las vistas no importan. Leer `Palette.jade500` desde una vista no compila.
- **Roles mal declarados.** Un enum sin categoría, una categoría repetida o un caso con valores asociados son diagnósticos del macro.
- **Subárbol sin tema.** En debug, una advertencia de runtime y colores rosa; nunca un fallo en silencio.

## Estado

Fase 0.1: `@Roles`, `@Theme`, `@Primitives`, `.theme(_:)`, `.theme(adding:)` y sobrecargas de
modificadores para color, fuente, espaciado y radio. Swift 6.2, iOS 17 / macOS 14.

El diseño completo, las fases y los riesgos están en [PLAN.md](PLAN.md).
