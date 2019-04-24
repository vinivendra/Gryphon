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

private func gryphonTemplates() {
	let _array: ArrayClass<Any> = []
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
// declaration: 	separator: Char,
// declaration: 	maxSplits: Int = Int.MAX_VALUE,
// declaration: 	omittingEmptySubsequences: Boolean = true)
// declaration: 	: MutableList<String>
// declaration: {
// declaration: 	return this.split(separator = separator.toString(),
// declaration: 		maxSplits = maxSplits,
// declaration: 		omittingEmptySubsequences = omittingEmptySubsequences)
// declaration: }

internal extension String {
	// Result should have at most maxSplits + 1 elements.
	func split(
		withStringSeparator separator: String,
		maxSplits: Int = Int.max,
		omittingEmptySubsequences: Bool = true) -> [String]
	{
		var result: [String] = []

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
	func occurrences(of searchedSubstring: String) -> [Range<String.Index>] {
		var result: [Range<String.Index>] = []

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

	// TODO: test
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

	func capitalizedAsCamelCase() -> String {
		let firstCharacter = self.first!
		let capitalizedFirstCharacter = String(firstCharacter).uppercased()
		return String(capitalizedFirstCharacter + self.dropFirst())
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
extension Array { // kotlin: ignore
	/// Returns nil if index is out of bounds.
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

	/// Returns the same array, but with the first element moved to the end.
	func rotated() -> [Element] {
		guard let first = first else {
			return self
		}

		var newArray: [Element] = [Element]()
		newArray.reserveCapacity(self.count)
		newArray.append(contentsOf: self.dropFirst())
		newArray.append(first)

		return newArray
	}

	/// Moves the first element of the array to the end.
	mutating func rotate() {
		self = self.rotated()
	}

	/// Groups the array's elements into a dictionary according to the keys provided by the given
	/// closure, forming a sort of histogram.
	func group<Key>(by getKey: (Element) -> Key) -> [Key: [Element]] {
		var result = [Key: [Element]]()
		for element in self {
			let key = getKey(element)
			var array = result[key] ?? []
			array.append(element)
			result[key] = array
		}
		return result
	}
}

extension ArrayClass {
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
	func rotated() -> ArrayClass<Element> {
		guard let first = self.first else {
			return self
		}

		var newArray: ArrayClass<Element> = []
		newArray.reserveCapacity(self.count) // kotlin: ignore
		newArray.append(contentsOf: self.dropFirst())
		newArray.append(first)

		return newArray
	}

	/// Groups the array's elements into a dictionary according to the keys provided by the given
	/// closure, forming a sort of histogram.
	func group<Key>(by getKey: (Element) -> Key)
		-> DictionaryClass<Key, ArrayClass<Element>>
	{
		let result: DictionaryClass<Key, ArrayClass<Element>> = [:]
		for element in self {
			let key = getKey(element)
			let array = result[key] ?? []
			array.append(element)
			result[key] = array
		}
		return result
	}
}

// MARK: - Common types conforming to PrintableAsTree
extension Dictionary: // kotlin: ignore
	PrintableAsTree where Value: PrintableAsTree, Key == String
{
	public var treeDescription: String { return "Dictionary" }
	public var printableSubtrees: ArrayClass<PrintableAsTree?> {
		let result: ArrayClass<PrintableAsTree?> = []
		for (key, value) in self {
			result.append(PrintableTree(key, [value]))
		}
		return result
	}
}

// MARK: - PrintableTree compatibility with Array
// Only needed temporarily, while the conversion of the codebase (from using Array to using
// ArrayClass) isn't done.
extension PrintableTree { // kotlin: ignore
	convenience init(_ description: String, _ subtrees: [PrintableAsTree?]) {
		self.init(description, ArrayClass(subtrees))
	}

	convenience init(_ subtrees: [PrintableAsTree?]) {
		self.init("Array", ArrayClass(subtrees))
	}

	static func initOrNil(_ description: String, _ subtreesOrNil: [PrintableAsTree?])
		-> PrintableTree?
	{
		let arrayClass = ArrayClass(subtreesOrNil)
		return PrintableTree.initOrNil(description, arrayClass)
	}

	convenience init(_ description: String, _ subtrees: [String?]) {
		let convertedSubtrees = subtrees.map { (string: String?) -> PrintableAsTree? in
			if let string = string {
				return PrintableTree(string)
			}
			else {
				return nil
			}
		}
		self.init(description, convertedSubtrees)
	}
}
