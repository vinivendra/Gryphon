private typealias OutputFileMapBuffer =
	DictionaryReference<String, DictionaryReference<OutputFileMap.OutputType, String>>

public class OutputFileMap {
	public enum OutputType: String {
		case astDump = "ast-dump"
		case swiftAST
		case gryphonASTRaw
		case gryphonAST
		case kotlin
	}

	private var outputFileMap: OutputFileMapBuffer

	private init(outputFileMap: OutputFileMapBuffer) {
		self.outputFileMap = outputFileMap
	}
}

extension OutputFileMap { // kotlin: ignore
	public func getFileMap(forInputFile file: String) -> DictionaryReference<OutputType, String>? {
		return outputFileMap[file]
	}

	public func getOutputFile(forInputFile file: String, outputType: OutputType) -> String? {
		return getFileMap(forInputFile: file)?[outputType]
	}

	public convenience init(_ file: String) {
		let contents = try! Utilities.readFile(file)

		let result: DictionaryReference<String, DictionaryReference<OutputType, String>> = [:]

		var currentFileResult: DictionaryReference<OutputType, String> = [:]
		var currentFilePath: String?
		for (index, line) in contents.split(separator: "\n").enumerated() {
			let lineNumber = index + 1
			let lineComponents = line.split(separator: "\"")

			// If there are no strings in this line
			if lineComponents.count == 1 {
				continue
			}
			// If there's one string in this line, it's a file path
			else if lineComponents.count < 4 {
				// Save the results for the current file and start building new results for the new
				// file
				if let currentFilePath = currentFilePath {
					result[currentFilePath] = currentFileResult
				}

				currentFileResult = [:]
				currentFilePath = String(lineComponents[1])
			}
			// If there are at least two strings in this line, it's an output type and an output
			// file path
			else if let outputType = OutputType(rawValue: String(lineComponents[1])) {
				let outputFilePath = String(lineComponents[3])
				currentFileResult[outputType] = outputFilePath
			}
			else {
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
		}

		// Save the last file result that was being built
		if let currentFilePath = currentFilePath {
			result[currentFilePath] = currentFileResult
		}

		self.init(outputFileMap: result)
	}
}
