//
// Copyright 2018 Vinicius Jorge Vendramini
//
// Licensed under the Hippocratic License, Version 2.1;
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://firstdonoharm.dev/version/2/1/license.md
//
// To the full extent allowed by law, this software comes "AS IS,"
// WITHOUT ANY WARRANTY, EXPRESS OR IMPLIED, and licensor and any other
// contributor shall not be liable to anyone for any damages or other
// liability arising from, out of, or in connection with the sotfware
// or this license, under any kind of legal claim.
// See the License for the specific language governing permissions and
// limitations under the License.
//

// gryphon output: Sources/GryphonLib/Compiler.swiftAST
// gryphon output: Sources/GryphonLib/Compiler.gryphonASTRaw
// gryphon output: Sources/GryphonLib/Compiler.gryphonAST
// gryphon output: Bootstrap/Compiler.kt

import Foundation

public class Compiler {
	public static var logError: ((String) -> ()) = { input in
		fputs(input + "\n", stderr) // gryphon ignore
		// gryphon insert: System.err.println(input)
	}

	public static var logIndentation = 0
	public static var shouldLogProgress = false
	static func log(_ contents: String) {
		guard shouldLogProgress else {
			return
		}

		// Add indentation
		// (If there's a mismatch in indentation increases/decreases and the indentation becomes
		// negative, this shouldn't crash)
		var indentation = ""
		var i = 0
		while i < logIndentation {
			indentation += "\t"
			i += 1
		}

		// Print contents with the right indentation
		let contentLines = contents.split(withStringSeparator: "\n")
		for line in contentLines {
			output(indentation + line)
		}
	}

	/// Log the start of a new operation
	static func logStart(_ contents: String) {
		log(contents)
		logIndentation += 1
	}

	/// Log the end of an operation
	static func logEnd(_ contents: String) {
		logIndentation -= 1
		log(contents)
	}

	/// Used for printing strings to stdout. Can be changed by tests in order to check the outputs.
	public static func output(_ contents: Any) {
		outputFunction(contents)
	}

	public static var outputFunction: ((Any) -> ()) =
		{ contents in
			print(contents)
		}

	//
	public static var shouldStopAtFirstError = false
	public static var shouldAvoidUnicodeCharacters = false

	internal static var issues: MutableList<CompilerIssue> = []

	internal static var numberOfErrors: Int {
		return issues.filter { $0.isError }.count
	}
	internal static var numberOfWarnings: Int {
		return issues.filter { !$0.isError }.count
	}

	internal static func handleError(
		message: String,
		ast: PrintableAsTree? = nil,
		sourceFile: SourceFile?,
		sourceFileRange: SourceFileRange?)
		throws
	{
		let issue = CompilerIssue(
			message: message,
			ast: ast,
			sourceFile: sourceFile,
			sourceFileRange: sourceFileRange,
			isError: true)

		if Compiler.shouldStopAtFirstError {
			throw GryphonError(errorMessage: issue.fullMessage)
		}
		else {
			Compiler.issues.append(issue)
		}
	}

	internal static func handleWarning(
		message: String,
		ast: PrintableAsTree? = nil,
		sourceFile: SourceFile?,
		sourceFileRange: SourceFileRange?)
	{
		// Check if there's a comment muting warnings in this line in the source code
		if let sourceFileRange = sourceFileRange {
			if let comment = sourceFile?.getTranslationCommentFromLine(sourceFileRange.lineStart) {
				if comment.key == .mute {
					return
				}
			}
		}

		Compiler.issues.append(CompilerIssue(
			message: message,
			ast: ast,
			sourceFile: sourceFile,
			sourceFileRange: sourceFileRange,
			isError: false))
	}

	public static func hasIssues() -> Bool {
		return !issues.isEmpty
	}

	public static func clearIssues() {
		issues = []
	}

