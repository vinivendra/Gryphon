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

func updateFiles(
	in folder: String,
	from originExtension: GRYFileExtension,
	to destinationExtension: GRYFileExtension,
	with closure: (String, String) throws -> ()) rethrows
{
	let currentURL = URL(fileURLWithPath: Process().currentDirectoryPath + "/" + folder)
	let fileURLs = try! FileManager.default.contentsOfDirectory(
		at: currentURL,
		includingPropertiesForKeys: nil)
	let testFiles = fileURLs.filter { $0.pathExtension == originExtension.rawValue }.sorted
	{ (url1: URL, url2: URL) -> Bool in
		url1.absoluteString < url2.absoluteString
	}

	for originFile in testFiles {
		let originFilePath = originFile.path
		let destinationFilePath =
			GRYUtils.changeExtension(of: originFilePath, to: destinationExtension)

		let destinationFileWasJustCreated =
			GRYUtils.createFileIfNeeded(at: destinationFilePath, containing: "")
		let destinationFileIsOutdated = destinationFileWasJustCreated ||
			GRYUtils.file(originFilePath, wasModifiedLaterThan: destinationFilePath)

		if destinationFileIsOutdated {
			print("\tUpdating \(destinationFilePath)...")
			try closure(originFilePath, destinationFilePath)
		}
	}
}

func updateFiles(inFolder folder: String) throws {
	print("Updating files in \(folder)...")

	updateFiles(in: folder, from: .swift, to: .swiftAstDump)
	{ (_: String, astFilePath: String) in
		// The swiftAstDump files must be updated externally by the perl script. If any files are
		// out of date, this closure gets called and informs the user how to update them.
		fatalError("Please update ast file \(astFilePath) with the `dump-ast.pl` perl script.")
	}

	updateFiles(in: folder, from: .swiftAstDump, to: .grySwiftAstJson)
	{ (dumpFilePath: String, jsonFilePath: String) in
		let ast = GRYSwiftAst(astFile: dumpFilePath)
		ast.writeAsJSON(toFile: jsonFilePath)
	}

	try updateFiles(in: folder, from: .grySwiftAstJson, to: .gryRawAstJson)
	{ (swiftAstFilePath: String, gryphonAstRawFilePath: String) in
		let swiftAst = GRYSwiftAst.initialize(fromJsonInFile: swiftAstFilePath)
		let gryphonAst = try GRYSwift4Translator().translateAST(swiftAst)
		gryphonAst.writeAsJSON(toFile: gryphonAstRawFilePath)
	}

	try updateFiles(in: folder, from: .gryRawAstJson, to: .gryAstJson)
	{ (gryphonAstRawFilePath: String, gryphonAstFilePath: String) throws in
		let gryphonAstRaw = GRYAst.initialize(fromJsonInFile: gryphonAstRawFilePath)
		let gryphonAst = GRYTranspilationPass.runAllPasses(on: gryphonAstRaw)
		gryphonAst.writeAsJSON(toFile: gryphonAstFilePath)
	}

	print("Done!")
}

func main() {
	do {
		try updateFiles(inFolder: "Test Files")
		try updateFiles(inFolder: "Example ASTs")

		////////////////////////////////////////////////////////////////////////////////////////////
		// Set the path to the desired input file as the `filePath`.

//		let filePath = Process().currentDirectoryPath + "/Test Files/kotlinLiterals.swift"
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
//		print(GRYCompiler.getSwiftASTDump(forFileAt: filePath))

		// 2: Swiftc's Ast dump -> Gryphon's version of the Swift Ast
//		GRYCompiler.generateSwiftAST(forFileAt: filePath).prettyPrint(horizontalLimit: 100)

		// 3: Swiftc's Ast dump -> Swift Ast -> Gryphon's internal Ast (raw, before passes)
//		try GRYCompiler.generateGryphonAst(forFileAt: filePath).prettyPrint(horizontalLimit: 100)

		// 3.1: Swiftc's Ast dump -> Swift Ast -> Gryphon Ast (raw) + Gryphon Ast (after passes)
//		try GRYCompiler.generateGryphonAstAndRunPasses(forFileAt: filePath)
//			.prettyPrint(horizontalLimit: 100)

		// 4: Swiftc's Ast dump -> Swift Ast -> Gryphon Ast (raw) + Gryphon Ast -> Kotlin code
//		try print(GRYCompiler.generateKotlinCode(forFileAt: filePath))

		// 5: Ast dump -> Swift Ast -> GRYAst (raw) -> GRYAst -> Kotlin -> Output of running Kotlin
		try print(GRYCompiler.compileAndRun(fileAt: filePath))
	}
	catch let error {
		if let error = error as? GRYPrintableError {
			error.print()
		}
		else {
			print("Unexpected error: \(error)")
			fatalError()
		}
	}
}

main()
