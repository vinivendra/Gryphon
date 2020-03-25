//
// Copyright 2018 Vinicius Jorge Vendramini
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
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
	private static let standardErrorQueue: OperationQueue =  {
			let queue = OperationQueue()
			queue.name = String("shell_background")
			queue.maxConcurrentOperationCount =
				OperationQueue.defaultMaxConcurrentOperationCount
			return queue
		}()

	@discardableResult
	internal static func runShellCommand(
		_ command: String,
		arguments: List<String>,
		fromFolder currentFolder: String? = nil)
		-> CommandOutput
	{
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

		var completeErrorReceived = false
		standardErrorQueue.addOperation(BlockOperation(block: {
				while handleInput(pipe: standardError, stream: &errorStream, result: &error) {}
				completeErrorReceived = true
			}))

		while handleInput(pipe: standardOutput, stream: &outputStream, result: &output) {}
		while !completeErrorReceived {}

		while process.isRunning {}

		let status = process.terminationStatus

		return CommandOutput(standardOutput: output, standardError: error, status: status)
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
