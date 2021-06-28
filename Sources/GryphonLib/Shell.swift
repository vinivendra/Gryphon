//
// Copyright 2018 Vinicius Jorge Vendramini
//
// Licensed under the Hippocratic License, Version 2.1;
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://firstdonoharm.dev/version/2/1/license
//
// To the full extent allowed by law, this software comes "AS IS,"
// WITHOUT ANY WARRANTY, EXPRESS OR IMPLIED, and licensor and any other
// contributor shall not be liable to anyone for any damages or other
// liability arising from, out of, or in connection with the sotfware
// or this license, under any kind of legal claim.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

/// Used for executing command line programs. Heavily inspired by (and used with the permission of):
/// https://github.com/SDGGiesbrecht/SDGCornerstone/blob/
///     54d06623981e6746e957b156d14aad373578af46/Sources/SDGCornerstone/Shell/Shell.swift
public struct Shell {
	public struct CommandOutput {
		public let standardOutput: String
		public let standardError: String
		public let status: Int32
	}

	/// Used to split data received from process pipes into separate lines
	private static let newLine = "\n"
	private static let newLineData = newLine.data(using: String.Encoding.utf8)!

	/// Reads available data from the pipe and appends it to the stream, one line of text at a
	/// time. Returns `true` if there's still more data to read, `false` otherwise.
	private static func handleInput(pipe: Pipe, stream: inout Data, result: inout String) -> Bool {
		let newData = pipe.fileHandleForReading.availableData
		stream.append(newData)

		while let lineEnd = stream.range(of: newLineData) {
			let line = stream.subdata(in: stream.startIndex ..< lineEnd.lowerBound)
			stream.removeSubrange(stream.startIndex ..< lineEnd.upperBound)
			let string = String(data: line, encoding: .utf8) ?? ""
			result.append(string + newLine)
		}

		return !newData.isEmpty
	}

	/// An operation queue used to read a process's standard error at the same time that the
	/// process's standard output is read in the main queue
	private static func createStandardErrorQueue() -> OperationQueue {
		let queue = OperationQueue()
		queue.name = String("shell_background")
		queue.maxConcurrentOperationCount =
			OperationQueue.defaultMaxConcurrentOperationCount
		return queue
	}

	@discardableResult
	internal static func runShellCommand(
		_ command: String,
		arguments: List<String>,
		fromFolder currentFolder: String? = nil)
		-> CommandOutput
	{
		Compiler.log("🛠  \(arguments.joined(separator: " "))")

		let process = Process()
		let standardOutput = Pipe()
		let standardError = Pipe()

		process.arguments = arguments.array
		process.qualityOfService = .userInitiated
		process.standardOutput = standardOutput
		process.standardError = standardError

		if #available(OSX 10.13, *) {
			process.executableURL = URL(fileURLWithPath: command)
			if let currentFolder = currentFolder {
				process.currentDirectoryURL = URL(fileURLWithPath: currentFolder)
			}
			try! process.run()
		} else {
			process.launchPath = command
			if let currentFolder = currentFolder {
				process.currentDirectoryPath = currentFolder
			}
			process.launch()
		}

		var output = ""
		var outputStream = Data()
		var error = ""
		var errorStream = Data()

		let standardErrorQueue = createStandardErrorQueue()
		standardErrorQueue.addOperation(BlockOperation(block: {
				while handleInput(pipe: standardError, stream: &errorStream, result: &error) {}
			}))

		while handleInput(pipe: standardOutput, stream: &outputStream, result: &output) {}

		standardErrorQueue.waitUntilAllOperationsAreFinished()

		while process.isRunning {}

		let status = process.terminationStatus

		let result = CommandOutput(
			standardOutput: output,
			standardError: error,
			status: status)

		return result
	}

	@discardableResult
	internal static func runShellCommand(
		_ arguments: List<String>,
		fromFolder currentFolder: String? = nil)
		-> CommandOutput
	{
		return runShellCommand(
			"/usr/bin/env",
			arguments: arguments,
			fromFolder: currentFolder)
	}
}
