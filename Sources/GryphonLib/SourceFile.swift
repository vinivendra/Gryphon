/*
* Copyright 2018 Vinícius Jorge Vendramini
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

import Foundation

public class SourceFile {
	public var path: String
	private let lines: ArrayClass<Substring>

	public init(path: String, contents: String) {
		self.path = path

		self.lines = ArrayClass<Substring>(
			contents.split(separator: "\n", omittingEmptySubsequences: false))
	}

	public var numberOfLines: Int {
		return lines.count
	}

	public func getLine(_ lineNumber: Int) -> String? {
		if let line = lines[safe: lineNumber - 1] {
			return String(line)
		}
		else {
			return nil
		}
	}

	public struct Comment {
		let key: String
		let value: String
	}
}

extension SourceFile {
	public func getCommentFromLine(_ lineNumber: Int) -> SourceFile.Comment? {
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
				return SourceFile.Comment(key: String(key.dropLast()), value: "")
			}

			return nil
		}

		let key = commentComponents[0]
		let value = commentComponents[1]
		return SourceFile.Comment(key: key, value: value)
	}
}

struct SourceFileRange: Equatable {
	let lineStart: Int
	let lineEnd: Int
	let columnStart: Int
	let columnEnd: Int

	/// This is technically incorrect but allows AST nodes with ranges to get an automatic Equatable
	/// conformance that ignores ranges, which is useful since we're frequently comparing nodes
	/// with the same practical meaning but different source file ranges.
	static func == (lhs: SourceFileRange, rhs: SourceFileRange) -> Bool { // kotlin: ignore
		return true
	}
}
