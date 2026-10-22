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
        // Los demás módulos del paquete solo se leen para contar usos pendientes de cada @Bridge.
        let usages = context.package.targets
            .compactMap { $0 as? SwiftSourceModuleTarget }
            .filter { $0.id != target.id }
            .flatMap { $0.sourceFiles(withSuffix: "swift").map(\.url) }
        return [try command(tool: context.tool(named: "livery-registry").url,
                            workDirectory: context.pluginWorkDirectoryURL,
                            targetName: target.name, inputs: inputs, usages: usages)]
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension LiveryRegistry: XcodeBuildToolPlugin {
    func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
        let inputs = target.inputFiles.filter { $0.url.pathExtension == "swift" }.map(\.url)
        let usages = context.xcodeProject.targets
            .filter { $0.id != target.id }
            .flatMap { $0.inputFiles.filter { $0.url.pathExtension == "swift" }.map(\.url) }
        return [try command(tool: context.tool(named: "livery-registry").url,
                            workDirectory: context.pluginWorkDirectoryURL,
                            targetName: target.displayName, inputs: inputs, usages: usages)]
    }
}
#endif

private func command(tool: URL, workDirectory: URL, targetName: String, inputs: [URL], usages: [URL]) throws -> Command {
    let output = workDirectory.appending(path: "Livery+Registry.swift")
    var arguments = [output.path()] + inputs.map { $0.path() }
    if !usages.isEmpty { arguments += ["--usages"] + usages.map { $0.path() } }
    return .buildCommand(
        displayName: "Livery: registrar roles, temas y puentes de \(targetName)",
        executable: tool,
        arguments: arguments,
        inputFiles: inputs + usages,
        outputFiles: [output]
    )
}
