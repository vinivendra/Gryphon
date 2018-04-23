import Foundation
import GryphonLib

func updateJsonTestFiles() {
	
	let currentURL = URL(fileURLWithPath: Process().currentDirectoryPath + "/Test Files")
	let fileURLs = try! FileManager.default.contentsOfDirectory(at: currentURL, includingPropertiesForKeys: nil)
	let testFiles = fileURLs.filter { $0.pathExtension == "swift" }
	
	print("Updating JSON files...")
	
	for testFile in testFiles {
		let testFilePath = testFile.path
		print("\tUpdating \(testFilePath)...")
		GRYCompiler.updateAstJson(forFileAt: testFilePath)
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
