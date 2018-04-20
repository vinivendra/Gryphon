import Foundation
import GryphonLib

func main() {
	let filePath = Process().currentDirectoryPath + "/Test Files/functionCalls.swift"
//	let filePath = Process().currentDirectoryPath + "/test.swift"

//	print(GRYCompiler.getSwiftASTDump(forFileAt: filePath))
	print(GRYCompiler.generateAstJson(forFileAt: filePath)!)
//	print(GRYCompiler.generateAST(forFileAt: filePath))
	print(GRYCompiler.generateKotlinCode(forFileAt: filePath))
//	print(GRYCompiler.compileAndRun(fileAt: filePath))
}

main()
