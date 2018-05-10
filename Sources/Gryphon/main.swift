import Foundation
import GryphonLib

func updateJsonTestFiles(includeParserTests: Bool = false) {
	
	let currentURL = URL(fileURLWithPath: Process().currentDirectoryPath + "/Test Files")
	let fileURLs = try! FileManager.default.contentsOfDirectory(at: currentURL, includingPropertiesForKeys: nil)
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
	let jsonIsOutdated = jsonFileWasJustCreated || GRYUtils.file(astFilePath, wasModifiedLaterThan: jsonFilePath)
	
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
	updateJsonTestFiles(includeParserTests: true)

//	let filePath = Process().currentDirectoryPath + "/Test Files/<#testFile#>.swift"
//	let filePath = Process().currentDirectoryPath + "/test.swift"

//	print(GRYCompiler.getSwiftASTDump(forFileAt: filePath))
//	print(GRYCompiler.generateAST(forFileAt: filePath).description(withHorizontalLimit: 100))
//	print(GRYCompiler.generateKotlinCode(forFileAt: filePath))
//	print(GRYCompiler.compileAndRun(fileAt: filePath))
}

main()
