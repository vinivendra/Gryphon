//
// Copyright 2018 Vinícius Jorge Vendramini
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

public class Driver {
	public struct Settings {
		let shouldEmitSwiftAST: Bool
		let shouldEmitRawAST: Bool
		let shouldEmitAST: Bool
		let shouldRun: Bool
		let shouldBuild: Bool
		let shouldEmitKotlin: Bool
		let shouldGenerateKotlin: Bool
		let shouldGenerateAST: Bool
		let shouldGenerateRawAST: Bool
		let shouldGenerateSwiftAST: Bool

		let canPrintToFiles: Bool
		let canPrintToOutput: Bool

		let horizontalLimit: Int?
		let outputFileMap: OutputFileMap?
		let outputFolder: String

		let mainFilePath: String?
	}

	public static func runUpToFirstPasses(
		withSettings settings: Settings,
		withContext context: TranspilationContext,
		onFile inputFilePath: String) throws -> Any?
	{
		guard settings.shouldGenerateSwiftAST else {
			return [] // value: mutableListOf<Any>()
		}

		let swiftASTDumpFile = getASTDump(forFile: inputFilePath, settings: settings)!

		let swiftASTDump = try Utilities.readFile(swiftASTDumpFile)

		// Generate the Swift AST
		let swiftAST = try Compiler.generateSwiftAST(fromASTDump: swiftASTDump)
		if settings.shouldEmitSwiftAST {
			let output = swiftAST.prettyDescription(
				horizontalLimit: settings.horizontalLimit)
			if let outputFilePath = settings.outputFileMap?.getOutputFile(
					forInputFile: inputFilePath, outputType: .swiftAST),
				settings.canPrintToFiles
			{
				Utilities.createFile(atPath: outputFilePath, containing: output)
			}
			else if settings.canPrintToOutput {
				print(output)
			}
		}

		guard settings.shouldGenerateRawAST else {
			return swiftAST
		}

		let isMainFile = (inputFilePath == settings.mainFilePath)

		let gryphonRawAST = try Compiler.generateGryphonRawAST(
			fromSwiftAST: swiftAST,
			asMainFile: isMainFile)
		if settings.shouldEmitRawAST {
			let output = gryphonRawAST.prettyDescription(
				horizontalLimit: settings.horizontalLimit)
			if let outputFilePath = settings.outputFileMap?.getOutputFile(
				forInputFile: inputFilePath, outputType: .gryphonASTRaw),
				settings.canPrintToFiles
			{
				Utilities.createFile(atPath: outputFilePath, containing: output)
			}
			else if settings.canPrintToOutput {
				print(output)
			}
		}

		guard settings.shouldGenerateAST else {
			return gryphonRawAST
		}

		let gryphonFirstPassedAST = try Compiler.generateGryphonASTAfterFirstPasses(
			fromGryphonRawAST: gryphonRawAST,
			withContext: context)

		return gryphonFirstPassedAST
	}

	public static func runAfterFirstPasses(
		onAST gryphonFirstPassedAST: GryphonAST,
		withSettings settings: Settings,
		withContext context: TranspilationContext,
		onFile inputFilePath: String)
		throws -> Any?
	{
		let gryphonAST = try Compiler.generateGryphonASTAfterSecondPasses(
			fromGryphonRawAST: gryphonFirstPassedAST, withContext: context)
		if settings.shouldEmitAST {
			let output = gryphonAST.prettyDescription(
				horizontalLimit: settings.horizontalLimit)
			if let outputFilePath = settings.outputFileMap?.getOutputFile(
					forInputFile: inputFilePath, outputType: .gryphonAST),
				settings.canPrintToFiles
			{
				Utilities.createFile(atPath: outputFilePath, containing: output)
			}
			else if settings.canPrintToOutput {
				print(output)
			}
		}

		guard settings.shouldGenerateKotlin else {
			return gryphonAST
		}

		let kotlinCode = try Compiler.generateKotlinCode(
			fromGryphonAST: gryphonAST,
			withContext: context)
		if let outputFilePath = settings.outputFileMap?.getOutputFile(
				forInputFile: inputFilePath, outputType: .kotlin),
			settings.canPrintToFiles
		{
			Utilities.createFile(atPath: outputFilePath, containing: kotlinCode)
		}
		else if settings.canPrintToOutput {
			if settings.shouldEmitKotlin {
				print(kotlinCode)
			}
		}

		return kotlinCode
	}