	public static func printIssues(skippingWarnings: Bool = false) {
		let issuesToPrint: List<CompilerIssue>
		if skippingWarnings {
			issuesToPrint = issues.filter { $0.isError }
		}
		else {
			issuesToPrint = issues
		}

		let sortedIssues = issuesToPrint.sorted { a, b in
				a.isBeforeIssueInLines(b)
			}.sorted { a, b in
				a.isBeforeIssueInSourceFile(b)
			}

		for issue in sortedIssues {
			logError(issue.fullMessage)
		}
	}

	//
	public static func generateSwiftAST(fromASTDump astDump: String) throws -> SwiftAST {
		let ast = try ASTDumpDecoder(encodedString: astDump).decode()
		return ast
	}

	public static func transpileSwiftAST(fromASTDumpFile inputFile: String) throws -> SwiftAST {
		let astDump = try Utilities.readFile(inputFile)
		return try generateSwiftAST(fromASTDump: astDump)
	}

	//
	public static func generateGryphonRawAST(
		fromSwiftAST swiftAST: SwiftAST,
		asMainFile: Bool,
		withContext context: TranspilationContext)
		throws -> GryphonAST
	{
		return try SwiftTranslator(context: context).translateAST(swiftAST, asMainFile: asMainFile)
	}

	public static func transpileGryphonRawASTs(
		fromASTDumpFiles inputFiles: List<String>,
		withContext context: TranspilationContext)
		throws -> List<GryphonAST>
	{
		let asts = try inputFiles.map { try transpileSwiftAST(fromASTDumpFile: $0) }
		let translateAsMainFile = (inputFiles.count == 1)
		return try asts.map {
			try generateGryphonRawAST(
				fromSwiftAST: $0,
				asMainFile: translateAsMainFile,
				withContext: context)
		}
	}

	//
	public static func generateGryphonASTAfterFirstPasses(
		fromGryphonRawAST ast: GryphonAST,
		withContext context: TranspilationContext)
		throws -> GryphonAST
	{
		return TranspilationPass.runFirstRoundOfPasses(on: ast, withContext: context)
	}

	public static func generateGryphonASTAfterSecondPasses(
		fromGryphonRawAST ast: GryphonAST,
		withContext context: TranspilationContext)
		throws -> GryphonAST
	{
		return TranspilationPass.runSecondRoundOfPasses(on: ast, withContext: context)
	}

	public static func generateGryphonAST(
		fromGryphonRawAST ast: GryphonAST,
		withContext context: TranspilationContext)
		throws -> GryphonAST
	{
		var ast = ast
		ast = TranspilationPass.runFirstRoundOfPasses(on: ast, withContext: context)
		ast = TranspilationPass.runSecondRoundOfPasses(on: ast, withContext: context)
		return ast
	}

	public static func transpileGryphonASTs(
		fromASTDumpFiles inputFiles: List<String>,
		withContext context: TranspilationContext)
		throws -> List<GryphonAST>
	{
		let rawASTs = try transpileGryphonRawASTs(
			fromASTDumpFiles: inputFiles,
			withContext: context)
		return try rawASTs.map {
			try generateGryphonAST(fromGryphonRawAST: $0, withContext: context)
		}
	}

	//
	public static func generateKotlinCode(
		fromGryphonAST ast: GryphonAST,
		withContext context: TranspilationContext)
		throws -> String
	{
		let translation = try KotlinTranslator(context: context).translateAST(ast)
		let translationResult = translation.resolveTranslation()

		if let swiftFilePath = ast.sourceFile?.path, let kotlinFilePath = ast.outputFileMap[.kt] {
			let errorMap = translationResult.errorMap
			let errorMapFilePath =
				SupportingFile.pathOfKotlinErrorMapFile(forKotlinFile: kotlinFilePath)
			let errorMapFolder =
				errorMapFilePath.split(withStringSeparator: "/").dropLast().joined(separator: "/")
			let errorMapFileContents = swiftFilePath + "\n" + errorMap
			Utilities.createFolderIfNeeded(at: errorMapFolder)
			try Utilities.createFile(atPath: errorMapFilePath, containing: errorMapFileContents)
		}

		return translationResult.translation
	}

