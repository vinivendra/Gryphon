import Foundation
import GryphonLib

func main() {
    let testFilePath = Process().currentDirectoryPath + "/test.swift"
    _ = GRYCompiler.compile(fileAt: testFilePath)
}

main()
