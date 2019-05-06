kotlinc -include-runtime -d kotlin.jar PrintableAsTree.kt PrintableAsTreeTest.kt KotlinTests.kt StandardLibrary.kt ASTDumpDecoder.kt ASTDumpDecoderTest.kt main.kt Extensions.kt ExtensionsTest.kt SwiftAST.kt Utilities.kt UtilitiesTest.kt Compiler.kt SourceFile.kt Driver.kt OutputFileMap.kt GryphonAST.kt SwiftTranslator.kt;

java -jar kotlin.jar -emit-swiftAST ../Test\ Files/*.swift -output-file-map=../output-file-map-tests.json;