	@discardableResult
	public static func run(
		withArguments arguments: ArrayClass<String>) throws -> Any?
	{
		if arguments.contains("-init") {
			initialize()
			print("Initialization successful.")
			return nil
		}

		defer {
			if arguments.contains("-summarize-errors") {
				Compiler.printErrorStatistics()
			}
			else {
				Compiler.printErrorsAndWarnings()
			}
		}

		Compiler.clearErrorsAndWarnings()

		// Parse arguments
		Compiler.shouldLogProgress(if: arguments.contains("-verbose"))
		Compiler.shouldStopAtFirstError = !arguments.contains("-continue-on-error")

		//
		let horizontalLimit: Int?
		if let lineLimitArgument = arguments.first(where: { $0.hasPrefix("-line-limit=") }) {
			let lineLimitString = lineLimitArgument.dropFirst("-line-limit=".count)
			horizontalLimit = Int(lineLimitString)
		}
		else {
			horizontalLimit = nil
		}

		//
		let outputFileMap: OutputFileMap?
		if let outputFileMapArgument =
			arguments.first(where: { $0.hasPrefix("-output-file-map=") })
		{
			let outputFileMapPath = outputFileMapArgument.dropFirst("-output-file-map=".count)
			outputFileMap = OutputFileMap(String(outputFileMapPath))
		}
		else {
			outputFileMap = nil
		}

		//
		let outputFolder: String
		if let outputFolderIndex = arguments.index(of: "-o") {
			if let maybeOutputFolder = arguments[safe: outputFolderIndex + 1] {
				outputFolder = maybeOutputFolder
			}
			else {
				outputFolder = OS.buildFolder
			}
		}
		else {
			outputFolder = OS.buildFolder
		}

		//
		let inputFilePaths = arguments.filter {
			!$0.hasPrefix("-") && $0 != "run" && $0 != "build"
		}

		//
		let shouldEmitSwiftAST = arguments.contains("-emit-swiftAST")
		let shouldEmitRawAST = arguments.contains("-emit-rawAST")
		let shouldEmitAST = arguments.contains("-emit-AST")
		let shouldRun = arguments.contains("run")
		let shouldBuild = shouldRun || arguments.contains("build")

		let hasChosenTask = shouldEmitSwiftAST ||
			shouldEmitRawAST ||
			shouldEmitAST ||
			shouldRun ||
			shouldBuild

		let shouldEmitKotlin = !hasChosenTask || arguments.contains("-emit-kotlin")

		//
		let canPrintToFiles = !arguments.contains("-Q")
		let canPrintToOutput = !arguments.contains("-q")

		//
		let shouldGenerateKotlin = shouldBuild || shouldEmitKotlin
		let shouldGenerateAST = shouldGenerateKotlin || shouldEmitAST
		let shouldGenerateRawAST = shouldGenerateAST || shouldEmitRawAST
		let shouldGenerateSwiftAST = shouldGenerateRawAST || shouldEmitSwiftAST

		//
		let mainFilePath: String?
		if arguments.contains("-no-main-file") {
			mainFilePath = nil
		}
		else if inputFilePaths.count == 1 {
			mainFilePath = inputFilePaths[0]
		}
		else {
			mainFilePath = inputFilePaths.first {
				$0.hasSuffix("main.swift") || $0.hasSuffix("main.swiftASTDump")
			}
		}

		//
		let settings = Settings(
			shouldEmitSwiftAST: shouldEmitSwiftAST,
			shouldEmitRawAST: shouldEmitRawAST,
			shouldEmitAST: shouldEmitAST,
			shouldRun: shouldRun,
			shouldBuild: shouldBuild,
			shouldEmitKotlin: shouldEmitKotlin,
			shouldGenerateKotlin: shouldGenerateKotlin,
			shouldGenerateAST: shouldGenerateAST,
			shouldGenerateRawAST: shouldGenerateRawAST,
			shouldGenerateSwiftAST: shouldGenerateSwiftAST,
			canPrintToFiles: canPrintToFiles,
			canPrintToOutput: canPrintToOutput,
			horizontalLimit: horizontalLimit,
			outputFileMap: outputFileMap,
			outputFolder: outputFolder,
			mainFilePath: mainFilePath)

		//
		var indentationString = "\t"
		if let indentationArgument = arguments.first(where: { $0.hasPrefix("-indentation=") }) {
			let indentationargument = indentationArgument
				.dropFirst("-indentation=".count)

			if indentationargument == "t" {
				indentationString = "\t"
			}
			else if let numberOfSpaces = Int(indentationargument) {
				var result = ""
				for _ in 0..<numberOfSpaces {
					result += " "
				}
				indentationString = result
			}
		}

		//
		let context = TranspilationContext(indentationString: indentationString)

		//
		let shouldRunConcurrently = !arguments.contains("-sync")

		// Update libraries syncronously to guarantee it's only done once
		if shouldGenerateAST {
			try Utilities.updateLibraryFiles()
		}

		// Run compiler steps
		let filteredInputFiles = inputFilePaths.filter {
			$0.hasSuffix(".swift") || $0.hasSuffix(".swiftASTDump")
		}

		let firstResult: ArrayClass<Any?>
		if shouldRunConcurrently {
			firstResult = try filteredInputFiles.parallelMap {
				try runUpToFirstPasses(withSettings: settings, withContext: context, onFile: $0)
			}
		}
		else {
			firstResult = try filteredInputFiles.map {
				try runUpToFirstPasses(withSettings: settings, withContext: context, onFile: $0)
			}
		}

		// If we've received a non-raw AST then we're in the middle of the transpilation passes.
		// This means we need to at least run the second round of passes.
		guard let asts = firstResult.as(ArrayClass<GryphonAST>.self),
			settings.shouldGenerateAST else
		{
			return firstResult
		}

		let pairsArray = zipToClass(asts, filteredInputFiles) // kotlin: ignore
		// insert: val pairsArray: MutableList<Pair<GryphonAST, String>> =
		// insert: 	asts.zip(filteredInputFiles).toMutableList()

		let secondResult: ArrayClass<Any?>
		if shouldRunConcurrently {
			secondResult = try pairsArray.parallelMap {
				try runAfterFirstPasses(
					onAST: $0.0,
					withSettings: settings,
					withContext: context,
					onFile: $0.1)
			}
		}
		else {
			secondResult = try pairsArray.map {
				try runAfterFirstPasses(
					onAST: $0.0,
					withSettings: settings,
					withContext: context,
					onFile: $0.1)
			}
		}

		guard settings.shouldBuild else {
			return secondResult
		}

		let generatedKotlinFiles = filteredInputFiles.compactMap {
			settings.outputFileMap?.getOutputFile(forInputFile: $0, outputType: .kotlin)
		}
		let inputKotlinFiles = inputFilePaths.filter { $0.hasSuffix(".kt") }

		let kotlinFiles = generatedKotlinFiles
		kotlinFiles.append(contentsOf: inputKotlinFiles)

		guard let compilationResult = try Compiler.compile(
			kotlinFiles: kotlinFiles,
			outputFolder: settings.outputFolder) else
		{
			return nil
		}

		guard settings.shouldRun else {
			return compilationResult
		}

		let runResult = try Compiler.runCompiledProgram(fromFolder: settings.outputFolder)

		return runResult
	}

