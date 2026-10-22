//
//  Scaffold.swift
//  LiveryScaffold
//
//  `theme init`: la estructura de un sistema de diseño, generada en vez de documentada, porque
//  una convención que no se genera no se sigue. Produce un paquete Swift con dos módulos:
//
//      <Nombre>/
//        Package.swift
//        Sources/<Nombre>Primitives/   ← la paleta y las medidas crudas; solo <Nombre> lo importa
//        Sources/<Nombre>/             ← roles y temas, con el plugin LiveryRegistry activo
//        Tests/<Nombre>Tests/          ← el tema resuelve lo que declara
//

import Foundation

public struct Scaffold {
    /// Nombre del paquete y del módulo de roles y temas. También prefijo del módulo de primitivos.
    public var name: String
    /// Dependencia de Livery: una URL de git o una ruta local.
    public var livery: Dependency

    public enum Dependency: Equatable, Sendable {
        case url(String, branch: String)
        case path(String)

        public static let `default` = Dependency.url("https://github.com/fsaldivar-dev/Livery.git", branch: "master")

        var manifest: String {
            switch self {
            case .url(let url, let branch): "        .package(url: \"\(url)\", branch: \"\(branch)\"),"
            case .path(let path): "        .package(name: \"Livery\", path: \"\(path)\"),"
            }
        }
    }

    public init(name: String, livery: Dependency = .default) {
        self.name = name
        self.livery = livery
    }

    /// Un nombre válido de módulo Swift: letras, dígitos y guiones bajos, sin empezar por dígito.
    public static func isValidName(_ name: String) -> Bool {
        guard let first = name.first, first.isLetter || first == "_" else { return false }
        return name.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" }
    }

    public var primitivesModule: String { name + "Primitives" }
    public var testsModule: String { name + "Tests" }

    /// Ruta relativa y contenido de cada archivo.
    public var files: [(path: String, contents: String)] {
        [
            ("Package.swift", package),
            ("Sources/\(primitivesModule)/Palette.swift", palette),
            ("Sources/\(primitivesModule)/Metrics.swift", metrics),
            ("Sources/\(name)/Roles.swift", roles),
            ("Sources/\(name)/Themes.swift", themes),
            ("Tests/\(testsModule)/\(testsModule).swift", tests),
            (".gitignore", ".build/\n.swiftpm/\nxcuserdata/\n.DS_Store\n"),
            ("README.md", readme),
        ]
    }

    /// Escribe el paquete en `directory/<name>`. Falla si la carpeta ya existe.
    @discardableResult
    public func write(into directory: URL) throws -> URL {
        let root = directory.appending(path: name)
        let fileManager = FileManager.default
        guard !fileManager.fileExists(atPath: root.path()) else {
            throw ScaffoldError.alreadyExists(root.path())
        }
        for file in files {
            let url = root.appending(path: file.path)
            try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try file.contents.write(to: url, atomically: true, encoding: .utf8)
        }
        return root
    }

    /// Lo que la app tiene que hacer después.
    public var nextSteps: String {
        """
        Siguiente paso: enlaza \(name) en tu app.

          1. Añade el paquete como dependencia local (Xcode: File › Add Package Dependencies › Add Local…).
          2. En el target de la app, importa `\(name)` y aplica el tema en la raíz:

                 import \(name)
                 import Livery

                 ContentView().theme(.base)

          3. Activa el plugin LiveryRegistry en los targets de UI para que el lint vigile
             colores, fuentes y medidas decididas fuera del sistema (Xcode: Build Phases ›
             Run Build Tool Plug-ins; SwiftPM: `plugins: [.plugin(name: "LiveryRegistry", package: "Livery")]`).

        Las vistas hablan solo en roles: `.foregroundStyle(.theme.color.onSurface)`, `.padding(.theme.space.md)`.
        Nunca importes \(primitivesModule) desde una vista: ahí viven los valores crudos.
        """
    }

    // MARK: - Plantillas

