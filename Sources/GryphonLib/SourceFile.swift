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

// gryphon output: Test files/Bootstrap/SourceFile.kt

import Foundation

public class SourceFile {
	public var path: String
	private let lines: List<Substring>

	public init(path: String, contents: String) {
		self.path = path
		self.lines = List<Substring>(
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
		// Comments with values (i.e. `// gryphon insert: <value>`)
		case insert
		case insertInMain
		case value
		case annotation
		case output

		// Comments without values (i.e. `// gryphon ignore`)
		case ignore
		case inspect
		case multiline
		case pure
		case mute
	}

	public struct TranslationComment {
		let key: CommentKey
		let value: String?
	}

	public struct CommonComment {
		let contents: String
		let range: SourceFileRange
	}
}

extension SourceFile {
	/// Returns any comment in the given line, or `nil` if there isn't one. Line indices start at 1.
	// gryphon pure
	public func getCommentFromLine(_ lineNumber: Int) -> SourceFile.CommonComment? {
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
				/* gryphon value: ' ' */ " "
			&& $0 !=
				/* gryphon value: '\\t' */ "\t"
		}
		guard !commentIsAfterCode else {
			return nil
		}

		// Get the comment's range
		let columnStartIndex = line.occurrences(of: "//").first!.lowerBound
		let columnStartInt = /* gryphon value: columnStartIndex */
			columnStartIndex.utf16Offset(in: line)

		let range = SourceFileRange(
			lineStart: lineNumber,
			lineEnd: lineNumber,
			columnStart: columnStartInt,
			columnEnd: line.count)

		return SourceFile.CommonComment(contents: lineComponents[1], range: range)
	}

	/// Returns a keyed comment in the given line, or `nil` if there isn't one (or if the existing
	/// comment isn't keyed).
	public func getTranslationCommentFromLine(_ lineNumber: Int) -> SourceFile.TranslationComment? {
		guard let line = getLine(lineNumber) else {
			return nil
		}

		// Get the comment from the line
		let lineComponents = line
			.split(withStringSeparator: "// ", maxSplits: 1, omittingEmptySubsequences: false)
		guard lineComponents.count == 2 else {
			return nil
		}

		let comment = lineComponents[1]

		// Make sure it's a gryphon comment
		guard comment.hasPrefix("gryphon ") else {
			return nil
		}

		// Separate the comment in a key and an optional value
		let commentComponents = comment.split(
			withStringSeparator: ": ",
			maxSplits: 1,
			omittingEmptySubsequences: false)
		let commentKeyString = String(commentComponents[0].dropFirst("gryphon ".count))

		// If it's a valid key
		if let commentKey = SourceFile.CommentKey(rawValue: commentKeyString) {
			let value = commentComponents[safe: 1]
			return SourceFile.TranslationComment(key: commentKey, value: value)
		}
		else {
			// Special case: if it's an empty insert comment, there's no space after the ":", so the
			// `split(...)` fails above. This means Initializing the key fails, because there's
			// still a ":" in the key string.
			if commentKeyString == "\(SourceFile.CommentKey.insert.rawValue):" ||
				commentKeyString == "\(SourceFile.CommentKey.insertInMain.rawValue):"
			{
				let cleanKey = String(commentKeyString.dropLast())
				let commentKey = SourceFile.CommentKey(rawValue: cleanKey)!
				return SourceFile.TranslationComment(key: commentKey, value: "")
			}
		}

		return nil
	}
}

public struct SourceFileRange: Equatable, Hashable, CustomStringConvertible {
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

	/// Real equatable comparison
	public func isEqual(to other: SourceFileRange) -> Bool {
		return self.lineStart == other.lineStart &&
			self.lineEnd == other.lineEnd &&
			self.columnStart == other.columnStart &&
			self.columnEnd == other.columnEnd
	}

	public var description: String {
		return "\(lineStart):\(columnStart) - \(lineEnd):\(columnEnd)"
	}
}
