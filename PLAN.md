# Livery — plan de la librería

*One airframe. Any livery.*

Un framework para construir sistemas de diseño en Swift. No trae un look; trae la
estructura que Apple nunca dio: capas, reglas y migraciones, verificadas por el
compilador.

## 1. Por qué existe

Crear y migrar un sistema de diseño en iOS duele porque no hay estructura
definida. Android la tiene: `colors.xml` (primitivos), `attrs.xml` (roles),
`themes.xml` (resolución), `values-night/` (modos), `styles.xml` (componentes), y
un `R` generado y tipado que hace que un token mal nombrado sea un error de
compilación y no un bug en producción.

En iOS cada equipo inventa su `Theme.shared`, referencia colores por string desde
el asset catalog, y los componentes leen primitivos directamente. Migrar de un DS
a otro es reescribir vistas una por una sin tabla de equivalencias ni progreso
medible.

Livery asume que nadie va a leer la guía. La abstracción la carga el framework
y la hace cumplir el compilador. Si algo depende de disciplina, no existe.

## 2. Qué es un sistema de diseño (lo que el kernel modela)

Un vocabulario cerrado de decisiones, con reglas de combinación, compartido entre
diseño y código. Sus piezas, de concreta a abstracta:

| Pieza | Qué es | Equivalente Android |
|---|---|---|
| Primitivos | Valores crudos con nombre. Privados a los temas. | `colors.xml`, `dimens.xml` |
| Escalas | Familias ordenadas y cerradas de primitivos. | `dimens.xml` |
| Roles | La decisión de intención: `surface`, `accent`, `titleMedium`. | `attrs.xml` |
| Temas | Una función de roles a valores. Uno por estilo o modo. | `themes.xml`, `values-night/` |
| Contratos de componente | Anatomía, variantes, tamaños, estados, y qué rol lee cada parte. | `styles.xml` |
| Puentes | Tabla de equivalencias entre dos versiones de roles. | tablas M2→M3 |

Reglas, pocas y rígidas:

1. Las vistas y componentes leen roles. Nunca primitivos.
2. Todo rol está resuelto en todo tema que lo declara.
3. Toda combinación de parte, variante, tamaño y estado de un componente está definida.
4. Un rol deprecado declara su reemplazo.
5. Un puente cubre todos los roles de la versión vieja.

## 3. Principios de diseño

- **Gramática cerrada, vocabulario abierto.** El kernel no sabe que existe un rol
  llamado `accent`. Sabe que existen roles, temas, contratos y puentes, y cómo se
  relacionan. Los nombres los pone cada sistema.
- **El archivo es Swift.** La fuente de verdad son declaraciones Swift, no JSON.
  Es lo único que Xcode entiende con autocompletado, rename, swatches
  (`#colorLiteral`) y errores por línea. El JSON (W3C Design Tokens) es una
  salida para Penpot y Figma, y una entrada de una sola vez.
- **Macros más un plugin de build son el `aapt`.** Un macro solo puede escribir
  dentro del tipo que decora, así que verifica y genera `Resolver`, `Values` y
  `ThemeProvider`. Lo que vive fuera (`theme.color`, `.light`, y en fase 2 los
  reenvíos del puente) lo escribe el plugin `LiveryRegistry`, que parsea los
  fuentes del target antes de compilar. Es el mismo patrón que `AnnotationRegistry`
  en AnnotationSwift y `JadeRegistry` en JadeAPI.
- **La verificación es la que Swift ya sabe hacer.** Completitud de un tema =
  conformance a un protocolo. Completitud de un estilo = switch exhaustivo.
  Rename = refactor de Xcode. Deprecación = `@available` con `renamed:` y fix-it.
- **Los estilos son por subárbol, no globales.** Una app puede tener varios
  estilos conviviendo, y un DS viejo y uno nuevo durante una migración.
- **Cero ceremonia en la vista.** No se declara `@Environment`. Se escribe
  `.foregroundStyle(theme.color.onSurface)` y el tema se resuelve solo, con
  autocompletado de los roles en cada paso.

## 4. Nombre y módulos

Paquete `Livery`: la librea es la pintura que una aerolínea aplica a aviones idénticos.
La estructura es el fuselaje; tu marca es la librea. El namespace en las vistas es
`theme`, nunca `ds`.

