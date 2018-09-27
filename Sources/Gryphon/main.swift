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
    with closure: (String, String) -> ())
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
            closure(originFilePath, destinationFilePath)
        }
    }
}

func updateFiles(inFolder folder: String) {
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

    updateFiles(in: folder, from: .grySwiftAstJson, to: .expectedGrySwiftAstJson)
    { (jsonFilePath: String, expectedJsonFilePath: String) in
        let jsonContents = try! String(contentsOfFile: jsonFilePath)
        let expectedJsonURL = URL(fileURLWithPath: expectedJsonFilePath)
        try! jsonContents.write(to: expectedJsonURL, atomically: false, encoding: .utf8)
    }

	updateFiles(in: folder, from: .grySwiftAstJson, to: .gryAstJson)
	{ (swiftAstFilePath: String, gryphonAstFilePath: String) in
		let swiftAst = GRYSwiftAst.initialize(fromJsonInFile: swiftAstFilePath)
		let gryphonAst = GRYSwift4_1Translator().translateAST(swiftAst)
		gryphonAst.writeAsJSON(toFile: gryphonAstFilePath)

		let jsonContents = try! String(contentsOfFile: gryphonAstFilePath)
		let astData = Data(jsonContents.utf8)
		let decodedAst = try! JSONDecoder().decode(GRYSourceFile.self, from: astData)
		decodedAst.prettyPrint(horizontalLimit: 100)
	}

	print("Done!")
}

func main() {
    updateFiles(inFolder: "Test Files")
    updateFiles(inFolder: "Example ASTs")

//    let filePath = Process().currentDirectoryPath + "/Test Files/assignments.swift"
    let filePath = Process().currentDirectoryPath + "/Example ASTs/test.swift"

	let swiftAst = GRYCompiler.generateAST(forFileAt: filePath)
	let ast = GRYSwift4_1Translator().translateAST(swiftAst)
	print(swiftAst.description(withHorizontalLimit: 60))
	print("--")
	ast!.prettyPrint()

//	print(GRYCompiler.getSwiftASTDump(forFileAt: filePath))
//    print(GRYCompiler.generateAST(forFileAt: filePath).description(withHorizontalLimit: 100))
//    print(GRYCompiler.processExternalAST(filePath))
//    let (code, _, _) =
//        GRYCompiler.generateKotlinCodeWithDiagnostics(forFileAt: filePath)
//	print(ast.description(withHorizontalLimit: 100))
//  print(code ?? "Failed to translate Kotlin code.")
//	print(diagnostics)
//	print(GRYCompiler.compileAndRun(fileAt: filePath))
}

main()
