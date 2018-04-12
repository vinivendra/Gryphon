import GryphonLib

func main() {
    
    // Get the file path
    guard CommandLine.arguments.count >= 2 else {
        let commandPath = CommandLine.arguments[0]
        let commandName = commandPath.split(separator: "/").last!
        print("Usage: \(commandName) <filePath>")
        return
    }
    let testFilePath = CommandLine.arguments[1]

    _ = GRYCompiler.compile(fileAt: testFilePath)
}

main()
