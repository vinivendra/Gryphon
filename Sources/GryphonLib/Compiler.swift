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

public enum Compiler {

	#if os(Linux) || os(FreeBSD)
	static let kotlinCompilerPath = "/opt/kotlinc/bin/kotlinc"
	#else
	static let kotlinCompilerPath = "/usr/local/bin/kotlinc"
	#endif

	public enum KotlinCompilationResult: CustomStringConvertible {
		case success(commandOutput: Shell.CommandOutput)
		case failure(errorMessage: String)

		public var description: String {
			switch self {
			case let .success(commandOutput: commandOutput):
				return "Kotlin compilation result:\n" +
					"- Output:\n" +
					commandOutput.standardOutput +
					"- Error:\n" +
					commandOutput.standardError +
					"- Status: \(commandOutput.status)\n"
			case let .failure(errorMessage: errorMessage):
				return "Kotlin compilation failed: \(errorMessage)"
			}
		}
	}

	public static func compileAndRun(filesAt filePaths: [String]) throws -> KotlinCompilationResult
	{
		let compilationResult = try compile(filesAt: filePaths)

		guard case .success = compilationResult else {
			return compilationResult
		}

		log?("\t- Running Kotlin...")
		let arguments = ["java", "-jar", "kotlin.jar"]
		let commandResult = Shell.runShellCommand(arguments, fromFolder: Utilities.buildFolder)

		guard let result = commandResult else {
			return .failure(errorMessage: "\t\t- Java running timed out.")
		}

		return .success(commandOutput: result)
	}

	public static func compile(filesAt filePaths: [String]) throws -> KotlinCompilationResult {
		let kotlinFilePaths =
			try generateKotlinCode(forFilesAt: filePaths, outputFolder: Utilities.buildFolder)

		log?("\t- Compiling Kotlin...")

		// Call the kotlin compiler
		let arguments =
			["-include-runtime", "-d", Utilities.buildFolder + "/kotlin.jar"] + kotlinFilePaths
		let commandResult = Shell.runShellCommand(kotlinCompilerPath, arguments: arguments)

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

	/// Transpiles the given files and writes the output to files in the given outputFolder. Returns
	/// the paths to the output files.
	@discardableResult
	public static func generateKotlinCode(
		forFilesAt filePaths: [String], outputFolder: String) throws -> [String]
	{
		let kotlinCodes = try generateKotlinCode(forFilesAt: filePaths)

		var outputFiles: [String] = []
		for (filePath, kotlinCode) in zip(filePaths, kotlinCodes) {
			let fileName = URL(fileURLWithPath: filePath).deletingPathExtension().lastPathComponent
			let outputFile = Utilities.createFile(
				named: fileName + .kt,
				inDirectory: outputFolder,
				containing: kotlinCode)
			outputFiles.append(outputFile)
		}

		return outputFiles
	}

	public static func generateKotlinCode(forFilesAt filePaths: [String]) throws -> [String] {
		let asts = try generateGryphonASTAndRunPasses(forFilesAt: filePaths)
		log?("\t- Translating AST to Kotlin...")
		let kotlinCodes = try asts.map { try KotlinTranslator().translateAST($0) }
		return kotlinCodes
	}

	public static func generateGryphonASTAndRunPasses(forFilesAt filePaths: [String]) throws
		-> [GryphonAST]
	{
		var asts = try filePaths.map { try generateGryphonAST(forFileAt: $0) }
		log?("\t- Translating Swift AST to Gryphon AST...")
		asts = asts.map { TranspilationPass.runFirstRoundOfPasses(on: $0) }
		asts = asts.map { TranspilationPass.runSecondRoundOfPasses(on: $0) }
		return asts
	}

	public static func generateGryphonAST(forFileAt filePath: String) throws -> GryphonAST {
		let swiftAST = try generateSwiftAST(forFileAt: filePath)
		log?("\t- Translating Swift AST to Gryphon AST...")
		let ast = try SwiftTranslator().translateAST(swiftAST)
		return ast
	}

	public static func generateSwiftAST(forFileAt filePath: String) throws -> SwiftAST {
		let astDumpFilePath = Utilities.changeExtension(of: filePath, to: .swiftASTDump)

		log?("\t- Building SwiftAST...")
		let ast = try ASTDumpDecoder.decode(file: astDumpFilePath)
		return ast
	}

	public static func getSwiftASTDump(forFileAt filePath: String) throws -> String {
		log?("\t- Getting swift AST dump...")
		let astDumpFilePath = Utilities.changeExtension(of: filePath, to: .swiftASTDump)
		return try String(contentsOfFile: astDumpFilePath)
	}

	//
	public static var shouldStopAtFirstError = false

	public private(set) static var errors = [Error]()
	public private(set) static var warnings = [String]()

	public static func handleError(_ error: Error) throws {
		if Compiler.shouldStopAtFirstError {
			throw error
		}
		else {
			Compiler.errors.append(error)
		}
	}

	public static func handleWarning(_ warning: String) {
		Compiler.warnings.append(warning)
	}

	public static func printErrorsAndWarnings() {
		if !errors.isEmpty {
			print("Errors:")
			for error in errors {
				print("🚨 \(error)")
			}
		}

		if !warnings.isEmpty {
			print("Warnings:")
			for warning in warnings {
				print("⚠️ \(warning)")
			}
		}

		if hasErrorsOrWarnings() {
			print("Total: \(errors.count) errors and \(warnings.count) warnings.")
		}
	}

	public static func hasErrorsOrWarnings() -> Bool {
		return !errors.isEmpty || !warnings.isEmpty
	}

	public static func clearErrorsAndWarnings() {
		errors = []
		warnings = []
	}

	public static func printErrorStatistics() {
		let swiftASTDumpErrors = errors.compactMap { $0 as? SwiftTranslatorError }
		if !swiftASTDumpErrors.isEmpty {
			print("Swift AST translator failed to translate:")

			let swiftASTDumpHistogram = swiftASTDumpErrors.group { $0.astName }
			for (astName, errorArray) in
				swiftASTDumpHistogram.sorted(by: { $0.value.count > $1.value.count })
			{
				print("- \(errorArray.count) \(astName)s")
			}
		}

		let kotlinTranslatorErrors = errors.compactMap { $0 as? KotlinTranslatorError }
		if !kotlinTranslatorErrors.isEmpty {
			print("Kotlin translator failed to translate:")

			let kotlinTranslatorHistogram = kotlinTranslatorErrors.group { $0.astName }
			for (astName, errorArray) in
				kotlinTranslatorHistogram.sorted(by: { $0.value.count > $1.value.count })
			{
				print("- \(errorArray.count) \(astName)s")
			}
		}
	}

	//
	private static var log: ((String) -> ())? = { print($0) }

	public static var shouldLogProgress = false {
		didSet {
			if shouldLogProgress {
				log = { print($0) }
			}
			else {
				log = nil
			}
		}
	}
}