	public static func transpileKotlinCode(
		fromASTDumpFiles inputFiles: List<String>,
		withContext context: TranspilationContext)
		throws -> List<String>
	{
		let asts = try transpileGryphonASTs(fromASTDumpFiles: inputFiles, withContext: context)
		return try asts.map {
			try generateKotlinCode(fromGryphonAST: $0, withContext: context)
		}
	}
}

/// A compiler error or warning, including information needed to sort it before printing
/// (sourceFile, range and isError) and the full message that should be printed.
internal class CompilerIssue {
	/// The complete message, including source file and range information, that should be printed
	let fullMessage: String
	/// `true` if this is an error, `false` if this is a warning.
	let isError: Bool
	let sourceFile: SourceFile?
	let range: SourceFileRange?

	static var shouldPrintASTs = false

	/// Initializes an issue, using the given information to create the message to be printed.
	/// The `message` parameter is the short message in the issue header (i.e. "Unrecognized
	/// identifier"); the details can be verbose, they will be printed later and won't show in Xcode
	/// (i.e. "while translating the AST:\n\(ast.prettyPrint())").
	init(
		message: String,
		ast: PrintableAsTree?,
		sourceFile: SourceFile?,
		sourceFileRange: SourceFileRange?,
		isError: Bool)
	{
		self.fullMessage = CompilerIssue.createMessage(
			message: message,
			ast: ast,
			sourceFile: sourceFile,
			sourceFileRange: sourceFileRange,
			isError: isError)
		self.isError = isError
		self.sourceFile = sourceFile
		self.range = sourceFileRange
	}

	private static func createMessage(
		message: String,
		ast: PrintableAsTree?,
		sourceFile: SourceFile?,
		sourceFileRange: SourceFileRange?,
		isError: Bool) -> String
	{
		let result: String

		let errorOrWarning = isError ? "error" : "warning"

		if let sourceFile = sourceFile {
			let sourceFilePath = sourceFile.path
			let absolutePath = Utilities.getAbsoultePath(forFile: sourceFilePath)

			if let sourceFileRange = sourceFileRange {
				let sourceFileString = sourceFile.getLine(sourceFileRange.lineStart) ??
					"<<Unable to get line \(sourceFileRange.lineStart) in file \(absolutePath)>>"

				var underlineString = ""
				if sourceFileRange.columnEnd <= sourceFileString.count {
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
						for _ in sourceFileRange.columnStart..<sourceFileRange.columnEnd {
							underlineString += "~"
						}
					}
				}

				result = "\(absolutePath):\(sourceFileRange.lineStart):" +
					"\(sourceFileRange.columnStart): \(errorOrWarning): \(message)\n" +
					"\(sourceFileString)\n" +
					"\(underlineString)\n"
			}
			else {
				result = "\(absolutePath): \(errorOrWarning): \(message)\n"
			}
		}
		else {
			result = "\(errorOrWarning): \(message)\n"
		}

		if CompilerIssue.shouldPrintASTs, let ast = ast {
			return result + "Thrown when translating the following AST node:\n" +
				ast.prettyDescription()
		}
		else {
			return result
		}
	}

	/// Comparison function for ordering issues with smaller lines first, and issues with no lines
	/// last (i.e. issues where the `range` is `nil`).
	func isBeforeIssueInLines(_ otherIssue: CompilerIssue) -> Bool {
		if let thisLine = self.range?.lineStart {
			if let otherLine = otherIssue.range?.lineStart {
				return thisLine < otherLine
			}
			else {
				return true
			}
		}

		return false
	}

	/// Comparison function for ordering issues alphabetically by source file path, and issues with
	/// no source files last.
	func isBeforeIssueInSourceFile(_ otherIssue: CompilerIssue) -> Bool {
		if let thisPath = self.sourceFile?.path {
			if let otherPath = otherIssue.sourceFile?.path {
				return thisPath < otherPath
			}
			else {
				return true
			}
		}

		return false
	}
}
