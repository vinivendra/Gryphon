//
// Copyright 2018 Vinicius Jorge Vendramini
//
// Licensed under the Hippocratic License, Version 2.1;
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://firstdonoharm.dev/version/2/1/license
//
// To the full extent allowed by law, this software comes "AS IS,"
// WITHOUT ANY WARRANTY, EXPRESS OR IMPLIED, and licensor and any other
// contributor shall not be liable to anyone for any damages or other
// liability arising from, out of, or in connection with the sotfware
// or this license, under any kind of legal claim.
// See the License for the specific language governing permissions and
// limitations under the License.
//

public class Driver {
	public static let gryphonVersion = "0.19"

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
		"--create-folders",
		"--write-to-console",
		"--verbose",
		"--quiet",
		"--sync",
	]

	public static let supportedArgumentsWithParameters: List = [
		"--indentation=",
		"--target=",
		"-line-limit=",
	]

	public static let debugArguments: List = [
		"-xcode",
		"setup-xcode",
		"make-gryphon-targets",
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

		let shouldCreateFolders: Bool
		let forcePrintingToConsole: Bool
		let quietModeIsOn: Bool

		let mainFilePath: String?
		let xcodeProjectPath: String?
		let pathConfigurations: Map<String, String>
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
		let isVerbose = arguments.contains("--verbose")
		Compiler.shouldLogProgress = isVerbose

		Compiler.log("ℹ️  Gryphon version \(gryphonVersion)")
		Compiler.log("ℹ️  SwiftSyntax version \(TranspilationContext.swiftSyntaxVersion)")

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

		if arguments.contains("clean") {

			Compiler.logStart("🧑‍💻  Deleting Gryphon files...")
			cleanup()
			Compiler.logEnd("✅  Done deleting Gryphon files.")

			if !arguments.contains("init") {
				return nil
			}
		}

		if arguments.contains("generate-libraries") {
			Compiler.logStart("🧑‍💻  Generating libraries...")
			try generateLibraries()
			Compiler.logEnd("✅  Done generating libraries.")

			return nil
		}

		Compiler.logStart("🧑‍💻  Checking Xcode arguments...")

		// Get the chosen target, if there is one
		let target = getValue(of: "--target", inArguments: arguments)
		if let chosenTarget = target {
			Compiler.log("ℹ️  Using target \(chosenTarget).")
		}
		else {
			Compiler.log("ℹ️  Using default target.")
		}

		// Get the Xcode project, if there is one
		let maybeXcodeProject = getXcodeProject(inArguments: arguments)
		if let xcodeProject = maybeXcodeProject {
			Compiler.log("ℹ️  Using Xcode project \(xcodeProject).")
		}
		else {
			Compiler.log("ℹ️  Not using Xcode.")
		}

		Compiler.logEnd("✅  Done checking Xcode arguments.")

		if arguments.contains("init") {
			// The `-xcode` flag forces the initialization to add Xcode files to the
			// Gryphon build folder even if no Xcode project was given. It's currently
			// used only for developing Gryphon.
			let shouldInitializeXcodeFiles = (maybeXcodeProject != nil) ||
				arguments.contains("-xcode")

			Compiler.logStart("🧑‍💻  Initializing...")
			try initialize(includingXcodeFiles: shouldInitializeXcodeFiles)

			if let xcodeProject = maybeXcodeProject {
				let recursiveArguments = getRecursiveArguments(from: arguments)

				let configFiles = getPathConfigurationFiles(inArguments: arguments)
				if configFiles.isEmpty,
				   !Utilities.fileExists(at: SupportingFile.configFile.absolutePath)
				{
					try initialize(file: SupportingFile.configFile)
					recursiveArguments.append(SupportingFile.configFile.relativePath)
				}

				let setupArguments: MutableList = ["setup-xcode", xcodeProject]
				setupArguments.append(contentsOf: recursiveArguments)
				_ = try Driver.run(withArguments: setupArguments)

				let makeTargetArguments: MutableList = ["make-gryphon-targets", xcodeProject]
				makeTargetArguments.append(contentsOf: recursiveArguments)
				_ = try Driver.run(withArguments: makeTargetArguments)
			}

			Compiler.logEnd("✅  Done initializing.")
			return nil
		}

		if arguments.contains("setup-xcode") {
			guard let xcodeProject = maybeXcodeProject else {
				throw GryphonError(errorMessage:
					"Please specify an Xcode project when using `setup-xcode`.")
			}

			Compiler.logStart("🧑‍💻  Creating iOS compilation files...")

			try createIOSCompilationFiles(forXcodeProject: xcodeProject, forTarget: target)

			Compiler.logEnd("✅  Done creating iOS compilation files.")

			return nil
		}
		if arguments.contains("make-gryphon-targets") {
			guard let xcodeProject = maybeXcodeProject else {
				throw GryphonError(errorMessage:
					"Please specify an Xcode project when using `make-gryphon-targets`.")
			}

			Compiler.logStart("🧑‍💻  Adding Gryphon targets to Xcode...")

			let configFiles = getPathConfigurationFiles(inArguments: arguments)

			try makeGryphonTargets(
				forXcodeProject: xcodeProject,
				forTarget: target,
				configFiles: configFiles)

			Compiler.logEnd("✅  Done adding Gryphon targets.")

			return nil
		}

		// If there's no build folder, create one, perform the transpilation, then delete it
		if !Utilities.fileExists(at: SupportingFile.gryphonBuildFolder) {
			Compiler.logStart("🧑‍💻  Starting compilation with temporary build folder...")
			let result = try performCompilationWithTemporaryBuildFolder(withArguments: arguments)
			Compiler.logEnd("✅  Done compilation with temporary build folder")
			return result
		}
		else {
			Compiler.logStart("🧑‍💻  Starting compilation...")
			let result = try performCompilation(withArguments: arguments)
			Compiler.logEnd("✅  Done compilation.")
			return result
		}
	}

	public static func runUpToFirstPasses(
		withSettings settings: Settings,
		withContext context: TranspilationContext,
		onFile inputFilePath: String)
		throws -> Any?
	{
		let inputFileRelativePath = Utilities.getRelativePath(forFile: inputFilePath)

		guard settings.shouldGenerateSwiftAST else {
			Compiler.logStart("☑️  Nothing to do for \(inputFileRelativePath).")
			return []
		}

		let isMainFile = (inputFilePath == settings.mainFilePath)

		Compiler.logStart("🧑‍💻  Processing SwiftSyntax for \(inputFileRelativePath)...")
		let decoder = try Compiler.generateSwiftSyntaxDecoder(
			fromSwiftFile: inputFilePath,
			withContext: context)
		let swiftAST = decoder.syntaxTree.toPrintableTree()
		Compiler.logEnd("✅  Done processing SwiftSyntax for \(inputFileRelativePath).")

		Compiler.logStart("🧑‍💻  Converting SwiftSyntax for \(inputFileRelativePath)...")
		let gryphonRawAST = try Compiler.generateGryphonRawAST(
			usingFileDecoder: decoder,
			asMainFile: isMainFile,
			withContext: context)
		Compiler.logEnd("✅  Done converting SwiftSyntax for \(inputFileRelativePath).")

		if settings.shouldEmitSwiftAST {
			let output = swiftAST.prettyDescription()
			if let outputFilePath = gryphonRawAST.outputFileMap[.swiftAST],
				!settings.forcePrintingToConsole
			{
				Compiler.log("📝  Writing Swift AST to file for \(inputFileRelativePath)")
				try Utilities.createFile(
					atPath: outputFilePath,
					containing: output,
					createIntermediateFolders: settings.shouldCreateFolders)
			}
			else if !settings.quietModeIsOn {
				Compiler.log("📝  Printing Swift AST for \(inputFileRelativePath):")
				Compiler.output(output)
			}
		}

		if settings.shouldEmitRawAST {
			let output = gryphonRawAST.prettyDescription()
			if let outputFilePath = gryphonRawAST.outputFileMap[.gryphonASTRaw],
				!settings.forcePrintingToConsole
			{
				Compiler.log("📝  Writing raw AST to file for \(inputFileRelativePath)")
				try Utilities.createFile(
					atPath: outputFilePath,
					containing: output,
					createIntermediateFolders: settings.shouldCreateFolders)
			}
			else if !settings.quietModeIsOn {
				Compiler.log("📝  Printing raw AST for \(inputFileRelativePath):")
				Compiler.output(output)
			}
		}

		guard settings.shouldGenerateAST else {
			return gryphonRawAST
		}

		Compiler.logStart("🧑‍💻  Running first passes on AST for \(inputFileRelativePath)...")
		let gryphonFirstPassedAST = try Compiler.generateGryphonASTAfterFirstPasses(
			fromGryphonRawAST: gryphonRawAST,
			withContext: context)
		Compiler.logEnd("✅  Done running first passes on AST for \(inputFileRelativePath).")

		return gryphonFirstPassedAST
	}

	public static func runAfterFirstPasses(
		onAST gryphonFirstPassedAST: GryphonAST,
		withSettings settings: Settings,
		withContext context: TranspilationContext,
		onFile inputFilePath: String)
		throws -> Any?
	{
		let inputFileRelativePath = Utilities.getRelativePath(forFile: inputFilePath)

		Compiler.logStart("🧑‍💻  Running second passes on AST for \(inputFileRelativePath)...")
		let gryphonAST = try Compiler.generateGryphonASTAfterSecondPasses(
			fromGryphonRawAST: gryphonFirstPassedAST, withContext: context)
		Compiler.logEnd("✅  Done running second passes on AST for \(inputFileRelativePath).")

		if settings.shouldEmitAST {
			let output = gryphonAST.prettyDescription()
			if let outputFilePath = gryphonAST.outputFileMap[.gryphonAST],
				!settings.forcePrintingToConsole
			{
				Compiler.log("📝  Writing AST to file for \(inputFileRelativePath)")
				try Utilities.createFile(
					atPath: outputFilePath,
					containing: output,
					createIntermediateFolders: settings.shouldCreateFolders)
			}
			else if !settings.quietModeIsOn {
				Compiler.log("📝  Printing AST for \(inputFileRelativePath):")
				Compiler.output(output)
			}
		}

		guard settings.shouldGenerateKotlin else {
			return gryphonAST
		}

		Compiler.logStart("🧑‍💻  Generating Kotlin code for \(inputFileRelativePath)...")
		let kotlinCode = try Compiler.generateKotlinCode(
			fromGryphonAST: gryphonAST,
			withContext: context)
		Compiler.logEnd("✅  Done generating Kotlin code for \(inputFileRelativePath).")

		if settings.shouldEmitKotlin {
			if settings.forcePrintingToConsole {
				if !settings.quietModeIsOn {
					Compiler.log("📝  Printing Kotlin code for \(inputFileRelativePath):")
					Compiler.output(kotlinCode)
				}
			}
			else {
				if let outputFilePath = gryphonAST.outputFileMap[.kt] {
					Compiler.log("📝  Writing Kotlin to file for \(inputFileRelativePath)")
					try Utilities.createFile(
						atPath: outputFilePath,
						containing: kotlinCode,
						createIntermediateFolders: settings.shouldCreateFolders)
				}
				else {
					if settings.xcodeProjectPath != nil {
						Compiler.log("⚠️  No output Kotlin file found for \(inputFileRelativePath)")

						// If the user didn't ask to print to console and we're in Xcode but there's
						// no output file, it's likely the user forgot to add an output file
						Compiler.handleWarning(
							message: "No output file path set for \"\(inputFilePath)\"." +
								" Set it with \"// gryphon output: <output file>\".",
							syntax: nil,
							sourceFile: gryphonAST.sourceFile,
							sourceFileRange: SourceFileRange(
								lineStart: 1, lineEnd: 1,
								columnStart: 1, columnEnd: 1))
					}

					if !settings.quietModeIsOn {
						Compiler.log("📝  Printing Kotlin code for \(inputFileRelativePath):")
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
		withArguments arguments: List<String>)
		throws -> Any?
	{
		let newArguments = getRecursiveArguments(from: arguments)

		var result: Any?
		do {
			newArguments.append("init")
			_ = try Driver.run(withArguments: newArguments)
			result = try performCompilation(withArguments: arguments)
		}
		catch let error {
			// Ensure `clean` runs even if an error was thrown
			newArguments.append("clean")
			_ = try Driver.run(withArguments: newArguments)
			throw error
		}

		// Call `clean` if no errors were thrown
		newArguments.append("clean")
		_ = try Driver.run(withArguments: newArguments)

		return result
	}

	@discardableResult
	public static func performCompilation(
		withArguments arguments: List<String>)
		throws -> Any?
	{
		Compiler.logStart("🧑‍💻  Parsing arguments...")

		Compiler.clearIssues()

		// Parse arguments
		Compiler.shouldStopAtFirstError = !arguments.contains("--continue-on-error")
		Compiler.shouldAvoidUnicodeCharacters = arguments.contains("-avoid-unicode")

		//
		CompilerIssue.shouldPrintASTs = arguments.contains("-print-ASTs-on-error")

		if let lineLimitString = getValue(of: "-line-limit", inArguments: arguments) {
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
		let shouldCreateFolders = arguments.contains("--create-folders")
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
		let maybeXcodeProject = getXcodeProject(inArguments: arguments)
		let maybeTarget = getValue(of: "--target", inArguments: arguments)

		//
		let pathConfigurationFiles = getPathConfigurationFiles(inArguments: arguments)
		let pathConfigurations = try getPathConfigurations(from: pathConfigurationFiles)

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
			shouldCreateFolders: shouldCreateFolders,
			forcePrintingToConsole: forcePrintingToConsole,
			quietModeIsOn: quietModeIsOn,
			mainFilePath: mainFilePath,
			xcodeProjectPath: maybeXcodeProject,
			pathConfigurations: pathConfigurations)

		Compiler.logStart("🔧  Using settings:")
		Compiler.log("ℹ️  shouldEmitSwiftAST: \(shouldEmitSwiftAST)")
		Compiler.log("ℹ️  shouldEmitRawAST: \(shouldEmitRawAST)")
		Compiler.log("ℹ️  shouldEmitAST: \(shouldEmitAST)")
		Compiler.log("ℹ️  shouldEmitKotlin: \(shouldEmitKotlin)")
		Compiler.log("ℹ️  shouldGenerateKotlin: \(shouldGenerateKotlin)")
		Compiler.log("ℹ️  shouldGenerateAST: \(shouldGenerateAST)")
		Compiler.log("ℹ️  shouldGenerateRawAST: \(shouldGenerateRawAST)")
		Compiler.log("ℹ️  shouldGenerateSwiftAST: \(shouldGenerateSwiftAST)")
		Compiler.log("ℹ️  forcePrintingToConsole: \(forcePrintingToConsole)")
		Compiler.log("ℹ️  quietModeIsOn: \(quietModeIsOn)")
		Compiler.log("ℹ️  mainFilePath: \(mainFilePath ?? "no main file")")
		Compiler.log("ℹ️  xcodeProjectPath: \(maybeXcodeProject ?? "no Xcode project")")
		Compiler.log("ℹ️  pathConfigurations: \(pathConfigurations)")
		Compiler.logEnd("🔧  Settings done.")

		//
		var indentationString = "    "
		if let indentationArgument = getValue(of: "--indentation", inArguments: arguments) {
			if indentationArgument == "t" {
				indentationString = "\t"
			}
			else if let numberOfSpaces = Int(indentationArgument) {
				indentationString = String(repeating: " ", count: numberOfSpaces)
			}
		}

		//
		let shouldRunConcurrently = !arguments.contains("--sync")

		Compiler.logEnd("✅  Done parsing arguments.")

		/// Get the input files
		let isSkippingFiles = arguments.contains("--skip")

		let inputFiles = try getInputFilePaths(inArguments: arguments)
		if inputFiles.isEmpty {
			throw GryphonError(errorMessage: "No input files provided.")
		}
		let allSourceFiles = inputFiles.toMutableList()

		if isSkippingFiles {
			let skippedFiles = try getSkippedInputFilePaths(inArguments: arguments)
			allSourceFiles.append(contentsOf: skippedFiles)
		}

		let sdkPath: String?
		let otherSwiftArguments: MutableList<String>
		if maybeXcodeProject != nil {
			(sdkPath, otherSwiftArguments) = try readCompilationArgumentsFromFile()
		}
		else {
			let arguments = allSourceFiles
				.map { Utilities.getAbsolutePath(forFile: $0) }
				.toMutableList()

			sdkPath = nil
			otherSwiftArguments = arguments
		}

		/// Perform transpilation
		do {
			let context = try TranspilationContext(
				indentationString: indentationString,
				defaultsToFinal: defaultsToFinal,
				xcodeProjectPath: maybeXcodeProject,
				pathConfigurations: pathConfigurations,
				target: maybeTarget,
				swiftCompilationArguments: otherSwiftArguments,
				absolutePathToSDK: sdkPath)

			Compiler.logStart("🧑‍💻 Starting first part of translation [1/2]...")

			let firstResult: List<Any?>
			if shouldRunConcurrently {
				Compiler.log("🔀  Translating concurrently, logs may come out of order.")
				firstResult = try inputFilePaths.parallelMap {
					try runUpToFirstPasses(withSettings: settings, withContext: context, onFile: $0)
				}
			}
			else {
				Compiler.log("⏩  Translating sequentially.")
				firstResult = try inputFilePaths.map {
					try runUpToFirstPasses(withSettings: settings, withContext: context, onFile: $0)
				}
			}

			// If we've received a non-raw AST then we're in the middle of the transpilation passes.
			// This means we need to at least run the second round of passes.
			guard let asts = firstResult.as(List<GryphonAST>.self),
				settings.shouldGenerateAST else
			{
				Compiler.log("✅  Done first part of translation. Returning result.")
				return firstResult
			}

			Compiler.logEnd("✅  Done first part of translation.")
			Compiler.logStart("🧑‍💻 Starting second part translation [2/2]...")

			let pairsArray = zip(asts, inputFilePaths)

			let secondResult: List<Any?>
			if shouldRunConcurrently {
				Compiler.log("🔀  Translating concurrently, logs may come out of order.")
				secondResult = try pairsArray.parallelMap {
					try runAfterFirstPasses(
						onAST: $0.0,
						withSettings: settings,
						withContext: context,
						onFile: $0.1)
				}
			}
			else {
				Compiler.log("⏩  Translating sequentially.")
				secondResult = try pairsArray.map {
					try runAfterFirstPasses(
						onAST: $0.0,
						withSettings: settings,
						withContext: context,
						onFile: $0.1)
				}
			}

			Compiler.logEnd("✅  Done second part of translation.")
			Compiler.logStart("🧑‍💻  Printing issues (if there are any)...")
			Compiler.printIssues(skippingWarnings: quietModeIsOn)
			Compiler.logEnd("✅  Done printing issues.")

			return secondResult
		}
		catch let error {
			Compiler.log("⚠️  Something happened.")
			Compiler.logStart("⚠️  Printing issues (if there are any)...")
			Compiler.printIssues(skippingWarnings: quietModeIsOn)
			Compiler.logEnd("⚠️  Done printing issues.")
			throw error
		}
	}

	/// Reads the saved information from the `sourceKitCompilationArguments` file
	/// and structures it into a `SwiftCompilationArguments` object.
	/// Use this method only when using Xcode, since it depends on
	/// an Xcode-only file.
	static func readCompilationArgumentsFromFile()
		throws -> (sdkPath: String, otherArguments: MutableList<String>)
	{
		let arguments = try String(
			contentsOfFile: SupportingFile.sourceKitCompilationArguments.absolutePath)
			.splitUsingUnescapedSpaces()
			.map { $0.replacingOccurrences(of: "\\ ", with: " ") }
			.toMutableList()

		guard let sdkArgumentIndex = arguments.firstIndex(of: "-sdk") else {
			throw GryphonError(
				errorMessage: "Unable to find path to the SDK in the iOS compilation " +
					"arguments. Try cleaning the Xcode project, building it again, and " +
					"running `gryphon init <xcodeproj>`.")
		}

		let sdkPath = arguments[sdkArgumentIndex + 1]
		arguments.remove(at: sdkArgumentIndex) // Remove the "-sdk"
		arguments.remove(at: sdkArgumentIndex) // Remove the SDK path

		return (sdkPath, arguments)
	}

	/// Returns a list of all Swift input files, including those inside xcfilelists, but
	/// excluding any files paths after the `--skip` flag.
	/// Also excludes any commented files (with `#`) in an xcfilelist.
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
			let cleanFiles = files.map { $0.trimmingWhitespaces() }
			let uncommentedFiles = cleanFiles.filter { !$0.hasPrefix("#") }
			result.append(contentsOf: uncommentedFiles)
		}

		let missingFiles = result.filter({ !Utilities.fileExists(at: $0) })
		if !missingFiles.isEmpty {
			throw GryphonError(
				errorMessage: "Unable to open files: \(missingFiles.joined(separator: ", "))")
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
			Compiler.log("ℹ️  Generating xcode files")
			filesToInitialize = SupportingFile.filesForXcodeInitialization
		}
		else {
			Compiler.log("ℹ️  Generating basic files only")
			filesToInitialize = SupportingFile.filesForInitialization
		}

		for file in filesToInitialize {
			try initialize(file: file)
		}
	}

	static func initialize(file: SupportingFile) throws {
		if let contents = file.contents {
			if let folder = file.folder {
				Utilities.createFolderIfNeeded(at: folder)
			}
			try Utilities.createFile(
				atPath: file.relativePath,
				containing: contents,
				createIntermediateFolders: false)
		}
	}

	static func cleanup() {
		Utilities.deleteFolder(at: SupportingFile.gryphonBuildFolder)
	}

	static func generateLibraries() throws {
		try Utilities.createFile(
			atPath: SupportingFile.gryphonSwiftLibrary.relativePath,
			containing: SupportingFile.gryphonSwiftLibrary.contents!,
			createIntermediateFolders: false)
		try Utilities.createFile(
			atPath: SupportingFile.gryphonKotlinLibrary.relativePath,
			containing: SupportingFile.gryphonKotlinLibrary.contents!,
			createIntermediateFolders: false)
	}

	/// Calls xcodebuild with the given arguments
	static func runXcodebuild(
		forXcodeProject xcodeProjectPath: String,
		forTarget target: String?,
		simulator: String? = nil,
		dryRun: Bool)
		-> Shell.CommandOutput
	{
		let arguments: MutableList = [
			"xcodebuild",
			"-UseModernBuildSystem=NO",
			"-project",
			"\(xcodeProjectPath)", ]

		if let userTarget = target {
			arguments.append("-target")
			arguments.append(userTarget)
		}

		if let simulatorVersion = simulator {
			arguments.append("-sdk")
			arguments.append("iphonesimulator\(simulatorVersion)")
		}

		if dryRun {
			arguments.append("-dry-run")
		}

		let commandResult = Shell.runShellCommand(arguments)

		// If something went wrong, try to recover
		if commandResult.status != 0 {
			// Code signing errors might be solved by forcing a build with the simulator
			if simulator == nil,
				(commandResult.standardError.contains("Code Signing Error:") ||
				 commandResult.standardOutput.contains("Code Signing Error:"))
			{
				Compiler.log("⚠️  There was a code signing error when running xcodebuild. " +
					"Using a simulator might fix it.")
				Compiler.logStart("⚠️  Looking for an installed simulator...")
				if let iOSVersion = lookForSimulatorVersion() {
					Compiler.logEnd("⚠️  Found a simulator for iOS \(iOSVersion).")
					Compiler.logStart("⚠️  Calling xcodebuild again...")
					let result = runXcodebuild(
						forXcodeProject: xcodeProjectPath,
						forTarget: target,
						simulator: iOSVersion,
						dryRun: dryRun)
					Compiler.logEnd("⚠️  Done.")
					return result
				}
				else {
					Compiler.logEnd("⚠️  No installed simulators were found.")
				}
			}
		}

		return commandResult
	}

	/// Try to discover an installed simulator version using xcodebuild
	static func lookForSimulatorVersion() -> String? {
		// Try to discover the version of an installed simulator
		let sdkCommandResult = Shell.runShellCommand(["xcodebuild", "-showsdks"])
		if sdkCommandResult.status == 0 {
			let output = sdkCommandResult.standardOutput
			let outputLines = output.split(withStringSeparator: "\n")

			// Valid output lines are of the form:
			// 	Simulator - iOS 13.4          	-sdk iphonesimulator13.4
			for line in outputLines {
				if line.contains("iphonesimulator") {
					let components = line.split(withStringSeparator: " ")
					if let simulatorComponent = components.last {
						return String(
							simulatorComponent.dropFirst("iphonesimulator".count))
					}
				}
			}
		}

		return nil
	}

	/// Calls xcodebuild to create the files for compiling iOS projects.
	/// This includes a bash script that calls `swiftc` with `-dump-ast`
	/// and a file with the `swiftc` arguments for SourceKit.
	static func createIOSCompilationFiles(
		forXcodeProject xcodeProjectPath: String,
		forTarget target: String?)
		throws
	{
		let commandResult = runXcodebuild(
			forXcodeProject: xcodeProjectPath,
			forTarget: target,
			dryRun: true)

		guard commandResult.status == 0 else {
			throw GryphonError(errorMessage: "Error running xcodebuild:\n" +
				commandResult.standardOutput +
				commandResult.standardError)
		}

		let output = commandResult.standardOutput

		// If the target depends on other targets, the other targets will be built first. We have
		// to remove their build commands and keep only the target we chose.
		let targetContents: String
		if let userTarget = target {
			Compiler.log("ℹ️  Looking for build instructions for the \(userTarget) target...")

			let separator = "=== BUILD TARGET "
			let components = output.split(withStringSeparator: separator)
			guard let selectedComponent = components.first(where: { $0.hasPrefix(userTarget) })
				else
			{
				throw GryphonError(errorMessage: "Failed to find build instructions for target " +
					"\(userTarget) in the xcodebuild output.")
			}
			targetContents = selectedComponent
		}
		else {
			targetContents = output
		}

		Compiler.log("ℹ️  Looking for Swift compilation command...")
		let buildSteps = targetContents.split(withStringSeparator: "\n\n")
		guard let compileSwiftStep =
			buildSteps.first(where: { $0.hasPrefix("CompileSwiftSources") }) else
		{
			if output.contains("builtin-validationUtility") {
				throw GryphonError(errorMessage:
					"Unable to find the Swift compilation command for the Xcode project.\n" +
						"It's possible the build might be cached.\n" +
						"Try deleting the \"build\" folder, if there is one, then run Gryphon " +
						"again.")
			}
			else {
				throw GryphonError(errorMessage:
					"Unable to find the Swift compilation command in the Xcode project.")
			}
		}

		Compiler.log("ℹ️  Adapting Swift compilation command for dumping ASTs...")
		let commands = compileSwiftStep.split(withStringSeparator: "\n")

		var sourceKitFileContents = ""

		// Fix the call to the Swift compiler
		let compilationCommand = commands.last!
		let commandComponents = compilationCommand.splitUsingUnescapedSpaces()

		let filteredArguments = commandComponents.filter { (argument: String) -> Bool in
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
		}

		let sourceKitArguments = filteredArguments.toMutableList()

		sourceKitArguments.append("-D")
		sourceKitArguments.append("GRYPHON")

		// Build the resulting command
		sourceKitFileContents += sourceKitArguments.dropFirst().joined(separator: " ")

		try Utilities.createFile(
			named: SupportingFile.sourceKitCompilationArguments.name,
			inDirectory: SupportingFile.sourceKitCompilationArguments.folder ?? ".",
			containing: sourceKitFileContents)
	}

	static func makeGryphonTargets(
		forXcodeProject xcodeProjectPath: String,
		forTarget target: String?,
		configFiles: List<String>)
		throws
	{
		// Run the ruby script
		let arguments: MutableList = [
			"bash",
			"\(SupportingFile.runRubyScript.absolutePath)",
			"\(SupportingFile.makeGryphonTargets.absolutePath)",
			"\(xcodeProjectPath)", ]

		// Any other arguments will be appended to the target's script
		if let userTarget = target {
			arguments.append("--target=\"\(userTarget)\"")
		}
		arguments.append(contentsOf: configFiles)

		Compiler.logStart("🧑‍💻  Calling ruby to create the Gryphon targets...\n")
		let commandResult = Shell.runShellCommand(arguments)

		guard commandResult.status == 0 else {
			// If ruby is complaining that Xcodeproj is uninstalled
			if commandResult.standardError.contains(
				"in `require': cannot load such file -- xcodeproj")
			{
				throw GryphonError(errorMessage: "Error making gryphon targets:\n" +
					"Unable to find Xcodeproj installation. You can try reinstalling Gryphon, or " +
					"installing Xcodeproj manually (https://github.com/CocoaPods/Xcodeproj).")
			}
			else {
				// If it was an unknown error
				throw GryphonError(errorMessage: "Error making gryphon targets:\n" +
					commandResult.standardOutput +
					commandResult.standardError)
			}
		}

		Compiler.log(commandResult.standardOutput)
		Compiler.logEnd("✅  Done calling ruby.")

		// Create the xcfilelist so the user has an easier time finding it and populating it
		Compiler.log("ℹ️  Creating xcfilelist.")
		_ = Utilities.createFileIfNeeded(at: SupportingFile.xcFileList.relativePath)
	}

	static func unsupportedArguments(in arguments: List<String>) -> List<String> {
		// Start with all arguments, remove the ones that are OK, return what's left
		var badArguments = arguments
		badArguments = badArguments.filter { !supportedArguments.contains($0) }
		badArguments = badArguments.filter { !debugArguments.contains($0) }
		badArguments = badArguments.filter { !isSupportedArgumentWithParameters($0) }
		badArguments = badArguments.filter { !isXcodeProject($0) }
		badArguments = badArguments.filter { !isPathConfigurationFile($0) }
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

	static func isPathConfigurationFile(_ filePath: String) -> Bool {
		let cleanPath = filePath.hasSuffix("/") ? String(filePath.dropLast()) : filePath
		return Utilities.fileHasExtension(cleanPath, .config)
	}

	static func getPathConfigurationFiles(inArguments arguments: List<String>) -> List<String> {
		return arguments
			.filter { isPathConfigurationFile($0) }
			.map { $0.hasSuffix("/") ? String($0.dropLast()) : $0 }
	}

	static func getPathConfigurations(
		from configFileLists: List<String>)
	throws -> Map<String, String>
	{
		let result = MutableMap<String, String>()

		for file in configFileLists {
			let contents = try Utilities.readFile(file)
			for line in contents.split(separator: "\n") {
				let components = line.split(separator: "=")
				guard components.count >= 2 else {
					continue
				}
				let key = String(components[0])
					.trimmingWhitespaces()
				let value = String(components.dropFirst().joined(separator: "="))
					.trimmingWhitespaces()
				result[key] = value
			}
		}

		return result
	}

	/// Looks for an argument of the format "<argument>=<value>" and returns the value. For example,
	/// `getValue(of: "--target", inArguments: ["--target=Foo"])` returns `"Foo"`. Returns `nil` if
	/// the argument is absent.
	static func getValue(of argument: String, inArguments arguments: List<String>) -> String? {
		if let targetArgument = arguments.first(where: { $0.hasPrefix("\(argument)=") }) {
			return String(targetArgument.dropFirst("\(argument)=".count))
		}
		else {
			return nil
		}
	}

	/// Fetches the arguments that should be included in recursive driver calls, which are
	/// `--target=`, `--verbose`, and the config files.
	static func getRecursiveArguments(from arguments: List<String>) -> MutableList<String> {
		let result: MutableList<String> = []

		if arguments.contains("--verbose") {
			result.append("--verbose")
		}
		if let targetArgument = arguments.first(where: { $0.hasPrefix("--target=") }) {
			result.append(targetArgument)
		}

		let configFiles = getPathConfigurationFiles(inArguments: arguments)
		result.append(contentsOf: configFiles)

		return result
	}

	static func printVersion() {
		Compiler.output("Gryphon version \(gryphonVersion), using the Swift " +
			"\(TranspilationContext.swiftSyntaxVersion) parser")
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

	  ↪️  --create-folders
			Create intermediate folders (if needed) before writing the output
			files.

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

      ↪️  --target=<target name>
            Specify the target to be built when translating with Xcode.

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
