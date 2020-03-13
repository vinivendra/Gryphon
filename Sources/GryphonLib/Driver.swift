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

// gryphon output: Sources/GryphonLib/Driver.swiftAST
// gryphon output: Sources/GryphonLib/Driver.gryphonASTRaw
// gryphon output: Sources/GryphonLib/Driver.gryphonAST
// gryphon output: Bootstrap/Driver.kt

public class Driver {
	public static let gryphonVersion = "0.4-beta"

	public static let supportedArguments: List = [
		"help", "-help", "--help",
		"--version",
		"init",
		"clean",
		"--skip",
		"--no-main-file",
		"--default-final",
		"--continue-on-error",
		"--write-to-console",
		"--verbose",
		"--sync",
	]

	public static let supportedArgumentsWithParameters: List = [
		"--indentation=",
		"-line-limit=",
	]

	public static let debugArguments: List = [
		"--xcode",
		"-setupXcode",
		"-makeGryphonTargets",
		"-skipASTDumps",
		"-emit-swiftAST",
		"-emit-rawAST",
		"-emit-AST",
		"-emit-kotlin",
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

		let shouldPrintToConsole: Bool

		let horizontalLimit: Int?

		let mainFilePath: String?
	}

	public struct KotlinTranslation {
		let kotlinFilePath: String?
		let kotlinCode: String
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

		let swiftASTDumpFile = SupportingFile.pathOfSwiftASTDumpFile(forSwiftFile: inputFilePath)

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
		if settings.shouldEmitSwiftAST {
			let output = swiftAST.prettyDescription(
				horizontalLimit: settings.horizontalLimit)
			print(output)
		}

		guard settings.shouldGenerateRawAST else {
			return swiftAST
		}

		let isMainFile = (inputFilePath == settings.mainFilePath)

		let gryphonRawAST = try Compiler.generateGryphonRawAST(
			fromSwiftAST: swiftAST,
			asMainFile: isMainFile,
			withContext: context)

		if settings.shouldEmitSwiftAST {
			let output = swiftAST.prettyDescription(
				horizontalLimit: settings.horizontalLimit)
			if let outputFilePath = gryphonRawAST.outputFileMap[.swiftAST],
				!settings.shouldPrintToConsole
			{
				try Utilities.createFile(atPath: outputFilePath, containing: output)
			}
		}

