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
//  Si el target ya tiene `Generated/Livery+Registry.swift` entre sus fuentes (escrito por el
//  command plugin LiveryGenerate, para que Xcode lo vea como código normal), aquí no se genera
//  otro: solo se verifica que esté al día y el build falla si no.
//

import Foundation
import PackagePlugin

@main
struct LiveryRegistry: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        guard let target = target as? SwiftSourceModuleTarget else { return [] }
        let allInputs = target.sourceFiles(withSuffix: "swift").map(\.url)
        let committed = allInputs.first { $0.lastPathComponent == registryFileName }
        let inputs = allInputs.filter { $0 != committed }
        // Los demás módulos del paquete solo se leen para contar usos pendientes de cada @Bridge.
        let usages = context.package.targets
            .compactMap { $0 as? SwiftSourceModuleTarget }
            .filter { $0.id != target.id }
            .flatMap { $0.sourceFiles(withSuffix: "swift").map(\.url) }
        return [try command(tool: context.tool(named: "livery-registry").url,
                            workDirectory: context.pluginWorkDirectoryURL,
                            targetName: target.name, inputs: inputs, usages: usages, verify: committed)]
    }
}

private let registryFileName = "Livery+Registry.swift"

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension LiveryRegistry: XcodeBuildToolPlugin {
    func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
        let allInputs = target.inputFiles.filter { $0.url.pathExtension == "swift" }.map(\.url)
        let committed = allInputs.first { $0.lastPathComponent == registryFileName }
        let inputs = allInputs.filter { $0 != committed }
        let usages = context.xcodeProject.targets
            .filter { $0.id != target.id }
            .flatMap { $0.inputFiles.filter { $0.url.pathExtension == "swift" }.map(\.url) }
        return [try command(tool: context.tool(named: "livery-registry").url,
                            workDirectory: context.pluginWorkDirectoryURL,
                            targetName: target.displayName, inputs: inputs, usages: usages, verify: committed)]
    }
}
#endif

private func command(tool: URL, workDirectory: URL, targetName: String, inputs: [URL], usages: [URL], verify: URL?) throws -> Command {
    // Con un archivo generado en Sources, la salida del build es un stub: el nombre cambia para no duplicar el tipo.
    let output = workDirectory.appending(path: verify == nil ? registryFileName : "Livery+RegistryCheck.swift")
    var arguments = [output.path()] + inputs.map { $0.path() }
    if !usages.isEmpty { arguments += ["--usages"] + usages.map { $0.path() } }
    if let verify { arguments += ["--verify", verify.path()] }
    return .buildCommand(
        displayName: verify == nil
            ? "Livery: registrar roles, temas y puentes de \(targetName)"
            : "Livery: verificar Generated/\(registryFileName) de \(targetName)",
        executable: tool,
        arguments: arguments,
        inputFiles: inputs + usages + (verify.map { [$0] } ?? []),
        outputFiles: [output]
    )
}
