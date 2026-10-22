//
//  main.swift
//  livery-registry
//
//  Uso: livery-registry <salida.swift> <fuentes del módulo…> [--usages <fuentes de otros módulos…>]
//  Lo invoca el plugin LiveryRegistry; también sirve a mano para inspeccionar la salida. Los
//  fuentes tras `--usages` no declaran nada: solo se cuentan en el reporte de cada @Bridge.
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
var collectingUsages = false
for path in arguments.dropFirst() {
    if path == "--usages" { collectingUsages = true; continue }
    if let text = try? String(contentsOfFile: path, encoding: .utf8) {
        let source = RegistryGenerator.Source(path: path, text: text)
        if collectingUsages { usages.append(source) } else { sources.append(source) }
    }
}

let output = RegistryGenerator().generate(sources: sources, usages: usages)
for diagnostic in output.diagnostics {
    FileHandle.standardError.write(Data((diagnostic.description + "\n").utf8))
}
do {
    try FileManager.default.createDirectory(atPath: (outputPath as NSString).deletingLastPathComponent, withIntermediateDirectories: true)
    try output.code.write(toFile: outputPath, atomically: true, encoding: .utf8)
} catch {
    FileHandle.standardError.write(Data("livery-registry: no se pudo escribir \(outputPath): \(error)\n".utf8))
    exit(1)
}
exit(output.hasErrors ? 1 : 0)