| Target | Tipo | Contenido |
|---|---|---|
| `Livery` | librería | Runtime: `Theme`, `Shade`, `ThemeRef` (referencias `.theme…` con autocompletado, `ShapeStyle` para colores), `EnvironmentValues.theme`, `.environment(\.theme, …)` y `.environment(\.theme, adding:)`, sobrecargas de modificadores. |
| `LiveryMacros` | macro | `@Primitives`, `@Roles`, `@Theme`, `@Component`, `@Style`, `@Bridge`. |
| `ThemeLint` | build plugin | Marca valores hardcodeados en targets de UI. |
| `theme` | ejecutable | CLI: `init`, `export`, `import`, `report`. |

Requisitos: Swift 6.2, iOS 17 / macOS 14 (por `ShapeStyle.resolve(in:)`). El módulo
se llama `Livery` y no `Theme` para que `Theme.Colors` nunca sea ambiguo entre
módulo y tipo.

## 5. Estructura que genera `theme init`

Hecho. `theme init <Nombre> [--at <carpeta>] [--livery <url|ruta>] [--branch <rama>]`
genera un paquete Swift:

```
<Nombre>/
  Package.swift
  Sources/
    <Nombre>Primitives/   ← Palette.swift, Metrics.swift. Solo <Nombre> lo importa.
    <Nombre>/             ← Roles.swift, Themes.swift. Plugin LiveryRegistry activo.
  Tests/<Nombre>Tests/    ← el tema resuelve lo que declara; la escala de espacio crece.
  README.md
```

La regla 1 (vistas no leen primitivos) se cumple por frontera de módulo: la app
importa `<Nombre>`, nunca `<Nombre>Primitives`. Al terminar, la CLI imprime cómo
enlazar el paquete y activar el plugin en los targets de UI para el lint.

Las plantillas viven en `LiveryScaffold` como strings, probadas sin disco; el
paquete generado se compiló y testeó de verdad contra la copia local de Livery.

## 6. Declaración

Las declaraciones son tipos planos, como en Android, donde `colors.xml` y
`themes.xml` son archivos sueltos y `R` es generado. La categoría de un conjunto
de roles se declara por conformance y fija el nombre de la propiedad y el tipo de
valor:

| Categoría | Propiedad | Valor |
|---|---|---|
| `ColorRoles` | `theme.color` | `Shade`: claro y oscuro obligatorios, contraste aumentado opcional |
| `TypeRoles` | `theme.type` | `Font` |
| `SpaceRoles` | `theme.space` | `CGFloat` |
| `ShapeRoles` | `theme.shape` | `CGFloat` (radio) |

```swift
// Primitives/Palette.swift
@Primitives enum Palette {
    static let jade500   = #colorLiteral(red: 0, green: 0.6, blue: 0.4, alpha: 1)
    static let neutral50 = #colorLiteral(red: 0.98, green: 0.98, blue: 0.98, alpha: 1)
}

// Roles/Colors.swift
@Roles enum Colors: ColorRoles  { case surface, onSurface, accent, onAccent }
@Roles enum Spacing: SpaceRoles { case xs, sm, md, lg, xl }

// Themes/Light.swift
@Theme struct Light: Colors.Resolver, Spacing.Resolver {
    let surface   = Shade(light: Palette.neutral50, dark: Palette.neutral900)
    let accent    = Shade(Palette.jade500)
    // falta `onSurface` → error de conformance en esta línea, con fix-it
    // `let accent = Palette.jade500` sin Shade → error: falta decidir el oscuro
}
```

Quién genera qué:

- `@Roles` (macro) genera `Resolver` (un protocolo con una propiedad por rol),
  `Values` (la resolución inmutable que viaja en `Theme`), `unresolved` (valores
  de reserva visibles: rosa, `body`, `0`) y la conformance a `RoleSet`. Rechaza
  enums sin categoría y casos con valores asociados o raw value.
- `@Theme` (macro) lee las conformances `X.Resolver` de la declaración y genera
  `ThemeProvider.resolvedTheme`, que registra cada `Values`. La completitud la
  verifica la conformance.
- `@Primitives` solo marca la paleta para el exportador.
- `LiveryRegistry` (plugin) escribe `extension Theme` con `var color: Colors.Values`
  por cada `@Roles` y `static var light: Theme` por cada `@Theme` construible sin
  argumentos. Diagnostica categorías repetidas con archivo y línea.
- `@Component` / `@Style` (fase 3): generan la tabla de combinaciones y exigen
  switch exhaustivo.
