//
//  Importer.swift
//  LiveryScaffold
//
//  `theme import`: convierte un archivo W3C Design Tokens (de Penpot, Figma/Tokens Studio) en
//  primitivos Swift. Es un andamio de una sola vez: los colores pasan a una paleta y las medidas
//  a constantes; luego alguien los nombra como roles. Solo transforma JSON a texto, así que vive
//  en la CLI y no necesita el módulo del usuario.
//

import Foundation

public enum Importer {
    public struct Result {
        public var swift: String
        public var colors: Int
        public var dimensions: Int
    }

    public enum Failure: Error, CustomStringConvertible {
        case notReadable(String)
        case notJSON(String)
        public var description: String {
            switch self {
            case .notReadable(let path): "No se pudo leer \(path)."
            case .notJSON(let path): "\(path) no es un archivo W3C Design Tokens válido (JSON)."
            }
        }
    }

    /// Lee un archivo de tokens y genera el Swift de los primitivos.
    public static func swift(fromFile path: String, enumName: String = "ImportedTokens") throws -> Result {
        guard let text = try? String(contentsOfFile: path, encoding: .utf8) else { throw Failure.notReadable(path) }
        guard let root = (try? JSONSerialization.jsonObject(with: Data(text.utf8))) as? [String: Any] else {
            throw Failure.notJSON(path)
        }
        return swift(from: root, enumName: enumName)
    }

    /// Genera el Swift a partir del árbol de tokens ya parseado.
    public static func swift(from root: [String: Any], enumName: String) -> Result {
        var colors: [(String, String)] = []       // (nombre, hex 0x…)
        var dimensions: [(String, Int)] = []       // (nombre, puntos)
        walk(root, prefix: "") { name, token in
            guard let type = token["$type"] as? String else { return }
            switch type {
            case "color":
                if let hex = (token["$value"] as? String).flatMap(normalizeHex) {
                    colors.append((trimGroup(name, ["color", "colors", "colour", "colours"]), hex))
                }
            case "dimension":
                if let points = (token["$value"] as? String).flatMap(points(from:)) {
                    dimensions.append((trimGroup(name, ["spacing", "space", "radius", "radii", "size", "sizes", "dimension"]), points))
                }
            default:
                break
            }
        }
        colors.sort { $0.0 < $1.0 }
        dimensions.sort { $0.0 < $1.0 }

        var lines = [
            "//",
            "//  \(enumName).swift",
            "//  Generado por `theme import` a partir de un archivo W3C Design Tokens.",
            "//  Son primitivos: nómbralos como roles en tu sistema de diseño.",
            "//",
            "",
            "import Livery",
            "",
        ]
        if !colors.isEmpty {
            lines.append("@Primitives public enum \(enumName)Colors {")
            lines += colors.map { "    public static let \(identifier($0.0)) = Color(hex: \($0.1))" }
            lines.append("}")
            lines.append("")
            lines.append("extension Color {")
            lines.append("    /// `0xRRGGBB`. Solo para la paleta importada.")
            lines.append("    init(hex: UInt32) {")
            lines.append("        self.init(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)")
            lines.append("    }")
            lines.append("}")
            lines.append("")
        }
        if !dimensions.isEmpty {
            lines.append("@Primitives public enum \(enumName)Metrics {")
            lines += dimensions.map { "    public static let \(identifier($0.0)): CGFloat = \($0.1)" }
            lines.append("}")
            lines.append("")
        }
        return Result(swift: lines.joined(separator: "\n"), colors: colors.count, dimensions: dimensions.count)
    }

    /// Recorre el árbol: un token es un objeto con `$type`; cualquier otro objeto es un grupo.
    private static func walk(_ node: [String: Any], prefix: String, found: (String, [String: Any]) -> Void) {
        for (key, value) in node {
            guard key.first != "$", let object = value as? [String: Any] else { continue }
            let name = prefix.isEmpty ? key : prefix + "_" + key
            if object["$type"] != nil {
                found(name, object)
            } else {
                walk(object, prefix: name, found: found)
            }
        }
    }

    /// Quita el segmento de grupo redundante: `color_accent` → `accent` (ya va en un enum de color).
    private static func trimGroup(_ name: String, _ groups: [String]) -> String {
        let parts = name.split(separator: "_")
        if let first = parts.first, groups.contains(String(first).lowercased()), parts.count > 1 {
            return parts.dropFirst().joined(separator: "_")
        }
        return name
    }

    /// `#4F46E5` o `#4F46E5FF` → `0x4F46E5`.
    private static func normalizeHex(_ value: String) -> String? {
        let hex = value.hasPrefix("#") ? String(value.dropFirst()) : value
        let rgb = hex.count >= 6 ? String(hex.prefix(6)) : hex
        guard rgb.count == 6, rgb.allSatisfy(\.isHexDigit) else { return nil }
        return "0x" + rgb.uppercased()
    }

    /// `16px` o `16` → 16.
    private static func points(from value: String) -> Int? {
        Int(value.replacingOccurrences(of: "px", with: "").trimmingCharacters(in: .whitespaces))
    }

    /// Un identificador Swift válido: `on-surface` → `onSurface`, `2xl` → `_2xl`.
    private static func identifier(_ name: String) -> String {
        let parts = name.split(whereSeparator: { "-_ .".contains($0) })
        var result = parts.enumerated().map { index, part in
            index == 0 ? String(part) : part.prefix(1).uppercased() + part.dropFirst()
        }.joined()
        if let first = result.first, first.isNumber { result = "_" + result }
        return result.isEmpty ? "_" : result
    }
}