    var package: String {
        """
        // swift-tools-version: 6.2
        import PackageDescription

        // Sistema de diseño de la app, construido con Livery. Generado por `theme init`.
        //
        // \(primitivesModule): los valores crudos (paleta, medidas). Solo \(name) lo importa.
        // \(name): roles y temas. El plugin LiveryRegistry genera `theme.color`, `.base`, etc.
        let package = Package(
            name: "\(name)",
            platforms: [.iOS(.v17), .macOS(.v14), .tvOS(.v17), .watchOS(.v10), .visionOS(.v1)],
            products: [
                .library(name: "\(name)", targets: ["\(name)"]),
            ],
            dependencies: [
        \(livery.manifest)
            ],
            targets: [
                .target(
                    name: "\(primitivesModule)",
                    dependencies: [.product(name: "Livery", package: "Livery")]
                ),
                .target(
                    name: "\(name)",
                    dependencies: ["\(primitivesModule)", .product(name: "Livery", package: "Livery")],
                    plugins: [.plugin(name: "LiveryRegistry", package: "Livery")]
                ),
                .testTarget(name: "\(testsModule)", dependencies: ["\(name)"]),
            ]
        )

        """
    }

    var palette: String {
        """
        //
        //  Palette.swift
        //  \(primitivesModule)
        //
        //  Los valores crudos del sistema. Nombres de pintura, no de intención: aquí no hay `accent`
        //  ni `surface`, eso lo deciden los temas en \(name). Este módulo solo lo importa \(name).
        //

        import Livery

        @Primitives public enum Palette {
            // Neutros, del papel a la tinta.
            public static let neutral50  = Color(hex: 0xF8FAFC)
            public static let neutral100 = Color(hex: 0xF1F5F9)
            public static let neutral200 = Color(hex: 0xE2E8F0)
            public static let neutral300 = Color(hex: 0xCBD5E1)
            public static let neutral400 = Color(hex: 0x94A3B8)
            public static let neutral500 = Color(hex: 0x64748B)
            public static let neutral600 = Color(hex: 0x475569)
            public static let neutral700 = Color(hex: 0x334155)
            public static let neutral800 = Color(hex: 0x1E293B)
            public static let neutral900 = Color(hex: 0x0F172A)
            public static let neutral950 = Color(hex: 0x020617)

            // El color de marca. Cámbialo aquí y el tema lo recoge.
            public static let brand400 = Color(hex: 0x818CF8)
            public static let brand500 = Color(hex: 0x6366F1)
            public static let brand600 = Color(hex: 0x4F46E5)

            public static let danger400 = Color(hex: 0xFB7185)
            public static let danger600 = Color(hex: 0xE11D48)

            public static let white = Color.white
        }

        extension Color {
            /// `0xRRGGBB`. Solo para la paleta: las vistas nunca ven un hex.
            init(hex: UInt32) {
                self.init(
                    red: Double((hex >> 16) & 0xFF) / 255,
                    green: Double((hex >> 8) & 0xFF) / 255,
                    blue: Double(hex & 0xFF) / 255
                )
            }
        }

        """
    }

    var metrics: String {
        """
        //
        //  Metrics.swift
        //  \(primitivesModule)
        //

        import Livery

        @Primitives public enum Metrics {
            /// Unidad base de la escala de espaciado. Todo espacio es un múltiplo.
            public static let unit: CGFloat = 4
        }

        """
    }

    var roles: String {
        """
        //
        //  Roles.swift
        //  \(name)
        //
        //  Qué existe. Nombres de intención: una vista pide `accent`, nunca `brand500`.
        //  Añade un rol y todos los temas dejan de compilar hasta resolverlo. Renombra uno con el
        //  refactor de Xcode. Cuando llegue un sistema nuevo, declara el conjunto nuevo y un @Bridge.
        //

        import Livery

        @Roles public enum Colors: ColorRoles, CaseIterable {
            case surface, surfaceElevated, onSurface, onSurfaceSecondary
            case accent, onAccent, outline, danger
        }

        @Roles public enum Typography: TypeRoles, CaseIterable {
            case title, headline, body, caption
        }

        @Roles public enum Spacing: SpaceRoles, CaseIterable {
            case xs, sm, md, lg, xl
        }

        @Roles public enum Shapes: ShapeRoles, CaseIterable {
            case small, medium, large
        }

        """
    }

