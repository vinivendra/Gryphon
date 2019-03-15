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

public struct GRYFile {
	private var lines: [Substring]

	public init(contents: String) {
		self.lines = contents.split(separator: "\n", omittingEmptySubsequences: false)
	}

	public func getLine(_ lineNumber: Int) -> String? {
		if let line = lines[safe: lineNumber - 1] {
			return String(line)
		}
		else {
			return nil
		}
	}

	public func getCommentsFromLine(_ lineNumber: Int) -> [String: String]? {
		guard let line = getLine(lineNumber) else {
			return nil
		}

		let commentComponents = line.split(withStringSeparator: "// ").dropFirst()
		var result = [String: String]()
		for component in commentComponents {
			let keyAndValue = component.split(withStringSeparator: ": ")
			if let key = keyAndValue.first {
				let value = keyAndValue.dropFirst().joined()
					.trimmingCharacters(in: CharacterSet.whitespaces)
				result[key] = value
			}
		}

		if result.isEmpty {
			return nil
		}
		else {
			return result
		}
	}
}
