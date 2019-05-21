//
// Copyright 2018 Vinícius Jorge Vendramini
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
// declaration: import java.io.File

private typealias OutputFileMapBuffer =
	DictionaryClass<String, DictionaryClass<OutputFileMap.OutputType, String>>

public class OutputFileMap {
	public enum OutputType: String {
		case astDump = "ast-dump"
		case swiftAST
		case gryphonASTRaw
		case gryphonAST
		case kotlin

		init?(fileExtension: FileExtension) {
			switch fileExtension {
			case .swiftASTDump:
				self = .astDump
			case .swiftAST:
				self = .swiftAST
			case .kt:
				self = .kotlin
			default:
				return nil
			}
		}
	}

	private var buffer: OutputFileMapBuffer

	private init(buffer: OutputFileMapBuffer) {
		self.buffer = buffer
	}

	public func getFileMap(forInputFile file: String) -> DictionaryClass<OutputType, String>? {
		return buffer[Utilities.getAbsoultePath(forFile: file)]
	}

	public func getOutputFile(forInputFile file: String, outputType: OutputType) -> String? {
		guard let fileMap = getFileMap(forInputFile: file) else {
			return nil
		}
		return fileMap[outputType]
	}

	public init(_ file: String) {
		let contents = try! Utilities.readFile(file)

		let result: DictionaryClass<String, DictionaryClass<OutputType, String>> = [:]

		var currentFileResult: DictionaryClass<OutputType, String> = [:]
		var currentFilePath: String?
		let lines = contents.split(separator: "\n")

		for index in lines.indices {
			let line = lines[index]

			let lineNumber = index + 1
			let lineComponents = line.split(separator: "\"")

			// If there are no strings in this line
			if lineComponents.count == 1 {
				continue
			}

			// If there's one string in this line, it's a file path
			if lineComponents.count < 4 {
				// Save the results for the current file and start building new results for the new
				// file
				if let currentFilePath = currentFilePath {
					result[currentFilePath] = currentFileResult
				}

				currentFileResult = [:]
				currentFilePath = Utilities.getAbsoultePath(forFile: String(lineComponents[1]))
				continue
			}

			// If there are at least two strings in this line, it's an output type and an output
			// file path
			if let outputType = OutputType(rawValue: String(lineComponents[1])) {
				let outputFilePath = String(lineComponents[3])
				currentFileResult[outputType] = outputFilePath
				continue
			}

			// If we got here, we can't interpret this file correctly.
			let sourceFile = SourceFile(path: file, contents: contents)
			let sourceFileRange = SourceFileRange(
				lineStart: lineNumber,
				lineEnd: lineNumber,
				columnStart: 1,
				columnEnd: line.count)
			Compiler.handleWarning(
				message: "Unable to interpret line in output file map.",
				sourceFile: sourceFile,
				sourceFileRange: sourceFileRange)
		}

		// Save the last file result that was being built
		if let currentFilePath = currentFilePath {
			result[currentFilePath] = currentFileResult
		}

		self.buffer = result
	}
}
