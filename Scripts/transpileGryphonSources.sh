#!/bin/bash

./.build/debug/Gryphon \
	--indentation=4 \
	-print-ASTs-on-error \
	-skip-AST-dumps \
	--continue-on-error \
	Test\ Files/Bootstrap/gryphon-old/Sources/GryphonLib/AuxiliaryFileContents.swift \
	Test\ Files/Bootstrap/gryphon-old/Sources/GryphonLib/Compiler.swift \
	Test\ Files/Bootstrap/gryphon-old/Sources/GryphonLib/Driver.swift \
	Test\ Files/Bootstrap/gryphon-old/Sources/GryphonLib/Extensions.swift \
	Test\ Files/Bootstrap/gryphon-old/Sources/GryphonLib/GryphonAST.swift \
	Test\ Files/Bootstrap/gryphon-old/Sources/GryphonLib/GryphonSwiftLibrary.swift \
	Test\ Files/Bootstrap/gryphon-old/Sources/GryphonLib/KotlinTranslationResult.swift \
	Test\ Files/Bootstrap/gryphon-old/Sources/GryphonLib/KotlinTranslator.swift \
	Test\ Files/Bootstrap/gryphon-old/Sources/GryphonLib/LibraryTranspilationPass.swift \
	Test\ Files/Bootstrap/gryphon-old/Sources/GryphonLib/PrintableAsTree.swift \
	Test\ Files/Bootstrap/gryphon-old/Sources/GryphonLib/RubyScriptContents.swift \
	Test\ Files/Bootstrap/gryphon-old/Sources/GryphonLib/SharedUtilities.swift \
	Test\ Files/Bootstrap/gryphon-old/Sources/GryphonLib/SourceFile.swift \
	Test\ Files/Bootstrap/gryphon-old/Sources/GryphonLib/SwiftAST.swift \
	Test\ Files/Bootstrap/gryphon-old/Sources/GryphonLib/TranspilationContext.swift \
	Test\ Files/Bootstrap/gryphon-old/Sources/GryphonLib/TranspilationPass.swift \
	Test\ Files/Bootstrap/gryphon-old/Tests/GryphonLibTests/AcceptanceTest.swift \
	Test\ Files/Bootstrap/gryphon-old/Tests/GryphonLibTests/CompilerTest.swift \
	Test\ Files/Bootstrap/gryphon-old/Tests/GryphonLibTests/DriverTest.swift \
	Test\ Files/Bootstrap/gryphon-old/Tests/GryphonLibTests/ExtensionsTest.swift \
	Test\ Files/Bootstrap/gryphon-old/Tests/GryphonLibTests/IntegrationTest.swift \
	Test\ Files/Bootstrap/gryphon-old/Tests/GryphonLibTests/KotlinTranslationResultTest.swift \
	Test\ Files/Bootstrap/gryphon-old/Tests/GryphonLibTests/LibraryTranspilationTest.swift \
	Test\ Files/Bootstrap/gryphon-old/Tests/GryphonLibTests/ListTest.swift \
	Test\ Files/Bootstrap/gryphon-old/Tests/GryphonLibTests/MutableListTest.swift \
	Test\ Files/Bootstrap/gryphon-old/Tests/GryphonLibTests/MapTest.swift \
	Test\ Files/Bootstrap/gryphon-old/Tests/GryphonLibTests/MutableMapTest.swift \
	Test\ Files/Bootstrap/gryphon-old/Tests/GryphonLibTests/PrintableAsTreeTest.swift \
	Test\ Files/Bootstrap/gryphon-old/Tests/GryphonLibTests/ShellTest.swift \
	Test\ Files/Bootstrap/gryphon-old/Tests/GryphonLibTests/SourceFileTest.swift \
	Test\ Files/Bootstrap/gryphon-old/Tests/GryphonLibTests/UtilitiesTest.swift \
	Test\ Files/Bootstrap/gryphon-old/Tests/GryphonLibTests/SharedTestUtilities.swift \
	--skip \
	Test\ Files/Bootstrap/gryphon-old/Sources/GryphonLib/Shell.swift \
	Test\ Files/Bootstrap/gryphon-old/Sources/GryphonLib/Utilities.swift \
	Test\ Files/Bootstrap/gryphon-old/Tests/GryphonLibTests/TestUtilities.swift \
	Test\ Files/Bootstrap/gryphon-old/.gryphon/GryphonXCTest.swift
