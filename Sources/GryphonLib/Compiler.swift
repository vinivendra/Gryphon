//
// Copyright 2018 Vinicius Jorge Vendramini
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

// gryphon output: Sources/GryphonLib/Compiler.swiftAST
// gryphon output: Sources/GryphonLib/Compiler.gryphonASTRaw
// gryphon output: Sources/GryphonLib/Compiler.gryphonAST
// gryphon output: Bootstrap/Compiler.kt

import Foundation

public class Compiler {
	public private(set) static var log: ((String) -> ()) = { print($0) }

	public static func shouldLogProgress(if value: Bool) {
		if value {
			log = { print($0) }
		}
		else {
			log = { _ in }
		}
	}

	//
	public static var shouldStopAtFirstError = false
	public static var shouldAvoidUnicodeCharacters = false

	// TODO: handle translation of private(set)
	internal static var issues: MutableList<CompilerIssue> = []

	internal static var numberOfErrors: Int {
		return issues.filter { $0.isError }.count
	}
	internal static var numberOfWarnings: Int {
		return issues.filter { !$0.isError }.count
	}

	internal static func handleError(
		message: String,
		astDetails: String = "",
		sourceFile: SourceFile?,
		sourceFileRange: SourceFileRange?)
		throws
	{
		let issue = CompilerIssue(
			message: message,
			astDetails: astDetails,
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
		astDetails: String = "",
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
			astDetails: astDetails,
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

	public static func printErrorsAndWarnings() {
		let sortedIssues = issues.sorted { a, b in
				a.isBeforeIssueInLines(b)
			}.sorted { a, b in
				a.isBeforeIssueInSourceFile(b)
			}

		for issue in sortedIssues {
			print(issue.fullMessage)
		}

		if hasIssues() {
			print("Total: \(numberOfErrors) errors and \(numberOfWarnings) warnings.")
		}
	}

	//
	public static func generateSwiftAST(fromASTDump astDump: String) throws -> SwiftAST {
		log("\t- Building SwiftAST...")
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
		log("\t- Translating Swift ASTs to Gryphon ASTs...")
		return try SwiftTranslator(context: context).translateAST(swiftAST, asMainFile: asMainFile)
	}

	public static func transpileGryphonRawASTs(
		fromASTDumpFiles inputFiles: MutableList<String>,
		withContext context: TranspilationContext)
		throws -> MutableList<GryphonAST>
	{
		let asts = try inputFiles.map { try transpileSwiftAST(fromASTDumpFile: $0) }
		let translateAsMainFile = (inputFiles.count == 1)
		return try asts.map {
			try generateGryphonRawAST(
				fromSwiftAST: $0,
				asMainFile: translateAsMainFile,
				withContext: context)
		}.toMutableList()
	}

	//
	public static func generateGryphonASTAfterFirstPasses(
		fromGryphonRawAST ast: GryphonAST,
		withContext context: TranspilationContext)
		throws -> GryphonAST
	{
		log("\t- Running first round of passes...")
		try Utilities.processGryphonTemplatesLibrary()
		return TranspilationPass.runFirstRoundOfPasses(on: ast, withContext: context)
	}

	public static func generateGryphonASTAfterSecondPasses(
		fromGryphonRawAST ast: GryphonAST,
		withContext context: TranspilationContext)
		throws -> GryphonAST
	{
		log("\t- Running second round of passes...")
		try Utilities.processGryphonTemplatesLibrary()
		return TranspilationPass.runSecondRoundOfPasses(on: ast, withContext: context)
	}

	public static func generateGryphonAST(
		fromGryphonRawAST ast: GryphonAST,
		withContext context: TranspilationContext)
		throws -> GryphonAST
	{
		var ast = ast
		log("\t- Running passes on Gryphon ASTs...")
		try Utilities.processGryphonTemplatesLibrary()
		ast = TranspilationPass.runFirstRoundOfPasses(on: ast, withContext: context)
		ast = TranspilationPass.runSecondRoundOfPasses(on: ast, withContext: context)
		return ast
	}

	public static func transpileGryphonASTs(
		fromASTDumpFiles inputFiles: MutableList<String>,
		withContext context: TranspilationContext)
		throws -> MutableList<GryphonAST>
	{
		let rawASTs = try transpileGryphonRawASTs(
			fromASTDumpFiles: inputFiles,
			withContext: context)
		return try rawASTs.map {
			try generateGryphonAST(fromGryphonRawAST: $0, withContext: context)
		}.toMutableList()
	}

	//
	public static func generateKotlinCode(
		fromGryphonAST ast: GryphonAST,
		withContext context: TranspilationContext)
		throws -> String
	{
		log("\t- Translating AST to Kotlin...")
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
			Utilities.createFile(atPath: errorMapFilePath, containing: errorMapFileContents)
		}

		return translationResult.translation
	}

	public static func transpileKotlinCode(
		fromASTDumpFiles inputFiles: MutableList<String>,
		withContext context: TranspilationContext)
		throws -> MutableList<String>
	{
		let asts = try transpileGryphonASTs(fromASTDumpFiles: inputFiles, withContext: context)
		return try asts.map {
			try generateKotlinCode(fromGryphonAST: $0, withContext: context)
		}.toMutableList()
	}
}

public struct GryphonError: Error, CustomStringConvertible {
	let errorMessage: String

	public var description: String {
		return errorMessage
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

	/// Initializes an issue, using the given information to create the message to be printed.
	/// The `message` parameter is the short message in the issue header (i.e. "Unrecognized
	/// identifier"); the details can be verbose, they will be printed later and won't show in Xcode
	/// (i.e. "while translating the AST:\n\(ast.prettyPrint())").
	init(
		message: String,
		astDetails: String,
		sourceFile: SourceFile?,
		sourceFileRange: SourceFileRange?,
		isError: Bool)
	{
		self.fullMessage = CompilerIssue.createMessage(
			message: message,
			astDetails: astDetails,
			sourceFile: sourceFile,
			sourceFileRange: sourceFileRange,
			isError: isError)
		self.isError = isError
		self.sourceFile = sourceFile
		self.range = sourceFileRange
	}

	private static func createMessage(
		message: String,
		astDetails: String,
		sourceFile: SourceFile?,
		sourceFileRange: SourceFileRange?,
		isError: Bool) -> String
	{
		let errorOrWarning = isError ? "error" : "warning"

		if let sourceFile = sourceFile {
			let sourceFilePath = sourceFile.path
			let absolutePath = Utilities.getAbsoultePath(forFile: sourceFilePath)

			if let sourceFileRange = sourceFileRange {
				let sourceFileString = sourceFile.getLine(sourceFileRange.lineStart) ??
					"<<Unable to get line \(sourceFileRange.lineStart) in file \(absolutePath)>>"

				var underlineString = ""
				if sourceFileRange.columnEnd < sourceFileString.count {
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
				}

				return "\(absolutePath):\(sourceFileRange.lineStart):" +
					"\(sourceFileRange.columnStart): \(errorOrWarning): \(message)\n" +
					"\(sourceFileString)\n" +
					"\(underlineString)\n" +
					astDetails
			}
			else {
				return "\(absolutePath): \(errorOrWarning): \(message)\n" +
					astDetails
			}
		}
		else {
			return "\(errorOrWarning): \(message)\n" +
				astDetails
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
