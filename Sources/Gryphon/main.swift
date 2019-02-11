/*
* Copyright 2018 Vinícius Jorge Vendramini
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

import Foundation
import GryphonLib

do {
	// Set the path to the desired input file as the `filePath`.

//	let filePath = Process().currentDirectoryPath + "/Test Files/bhaskara.swift"
	let filePath = Process().currentDirectoryPath + "/Example ASTs/test.swift"
//	let filePath =
//		Process().currentDirectoryPath + "/Sources AST Dumps/GRYPrintableAsTree.swiftASTDump"

	////////////////////////////////////////////////////////////////////////////////////////////
	// The following (possibly commented) lines of code execute the transpilation process up to
	// a specific step, then print the result. The first line only runs the first step, the
	// second runs the first two steps, and so forth. Commenting and un-commenting specific
	// lines allows you to visualize the compilation steps seprately.
	//
	// Note that if the input file is a .swiftASTDump file instead of a .swift file the
	// transpiler should still work normally.

	// 1: Run the swift compiler and get its AST dump
//	try print(GRYCompiler.getSwiftASTDump(forFileAt: filePath))

	// 2: Swiftc's AST dump -> Gryphon's version of the Swift AST
//	try GRYCompiler.generateSwiftAST(forFileAt: filePath).prettyPrint()

	// 3: Swiftc's AST dump -> Swift AST -> Gryphon's internal AST (raw, before passes)
//	try GRYCompiler.generateGryphonAST(forFileAt: filePath).prettyPrint()

	// 3.1: Swiftc's AST dump -> Swift AST -> Gryphon AST (raw) + Gryphon AST (after passes)
//	try GRYCompiler.generateGryphonASTAndRunPasses(forFileAt: filePath)
//		.prettyPrint()

	// 4: Swiftc's AST dump -> Swift AST -> Gryphon AST (raw) + Gryphon AST -> Kotlin code
	 try print(GRYCompiler.generateKotlinCode(forFileAt: filePath))

	// 5: AST dump -> Swift AST -> GRYAST (raw) -> GRYAST -> Kotlin -> Output of running Kotlin
//	try print(GRYCompiler.compileAndRun(fileAt: filePath))

	for warning in GRYTranspilationPass.warnings {
		print("warning: \(warning)")
}
}
catch let error {
	print("🚨 Error:\n\(error)")
}
