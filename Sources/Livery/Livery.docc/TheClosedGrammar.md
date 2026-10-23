# The closed grammar

What a Livery design system is allowed to be — the limits every theme and view plugs into.

## Overview

A design system drifts when anyone can invent a token. Livery closes the grammar so the system has a
shape a reader can hold: a fixed set of **categories**, a fixed **value type** per category, and one
rule for resolving them. The names inside each category are open — the system's vocabulary — but the
categories themselves, and the type a role must be, are the kernel's. This page is that boundary; a
view that steps outside it does not compile.

## The seven categories

Each category is a role protocol, a `theme` accessor, and a value type. A role set conforms to the
protocol; a theme resolves it; a view reads `theme.<category>.<role>`.

| Category | Protocol | Accessor | Value type |
| --- | --- | --- | --- |
| Color | ``ColorRoles`` | `theme.color` | ``Shade`` — light + dark required, optional increased-contrast |
| Typography | ``TypeRoles`` | `theme.type` | ``TypeStyle`` — built from a system text style, scales with Dynamic Type |
| Spacing | ``SpaceRoles`` | `theme.space` | `CGFloat` (points) |
| Shape | ``ShapeRoles`` | `theme.shape` | `CGFloat` (corner radius) |
| Motion | ``MotionRoles`` | `theme.motion` | ``Motion`` — animation + optional reduced variant |
| Elevation | ``ElevationRoles`` | `theme.elevation` | ``Elevation`` — a shadow whose color is a ``Shade`` |
| Icon | ``IconRoles`` | `theme.icon` | ``Icon`` — an SF Symbol, or a bundled custom symbol |

## Declaring the vocabulary

Roles are plain enums marked `@Roles`; the macro makes them `CaseIterable` so a catalog, the export,
and the contrast report can walk them.

```swift
@Roles enum Colors: ColorRoles, CaseIterable { case surface, onSurface, accent, danger }
@Roles enum Typography: TypeRoles, CaseIterable { case title, body, caption }
@Roles enum Spacing: SpaceRoles, CaseIterable { case xs, sm, md, lg, xl }
```

## Resolving a theme

A theme conforms to each category's `Resolver`. `@Theme` reads those conformances and registers them;
the build plugin writes `theme.color`, the `.light` static accessor, and the rest.

```swift
@Theme struct Light: Colors.Resolver, Typography.Resolver, Spacing.Resolver {
    let surface   = Shade(light: .white, dark: .black)
    let onSurface = Shade(light: .black, dark: .white)
    let accent    = Shade(light: .indigo, dark: .mint)
    let danger    = Shade(.red)
    let title = TypeStyle(.title, weight: .semibold)
    let body  = TypeStyle(.body)
    let caption = TypeStyle(.caption)
    let xs: CGFloat = 4, sm: CGFloat = 8, md: CGFloat = 16, lg: CGFloat = 24, xl: CGFloat = 40
}
```

Forget a role and the error lands on the theme, with a fix-it. That is the point: the system cannot be
half-resolved.

## Why the limits hold

- **Views read roles, never primitives** — the primitive palette lives in a module the app never
  imports.
- **Every role is resolved in every theme** — guaranteed by `Resolver` conformance, checked by the
  compiler.
- **A color decides light and dark, a font scales, motion respects Reduce Motion** — guaranteed by the
  value types ``Shade``, ``TypeStyle`` and ``Motion``, not by a lint anyone can ignore.

## Topics

- ``Theme``
- ``Shade``
- ``TypeStyle``
