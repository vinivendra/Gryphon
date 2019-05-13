open class Driver {
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

            if (!(settings.shouldGenerateRawAST)) {
                return swiftAST
            }

            val isMainFile: Boolean = (inputFilePath == settings.mainFilePath)
            val gryphonRawAST: GryphonAST = Compiler.generateGryphonRawAST(swiftAST = swiftAST, asMainFile = isMainFile)

            if (settings.shouldEmitRawAST) {
                val output: String = gryphonRawAST.prettyDescription(horizontalLimit = settings.horizontalLimit)
                val outputFilePath: String? = settings.outputFileMap?.getOutputFile(
                    file = inputFilePath,
                    outputType = OutputFileMap.OutputType.GRYPHON_AST_RAW)
                if (outputFilePath != null && settings.canPrintToFiles) {
                    Utilities.createFile(filePath = outputFilePath, contents = output)
                }
                else if (settings.canPrintToOutput) {
                    println(output)
                }
            }

            if (!(settings.shouldGenerateAST)) {
                return gryphonRawAST
            }

            val gryphonFirstPassedAST: GryphonAST = Compiler.generateGryphonASTAfterFirstPasses(ast = gryphonRawAST)

            return gryphonFirstPassedAST
        }

        public fun runAfterFirstPasses(
            gryphonFirstPassedAST: GryphonAST,
            settings: Driver.Settings,
            inputFilePath: String)
            : Any?
        {
            val gryphonAST: GryphonAST = Compiler.generateGryphonASTAfterSecondPasses(ast = gryphonFirstPassedAST)

            if (settings.shouldEmitAST) {
                val output: String = gryphonAST.prettyDescription(horizontalLimit = settings.horizontalLimit)
                val outputFilePath: String? = settings.outputFileMap?.getOutputFile(
                    file = inputFilePath,
                    outputType = OutputFileMap.OutputType.GRYPHON_AST)
                if (outputFilePath != null && settings.canPrintToFiles) {
                    Utilities.createFile(filePath = outputFilePath, contents = output)
                }
                else if (settings.canPrintToOutput) {
                    println(output)
                }
            }

            if (!(settings.shouldGenerateKotlin)) {
                return gryphonAST
            }

            val kotlinCode: String = Compiler.generateKotlinCode(ast = gryphonAST)
            val outputFilePath: String? = settings.outputFileMap?.getOutputFile(
                file = inputFilePath,
                outputType = OutputFileMap.OutputType.KOTLIN)

            if (outputFilePath != null && settings.canPrintToFiles) {
                Utilities.createFile(filePath = outputFilePath, contents = kotlinCode)
            }
            else if (settings.canPrintToOutput) {
                if (settings.shouldEmitKotlin) {
                    println(kotlinCode)
                }
            }

            return kotlinCode
        }

        public fun run(arguments: MutableList<String>): Any? {
            try {
                Compiler.clearErrorsAndWarnings()
                Compiler.shouldLogProgress(value = arguments.contains("-verbose"))

                Compiler.shouldStopAtFirstError = !arguments.contains("-continue-on-error")

                val indentationArgument: String? = arguments.find { it.startsWith("-indentation=") }

                if (indentationArgument != null) {
                    val indentationString: String = indentationArgument.drop("-indentation=".length)
                    val numberOfSpaces: Int? = indentationString.toIntOrNull()
                    if (indentationString == "t") {
                        KotlinTranslator.indentationString = "\t"
                    }
                    else if (numberOfSpaces != null) {
                        var result: String = ""
                        for (_0 in 0 until numberOfSpaces) {
                            result += " "
                        }
                        KotlinTranslator.indentationString = result
                    }
                }

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
                val mainFilePath: String?

                if (arguments.contains("-no-main-file")) {
                    mainFilePath = null
                }
                else if (inputFilePaths.size == 1) {
                    mainFilePath = inputFilePaths[0]
                }
                else {
                    mainFilePath = inputFilePaths.find { it.endsWith("main.swift") || it.endsWith("main.swiftASTDump") }
                }

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

                if (shouldGenerateAST) {
                    Utilities.updateLibraryFiles()
                }

                val filteredInputFiles: MutableList<String> = inputFilePaths.filter { it.endsWith(".swift") || it.endsWith(".swiftASTDump") }.toMutableList()
                val firstResult: MutableList<Any?>

                if (shouldRunConcurrently) {
                    firstResult = filteredInputFiles.parallelMap { runUpToFirstPasses(settings = settings, inputFilePath = it) }
                }
                else {
                    firstResult = filteredInputFiles.map { runUpToFirstPasses(settings = settings, inputFilePath = it) }.toMutableList()
                }

                val asts: MutableList<GryphonAST>? = firstResult as? MutableList<GryphonAST>

                if (!(asts != null && settings.shouldGenerateAST)) {
                    return firstResult
                }

                val pairsArray: MutableList<Pair<GryphonAST, String>> =
                	asts.zip(filteredInputFiles).toMutableList()

                val secondResult: MutableList<Any?>

                if (shouldRunConcurrently) {
                    secondResult = pairsArray.parallelMap { runAfterFirstPasses(
                            gryphonFirstPassedAST = it.first,
                            settings = settings,
                            inputFilePath = it.second) }
                }
                else {
                    secondResult = pairsArray.map { runAfterFirstPasses(
                        gryphonFirstPassedAST = it.first,
                        settings = settings,
                        inputFilePath = it.second) }.toMutableList()
                }

                if (!(settings.shouldBuild)) {
                    return secondResult
                }

                val generatedKotlinFiles: MutableList<String> = filteredInputFiles.map { settings.outputFileMap?.getOutputFile(file = it, outputType = OutputFileMap.OutputType.KOTLIN) }.filterNotNull().toMutableList()
                val inputKotlinFiles: MutableList<String> = inputFilePaths.filter { it.endsWith(".kt") }.toMutableList()
                val kotlinFiles: MutableList<String> = generatedKotlinFiles

                kotlinFiles.addAll(inputKotlinFiles)

                val compilationResult: Shell.CommandOutput? = Compiler.compile(filePaths = kotlinFiles, outputFolder = settings.outputFolder)

                compilationResult ?: return null

                if (!(settings.shouldRun)) {
                    return compilationResult
                }

                val runResult: Shell.CommandOutput? = Compiler.runCompiledProgram(outputFolder = settings.outputFolder)

                return runResult
            }
            finally {
                if (arguments.contains("-summarize-errors")) {
                    Compiler.printErrorStatistics()
                }
                else {
                    Compiler.printErrorsAndWarnings()
                }
            }
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
