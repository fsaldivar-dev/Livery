// swift-tools-version: 6.2
import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "Livery",
    platforms: [
        .iOS(.v17), .macOS(.v14), .tvOS(.v17), .watchOS(.v10), .macCatalyst(.v17), .visionOS(.v1),
    ],
    products: [
        /// Runtime (`Theme`, `.theme(_:)`, key paths como estilos) y las macros `@Roles`, `@Theme`, `@Primitives`.
        .library(name: "Livery", targets: ["Livery"]),
        /// Build-tool plugin: genera `theme.color` por cada `@Roles` y `.light` por cada `@Theme`,
        /// o verifica el archivo generado en Sources si existe. También lint y reporte de puentes.
        .plugin(name: "LiveryRegistry", targets: ["LiveryRegistry"]),
        /// Command plugin: escribe `Sources/<Target>/Generated/Livery+Registry.swift` para que Xcode lo vea.
        .plugin(name: "LiveryGenerate", targets: ["LiveryGenerate"]),
        /// CLI: `theme init` genera la estructura de un sistema de diseño.
        .executable(name: "theme", targets: ["theme"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", "600.0.0"..<"605.0.0"),
    ],
    targets: [
        // Plugin del compilador: verifica declaraciones y genera lo que vive dentro del tipo decorado.
        .macro(
            name: "LiveryMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
            ]
        ),
        // Runtime público.
        .target(name: "Livery", dependencies: ["LiveryMacros"]),

        // Registro: el `aapt` de Livery. Generador, herramienta y plugin de build.
        .target(
            name: "LiveryRegistryCore",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
            ]
        ),
        .executableTarget(name: "livery-registry", dependencies: ["LiveryRegistryCore"]),
        .plugin(
            name: "LiveryRegistry",
            capability: .buildTool(),
            dependencies: ["livery-registry"]
        ),
        .plugin(
            name: "LiveryGenerate",
            capability: .command(
                intent: .custom(verb: "livery-generate", description: "Escribe Sources/<Target>/Generated/Livery+Registry.swift"),
                permissions: [.writeToPackageDirectory(reason: "Escribir el archivo generado dentro de Sources del target")]
            ),
            dependencies: ["livery-registry"]
        ),

        // CLI: plantillas de `theme init` y el ejecutable. Usa el generador para dejar escrito
        // `Generated/Livery+Registry.swift`, así el paquete nuevo funciona en Xcode desde el primer momento.
        .target(name: "LiveryScaffold", dependencies: ["LiveryRegistryCore"]),
        .executableTarget(name: "theme", dependencies: ["LiveryScaffold"]),

        // Pruebas end-to-end: roles y temas planos, con el plugin activo, resueltos desde el entorno.
        .testTarget(name: "LiveryTests", dependencies: ["Livery"], plugins: ["LiveryRegistry"]),
        // Pruebas del generador del registro.
        .testTarget(name: "LiveryRegistryTests", dependencies: ["LiveryRegistryCore"]),
        // Pruebas de las plantillas de `theme init`.
        .testTarget(name: "LiveryScaffoldTests", dependencies: ["LiveryScaffold"]),
        // Pruebas de expansión y diagnósticos de las macros.
        .testTarget(
            name: "LiveryMacrosTests",
            dependencies: [
                "LiveryMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
