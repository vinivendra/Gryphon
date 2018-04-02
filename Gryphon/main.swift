// TODO: Move test.swift into the project directory, change absolute paths to be relative, change the project's location

import Darwin

func main() {
	
	// Get the file path
	let sourceRoot = CommandLine.arguments[1]
	let testFilePath = sourceRoot + "/test.swift"
	
	// Call the swift compiler
	let command = "swiftc -dump-ast \(testFilePath)"
	let commandResult = Shell.runShellCommand(command)
	
	// Ensure the compiler terminated successfully
	guard commandResult.status == 0 else {
		print("Error parsing and typechecking input files. Swift compiler says:\n\(commandResult.standardError)")
		exit(commandResult.status)
	}

	// The compiler has dumped the ast to stderr
	var commandOutput = commandResult.standardError
	
	// Trim any warnings swift may have printed before the actual AST dump
	commandOutput =~ "^((.*)\n)*\\(source\\_file\n" => "\\(source\\_file\n"
	
	// Parse the AST into Gryphon data structures
	print("-- Gryphon AST --")
	let ast = GRYAst(fileContents: commandOutput)
	ast.prettyPrint()
	print()
}

main()
