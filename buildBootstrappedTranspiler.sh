kotlinc -include-runtime \
	-d Bootstrap/kotlin.jar \
	Bootstrap/PrintableAsTree.kt \
	Bootstrap/PrintableAsTreeTest.kt \
	Bootstrap/KotlinTests.kt \
	Bootstrap/KotlinStandardLibrary.kt \
	Bootstrap/ASTDumpDecoder.kt \
	Bootstrap/ASTDumpDecoderTest.kt \
	Bootstrap/main.kt \
	Bootstrap/Extensions.kt \
	Bootstrap/ExtensionsTest.kt \
	Bootstrap/SwiftAST.kt \
	Bootstrap/Utilities.kt \
    Bootstrap/SharedUtilities.kt \
	Bootstrap/UtilitiesTest.kt \
	Bootstrap/Compiler.kt \
	Bootstrap/SourceFile.kt \
	Bootstrap/Driver.kt \
	Bootstrap/OutputFileMap.kt \
	Bootstrap/GryphonAST.kt \
	Bootstrap/SwiftTranslator.kt \
	Bootstrap/TranspilationPass.kt \
	Bootstrap/KotlinTranslator.kt \
	Bootstrap/LibraryTranspilationPass.kt \
	Bootstrap/Shell.kt \
	Bootstrap/ShellTest.kt;
