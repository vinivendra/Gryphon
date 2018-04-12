import Foundation

internal enum Shell {
    @discardableResult
    static func runShellCommand(_ arguments: [String]) -> (standardOutput: String, standardError: String, status: Int32) {
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = arguments
        task.standardOutput = outputPipe
        task.standardError = errorPipe
        task.launch()
        task.waitUntilExit()
        
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let outputString = String(data: outputData, encoding: .utf8) ?? ""
        
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        let errorString = String(data: errorData, encoding: .utf8) ?? ""
        
        return (standardOutput: outputString,
                standardError: errorString,
                status: task.terminationStatus)
    }
}
