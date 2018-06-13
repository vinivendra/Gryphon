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

func updateJsonTestFiles(includeParserTests: Bool = false) {
	
	let currentURL = URL(fileURLWithPath: Process().currentDirectoryPath + "/Test Files")
	let fileURLs = try! FileManager.default.contentsOfDirectory(
		at: currentURL,
		includingPropertiesForKeys: nil)
	var testFiles = fileURLs.filter { $0.pathExtension == "swift" }
	
	let mainTestFile = URL(fileURLWithPath: Process().currentDirectoryPath + "/test.swift")
	testFiles.append(mainTestFile)
	
	print("Updating JSON files\(includeParserTests ? " and parser tests" : "")...")
	
	for swiftFile in testFiles {
		updateJsonTestFile(swiftFile, includeParserTests: includeParserTests)
	}
	
	print("Done!")
}

func updateJsonTestFile(_ swiftFile: URL, includeParserTests: Bool) {
	let swiftFilePath = swiftFile.path
	let astFilePath = GRYUtils.changeExtension(of: swiftFilePath, to: "ast")
	let jsonFilePath = GRYUtils.changeExtension(of: swiftFilePath, to: "json")
	let expectedJsonFilePath = GRYUtils.changeExtension(of: swiftFilePath, to: "expectedJson")
	
	let jsonFileWasJustCreated = GRYUtils.createFileIfNeeded(at: jsonFilePath, containing: "")
	let jsonIsOutdated =
		jsonFileWasJustCreated || GRYUtils.file(astFilePath, wasModifiedLaterThan: jsonFilePath)
	
	if jsonIsOutdated {
		let astIsOutdated = GRYUtils.file(swiftFilePath, wasModifiedLaterThan: astFilePath)
		
		if astIsOutdated {
			fatalError("Please update ast file \(astFilePath) with the `dump-ast.pl` perl script.")
		}
		
		print("\tUpdating \(swiftFilePath)...")
		
		let ast = GRYCompiler.generateAST(forFileAt: swiftFilePath)
		ast.writeAsJSON(toFile: jsonFilePath)
		
		if includeParserTests {
			ast.writeAsJSON(toFile: expectedJsonFilePath)
		}
	}
}

func main() {
	updateJsonTestFiles(includeParserTests: false)

//	let filePath = Process().currentDirectoryPath + "/Test Files/<#testFile#>.swift"
	let filePath = Process().currentDirectoryPath + "/test.swift"

//	print(GRYCompiler.getSwiftASTDump(forFileAt: filePath))
//	print(GRYCompiler.generateAST(forFileAt: filePath).description(withHorizontalLimit: 100))
	print(GRYCompiler.processExternalAST(filePath))
	let (code, diagnostics) = GRYCompiler.generateKotlinCodeAndDiagnostics(forFileAt: filePath)
	print(code)
	print(diagnostics)
//	print(GRYCompiler.compileAndRun(fileAt: filePath))
}

main()
