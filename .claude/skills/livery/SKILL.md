---
name: livery
description: Build, theme, or edit a SwiftUI app's design system with Livery (semantic tokens, themes, components). Use when the task involves design tokens, theming, dark mode, colors/typography/spacing/shape/motion/elevation/icon roles, a themed button or text field, migrating a design system, or exporting tokens to W3C/Penpot/Figma — anytime a file declares @Roles, @Theme, @Component or @Bridge, reads theme.color/theme.type/etc, or the repo depends on the Livery package.
---

# Livery

Livery is a framework for building a design system in Swift. It is not a component kit; it is the
structure: layered **roles → themes → components**, enforced by the compiler. The app says the
intention (`theme.color.accent`), never a raw value, so changing a brand, a mode, or a whole design
system is repainting, not rebuilding.

## Mental model (read this first)

- **Primitives**: raw values (a hex, a point size). Live in their own module that views never import.
- **Roles**: the vocabulary. `@Roles enum Colors: ColorRoles { case surface, accent }`. Names are the
  project's; categories are fixed by the kernel.
- **Themes**: resolve every role. `@Theme struct Light: Colors.Resolver { let surface = …, accent = … }`.
  If a theme forgets a role, it is a compile error on the theme, with a fix-it.
- **Components**: a contract (`@Component`) plus a bespoke `Style` the theme provides; the app uses it
  through SwiftUI's native style protocols.

The hard rules, enforced not documented:
1. Views read roles, never primitives — guaranteed by module boundary (the app imports the design
   system, never its `Primitives` module).
2. Every role is resolved in every theme — guaranteed by `Resolver` conformance.
3. Colors decide light **and** dark, fonts scale with Dynamic Type, motion respects Reduce Motion —
   guaranteed by the value types (`Shade`, `TypeStyle`, `Motion`), not a lint.

## Setup

Fastest: `swift run --package-path <livery> theme init <Name>` scaffolds a package with
`<Name>Primitives` (palette), `<Name>` (roles + themes, plugin active) and tests. Then add it to the
app and apply the theme once at the root.

Manual structure of a design-system target:
```
Sources/<Name>Primitives/   Palette.swift, Metrics.swift   — only <Name> imports it
Sources/<Name>/             Roles.swift, Themes.swift
Sources/<Name>/Generated/   Livery+Registry.swift          — written by `swift package livery-generate`
```
The target depends on `Livery` and enables the build plugin:
```swift
.target(name: "<Name>", dependencies: [.product(name: "Livery", package: "Livery")],
        plugins: [.plugin(name: "LiveryRegistry", package: "Livery")])
```
After changing any `@Roles`, `@Theme`, `@Component` or `@Bridge`, regenerate:
`swift package --allow-writing-to-package-directory livery-generate`. The build plugin fails the
build if `Generated/Livery+Registry.swift` is stale, so this is not optional.

## The seven token categories

Declare a role set per category; the theme resolves each. All role enums are plain, and the macro
makes them `CaseIterable` (used by the gallery, export and contrast report).

| Category | Protocol | Accessor | Value type |
|---|---|---|---|
| Color | `ColorRoles` | `theme.color` | `Shade` — light + dark required, optional increased-contrast |
| Typography | `TypeRoles` | `theme.type` | `TypeStyle` — built from a system text style, scales with Dynamic Type |
| Spacing | `SpaceRoles` | `theme.space` | `CGFloat` (points) |
| Shape | `ShapeRoles` | `theme.shape` | `CGFloat` (corner radius) |
| Motion | `MotionRoles` | `theme.motion` | `Motion` — animation + optional reduced variant |
| Elevation | `ElevationRoles` | `theme.elevation` | `Elevation` — shadow whose color is a `Shade` |
| Icon | `IconRoles` | `theme.icon` | `Icon` — an SF Symbol, or a bundled custom symbol |

