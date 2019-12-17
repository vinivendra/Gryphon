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

@testable import GryphonLib
import XCTest

class ListTest: XCTestCase {
	func testEquatable() {
		let list1: List = [1, 2, 3]
		let list2: List = [1, 2, 3]
		let list3: List = [4, 5, 6]

		XCTAssert(list1 == list2)
		XCTAssertFalse(list2 == list3)
	}

	func testInits() {
		let list1: List = [1, 2, 3]
		let list2: List = List([1, 2, 3])
		let list3: List = List(list1)
		let sequence = AnySequence([1, 2, 3])
		let list4: List = List(sequence)
		let list5: List<Int> = List()
		let list6: List<Int> = []

		XCTAssertEqual(list1, list2)
		XCTAssertEqual(list1, list3)
		XCTAssertEqual(list1, list4)
		XCTAssertNotEqual(list1, list5)
		XCTAssertNotEqual(list1, list6)
		XCTAssertEqual(list5, list6)
	}

	func testCasting() {
		let list1: List<Any> = [1, 2, 3]

		let failedCast: List<String>? = list1.as(List<String>.self)
		let successfulCast: List<Int>? = list1.as(List<Int>.self)

		XCTAssertNil(failedCast)
		XCTAssertNotNil(successfulCast)
		XCTAssertEqual(successfulCast, [1, 2, 3])
	}

	func testToMutableList() {
		let list1: List = [1, 2, 3]
		let list2: List = [1, 2, 3, 4]
		let mutableList: MutableList = list1.toMutableList()

		XCTAssert(list1 == mutableList)
		XCTAssert(mutableList == list1)
		XCTAssert(list2 != mutableList)
		XCTAssert(mutableList != list2)
	}

	func testSubscript() {
		let list1: List = [1, 2, 3]

		XCTAssertEqual(list1[0], 1)
		XCTAssertEqual(list1[1], 2)
		XCTAssertEqual(list1[2], 3)
	}

	func testDescription() {
		let list: List = [1, 2, 3]

		XCTAssert(list.description.contains("1"))
		XCTAssert(list.description.contains("2"))
		XCTAssert(list.description.contains("3"))
		XCTAssert(!list.description.contains("4"))
	}

	func testDebugDescription() {
		let list: List = [1, 2, 3]

		XCTAssert(list.debugDescription.contains("1"))
		XCTAssert(list.debugDescription.contains("2"))
		XCTAssert(list.debugDescription.contains("3"))
		XCTAssert(!list.debugDescription.contains("4"))
	}

	func testCollectionIndices() {
		let list: List = [1, 2, 3]
		let middleIndex = list.index(after: list.startIndex)
		let lastIndex = list.index(after: middleIndex)
		let endIndex = list.index(after: lastIndex)

		// Test start index
		XCTAssertEqual(list[list.startIndex], 1)

		// Test index(after:)
		XCTAssertEqual(list[middleIndex], 2)
		XCTAssertEqual(list[lastIndex], 3)

		// Test endIndex
		XCTAssertEqual(endIndex, list.endIndex)
		XCTAssertNotEqual(lastIndex, list.endIndex)
	}

	func testIsEmpty() {
		let list: List = [1, 2, 3]
		let emptyList: List<Int> = []

		XCTAssert(!list.isEmpty)
		XCTAssert(emptyList.isEmpty)
	}

	func testFirst() {
		let list: List = [1, 2, 3]
		let emptyList: List<Int> = []

		XCTAssertEqual(list.first, 1)
		XCTAssertEqual(emptyList.first, nil)
	}

	func testLast() {
		let list: List = [1, 2, 3]
		let emptyList: List<Int> = []

		XCTAssertEqual(list.last, 3)
		XCTAssertEqual(emptyList.last, nil)
	}

	func testIndexBefore() {
		let list: List = [1, 2, 3]
		let lastIndex = list.index(before: list.endIndex)

		XCTAssertEqual(list[lastIndex], 3)
	}

	func testAppending() {
		let list1: List = [1, 2, 3]
		let list2 = list1.appending(4)
		XCTAssertEqual(list2, [1, 2, 3, 4])
		XCTAssertEqual(list1, [1, 2, 3])
	}

	func testFilter() {
		let list1: List = [1, 2, 3]
		let list2 = list1.filter { $0 > 1 }
		XCTAssertEqual(list1, [1, 2, 3])
		XCTAssertEqual(list2, [2, 3])
	}

