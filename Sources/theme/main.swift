//
//  main.swift
//  theme
//
//  La CLI de Livery.
//
//      theme init [Nombre] [--at <carpeta>] [--livery <url|ruta>] [--branch <rama>]
//
//  Genera un paquete Swift con la estructura de un sistema de diseño: primitivos en un módulo
//  aparte, roles y temas con el plugin activo, y un test. Por defecto se llama DesignSystem y
//  se crea en la carpeta actual.
//

import Foundation
import LiveryScaffold

let usage = """
    uso:
      theme init [Nombre] [--at <carpeta>] [--livery <url|ruta>] [--branch <rama>]
      theme import <tokens.json> [--name <Nombre>] [--out <archivo.swift>]

    Genera un paquete Swift con la estructura de un sistema de diseño construido con Livery:
      <Nombre>Primitives   la paleta y las medidas crudas (solo <Nombre> lo importa)
      <Nombre>             roles y temas, con el plugin LiveryRegistry activo
      <Nombre>Tests        el tema resuelve lo que declara

    opciones:
      --at <carpeta>        dónde crear la carpeta <Nombre> (por defecto, la actual)
      --livery <url|ruta>   de dónde tomar Livery (por defecto, GitHub); una ruta local la usa tal cual
      --branch <rama>       rama de Livery cuando es una URL (por defecto, master)

    `theme import` convierte un archivo W3C Design Tokens (Penpot, Figma/Tokens Studio) en
    primitivos Swift (@Primitives). Es un andamio: luego nombras los valores como roles.
    """

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("theme: \(message)\n".utf8))
    exit(1)
}

var arguments = Array(CommandLine.arguments.dropFirst())
guard let command = arguments.first else {
    print(usage)
    exit(2)
}
arguments.removeFirst()

switch command {
case "init":
    var name = "DesignSystem"
    var directory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    var liveryLocation: String?
    var branch = "master"

    var iterator = arguments.makeIterator()
    while let argument = iterator.next() {
        switch argument {
        case "--at":
            guard let value = iterator.next() else { fail("--at necesita una carpeta") }
            directory = URL(fileURLWithPath: value)
        case "--livery":
            guard let value = iterator.next() else { fail("--livery necesita una URL o una ruta") }
            liveryLocation = value
        case "--branch":
            guard let value = iterator.next() else { fail("--branch necesita una rama") }
            branch = value
        case let value where value.hasPrefix("-"):
            fail("opción desconocida: \(value)\n\(usage)")
        default:
            name = argument
        }
    }

    guard Scaffold.isValidName(name) else { fail(ScaffoldError.invalidName(name).description) }

    let dependency: Scaffold.Dependency
    if let liveryLocation {
        let isURL = liveryLocation.contains("://") || liveryLocation.hasPrefix("git@")
        dependency = isURL ? .url(liveryLocation, branch: branch) : .path(liveryLocation)
    } else {
        dependency = .url("https://github.com/fsaldivar-dev/Livery.git", branch: branch)
    }

    let scaffold = Scaffold(name: name, livery: dependency)
    do {
        let root = try scaffold.write(into: directory)
        print("Creado \(root.path())")
        for file in scaffold.files {
            print("  \(file.path)")
        }
        print()
        print(scaffold.nextSteps)
    } catch {
        fail("\(error)")
    }

case "import":
    guard let file = arguments.first, !file.hasPrefix("-") else { fail("import necesita un archivo de tokens.\n\(usage)") }
    var name = "ImportedTokens"
    var output: String?
    var iterator = arguments.dropFirst().makeIterator()
    while let argument = iterator.next() {
        switch argument {
        case "--name": name = iterator.next() ?? name
        case "--out": output = iterator.next()
        default: fail("opción desconocida: \(argument)\n\(usage)")
        }
    }
    guard Scaffold.isValidName(name) else { fail(ScaffoldError.invalidName(name).description) }
    do {
        let result = try Importer.swift(fromFile: file, enumName: name)
        let path = output ?? "\(name).swift"
        try result.swift.write(toFile: path, atomically: true, encoding: .utf8)
        print("Escrito \(path): \(result.colors) colores, \(result.dimensions) medidas.")
        print("Siguiente paso: nombra estos primitivos como roles (@Roles) y resuélvelos en tu tema.")
    } catch {
        fail("\(error)")
    }

case "--help", "-h", "help":
    print(usage)

default:
    fail("comando desconocido: \(command)\n\(usage)")
}
