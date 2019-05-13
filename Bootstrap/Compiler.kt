open class Compiler {
    companion object {
        val kotlinCompilerPath: String = if (OS.osName == "Linux") { "/opt/kotlinc/bin/kotlinc" } else { "/usr/local/bin/kotlinc" }
        var log: (String) -> Unit = { println(it) }

        public fun shouldLogProgress(value: Boolean) {
            if (value) {
                log = { println(it) }
            }
            else {
                log = { }
            }
        }

        var shouldStopAtFirstError: Boolean = false
        var errors: MutableList<Exception> = mutableListOf()
        var warnings: MutableList<String> = mutableListOf()

        internal fun handleError(error: Exception) {
            if (Compiler.shouldStopAtFirstError) {
                throw error
            }
            else {
                Compiler.errors.add(error)
            }
        }

        internal fun handleWarning(
            message: String,
            details: String = "",
            sourceFile: SourceFile?,
            sourceFileRange: SourceFileRange?)
        {
            Compiler.warnings.add(Compiler.createErrorOrWarningMessage(
                message = message,
                details = details,
                sourceFile = sourceFile,
                sourceFileRange = sourceFileRange,
                isError = false))
        }

        public fun clearErrorsAndWarnings() {
            errors = mutableListOf()
            warnings = mutableListOf()
        }

        public fun generateSwiftAST(astDump: String): SwiftAST {
            log("\t- Building SwiftAST...")
            val ast: SwiftAST = ASTDumpDecoder(encodedString = astDump).decode()
            return ast
        }

        public fun transpileSwiftAST(inputFile: String): SwiftAST {
            val astDump: String = Utilities.readFile(inputFile)
            return generateSwiftAST(astDump = astDump)
        }

        public fun generateGryphonRawAST(swiftAST: SwiftAST, asMainFile: Boolean): GryphonAST {
            log("\t- Translating Swift ASTs to Gryphon ASTs...")
            return SwiftTranslator().translateAST(swiftAST, isMainFile = asMainFile)
        }

        public fun transpileGryphonRawASTs(
            inputFiles: MutableList<String>)
            : MutableList<GryphonAST>
        {
            val asts: MutableList<SwiftAST> = inputFiles.map { transpileSwiftAST(inputFile = it) }.toMutableList()
            val translateAsMainFile: Boolean = (inputFiles.size == 1)
            return asts.map { generateGryphonRawAST(swiftAST = it, asMainFile = translateAsMainFile) }.toMutableList()
        }

        public fun generateGryphonASTAfterFirstPasses(ast: GryphonAST): GryphonAST {
            log("\t- Running first round of passes...")
            Utilities.updateLibraryFiles()
            return TranspilationPass.runFirstRoundOfPasses(sourceFile = ast)
        }

        public fun generateGryphonASTAfterSecondPasses(ast: GryphonAST): GryphonAST {
            log("\t- Running second round of passes...")
            Utilities.updateLibraryFiles()
            return TranspilationPass.runSecondRoundOfPasses(sourceFile = ast)
        }

        public fun generateGryphonAST(ast: GryphonAST): GryphonAST {
            var ast: GryphonAST = ast

            log("\t- Running passes on Gryphon ASTs...")
            Utilities.updateLibraryFiles()

            ast = TranspilationPass.runFirstRoundOfPasses(sourceFile = ast)
            ast = TranspilationPass.runSecondRoundOfPasses(sourceFile = ast)

            return ast
        }

        public fun transpileGryphonASTs(
            inputFiles: MutableList<String>)
            : MutableList<GryphonAST>
        {
            val rawASTs: MutableList<GryphonAST> = transpileGryphonRawASTs(inputFiles = inputFiles)
            return rawASTs.map { generateGryphonAST(ast = it) }.toMutableList()
        }

        public fun generateKotlinCode(ast: GryphonAST): String {
            log("\t- Translating AST to Kotlin...")
            return KotlinTranslator().translateAST(ast)
        }

        public fun transpileKotlinCode(inputFiles: MutableList<String>): MutableList<String> {
            val asts: MutableList<GryphonAST> = transpileGryphonASTs(inputFiles = inputFiles)
            return asts.map { generateKotlinCode(ast = it) }.toMutableList()
        }

        public fun compile(
            filePaths: MutableList<String>,
            outputFolder: String)
            : Shell.CommandOutput?
        {
            log("\t- Compiling Kotlin...")

            val arguments: MutableList<String> = mutableListOf("-include-runtime", "-d", outputFolder + "/kotlin.jar")

            arguments.addAll(filePaths)

            val commandResult: Shell.CommandOutput? = Shell.runShellCommand(kotlinCompilerPath, arguments = arguments)

            return commandResult
        }

        public fun transpileThenCompile(
            inputFiles: MutableList<String>,
            outputFolder: String = OS.buildFolder)
            : Shell.CommandOutput?
        {
            val kotlinCodes: MutableList<String> = transpileKotlinCode(inputFiles = inputFiles)
            val kotlinFilePaths: MutableList<String> = mutableListOf()

            for ((inputFile, kotlinCode) in inputFiles.zip(kotlinCodes)) {
                val inputFileName: String = inputFile.split(separator = "/").lastOrNull()!!
                val kotlinFileName: String = Utilities.changeExtension(filePath = inputFileName, newExtension = FileExtension.KT)
                val folderWithSlash: String = if (outputFolder.endsWith("/")) { outputFolder } else { outputFolder + "/" }
                val kotlinFilePath: String = folderWithSlash + kotlinFileName

                Utilities.createFile(filePath = kotlinFilePath, contents = kotlinCode)
                kotlinFilePaths.add(kotlinFilePath)
            }

            return compile(filePaths = kotlinFilePaths, outputFolder = outputFolder)
        }

        public fun runCompiledProgram(
            outputFolder: String,
            arguments: MutableList<String> = mutableListOf())
            : Shell.CommandOutput?
        {
            log("\t- Running Kotlin...")

            val commandArguments: MutableList<String> = mutableListOf("java", "-jar", "kotlin.jar")

            commandArguments.addAll(arguments)

            val commandResult: Shell.CommandOutput? = Shell.runShellCommand(commandArguments, currentFolder = outputFolder)

            return commandResult
        }

        public fun transpileCompileAndRun(
            inputFiles: MutableList<String>,
            outputFolder: String = OS.buildFolder)
            : Shell.CommandOutput?
        {
            val compilationResult: Shell.CommandOutput? = transpileThenCompile(inputFiles = inputFiles, outputFolder = outputFolder)
            if (!(compilationResult != null && compilationResult!!.status == 0)) {
                return compilationResult
            }
            return runCompiledProgram(outputFolder = outputFolder)
        }
    }
}

