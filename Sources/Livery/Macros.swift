//
//  Macros.swift
//  Livery
//

/// Declara los conjuntos de roles de un sistema de diseño.
///
/// Se aplica a una `extension Theme`. Cada enum dentro declara un conjunto de roles y su
/// categoría por conformance: ``ColorRoles``, ``TypeRoles``, ``SpaceRoles`` o ``ShapeRoles``.
///
/// ```swift
/// @Roles extension Theme {
///     enum Colors: ColorRoles { case surface, onSurface, accent }
///     enum Spacing: SpaceRoles { case xs, sm, md, lg }
/// }
/// ```
///
/// Por cada enum genera:
/// - `Colors.Resolver`: un protocolo con una propiedad por rol. Un tema lo conforma, y si olvida
///   un rol, el compilador lo señala en la línea del tema.
/// - `Colors.Values`: la resolución inmutable que viaja en ``Theme``.
/// - `Theme.color` (o `type`, `space`, `shape` según la categoría), para que `\.color.surface`
///   exista como key path.
///
/// Una categoría solo puede declararse una vez por tema.
@attached(member, names: named(color), named(type), named(space), named(shape))
@attached(memberAttribute)
public macro Roles() = #externalMacro(module: "LiveryMacros", type: "RolesMacro")

/// Macro interna que ``Roles()`` adjunta a cada enum de roles. No la uses directamente.
@attached(member, names: named(Resolver), named(Values), named(unresolved))
@attached(extension, conformances: RoleSet)
public macro _RoleSet() = #externalMacro(module: "LiveryMacros", type: "RoleSetMacro")

/// Declara un tema: la resolución de uno o más conjuntos de roles.
///
/// Los conjuntos que resuelve se declaran como conformances a sus `Resolver`. La completitud la
/// verifica el compilador: si falta un rol, es un error de conformance con fix-it.
///
/// ```swift
/// @Theme struct Light: Theme.Colors.Resolver, Theme.Spacing.Resolver {
///     let surface   = Palette.neutral50
///     let onSurface = Palette.neutral900
///     let accent    = Palette.jade500
///     let xs: CGFloat = 4, sm: CGFloat = 8, md: CGFloat = 16, lg: CGFloat = 24
/// }
/// ```
///
/// Genera la conformance a ``ThemeProvider`` para poder aplicarlo con `.theme(Light())`.
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
