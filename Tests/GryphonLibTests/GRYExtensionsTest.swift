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

@testable import GryphonLib
import XCTest

struct TestableRange: Equatable {
	let lowerBound: Int
	let upperBound: Int

	init(_ range: Range<String.Index>) {
		self.lowerBound = range.lowerBound.encodedOffset
		self.upperBound = range.upperBound.encodedOffset
	}

	init(_ lowerBound: Int, _ upperBound: Int) {
		self.lowerBound = lowerBound
		self.upperBound = upperBound
	}
}

class GRYExtensionTest: XCTestCase {
	func testStringSplit() {
		XCTAssertEqual(
			"->".split(withStringSeparator: "->"),
			[])
		XCTAssertEqual(
			"a->b".split(withStringSeparator: "->"),
			["a", "b"])
		XCTAssertEqual(
			"a->b->c".split(withStringSeparator: "->"),
			["a", "b", "c"])
		XCTAssertEqual(
			"->b->c".split(withStringSeparator: "->"),
			["b", "c"])
		XCTAssertEqual(
			"->->c".split(withStringSeparator: "->"),
			["c"])
		XCTAssertEqual(
			"a->b->".split(withStringSeparator: "->"),
			["a", "b"])
		XCTAssertEqual(
			"a->->".split(withStringSeparator: "->"),
			["a"])
		XCTAssertEqual(
			"a->->b".split(withStringSeparator: "->"),
			["a", "b"])
		XCTAssertEqual(
			"abc".split(withStringSeparator: "->"),
			["abc"])
		XCTAssertEqual(
			"->(Int, (String) -> Int) ->-> Int ->"
				.split(withStringSeparator: "->"),
			["(Int, (String) ", " Int) ", " Int "])

		for _ in 0..<1_000 {
			let (string, separator, _, components) =
				Fuzzer.randomTest()
			XCTAssertEqual(string.split(withStringSeparator: separator), components)
		}
	}

	func testOccurrencesOfSubstring() {
		XCTAssertEqual(
			"->".occurrences(of: "->").map(TestableRange.init),
			[TestableRange(0, 2)])
		XCTAssertEqual(
			"a->b".occurrences(of: "->").map(TestableRange.init),
			[TestableRange(1, 3)])
		XCTAssertEqual(
			"a->b->c".occurrences(of: "->").map(TestableRange.init),
			[TestableRange(1, 3), TestableRange(4, 6)])
		XCTAssertEqual(
			"->b->c".occurrences(of: "->").map(TestableRange.init),
			[TestableRange(0, 2), TestableRange(3, 5)])
		XCTAssertEqual(
			"->->c".occurrences(of: "->").map(TestableRange.init),
			[TestableRange(0, 2), TestableRange(2, 4)])
		XCTAssertEqual(
			"a->b->".occurrences(of: "->").map(TestableRange.init),
			[TestableRange(1, 3), TestableRange(4, 6)])
		XCTAssertEqual(
			"a->->".occurrences(of: "->").map(TestableRange.init),
			[TestableRange(1, 3), TestableRange(3, 5)])
		XCTAssertEqual(
			"a->->b".occurrences(of: "->").map(TestableRange.init),
			[TestableRange(1, 3), TestableRange(3, 5)])
		XCTAssertEqual(
			"abc".occurrences(of: "->").map(TestableRange.init),
			[])
		XCTAssertEqual(
			"->(Int, (String) -> Int) ->-> Int ->"
				.occurrences(of: "->").map(TestableRange.init),
			[TestableRange(0, 2),
			 TestableRange(17, 19),
			 TestableRange(25, 27),
			 TestableRange(27, 29),
			 TestableRange(34, 36),
			 ])

		for _ in 0..<1_000 {
			let (string, separator, occurrences, _) =
				Fuzzer.randomTest()
			XCTAssertEqual(string.occurrences(of: separator).map(TestableRange.init), occurrences)
		}
	}

	func testSafeIndex() {
		let array = [1, 2, 3]
		XCTAssert(array[safe: 0] == 1)
		XCTAssert(array[safe: 1] == 2)
		XCTAssert(array[safe: 2] == 3)
		XCTAssert(array[safe: 3] == nil)
		XCTAssert(array[safe: -1] == nil)
	}

	func testRotate() {
		var array = [1, 2, 3]
		var array1 = array.rotated()
		var array2 = array1.rotated()
		let array3 = array2.rotated()
		XCTAssertEqual(array1, [2, 3, 1])
		XCTAssertEqual(array2, [3, 1, 2])
		XCTAssertEqual(array3, [1, 2, 3])

		array.rotate()
		array1.rotate()
		array2.rotate()
		XCTAssertEqual(array, [2, 3, 1])
		XCTAssertEqual(array1, [3, 1, 2])
		XCTAssertEqual(array2, [1, 2, 3])
	}

	static var allTests = [
		("testStringSplit", testStringSplit),
		("testOccurrencesOfSubstring", testOccurrencesOfSubstring),
	]
}

private enum Fuzzer {
	static private let characterSets: [[Character]]
		= [["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "A", "S", "D", "F", "G", "H", "J",
			"K", "L", "Z", "X", "C", "V", "B", "N", "M", ],
		   ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p", "a", "s", "d", "f", "g", "h", "j",
			"k", "l", "z", "x", "c", "v", "b", "n", "m", ],
		   ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"],
		   ["~", "!", "@", "#", "$", "%", "^", "&", "*", "(", ")", "_", "+", "`", "-", "=", "[",
			"]", "{", "}", "\\", "|", ";", ":", "'", "\"", ",", "<", ".", ">", "/", "?", ],
		   ["\n", " ", "\t"], ]

	static func randomTest()
		-> (string: String, separator: String, occurrences: [TestableRange], components: [String])
	{
		var string = ""
		var separator = ""
		var occurrences = [TestableRange]()
		var components = [String]()

		let (separatorCharacterSet, componentCharacterSet) =
			characterSets.distinctRandomElements()

		let separatorSize = TestUtils.rng.random(1...5)

		for _ in 0..<separatorSize {
			separator.append(separatorCharacterSet.randomElement())
		}

		let count = TestUtils.rng.random(0...10)
		let startsWithSeparator = TestUtils.rng.randomBool()

		var isSeparator = startsWithSeparator
		var currentIndex = 0

		for _ in 0..<count {
			defer { isSeparator = !isSeparator }

			if isSeparator {
				string += separator
				occurrences.append(TestableRange(currentIndex, currentIndex + separator.count))
				currentIndex += separator.count
			}
			else {
				let componentSize = TestUtils.rng.random(0...10)

				// Allow separators to be glued together
				guard componentSize > 0 else { continue }

				let newComponent = String((0..<componentSize).map { _ in
					componentCharacterSet.randomElement()
				})
				string += newComponent
				components.append(newComponent)
				currentIndex += componentSize
			}
		}

		return (string: string,
				separator: separator,
				occurrences: occurrences,
				components: components)
	}
}
