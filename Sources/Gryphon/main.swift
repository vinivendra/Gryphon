import Foundation
import GryphonLib

func main() {
//	let filePath = Process().currentDirectoryPath + "/Test Files/<#testFileName#>.swift"
	let filePath = Process().currentDirectoryPath + "/test.swift"

//	print(GRYCompiler.generateAstJson(forFileAt: filePath)!)
	print(GRYCompiler.generateAST(forFileAt: filePath))
	print(GRYCompiler.generateKotlinMainCode(forFileAt: filePath))
	print(GRYCompiler.compileAndRun(fileAt: filePath))
}

main()