		if settings.shouldEmitRawAST {
			let output = gryphonRawAST.prettyDescription(
				horizontalLimit: settings.horizontalLimit)
			if let outputFilePath = gryphonRawAST.outputFileMap[.gryphonASTRaw],
				!settings.shouldPrintToConsole
			{
				try Utilities.createFile(atPath: outputFilePath, containing: output)
			}
			else {
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
			if let outputFilePath = gryphonAST.outputFileMap[.gryphonAST],
				!settings.shouldPrintToConsole
			{
				try Utilities.createFile(atPath: outputFilePath, containing: output)
			}
			else {
				print(output)
			}
		}

		guard settings.shouldGenerateKotlin else {
			return gryphonAST
		}

		let kotlinCode = try Compiler.generateKotlinCode(
			fromGryphonAST: gryphonAST,
			withContext: context)
		if let outputFilePath = gryphonAST.outputFileMap[.kt],
			!settings.shouldPrintToConsole
		{
			let absoluteFilePath = Utilities.getAbsoultePath(forFile: outputFilePath)
			Compiler.log("Writing to file \(absoluteFilePath)")
			try Utilities.createFile(atPath: outputFilePath, containing: kotlinCode)
		}
		else {
			if settings.shouldEmitKotlin {
				print(kotlinCode)
			}
		}

		return KotlinTranslation(
			kotlinFilePath: gryphonAST.outputFileMap[.kt],
			kotlinCode: kotlinCode)
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

		if arguments.contains("init") {
			let maybeXcodeProject = getXcodeProject(inArguments: arguments)

			// The `--xcode` flag forces the initialization to add Xcode files to the
			// Gryphon build folder even if no Xcode project was given. It's currently
			// used only for developing Gryphon.
			let shouldInitializeXcodeFiles = (maybeXcodeProject != nil) ||
				arguments.contains("--xcode")

			try initialize(includingXcodeFiles: shouldInitializeXcodeFiles)

			Compiler.log("Initialization successful.")

			if let xcodeProject = maybeXcodeProject {
				if isVerbose {
					_ = try Driver.run(withArguments:
						["-setupXcode", "--verbose", xcodeProject])
					_ = try Driver.run(withArguments:
						["-makeGryphonTargets", "--verbose", xcodeProject])
				}
				else {
					_ = try Driver.run(withArguments:
						["-setupXcode", xcodeProject])
					_ = try Driver.run(withArguments:
						["-makeGryphonTargets", xcodeProject])
				}
			}

			return nil
		}

		if arguments.contains("-setupXcode") {
			guard let xcodeProject = getXcodeProject(inArguments: arguments) else {
				throw GryphonError(errorMessage:
					"Please specify an Xcode project when using `-setupXcode`.")
			}

			try setupGryphonFolder(forXcodeProject: xcodeProject)
			Compiler.log("Xcode setup successful.")
			return nil
		}
		if arguments.contains("-makeGryphonTargets") {
			guard let xcodeProject = getXcodeProject(inArguments: arguments) else {
				throw GryphonError(errorMessage:
					"Please specify an Xcode project when using `-makeGryphonTargets`.")
			}

			try makeGryphonTargets(forXcodeProject: xcodeProject)
			Compiler.log("Gryphon target creation successful.")
			return nil
		}

		// If there's no build folder, create one, perform the transpilation, then delete it
		if !Utilities.fileExists(at: SupportingFile.gryphonBuildFolder) {
			return try performCompilationWithTemporaryBuildFolder(withArguments: arguments)
		}
		else {
			return try performCompilation(withArguments: arguments)
		}
	}

	@discardableResult
	public static func performCompilationWithTemporaryBuildFolder(
		withArguments arguments: List<String>) throws -> Any?
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
			result = try performCompilation(withArguments: arguments)
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
		withArguments arguments: List<String>) throws -> Any?
	{
		defer {
			Compiler.printErrorsAndWarnings()
		}

		Compiler.clearIssues()

		// Parse arguments
		Compiler.shouldStopAtFirstError = !arguments.contains("--continue-on-error")
		Compiler.shouldAvoidUnicodeCharacters = arguments.contains("-avoid-unicode")

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
		let shouldPrintToConsole = arguments.contains("--write-to-console")

		//
		// Note: if we need to print the Swift AST to a file, we need to build the raw Gryphon AST
		// first to get the output file's path from the comments
		let shouldGenerateKotlin = shouldEmitKotlin
		let shouldGenerateAST = shouldGenerateKotlin || shouldEmitAST
		let shouldGenerateRawAST = shouldGenerateAST || shouldEmitRawAST ||
			(shouldEmitSwiftAST && !shouldPrintToConsole)
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
		let defaultFinal = arguments.contains("--default-final")

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
			shouldPrintToConsole: shouldPrintToConsole,
			horizontalLimit: horizontalLimit,
			mainFilePath: mainFilePath)

