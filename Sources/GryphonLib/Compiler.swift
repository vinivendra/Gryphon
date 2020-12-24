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

import Foundation
import SwiftSyntax

public class Compiler {
	private static var logIndentation: Atomic<Int> = Atomic(0)

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
		while i < logIndentation.atomic {
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
		logIndentation.mutateAtomically { $0 += 1 }
	}

	/// Log the end of an operation
	static func logEnd(_ contents: String) {
		logIndentation.mutateAtomically { $0 -= 1 }
		log(contents)
	}

	/// Used for printing strings to stdout. Can be changed by tests in order to check the outputs.
	public static func output(_ contents: Any, terminator: String = "\n") {
		outputFunction(contents, terminator)
	}

	/// The function used to output logs to the console. Set to a variable for testing. Any
	/// alternatives to this function should consider using the `printingLock`.
	public static var outputFunction: ((Any, String) -> ()) =
		{ contents, terminator in
			printingLock.lock()
			print(contents, terminator: terminator)
			printingLock.unlock()
		}

	/// The function used to error logs to stderr. Set to a variable for testing. Any
	/// alternatives to this function should consider using the `printingLock`.
	public static var logError: ((String) -> ()) = { input in
		printingLock.lock()
		fputs(input + "\n", stderr)
		printingLock.unlock()
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

	/// Uses the given syntax to check for `mute` comments before raising the warning.
	internal static func handleWarning(
		message: String,
		syntax: Syntax?,
		ast: PrintableAsTree? = nil,
		sourceFile: SourceFile?,
		sourceFileRange: SourceFileRange?)
	{
		if let syntax = syntax,
			let sourceFile = sourceFile,
			shouldMuteWarnings(forSyntax: syntax, inSourceFile: sourceFile)
		{
			return
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

	/// Checks this syntax for a leading mute comment. If there isn't one, check its parent
	/// syntaxes. Stop at the first statement or declaration, so we only check (e.g.) a variable
	/// declaration but not its enveloping class.
	public static func shouldMuteWarnings(
		forSyntax syntax: Syntax,
		inSourceFile sourceFile: SourceFile)
		-> Bool
	{
		var currentSyntax = syntax

		while true {
			if !SwiftSyntaxDecoder.getLeadingComments(
					forSyntax: currentSyntax,
					sourceFile: sourceFile,
					withKey: .mute)
				.isEmpty
			{
				// If there's a mute comment
				return true
			}

			// If we we're checking a statement or declaration
			if currentSyntax.is(StmtSyntax.self) || currentSyntax.is(DeclSyntax.self) {
				return false
			}

			if let parent = currentSyntax.parent {
				currentSyntax = parent
			}
			else {
				return false
			}
		}
	}

	/// Checks this statement for a mute comment.
	func shouldMuteWarning(
		forStatement statement: Statement,
		inSourceFile sourceFile: SourceFile)
		-> Bool
	{
		guard let currentSyntax = statement.syntax else {
			return false
		}

		if !SwiftSyntaxDecoder.getLeadingComments(
				forSyntax: currentSyntax,
				sourceFile: sourceFile,
				withKey: .mute)
			.isEmpty
		{
			return true
		}

		return false
	}

	//
	public static func generateSwiftSyntaxDecoder(
		fromSwiftFile inputFilePath: String,
		withContext context: TranspilationContext)
		throws -> SwiftSyntaxDecoder
	{
		let logInfo = Log.startLog(name: "1 - Swift Syntax")
		defer { Log.endLog(info: logInfo) }
		let sourceFile = try SourceFile.readFile(atPath: inputFilePath)
		return try SwiftSyntaxDecoder(sourceFile: sourceFile, context: context)
	}

	//
	public static func generateGryphonRawAST(
		usingFileDecoder decoder: SwiftSyntaxDecoder,
		asMainFile: Bool,
		withContext context: TranspilationContext)
		throws -> GryphonAST
	{
		let logInfo = Log.startLog(name: "1.5 - Swift Syntax Decoder")
		defer { Log.endLog(info: logInfo) }
		return try decoder.convertToGryphonAST(asMainFile: asMainFile)
	}

	public static func transpileGryphonRawASTs(
		fromInputFiles inputFiles: List<String>,
		fromASTDumpFiles astDumpFiles: List<String>,
		withContext context: TranspilationContext)
		throws -> List<GryphonAST>
	{
		let translateAsMainFile = (inputFiles.count == 1)

		return try inputFiles.map {
			let decoder = try generateSwiftSyntaxDecoder(
				fromSwiftFile: $0,
				withContext: context)
			return try generateGryphonRawAST(
				usingFileDecoder: decoder,
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
		let logInfo = Log.startLog(name: "2 - First round")
		defer { Log.endLog(info: logInfo) }
		return TranspilationPass.runFirstRoundOfPasses(on: ast, withContext: context)
	}

	public static func generateGryphonASTAfterSecondPasses(
		fromGryphonRawAST ast: GryphonAST,
		withContext context: TranspilationContext)
		throws -> GryphonAST
	{
		let logInfo = Log.startLog(name: "3 - Second round")
		defer { Log.endLog(info: logInfo) }
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
		fromInputFiles inputFiles: List<String>,
		fromASTDumpFiles astDumpFiles: List<String>,
		withContext context: TranspilationContext)
		throws -> List<GryphonAST>
	{
		let rawASTs = try transpileGryphonRawASTs(
			fromInputFiles: inputFiles,
			fromASTDumpFiles: astDumpFiles,
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
		let logInfo = Log.startLog(name: "4 - Kotlin code")
		defer { Log.endLog(info: logInfo) }
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
		fromInputFiles inputFiles: List<String>,
		fromASTDumpFiles astDumpFiles: List<String>,
		withContext context: TranspilationContext)
		throws -> List<String>
	{
		let asts = try transpileGryphonASTs(
			fromInputFiles: inputFiles,
			fromASTDumpFiles: astDumpFiles,
			withContext: context)
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
			let absolutePath = Utilities.getAbsolutePath(forFile: sourceFilePath)

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
