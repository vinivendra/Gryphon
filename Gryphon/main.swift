// TODO: Automatically calculate -dump-ast from terminal output
// TODO: Move test.swift into the project directory, change absolute paths to be relative, change the project's location

func main() {
	let filePath = "/Users/vini/Desktop/test.swift"
	let command = "swiftc -dump-ast \(filePath)"
	let commandResult = Shell.runShellCommand(command)
	var commandOutput = commandResult.error
	commandOutput =~ "^((.*)\n)*\\(source\\_file\n" => "\\(source\\_file\n"
	
	print("-- Gryphon AST --")
	let ast = GRYAst(fileContents: commandOutput)
	ast.prettyPrint()
	
	print()
}

main()