		//
		var indentationString = "\t"
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
		if !arguments.contains("-skipASTDumps") {
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

			try updateASTDumps(
				forFiles: allSourceFiles,
				usingXcode: isUsingXcode)

			// Check that all AST dump files have been updated successfully
			let outdatedASTDumps = outdatedASTDumpFiles(forInputFiles: allSourceFiles)
			if !outdatedASTDumps.isEmpty {

				if let xcodeProject = maybeXcodeProject {
					// If the AST dumps are out-of-date and we're using Xcode, it's possible one or
					// more files are missing from the AST dump script. Try updating the script,
					// then try to update the files again.

					Compiler.log("Failed to update some AST dump files: " +
						outdatedASTDumps.joined(separator: ", ") +
						". Attempting to update file list...")

					try setupGryphonFolder(forXcodeProject: xcodeProject)

					try updateASTDumps(
						forFiles: allSourceFiles,
						usingXcode: isUsingXcode)

					let newOutdatedASTDumps = outdatedASTDumpFiles(forInputFiles: allSourceFiles)

					if !newOutdatedASTDumps.isEmpty {
						throw GryphonError(errorMessage: "Unable to update AST dumps for files: " +
							newOutdatedASTDumps.joined(separator: ", ") + ". " +
							"Make sure the files are being compiled by Xcode.")
					}
				}
				else {
					throw GryphonError(errorMessage: "Unable to update AST dumps for files: " +
						outdatedASTDumps.joined(separator: ", ") + ".")
				}
			}
		}

		//// Perform transpilation

		//
		Compiler.log("Updating libraries...")
		let context = TranspilationContext(
			indentationString: indentationString,
			defaultFinal: defaultFinal)

		//
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

