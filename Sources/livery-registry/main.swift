//
//  main.swift
//  livery-registry
//
//  Uso: livery-registry <salida.swift> <fuentes del módulo…> [--usages <fuentes de otros módulos…>]
//                       [--verify <Sources/…/Generated/Livery+Registry.swift>]
//
//  Lo invocan los plugins LiveryRegistry (build) y LiveryGenerate (comando). Los fuentes tras
//  `--usages` no declaran nada: solo se cuentan en el reporte de cada @Bridge. Con `--verify`,
//  el módulo ya tiene el archivo generado entre sus fuentes: no se escribe otro (sería un
//  duplicado), solo se comprueba que esté al día y se avisa si no.
//

import Foundation
import LiveryRegistryCore

let arguments = Array(CommandLine.arguments.dropFirst())
guard let outputPath = arguments.first else {
    FileHandle.standardError.write(Data("uso: livery-registry <salida.swift> <fuentes.swift…>\n".utf8))
    exit(2)
}

var sources: [RegistryGenerator.Source] = []
var usages: [RegistryGenerator.Source] = []
var verifyPath: String?
var mode = "sources"
var remaining = Array(arguments.dropFirst())
while !remaining.isEmpty {
    let path = remaining.removeFirst()
    switch path {
    case "--usages": mode = "usages"
    case "--verify": verifyPath = remaining.isEmpty ? nil : remaining.removeFirst()
    default:
        guard let text = try? String(contentsOfFile: path, encoding: .utf8) else { continue }
        let source = RegistryGenerator.Source(path: path, text: text)
        if mode == "usages" { usages.append(source) } else { sources.append(source) }
    }
}

let output = RegistryGenerator().generate(sources: sources, usages: usages)
var diagnostics = output.diagnostics
var contents = output.code

if let verifyPath {
    let existing = (try? String(contentsOfFile: verifyPath, encoding: .utf8)) ?? ""
    if output.isUpToDate(comparedTo: existing) {
        contents = "// \(RegistryGenerator.fileName) vive en Sources/…/\(RegistryGenerator.generatedDirectory) y está al día.\n"
    } else {
        diagnostics.append(.init(path: verifyPath, line: 1, column: 1, severity: .error,
            message: "\(RegistryGenerator.fileName) está desactualizado respecto a los @Roles, @Theme y @Bridge del módulo. Ejecuta `swift package livery-generate` (o el comando LiveryGenerate desde Xcode) y vuelve a compilar."))
        contents = "// \(RegistryGenerator.fileName) desactualizado: regenera con `swift package livery-generate`.\n"
    }
}

for diagnostic in diagnostics {
    FileHandle.standardError.write(Data((diagnostic.description + "\n").utf8))
}
do {
    try FileManager.default.createDirectory(atPath: (outputPath as NSString).deletingLastPathComponent, withIntermediateDirectories: true)
    try contents.write(toFile: outputPath, atomically: true, encoding: .utf8)
} catch {
    FileHandle.standardError.write(Data("livery-registry: no se pudo escribir \(outputPath): \(error)\n".utf8))
    exit(1)
}
exit(diagnostics.contains { $0.severity == .error } ? 1 : 0)