internal fun Compiler.Companion.createErrorOrWarningMessage(
    message: String,
    details: String,
    sourceFile: SourceFile?,
    sourceFileRange: SourceFileRange?,
    isError: Boolean = true)
    : String
{
    val errorOrWarning: String = if (isError) { "error" } else { "warning" }
    if (sourceFile != null) {
        val sourceFilePath: String = sourceFile.path
        val relativePath: String = sourceFilePath
        if (sourceFileRange != null) {
            val sourceFileString: String = sourceFile.getLine(sourceFileRange.lineStart) ?: "<<Unable to get line ${sourceFileRange.lineStart} in file ${relativePath}>>"
            var underlineString: String = ""

            if (sourceFileRange.columnEnd < sourceFileString.length) {
                for (i in 1 until sourceFileRange.columnStart) {
                    val sourceFileCharacter: Char = sourceFileString[0 + i - 1]
                    if (sourceFileCharacter == '\t') {
                        underlineString += "\t"
                    }
                    else {
                        underlineString += " "
                    }
                }
                underlineString += "^"
                if (sourceFileRange.columnStart < sourceFileRange.columnEnd) {
                    for (_0 in (sourceFileRange.columnStart + 1) until sourceFileRange.columnEnd) {
                        underlineString += "~"
                    }
                }
            }

            return "${relativePath}:${sourceFileRange.lineStart}:" + "${sourceFileRange.columnStart}: ${errorOrWarning}: ${message}\n" + "${sourceFileString}\n" + "${underlineString}\n" + details
        }
        else {
            return "${relativePath}: ${errorOrWarning}: ${message}\n" + details
        }
    }
    else {
        return "${errorOrWarning}: ${message}\n" + details
    }
}