		return secondResult
	}

	static func getXcodeProject(inArguments arguments: List<String>) -> String? {
		return arguments.first { Utilities.fileHasExtension($0, .xcodeproj) }
	}

	static func outdatedASTDumpFiles(
		forInputFiles inputFiles: List<String>)
		-> MutableList<String>
	{
		let result: MutableList<String> = []

		for inputFile in inputFiles {
			let astDumpFile = SupportingFile.pathOfSwiftASTDumpFile(forSwiftFile: inputFile)
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

	static func setupGryphonFolder(forXcodeProject xcodeProjectPath: String) throws {
		guard let commandResult = Shell.runShellCommand([
			"xcodebuild",
			"-dry-run",
			"-project",
			"\(xcodeProjectPath)", ]) else
		{
			throw GryphonError(errorMessage: "Failed to run xcodebuild")
		}

		guard commandResult.status == 0 else {
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
			!argument.hasPrefix("-emit")
		}.toMutableList()

		let templatesFilePath = SupportingFile.gryphonTemplatesLibrary.absolutePath
		newComponents.append(templatesFilePath)

		let escapedOutputFileMapPath = SupportingFile.temporaryOutputFileMap.relativePath
			.replacingOccurrences(of: " ", with: "\\ ")
		newComponents.append("-output-file-map")
		newComponents.append(escapedOutputFileMapPath)
		newComponents.append("-dump-ast")
		newComponents.append("-D")
		newComponents.append("GRYPHON")
		let newCompilationCommand = newComponents.joined(separator: " ")

		// Drop the header and the old compilation command
		var scriptContents = commands.dropFirst().dropLast().joined(separator: "\n")
		scriptContents += "\n" + newCompilationCommand + "\n"
		try Utilities.createFile(
			named: SupportingFile.astDumpsScript.name,
			inDirectory: SupportingFile.gryphonBuildFolder,
			containing: scriptContents)
	}

	static func makeGryphonTargets(forXcodeProject xcodeProjectPath: String) throws {
		// Run the ruby script
		guard let commandResult =
			Shell.runShellCommand([
				"ruby",
				"\(SupportingFile.makeGryphonTargets.relativePath)",
				"\(xcodeProjectPath)", ]) else
		{
			throw GryphonError(errorMessage: "Failed to make gryphon targets")
		}

		guard commandResult.status == 0 else {
			throw GryphonError(errorMessage: "Error making gryphon targets:\n" +
				commandResult.standardOutput +
				commandResult.standardError)
		}

		// Create the xcfilelist so the user has an easier time finding it and populating it
		_ = Utilities.createFileIfNeeded(at: SupportingFile.xcFileList.relativePath)
	}

	static func updateASTDumps(forFiles swiftFiles: List<String>, usingXcode: Bool) throws {
		//// Create the outputFileMap
		var outputFileMapContents = "{\n"

		// Add the swift files
		for swiftFile in swiftFiles {
			let astDumpPath = SupportingFile.pathOfSwiftASTDumpFile(forSwiftFile: swiftFile)
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
			let astDumpPath = SupportingFile.pathOfSwiftASTDumpFile(forSwiftFile: swiftFile)
			let folderPath = astDumpPath.split(withStringSeparator: "/")
				.dropLast()
				.joined(separator: "/")
			Utilities.createFolderIfNeeded(at: folderPath)
		}

		//// Call the Swift compiler to dump the ASTs
		let maybeCommandResult: Shell.CommandOutput?

		Compiler.log("Calling the Swift compiler...")
		if usingXcode {
			maybeCommandResult = Shell.runShellCommand(
				["bash", SupportingFile.astDumpsScript.relativePath],
				timeout: nil)
		}
		else {
			let arguments: MutableList = [
				"swiftc",
				"-dump-ast",
				"-module-name", "Main",
				"-D", "GRYPHON",
				"-output-file-map=\(SupportingFile.temporaryOutputFileMap.absolutePath)", ]
			for swiftFile in swiftFiles {
				arguments.append(Utilities.getAbsoultePath(forFile: swiftFile))
			}

			maybeCommandResult = Shell.runShellCommand(
				arguments,
				timeout: nil)
		}

		guard let commandResult = maybeCommandResult else {
			throw GryphonError(errorMessage: "Failed to call the Swift compiler.")
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
		badArguments = badArguments.filter { isSupportedArgumentWithParameters($0) }
		badArguments = badArguments.filter { isSupportedInputFilePath($0) }
		badArguments = badArguments.filter { !Utilities.fileHasExtension($0, .xcodeproj) }
		return badArguments
	}

	static func isSupportedArgumentWithParameters(_ argument: String) -> Bool {
		for supportedArgumentWithParameters in supportedArgumentsWithParameters {
			if argument.hasPrefix(supportedArgumentWithParameters) {
				return false
			}
		}
		return true
	}

	static func isSupportedInputFilePath(_ filePath: String) -> Bool {
		if let fileExtension = Utilities.getExtension(of: filePath) {
			if fileExtension == .swift ||
				fileExtension == .xcfilelist
			{
				return false
			}
		}
		return true
	}

	static func printVersion() {
		print("Gryphon version \(gryphonVersion)")
	}

	static func printUsage() {
		print(usageString)
	}

    static let usageString = """
		-- Gryphon transpiler --
		Version \(gryphonVersion)

		  Running this command with "help", "-help" or "--help" displays the
		  message below.
		  Running it with "--version" displays the current version.

		Main usage:

		  - Initialization
		      gryphon init [xcode project]

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

		      ↪️  --indentation=<N>
		            Specify the indentation to be used in the output Kotlin files. Use
		            "t" for tabs or an integer for the corresponding number of spaces.
		            Defaults to tabs.

		      ↪️  --verbose
		            Print more information to the console.

		      ↪️  --sync
		            Do not use concurrency.

		Advanced commands:
		  ➡️  clean
		        Clean Gryphon's build folder in the local directory.

		  ➡️  -setupXcode <Xcode project>
		        Configures Gryphon's build folder to be used with the given Xcode
		        project. Only needed if `gryphon init` was used without specifying an
		        Xcode project.

		  ➡️  -makeGryphonTargets <Xcode project>
		        Adds auxiliary targets to the given Xcode project. Only needed if
		        `gryphon init` was used without specifying an Xcode project.

		Advanced translation options:
		      ↪️  -skipASTDumps
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

		      ↪️  -line-limit=<N>
		            Limit the maximum horizontal size when printing ASTs.

		      ↪️  -avoid-unicode
		            Avoid using Unicode arrows and emojis in some places.
		"""
}
