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

public struct GRYFile {
	private var lines: [Substring]

	public init(contents: String) {
		self.lines = contents.split(separator: "\n", omittingEmptySubsequences: false)
	}

	public func getLine(_ lineNumber: Int) -> Substring? {
		return lines[safe: lineNumber - 1]
	}

	public func getCommentFromLine(_ lineNumber: Int) -> String? {
		guard let line = getLine(lineNumber) else {
			return nil
		}

		let wholeStringRange = Range<String.Index>(uncheckedBounds:
			(lower: line.startIndex, upper: line.endIndex))
		if let commentRange = line.range(of: "// gryphon: ", range: wholeStringRange) {
			let commentSuffix = line[commentRange.upperBound...]
			if !commentSuffix.isEmpty {
				return String(commentSuffix)
			}
		}

		return nil
	}
}
