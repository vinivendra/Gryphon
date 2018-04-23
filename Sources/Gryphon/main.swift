import Foundation
import GryphonLib

func updateJsonTestFiles() {
	
	let currentURL = URL(fileURLWithPath: Process().currentDirectoryPath + "/Test Files")
	let fileURLs = try! FileManager.default.contentsOfDirectory(at: currentURL, includingPropertiesForKeys: nil)
	let testFiles = fileURLs.filter { $0.pathExtension == "swift" }
	
	print("Updating JSON files...")
	
	for swiftFile in testFiles {
		let swiftFilePath = swiftFile.path
		let jsonFilePath = GRYUtils.changeExtension(of: swiftFilePath, to: "json")
		let jsonIsOutdated = GRYUtils.file(swiftFilePath, wasModifiedLaterThan: jsonFilePath)
		
		if jsonIsOutdated {
			let astFilePath = GRYUtils.changeExtension(of: swiftFilePath, to: "ast")
			let astIsOutdated = GRYUtils.file(swiftFilePath, wasModifiedLaterThan: astFilePath)
		
			if astIsOutdated {
				fatalError("Please update ast file \(astFilePath) with the `dump-ast.pl` perl script.")
			}
			
			print("\tUpdating \(swiftFilePath)...")
			GRYCompiler.updateAstJson(forFileAt: swiftFilePath)
		}
	}
	
	print("Done!")
}

func main() {
	updateJsonTestFiles()

//	let filePath = Process().currentDirectoryPath + "/Test Files/strings.swift"
//	let filePath = Process().currentDirectoryPath + "/test.swift"

//	print(GRYCompiler.getSwiftASTDump(forFileAt: filePath))
//	print(GRYCompiler.generateAST(forFileAt: filePath))
//	print(GRYCompiler.generateKotlinCode(forFileAt: filePath))
//	print(GRYCompiler.compileAndRun(fileAt: filePath))
}

main()
