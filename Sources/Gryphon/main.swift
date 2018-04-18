import Foundation
import GryphonLib

func main() {
	let filePath = Process().currentDirectoryPath + "/test.swift"
	_ = GRYCompiler.compile(fileAt: filePath)
	
//	let testFilePath = Process().currentDirectoryPath + "/Test Files/<#testFileName#>.swift"
//	print(GRYCompiler.generateAstJson(forFileAt: testFilePath)!)
}

main()
