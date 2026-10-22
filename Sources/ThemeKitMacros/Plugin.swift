import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct ThemeKitPlugin: CompilerPlugin {
    let providingMacros: [any Macro.Type] = [
        RolesMacro.self,
        RoleSetMacro.self,
        ThemeMacro.self,
        PrimitivesMacro.self,
    ]
}
