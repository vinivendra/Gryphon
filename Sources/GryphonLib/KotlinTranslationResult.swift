//
// Copyright 2018 Vinicius Jorge Vendramini
//
// Licensed under the Hippocratic License, Version 2.1;
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://firstdonoharm.dev/version/2/1/license.md
//
// To the full extent allowed by law, this software comes "AS IS,"
// WITHOUT ANY WARRANTY, EXPRESS OR IMPLIED, and licensor and any other
// contributor shall not be liable to anyone for any damages or other
// liability arising from, out of, or in connection with the sotfware
// or this license, under any kind of legal claim.
// See the License for the specific language governing permissions and
// limitations under the License.
//

// gryphon output: Sources/GryphonLib/KotlinTranslationResult.swiftAST
// gryphon output: Sources/GryphonLib/KotlinTranslationResult.gryphonASTRaw
// gryphon output: Sources/GryphonLib/KotlinTranslationResult.gryphonAST
// gryphon output: Bootstrap/KotlinTranslationResult.kt

public struct KotlinTranslationResult {
	let translation: String
	let errorMap: String
}

public class KotlinTranslation: PrintableAsTree, CustomStringConvertible {
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

	func append(_ map: KotlinTranslation) {
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

	public func resolveTranslation() -> KotlinTranslationResult {
		let translationResult: MutableList<String> = []
		let errorMap: MutableList<String> = []
		resolveTranslationInto(translationResult: translationResult, errorMap: errorMap)
		return KotlinTranslationResult(
			translation: translationResult.joined(),
			errorMap: errorMap.joined(separator: "\n"))
	}

	/// Processes the current translation result and adds the information into the given arrays.
	/// Returns the position at the end of the current translation result.
	private func resolveTranslationInto(
		translationResult: MutableList<String>,
		errorMap: MutableList<String>,
		startPosition: SourceFilePosition = SourceFilePosition.beginningOfFile)
		-> SourceFilePosition
	{
		var currentEndPosition = startPosition

		for child in children {
			if let string = child.stringLiteral {
				currentEndPosition = currentEndPosition.updated(withString: string)
				translationResult.append(string)
			}
			else {
				let node = child.node!
				currentEndPosition = node.resolveTranslationInto(
					translationResult: translationResult,
					errorMap: errorMap,
					startPosition: currentEndPosition)
			}
		}

		if let swiftRange = swiftRange {
			let newEntry = "\(startPosition.line):\(startPosition.column):" +
				"\(currentEndPosition.line):\(currentEndPosition.column):" +
				"\(swiftRange.lineStart):\(swiftRange.columnStart):" +
				"\(swiftRange.lineEnd):\(swiftRange.columnEnd)"
			let lastEntry = errorMap.last
			if lastEntry == nil || lastEntry! != newEntry {
				errorMap.append(newEntry)
			}
		}

		return currentEndPosition
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
	let node: KotlinTranslation?

	// Only these two initializers exist, therefore exactly one of the properties will always be
	// non-nil
	init(_ stringLiteral: String) { // gryphon ignore
		self.stringLiteral = stringLiteral
		self.node = nil
	}

	init(_ node: KotlinTranslation) { // gryphon ignore
		self.stringLiteral = nil
		self.node = node
	}

	// gryphon insert: constructor(stringLiteral: String): this(stringLiteral, null) { }
	// gryphon insert: constructor(node: KotlinTranslation): this(null, node) { }

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

extension SourceFilePosition {
	// Note: ensuring new lines only happen at the end of strings (i.e. all strings already come
	// separated by new lines) could make this more performant.
	/// Move this position forward to the end of the given string, updating the line and column
	/// numbers accordingly.
	func updated(withString string: String) -> SourceFilePosition {
		let newLines = string.occurrences(of: "\n").count
		if newLines > 0 {
			let newLine = self.line + newLines
			let lastLineContents = string.split(
				withStringSeparator: "\n",
				omittingEmptySubsequences: false).last!
			let newColumn = lastLineContents.count + 1
			return SourceFilePosition(line: newLine, column: newColumn)
		}
		else {
			let newColumn = self.column + string.count
			return SourceFilePosition(line: self.line, column: newColumn)
		}
	}
}

extension KotlinTranslation {
	func appendTranslations(
		_ translations: List<KotlinTranslation>,
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
