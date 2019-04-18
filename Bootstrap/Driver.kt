class Driver {
	companion object {
		public fun run(arguments: MutableList<String>): Any? {
			Compiler.clearErrorsAndWarnings()

			val shouldEmitSwiftAST: Boolean = arguments.contains("-emit-swiftAST")
			val shouldEmitRawAST: Boolean = arguments.contains("-emit-rawAST")
			val shouldEmitAST: Boolean = arguments.contains("-emit-AST")
			val shouldRun: Boolean = arguments.contains("run")
			val shouldBuild: Boolean = shouldRun || arguments.contains("build")
			val hasChosenTask: Boolean = shouldEmitSwiftAST || shouldEmitRawAST || shouldEmitAST || shouldRun || shouldBuild
			val shouldEmitKotlin: Boolean = !hasChosenTask || arguments.contains("-emit-kotlin")
			val shouldGenerateKotlin: Boolean = shouldBuild || shouldEmitKotlin
			val shouldGenerateAST: Boolean = shouldGenerateKotlin || shouldEmitAST
			val shouldGenerateRawAST: Boolean = shouldGenerateAST || shouldEmitRawAST
			val shouldGenerateSwiftAST: Boolean = shouldGenerateRawAST || shouldEmitSwiftAST
			val canPrintToFiles: Boolean = !arguments.contains("-Q")
			val canPrintToOutput: Boolean = !arguments.contains("-q")

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

			if (!(shouldGenerateSwiftAST)) {
				return null
			}

			val astDumpFilesFromOutputFileMap: MutableList<String> = inputFilePaths.map { inputFile ->
					if (inputFile.endsWith(".swift")) {
						val astDumpFile: String? = outputFileMap?.getOutputFile(file = inputFile, outputType = OutputFileMap.OutputType.AST_DUMP)
						if (astDumpFile != null) {
							astDumpFile
						}
					}

					if (inputFile.endsWith(".swiftASTDump")) {
						inputFile
					}

					null
				}.filterNotNull().toMutableList()
			val swiftASTDumpFiles: MutableList<String> = if (!astDumpFilesFromOutputFileMap.isEmpty()) { astDumpFilesFromOutputFileMap } else { inputFilePaths.filter { it.endsWith(".swift") }.toMutableList().map { Utilities.changeExtension(filePath = it, newExtension = FileExtension.SWIFT_AST_DUMP) }.toMutableList() }
			val swiftASTDumps: MutableList<String> = swiftASTDumpFiles.map { Utilities.readFile(it) }.toMutableList()
			val swiftASTs: MutableList<SwiftAST> = swiftASTDumps.map { Compiler.generateSwiftAST(astDump = it) }.toMutableList()

			if (shouldEmitSwiftAST) {
				for ((swiftFilePath, swiftAST) in inputFilePaths.zip(swiftASTs)) {
					val output: String = swiftAST.prettyDescription(horizontalLimit = horizontalLimit)
					val outputFilePath: String? = outputFileMap?.getOutputFile(file = swiftFilePath, outputType = OutputFileMap.OutputType.SWIFT_AST)
					if (outputFilePath != null && canPrintToFiles) {
						Utilities.createFile(filePath = outputFilePath, contents = output)
					}
					else if (canPrintToOutput) {
						println(output)
					}
				}
			}

			return null
		}
	}
}
