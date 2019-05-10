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

class ExtensionsTest: XCTestCase {
	func testStringSplit() {
		XCTAssertEqual(
			"->".split(withStringSeparator: "->"),
			[])
		XCTAssertEqual(
			"->->".split(withStringSeparator: "->"),
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

		// Omit empty subsequences
		XCTAssertEqual(
			"->".split(withStringSeparator: "->", omittingEmptySubsequences: false),
			["", ""])
		XCTAssertEqual(
			"->->".split(withStringSeparator: "->", omittingEmptySubsequences: false),
			["", "", ""])
		XCTAssertEqual(
			"a->b".split(withStringSeparator: "->", omittingEmptySubsequences: false),
			["a", "b"])
		XCTAssertEqual(
			"a->b->c".split(withStringSeparator: "->", omittingEmptySubsequences: false),
			["a", "b", "c"])
		XCTAssertEqual(
			"->b->c".split(withStringSeparator: "->", omittingEmptySubsequences: false),
			["", "b", "c"])
		XCTAssertEqual(
			"->->c".split(withStringSeparator: "->", omittingEmptySubsequences: false),
			["", "", "c"])
		XCTAssertEqual(
			"a->b->".split(withStringSeparator: "->", omittingEmptySubsequences: false),
			["a", "b", ""])
		XCTAssertEqual(
			"a->->".split(withStringSeparator: "->", omittingEmptySubsequences: false),
			["a", "", ""])
		XCTAssertEqual(
			"a->->b".split(withStringSeparator: "->", omittingEmptySubsequences: false),
			["a", "", "b"])
		XCTAssertEqual(
			"abc".split(withStringSeparator: "->", omittingEmptySubsequences: false),
			["abc"])
		XCTAssertEqual(
			"->(Int, (String) -> Int) ->-> Int ->"
				.split(withStringSeparator: "->", omittingEmptySubsequences: false),
			["", "(Int, (String) ", " Int) ", "", " Int ", ""])

		// Max splits
		XCTAssertEqual(
			"->".split(withStringSeparator: "->", maxSplits: 3, omittingEmptySubsequences: false),
			["", ""])
		XCTAssertEqual(
			"->->".split(withStringSeparator: "->", maxSplits: 1, omittingEmptySubsequences: false),
			["", "->"])
		XCTAssertEqual(
			"a->b".split(withStringSeparator: "->", maxSplits: 0, omittingEmptySubsequences: false),
			["a->b"])
		XCTAssertEqual(
			"a->b->c".split(
				withStringSeparator: "->", maxSplits: 2, omittingEmptySubsequences: false),
			["a", "b", "c"])
		XCTAssertEqual(
			"a->b->c->d".split(
				withStringSeparator: "->", maxSplits: 2, omittingEmptySubsequences: false),
			["a", "b", "c->d"])
		XCTAssertEqual(
			"a->b->c->d".split(
				withStringSeparator: "->", maxSplits: 1, omittingEmptySubsequences: false),
			["a", "b->c->d"])
		XCTAssertEqual(
			"->b->c".split(withStringSeparator: "->", maxSplits: 1),
			["b->c"])
		XCTAssertEqual(
			"->->c".split(withStringSeparator: "->", maxSplits: 1),
			["->c"])
		XCTAssertEqual(
			"a->b->".split(withStringSeparator: "->", maxSplits: 1),
			["a", "b->"])
		XCTAssertEqual(
			"a->->".split(withStringSeparator: "->", maxSplits: 1),
			["a", "->"])
		XCTAssertEqual(
			"a->->b".split(withStringSeparator: "->", maxSplits: 1),
			["a", "->b"])
		XCTAssertEqual(
			"abc".split(withStringSeparator: "->", maxSplits: 0),
			["abc"])
		XCTAssertEqual(
			"abc".split(withStringSeparator: "->", maxSplits: 1),
			["abc"])
		XCTAssertEqual(
			"->(Int, (String) -> Int) ->-> Int ->"
				.split(withStringSeparator: "->", maxSplits: 3, omittingEmptySubsequences: false),
			["", "(Int, (String) ", " Int) ", "-> Int ->"])
		XCTAssertEqual(
			"->(Int, (String) -> Int) ->-> Int ->"
				.split(withStringSeparator: "->", maxSplits: 3),
			["(Int, (String) ", " Int) ", "-> Int ->"])
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
	}

	func testRemoveTrailingWhitespace() {
		XCTAssertEqual("", "".removeTrailingWhitespace())
		XCTAssertEqual("a", "a".removeTrailingWhitespace())
		XCTAssertEqual("abcde", "abcde".removeTrailingWhitespace())
		XCTAssertEqual("abcde", "abcde".removeTrailingWhitespace())
		XCTAssertEqual("abcde", "abcde  \t\t  ".removeTrailingWhitespace())
		XCTAssertEqual("abcde  \t\t  abcde", "abcde  \t\t  abcde".removeTrailingWhitespace())
		XCTAssertEqual("abcde  \t\t  abcde", "abcde  \t\t  abcde  ".removeTrailingWhitespace())
		XCTAssertEqual("abcde  \t\t  abcde", "abcde  \t\t  abcde \t ".removeTrailingWhitespace())
	}

	func testUpperSnakeCase() {
		XCTAssertEqual("ABC", "abc".upperSnakeCase())
		XCTAssertEqual("FOO_BAR", "fooBar".upperSnakeCase())
		XCTAssertEqual("FOO_BAR", "FooBar".upperSnakeCase())
		XCTAssertEqual("HTTPS_BAR", "HTTPSBar".upperSnakeCase())
	}

	func testSafeIndex() {
		let array: ArrayClass = [1, 2, 3]
		XCTAssert(array[safe: 0] == 1)
		XCTAssert(array[safe: 1] == 2)
		XCTAssert(array[safe: 2] == 3)
		XCTAssert(array[safe: 3] == nil)
		XCTAssert(array[safe: -1] == nil)
	}

	func testSecondToLast() {
		let array1: ArrayClass = [1, 2, 3]
		let array2: ArrayClass = [1]
		XCTAssert(array1.secondToLast == 2)
		XCTAssert(array2.secondToLast == nil)
	}

	func testRotate() {
		let array: ArrayClass = [1, 2, 3]
		let array1 = array.rotated()
		let array2 = array1.rotated()
		let array3 = array2.rotated()
		XCTAssertEqual(array1, [2, 3, 1])
		XCTAssertEqual(array2, [3, 1, 2])
		XCTAssertEqual(array3, [1, 2, 3])
	}

	func testGroupBy() {
		let array: ArrayClass = [1, 2, 3, 2, 3, 1, 2, 3]
		let histogram = array.group(by: { "\($0)" })
		XCTAssertEqual(
			histogram,
			["1": [1, 1],
			 "2": [2, 2, 2],
			 "3": [3, 3, 3], ])

		let isEvenHistogram = array.group(by: { $0 % 2 == 0 })
		XCTAssertEqual(
			isEvenHistogram,
			[true: [2, 2, 2],
			 false: [1, 3, 3, 1, 3], ])
	}

	static var allTests = [
		("testStringSplit", testStringSplit),
		("testOccurrencesOfSubstring", testOccurrencesOfSubstring),
		("testRemoveTrailingWhitespace", testRemoveTrailingWhitespace),
		("testUpperSnakeCase", testUpperSnakeCase),
		("testSafeIndex", testSafeIndex),
		("testSecondToLast", testSecondToLast),
		("testRotate", testRotate),
		("testGroupBy", testGroupBy),
	]
}
