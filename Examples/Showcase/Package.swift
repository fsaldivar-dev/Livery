// swift-tools-version: 6.2
import PackageDescription

// Showcase: un sistema de diseño declarado con Livery y una galería para verlo cambiar de tema,
// de modo y de densidad. Sigue la estructura que Livery propone: los primitivos viven en un
// módulo que solo los temas importan, así una vista no puede leer `Palette` ni queriendo.
//
//   swift run --package-path Examples/Showcase      (macOS)
let package = Package(
    name: "Showcase",
    platforms: [.macOS(.v14), .iOS(.v17)],
    dependencies: [
        // `name:` fija la identidad: SwiftPM la derivaría del nombre de la carpeta.
        .package(name: "Livery", path: "../.."),
    ],
    targets: [
        // Valores crudos. Solo DesignSystem lo importa.
        .target(
            name: "Primitives",
            dependencies: [.product(name: "Livery", package: "Livery")]
        ),
        // Roles y temas. El plugin genera `theme.color`, `.daylight`, `.carbon`, `.dense`.
        .target(
            name: "DesignSystem",
            dependencies: ["Primitives", .product(name: "Livery", package: "Livery")],
            resources: [.process("Resources/Symbols.xcassets")],
            plugins: [.plugin(name: "LiveryRegistry", package: "Livery")]
        ),
        // La app: importa DesignSystem y Livery, nunca Primitives. Con el plugin activo, el lint
        // avisa de cualquier color, fuente o medida decidida fuera del sistema.
        .executableTarget(
            name: "Showcase",
            dependencies: ["DesignSystem", .product(name: "Livery", package: "Livery")],
            plugins: [.plugin(name: "LiveryRegistry", package: "Livery")]
        ),
    ]
)
