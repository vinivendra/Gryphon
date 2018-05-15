import Foundation

#if os(Linux) || os(FreeBSD)
func stopTask(_ task: Process) {}
#else
func stopTask(_ task: Process) {
	task.interrupt()
}
#endif

public enum GRYShell {
	public typealias CommandOutput = (standardOutput: String, standardError: String, status: Int32)

	static let defaultTimeout: TimeInterval = 60

	/// Returns nil when the operation times out.
	@discardableResult
	internal static func runShellCommand(_ command: String, arguments: [String],
										 fromFolder currentFolder: String? = nil,
										 timeout: TimeInterval = GRYShell.defaultTimeout) -> CommandOutput!
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
		
		let startTime = Date()
		while task.isRunning,
			Date().timeIntervalSince(startTime) < timeout { }
		
		guard !task.isRunning else {
			stopTask(task)
			return nil
		}
		
		let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
		let outputString = String(data: outputData, encoding: .utf8) ?? ""
		
		let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
		let errorString = String(data: errorData, encoding: .utf8) ?? ""
		
		return (standardOutput: outputString,
				standardError: errorString,
				status: task.terminationStatus)
	}
	
	/// Returns nil when the operation times out.
	@discardableResult
	internal static func runShellCommand(_ arguments: [String],
										 fromFolder currentFolder: String? = nil,
										 timeout: TimeInterval = GRYShell.defaultTimeout) -> CommandOutput!
	{
		return runShellCommand("/usr/bin/env", arguments: arguments, fromFolder: currentFolder, timeout: timeout)
	}
}
