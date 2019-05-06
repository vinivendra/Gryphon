kotlinc -include-runtime \
	-d Bootstrap/kotlin.jar \
	Bootstrap/PrintableAsTree.kt \
	Bootstrap/PrintableAsTreeTest.kt \
	Bootstrap/KotlinTests.kt \
	Bootstrap/StandardLibrary.kt \
	Bootstrap/ASTDumpDecoder.kt \
	Bootstrap/ASTDumpDecoderTest.kt \
	Bootstrap/main.kt \
	Bootstrap/Extensions.kt \
	Bootstrap/ExtensionsTest.kt \
	Bootstrap/SwiftAST.kt \
	Bootstrap/Utilities.kt \
	Bootstrap/UtilitiesTest.kt \
	Bootstrap/Compiler.kt \
	Bootstrap/SourceFile.kt \
	Bootstrap/Driver.kt \
	Bootstrap/OutputFileMap.kt \
	Bootstrap/GryphonAST.kt \
	Bootstrap/SwiftTranslator.kt;

java -jar Bootstrap/kotlin.jar -emit-swiftAST \
	Test\ Files/*.swift -output-file-map=output-file-map-tests.json;

java -jar Bootstrap/kotlin.jar -emit-rawAST \
	Test\ Files/*.swift -output-file-map=output-file-map-tests.json;
