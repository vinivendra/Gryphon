import Foundation

public enum GRYCompiler {
	public static func compileAndRun(fileAt filePath: String) -> GRYShell.CommandOutput {
		_ = compile(fileAt: filePath)
		
		log?("Running Kotlin...")
		let arguments = ["java", "-jar", "kotlin.jar"]
		let commandResult = GRYShell.runShellCommand(arguments, fromFolder: Utils.buildFolder)
		
		return commandResult
	}
	
	@discardableResult
	public static func compile(fileAt filePath: String) -> String {
		let kotlinCode = generateKotlinCode(forFileAt: filePath)
		
		log?("Compiling Kotlin...")
		let fileName = URL(fileURLWithPath: filePath).deletingPathExtension().lastPathComponent
		let kotlinFilePath = Utils.createFile(named: fileName + ".kt",
											  inDirectory: Utils.buildFolder,
											  containing: kotlinCode)
		
		// Call the kotlin compiler
		let arguments = ["-include-runtime",  "-d", Utils.buildFolder + "/kotlin.jar", kotlinFilePath]
		let commandResult = GRYShell.runShellCommand("/usr/local/bin/kotlinc", arguments: arguments)
		
		// Ensure the compiler terminated successfully
		guard commandResult.standardError.isEmpty else {
			fatalError("Compiling kotlin files. Kotlin compiler says:\n\(commandResult.standardError)")
		}
		
		return kotlinFilePath
	}
	
	public static func generateKotlinCode(forFileAt filePath: String) -> String {
		let ast = generateAST(forFileAt: filePath)
		
		log?("Translating AST to Kotlin...")
		let kotlin = GRYKotlinTranslator().translateAST(ast)
		return kotlin
	}
	
	public static func updateAstJson(forFileAt filePath: String) {
		let ast = generateAST(forFileAt: filePath)

		log?("Writing AST JSON...")
		let jsonFilePath = Utils.changeExtension(of: filePath, to: "json")
		ast.writeAsJSON(toFile: jsonFilePath)
	}
	
	public static func generateAST(forFileAt filePath: String) -> GRYAst {
		let astDumpFilePath = Utils.changeExtension(of: filePath, to: "ast")
		
		log?("Building GRYAst...")
		let ast = GRYAst(astFile: astDumpFilePath)
		return ast
	}
	
	public static func getSwiftASTDump(forFileAt filePath: String) -> String {
		log?("Getting swift AST dump...")
		// TODO: Check if the ast file is outdated
		let astDumpFilePath = Utils.changeExtension(of: filePath, to: "ast")
		return try! String(contentsOfFile: astDumpFilePath)
	}
}
