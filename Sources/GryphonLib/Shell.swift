/*
* Copyright 2018 Vinícius Jorge Vendramini
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

import Foundation

#if os(Linux) || os(FreeBSD)
func stopTask(_ task: Process) {}
#else
func stopTask(_ task: Process) {
	task.interrupt()
}
#endif

public class Shell {
	public struct CommandOutput {
		let standardOutput: String
		let standardError: String
		let status: Int32
	}

	static let defaultTimeout: TimeInterval = 60

	/// Returns nil when the operation times out.
	@discardableResult
	internal static func runShellCommand(
		_ command: String,
		arguments: [String],
		fromFolder currentFolder: String? = nil,
		timeout: TimeInterval = Shell.defaultTimeout)
		-> CommandOutput!
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

		return CommandOutput(standardOutput: outputString,
				standardError: errorString,
				status: task.terminationStatus)
	}

	/// Returns nil when the operation times out.
	@discardableResult
	internal static func runShellCommand(
		_ arguments: [String],
		fromFolder currentFolder: String? = nil,
		timeout: TimeInterval = Shell.defaultTimeout) -> CommandOutput!
	{
		return runShellCommand(
			"/usr/bin/env",
			arguments: arguments,
			fromFolder: currentFolder,
			timeout: timeout)
	}
}
