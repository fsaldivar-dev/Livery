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
/// - `Colors.unresolved`: valores de reserva visibles (rosa, `body`, `0`).
///
/// La propiedad `theme.color` (o `type`, `space`, `shape`) la genera el plugin de build
/// `LiveryRegistry`, que debe estar activo en el target. Una categoría solo puede declararse
/// una vez por módulo; el plugin lo verifica.
@attached(member, names: named(Resolver), named(Values), named(unresolved))
@attached(extension, conformances: RoleSet)
public macro Roles() = #externalMacro(module: "LiveryMacros", type: "RolesMacro")

/// Declara un tema: la resolución de uno o más conjuntos de roles.
///
/// Los conjuntos que resuelve se declaran como conformances a sus `Resolver`. La completitud la
/// verifica el compilador: si falta un rol, es un error de conformance con fix-it.
///
/// ```swift
/// @Theme struct Light: Colors.Resolver, Spacing.Resolver {
///     let surface   = Palette.neutral50
///     let onSurface = Palette.neutral900
///     let accent    = Palette.jade500
///     let xs: CGFloat = 4, sm: CGFloat = 8, md: CGFloat = 16, lg: CGFloat = 24
/// }
/// ```
///
/// Genera la conformance a ``ThemeProvider`` para poder aplicarlo con `.theme(Light())`.
/// El acceso corto `.theme(.light)` lo genera el plugin de build `LiveryRegistry` para todo
/// tema que se pueda construir sin argumentos.
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
