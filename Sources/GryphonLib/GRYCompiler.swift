import Foundation

public enum GRYCompiler {
	public static func compileAndRun(fileAt filePath: String) -> GRYShell.CommandOutput {
		_ = compile(fileAt: filePath)
		
		let arguments = ["java", "-jar", "kotlin.jar"]
		let commandResult = GRYShell.runShellCommand(arguments, fromFolder: Utils.buildFolder)
		
		return commandResult
	}
	
	@discardableResult
	public static func compile(fileAt filePath: String) -> String {
		let kotlinCode = generateKotlinCode(forFileAt: filePath)
		let kotlinFileName = Utils.trimmedFileName(fromPath: filePath) + ".kt"
		let kotlinFilePath = Utils.createFile(named: kotlinFileName,
											  inDirectory: Utils.buildFolder,
											  containing: kotlinCode)
		
		// Call the kotlin compiler
		let arguments = ["-include-runtime",  "-d", Utils.buildFolder + "/kotlin.jar", kotlinFilePath]
		let commandResult = GRYShell.runShellCommand("/usr/local/bin/kotlinc", arguments: arguments)
		
		// Ensure the compiler terminated successfully
		guard commandResult.status == 0 else {
			fatalError("Compiling kotlin files. Kotlin compiler says:\n\(commandResult.standardError)")
		}
		
		return kotlinFilePath
	}
	
	public static func generateKotlinCode(forFileAt filePath: String) -> String {
		let ast = generateAST(forFileAt: filePath)
		let kotlin = GRYKotlinTranslator().translateAST(ast)
		return kotlin
	}
	
	public static func generateAstJson(forFileAt filePath: String) -> String? {
		let ast = generateAST(forFileAt: filePath)
		let jsonData = try! JSONEncoder().encode(ast)

		guard let rawJsonString = String(data: jsonData, encoding: .utf8) else { return nil }

		let processedJsonString = Utils.insertPlaceholders(in: rawJsonString, forFilePath: filePath)
		return processedJsonString
	}
	
	public static func generateAST(forFileAt filePath: String) -> GRYAst {
		let astDump = getSwiftASTDump(forFileAt: filePath)
		let ast = GRYAst(fileContents: astDump)
		return ast
	}
	
	public static func getSwiftASTDump(forFileAt filePath: String) -> String {
		// Call the swift compiler
		let command = ["swiftc", "-dump-ast", filePath]
		let commandResult = GRYShell.runShellCommand(command)
		
		// Ensure the compiler terminated successfully
		guard commandResult.status == 0 else {
			fatalError("Error parsing and typechecking input files. Swift compiler says:\n\(commandResult.standardError)")
		}
		
		// The compiler has dumped the ast to stderr
		var astDump = commandResult.standardError
		
		// Trim any warnings swift may have printed before the actual AST dump
		astDump =~ "^((.*)\n)*\\(source\\_file\n" => "\\(source\\_file\n"
		
		return astDump
	}
}