	func testMap() {
		let list1: List = [1, 2, 3]
		let list2 = list1.map { $0 * 2 }
		XCTAssertEqual(list1, [1, 2, 3])
		XCTAssertEqual(list2, [2, 4, 6])
	}

	func testCompactMap() {
		let list1: List = [1, 2, 3]
		let list2 = list1.compactMap { (e: Int) -> Int? in (e == 2) ? e : nil }
		XCTAssertEqual(list1, [1, 2, 3])
		XCTAssertEqual(list2, [2])
	}

	func testFlatMap() {
		let list1: List = [1, 2, 3]
		let list2 = list1.flatMap { [$0, 10 * $0] }
		XCTAssertEqual(list1, [1, 2, 3])
		XCTAssertEqual(list2, [1, 10, 2, 20, 3, 30])
	}

	func testSortedBy() {
		let list1: List = [3, 1, 2]
		let list2: List = [1, 2, 3]

		XCTAssertEqual(list1.sorted { $0 < $1 }, [1, 2, 3])
		XCTAssertEqual(list1, [3, 1, 2])
		XCTAssertEqual(list2.sorted { $0 < $1 }, [1, 2, 3])
		XCTAssertEqual(list2.sorted { $0 > $1 }, [3, 2, 1])
	}

	func testAppendingContentsOf() {
		let list1: List = [1, 2, 3]
		let list2: List = [4, 5, 6]
		let list3: List<Int> = [7, 8, 9]

		XCTAssertEqual(list1.appending(contentsOf: list2), [1, 2, 3, 4, 5, 6])
		XCTAssertEqual(list1, [1, 2, 3])
		XCTAssertEqual(list2, [4, 5, 6])

		XCTAssertEqual(list1.appending(contentsOf: list3), [1, 2, 3, 7, 8, 9])
		XCTAssertEqual(list1, [1, 2, 3])
		XCTAssertEqual(list3, [7, 8, 9])
	}

	func testIndices() {
		let list: List = [1, 2, 3]
		XCTAssertEqual(list.indices, 0..<3)
	}

	func testIndexOfElement() {
		let list: List = [1, 2, 10]
		XCTAssertEqual(list.index(of: 1), 0)
		XCTAssertEqual(list.index(of: 2), 1)
		XCTAssertEqual(list.index(of: 10), 2)
	}

	func testHash() {
		let list1: List = [1, 2, 3]
		let list2: List = [1, 2, 3]
		let list3: List = [1, 2, 3, 4]
		let hash1 = list1.hashValue
		let hash2 = list2.hashValue
		let hash3 = list3.hashValue

		XCTAssertEqual(hash1, hash2)
		XCTAssertNotEqual(hash1, hash3)
		XCTAssertNotEqual(hash2, hash3)
	}

	func testSorted() {
		let list1: List = [3, 2, 1]
		let list2: List = [1, 2, 3]

		XCTAssertEqual(list1.sorted(), [1, 2, 3])
		XCTAssertEqual(list1, [3, 2, 1])
		XCTAssertEqual(list2.sorted(), [1, 2, 3])
	}

	func testZipToClass() {
		let list1: List = [3, 2, 1]
		let list2: List = [1, 2, 3]

		for (a, b) in zipToClass(list1, list2) {
			XCTAssertEqual(a + b, 4)
		}
	}

	static var allTests = [
		("testEquatable", testEquatable),
		("testInits", testInits),
		("testCasting", testCasting),
		("testSubscript", testSubscript),
		("testDescription", testDescription),
		("testDebugDescription", testDebugDescription),
		("testCollectionIndices", testCollectionIndices),
		("testIsEmpty", testIsEmpty),
		("testFirst", testFirst),
		("testLast", testLast),
		("testIndexBefore", testIndexBefore),
		("testAppending", testAppending),
		("testFilter", testFilter),
		("testMap", testMap),
		("testCompactMap", testCompactMap),
		("testFlatMap", testFlatMap),
		("testSortedBy", testSortedBy),
		("testAppendingContentsOf", testAppendingContentsOf),
		("testIndices", testIndices),
		("testIndexOfElement", testIndexOfElement),
		("testHash", testHash),
		("testSorted", testSorted),
		("testZipToClass", testZipToClass),
		]
}
