import Foundation
import Testing
@testable import LiveryScaffold

@Suite struct ScaffoldTests {
    @Test func namesAreValidated() {
        #expect(Scaffold.isValidName("DesignSystem"))
        #expect(Scaffold.isValidName("Sajaru_DS2"))
        #expect(!Scaffold.isValidName("2DS"))
        #expect(!Scaffold.isValidName("Design-System"))
        #expect(!Scaffold.isValidName(""))
    }

    @Test func filesFollowTheProposedStructure() {
        let scaffold = Scaffold(name: "Sajaru", livery: .path("../Livery"))
        let paths = scaffold.files.map(\.path)
        #expect(paths == [
            "Package.swift",
            "Sources/SajaruPrimitives/Palette.swift",
            "Sources/SajaruPrimitives/Metrics.swift",
            "Sources/Sajaru/Roles.swift",
            "Sources/Sajaru/Themes.swift",
            "Sources/Sajaru/Generated/Livery+Registry.swift",
            "Tests/SajaruTests/SajaruTests.swift",
            ".gitignore",
            "README.md",
        ])
        let package = scaffold.files[0].contents
        #expect(package.contains(".package(name: \"Livery\", path: \"../Livery\"),"))
        #expect(package.contains("plugins: [.plugin(name: \"LiveryRegistry\", package: \"Livery\")]"))
        #expect(package.contains("dependencies: [\"SajaruPrimitives\", .product(name: \"Livery\", package: \"Livery\")]"))
        #expect(scaffold.files[4].contents.contains("import SajaruPrimitives"))
        #expect(!scaffold.files[3].contents.contains("Primitives"), "los roles no conocen la paleta")
        let registry = scaffold.files[5].contents
        #expect(registry.contains("public var color: Colors.Values { values(Colors.self) }"))
        #expect(registry.contains("public static var base: Livery.Theme { Base().resolvedTheme }"))
    }

    @Test func defaultDependencyIsGitHubMaster() {
        let package = Scaffold(name: "DesignSystem").files[0].contents
        #expect(package.contains(".package(url: \"https://github.com/fsaldivar-dev/Livery.git\", branch: \"master\"),"))
    }

    @Test func writesAndRefusesToOverwrite() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "livery-scaffold-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let scaffold = Scaffold(name: "Demo")
        let root = try scaffold.write(into: directory)
        #expect(root.lastPathComponent == "Demo")
        for file in scaffold.files {
            #expect(FileManager.default.fileExists(atPath: root.appending(path: file.path).path()), Comment(rawValue: file.path))
        }
        #expect(throws: ScaffoldError.self) { try scaffold.write(into: directory) }
    }
}
