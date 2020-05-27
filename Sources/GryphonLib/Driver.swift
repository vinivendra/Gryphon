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

// gryphon output: Sources/GryphonLib/Driver.swiftAST
// gryphon output: Sources/GryphonLib/Driver.gryphonASTRaw
// gryphon output: Sources/GryphonLib/Driver.gryphonAST
// gryphon output: Bootstrap/Driver.kt

public class Driver {
	public static let gryphonVersion = "0.6"

	public static let supportedArguments: List = [
		"help", "-help", "--help",
		"--version",
		"init",
		"clean",
		"generate-libraries",
		"--skip",
		"--no-main-file",
		"--default-final",
		"--continue-on-error",
		"--write-to-console",
		"--verbose",
		"--quiet",
		"--sync",
	]

	public static let supportedArgumentsWithParameters: List = [
		"--indentation=",
		"--toolchain=",
		"-line-limit=",
	]

	public static let debugArguments: List = [
		"-xcode",
		"setup-xcode",
		"make-gryphon-targets",
		"-skip-AST-dumps",
		"-emit-swiftAST",
		"-emit-rawAST",
		"-emit-AST",
		"-emit-kotlin",
		"-print-ASTs-on-error",
		"-avoid-unicode",
	]

	public struct Settings {
		let shouldEmitSwiftAST: Bool
		let shouldEmitRawAST: Bool
		let shouldEmitAST: Bool
		let shouldEmitKotlin: Bool
		let shouldGenerateKotlin: Bool
		let shouldGenerateAST: Bool
		let shouldGenerateRawAST: Bool
		let shouldGenerateSwiftAST: Bool

		let forcePrintingToConsole: Bool
		let quietModeIsOn: Bool

		let mainFilePath: String?
		let xcodeProjectPath: String?
	}

	public struct KotlinTranslation {
		let kotlinFilePath: String?
		let kotlinCode: String
	}

	@discardableResult
	public static func run(
		withArguments arguments: List<String>)
		throws -> Any?
	{
		let badArguments = unsupportedArguments(in: arguments)
		if !badArguments.isEmpty {
			let argumentsString = badArguments.map { "\"\($0)\"" }.joined(separator: ", ")
			throw GryphonError(errorMessage: "Unsupported arguments: \(argumentsString).")
		}

		if arguments.isEmpty ||
			arguments.contains("help") ||
			arguments.contains("-help") ||
			arguments.contains("--help")
		{
			printUsage()
			return nil
		}

		if arguments.contains("--version") {
			printVersion()
			return nil
		}

		let isVerbose = arguments.contains("--verbose")
		Compiler.shouldLogProgress(if: isVerbose)

		if arguments.contains("clean") {
			cleanup()
			Compiler.log("Cleanup successful.")

			if !arguments.contains("init") {
				return nil
			}
		}

		if arguments.contains("generate-libraries") {
			try generateLibraries()
			Compiler.log("Generated Gryphon libraries.")
			return nil
		}

		let toolchain: String?
		if let toolchainArgument = arguments.first(where: { $0.hasPrefix("--toolchain=") }) {
			if OS.osType == .linux {
				throw GryphonError(errorMessage: "Toolchain support is implemented using xcrun, " +
					"which is only available in macOS.")
			}

			let toolchainName = String(toolchainArgument.dropFirst("--toolchain=".count))
			toolchain = toolchainName
		}
		else {
			toolchain = nil
		}
		try TranspilationContext.checkToolchainSupport(toolchain)

		let maybeXcodeProject = getXcodeProject(inArguments: arguments)

		if arguments.contains("init") {
			// The `-xcode` flag forces the initialization to add Xcode files to the
			// Gryphon build folder even if no Xcode project was given. It's currently
			// used only for developing Gryphon.
			let shouldInitializeXcodeFiles = (maybeXcodeProject != nil) ||
				arguments.contains("-xcode")

			try initialize(includingXcodeFiles: shouldInitializeXcodeFiles)

			Compiler.log("Initialization successful.")

			if let xcodeProject = maybeXcodeProject {
				let newArguments: MutableList = [xcodeProject]
				if isVerbose {
					newArguments.append("--verbose")
				}

				let setupArguments: MutableList = ["setup-xcode"]
				setupArguments.append(contentsOf: newArguments)
				_ = try Driver.run(withArguments: setupArguments)

				let makeTargetArguments: MutableList = ["make-gryphon-targets"]
				makeTargetArguments.append(contentsOf: newArguments)
				_ = try Driver.run(withArguments: makeTargetArguments)
			}

			return nil
		}

		if arguments.contains("setup-xcode") {
			guard let xcodeProject = maybeXcodeProject else {
				throw GryphonError(errorMessage:
					"Please specify an Xcode project when using `setup-xcode`.")
			}

			try createASTDumpsScript(
				forXcodeProject: xcodeProject,
				usingToolchain: toolchain,
				simulator: nil)

			Compiler.log("Xcode setup successful.")
			return nil
		}
		if arguments.contains("make-gryphon-targets") {
			guard let xcodeProject = maybeXcodeProject else {
				throw GryphonError(errorMessage:
					"Please specify an Xcode project when using `make-gryphon-targets`.")
			}

			try makeGryphonTargets(forXcodeProject: xcodeProject, usingToolchain: toolchain)
			Compiler.log("Gryphon target creation successful.")
			return nil
		}

		// If there's no build folder, create one, perform the transpilation, then delete it
		if !Utilities.fileExists(at: SupportingFile.gryphonBuildFolder) {
			return try performCompilationWithTemporaryBuildFolder(
				withArguments: arguments,
				usingToolchain: toolchain)
		}
		else {
			return try performCompilation(
				withArguments: arguments,
				usingToolchain: toolchain)
		}
	}

