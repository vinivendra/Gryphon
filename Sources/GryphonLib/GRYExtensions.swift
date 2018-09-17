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

internal extension String {
	/// Ignores empty substrings
	func split(withStringSeparator separator: String) -> [String] {
		var result = [String]()

		var previousIndex = startIndex
		let separators = self.occurrences(of: separator)

		// Add all substrings immediately before each separator
		for separator in separators {
			defer { previousIndex = separator.upperBound }

			let substring = self[previousIndex..<separator.lowerBound]
			guard !substring.isEmpty else { continue }

			result.append(String(substring))
		}

		// Add the last substring (which the loop above ignores)
		let substring = self[previousIndex..<endIndex]
		if !substring.isEmpty {
			result.append(String(substring))
		}

		return result
	}

	/// Non-overlapping
	func occurrences(of substring: String) -> [Range<String.Index>] {
		var result = [Range<String.Index>]()

		var currentRange = Range<String.Index>(uncheckedBounds:
			(lower: startIndex, upper: endIndex))

		while let foundRange = self.range(of: substring, range: currentRange) {
			result.append(foundRange)
			currentRange = Range<String.Index>(uncheckedBounds:
				(lower: foundRange.upperBound, upper: endIndex))
		}
		return result
	}
}

extension Array {
	// TODO: Test this.
	subscript (safe index: Int) -> Element? {
		if index >= 0 && index < count {
			return self[index]
		}
		else {
			return nil
		}
	}

	var secondToLast: Element? {
		return self.dropLast().last
	}

	// TODO: Test this.
	/// Returns the same array, but with the first element moved to the end.
	func rotated() -> Array<Element> {
		guard let first = first else {
			return self
		}

		var newArray: Array<Element> = Array<Element>()
		newArray.reserveCapacity(self.count)
		newArray.append(contentsOf: self.dropFirst())
		newArray.append(first)

		return newArray
	}

	/// Moves the first element of the array to the end.
	mutating func rotate() {
		self = self.rotated()
	}
}