```swift
// Roles.swift
@Roles enum Colors: ColorRoles, CaseIterable { case surface, surfaceElevated, onSurface, onSurfaceSecondary, accent, onAccent, outline, danger }
@Roles enum Typography: TypeRoles, CaseIterable { case title, headline, body, caption }
@Roles enum Spacing: SpaceRoles, CaseIterable { case xs, sm, md, lg, xl }
@Roles enum Shapes: ShapeRoles, CaseIterable { case small, medium, large }
@Roles enum Motions: MotionRoles, CaseIterable { case quick, normal, slow }
@Roles enum Elevations: ElevationRoles, CaseIterable { case card, popover }
@Roles enum Icons: IconRoles, CaseIterable { case play, delete, favorite }

// Themes.swift — @Theme reads the Resolver conformances and registers each; the plugin writes theme.<cat> and .light
@Theme struct Light: Colors.Resolver, Typography.Resolver, Spacing.Resolver, Shapes.Resolver, Motions.Resolver, Elevations.Resolver, Icons.Resolver {
    let surface = Shade(light: Palette.slate50, dark: Palette.slate950)
    let onSurface = Shade(light: Palette.slate900, dark: Palette.slate100)
    let accent = Shade(light: Palette.indigo600, dark: Palette.indigo400)
    // … every color role, as a Shade …
    let title = TypeStyle(.title, weight: .semibold)   // never Font.system(size:) — that won't compile for a role
    let body  = TypeStyle(.body)
    let xs: CGFloat = 4, sm: CGFloat = 8, md: CGFloat = 16, lg: CGFloat = 24, xl: CGFloat = 40
    let small: CGFloat = 6, medium: CGFloat = 12, large: CGFloat = 20
    let quick = Motion(.easeOut(duration: 0.12))
    let card = Elevation(color: Shade(light: .black.opacity(0.10), dark: .black.opacity(0.45)), radius: 10, y: 4)
    let play = Icon("play.circle.fill"); let delete = Icon("trash"); let favorite = Icon("star.fill")
}
```

## Using it in views

Apply the theme once at the root (it is a SwiftUI environment value); set `.tint` so native controls
follow the accent. Read it with `@Environment(\.theme)` and use native modifiers.

```swift
ContentView()
    .environment(\.theme, .light)            // the generated short accessor; .environment(\.theme, adding: .dense) layers a partial theme
    .tint(/* from a themed root view */)

struct Card: View {
    @Environment(\.theme) private var theme
    var body: some View {
        VStack {
            Text("Title").textStyle(.title)                       // textStyle bundles a type role + a color role
            Text("Body").foregroundStyle(theme.color.onSurface)   // Shade is a ShapeStyle
                .font(theme.type.body)                            // TypeStyle via the font(_:) overload
            Image(theme.icon.favorite).symbolEffect(.bounce, value: liked)
        }
        .padding(theme.space.lg)
        .background(theme.color.surfaceElevated, in: .rect(cornerRadius: theme.shape.medium))
        .elevation(theme.elevation.card)
    }
}
```
`textStyle(_:)` (font + color in one call) and `tint` of native controls are example-level conveniences
the design system defines, not kernel API. Copy them into the design-system target.

## Components

A component is a contract plus a bespoke style stored in the theme. Mark the enum `@Component`; it
generates the `Styler` protocol; the plugin generates `theme.<component>`. The author writes the
`Style` struct and an `unstyled` fallback. Integrate through SwiftUI's own protocols: a themed
`ButtonStyle`, or a custom view for controls SwiftUI can't style (like a text field). Follow Apple's
HIG — for buttons that means a tint plus prominent/bordered/plain styles, with destructive as a role.
Build a bespoke component only when SwiftUI has no native control; for Text/Button/Toggle/icons,
theme the native primitive.

## Migration between design systems

When a new system replaces an old one, do not touch views. Declare the new role set, keep the old one,
and write one `@Bridge`:
```swift
@Bridge(from: ColorsV1.self, to: Colors.self)
enum ColorsV1toV2 {
    static let primary = Colors.accent                 // renamed → fix-it on every use
    static func divider(_ c: Colors.Values) -> Shade { c.outline.opacity(0.4) }   // removed → computed
}
```
The plugin verifies the bridge covers every old role, generates deprecated forwards on the new
`Values` (so old views compile and get the new colors), and reports remaining uses on the bridge line.
Warnings are the progress bar; at zero, delete the old set and the bridge.

## Accessibility and interop, verified not promised

- `theme.contrastReport()` returns the `onX`/`X` color pairs below WCAG AA in light and dark. Put it in
  a test so CI gates accessibility.
- `theme.w3cTokens(mode:)` exports a W3C Design Tokens JSON (Tokens Studio format) for Penpot/Figma.
- `theme import <file>.tokens.json` turns a designer's tokens file into `@Primitives` Swift.

## Gotchas

- Regenerate `Generated/Livery+Registry.swift` after any role/theme/component/bridge change, or the
  build fails (by design).
- Custom symbols ship as an SVG in an asset catalog (`.process` resource) resolved with
  `Icon("Name", in: .module)`. Asset catalogs are compiled by `actool`, which runs in **Xcode builds**
  only; a plain `swift run` copies them raw, so a custom symbol renders in Xcode/the app, not in a
  command-line snapshot. System SF Symbols always work.
- `ImageRenderer` (headless snapshots) cannot draw live controls — a `TextField` or `Toggle` shows a
  yellow placeholder. Verify those in a windowed build.
- A role's value type is fixed: a color must be a `Shade` (not `Color`), a font a `TypeStyle` (not
  `Font`) — a raw value won't compile. That is the guarantee, not a limitation.
- Minimum platform is iOS 17 / macOS 14 (`Color.Resolved`, `ShapeStyle.resolve`, `symbolEffect`).
