# ``Livery``

Build a design system in Swift — layered **roles → themes → components**, enforced by the compiler.

## Overview

Livery is not a component kit; it is the structure. A view states the intention (``Theme`` ·
`color.accent`), never a raw value, so changing a brand, a mode, or a whole design system is
*repainting*, not *rebuilding*.

This documentation is the reference, and it is the system's **limits**. Read it the way you would read
a design-system page in Figma: the board every screen plugs into. The grammar is **closed** — seven
token categories, role sets, and a fixed value type per category — and the vocabulary is **open**: the
role names are the project's own.

Three rules, enforced not documented:

- A **role** is the vocabulary. `@Roles enum Colors: ColorRoles { case surface, accent }`. The
  categories are fixed by the kernel; the names are yours.
- A **theme** resolves every role. `@Theme struct Light: Colors.Resolver { … }`. If a theme forgets a
  role, it is a compile error on the theme, with a fix-it.
- A **value type** is the guarantee. A color is a ``Shade`` (light *and* dark, always), a font a
  ``TypeStyle`` (scales with Dynamic Type), motion a ``Motion`` (respects Reduce Motion). A raw value
  for a role does not compile.

Views read the theme from the environment and use native modifiers:

```swift
struct Card: View {
    @Environment(\.theme) private var theme
    var body: some View {
        Text("Title")
            .font(theme.type.title)                     // TypeStyle via the font(_:) overload
            .foregroundStyle(theme.color.onSurface)     // Shade is a ShapeStyle
            .padding(theme.space.lg)
            .background(theme.color.surface, in: .rect(cornerRadius: theme.shape.medium))
    }
}
```

## Topics

### Essentials

- ``Theme``
- ``ThemeProvider``
- <doc:TheClosedGrammar>

### Token value types

- ``Shade``
- ``TypeStyle``
- ``Motion``
- ``Elevation``
- ``Icon``

### Role categories

- ``ColorRoles``
- ``TypeRoles``
- ``SpaceRoles``
- ``ShapeRoles``
- ``MotionRoles``
- ``ElevationRoles``
- ``IconRoles``
- ``RoleSet``

### Components

- ``ComponentState``
- ``ComponentVariant``
- ``ComponentSize``

### Accessibility and export

- ``ContrastChecker``
- ``ContrastIssue``
- ``WCAGLevel``
- ``W3CDocument``
- ``TokenMode``
