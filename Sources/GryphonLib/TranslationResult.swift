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

// gryphon output: Sources/GryphonLib/TranslationResult.swiftAST
// gryphon output: Sources/GryphonLib/TranslationResult.gryphonASTRaw
// gryphon output: Sources/GryphonLib/TranslationResult.gryphonAST
// gryphon output: Bootstrap/TranslationResult.kt

public struct TranslationResult {
	let translation: String
	let errorMap: String
}

public class Translation: PrintableAsTree, CustomStringConvertible {
	let swiftRange: SourceFileRange?
	let children: MutableList<TranslationUnit> = []

	init(range: SourceFileRange?) {
		self.swiftRange = range
	}

	init(range: SourceFileRange?, string: String) {
		self.swiftRange = range
		self.append(string)
	}

	//
	public var description: String {
		return prettyDescription()
	}

	public var treeDescription: String { // gryphon annotation: override
		return "Translation"
	}

	public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		return children.forceCast(to: List<PrintableAsTree?>.self)
	}

	//
	func append(_ string: String) {
		children.append(TranslationUnit(string))
	}

	func append(_ map: Translation) {
		children.append(TranslationUnit(map))
	}

	var isEmpty: Bool {
		if children.isEmpty {
			return true
		}

		for child in children {
			if let string = child.stringLiteral {
				if string != "" {
					return false
				}
			}
			else {
				if !(child.node!.isEmpty) {
					return false
				}
			}
		}

		return true
	}

	public func resolveTranslation() -> TranslationResult {
		let translationResult: MutableList<String> = []
		let errorMap: MutableList<String> = []
		resolveTranslationInto(translationResult: translationResult, errorMap: errorMap)
		return TranslationResult(
			translation: translationResult.joined(),
			errorMap: errorMap.joined(separator: "\n"))
	}

	private func resolveTranslationInto(
		translationResult: MutableList<String>,
		errorMap: MutableList<String>,
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
			let newEntry = "\(startingPosition.lineNumber):\(startingPosition.columnNumber):" +
				"\(endPosition.lineNumber):\(endPosition.columnNumber):" +
				"\(swiftRange.lineStart):\(swiftRange.columnStart):" +
				"\(swiftRange.lineEnd):\(swiftRange.columnEnd)"
			let lastEntry = errorMap.last
			if lastEntry == nil || lastEntry! != newEntry {
				errorMap.append(newEntry)
			}
		}
	}

	/// Goes through the translation subtree looking for the given suffix. If it is found, it is
	/// dropped from the tree (in-place). Otherwise, nothing happens.
	/// Does not match the suffix if it is separated between more than one translation unit.
	public func dropLast(_ string: String) {
		if let lastUnit = children.last {
			if let stringLiteral = lastUnit.stringLiteral {
				if stringLiteral.hasSuffix(string) {
					let newUnit =
						TranslationUnit(String(stringLiteral.dropLast(string.count)))
					children[children.count - 1] = newUnit
				}
			}
			else {
				lastUnit.node!.dropLast(string)
			}
		}
	}
}

struct TranslationUnit: PrintableAsTree, CustomStringConvertible {
	let stringLiteral: String?
	let node: Translation?

	// Only these two initializers exist, therefore exactly one of the properties will always be
	// non-nil
	init(_ stringLiteral: String) { // gryphon ignore
		self.stringLiteral = stringLiteral
		self.node = nil
	}

	init(_ node: Translation) { // gryphon ignore
		self.stringLiteral = nil
		self.node = node
	}

	// gryphon insert: constructor(stringLiteral: String): this(stringLiteral, null) { }
	// gryphon insert: constructor(node: Translation): this(null, node) { }

	//
	var description: String {
		return prettyDescription()
	}

	var treeDescription: String { // gryphon annotation: override
		if let stringLiteral = self.stringLiteral {
			let escapedString = stringLiteral
				.replacingOccurrences(of: "\n", with: "\\n")
				.replacingOccurrences(of: "\t", with: "\\t")
			return "\"\(escapedString)\""
		}
		else {
			let node = self.node!
			if let range = node.swiftRange {
				return range.description
			}
			else {
				return ""
			}
		}
	}

	var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		if let node = self.node {
			return node.children.forceCast(to: List<PrintableAsTree?>.self)
		}
		else {
			return []
		}
	}
}

internal class SourceFilePosition {
	var lineNumber: Int
	var columnNumber: Int

	public init() {
		self.lineNumber = 1
		self.columnNumber = 1
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
			let lastLineContents = string.split(
				withStringSeparator: "\n",
				omittingEmptySubsequences: false).last!
			self.columnNumber = lastLineContents.count + 1
		}
		else {
			self.columnNumber += string.count
		}
	}

	func copy() -> SourceFilePosition {
		return SourceFilePosition(lineNumber: self.lineNumber, columnNumber: self.columnNumber)
	}
}

extension Translation {
	func appendTranslations(
		_ translations: List<Translation>,
		withSeparator separator: String)
	{
		for translation in translations.dropLast() {
			self.append(translation)
			self.append(separator)
		}
		if let lastTranslation = translations.last {
			self.append(lastTranslation)
		}
	}
}
