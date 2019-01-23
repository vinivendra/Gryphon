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

//	let filePath = Process().currentDirectoryPath + "/Test Files/kotlinLiterals.swift"
	let filePath = Process().currentDirectoryPath + "/Example ASTs/test.swift"

	////////////////////////////////////////////////////////////////////////////////////////////
	// The following (possibly commented) lines of code execute the transpilation process up to
	// a specific step, then print the result. The first line only runs the first step, the
	// second runs the first two steps, and so forth. Commenting and un-commenting specific
	// lines allows you to visualize the compilation steps seprately.
	//
	// Note that if the input file is a .swiftAstDump file instead of a .swift file the
	// transpiler should still work normally.

	// 1: Run the swift compiler and get its Ast dump
//	try print(GRYCompiler.getSwiftASTDump(forFileAt: filePath))

	// 2: Swiftc's Ast dump -> Gryphon's version of the Swift Ast
//	try GRYCompiler.generateSwiftAST(forFileAt: filePath).prettyPrint(horizontalLimit: 100)

	// 3: Swiftc's Ast dump -> Swift Ast -> Gryphon's internal Ast (raw, before passes)
//	try GRYCompiler.generateGryphonAst(forFileAt: filePath).prettyPrint(horizontalLimit: 100)

	// 3.1: Swiftc's Ast dump -> Swift Ast -> Gryphon Ast (raw) + Gryphon Ast (after passes)
//	try GRYCompiler.generateGryphonAstAndRunPasses(forFileAt: filePath)
//		.prettyPrint(horizontalLimit: 100)

	// 4: Swiftc's Ast dump -> Swift Ast -> Gryphon Ast (raw) + Gryphon Ast -> Kotlin code
//	try print(GRYCompiler.generateKotlinCode(forFileAt: filePath))

	// 5: Ast dump -> Swift Ast -> GRYAst (raw) -> GRYAst -> Kotlin -> Output of running Kotlin
	try print(GRYCompiler.compileAndRun(fileAt: filePath))

	for warning in GRYTranspilationPass.warnings {
		print("warning: \(warning)")
}
}
catch let error {
	print("🚨 Error:\n\(error)")
}
