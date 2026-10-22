//
//  main.swift
//  livery-registry
//
//  Uso: livery-registry <salida.swift> <fuente1.swift> <fuente2.swift> …
//  Lo invoca el plugin LiveryRegistry; también sirve a mano para inspeccionar la salida.
//

import Foundation
import LiveryRegistryCore

let arguments = Array(CommandLine.arguments.dropFirst())
guard let outputPath = arguments.first else {
    FileHandle.standardError.write(Data("uso: livery-registry <salida.swift> <fuentes.swift…>\n".utf8))
    exit(2)
}

var sources: [RegistryGenerator.Source] = []
for path in arguments.dropFirst() {
    if let text = try? String(contentsOfFile: path, encoding: .utf8) {
        sources.append(RegistryGenerator.Source(path: path, text: text))
    }
}

let output = RegistryGenerator().generate(sources: sources)
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