- `@Bridge(from:to:)` (fase 2): el plugin verifica cobertura de todos los roles
  viejos y genera reenvíos deprecados en `Values` (ver sección 8).

Límite actual: una categoría solo puede declararse una vez por módulo. Un segundo
conjunto de color para una sección (`PlayerColors`) necesita un namespace propio;
queda para 0.2.

## 7. Consumo

La forma recomendada es la de SwiftUI: la vista declara el tema como propiedad
del entorno y habla solo en roles, con modificadores nativos.

```swift
struct Card: View {
    @Environment(\.theme) private var theme

    var body: some View {
        Text(fighter.name)
            .font(theme.type.titleMedium)
            .foregroundStyle(theme.color.onSurface)
            .padding(theme.space.lg)
            .background(theme.color.surfaceElevated, in: .rect(cornerRadius: theme.shape.medium))
    }
}
```

`theme` es un `Theme` con tipo declarado en el mismo archivo: `theme.type.x` es un
`Font`, `theme.color.x` un `Shade` (que es `ShapeStyle`), `theme.space.x` un
`CGFloat`. No hay nada que inferir, y por eso el autocompletado no puede fallar.

Historia de esta decisión, medida con `sourcekit-lsp` y verificada en Xcode:

- `\.type.title` (key path): autocompleta en `foregroundStyle` y da cero en
  `font`, donde compite con la sobrecarga nativa que recibe `Font?`.
- `.theme.type.title` (miembro implícito): autocompleta en un archivo mínimo y da
  cero dentro de un `ViewBuilder` real.
- `theme.type.title` con `theme` global: perfecto en `sourcekit-lsp`, pero en
  Xcode, que tipa un paquete local desde el fuente, el global aparecía sin tipo
  y la cadena no seguía, incluso con el tipo anotado.
- `@Environment(\.theme) var theme`: tipo declarado en la vista, autocompletado
  determinista en cualquier posición.

El global `theme` (un `ThemeRef<Theme>` con `@dynamicMemberLookup`) se conserva
como atajo para vistas que no quieran la línea del `@Environment`: las cadenas
son las mismas y se resuelven al dibujar. `ThemeRef<Shade>` es `ShapeStyle` y
hay sobrecargas finas para fuente, padding, radio y `tint`.

Aplicar un tema es poner un valor en el entorno, una vez, en la raíz:

```swift
ContentView().environment(\.theme, .light)
PlayerView().environment(\.theme, adding: .playerDense)
BrandedView().environment(\.theme, adding: Brand(accent: Shade(.purple)))
```

No hay inyección automática: el valor por defecto del entorno lo define Livery,
que no conoce los temas de la app, y evitarlo exigiría `@_dynamicReplacement` o
escanear clases ObjC al arrancar. La línea en la raíz es además la que necesitan
los previews: `#Preview { Card().environment(\.theme, .light) }`.

Cuando hace falta el valor en lógica, no en un modificador, la misma propiedad
sirve: `theme.color[.accent]` (subscript por caso, para galerías y exportadores).

Varios estilos por app: cada uno es un `@Theme` distinto. Un conjunto de roles
que un subárbol no resuelve es un fallo en debug con mensaje claro
(`PlayerColors no está resuelto por Light`) y un valor de reserva en release.
Ver riesgo R2.

Lo que la raíz `Theme` expone es el vocabulario del proyecto: `theme.color`,
`theme.type`, `theme.space`, `theme.shape`, `theme.elevation`, `theme.motion`.
Los nombres de las categorías los fija el kernel; los roles dentro de cada una
los pone el proyecto.

## 7b. Modos y accesibilidad

Los modos son una dimensión de la resolución, no temas distintos. Cada categoría
decide con su tipo de valor a qué responde:

| Ajuste del sistema | Quién responde | Estado |
|---|---|---|
| Claro / oscuro | `Shade`, obligatorio | Hecho |
| Contraste aumentado | `Shade`, variantes opcionales | Hecho |
| Dynamic Type | `TypeStyle` relativo a un estilo de texto | Pendiente (slice 2) |
| Reducir movimiento | categoría `motion` con variante reducida | Pendiente |
| Clase de tamaño | variantes de `space` | Pendiente |

Reglas verificables en build, en el plugin: contraste WCAG entre pares por
convención (`onSurface` sobre `surface`, `onAccent` sobre `accent`) cuando los
valores son literales, en ambos modos. Pendiente (fase 2).

Semántica para VoiceOver y objetivos táctiles mínimos: parte de los contratos de
componente (fase 3).