    var themes: String {
        """
        //
        //  Themes.swift
        //  \(name)
        //
        //  Cómo se resuelve cada rol. Si un tema olvida uno, el compilador lo señala aquí.
        //  Un color es un `Shade`: claro y oscuro decididos siempre; contraste aumentado opcional.
        //  Se aplica con `.theme(.base)`; el acceso corto lo genera el plugin.
        //

        import Livery
        import \(primitivesModule)

        @Theme public struct Base: Colors.Resolver, Typography.Resolver, Spacing.Resolver, Shapes.Resolver {
            public init() {}

            public let surface            = Shade(light: Palette.neutral50, dark: Palette.neutral950)
            public let surfaceElevated    = Shade(light: Palette.white, dark: Palette.neutral900)
            public let onSurface          = Shade(light: Palette.neutral900, dark: Palette.neutral100)
            public let onSurfaceSecondary = Shade(light: Palette.neutral500, dark: Palette.neutral400, darkIncreased: Palette.neutral300)
            public let accent             = Shade(light: Palette.brand600, dark: Palette.brand400)
            public let onAccent           = Shade(light: Palette.white, dark: Palette.neutral950)
            public let outline            = Shade(light: Palette.neutral200, dark: Palette.neutral800)
            public let danger             = Shade(light: Palette.danger600, dark: Palette.danger400)

            public let title    = Font.title.weight(.semibold)
            public let headline = Font.headline
            public let body     = Font.body
            public let caption  = Font.caption

            public let xs = Metrics.unit
            public let sm = Metrics.unit * 2
            public let md = Metrics.unit * 4
            public let lg = Metrics.unit * 6
            public let xl = Metrics.unit * 10

            public let small: CGFloat  = 6
            public let medium: CGFloat = 12
            public let large: CGFloat  = 20
        }

        """
    }

    var tests: String {
        """
        import Livery
        import Testing
        @testable import \(name)

        @Suite struct \(testsModule) {
            @Test func baseResolvesEveryRoleSet() {
                let theme = Theme.base
                #expect(theme.resolves(Colors.self))
                #expect(theme.resolves(Typography.self))
                #expect(theme.resolves(Spacing.self))
                #expect(theme.resolves(Shapes.self))
            }

            @Test func spacingScaleIsIncreasing() {
                let values = Spacing.allCases.map { Theme.base.space[$0] }
                #expect(values == values.sorted())
            }
        }

        """
    }

    var readme: String {
        """
        # \(name)

        El sistema de diseño de la app, construido con [Livery](https://github.com/fsaldivar-dev/Livery).
        Generado por `theme init`.

        - `Sources/\(primitivesModule)`: la paleta y las medidas crudas. Solo `\(name)` lo importa.
        - `Sources/\(name)`: los roles (qué existe) y los temas (cómo se resuelve). El plugin
          `LiveryRegistry` genera `theme.color`, `theme.space`, `.base`, etc.
        - `Tests/\(testsModule)`: el tema resuelve todo lo que declara.

        En la app:

        ```swift
        import \(name)
        import Livery

        ContentView().theme(.base)

        Text("Hola")
            .font(.theme.type.body)
            .foregroundStyle(.theme.color.onSurface)
            .padding(.theme.space.md)
        ```

        """
    }
}

public enum ScaffoldError: Error, CustomStringConvertible {
    case alreadyExists(String)
    case invalidName(String)

    public var description: String {
        switch self {
        case .alreadyExists(let path): "Ya existe \(path). Elige otro nombre o borra la carpeta."
        case .invalidName(let name): "`\(name)` no es un nombre de módulo válido: usa letras, dígitos y guiones bajos, sin empezar por dígito."
        }
    }
}
