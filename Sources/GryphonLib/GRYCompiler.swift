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

	public static func compileAndRun(fileAt filePath: String) throws -> KotlinCompilationResult {
		let compilationResult = try compile(fileAt: filePath)
		guard case .success(_) = compilationResult else {
			return compilationResult
		}

		print("\t- Running Kotlin...")
		let arguments = ["java", "-jar", "kotlin.jar"]
		let commandResult = GRYShell.runShellCommand(arguments, fromFolder: GRYUtils.buildFolder)

		guard let result = commandResult else {
			return .failure(errorMessage: "\t\t- Java running timed out.")
		}

		return .success(commandOutput: result)
	}

	public static func compile(fileAt filePath: String) throws -> KotlinCompilationResult {
		let kotlinCode = try generateKotlinCode(forFileAt: filePath)

		print("\t- Compiling Kotlin...")
		let fileName = URL(fileURLWithPath: filePath).deletingPathExtension().lastPathComponent
		let kotlinFilePath = GRYUtils.createFile(
			named: fileName + .kt,
			inDirectory: GRYUtils.buildFolder,
			containing: kotlinCode)

		// Call the kotlin compiler
		let arguments =
			["-include-runtime", "-d", GRYUtils.buildFolder + "/kotlin.jar", kotlinFilePath]
		let commandResult = GRYShell.runShellCommand(kotlinCompilerPath, arguments: arguments)

		// Ensure the compiler terminated successfully
		guard let result = commandResult else {
			return .failure(errorMessage: "\t\t- Kotlin compiler timed out.")
		}
		guard result.status == 0 else {
			return .failure(errorMessage:
				"\t\t- Error compiling kotlin files. Kotlin compiler says:\n" +
				"\(result.standardError)")
		}

		return .success(commandOutput: result)
	}

	public static func generateKotlinCode(forFileAt filePath: String) throws -> String {
		let ast = try generateGryphonAst(forFileAt: filePath)

		print("\t- Translating AST to Kotlin...")
		return GRYKotlinTranslator().translateAST(ast)
	}

	public static func generateGryphonAst(forFileAt filePath: String) throws -> GRYSourceFile {
		let swiftAst = generateSwiftAST(forFileAt: filePath)
		print("\t- Translating Swift Ast to Gryphon Ast...")
		let ast = try GRYSwift4_1Translator().translateAST(swiftAst)
		return ast
	}

	public static func processExternalSwiftAST(_ filePath: String) -> GRYSwiftAst {
		let astFilePath = GRYUtils.changeExtension(of: filePath, to: .swiftAstDump)

		print("\t- Building GRYSwiftAst from external AST...")
		let ast = GRYSwiftAst(astFile: astFilePath)

		let jsonFilePath = GRYUtils.changeExtension(of: filePath, to: .grySwiftAstJson)
		let jsonFileWasJustCreated = GRYUtils.createFileIfNeeded(at: jsonFilePath, containing: "")
		let jsonIsOutdated =
			jsonFileWasJustCreated || GRYUtils.file(astFilePath, wasModifiedLaterThan: jsonFilePath)
		if jsonIsOutdated {
			print("\t\t- Updating \(jsonFilePath)...")
			ast.writeAsJSON(toFile: jsonFilePath)
		}

		return ast
	}

	public static func generateSwiftAST(forFileAt filePath: String) -> GRYSwiftAst {
		let astDumpFilePath = GRYUtils.changeExtension(of: filePath, to: .swiftAstDump)

		print("\t- Building GRYSwiftAst...")
		let ast = GRYSwiftAst(astFile: astDumpFilePath)
		return ast
	}

	public static func getSwiftASTDump(forFileAt filePath: String) -> String {
		print("\t- Getting swift AST dump...")
		let astDumpFilePath = GRYUtils.changeExtension(of: filePath, to: .swiftAstDump)
		return try! String(contentsOfFile: astDumpFilePath)
	}
}
