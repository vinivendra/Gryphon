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
			fromGryphonRawAST: gryphonRawAST)

		return gryphonFirstPassedAST
	}

	public static func runAfterFirstPasses(
		onAST gryphonFirstPassedAST: GryphonAST,
		withSettings settings: Settings,
		onFile inputFilePath: String)
		throws -> Any?
	{
		let gryphonAST = try Compiler.generateGryphonASTAfterSecondPasses(
			fromGryphonRawAST: gryphonFirstPassedAST)
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

		let kotlinCode = try Compiler.generateKotlinCode(fromGryphonAST: gryphonAST)
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

		if let indentationArgument = arguments.first(where: { $0.hasPrefix("-indentation=") }) {
			let indentationString = indentationArgument
				.dropFirst("-indentation=".count)

			if indentationString == "t" {
				KotlinTranslator.indentationString = "\t"
			}
			else if let numberOfSpaces = Int(indentationString) {
				var result = ""
				for _ in 0..<numberOfSpaces {
					result += " "
				}
				KotlinTranslator.indentationString = result
			}
		}

		let horizontalLimit: Int?
		if let lineLimitArgument = arguments.first(where: { $0.hasPrefix("-line-limit=") }) {
			let lineLimitString = lineLimitArgument.dropFirst("-line-limit=".count)
			horizontalLimit = Int(lineLimitString)
		}
		else {
			horizontalLimit = nil
		}

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

		let inputFilePaths = arguments.filter {
			!$0.hasPrefix("-") && $0 != "run" && $0 != "build"
		}

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

		let canPrintToFiles = !arguments.contains("-Q")
		let canPrintToOutput = !arguments.contains("-q")

		let shouldGenerateKotlin = shouldBuild || shouldEmitKotlin
		let shouldGenerateAST = shouldGenerateKotlin || shouldEmitAST
		let shouldGenerateRawAST = shouldGenerateAST || shouldEmitRawAST
		let shouldGenerateSwiftAST = shouldGenerateRawAST || shouldEmitSwiftAST

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
				try runUpToFirstPasses(withSettings: settings, onFile: $0)
			}
		}
		else {
			firstResult = try filteredInputFiles.map {
				try runUpToFirstPasses(withSettings: settings, onFile: $0)
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
					onFile: $0.1)
			}
		}
		else {
			secondResult = try pairsArray.map {
				try runAfterFirstPasses(
					onAST: $0.0,
					withSettings: settings,
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
