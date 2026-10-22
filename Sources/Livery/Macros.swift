//
//  Macros.swift
//  Livery
//

/// Declara un conjunto de roles: un enum con un caso por decisión de diseño.
///
/// La categoría se declara por conformance (``ColorRoles``, ``TypeRoles``, ``SpaceRoles`` o
/// ``ShapeRoles``) y fija el tipo de cada rol y el nombre bajo el que se expone en ``Theme``.
///
/// ```swift
/// @Roles enum Colors: ColorRoles { case surface, onSurface, accent }
/// @Roles enum Spacing: SpaceRoles { case xs, sm, md, lg }
/// ```
///
/// El macro genera:
/// - `Colors.Resolver`: un protocolo con una propiedad por rol. Un tema lo conforma, y si olvida
///   un rol, el compilador lo señala en la línea del tema.
/// - `Colors.Values`: la resolución inmutable que viaja en ``Theme``.
/// - `Colors.unresolved`: valores de reserva visibles (rosa en ambos modos, `body`, `0`).
///
/// La propiedad `theme.color` (o `type`, `space`, `shape`) la genera el plugin de build
/// `LiveryRegistry`, que debe estar activo en el target. Una categoría solo puede declararse
/// una vez por módulo; el plugin lo verifica.
@attached(member, names: named(Resolver), named(Values), named(unresolved))
@attached(extension, conformances: RoleSet, Sendable)
public macro Roles() = #externalMacro(module: "LiveryMacros", type: "RolesMacro")

/// Declara un tema: la resolución de uno o más conjuntos de roles.
///
/// Los conjuntos que resuelve se declaran como conformances a sus `Resolver`. La completitud la
/// verifica el compilador: si falta un rol, es un error de conformance con fix-it.
///
/// ```swift
/// @Theme struct Light: Colors.Resolver, Spacing.Resolver {
///     let surface   = Shade(light: Palette.neutral50, dark: Palette.neutral900)
///     let onSurface = Shade(light: Palette.neutral900, dark: Palette.neutral50)
///     let accent    = Shade(Palette.jade500)
///     let xs: CGFloat = 4, sm: CGFloat = 8, md: CGFloat = 16, lg: CGFloat = 24
/// }
/// ```
///
/// Genera la conformance a ``ThemeProvider``. El acceso corto `Theme.light` lo genera el plugin
/// de build `LiveryRegistry` para todo tema que se pueda construir sin argumentos, y se aplica
/// con `.environment(\.theme, .light)`.
/// Las conformances a `Resolver` deben estar en la declaración, no en una extensión.
@attached(extension, conformances: ThemeProvider, names: named(resolvedTheme))
public macro Theme() = #externalMacro(module: "LiveryMacros", type: "ThemeMacro")

/// Marca la paleta de valores crudos de un sistema de diseño.
///
/// ```swift
/// @Primitives enum Palette {
///     static let jade500 = #colorLiteral(red: 0, green: 0.6, blue: 0.4, alpha: 1)
/// }
/// ```
///
/// Hoy solo documenta la intención y deja el enum visible para el exportador. La regla de que
/// las vistas no lean primitivos se cumple por frontera de módulo: declara la paleta en un
/// target que solo importen los temas.
@attached(peer)
public macro Primitives() = #externalMacro(module: "LiveryMacros", type: "PrimitivesMacro")

/// Declara cómo se expresa cada rol de un conjunto viejo en términos de uno nuevo.
///
/// Es la tabla de migración entre dos sistemas de diseño, escrita una vez y verificada. Cada
/// miembro cubre un rol del conjunto viejo: un `static let` lo renombra a un rol nuevo, y un
/// `static func` lo calcula a partir de los valores nuevos. Un comentario de documentación sobre
/// el `func` se convierte en el mensaje de deprecación.
///
/// ```swift
/// @Bridge(from: ColorsV1.self, to: Colors.self)
/// enum ColorsV1toV2 {
///     static let primary        = Colors.brand            // renombrado: fix-it automático
///     static let cardBackground = Colors.surfaceElevated
///     /// DS2 eliminó el divisor; usa `outline` con opacidad.
///     static func divider(_ colors: Colors.Values) -> Shade { colors.outline.opacity(0.4) }
/// }
/// ```
///
/// Con el plugin `LiveryRegistry` activo:
/// - El puente debe cubrir todos los roles de `ColorsV1` que no existan ya en `Colors`; si falta
///   uno, el build falla señalando el puente.
/// - `Colors.Values` gana un reenvío deprecado por cada rol viejo. Las vistas que leen
///   `theme.color.primary` siguen compilando, reciben `brand`, y muestran un warning con fix-it.
/// - `ColorsV1` deja de exponerse como `theme.color`; ese lugar lo ocupa `Colors`.
/// - El plugin avisa en la línea del puente cuántos usos quedan por migrar. En cero, borra
///   `ColorsV1` y el puente.
@attached(peer)
public macro Bridge<From, To>(from: From.Type, to: To.Type) = #externalMacro(module: "LiveryMacros", type: "BridgeMacro")