## 8. Cambio y migración

| Cambio | Qué pasa |
|---|---|
| Cambia un valor | Se edita un primitivo. Nada más se entera. |
| Se agrega un rol | Todos los temas que declaran ese conjunto dejan de compilar hasta resolverlo, cada uno en su línea. |
| Se renombra un rol | Refactor de Xcode, o `@Deprecated(renamed:)` con fix-it en cada uso. |
| Se elimina un rol | El compilador lista cada vista que lo leía. |
| Llega DS2 | Se escribe un `@Bridge`. Ver abajo. |

Migración de DS1 a DS2 con el puente. DS2 se declara tal cual lo manda diseño, sin
mirar DS1; el puente dice cómo se expresa cada rol viejo en términos nuevos:

```swift
@Bridge(from: ColorsV1.self, to: Colors.self)
enum ColorsV1toV2 {
    static let primary        = Colors.brand              // renombrado
    static let cardBackground = Colors.surfaceElevated    // renombrado
    /// DS2 eliminó el divisor; usa `outline` con opacidad.
    static func divider(_ colors: Colors.Values) -> Shade { colors.outline.opacity(0.4) }
    // falta `textSecondary` → el plugin falla el build señalando esta línea
}
```

Hecho. El macro valida la forma (`static let viejo = Nuevo.rol` o
`static func viejo(_: Nuevo.Values) -> T`); el plugin, que ve el módulo entero,
verifica cobertura, marca `ColorsV1` como legado para que no ocupe `theme.color`,
y genera los reenvíos. Un rol que existe con el mismo nombre en ambos no se
puentea. El comentario `///` de un `func` es el mensaje de deprecación.

El plugin verifica que el puente cubra todos los casos de `ColorsV1` y genera, en
`Colors.Values`, un reenvío deprecado por cada rol viejo:

```swift
extension Colors.Values {
    @available(*, deprecated, renamed: "brand")
    var primary: Color { brand }
    @available(*, deprecated, message: "DS2 eliminó divider; usa outline con opacidad")
    var divider: Color { outline.opacity(0.4) }
}
```

1. Con el puente, las vistas que leen `\.color.primary` obtienen `brand`. Se cambia
   el tema de la raíz a uno que resuelve DS2 y toda la app se ve con DS2 sin tocar
   vistas. El puente no toca los temas.
2. Cada rol de DS1 queda deprecado con reemplazo. Migrar una vista es aceptar
   fix-its. El conteo de warnings es la barra de progreso y un gate en CI: no
   sube, solo baja.
3. DS1 y DS2 conviven en el mismo árbol, pantalla por pantalla.
4. En cero warnings se borran DS1 y el puente. El plugin deja de generar los
   reenvíos y cualquier uso viejo que quedara pasa de warning a error.

Lo que queda manual: la ambigüedad semántica. Si DS1 `primary` se usaba para
marca y acción y DS2 los separa, el puente elige un default y las vistas que
querían lo otro se corrigen al revisar fix-its. `theme report` lista, por rol
deprecado, en qué archivos se usa.

## 9. Lint

Hecho. El plugin `LiveryRegistry`, en un target donde no encuentra `@Roles`,
`@Theme`, `@Bridge` ni `@Primitives`, trata el módulo como UI y marca como
warning, con archivo y línea:

- Colores construidos en la vista: `Color(red:…)`, `Color("nombre")`,
  `Color(hex:)`, `Color(.sRGB, …)`.
- Colores del sistema: `Color.red`, `.foregroundStyle(.blue)`, en
  `foregroundStyle`, `background`, `fill`, `stroke`, `tint`, `border`.
- Fuentes fuera del tema: `Font.system(size:)` y estilos de texto directos
  (`.font(.title)`).
- Medidas sueltas distintas de cero en `padding`, `spacing:` y `cornerRadius:`.

Los módulos del sistema de diseño quedan exentos por definición: ahí es donde
los valores crudos deben vivir. El lint avisa, no rompe el build; la regla de
"en CI el conteo no sube" es del pipeline, no del plugin.

Fuera por ahora: `frame(width:height:)`, `shadow`, `lineWidth`. Tienen demasiados
usos legítimos de layout para una regla sintáctica.

## 10. Interoperabilidad

- `theme export` escribe W3C Design Tokens (`*.tokens.json`) desde las
  declaraciones Swift, para Penpot y Figma (Tokens Studio).
