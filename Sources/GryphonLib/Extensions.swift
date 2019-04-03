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
		guard self.contains(where: { $0.isLowercase }) else {
			return self
		}

		var newString: String = ""

		let upperCase = CharacterSet.uppercaseLetters
		var range = self.startIndex..<self.endIndex
		while let foundRange = self.rangeOfCharacter(from: upperCase, range: range) {
			newString += self[range.lowerBound..<foundRange.lowerBound].uppercased()
			newString += "_"
			newString += self[foundRange]

			range = foundRange.upperBound..<self.endIndex
		}
		newString += self[range].uppercased()

		return newString
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
}

//
extension Array {
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

extension ArrayReference {
	/// Returns nil if index is out of bounds.
	subscript (safe index: Int) -> Element? {
		return array[safe: index]
	}

	var secondToLast: Element? {
		return self.array.secondToLast
	}

	/// Returns the same array, but with the first element moved to the end.
	func rotated() -> ArrayReference<Element> {
		return ArrayReference(array: self.array.rotated())
	}

	/// Moves the first element of the array to the end.
	func rotate() {
		self.array.rotate()
	}

	/// Groups the array's elements into a dictionary according to the keys provided by the given
	/// closure, forming a sort of histogram.
	func group<Key>(by getKey: (Element) -> Key) -> [Key: [Element]] {
		return self.array.group(by: getKey)
	}
}

// MARK: Common types conforming to PrintableAsTree
extension Dictionary: PrintableAsTree where Value: PrintableAsTree, Key == String {
	public var treeDescription: String { return "Dictionary" }
	public var printableSubtrees: ArrayReference<PrintableAsTree?> {
		let result: ArrayReference<PrintableAsTree?> = []
		for (key, value) in self {
			result.append(PrintableTree(key, [value]))
		}
		return result
	}
}

// MARK: PrintableTree compatibility with Array
// Only needed temporarily, while the conversion of the codebase (from using Array to using
// ArrayReference) isn't done.
extension PrintableTree {
	convenience init(_ description: String, _ subtrees: [PrintableAsTree?]) {
		self.init(description, ArrayReference<PrintableAsTree?>(array: subtrees))
	}

	convenience init(_ subtrees: [PrintableAsTree?]) {
		self.init("Array", ArrayReference<PrintableAsTree?>(array: subtrees))
	}

	static func initOrNil(_ description: String, _ subtreesOrNil: [PrintableAsTree?])
		-> PrintableTree?
	{
		let arrayReference = ArrayReference<PrintableAsTree?>(array: subtreesOrNil)
		return PrintableTree.initOrNil(description, arrayReference)
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
