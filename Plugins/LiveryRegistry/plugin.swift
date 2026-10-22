//
//  plugin.swift
//  LiveryRegistry
//
//  Build-tool plugin de Livery: antes de compilar cada módulo, genera `Livery+Registry.swift` con
//  la extensión de `Theme` que los macros no pueden escribir: `theme.color` por cada `@Roles`
//  y `.light` por cada `@Theme`. Actívalo en el target que declara el sistema de diseño:
//
//      .target(name: "App", dependencies: [.product(name: "Livery", package: "Livery")],
//              plugins: [.plugin(name: "LiveryRegistry", package: "Livery")])
//

import Foundation
import PackagePlugin

@main
struct LiveryRegistry: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        guard let target = target as? SwiftSourceModuleTarget else { return [] }
        let inputs = target.sourceFiles(withSuffix: "swift").map(\.url)
        return [try command(tool: context.tool(named: "livery-registry").url,
                            workDirectory: context.pluginWorkDirectoryURL,
                            targetName: target.name, inputs: inputs)]
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension LiveryRegistry: XcodeBuildToolPlugin {
    func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
        let inputs = target.inputFiles.filter { $0.url.pathExtension == "swift" }.map(\.url)
        return [try command(tool: context.tool(named: "livery-registry").url,
                            workDirectory: context.pluginWorkDirectoryURL,
                            targetName: target.displayName, inputs: inputs)]
    }
}
#endif

private func command(tool: URL, workDirectory: URL, targetName: String, inputs: [URL]) throws -> Command {
    let output = workDirectory.appending(path: "Livery+Registry.swift")
    return .buildCommand(
        displayName: "Livery: registrar roles y temas de \(targetName)",
        executable: tool,
        arguments: [output.path()] + inputs.map { $0.path() },
        inputFiles: inputs,
        outputFiles: [output]
    )
}
