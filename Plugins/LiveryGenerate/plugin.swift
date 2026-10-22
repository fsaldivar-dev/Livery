//
//  plugin.swift
//  LiveryGenerate
//
//  Command plugin de Livery: escribe `Sources/<Target>/Generated/Livery+Registry.swift` en cada
//  target del paquete que declara @Roles, @Theme o @Bridge. Al vivir en Sources, Xcode lo trata
//  como código normal: navegación y autocompletado sin depender del índice de salidas de plugins.
//
//      swift package --allow-writing-to-package-directory livery-generate [--target Nombre]
//
//  Desde Xcode: clic derecho sobre el paquete › LiveryGenerate. El build-tool plugin LiveryRegistry
//  verifica después, en cada build, que el archivo siga al día.
//

import Foundation
import PackagePlugin

@main
struct LiveryGenerate: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        var wanted: Set<String> = []
        var iterator = arguments.makeIterator()
        while let argument = iterator.next() {
            if argument == "--target", let name = iterator.next() { wanted.insert(name) }
        }
        let targets = context.package.targets.compactMap { $0 as? SwiftSourceModuleTarget }
        let selected = wanted.isEmpty ? targets : targets.filter { wanted.contains($0.name) }
        for target in selected {
            try generate(for: target, among: targets, tool: try context.tool(named: "livery-registry").url)
        }
    }

    private func generate(for target: SwiftSourceModuleTarget, among targets: [SwiftSourceModuleTarget], tool: URL) throws {
        let sources = target.sourceFiles(withSuffix: "swift").map(\.url)
        let declares = sources.contains { url in
            guard let text = try? String(contentsOf: url, encoding: .utf8) else { return false }
            return text.contains("@Roles") || text.contains("@Theme") || text.contains("@Bridge")
        }
        guard declares else { return }

        let output = target.directoryURL.appending(path: "Generated").appending(path: "Livery+Registry.swift")
        let inputs = sources.filter { $0 != output }
        let usages = targets.filter { $0.id != target.id }.flatMap { $0.sourceFiles(withSuffix: "swift").map(\.url) }
        var arguments = [output.path()] + inputs.map { $0.path() }
        if !usages.isEmpty { arguments += ["--usages"] + usages.map { $0.path() } }

        let process = Process()
        process.executableURL = tool
        process.arguments = arguments
        try process.run()
        process.waitUntilExit()
        if process.terminationStatus == 0 {
            print("Livery: escrito \(output.path())")
        } else {
            Diagnostics.error("Livery: no se pudo generar \(output.path()) (ver errores arriba).")
        }
    }
}