- `theme import` lee ese JSON una vez y escribe `Primitives/*.swift` y un
  borrador de `Roles/` que alguien nombra bien después.
- **UIKit / AppKit**: el runtime expone `Theme.current` para el subárbol activo
  vía `UITraitCollection` en iOS 17 (`traitOverrides`) y un fallback global.
  Los roles de color entregan `UIColor` además de `Color`.
- **Colores**: primitivos en Swift con `#colorLiteral` por defecto. Opción de
  paleta plana en asset catalog (sin variantes claro/oscuro) usando los símbolos
  generados por Xcode 15; claro/oscuro lo decide siempre el tema.

## 11. Riesgos y decisiones abiertas

- **R1. Key paths y miembros implícitos en modificadores.** Descartados: el
  `KeyPath` no puede ser `ShapeStyle`, y tanto `\.x` como `.theme.x` autocompletan
  mal según el contexto. La API es el global `theme` sobre `ThemeRef` con
  `@dynamicMemberLookup` (sección 7). Al medir autocompletado, borrar antes
  `.build/index-build`: un índice rancio da resultados de una API que ya no existe.
- **R2. Seguridad de tipos entre subárboles.** Con una sola raíz `Theme`, un
  key path a un conjunto de roles que el tema activo no resuelve no puede fallar
  en compilación. Se acepta fallo en debug y reserva en release. Alternativa
  futura: raíces por tema con genéricos, más seguro y mucho más ruidoso.
- **R3. Peso de AnnotationSwift.** Resuelto: no se usa en 0.1. Sus macros
  decoran funciones y propiedades; los de Livery son de miembros y extensión.
  Podría volver en fase 3 para el lado del consumo.
- **R4. `#colorLiteral` en Swift 6.2.** Pendiente. Showcase usa `Color(red:green:blue:)`
  en la paleta mientras tanto.
- **R5. Macros y extensiones.** Un macro no puede generar `extension Theme` desde
  otro tipo, ni como peer ni como extensión (comprobado dos veces: el compilador
  rechaza la primera y reescribe la segunda al tipo decorado). Por eso existe el
  plugin de build. Costo: activar el plugin en el target, el diálogo de confianza
  de Xcode la primera vez, y autocompletado de `.light` solo tras compilar.
- **D1.** Nombre del paquete: `Livery` (antes `ThemeKit`). Decidido.
- **D2.** Mínimo de plataforma: iOS 17 / macOS 14 por `resolve(in:)`. Decidido.

## 12. Fases

| Fase | Entrega | Criterio de hecho |
|---|---|---|
| 0.1 Núcleo | `@Primitives`, `@Roles`, `@Theme`, `Shade`, plugin `LiveryRegistry`, `.environment(\.theme, …)`, `.environment(\.theme, adding:)`, `ThemeRef`, sobrecargas para fuente, padding, radio, tint, `theme init`. **Hecho.** | Sajaru Corner tiene su DS declarado y una pantalla migrada a key paths. |
| 0.2 Cambio | `@Bridge` con reenvíos deprecados y reporte de usos pendientes, lint en el plugin. **Hecho.** | Migrar un conjunto de roles V1→V2 en Sajaru sin tocar vistas, y bajar warnings a cero. |
| 0.3 Componentes | `@Component`, `@Style`, catálogo base (Button, Card, TextField). | Botón de Sajaru declarado como contrato con estilo exhaustivo. |
| 0.4 Diseño | `theme export` / `theme import` W3C, catálogo visual generado. | Tokens de Sajaru abren en Penpot. |

Fuera de alcance: patrones y principios como tipos (quedan como documentación),
catálogo de componentes cerrado, soporte de UIKit más allá de lectura de roles.

## 13. App de validación

`Examples/Showcase` (macOS, hecho): primitivos, roles y temas en módulos reales con
el plugin activo, modo `--snapshot <carpeta>` que escribe un PNG por tema y modo, galería de roles por `CaseIterable` y el subscript `theme.color[.accent]`,
cambio de tema, modo y densidad en vivo, y la opción "Sin tema" para ver la reserva
rosa. Es donde se prueban las APIs antes de tocar una app de verdad.

Sajaru Corner (iOS/iPadOS/macOS). Tiene tokens semánticos y componentes en
Penpot, varias superficies con look distinto (reproductor de análisis denso y
oscuro, biblioteca clara), y es un candidato natural para probar varios estilos
por subárbol y la exportación a Penpot.
