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
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", "600.0.0"..<"605.0.0"),
    ],
    targets: [
        // Plugin del compilador: el `aapt` de Livery. Lee declaraciones, verifica y genera accesores.
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

        // Pruebas end-to-end: roles, temas y resolución desde el entorno.
        .testTarget(name: "LiveryTests", dependencies: ["Livery"]),
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
