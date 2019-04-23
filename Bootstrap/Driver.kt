class Driver {
	companion object {
		public fun runUpToFirstPasses(settings: Driver.Settings, inputFilePath: String): Any? {
			if (!(settings.shouldGenerateSwiftAST)) {
				return mutableListOf<Any>()
			}

			val swiftASTDumpFile: String = getASTDump(file = inputFilePath, settings = settings)!!
			val swiftASTDump: String = Utilities.readFile(swiftASTDumpFile)
			val swiftAST: SwiftAST = Compiler.generateSwiftAST(astDump = swiftASTDump)

			if (settings.shouldEmitSwiftAST) {
				val output: String = swiftAST.prettyDescription(horizontalLimit = settings.horizontalLimit)
				val outputFilePath: String? = settings.outputFileMap?.getOutputFile(
					file = inputFilePath,
					outputType = OutputFileMap.OutputType.SWIFT_AST)
				if (outputFilePath != null && settings.canPrintToFiles) {
					Utilities.createFile(filePath = outputFilePath, contents = output)
				}
				else if (settings.canPrintToOutput) {
					println(output)
				}
			}

			return null
		}

		public fun run(arguments: MutableList<String>): Any? {
			Compiler.clearErrorsAndWarnings()
			Compiler.shouldLogProgress(value = arguments.contains("-verbose"))

			Compiler.shouldStopAtFirstError = !arguments.contains("-continue-on-error")

			val horizontalLimit: Int?
			val lineLimitArgument: String? = arguments.find { it.startsWith("-line-limit=") }

			if (lineLimitArgument != null) {
				val lineLimitString: String = lineLimitArgument.drop("-line-limit=".length)
				horizontalLimit = lineLimitString.toIntOrNull()
			}
			else {
				horizontalLimit = null
			}

			val outputFileMap: OutputFileMap?
			val outputFileMapArgument: String? = arguments.find { it.startsWith("-output-file-map=") }

			if (outputFileMapArgument != null) {
				val outputFileMapPath: String = outputFileMapArgument.drop("-output-file-map=".length)
				outputFileMap = OutputFileMap(outputFileMapPath)
			}
			else {
				outputFileMap = null
			}

			val outputFolder: String
			val outputFolderIndex: Int? = arguments.indexOf("-o")

			if (outputFolderIndex != null) {
				val maybeOutputFolder: String? = arguments.getSafe(outputFolderIndex + 1)
				if (maybeOutputFolder != null) {
					outputFolder = maybeOutputFolder
				}
				else {
					outputFolder = OS.buildFolder
				}
			}
			else {
				outputFolder = OS.buildFolder
			}

			val inputFilePaths: MutableList<String> = arguments.filter { !it.startsWith("-") && it != "run" && it != "build" }.toMutableList()
			val shouldEmitSwiftAST: Boolean = arguments.contains("-emit-swiftAST")
			val shouldEmitRawAST: Boolean = arguments.contains("-emit-rawAST")
			val shouldEmitAST: Boolean = arguments.contains("-emit-AST")
			val shouldRun: Boolean = arguments.contains("run")
			val shouldBuild: Boolean = shouldRun || arguments.contains("build")
			val hasChosenTask: Boolean = shouldEmitSwiftAST || shouldEmitRawAST || shouldEmitAST || shouldRun || shouldBuild
			val shouldEmitKotlin: Boolean = !hasChosenTask || arguments.contains("-emit-kotlin")
			val canPrintToFiles: Boolean = !arguments.contains("-Q")
			val canPrintToOutput: Boolean = !arguments.contains("-q")
			val shouldGenerateKotlin: Boolean = shouldBuild || shouldEmitKotlin
			val shouldGenerateAST: Boolean = shouldGenerateKotlin || shouldEmitAST
			val shouldGenerateRawAST: Boolean = shouldGenerateAST || shouldEmitRawAST
			val shouldGenerateSwiftAST: Boolean = shouldGenerateRawAST || shouldEmitSwiftAST
			val mainFilePath: String? = if (inputFilePaths.size == 1) { inputFilePaths[(0)] } else { inputFilePaths.find { it.endsWith("main.swift") || it.endsWith("main.swiftASTDump") } }
			val settings: Settings = Settings(
				shouldEmitSwiftAST = shouldEmitSwiftAST,
				shouldEmitRawAST = shouldEmitRawAST,
				shouldEmitAST = shouldEmitAST,
				shouldRun = shouldRun,
				shouldBuild = shouldBuild,
				shouldEmitKotlin = shouldEmitKotlin,
				shouldGenerateKotlin = shouldGenerateKotlin,
				shouldGenerateAST = shouldGenerateAST,
				shouldGenerateRawAST = shouldGenerateRawAST,
				shouldGenerateSwiftAST = shouldGenerateSwiftAST,
				canPrintToFiles = canPrintToFiles,
				canPrintToOutput = canPrintToOutput,
				horizontalLimit = horizontalLimit,
				outputFileMap = outputFileMap,
				outputFolder = outputFolder,
				mainFilePath = mainFilePath)
			val shouldRunConcurrently: Boolean = !arguments.contains("-sync")
			val filteredInputFiles: MutableList<String> = inputFilePaths.filter { it.endsWith(".swift") || it.endsWith(".swiftASTDump") }.toMutableList()
			val firstResult: MutableList<Any?>

			if (shouldRunConcurrently) {
				firstResult = filteredInputFiles.parallelMap { runUpToFirstPasses(settings = settings, inputFilePath = it) }
			}
			else {
				firstResult = filteredInputFiles.map { runUpToFirstPasses(settings = settings, inputFilePath = it) }.toMutableList()
			}

			return firstResult
		}

		internal fun getASTDump(file: String, settings: Driver.Settings): String? {
			if (file.endsWith(".swift")) {
				val astDumpFile: String? = settings.outputFileMap?.getOutputFile(file = file, outputType = OutputFileMap.OutputType.AST_DUMP)
				if (astDumpFile != null) {
					return astDumpFile
				}
				else {
					return Utilities.changeExtension(filePath = file, newExtension = FileExtension.SWIFT_AST_DUMP)
				}
			}
			else if (file.endsWith(".swiftASTDump")) {
				return file
			}
			else {
				return null
			}
		}
	}

	data class Settings(
		val shouldEmitSwiftAST: Boolean,
		val shouldEmitRawAST: Boolean,
		val shouldEmitAST: Boolean,
		val shouldRun: Boolean,
		val shouldBuild: Boolean,
		val shouldEmitKotlin: Boolean,
		val shouldGenerateKotlin: Boolean,
		val shouldGenerateAST: Boolean,
		val shouldGenerateRawAST: Boolean,
		val shouldGenerateSwiftAST: Boolean,
		val canPrintToFiles: Boolean,
		val canPrintToOutput: Boolean,
		val horizontalLimit: Int?,
		val outputFileMap: OutputFileMap?,
		val outputFolder: String,
		val mainFilePath: String?
	)
}
