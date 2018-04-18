import Foundation
import GryphonLib

func main() {
//	let filePath = Process().currentDirectoryPath + "/Test Files/<#testFileName#>.swift"
	let filePath = Process().currentDirectoryPath + "/test.swift"

//	print(GRYCompiler.generateAstJson(forFileAt: testFilePath)!)
	print(GRYCompiler.compile(fileAt: filePath))
//	print(GRYCompiler.generateAstJson(forFileAt: filePath)!)
}

main()
