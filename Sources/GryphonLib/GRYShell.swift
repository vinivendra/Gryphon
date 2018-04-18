import Foundation

public enum GRYShell {
	public typealias CommandOutput = (standardOutput: String, standardError: String, status: Int32)
	
	@discardableResult
	internal static func runShellCommand(_ command: String, arguments: [String], fromFolder currentFolder: String? = nil)
		-> CommandOutput
	{
		let outputPipe = Pipe()
		let errorPipe = Pipe()
		let task = Process()
		task.launchPath = command
		task.arguments = arguments
		task.standardOutput = outputPipe
		task.standardError = errorPipe
		
		if let currentFolder = currentFolder {
			task.currentDirectoryPath = currentFolder
		}
		
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
	
	@discardableResult
	internal static func runShellCommand(_ arguments: [String], fromFolder currentFolder: String? = nil)
		-> CommandOutput
	{
		return runShellCommand("/usr/bin/env", arguments: arguments, fromFolder: currentFolder)
	}
}
