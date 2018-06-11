/*
* Copyright 2018 Vinícius Jorge Vendramini
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

import Foundation

public enum GRYCompiler {

	#if os(Linux) || os(FreeBSD)
	static let kotlinCompilerPath = "/opt/kotlinc/bin/kotlinc"
	#else
	static let kotlinCompilerPath = "/usr/local/bin/kotlinc"
	#endif

	public enum KotlinCompilationResult {
		case success(commandOutput: GRYShell.CommandOutput)
		case failure(errorMessage: String)
	}

	public static func compileAndRun(fileAt filePath: String) -> KotlinCompilationResult {
		let compilationResult = compile(fileAt: filePath)
		guard case .success(_) = compilationResult else { return compilationResult }

		log?("Running Kotlin...")
		let arguments = ["java", "-jar", "kotlin.jar"]
		let commandResult = GRYShell.runShellCommand(arguments, fromFolder: GRYUtils.buildFolder)

		guard let result = commandResult else {
			return .failure(errorMessage: "Java running timed out.")
		}

		return .success(commandOutput: result)
	}

	public static func compile(fileAt filePath: String) -> KotlinCompilationResult {
		let kotlinCode = generateKotlinCode(forFileAt: filePath)

		log?("Compiling Kotlin...")
		let fileName = URL(fileURLWithPath: filePath).deletingPathExtension().lastPathComponent
		let kotlinFilePath = GRYUtils.createFile(named: fileName + ".kt",
											  inDirectory: GRYUtils.buildFolder,
											  containing: kotlinCode)

		// Call the kotlin compiler
		let arguments = ["-include-runtime", "-d", GRYUtils.buildFolder + "/kotlin.jar", kotlinFilePath]
		let commandResult = GRYShell.runShellCommand(kotlinCompilerPath, arguments: arguments)

		// Ensure the compiler terminated successfully
		guard let result = commandResult else {
			return .failure(errorMessage: "Kotlin compiler timed out.")
		}
		guard result.status == 0 else {
			return .failure(errorMessage: "Error compiling kotlin files. Kotlin compiler says:\n\(result.standardError)")
		}

		return .success(commandOutput: result)
	}

	public static func generateKotlinCode(forFileAt filePath: String) -> String {
		let jsonFile = GRYUtils.changeExtension(of: filePath, to: "json")
		let ast = GRYAst.initialize(fromJsonInFile: jsonFile)

		log?("Translating AST to Kotlin...")
		let kotlinTranslator = GRYKotlinTranslator()
		let kotlinCode = kotlinTranslator.translateAST(ast)
		print("======\n\(kotlinTranslator.diagnostics)\n======\n")
		return kotlinCode
	}

	public static func processExternalAST(_ filePath: String) -> GRYAst {
		let astFilePath = GRYUtils.changeExtension(of: filePath, to: "ast")

		log?("Building GRYAst from external AST...")
		let ast = GRYAst(astFile: astFilePath)

		let jsonFilePath = GRYUtils.changeExtension(of: filePath, to: "json")
		let jsonFileWasJustCreated = GRYUtils.createFileIfNeeded(at: jsonFilePath, containing: "")
		let jsonIsOutdated = jsonFileWasJustCreated || GRYUtils.file(astFilePath, wasModifiedLaterThan: jsonFilePath)
		if jsonIsOutdated {
			log?("\tUpdating \(jsonFilePath)...")
			ast.writeAsJSON(toFile: jsonFilePath)
		}

		return ast
	}

	public static func generateAST(forFileAt filePath: String) -> GRYAst {
		let astDumpFilePath = GRYUtils.changeExtension(of: filePath, to: "ast")

		log?("Building GRYAst...")
		let ast = GRYAst(astFile: astDumpFilePath)
		return ast
	}

	public static func getSwiftASTDump(forFileAt filePath: String) -> String {
		log?("Getting swift AST dump...")
		let astDumpFilePath = GRYUtils.changeExtension(of: filePath, to: "ast")
		return try! String(contentsOfFile: astDumpFilePath)
	}
}
