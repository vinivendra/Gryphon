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

// gryphon output: Sources/GryphonLib/ErrorMapping.swiftAST
// gryphon output: Sources/GryphonLib/ErrorMapping.gryphonASTRaw
// gryphon output: Sources/GryphonLib/ErrorMapping.gryphonAST
// gryphon output: Bootstrap/ErrorMapping.kt

public struct TranslationResult {
	let translation: String
	let errorMap: String
}

public class Translation {
	let swiftRange: SourceFileRange?
	let children: ArrayClass<TranslationUnit> = []

	init(forRange range: SourceFileRange?) {
		self.swiftRange = range
	}

	func append(_ string: String) {
		children.append(TranslationUnit(string))
	}

	func append(_ map: Translation) {
		children.append(TranslationUnit(map))
	}

	public func resolveTranslation() -> TranslationResult {
		let translationResult: ArrayClass<String> = []
		let errorMap: ArrayClass<String> = []
		resolveTranslationInto(translationResult: translationResult, errorMap: errorMap)
		return TranslationResult(
			translation: translationResult.joined(),
			errorMap: errorMap.joined(separator: "\n"))
	}

	private func resolveTranslationInto(
		translationResult: ArrayClass<String>,
		errorMap: ArrayClass<String>,
		currentPosition: SourceFilePosition = SourceFilePosition())
	{
		let startingPosition = currentPosition.copy()

		for child in children {
			if let string = child.stringLiteral {
				currentPosition.updateWithString(string)
				translationResult.append(string)
			}
			else {
				let node = child.node!
				node.resolveTranslationInto(
					translationResult: translationResult,
					errorMap: errorMap,
					currentPosition: currentPosition)
			}
		}

		if let swiftRange = swiftRange {
			let endPosition = currentPosition.copy()
			errorMap.append(
				"\(swiftRange.lineStart):\(swiftRange.columnStart), " +
				"\(swiftRange.lineEnd):\(swiftRange.columnEnd) -> " +
				"\(startingPosition.lineNumber):\(startingPosition.columnNumber), " +
				"\(endPosition.lineNumber):\(startingPosition.columnNumber)")
		}
	}
}

struct TranslationUnit {
	let stringLiteral: String?
	let node: Translation?

	// Only these two initializers exits, therefore exactly one of the properties will always be
	// non-nil
	init(_ stringLiteral: String) {
		self.stringLiteral = stringLiteral
		self.node = nil
	}

	init(_ node: Translation) {
		self.stringLiteral = nil
		self.node = node
	}
}

private class SourceFilePosition {
	var lineNumber: Int = 0
	var columnNumber: Int = 0

	public init() {
		self.lineNumber = 0
		self.columnNumber = 0
	}

	private init(lineNumber: Int, columnNumber: Int) {
		self.lineNumber = lineNumber
		self.columnNumber = columnNumber
	}

	// Note: ensuring new lines only happen at the end of strings (i.e. all strings already come
	// separated by new lines) could make this more performant.
	func updateWithString(_ string: String) {
		let newLines = string.occurrences(of: "\n").count
		if newLines > 0 {
			self.lineNumber += newLines
			self.columnNumber = string.split(withStringSeparator: "\n").last!.count
		}
		else {
			self.columnNumber = string.count
		}
	}

	func copy() -> SourceFilePosition {
		return SourceFilePosition(lineNumber: self.lineNumber, columnNumber: self.columnNumber)
	}
}
