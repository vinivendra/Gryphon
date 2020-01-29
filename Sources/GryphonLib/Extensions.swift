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

// gryphon output: Sources/GryphonLib/Extensions.swiftAST
// gryphon output: Sources/GryphonLib/Extensions.gryphonASTRaw
// gryphon output: Sources/GryphonLib/Extensions.gryphonAST
// gryphon output: Bootstrap/Extensions.kt

import Foundation

private func gryphonTemplates() {
	let _array: MutableList<Any> = []
	let _index = 0
	let _string1 = ""
	let _character: Character = " "
	let _bool = true

	_ = _array[safe: _index]
	_ = "_array.getSafe(_index)"

	_ = _string1.split(separator: _character)
	_ = "_string1.split(separator = _character)"

	_ = _string1.split(separator: _character, omittingEmptySubsequences: _bool)
	_ = "_string1.split(separator = _character, omittingEmptySubsequences = _bool)"
}

// declaration: internal fun String.split(
// declaration:     separator: Char,
// declaration:     maxSplits: Int = Int.MAX_VALUE,
// declaration:     omittingEmptySubsequences: Boolean = true)
// declaration:     : MutableList<String>
// declaration: {
// declaration:     return this.split(separator = separator.toString(),
// declaration:         maxSplits = maxSplits,
// declaration:         omittingEmptySubsequences = omittingEmptySubsequences)
// declaration: }

internal extension String {
	// Result should have at most maxSplits + 1 elements.
	func split(
		withStringSeparator separator: String,
		maxSplits: Int = Int.max,
		omittingEmptySubsequences: Bool = true) -> MutableList<String>
	{
		let result: MutableList<String> = []

		var splits = 0
		var previousIndex = startIndex
		let separators = self.occurrences(of: separator)

		// Add all substrings immediately before each separator
		for separator in separators {
			if splits >= maxSplits {
				splits += 1
				break
			}

			let substring = self[previousIndex..<separator.lowerBound]

			if omittingEmptySubsequences {
				guard !substring.isEmpty else {
					splits += 1
					previousIndex = separator.upperBound
					continue
				}
			}

			result.append(String(substring))

			splits += 1
			previousIndex = separator.upperBound
		}

		// Add the last substring (which the loop above ignores)
		let substring = self[previousIndex..<endIndex]
		if !(substring.isEmpty && omittingEmptySubsequences) {
			result.append(String(substring))
		}

		return result
	}

	/// Non-overlapping
	func occurrences(of searchedSubstring: String) -> MutableList<Range<String.Index>> {
		let result: MutableList<Range<String.Index>> = []

		var currentSubstring = Substring(self)
		var substringOffset = self.startIndex

		while substringOffset < self.endIndex {
			let maybeIndex = // kotlin: ignore
				currentSubstring.range(of: searchedSubstring)?.lowerBound
			// insert: var maybeIndex: Int? = currentSubstring.indexOf(searchedSubstring)
			// insert: maybeIndex = if (maybeIndex == -1) { null } else { maybeIndex }

			guard let foundIndex = maybeIndex else {
				break
			}

			// In Kotlin the foundIndex is counted from the substring's start, but in Swift it's
			// from the string's start. This compensates for that difference.
			let occurenceStartIndex = foundIndex // value: foundIndex + substringOffset

			let occurenceEndIndex =
				currentSubstring.index(occurenceStartIndex, offsetBy: searchedSubstring.count)
			result.append(Range<String.Index>(uncheckedBounds:
				(lower: occurenceStartIndex, upper: occurenceEndIndex)))
			substringOffset = occurenceEndIndex
			currentSubstring = self[substringOffset...]
		}
		return result
	}

	/// Returns an array of the string's components separated by spaces. Spaces that have been
	/// escaped ("\ ") are ignored.
	func splitUsingUnescapedSpaces() -> MutableList<String> {
		let result: MutableList<String> = []

		var isEscaping = false
		var index = self.startIndex
		var startIndexOfCurrentComponent = index
		while index != self.endIndex {
			let character = self[index]
			if character == "\\" {
				isEscaping = !isEscaping
			}
			else if character == " ", !isEscaping {
				result.append(String(self[startIndexOfCurrentComponent..<index]))
				startIndexOfCurrentComponent = self.index(after: index)
			}

			if character != "\\" {
				isEscaping = false
			}

			index = self.index(after: index)
		}

		if startIndexOfCurrentComponent != index {
			result.append(String(self[startIndexOfCurrentComponent..<index]))
		}

		return result
	}

	func removeTrailingWhitespace() -> String {
		guard !isEmpty else {
			return ""
		}

		var lastValidIndex = index(before: endIndex)
		while lastValidIndex != startIndex {
			let character = self[lastValidIndex]
			if character != " " && character != "\t" {
				break
			}
			self.formIndex(before: &lastValidIndex)
		}
		return String(self[startIndex...lastValidIndex])
	}

