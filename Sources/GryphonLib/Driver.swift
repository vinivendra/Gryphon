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

public enum Driver {
	@discardableResult
	public static func run(
		withArguments arguments: [String] = Array(CommandLine.arguments.dropFirst())) throws -> Any?
	{
		Compiler.clearErrorsAndWarnings()

		defer {
			if arguments.contains("-summarize-errors") {
				Compiler.printErrorStatistics()
			}
			else {
				Compiler.printErrorsAndWarnings()
			}
		}

		// Parse arguments
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

		let shouldGenerateKotlin = shouldBuild || shouldEmitKotlin
		let shouldGenerateAST = shouldGenerateKotlin || shouldEmitAST
		let shouldGenerateRawAST = shouldGenerateAST || shouldEmitRawAST
		let shouldGenerateSwiftAST = shouldGenerateRawAST || shouldEmitSwiftAST

		Compiler.shouldLogProgress = arguments.contains("-verbose")
		Compiler.shouldStopAtFirstError = !arguments.contains("-continue-on-error")

		let horizontalLimit: Int?
		if let lineLimitArgument = arguments.first(where: { $0.hasPrefix("-line-limit=") }) {
			let lineLimitString = lineLimitArgument.dropFirst("-line-limit=".count)
			horizontalLimit = Int(lineLimitString)
		}
		else {
			horizontalLimit = nil
		}

		let outputFileMap: OutputFileMap?
		if let outputFileMapArgument = arguments.first(where: { $0.hasPrefix("-output-file-map=") })
		{
			let outputFileMapPath = outputFileMapArgument.dropFirst("-output-file-map=".count)
			outputFileMap = OutputFileMap(String(outputFileMapPath))
		}
		else {
			outputFileMap = nil
		}

		let outputFolder: String
		if let outputFolderIndex = arguments.index(of: "-o"),
			let maybeOutputFolder = arguments[safe: outputFolderIndex + 1]
		{
			outputFolder = maybeOutputFolder
		}
		else {
			outputFolder = OS.buildFolder
		}

		let inputFilePaths = arguments.filter { !$0.hasPrefix("-") && $0 != "run" && $0 != "build" }

		// Run compiler steps
		guard shouldGenerateSwiftAST else {
			return nil
		}

		let astDumpFilesFromOutputFileMap = inputFilePaths.compactMap { inputFile -> String? in
			if inputFile.hasSuffix(".swiftASTDump") {
				return inputFile
			}
			else if inputFile.hasSuffix(".swift"),
				let astDumpFile = outputFileMap?.getOutputFile(
					forInputFile: inputFile, outputType: .astDump)
			{
				return astDumpFile
			}
			else {
				return nil
			}
		}

		let swiftASTDumpFiles = !astDumpFilesFromOutputFileMap.isEmpty ?
			astDumpFilesFromOutputFileMap :
			inputFilePaths.filter { $0.hasSuffix(".swift") }
				.map { Utilities.changeExtension(of: $0, to: .swiftASTDump) }

		let swiftASTDumps = try swiftASTDumpFiles.map { try Utilities.readFile($0) }

		let swiftASTs = try swiftASTDumps.map { try Compiler.generateSwiftAST(fromASTDump: $0) }
		if shouldEmitSwiftAST {
			for (swiftFilePath, swiftAST) in zip(inputFilePaths, swiftASTs) {
				let output = swiftAST.prettyDescription(horizontalLimit: horizontalLimit)
				if let outputFilePath =
					outputFileMap?.getOutputFile(forInputFile: swiftFilePath, outputType: .swiftAST)
				{
					Utilities.createFile(atPath: outputFilePath, containing: output)
				}
				else {
					print(output)
				}
			}
		}

		guard shouldGenerateRawAST else {
			return swiftASTs
		}

		let gryphonRawASTs = try Compiler.generateGryphonRawASTs(fromSwiftASTs: swiftASTs)
		if shouldEmitRawAST {
			for (swiftFilePath, gryphonRawAST) in zip(inputFilePaths, gryphonRawASTs) {
				let output = gryphonRawAST.prettyDescription(horizontalLimit: horizontalLimit)
				if let outputFilePath = outputFileMap?.getOutputFile(
					forInputFile: swiftFilePath, outputType: .gryphonASTRaw)
				{
					Utilities.createFile(atPath: outputFilePath, containing: output)
				}
				else {
					print(output)
				}
			}
		}

		guard shouldGenerateAST else {
			return gryphonRawASTs
		}

		let gryphonASTs = try Compiler.generateGryphonASTs(fromGryphonRawASTs: gryphonRawASTs)
		if shouldEmitAST {
			for (swiftFilePath, gryphonAST) in zip(inputFilePaths, gryphonASTs) {
				let output = gryphonAST.prettyDescription(horizontalLimit: horizontalLimit)
				if let outputFilePath = outputFileMap?.getOutputFile(
					forInputFile: swiftFilePath, outputType: .gryphonAST)
				{
					Utilities.createFile(atPath: outputFilePath, containing: output)
				}
				else {
					print(output)
				}
			}
		}

		guard shouldGenerateKotlin else {
			return gryphonASTs
		}

		let kotlinCodes = try Compiler.generateKotlinCode(fromGryphonASTs: gryphonASTs)
		for (swiftFilePath, kotlinCode) in zip(inputFilePaths, kotlinCodes) {
			let output = kotlinCode
			if let outputFilePath = outputFileMap?.getOutputFile(
				forInputFile: swiftFilePath, outputType: .kotlin)
			{
				Utilities.createFile(atPath: outputFilePath, containing: output)
			}
			else {
				if shouldEmitKotlin {
					print(output)
				}
			}
		}

		guard shouldBuild else {
			return kotlinCodes
		}

		let generatedKotlinFiles = inputFilePaths.compactMap {
			outputFileMap?.getOutputFile(forInputFile: $0, outputType: .kotlin)
		}
		let inputKotlinFiles = inputFilePaths.filter { $0.hasSuffix(".kt") }
		let kotlinFiles = generatedKotlinFiles + inputKotlinFiles

		let compilationResult =
			try Compiler.compile(kotlinFiles: kotlinFiles, outputFolder: outputFolder)

		if case .failure = compilationResult {
			return compilationResult
		}

		guard shouldRun else {
			return compilationResult
		}

		let runResult = try Compiler.runCompiledProgram(fromFolder: outputFolder)

		return runResult
	}
}