	static func initialize() {
		let gryphonFolder = ".gryphon"

		// Create gryphon folder
		Utilities.createFolderIfNeeded(at: gryphonFolder)

		// Save the standard library templates file in it
		Utilities.createFile(
			named: "StandardLibrary.template.swift",
			inDirectory: gryphonFolder,
			containing: DriverContants.standardLibraryTemplateFileContents)
	}

	static func getASTDump(forFile file: String, settings: Settings) -> String? {
		if file.hasSuffix(".swift") {
			if let astDumpFile = settings.outputFileMap?.getOutputFile(
				forInputFile: file, outputType: .astDump)
			{
				return astDumpFile
			}
			else {
				return Utilities.changeExtension(of: file, to: .swiftASTDump)
			}
		}
		else if file.hasSuffix(".swiftASTDump") {
			return file
		}
		else {
			return nil
		}
	}
}

// declaration: class DriverContants {
// declaration:     companion object {
// declaration:         val standardLibraryTemplateFileContents: String = ""
// declaration:     }
// declaration: }

class DriverContants { // kotlin: ignore
	// FIXME: Add support for multi-line string, with special attention to the comments inside it.
	static let standardLibraryTemplateFileContents = """
	// WARNING: Any changes to this file should be reflected in the literal string in Driver.swift

	import Foundation

	// MARK: - Define special types as stand-ins for some protocols and other types

	// Replacement for Hashable
	struct Hash: Hashable { }

	// Replacement for Comparable
	struct Compare: Comparable {
		static func < (lhs: Compare, rhs: Compare) -> Bool {
			return false
		}
	}

	// Replacement for Optional
	struct MyOptional { }

	// Replacement for Any
	struct AnyType: CustomStringConvertible, LosslessStringConvertible {
		init() { }

		var description: String = ""

		init?(_ description: String) {
			return nil
		}
	}

	// MARK: - Define the templates
	func gryphonTemplates() {

		// MARK: Declare placeholder variables to use in the templates
		var _strArray: [String] = []
		var _array: [Any] = []
		var _array1: [Any] = []
		var _array2: [Any] = []
		var _arrayOfOptionals: [Any?] = []
		var _comparableArray : [Compare] = []
		let _compare = Compare()
		var _index: String.Index = "abc".endIndex
		let _index1: String.Index = "abc".startIndex
		let _index2: String.Index = "abc".startIndex
		var _string: String = "abc"
		var _string1: String = "abc"
		let _string2: String = "abc"
		let _string3: String = "abc"
		let _character: Character = "a"
		let _substring: Substring = "abc".dropLast()
		let _range: Range<String.Index> = _string.startIndex..<_string.endIndex
		let _any: Any = "abc"
		let _anyType: AnyType = AnyType()
		let _optional: MyOptional? = MyOptional()
		let _double: Double = 0
		let _double1: Double = 0
		let _double2: Double = 0
		let _int: Int = 0
		let _int1: Int = 0
		let _int2: Int = 0
		let _dictionary: [Hash: Any] = [:]
		let _closure: (Any, Any) -> Any = { a, b in a }
		let _closure2: (Any) -> Any = { a in a }
		let _closure3: (Any) -> Bool = { _ in true }
		let _closure4: (MyOptional) -> Any = { _ in true }
		let _closure5: (Character) -> Bool = { _ in true }
		let _closure6: (Any) -> Any? = { a in a }
		let _closure7: (Compare, Compare) -> Bool = { _, _ in true }

		// MARK: Declare the templates

		// System
		_ = print(_any)
		_ = "println(_any)"

		_ = print(_any, terminator: "")
		_ = "print(_any)"

		_ = fatalError(_string)
		_ = "println(\\\"Fatal error: ${_string}\\\"); exitProcess(-1)"

		// Darwin
		_ = sqrt(_double)
		_ = "Math.sqrt(_double)"

		// String
		_ = String(_anyType)
		_ = "_anyType.toString()"

		_ = _anyType.description
		_ = "_anyType.toString()"

		_ = _string.isEmpty
		_ = "_string.isEmpty()"

		_ = _string.count
		_ = "_string.length"

		_ = _string.first
		_ = "_string.firstOrNull()"

		_ = _string.last
		_ = "_string.lastOrNull()"

		_ = Double(_string)
		_ = "_string.toDouble()"

		_ = Float(_string)
		_ = "_string.toFloat()"

		_ = UInt64(_string)
		_ = "_string.toULong()"

		_ = Int64(_string)
		_ = "_string.toLong()"

		_ = Int(_string)
		_ = "_string.toIntOrNull()"

		_ = _string.dropLast()
		_ = "_string.dropLast(1)"

		_ = _string.dropLast(_int)
		_ = "_string.dropLast(_int)"

		_ = _string.dropFirst()
		_ = "_string.drop(1)"

		_ = _string.dropFirst(_int)
		_ = "_string.drop(_int)"

		_ = _string.indices
		_ = "_string.indices"

		_ = _string.firstIndex(of: _character)!
		_ = "_string.indexOf(_character)"

		_ = _string.contains(where: _closure5)
		_ = "(_string.find _closure5 != null)"

		_ = _string.index(of: _character)
		_ = "_string.indexOrNull(_character)"

		_ = _string.prefix(_int)
		_ = "_string.substring(0, _int)"

		_ = _string.prefix(upTo: _index)
		_ = "_string.substring(0, _index)"

		_ = _string[_index...]
		_ = "_string.substring(_index)"

		_ = _string[..._index]
		_ = "_string.substring(0, _index)"

		_ = _string[_index1..<_index2]
		_ = "_string.substring(_index1, _index2)"

		_ = _string[_index1..._index2]
		_ = "_string.substring(_index1, _index2 + 1)"

		_ = String(_substring)
		_ = "_substring"

		_ = _string.endIndex
		_ = "_string.length"

		_ = _string.startIndex
		_ = "0"

		_ = _string.formIndex(before: &_index)
		_ = "_index -= 1"

		_ = _string.index(after: _index)
		_ = "_index + 1"

		_ = _string.index(before: _index)
		_ = "_index - 1"

		_ = _string.index(_index, offsetBy: _int)
		_ = "_index + _int"

		_ = _substring.index(_index, offsetBy: _int)
		_ = "_index + _int"

		_ = _string1.replacingOccurrences(of: _string2, with: _string3)
		_ = "_string1.replace(_string2, _string3)"

		_ = _string1.prefix(while: _closure5)
		_ = "_string1.takeWhile _closure5"

		_ = _string1.hasPrefix(_string2)
		_ = "_string1.startsWith(_string2)"

		_ = _string1.hasSuffix(_string2)
		_ = "_string1.endsWith(_string2)"

		_ = _range.lowerBound
		_ = "_range.start"

		_ = _range.upperBound
		_ = "_range.endInclusive"

		_ = Range<String.Index>(uncheckedBounds: (lower: _index1, upper: _index2))
		_ = "IntRange(_index1, _index2)"

		_ = _string1.append(_string2)
		_ = "_string1 += _string2"

		_ = _string.append(_character)
		_ = "_string += _character"

		_ = _string.capitalized
		_ = "_string.capitalize()"

		_ = _string.uppercased()
		_ = "_string.toUpperCase()"

		// Character
		_ = _character.uppercased()
		_ = "_character.toUpperCase()"

		// Array
		_ = _array.append(_any)
		_ = "_array.add(_any)"

		_ = _array.insert(_any, at: _int)
		_ = "_array.add(_int, _any)"

		_ = _arrayOfOptionals.append(nil)
		_ = "_arrayOfOptionals.add(null)"

		_ = _array1.append(contentsOf: _array2)
		_ = "_array1.addAll(_array2)"

		_ = _array.isEmpty
		_ = "_array.isEmpty()"

		_ = _strArray.joined(separator: _string)
		_ = "_strArray.joinToString(separator = _string)"

		_ = _strArray.joined()
		_ = "_strArray.joinToString(separator = \\\"\\\")"

		_ = _array.count
		_ = "_array.size"

		_ = _array.indices
		_ = "_array.indices"

		_ = _array.first
		_ = "_array.firstOrNull()"

		_ = _array.first(where: _closure3)
		_ = "_array.find _closure3"

		_ = _array.last
		_ = "_array.lastOrNull()"

		_ = _array.removeFirst()
		_ = "_array.removeAt(0)"

		_ = _array.removeLast()
		_ = "_array.removeLast()"

		_ = _array.dropFirst()
		_ = "_array.drop(1)"

		_ = _array.dropLast()
		_ = "_array.dropLast(1)"

		_ = _array.map(_closure2)
		_ = "_array.map _closure2.toMutableList()"

		_ = _array.flatMap(_closure6)
		_ = "_array.flatMap _closure6.toMutableList()"

		_ = _array.compactMap(_closure2)
		_ = "_array.map _closure2.filterNotNull().toMutableList()"

		_ = _array.filter(_closure3)
		_ = "_array.filter _closure3.toMutableList()"

		_ = _array.reduce(_any, _closure)
		_ = "_array.fold(_any) _closure"

		_ = zip(_array1, _array2)
		_ = "_array1.zip(_array2)"

		_ = _array.indices
		_ = "_array.indices"

		_ = _array.index(where: _closure3)
		_ = "_array.indexOfFirst _closure3"

		_ = _array.contains(where: _closure3)
		_ = "(_array.find _closure3 != null)"

		_ = _comparableArray.sorted()
		_ = "_comparableArray.sorted()"

		_ = _comparableArray.sorted(by: _closure7)
		_ = "_comparableArray.sorted(isAscending = _closure7)"

		_ = _comparableArray.contains(_compare)
		_ = "_comparableArray.contains(_compare)"

		_ = _comparableArray.index(of: _compare)
		_ = "_comparableArray.indexOf(_compare)"

		_ = _comparableArray.firstIndex(of: _compare)
		_ = "_comparableArray.indexOf(_compare)"

		// Dictionary
		_ = _dictionary.reduce(_any, _closure)
		_ = "_dictionary.entries.fold(initial = _any, operation = _closure)"

		_ = _dictionary.map(_closure2)
		_ = "_dictionary.map _closure2.toMutableList()"

		// TODO: Translate mapValues (Kotlin's takes (Key, Value) as an argument)

		// Int
		_ = Int.max
		_ = "Int.MAX_VALUE"

		_ = Int.min
		_ = "Int.MIN_VALUE"

		_ = min(_int1, _int2)
		_ = "Math.min(_int1, _int2)"

		_ = _int1..._int2
		_ = "_int1.._int2"

		_ = _int1..<_int2
		_ = "_int1 until _int2"

		// Double
		_ = _double1..._double2
		_ = "(_double1).rangeTo(_double2)"

		// Optional
		_ = _optional.map(_closure4)
		_ = "_optional?.let _closure4"
	}


	"""
}
