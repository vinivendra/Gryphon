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

// gryphon output: Sources/GryphonLib/SourceFile.swiftAST
// gryphon output: Sources/GryphonLib/SourceFile.gryphonASTRaw
// gryphon output: Sources/GryphonLib/SourceFile.gryphonAST
// gryphon output: Bootstrap/SourceFile.kt

import Foundation

public class SourceFile {
	public var path: String
	public let contents: String
	public let lines: List<Substring>

	public init(path: String, contents: String) {
		self.path = path
		self.contents = contents
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
		case generics
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
	public func getCommentFromLine(_ lineNumber: Int) -> CommonComment? { // gryphon pure
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
				" " // gryphon value: ' '
			&& $0 !=
				"\t" // gryphon value: '\\t'
		}
		guard !commentIsAfterCode else {
			return nil
		}

		// Get the comment's range
		let columnStartIndex = line.occurrences(of: "//").first!.lowerBound
		let columnStartInt = line.distance(from: line.startIndex, to: columnStartIndex)

		let range = SourceFileRange(
			start: SourceFilePosition(
				line: lineNumber,
				column: columnStartInt),
			end: SourceFilePosition(
				line: lineNumber,
				column: line.count))

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

		return SourceFile.getTranslationCommentFromString(comment)
	}

	/// Returns a keyed comment in the given string, or `nil` if the existing comment isn't keyed).
	/// Expects the string to not include the initial `// `.
	public static func getTranslationCommentFromString(
		_ comment: String)
		-> SourceFile.TranslationComment?
	{
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

/// Lines and columns are counted from `1` (i.e. the first line in a file is line number `1` and the
/// first character in that line is the character in column number `1`). Newlines show up at the end
/// of each line (e.g. a newline dividing line `1` from line `2` is at
/// `SourceFilePosition(line: 1, column: line1.count)`.
public struct SourceFilePosition: Hashable, CustomStringConvertible, Comparable, Equatable {
	let line: Int
	let column: Int

	public var description: String {
		return "\(line):\(column)"
	}

	public static let beginningOfFile = SourceFilePosition(line: 1, column: 1)

	public static func < (lhs: SourceFilePosition, rhs: SourceFilePosition) -> Bool {
		if lhs.line < rhs.line {
			return true
		}
		else if lhs.line == rhs.line {
			return lhs.column < rhs.column
		}
		else {
			return false
		}
	}
}

/// Both start and end positions are inlusive in the range (i.e. `[start, end]`)
public struct SourceFileRange: Equatable, Hashable, CustomStringConvertible {
	let start: SourceFilePosition
	let end: SourceFilePosition

	// TODO: Remove this later
	var lineStart: Int {
		get {
			return start.line
		}
	}
	var lineEnd: Int {
		get {
			return end.line
		}
	}
	var columnStart: Int {
		get {
			return start.column
		}
	}
	var columnEnd: Int {
		get {
			return end.column
		}
	}

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
		return "\(start) - \(end)"
	}

	public static func getRange(
		withStartOffset startOffset: Int,
		withEndOffset endOffset: Int,
		inFile sourceFile: SourceFile)
		-> SourceFileRange
	{
		return SourceFilePositionMap.getRange(
			withStartOffset: startOffset,
			withEndOffset: endOffset,
			inFile: sourceFile)
	}

	init(
		start: SourceFilePosition,
		end: SourceFilePosition)
	{
		self.start = start
		self.end = end
	}

	// TODO: Remove this later
	init(
		lineStart: Int,
		lineEnd: Int,
		columnStart: Int,
		columnEnd: Int)
	{
		self.start = SourceFilePosition(line: lineStart, column: columnStart)
		self.end = SourceFilePosition(line: lineEnd, column: columnEnd)
	}
}

/// SwiftSyntax reports ranges as utf8 offsets from the start, but source files ranges are stored as
/// line + column combos. The mapping from offsets to lines is done by storing the offset of the
/// first character in each line (e.g. the first character in line `1` has offset `0`, the one in
/// line `2` may have offset `10`, the one in line `3` may have offest `15`, etc.).
private struct SourceFilePositionMap { // gryphon ignore
	/// Cache that uses the paths of source files as indices and returns the offset-line map for
	/// that file, if any.
	private static let mapsCache: Atomic<MutableMap<String, SourceFilePositionMap>> = Atomic([:])

	/// Contains the offsets corresponding to the start of each line. The element at `0` is the
	/// offset of the first character of line `1`, etc.
	private let map: List<Int>

	init(sourceFile: SourceFile) {
		let result: MutableList<Int> = [0]
		var accumulatedOffset = 0

		for line in sourceFile.lines {
			accumulatedOffset += line.utf8.count + 1 // Add the newline character
			result.append(accumulatedOffset)
		}

		self.map = result
	}

	static func getRange(
		withStartOffset startOffset: Int,
		withEndOffset endOffset: Int,
		inFile sourceFile: SourceFile)
		-> SourceFileRange
	{
		return mapsCache.mutateAtomically { mapsCache in
			if let cachedMap = mapsCache[sourceFile.path] {
				let startPosition = cachedMap.getPosition(ofOffset: startOffset)
				let endPosition = cachedMap.getPosition(ofOffset: endOffset)
				return SourceFileRange(start: startPosition, end: endPosition)
			}
			else {
				let newMap = SourceFilePositionMap(sourceFile: sourceFile)
				mapsCache[sourceFile.path] = newMap
				let startPosition = newMap.getPosition(ofOffset: startOffset)
				let endPosition = newMap.getPosition(ofOffset: endOffset)
				return SourceFileRange(start: startPosition, end: endPosition)
			}
		}
	}

	/// Get the number of the line that contains the character represented by this offset, and the
	/// column of the character in that line. Lines and columns for `SourceFilePosition`s begin
	/// counting at `1`, and newlines are counted as being part of the preceding line.
	private func getPosition(ofOffset offset: Int) -> SourceFilePosition {
		guard offset != 0 else {
			return SourceFilePosition.beginningOfFile
		}

		var lineNumber = 1
		while lineNumber < map.count {
			let nextOffset = map[lineNumber]
			if nextOffset > offset {
				let currentLineOffset = map[lineNumber - 1]

				// lineNumber will have passed the line (+1) but it'll also be a 0-based index (-1)
				let line = lineNumber
				// currentLineOffset is the index of the first character, which also has to be
				// counted (+1)
				let column = offset - currentLineOffset + 1
				return SourceFilePosition(line: line, column: column)
			}
			lineNumber += 1
		}

		// If it's in the last line
		let previousLineOffset = map.last!
		let line = map.count
		let column = offset - previousLineOffset
		return SourceFilePosition(line: line, column: column)
	}
}
