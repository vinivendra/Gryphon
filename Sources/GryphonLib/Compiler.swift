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

public class Compiler {
	static let kotlinCompilerPath = (OS.osName == "Linux") ?
		"/opt/kotlinc/bin/kotlinc" :
		"/usr/local/bin/kotlinc"

	//
	public private(set) static var log: ((String) -> ()) = { print($0) }

	public static func shouldLogProgress(if value: Bool) {
		if value {
			log = { print($0) }
		}
		else {
			log = { _ in }
		}
	}
}

extension Compiler { // kotlin: ignore

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

	public static func runCompiledProgram(fromFolder outputFolder: String)
		throws -> KotlinCompilationResult
	{
		log("\t- Running Kotlin...")
		let arguments = ["java", "-jar", "kotlin.jar"]
		let commandResult = Shell.runShellCommand(arguments, fromFolder: outputFolder)

		guard let result = commandResult else {
			return .failure(errorMessage: "\t\t- Java running timed out.")
		}

		return .success(commandOutput: result)
	}

	public static func compile(kotlinFiles filePaths: [String], outputFolder: String)
		throws -> KotlinCompilationResult
	{
		log("\t- Compiling Kotlin...")

		// Call the kotlin compiler
		let arguments = ["-include-runtime", "-d", outputFolder + "/kotlin.jar"] + filePaths
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

	public static func generateKotlinCode(fromGryphonASTs asts: [GryphonAST]) throws -> [String] {
		log("\t- Translating ASTs to Kotlin...")
		let kotlinCodes = try asts.map { try KotlinTranslator().translateAST($0) }
		return kotlinCodes
	}

	public static func generateGryphonASTs(fromGryphonRawASTs asts: [GryphonAST]) throws
		-> [GryphonAST]
	{
		var asts = asts
		log("\t- Translating Swift ASTs to Gryphon ASTs...")
		try Utilities.updateLibraryFiles()
		asts = asts.map { TranspilationPass.runFirstRoundOfPasses(on: $0) }
		asts = asts.map { TranspilationPass.runSecondRoundOfPasses(on: $0) }
		return asts
	}

	public static func generateGryphonRawASTs(fromSwiftASTs swiftASTs: [SwiftAST])
		throws -> [GryphonAST]
	{
		let translateAsMainFile = (swiftASTs.count == 1)

		log("\t- Translating Swift ASTs to Gryphon ASTs...")
		let gryphonASTs = try swiftASTs.map {
			try SwiftTranslator().translateAST($0, asMainFile: translateAsMainFile)
		}

		return gryphonASTs
	}

	public static func generateSwiftAST(fromASTDump astDump: String) throws -> SwiftAST {
		log("\t- Building SwiftAST...")
		let ast = try ASTDumpDecoder(encodedString: astDump).decode()
		return ast
	}

	//
	public static func runCompiledProgram(
		fromASTDumpFiles inputFiles: [String], fromFolder outputFolder: String = OS.buildFolder)
		throws -> KotlinCompilationResult
	{
		let compilationResult = try compile(ASTDumpFiles: inputFiles, outputFolder: outputFolder)
		guard case .success = compilationResult else {
			return compilationResult
		}
		return try runCompiledProgram(fromFolder: outputFolder)
	}

	public static func compile(
		ASTDumpFiles inputFiles: [String], outputFolder: String = OS.buildFolder)
		throws -> KotlinCompilationResult
	{
		let kotlinCodes = try generateKotlinCode(fromASTDumpFiles: inputFiles)
		// Write kotlin files to the output folder
		let kotlinFilePaths = zip(inputFiles, kotlinCodes).map { tuple -> String in
			let inputFile = tuple.0
			let kotlinCode = tuple.1
			let inputFileName = inputFile.split(withStringSeparator: "/").last!
			let kotlinFileName = Utilities.changeExtension(of: inputFileName, to: .kt)
			let folderWithSlash = outputFolder.hasSuffix("/") ? outputFolder : (outputFolder + "/")
			let kotlinFilePath = folderWithSlash + kotlinFileName
			Utilities.createFile(atPath: kotlinFilePath, containing: kotlinCode)
			return kotlinFilePath
		}
		return try compile(kotlinFiles: kotlinFilePaths, outputFolder: outputFolder)
	}

	public static func generateKotlinCode(fromASTDumpFiles inputFiles: [String]) throws -> [String]
	{
		let asts = try generateGryphonASTs(fromASTDumpFiles: inputFiles)
		return try generateKotlinCode(fromGryphonASTs: asts)
	}

	public static func generateGryphonASTs(fromASTDumpFiles inputFiles: [String])
		throws -> [GryphonAST]
	{
		let rawASTs = try generateGryphonRawASTs(fromASTDumpFiles: inputFiles)
		return try generateGryphonASTs(fromGryphonRawASTs: rawASTs)
	}

	public static func generateGryphonRawASTs(fromASTDumpFiles inputFiles: [String])
		throws -> [GryphonAST]
	{
		let asts = try inputFiles.map { try generateSwiftAST(fromASTDumpFile: $0) }
		return try generateGryphonRawASTs(fromSwiftASTs: asts)
	}

	public static func generateSwiftAST(fromASTDumpFile inputFile: String) throws -> SwiftAST {
		let astDump = try Utilities.readFile(inputFile)
		return try generateSwiftAST(fromASTDump: astDump)
	}

	//
	public static var shouldStopAtFirstError = false

	public private(set) static var errors = [Error]()
	public private(set) static var warnings = [String]()

	internal static func handleError(_ error: Error) throws {
		if Compiler.shouldStopAtFirstError {
			throw error
		}
		else {
			Compiler.errors.append(error)
		}
	}

	internal static func handleWarning(
		file: String = #file,
		line: Int = #line,
		function: String = #function,
		message: String,
		details: String = "",
		sourceFile: SourceFile?,
		sourceFileRange: SourceFileRange?)
	{
		Compiler.warnings.append(
			Compiler.createErrorOrWarningMessage(
				file: file,
				line: line,
				function: function,
				message: message,
				details: details,
				sourceFile: sourceFile,
				sourceFileRange: sourceFileRange,
				isError: false))
	}

	public static func printErrorsAndWarnings() {
		if !errors.isEmpty {
			print("Errors:")
			for error in errors {
				print(error)
			}
		}

		if !warnings.isEmpty {
			print("Warnings:")
			for warning in warnings {
				print(warning)
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
		print("Errors: \(Compiler.errors.count). Warnings: \(Compiler.warnings.count).")

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

	static func createErrorOrWarningMessage(
		file: String = #file,
		line: Int = #line,
		function: String = #function,
		message: String,
		details: String,
		sourceFile: SourceFile?,
		sourceFileRange: SourceFileRange?,
		isError: Bool = true) -> String
	{
		let throwingFileName = file.split(separator: "/").last!.split(separator: ".").first!

		let errorOrWarning = isError ? "error" : "warning"

		if let sourceFile = sourceFile,
			let sourceFileRange = sourceFileRange
		{
			let sourceFilePath = sourceFile.path
			let sourceFileURL = URL(fileURLWithPath: sourceFilePath)
			let relativePath = sourceFileURL.relativePath

			let sourceFileString = sourceFile.getLine(sourceFileRange.lineStart) ??
				"<<Unable to get line \(sourceFileRange.lineStart) in file \(relativePath)>>"

			var underlineString = ""
			for i in 1..<sourceFileRange.columnStart {
				let sourceFileCharacter = sourceFileString[
					sourceFileString.index(sourceFileString.startIndex, offsetBy: i - 1)]
				if sourceFileCharacter == "\t" {
					underlineString += "\t"
				}
				else {
					underlineString += " "
				}
			}
			underlineString += "^"
			if sourceFileRange.columnStart < sourceFileRange.columnEnd {
				for _ in (sourceFileRange.columnStart + 1)..<sourceFileRange.columnEnd {
					underlineString += "~"
				}
			}

			return "\(relativePath):\(sourceFileRange.lineStart):" +
				"\(sourceFileRange.columnStart): \(errorOrWarning): \(message)\n" +
				"\(sourceFileString)\n" +
				"\(underlineString)\n" +
				"Thrown by \(throwingFileName):\(line) - \(function)\n" +
				details
		}
		else {
			return "\(errorOrWarning): \(message)\n" +
				"Thrown by \(throwingFileName):\(line) - \(function)\n" +
				details
		}
	}
}