	/// "fooBar" becomes "FOO_BAR", "HTTPSBar" becomes "HTTPS_BAR", etc
	func upperSnakeCase() -> String {
		guard !self.isEmpty else {
			return self
		}

		var result: String = ""
		result.append(self[self.startIndex].uppercased())

		let indicesWithoutTheFirstOne = self.indices.dropFirst() // kotlin: ignore
		// insert: val indicesWithoutTheFirstOne = this.indices.drop(1)

		for index in indicesWithoutTheFirstOne {
			let currentCharacter = self[index]
			if currentCharacter.isUppercase {
				let nextIndex = self.index(after: index)
				if nextIndex != endIndex, !self[nextIndex].isUppercase, self[nextIndex] != "_" {
					result.append("_")
				}
				else if index > startIndex {
					let previousIndex = self.index(before: index)
					if !self[previousIndex].isUppercase, self[previousIndex] != "_" {
						result.append("_")
					}
				}
				result.append(currentCharacter)
			}
			else {
				result.append(currentCharacter.uppercased())
			}
		}

		return result
	}

	/// "fooBar" becomes "FooBar"
	func capitalizedAsCamelCase() -> String {
		let firstCharacter = self.first!
		let capitalizedFirstCharacter = String(firstCharacter).uppercased()
		return String(capitalizedFirstCharacter + self.dropFirst())
	}

	/// Turns all "\\n" (backslash + 'n') into "\n" (newline), "\\t" (backslash + 't') into "\t"
	/// (tab), and "\\\\" (backslash + backslash) into "\\" (backslash).
	var removingBackslashEscapes: String {
		var result = ""
		var isEscaping = false

		for character in self {
			if !isEscaping {
				if character == "\\" {
					isEscaping = true
				}
				else {
					result.append(character)
				}
			}
			else {
				switch character {
				case "\\":
					result.append("\\")
				case "n":
					result.append("\n")
				case "t":
					result.append("\t")
				default:
					result.append(character)
					isEscaping = false
				}

				isEscaping = false
			}
		}

		return result
	}
}

//
extension Character {
	var isNumber: Bool {
		return self == "0" ||
			self == "1" ||
			self == "2" ||
			self == "3" ||
			self == "4" ||
			self == "5" ||
			self == "6" ||
			self == "7" ||
			self == "8" ||
			self == "9"
	}

	var isUppercase: Bool {
		return self == "A" ||
			self == "B" ||
			self == "C" ||
			self == "D" ||
			self == "E" ||
			self == "F" ||
			self == "G" ||
			self == "H" ||
			self == "I" ||
			self == "J" ||
			self == "K" ||
			self == "L" ||
			self == "M" ||
			self == "N" ||
			self == "O" ||
			self == "P" ||
			self == "Q" ||
			self == "R" ||
			self == "S" ||
			self == "T" ||
			self == "U" ||
			self == "V" ||
			self == "W" ||
			self == "X" ||
			self == "Y" ||
			self == "Z"
	}
}

//
extension List {
	/// Returns nil if index is out of bounds.
	subscript (safe index: Int) -> Element? { // kotlin: ignore
		return getSafe(index)
	}

	/// Returns nil if index is out of bounds.
	func getSafe(_ index: Int) -> Element? {
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

	/// Returns the same array, but with the first element moved to the end.
	func rotated() -> List<Element> {
		guard let first = self.first else {
			return self
		}

		var newArray: MutableList<Element> = []
		newArray.reserveCapacity(self.count) // kotlin: ignore
		newArray.append(contentsOf: self.dropFirst())
		newArray.append(first)

		return newArray
	}

	/// Groups the array's elements into a dictionary according to the keys provided by the given
	/// closure, forming a sort of histogram.
	func group<Key>(by getKey: (Element) -> Key)
		-> MutableMap<Key, MutableList<Element>>
	{
		let result: MutableMap<Key, MutableList<Element>> = [:]
		for element in self {
			let key = getKey(element)
			let array = result[key] ?? []
			array.append(element)
			result[key] = array
		}
		return result
	}
}

extension List where Element: Equatable {
	/// Removes duplicated items from the array, keeping the first unique items. Returns a copy of
	/// the array with only unique items in it. O(n^2).
	func removingDuplicates() -> MutableList<Element> {
		let result: MutableList<Element> = []

		for i in self.indices {
			let consideredDeclaration = self[i]

			var hasDuplicate = false

			var j = i - 1
			while j >= 0 {
				let possibleDuplicate = self[j]

				if possibleDuplicate == consideredDeclaration {
					hasDuplicate = true
					break
				}

				j -= 1
			}

			if !hasDuplicate {
				result.append(consideredDeclaration)
			}
		}

		return result
	}
}

//
extension PrintableTree {
	static func ofStrings(_ description: String, _ subtrees: List<String>)
		-> PrintableAsTree?
	{
		let newSubtrees = subtrees.map { string -> PrintableAsTree? in PrintableTree(string) }
		return PrintableTree.initOrNil(description, newSubtrees)
	}
}
