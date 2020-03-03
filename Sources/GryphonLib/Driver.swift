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

	public static let supportedArguments: List<String> = [
		"help", "-help", "--help",
		"--version",
		"init",
		"clean",
		"-o",
		"--no-main-file",
		"--default-final",
		"--continue-on-error",
		"--write-to-console",
		"--verbose",
		"--sync",
	]

	public static let supportedArgumentsWithParameters: List<String> = [
		"--indentation=",
		"-line-limit=",
	]

	public static let debugArguments: List<String> = [
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

	public struct DriverError: Error, CustomStringConvertible {
		let errorMessage: String

		public var description: String {
			return errorMessage
		}
	}

	public static func runUpToFirstPasses(
		withSettings settings: Settings,
		withContext context: TranspilationContext,
		onFile inputFilePath: String) throws -> Any?
	{
		guard settings.shouldGenerateSwiftAST else {
			return [] // gryphon value: mutableListOf<Any>()
		}

		let swiftASTDumpFile = getASTDump(forFile: inputFilePath)!

		let swiftASTDump = try Utilities.readFile(swiftASTDumpFile)

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
				Utilities.createFile(atPath: outputFilePath, containing: output)
			}
		}

		if settings.shouldEmitRawAST {
			let output = gryphonRawAST.prettyDescription(
				horizontalLimit: settings.horizontalLimit)
			if let outputFilePath = gryphonRawAST.outputFileMap[.gryphonASTRaw],
				!settings.shouldPrintToConsole
			{
				Utilities.createFile(atPath: outputFilePath, containing: output)
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
				Utilities.createFile(atPath: outputFilePath, containing: output)
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
			Utilities.createFile(atPath: outputFilePath, containing: kotlinCode)
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
		withArguments arguments: MutableList<String>) throws -> Any?
	{
		let badArguments = unsupportedArguments(in: arguments)
		if !badArguments.isEmpty {
			let argumentsString = badArguments.map { "\"\($0)\"" }.joined(separator: ", ")
			throw DriverError(errorMessage: "Unsupported arguments: \(argumentsString).")
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

		if arguments.contains("clean") {
			cleanup()
			print("Cleanup successful.")

			if !arguments.contains("init") {
				return nil
			}
		}

		let inputFiles = getInputFilePaths(inArguments: arguments)

		if arguments.contains("init") {
			initialize()
			print("Initialization successful.")

			let xcodeProjects = inputFiles.filter {
					Utilities.getExtension(of: $0) == .xcodeproj
				}

			if let xcodeProject = xcodeProjects.first {
				_ = try Driver.run(withArguments: ["-setupXcode", xcodeProject])
				_ = try Driver.run(withArguments: ["-makeGryphonTargets", xcodeProject])
			}

			return nil
		}

		if arguments.contains("-setupXcode") {
			let xcodeProjects = inputFiles.filter {
					Utilities.getExtension(of: $0) == .xcodeproj
				}

			guard let xcodeProject = xcodeProjects.first else {
				throw DriverError(errorMessage:
					"please specify an Xcode project when using `-setupXcode`.")
			}

			let success = setupGryphonFolder(forXcodeProject: xcodeProject)
			if success {
				print("AST dump script creation successful.")
				return nil
			}
			else {
				throw DriverError(errorMessage: "AST dump script creation failed.")
			}
		}
		if arguments.contains("-makeGryphonTargets") {
			let xcodeProjects = inputFiles.filter {
					Utilities.getExtension(of: $0) == .xcodeproj
				}

			guard let xcodeProject = xcodeProjects.first else {
				throw DriverError(errorMessage:
					"please specify an Xcode project when using `-makeGryphonTargets`.")
			}

			let success = makeGryphonTargets(forXcodeProject: xcodeProject)
			if success {
				print("Gryphon target creation successful.")
				return nil
			}
			else {
				throw DriverError(errorMessage: "Gryphon target creation failed.")
			}
		}

		if !arguments.contains("-skipASTDumps") {
			let inputFiles = getInputFilePaths(inArguments: arguments)
			if inputFiles.isEmpty {
				throw DriverError(errorMessage: "No input files provided.")
			}
			let swiftFiles = inputFiles.filter {
				Utilities.getExtension(of: $0) == .swift
			}
			let success = updateASTDumps(forFiles: swiftFiles)
			if !success {
				throw DriverError(errorMessage: "AST dump failed.")
			}
		}

		return try performCompilation(withArguments: arguments)
	}

	@discardableResult
	public static func performCompilation(
		withArguments arguments: MutableList<String>) throws -> Any?
	{
		defer {
			Compiler.printErrorsAndWarnings()
		}

		Compiler.clearIssues()

		// Parse arguments
		Compiler.shouldLogProgress(if: arguments.contains("--verbose"))
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
		let inputFilePaths = getInputFilePaths(inArguments: arguments)
		if inputFilePaths.isEmpty {
			throw DriverError(errorMessage: "No input files provided.")
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
				$0.hasSuffix("main.swift") || $0.hasSuffix("main.swiftASTDump")
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
		let context = TranspilationContext(
			indentationString: indentationString,
			defaultFinal: defaultFinal)

		//
		let shouldRunConcurrently = !arguments.contains("--sync")

		// Update libraries syncronously to guarantee it's only done once
		if shouldGenerateAST {
			try Utilities.processGryphonTemplatesLibrary()
		}

		// Run compiler steps
		let filteredInputFiles = inputFilePaths.filter {
			Utilities.fileHasExtension($0, .swift) || Utilities.fileHasExtension($0, .swiftASTDump)
		}

		let firstResult: MutableList<Any?>
		if shouldRunConcurrently {
			firstResult = try filteredInputFiles.parallelMap {
				try runUpToFirstPasses(withSettings: settings, withContext: context, onFile: $0)
			}
		}
		else {
			firstResult = try filteredInputFiles.map {
				try runUpToFirstPasses(withSettings: settings, withContext: context, onFile: $0)
			}.toMutableList()
		}

		// If we've received a non-raw AST then we're in the middle of the transpilation passes.
		// This means we need to at least run the second round of passes.
		guard let asts = firstResult.as(MutableList<GryphonAST>.self),
			settings.shouldGenerateAST else
		{
			return firstResult
		}

		let pairsArray = zip(asts, filteredInputFiles)

		let secondResult: MutableList<Any?>
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
			}.toMutableList()
		}

		return secondResult
	}

	static func getInputFilePaths(
		inArguments arguments: MutableList<String>)
		-> MutableList<String>
	{
		let cleanArguments = arguments.map {
			$0.hasSuffix("/") ?
				String($0.dropLast()) :
				$0
		}

		let result: MutableList<String> = []
		result.append(contentsOf: cleanArguments.filter {
			Utilities.getExtension(of: $0) == .swift
		})
		result.append(contentsOf: cleanArguments.filter {
			Utilities.getExtension(of: $0) == .swiftASTDump
		})
		result.append(contentsOf: cleanArguments.filter {
			Utilities.getExtension(of: $0) == .xcodeproj
		})

		let fileLists = cleanArguments.filter {
			Utilities.getExtension(of: $0) == .xcfilelist
		}
		for fileList in fileLists {
			do {
				let contents = try Utilities.readFile(fileList)
				let files = contents.split(withStringSeparator: "\n")
				result.append(contentsOf: files)
			} catch let error {
				print(error)
			}
		}

		return result
	}

	static func initialize() {
		// Create gryphon folder and subfolders
		Utilities.createFolderIfNeeded(at: SupportingFile.gryphonBuildFolder)
		Utilities.createFolderIfNeeded(at: SupportingFile.gryphonScriptsFolder)

		// Save the files
		Utilities.createFile(
			atPath: SupportingFile.gryphonTemplatesLibrary.relativePath,
			containing: gryphonTemplatesLibraryFileContents)
		Utilities.createFile(
			atPath: SupportingFile.gryphonXCTest.relativePath,
			containing: gryphonXCTestFileContents)
		Utilities.createFile(
			atPath: SupportingFile.mapKotlinErrorsToSwift.relativePath,
			containing: kotlinErrorMapScriptFileContents)
		Utilities.createFile(
			atPath: SupportingFile.mapGradleErrorsToSwift.relativePath,
			containing: gradleErrorMapScriptFileContents)
		Utilities.createFile(
			atPath: SupportingFile.makeGryphonTargets.relativePath,
			containing: xcodeTargetScriptFileContents)
		Utilities.createFile(
			atPath: SupportingFile.compileKotlin.relativePath,
			containing: compileKotlinScriptFileContents)
	}

	static func cleanup() {
		Utilities.deleteFolder(at: SupportingFile.gryphonBuildFolder)
	}

	static func setupGryphonFolder(forXcodeProject xcodeProjectPath: String) -> Bool {
		guard let commandResult = Shell.runShellCommand([
			"xcodebuild",
			"-dry-run",
			"-project",
			"\(xcodeProjectPath)", ]) else
		{
			print("Failed to run xcodebuild")
			return false
		}

		guard commandResult.status == 0 else {
			print("Error running xcodebuild:\n" +
				commandResult.standardOutput +
				commandResult.standardError)
			return false
		}

		let output = commandResult.standardOutput
		let buildSteps = output.split(withStringSeparator: "\n\n")
		guard let compileSwiftStep =
			buildSteps.first(where: { $0.hasPrefix("CompileSwiftSources") }) else
		{
			print("Unable to find the Swift compilation command in the Xcode project.")
			return false
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
		let newCompilationCommand = newComponents.joined(separator: " ")

		// Drop the header and the old compilation command
		var scriptContents = commands.dropFirst().dropLast().joined(separator: "\n")
		scriptContents += "\n" + newCompilationCommand + "\n"
		Utilities.createFile(
			named: SupportingFile.astDumpsScript.name,
			inDirectory: SupportingFile.gryphonBuildFolder,
			containing: scriptContents)

		return true
	}

	static func makeGryphonTargets(forXcodeProject xcodeProjectPath: String) -> Bool {
		// Run the ruby script
		guard let commandResult =
			Shell.runShellCommand([
				"ruby",
				"\(SupportingFile.makeGryphonTargets.relativePath)",
				"\(xcodeProjectPath)", ]) else
		{
			print("Failed to make gryphon targets")
			return false
		}

		guard commandResult.status == 0 else {
			print("Error making gryphon targets:\n" +
				commandResult.standardOutput +
				commandResult.standardError)
			return false
		}

		// Create the xcfilelist so the user has an easier time finding it and populating it
		_ = Utilities.createFileIfNeeded(at: SupportingFile.xcFileList.relativePath)

		return true
	}

	static func updateASTDumps(forFiles swiftFiles: List<String>) -> Bool {
		// TODO: Send these paths to constants so they aren't duplicated all around the code
		//// Create the outputFileMap
		var outputFileMapContents = "{\n"

		// Add the templates file
		let templatesFile = SupportingFile.gryphonTemplatesLibrary.absolutePath
		let templatesASTDumpFile = SupportingFile.gryphonTemplatesLibraryASTDump.absolutePath
		outputFileMapContents += "\t\"\(templatesFile)\": {\n" +
			"\t\t\"ast-dump\": \"\(templatesASTDumpFile)\",\n" +
			"\t},\n"

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

		Utilities.createFile(
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

		//// Call the Swift compiler
		guard let commandResult =
			Shell.runShellCommand(["bash", SupportingFile.astDumpsScript.relativePath]) else
		{
			print("Failed to call AST dump script.")
			return false
		}

		guard commandResult.status == 0 else {
			print("Error calling AST dump script:\n" +
				commandResult.standardOutput +
				commandResult.standardError)
			return false
		}

		return true
	}

	static func getASTDump(forFile file: String) -> String? {
		if Utilities.fileHasExtension(file, .swift) {
			return SupportingFile.pathOfSwiftASTDumpFile(forSwiftFile: file)
		}
		else if Utilities.fileHasExtension(file, .swiftASTDump) {
			return file
		}
		else {
			return nil
		}
	}

	static func unsupportedArguments(in arguments: MutableList<String>) -> List<String> {
		// Start with all arguments, remove the ones that are OK, return what's left
		var badArguments: List<String> = arguments
		badArguments = badArguments.filter { !supportedArguments.contains($0) }
		badArguments = badArguments.filter { !debugArguments.contains($0) }
		badArguments = badArguments.filter { isSupportedArgumentWithParameters($0) }
		badArguments = badArguments.filter { isSupportedInputFilePath($0) }
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
			if fileExtension == .swift || fileExtension == .swiftASTDump ||
				fileExtension == .xcfilelist || fileExtension == .xcodeproj ||
				fileExtension == .kt
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

		Commands:
		  ➡️  init <Xcode project>
		        Set up the current directory and the given Xcode project so that Gryphon
		        can translate the project's source files.
		  ➡️  clean
		        Deletes the files and folders created by `gryphon init`.

		Main usage:
		  gryphon [options] [file paths]

		  Options:
		      ↪️  --xcode
		            Transpiles the given source files in a way that's compatible with
		            Xcode projects and the iOS SDK. Omit this option if you want to
		            transpile standalone Swift files.

		      ↪️  --no-main-file
		            Do not generate a Kotlin file with a "main" function. This is
		            implied if also using `--xcode`.

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
