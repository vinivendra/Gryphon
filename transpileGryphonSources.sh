#!/bin/bash

./.build/debug/Gryphon \
	--indentation=4 \
	--quiet \
	\
	Sources/GryphonLib/ASTDumpDecoder.swift \
	Sources/GryphonLib/AuxiliaryFileContents.swift \
	Sources/GryphonLib/Compiler.swift \
	Sources/GryphonLib/Driver.swift \
	Sources/GryphonLib/Extensions.swift \
	Sources/GryphonLib/GryphonAST.swift \
	Sources/GryphonLib/GryphonSwiftLibrary.swift \
	Sources/GryphonLib/KotlinTranslationResult.swift \
	Sources/GryphonLib/KotlinTranslator.swift \
	Sources/GryphonLib/LibraryTranspilationPass.swift \
	Sources/GryphonLib/PrintableAsTree.swift \
	Sources/GryphonLib/SharedUtilities.swift \
	Sources/GryphonLib/SourceFile.swift \
	Sources/GryphonLib/SwiftAST.swift \
	Sources/GryphonLib/SwiftTranslator.swift \
	Sources/GryphonLib/TranspilationContext.swift \
	Sources/GryphonLib/TranspilationPass.swift \
	\
	Tests/GryphonLibTests/AcceptanceTest.swift \
	Tests/GryphonLibTests/ASTDumpDecoderTest.swift \
	Tests/GryphonLibTests/CompilerTest.swift \
	Tests/GryphonLibTests/DriverTest.swift \
	Tests/GryphonLibTests/ExtensionsTest.swift \
	Tests/GryphonLibTests/IntegrationTest.swift \
	Tests/GryphonLibTests/KotlinTranslationResultTest.swift \
	Tests/GryphonLibTests/LibraryTranspilationTest.swift \
	Tests/GryphonLibTests/ListTest.swift \
	Tests/GryphonLibTests/MutableListTest.swift \
	Tests/GryphonLibTests/MapTest.swift \
	Tests/GryphonLibTests/MutableMapTest.swift \
	Tests/GryphonLibTests/PrintableAsTreeTest.swift \
	Tests/GryphonLibTests/ShellTest.swift \
	Tests/GryphonLibTests/SourceFileTest.swift \
	Tests/GryphonLibTests/UtilitiesTest.swift \
	\
	Tests/GryphonLibTests/SharedTestUtilities.swift \
	\
	--skip \
	Sources/GryphonLib/Shell.swift \
	Sources/GryphonLib/Utilities.swift \
	Tests/GryphonLibTests/TestUtilities.swift \
	.gryphon/GryphonXCTest.swift
