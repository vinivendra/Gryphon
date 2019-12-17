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

// gryphon output: Sources/GryphonLib/SourceFile.swiftAST
// gryphon output: Sources/GryphonLib/SourceFile.gryphonASTRaw
// gryphon output: Sources/GryphonLib/SourceFile.gryphonAST
// gryphon output: Bootstrap/SourceFile.kt

import Foundation

public class SourceFile {
	public var path: String
	private let lines: MutableList<Substring>

	public init(path: String, contents: String) {
		self.path = path

		self.lines = MutableList<Substring>(
			contents.split(separator: "\n", omittingEmptySubsequences: false))
	}

	public var numberOfLines: Int {
		return lines.count
	}

	/// Get a line from the source file (indices starting in 1). Returns `nil` if the line number is
	/// larger than the file's size or less than zero.
	public func getLine(_ lineNumber: Int) -> String? {
		if let line = lines[safe: lineNumber - 1] {
			return String(line)
		}
		else {
			return nil
		}
	}

	public enum CommentKey: String {
		case declaration
		case insert
		case kotlin
		case value
		case inspect
		case gryphon
		case annotation
		case gryphonOutput = "gryphon output"
	}

	public struct KeyedComment {
		let key: CommentKey
		let value: String
	}

	public struct CommonComment {
		let contents: String
		let range: SourceFileRange
	}
}

extension SourceFile {
	/// Returns any comment in the given line, or `nil` if there isn't one. Line indices start at 1.
	public func getCommentFromLine(_ lineNumber: Int) -> CommonComment? { // gryphon: pure
		guard let line = getLine(lineNumber) else {
			return nil
		}

		let lineComponents = line
			.split(withStringSeparator: "//", maxSplits: 1, omittingEmptySubsequences: false)

		// If there's no comment
		guard lineComponents.count == 2 else {
			return nil
		}

		// If the comment comes after some code (not yet supported)
		let commentIsAfterCode = lineComponents[0].contains {
			$0 !=
				" " // value: ' '
			&& $0 !=
				"\t" // value: '\\t'
		}
		guard !commentIsAfterCode else {
			return nil
		}

		// Get the comment's range
		let columnStartIndex = line.occurrences(of: "//").first!.lowerBound
		let columnStartInt = columnStartIndex.utf16Offset(in: line) // value: columnStartIndex

		let range = SourceFileRange(
			lineStart: lineNumber,
			lineEnd: lineNumber,
			columnStart: columnStartInt,
			columnEnd: line.count)

		return SourceFile.CommonComment(contents: lineComponents[1], range: range)
	}

	/// Returns a keyed comment in the given line, or `nil` if there isn't one (or if the existing
	/// comment isn't keyed).
	public func getKeyedCommentFromLine(_ lineNumber: Int) -> SourceFile.KeyedComment? {
		guard let line = getLine(lineNumber) else {
			return nil
		}

		let lineComponents = line
			.split(withStringSeparator: "// ", maxSplits: 1, omittingEmptySubsequences: false)
		guard lineComponents.count == 2 else {
			return nil
		}

		let comment = lineComponents[1]
		let commentComponents =
			comment.split(withStringSeparator: ": ", maxSplits: 1, omittingEmptySubsequences: false)
		guard commentComponents.count == 2 else {
			// Allow the insertion of newlines even if the IDE trims the trailing spaces
			if let key = commentComponents.first, key == "declaration:" || key == "insert:" {
				let cleanKey = String(key.dropLast())
				let commentKey = SourceFile.CommentKey(rawValue: cleanKey)!
				return SourceFile.KeyedComment(key: commentKey, value: "")
			}

			return nil
		}

		let key = commentComponents[0]
		let value = commentComponents[1]

		// If it's a valid comment key
		if let commentKey = SourceFile.CommentKey(rawValue: key) {
			return SourceFile.KeyedComment(key: commentKey, value: value)
		}
		else {
			return nil
		}
	}
}

public struct SourceFileRange: Equatable, Hashable {
	let lineStart: Int
	let lineEnd: Int
	let columnStart: Int
	let columnEnd: Int

	/// This is technically incorrect but allows AST nodes with ranges to get an automatic Equatable
	/// conformance that ignores ranges, which is useful since we're frequently comparing nodes
	/// with the same practical meaning but different source file ranges.
	public static func == (lhs: SourceFileRange, rhs: SourceFileRange) -> Bool {
		return true
	}
}
