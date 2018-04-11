// TODO: `location` values are read incorrectly when the file path has spaces

#if os(Linux) || os(FreeBSD)
    import Glibc
#else
    import Darwin
#endif

func main() {
    
    // Get the file path
    guard CommandLine.arguments.count >= 2 else {
        let commandPath = CommandLine.arguments[0]
        let commandName = commandPath.split(separator: "/").last!
        print("Usage: \(commandName) <filePath>")
        return
    }
    let testFilePath = CommandLine.arguments[1]
    
    // Call the swift compiler
    let command = ["swiftc", "-dump-ast", testFilePath]
    let commandResult = Shell.runShellCommand(command)
    
    // Ensure the compiler terminated successfully
    guard commandResult.status == 0 else {
        print("Error parsing and typechecking input files. Swift compiler says:\n\(commandResult.standardError)")
        exit(commandResult.status)
    }
    
    // The compiler has dumped the ast to stderr
    var commandOutput = commandResult.standardError
    
//    print(commandOutput)
    
    // Trim any warnings swift may have printed before the actual AST dump
    commandOutput =~ "^((.*)\n)*\\(source\\_file\n" => "\\(source\\_file\n"
    
    // Parse the AST into Gryphon data structures
    print("-- Gryphon AST --")
    let ast = GRYAst(fileContents: commandOutput)
    ast.prettyPrint()
    print()
    
    // Translate the AST to Kotlin
    print("-- Kotlin --")
    let kotlin = GRYKotlinTranslator().translateAST(ast)
    print(kotlin)
    print()
}

main()
