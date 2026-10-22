import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct LiveryPlugin: CompilerPlugin {
    let providingMacros: [any Macro.Type] = [
        RolesMacro.self,
        ThemeMacro.self,
        PrimitivesMacro.self,
        ComponentMacro.self,
        BridgeMacro.self,
    ]
}