	public static func runUpToFirstPasses(
		withSettings settings: Settings,
		withContext context: TranspilationContext,
		onFile inputFilePath: String)
		throws -> Any?
	{
		guard settings.shouldGenerateSwiftAST else {
			return [] // gryphon value: listOf<Any>()
		}

		let swiftASTDumpFile = SupportingFile.pathOfSwiftASTDumpFile(
			forSwiftFile: inputFilePath,
			swiftVersion: context.swiftVersion)

		let swiftASTDump: String
		do {
			swiftASTDump = try Utilities.readFile(swiftASTDumpFile)
		}
		catch {
			throw GryphonError(errorMessage:
				"Error reading the AST for file \(inputFilePath). " +
				"Running `gryphon init` or `gryphon init <xcode_project>` might fix this issue.")
		}

		// Generate the Swift AST
		let swiftAST = try Compiler.generateSwiftAST(fromASTDump: swiftASTDump)

		guard settings.shouldGenerateRawAST else {
			if settings.shouldEmitSwiftAST, !settings.quietModeIsOn {
				let output = swiftAST.prettyDescription()
				Compiler.output(output)
			}

			return swiftAST
		}

		let isMainFile = (inputFilePath == settings.mainFilePath)

		let gryphonRawAST = try Compiler.generateGryphonRawAST(
			fromSwiftAST: swiftAST,
			asMainFile: isMainFile,
			withContext: context)

		if settings.shouldEmitSwiftAST {
			let output = swiftAST.prettyDescription()
			if let outputFilePath = gryphonRawAST.outputFileMap[.swiftAST],
				!settings.forcePrintingToConsole
			{
				try Utilities.createFile(atPath: outputFilePath, containing: output)
			}
			else if !settings.quietModeIsOn {
				Compiler.output(output)
			}
		}

		if settings.shouldEmitRawAST {
			let output = gryphonRawAST.prettyDescription()
			if let outputFilePath = gryphonRawAST.outputFileMap[.gryphonASTRaw],
				!settings.forcePrintingToConsole
			{
				try Utilities.createFile(atPath: outputFilePath, containing: output)
			}
			else if !settings.quietModeIsOn {
				Compiler.output(output)
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
			let output = gryphonAST.prettyDescription()
			if let outputFilePath = gryphonAST.outputFileMap[.gryphonAST],
				!settings.forcePrintingToConsole
			{
				try Utilities.createFile(atPath: outputFilePath, containing: output)
			}
			else if !settings.quietModeIsOn {
				Compiler.output(output)
			}
		}

		guard settings.shouldGenerateKotlin else {
			return gryphonAST
		}

		let kotlinCode = try Compiler.generateKotlinCode(
			fromGryphonAST: gryphonAST,
			withContext: context)
		if settings.shouldEmitKotlin {
			if settings.forcePrintingToConsole {
				if !settings.quietModeIsOn {
					Compiler.output(kotlinCode)
				}
			}
			else {
				if let outputFilePath = gryphonAST.outputFileMap[.kt] {
					let absoluteFilePath = Utilities.getAbsoultePath(forFile: outputFilePath)
					Compiler.log("Writing to file \(absoluteFilePath)")
					try Utilities.createFile(atPath: outputFilePath, containing: kotlinCode)
				}
				else {
					if settings.xcodeProjectPath != nil {
						// If the user didn't ask to print to console and we're in Xcode but there's
						// no output file, it's likely the user forgot to add an output file
						Compiler.handleWarning(
							message: "No output file path set for \"\(inputFilePath)\"." +
								" Set it with \"// gryphon output: <output file>\".",
							sourceFile: gryphonAST.sourceFile,
							sourceFileRange: SourceFileRange(
								lineStart: 1, lineEnd: 1,
								columnStart: 1, columnEnd: 1))
					}

					if !settings.quietModeIsOn {
						Compiler.output(kotlinCode)
					}
				}
			}
		}

		return KotlinTranslation(
			kotlinFilePath: gryphonAST.outputFileMap[.kt],
			kotlinCode: kotlinCode)
	}

	@discardableResult
	public static func performCompilationWithTemporaryBuildFolder(
		withArguments arguments: List<String>,
		usingToolchain toolchain: String?)
		throws -> Any?
	{
		let isVerbose = arguments.contains("--verbose")

		var result: Any?
		do {
			if isVerbose {
				_ = try Driver.run(withArguments: ["init", "--verbose"])
			}
			else {
				_ = try Driver.run(withArguments: ["init"])
			}
			result = try performCompilation(withArguments: arguments, usingToolchain: toolchain)
		}
		catch let error {
			// Ensure `clean` runs even if an error was thrown
			if isVerbose {
				_ = try Driver.run(withArguments: ["clean", "--verbose"])
			}
			else {
				_ = try Driver.run(withArguments: ["clean"])
			}
			throw error
		}

		// Call `clean` if no errors were thrown
		if isVerbose {
			_ = try Driver.run(withArguments: ["clean", "--verbose"])
		}
		else {
			_ = try Driver.run(withArguments: ["clean"])
		}

		return result
	}

	@discardableResult
	public static func performCompilation(
		withArguments arguments: List<String>,
		usingToolchain toolchain: String?)
		throws -> Any?
	{
		Compiler.clearIssues()

		// Parse arguments
		Compiler.shouldStopAtFirstError = !arguments.contains("--continue-on-error")
		Compiler.shouldAvoidUnicodeCharacters = arguments.contains("-avoid-unicode")

		//
		CompilerIssue.shouldPrintASTs = arguments.contains("-print-ASTs-on-error")

		if let lineLimitArgument = arguments.first(where: { $0.hasPrefix("-line-limit=") }) {
			let lineLimitString = lineLimitArgument.dropFirst("-line-limit=".count)
			printableAsTreeHorizontalLimit = Int(lineLimitString)
		}

		//
		let inputFilePaths = try getInputFilePaths(inArguments: arguments)
		if inputFilePaths.isEmpty {
			throw GryphonError(errorMessage: "No input files provided.")
		}

		//
		let shouldEmitSwiftAST = arguments.contains("-emit-swiftAST")
		let shouldEmitRawAST = arguments.contains("-emit-rawAST")
		let shouldEmitAST = arguments.contains("-emit-AST")

		let hasChosenTask = shouldEmitSwiftAST ||
			shouldEmitRawAST ||
			shouldEmitAST

		let shouldEmitKotlin = !hasChosenTask || arguments.contains("-emit-kotlin")

		//
		let forcePrintingToConsole = arguments.contains("--write-to-console")
		let quietModeIsOn = arguments.contains("--quiet")

		//
		// Note: if we need to print the Swift AST to a file, we need to build the raw Gryphon AST
		// first to get the output file's path from the comments
		let shouldGenerateKotlin = shouldEmitKotlin
		let shouldGenerateAST = shouldGenerateKotlin || shouldEmitAST
		let shouldGenerateRawAST = shouldGenerateAST || shouldEmitRawAST ||
			(shouldEmitSwiftAST && !forcePrintingToConsole)
		let shouldGenerateSwiftAST = shouldGenerateRawAST || shouldEmitSwiftAST

		//
		let mainFilePath: String?
		if arguments.contains("--no-main-file") {
			mainFilePath = nil
		}
		else if inputFilePaths.count == 1 {
			mainFilePath = inputFilePaths[0]
		}
		else {
			mainFilePath = inputFilePaths.first {
				$0.hasSuffix("main.swift")
			}
		}

		//
		let defaultsToFinal = arguments.contains("--default-final")

		//
		let settings = Settings(
			shouldEmitSwiftAST: shouldEmitSwiftAST,
			shouldEmitRawAST: shouldEmitRawAST,
			shouldEmitAST: shouldEmitAST,
			shouldEmitKotlin: shouldEmitKotlin,
			shouldGenerateKotlin: shouldGenerateKotlin,
			shouldGenerateAST: shouldGenerateAST,
			shouldGenerateRawAST: shouldGenerateRawAST,
			shouldGenerateSwiftAST: shouldGenerateSwiftAST,
			forcePrintingToConsole: forcePrintingToConsole,
			quietModeIsOn: quietModeIsOn,
			mainFilePath: mainFilePath,
			xcodeProjectPath: getXcodeProject(inArguments: arguments))

		//
		var indentationString = "    "
		if let indentationArgument = arguments.first(where: { $0.hasPrefix("--indentation=") }) {
			let indentationargument = indentationArgument
				.dropFirst("--indentation=".count)

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
		let shouldRunConcurrently = !arguments.contains("--sync")

		//// Dump the ASTs
		if !arguments.contains("-skip-AST-dumps") {
			let maybeXcodeProject = getXcodeProject(inArguments: arguments)
			let isUsingXcode = (maybeXcodeProject != nil)
			let isSkippingFiles = arguments.contains("--skip")

			if isUsingXcode && isSkippingFiles {
				throw GryphonError(errorMessage: "Argument `--skip` is not supported when " +
					"translating with Xcode support. To skip translation of a file, remove it " +
					"from the `xcfilelist`.")
			}

			let inputFiles = try getInputFilePaths(inArguments: arguments)
			if inputFiles.isEmpty {
				throw GryphonError(errorMessage: "No input files provided.")
			}
			let allSourceFiles = inputFiles.toMutableList()

			if isSkippingFiles {
				let skippedFiles = try getSkippedInputFilePaths(inArguments: arguments)
				allSourceFiles.append(contentsOf: skippedFiles)
			}

			let missingfiles = allSourceFiles.filter {
				!Utilities.fileExists(at: $0)
			}
			if !missingfiles.isEmpty {
				throw GryphonError(errorMessage:
					"File not found: \(missingfiles.joined(separator: ", ")).")
			}

			let swiftVersion = try TranspilationContext.getVersionOfToolchain(toolchain)

			var astDumpsSucceeded = true
			var astDumpError: Error? = nil
			do {
				try updateASTDumps(
					forFiles: allSourceFiles,
					usingXcode: isUsingXcode,
					usingToolchain: toolchain)
				astDumpsSucceeded = true
			}
			catch let error {
				astDumpsSucceeded = false
				astDumpError = error
			}

			let outdatedASTDumpsAfterFirstUpdate = outdatedASTDumpFiles(
				forInputFiles: allSourceFiles,
				swiftVersion: swiftVersion)

			if !astDumpsSucceeded || !outdatedASTDumpsAfterFirstUpdate.isEmpty {
				if let xcodeProject = maybeXcodeProject {
					// If the AST dump update failed and we're using Xcode, it's possible one
					// or more files are missing from the AST dump script. Try updating the
					// script, then try to update the files again.

					if outdatedASTDumpsAfterFirstUpdate.isEmpty {
						Compiler.log("There was an error when with the Swift compiler. " +
							"Attempting to update file list...")
					}
					else {
						Compiler.log("Failed to update some AST dump files: " +
							outdatedASTDumpsAfterFirstUpdate.joined(separator: ", ") +
							". Attempting to update file list...")
					}

					do {
						// If xcodebuild fails, it's better to ignore the error here and fail
						// with an "AST dump failure" message.
						try createASTDumpsScript(
							forXcodeProject: xcodeProject,
							usingToolchain: toolchain,
							simulator: nil)
					}
					catch { }

					try updateASTDumps(
						forFiles: allSourceFiles,
						usingXcode: isUsingXcode,
						usingToolchain: toolchain)

					let outdatedASTDumpsAfterSecondUpdate = outdatedASTDumpFiles(
						forInputFiles: allSourceFiles,
						swiftVersion: swiftVersion)

					if !outdatedASTDumpsAfterSecondUpdate.isEmpty {
						throw GryphonError(
							errorMessage: "Unable to update AST dumps for files: " +
								outdatedASTDumpsAfterSecondUpdate.joined(separator: ", ") + ". " +
							"Make sure the files are being compiled by Xcode.")
					}
				}
				else {
					if !outdatedASTDumpsAfterFirstUpdate.isEmpty {
						throw GryphonError(
							errorMessage: "Unable to update AST dumps for files: " +
								outdatedASTDumpsAfterFirstUpdate.joined(separator: ", ") + ".")
					}
					else if let astDumpError = astDumpError {
						throw GryphonError(
							errorMessage: "Unable to update AST dumps:\n\(astDumpError)")
					}
					else {
						throw GryphonError(
							errorMessage: "Unable to update AST dumps with unknown error.")
					}
				}
			}
		}

		//// Perform transpilation

		do {
			//
			let context = try TranspilationContext(
				toolchainName: toolchain,
				indentationString: indentationString,
				defaultsToFinal: defaultsToFinal)

			Compiler.log("Translating source files...\n")

			let firstResult: List<Any?>
			if shouldRunConcurrently {
				firstResult = try inputFilePaths.parallelMap {
					try runUpToFirstPasses(withSettings: settings, withContext: context, onFile: $0)
				}
			}
			else {
				firstResult = try inputFilePaths.map {
					try runUpToFirstPasses(withSettings: settings, withContext: context, onFile: $0)
				}
			}

			// If we've received a non-raw AST then we're in the middle of the transpilation passes.
			// This means we need to at least run the second round of passes.
			guard let asts = firstResult.as(List<GryphonAST>.self),
				settings.shouldGenerateAST else
			{
				return firstResult
			}

			let pairsArray = zip(asts, inputFilePaths)

			let secondResult: List<Any?>
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

			Compiler.printIssues(skippingWarnings: quietModeIsOn)
			return secondResult
		}
		catch let error {
			Compiler.printIssues(skippingWarnings: quietModeIsOn)
			throw error
		}
	}

	static func outdatedASTDumpFiles(
		forInputFiles inputFiles: List<String>,
		swiftVersion: String)
		-> MutableList<String>
	{
		let result: MutableList<String> = []

		for inputFile in inputFiles {
			let astDumpFile = SupportingFile.pathOfSwiftASTDumpFile(
				forSwiftFile: inputFile,
				swiftVersion: swiftVersion)
			if !Utilities.fileExists(at: astDumpFile) ||
				Utilities.file(inputFile, wasModifiedLaterThan: astDumpFile)
			{
				result.append(inputFile)
			}
		}

		return result
	}

	/// Returns a list of all Swift input files, including those inside xcfilelists, but
	/// excluding any files paths after the `--skip` flag.
	static func getInputFilePaths(
		inArguments arguments: List<String>)
		throws -> MutableList<String>
	{
		let cleanArguments = arguments.map {
				$0.hasSuffix("/") ?
					String($0.dropLast()) :
					$0
			}

		let argumentsBeforeSkip = cleanArguments.prefix {
				$0 != "--skip"
			}

		let result: MutableList<String> = []
		result.append(contentsOf: argumentsBeforeSkip.filter {
			Utilities.getExtension(of: $0) == .swift
		})

		let fileLists = argumentsBeforeSkip.filter {
			Utilities.getExtension(of: $0) == .xcfilelist
		}
		for fileList in fileLists {
			let contents = try Utilities.readFile(fileList)
			let files = contents.split(withStringSeparator: "\n")
			result.append(contentsOf: files)
		}

		return result
	}

	static func getSkippedInputFilePaths(
		inArguments arguments: List<String>)
		throws -> MutableList<String>
	{
		return try getInputFilePaths(inArguments: arguments.reversed())
	}

	static func initialize(includingXcodeFiles: Bool) throws {
		let filesToInitialize: List<SupportingFile>

		if includingXcodeFiles {
			filesToInitialize = SupportingFile.filesForXcodeInitialization
		}
		else {
			filesToInitialize = SupportingFile.filesForInitialization
		}

		for file in filesToInitialize {
			if let contents = file.contents {
				if let folder = file.folder {
					Utilities.createFolderIfNeeded(at: folder)
				}
				try Utilities.createFile(
					atPath: file.relativePath,
					containing: contents)
			}
		}
	}

	static func cleanup() {
		Utilities.deleteFolder(at: SupportingFile.gryphonBuildFolder)
	}

	static func generateLibraries() throws {
		try Utilities.createFile(
			atPath: SupportingFile.gryphonSwiftLibrary.relativePath,
			containing: SupportingFile.gryphonSwiftLibrary.contents!)
		try Utilities.createFile(
			atPath: SupportingFile.gryphonKotlinLibrary.relativePath,
			containing: SupportingFile.gryphonKotlinLibrary.contents!)
	}

	/// Calls xcodebuild to create the AST dump script file. If `simulator` is `nil` and xcodebuild
	/// fails, looks for an installed simulator and tries again recursively.
	static func createASTDumpsScript(
		forXcodeProject xcodeProjectPath: String,
		usingToolchain toolchain: String?,
		simulator: String?)
		throws
	{
		let arguments: MutableList = [
			"xcodebuild",
			"-UseModernBuildSystem=NO",
			"-dry-run",
			"-project",
			"\(xcodeProjectPath)", ]

		if let userToolchain = toolchain {
			arguments.append("-toolchain")
			arguments.append(userToolchain)
		}

		if let simulatorVersion = simulator {
			arguments.append("-sdk")
			arguments.append("iphonesimulator\(simulatorVersion)")
		}

		let commandResult = Shell.runShellCommand(arguments)

		// If something went wrong
		if commandResult.status != 0 {
			// Code signing errors might be solved by forcing a build with the simulator
			if simulator == nil,
				(commandResult.standardError.contains("Code Signing Error:") ||
				 commandResult.standardOutput.contains("Code Signing Error:"))
			{
				// Try to discover the version of an installed simulator
				let sdkCommandResult = Shell.runShellCommand(["xcodebuild", "-showsdks"])
				if sdkCommandResult.status == 0 {
					let output = sdkCommandResult.standardOutput
					let outputLines = output.split(withStringSeparator: "\n")

					// Valid output lines are of the form:
					// 	Simulator - iOS 13.4          	-sdk iphonesimulator13.4
					var maybeiOSVersion: String?
					for line in outputLines {
						if line.contains("iphonesimulator") {
							let components = line.split(withStringSeparator: " ")
							if let simulatorComponent = components.last {
								maybeiOSVersion = String(
									simulatorComponent.dropFirst("iphonesimulator".count))
							}
						}
					}

					if let iOSVersion = maybeiOSVersion {
						try createASTDumpsScript(forXcodeProject: xcodeProjectPath,
							usingToolchain: toolchain,
							simulator: iOSVersion)
						return
					}
				}
			}

			// If we failed to recover, throw an error
			throw GryphonError(errorMessage: "Error running xcodebuild:\n" +
				commandResult.standardOutput +
				commandResult.standardError)
		}

		let output = commandResult.standardOutput
		let buildSteps = output.split(withStringSeparator: "\n\n")
		guard let compileSwiftStep =
			buildSteps.first(where: { $0.hasPrefix("CompileSwiftSources") }) else
		{
			throw GryphonError(errorMessage:
				"Unable to find the Swift compilation command in the Xcode project.")
		}

		let commands = compileSwiftStep.split(withStringSeparator: "\n")

		// Drop the header and the old compilation command
		var result = commands.dropFirst().dropLast().joined(separator: "\n") + "\n"

		// Fix the call to the Swift compiler
		let compilationCommand = commands.last!
		let commandComponents = compilationCommand.splitUsingUnescapedSpaces()

		let newComponents = commandComponents.filter { (argument: String) -> Bool in
			argument != "-incremental" &&
			argument != "-whole-module-optimization" &&
			argument != "-c" &&
			argument != "-parseable-output" &&
			argument != "-output-file-map" &&
			!argument.hasSuffix("OutputFileMap.json") &&
			argument != "-serialize-diagnostics" &&
			!argument.hasSuffix(".swiftmodule") &&
			!argument.hasSuffix("Swift.h") &&
			!argument.hasSuffix("SwiftFileList") &&
			!argument.hasPrefix("-emit")
		}.toMutableList()

		let templatesFilePath = SupportingFile.gryphonTemplatesLibrary.absolutePath
			.replacingOccurrences(of: " ", with: "\\ ")
		newComponents.append(templatesFilePath)

		let escapedOutputFileMapPath = SupportingFile.temporaryOutputFileMap.absolutePath
			.replacingOccurrences(of: " ", with: "\\ ")
		newComponents.append("-output-file-map")
		newComponents.append(escapedOutputFileMapPath)
		newComponents.append("-dump-ast")
		newComponents.append("-D")
		newComponents.append("GRYPHON")

		// Build the resulting command
		result += "\t"
		if let chosenToolchain = toolchain {
			// Set the toolchain manually by replacing the direct call to swiftc with a call to
			// xcrun
			result += "\txcrun -toolchain \"\(chosenToolchain)\" swiftc "
			result += newComponents.dropFirst().joined(separator: " ")
		}
		else {
			// Use the default toolchain
			result += newComponents.joined(separator: " ")
		}
		result += "\n"

		try Utilities.createFile(
			named: SupportingFile.astDumpsScript.name,
			inDirectory: SupportingFile.gryphonBuildFolder,
			containing: result)
	}

	static func makeGryphonTargets(
		forXcodeProject xcodeProjectPath: String,
		usingToolchain toolchain: String?)
		throws
	{
		// Run the ruby script
		let arguments: MutableList = [
			"ruby",
			"\(SupportingFile.makeGryphonTargets.relativePath)",
			"\(xcodeProjectPath)", ]
		if let userToolchain = toolchain {
			arguments.append(userToolchain)
		}

		let commandResult = Shell.runShellCommand(arguments)

		guard commandResult.status == 0 else {
			throw GryphonError(errorMessage: "Error making gryphon targets:\n" +
				commandResult.standardOutput +
				commandResult.standardError)
		}

		// Create the xcfilelist so the user has an easier time finding it and populating it
		_ = Utilities.createFileIfNeeded(at: SupportingFile.xcFileList.relativePath)
	}

	static func updateASTDumps(
		forFiles swiftFiles: List<String>,
		usingXcode: Bool,
		usingToolchain toolchain: String?)
		throws
	{
		//// Create the outputFileMap
		var outputFileMapContents = "{\n"

		let swiftVersion = try TranspilationContext.getVersionOfToolchain(toolchain)

		// Add the swift files
		for swiftFile in swiftFiles {
			let astDumpPath = SupportingFile.pathOfSwiftASTDumpFile(
				forSwiftFile: swiftFile,
				swiftVersion: swiftVersion)
			let astDumpAbsolutePath = Utilities.getAbsoultePath(forFile: astDumpPath)
			let swiftAbsoultePath = Utilities.getAbsoultePath(forFile: swiftFile)
			outputFileMapContents += "\t\"\(swiftAbsoultePath)\": {\n" +
				"\t\t\"ast-dump\": \"\(astDumpAbsolutePath)\",\n" +
				"\t},\n"
		}
		outputFileMapContents += "}\n"

		try Utilities.createFile(
			atPath: SupportingFile.temporaryOutputFileMap.relativePath,
			containing: outputFileMapContents)

		//// Create the necessary folders for the AST dump files
		for swiftFile in swiftFiles {
			let astDumpPath = SupportingFile.pathOfSwiftASTDumpFile(
				forSwiftFile: swiftFile,
				swiftVersion: swiftVersion)
			let folderPath = astDumpPath.split(withStringSeparator: "/")
				.dropLast()
				.joined(separator: "/")
			Utilities.createFolderIfNeeded(at: folderPath)
		}

		//// Call the Swift compiler to dump the ASTs
		let commandResult: Shell.CommandOutput

		Compiler.log("Calling the Swift compiler...")
		if usingXcode {
			commandResult = Shell.runShellCommand(
				["bash", SupportingFile.astDumpsScript.relativePath])
		}
		else {
			let arguments: MutableList<String> = []

			if OS.osType == .macOS {
				arguments.append("xcrun")
			}

			if let chosenToolchainName = toolchain, chosenToolchainName != "" {
				arguments.append("-toolchain")
				arguments.append(chosenToolchainName)
			}

			arguments.append("swiftc")
			arguments.append("-dump-ast")
			arguments.append("-module-name")
			arguments.append("Main")
			arguments.append("-D")
			arguments.append("GRYPHON")
			arguments.append(
				"-output-file-map=\(SupportingFile.temporaryOutputFileMap.absolutePath)")

			for swiftFile in swiftFiles {
				arguments.append(Utilities.getAbsoultePath(forFile: swiftFile))
			}

			commandResult = Shell.runShellCommand(arguments)
		}

		guard commandResult.status == 0 else {
			var errorMessage = "Error calling the Swift compiler.\n"

			// Suggest solutions to known problems
			if commandResult.standardError.contains("statements are not allowed at the top level") {
				errorMessage.append(
					"This may have happened because top-level statements are only allowed " +
					"if the file is called \"main.swift\".\n")
			}
			else if commandResult.standardError.contains(
				".gryphon/updateASTDumps.sh: No such file or directory")
			{
				errorMessage.append(
					"Try running `gryphon init <xcode project>` to fix this problem.\n")
			}

			errorMessage.append("Swift compiler output:\n\n" +
				commandResult.standardOutput +
				commandResult.standardError)
			throw GryphonError(errorMessage: errorMessage)
		}
	}

	static func unsupportedArguments(in arguments: List<String>) -> List<String> {
		// Start with all arguments, remove the ones that are OK, return what's left
		var badArguments = arguments
		badArguments = badArguments.filter { !supportedArguments.contains($0) }
		badArguments = badArguments.filter { !debugArguments.contains($0) }
		badArguments = badArguments.filter { !isSupportedArgumentWithParameters($0) }
		badArguments = badArguments.filter { !isXcodeProject($0) }
		badArguments = badArguments.filter { !isSupportedInputFilePath($0) }
		return badArguments
	}

	static func isSupportedArgumentWithParameters(_ argument: String) -> Bool {
		for supportedArgumentWithParameters in supportedArgumentsWithParameters {
			if argument.hasPrefix(supportedArgumentWithParameters) {
				return true
			}
		}
		return false
	}

	/// Returns true if it's a swift file or a list of swift files
	static func isSupportedInputFilePath(_ filePath: String) -> Bool {
		if let fileExtension = Utilities.getExtension(of: filePath) {
			if fileExtension == .swift ||
				fileExtension == .xcfilelist
			{
				return true
			}
		}
		return false
	}

	static func isXcodeProject(_ filePath: String) -> Bool {
		let cleanPath = filePath.hasSuffix("/") ? String(filePath.dropLast()) : filePath
		return Utilities.fileHasExtension(cleanPath, .xcodeproj)
	}

	static func getXcodeProject(inArguments arguments: List<String>) -> String? {
		if let xcodeProject = arguments.first(where: { isXcodeProject($0) }) {
			let cleanPath = xcodeProject.hasSuffix("/") ?
				String(xcodeProject.dropLast()) :
				xcodeProject
			return cleanPath
		}
		return nil
	}

	static func printVersion() {
		Compiler.output("Gryphon version \(gryphonVersion)")
	}

	static func printUsage() {
		Compiler.output(usageString)
	}

	/// This string should be limited to be 80 characters wide to fit the terminal standard.
	/// It should also be indented using spaces to ensure the spacing is correct in different
	/// terminals.
    static let usageString = """
-- Gryphon transpiler --
Version \(gryphonVersion)

  Running this command with "help", "-help" or "--help" displays the
  message below.
  Running it with "--version" displays the current version.

Main usage:

  - Initialization
      gryphon init [xcode project] [options]

  - Translation
      gryphon [xcode project] [options] [input file paths]

  Notes:
      - Including the path of an Xcode project makes initialization and
        translation compatible with Xcode. Omit the Xcode project when
        translating standalone Swift files.
      - Input file paths may be:
        - Paths to .swift source files.
        - Paths to .xcfilelist files, which may contain paths to actual .swift
          source files separated by newlines.

  Options:
      ↪️  --skip
            Input files after this option will not be translated. Use this to
            specify files that have to be compiled by Swift but don't have to be
            translated by Gryphon.

      ↪️  --no-main-file
            Do not generate a Kotlin file with a "main" function. This is
            implied if translating files from an Xcode project.

      ↪️  --default-final
            Kotlin declarations will be "final" by default instead of "open".

      ↪️  --continue-on-error
            Continue translating even if errors are found.

      ↪️  --write-to-console
            Write the output of any translations to the console (instead of
            the specified output files).

      ↪️  --quiet
            Do not output translations to the console. If this is specified
            along with `--write-to-console`, no translations will be written
            anywhere. Also mutes warnings, but not errors.

      ↪️  --indentation=<N>
            Specify the indentation to be used in the output Kotlin files. Use
            "t" for tabs or an integer for the corresponding number of spaces.
            Defaults to four spaces.

      ↪️  --verbose
            Print more information to the console.

      ↪️  --sync
            Do not use concurrency.

      ↪️  --toolchain=<toolchain name>
            Specify the toolchain to be used when calling the Swift compiler.

Advanced subcommands:
  ➡️  clean
        Clean Gryphon's build folder in the local directory.

  ➡️  generate-libraries
        Creates a copy of the Gryphon Swift library and one of the Gryphon
        Kotlin Library in the current folder. Add these files to your Swift and
        Kotlin projects (respectively) to avoid some compilation and runtime
        errors.

  ➡️  setup-xcode <Xcode project>
        Configures Gryphon's build folder to be used with the given Xcode
        project. Only needed if `gryphon init` was used without specifying an
        Xcode project.

  ➡️  make-gryphon-targets <Xcode project>
        Adds auxiliary targets to the given Xcode project. Only needed if
        `gryphon init` was used without specifying an Xcode project.

Advanced translation options:
      ↪️  -skip-AST-dumps
            Skip calling the Swift compiler to update the AST dumps (i.e. if the
            Swift sources haven't changed since the last translation).

      ↪️  -emit-swiftAST
            Emit the Swift AST (an intermediate representation) either to a file
            ending in ".swiftAST" specified by a "// gryphon output: " comment
            or to the console if there isn't one.
      ↪️  -emit-rawAST
            Emit the raw Gryphon AST (an intermediate representation) either to
            a file ending in ".gryphonASTRaw" specified by a
            "// gryphon output: " comment or to the console if there isn't one.
      ↪️  -emit-AST
            Emit the processed Gryphon AST (an intermediate representation)
            either to a file ending in ".gryphonAST" specified by a
            "// gryphon output: " comment or to the console if there isn't one.
      ↪️  -emit-kotlin
            Emit the Kotlin output either to a file ending in ".kt" specified by
            a "// gryphon output: " comment or to the console if there isn't
            one. This is the default if no other `-emit` options are used.

      ↪️  -print-ASTs-on-error
            Include the ASTs for the relevant statements or expressions when
            printing errors.
      ↪️  -line-limit=<N>
            Limit the maximum horizontal size when printing ASTs. Useful so
            the text doesn't wrap and break the AST lines.

      ↪️  -avoid-unicode
            Avoid using Unicode arrows and emojis in some places.
"""
}
