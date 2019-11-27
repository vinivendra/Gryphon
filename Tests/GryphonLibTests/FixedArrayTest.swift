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

class FixedArrayTest: XCTestCase {
	func testEquatable() {
		let array1: FixedArray = [1, 2, 3]
		let array2: FixedArray = [1, 2, 3]
		let array3: FixedArray = [4, 5, 6]

		XCTAssert(array1 == array2)
		XCTAssertFalse(array2 == array3)
	}

	func testInits() {
		let array1: FixedArray = [1, 2, 3]
		let array2: FixedArray = FixedArray([1, 2, 3])
		let array3: FixedArray = FixedArray(array1)
		let sequence = AnySequence([1, 2, 3])
		let array4: FixedArray = FixedArray(sequence)
		let array5: FixedArray<Int> = FixedArray()
		let array6: FixedArray<Int> = []

		XCTAssertEqual(array1, array2)
		XCTAssertEqual(array1, array3)
		XCTAssertEqual(array1, array4)
		XCTAssertNotEqual(array1, array5)
		XCTAssertNotEqual(array1, array6)
		XCTAssertEqual(array5, array6)
	}

	func testCasting() {
		let array1: FixedArray<Any> = [1, 2, 3]

		let failedCast: FixedArray<String>? = array1.as(FixedArray<String>.self)
		let successfulCast: FixedArray<Int>? = array1.as(FixedArray<Int>.self)

		XCTAssertNil(failedCast)
		XCTAssertNotNil(successfulCast)
		XCTAssertEqual(successfulCast, [1, 2, 3])
	}

	func testToMutableArray() {
		let array1: FixedArray = [1, 2, 3]
		let array2: FixedArray = [1, 2, 3, 4]
		let mutableArray: MutableArray = array1.toMutableArray()

		XCTAssert(array1 == mutableArray)
		XCTAssert(mutableArray == array1)
		XCTAssert(array2 != mutableArray)
		XCTAssert(mutableArray != array2)
	}

	func testSubscript() {
		let array1: FixedArray = [1, 2, 3]

		XCTAssertEqual(array1[0], 1)
		XCTAssertEqual(array1[1], 2)
		XCTAssertEqual(array1[2], 3)
	}

	func testDescription() {
		let array: FixedArray = [1, 2, 3]

		XCTAssert(array.description.contains("1"))
		XCTAssert(array.description.contains("2"))
		XCTAssert(array.description.contains("3"))
		XCTAssert(!array.description.contains("4"))
	}

	func testDebugDescription() {
		let array: FixedArray = [1, 2, 3]

		XCTAssert(array.debugDescription.contains("1"))
		XCTAssert(array.debugDescription.contains("2"))
		XCTAssert(array.debugDescription.contains("3"))
		XCTAssert(!array.debugDescription.contains("4"))
	}

	func testCollectionIndices() {
		let array: FixedArray = [1, 2, 3]
		let middleIndex = array.index(after: array.startIndex)
		let lastIndex = array.index(after: middleIndex)
		let endIndex = array.index(after: lastIndex)

		// Test start index
		XCTAssertEqual(array[array.startIndex], 1)

		// Test index(after:)
		XCTAssertEqual(array[middleIndex], 2)
		XCTAssertEqual(array[lastIndex], 3)

		// Test endIndex
		XCTAssertEqual(endIndex, array.endIndex)
		XCTAssertNotEqual(lastIndex, array.endIndex)
	}

	func testIsEmpty() {
		let array: FixedArray = [1, 2, 3]
		let emptyArray: FixedArray<Int> = []

		XCTAssert(!array.isEmpty)
		XCTAssert(emptyArray.isEmpty)
	}

	func testFirst() {
		let array: FixedArray = [1, 2, 3]
		let emptyArray: FixedArray<Int> = []

		XCTAssertEqual(array.first, 1)
		XCTAssertEqual(emptyArray.first, nil)
	}

	func testLast() {
		let array: FixedArray = [1, 2, 3]
		let emptyArray: FixedArray<Int> = []

		XCTAssertEqual(array.last, 3)
		XCTAssertEqual(emptyArray.last, nil)
	}

	func testIndexBefore() {
		let array: FixedArray = [1, 2, 3]
		let lastIndex = array.index(before: array.endIndex)

		XCTAssertEqual(array[lastIndex], 3)
	}

	func testAppending() {
		let array1: FixedArray = [1, 2, 3]
		let array2 = array1.appending(4)
		XCTAssertEqual(array2, [1, 2, 3, 4])
		XCTAssertEqual(array1, [1, 2, 3])
	}

	func testFilter() {
		let array1: FixedArray = [1, 2, 3]
		let array2 = array1.filter { $0 > 1 }
		XCTAssertEqual(array1, [1, 2, 3])
		XCTAssertEqual(array2, [2, 3])
	}

	func testMap() {
		let array1: FixedArray = [1, 2, 3]
		let array2 = array1.map { $0 * 2 }
		XCTAssertEqual(array1, [1, 2, 3])
		XCTAssertEqual(array2, [2, 4, 6])
	}

	func testCompactMap() {
		let array1: FixedArray = [1, 2, 3]
		let array2 = array1.compactMap { (e: Int) -> Int? in (e == 2) ? e : nil }
		XCTAssertEqual(array1, [1, 2, 3])
		XCTAssertEqual(array2, [2])
	}

	func testFlatMap() {
		let array1: FixedArray = [1, 2, 3]
		let array2 = array1.flatMap { [$0, 10 * $0] }
		XCTAssertEqual(array1, [1, 2, 3])
		XCTAssertEqual(array2, [1, 10, 2, 20, 3, 30])
	}

	func testSortedBy() {
		let array1: FixedArray = [3, 1, 2]
		let array2: FixedArray = [1, 2, 3]

		XCTAssertEqual(array1.sorted { $0 < $1 }, [1, 2, 3])
		XCTAssertEqual(array1, [3, 1, 2])
		XCTAssertEqual(array2.sorted { $0 < $1 }, [1, 2, 3])
		XCTAssertEqual(array2.sorted { $0 > $1 }, [3, 2, 1])
	}

	func testAppendingContentsOf() {
		let array1: FixedArray = [1, 2, 3]
		let array2: FixedArray = [4, 5, 6]
		let array3: FixedArray<Int> = [7, 8, 9]

		XCTAssertEqual(array1.appending(contentsOf: array2), [1, 2, 3, 4, 5, 6])
		XCTAssertEqual(array1, [1, 2, 3])
		XCTAssertEqual(array2, [4, 5, 6])

		XCTAssertEqual(array1.appending(contentsOf: array3), [1, 2, 3, 7, 8, 9])
		XCTAssertEqual(array1, [1, 2, 3])
		XCTAssertEqual(array3, [7, 8, 9])
	}

	func testIndices() {
		let array: FixedArray = [1, 2, 3]
		XCTAssertEqual(array.indices, 0..<3)
	}

	func testIndexOfElement() {
		let array: FixedArray = [1, 2, 10]
		XCTAssertEqual(array.index(of: 1), 0)
		XCTAssertEqual(array.index(of: 2), 1)
		XCTAssertEqual(array.index(of: 10), 2)
	}

	func testHash() {
		let array1: FixedArray = [1, 2, 3]
		let array2: FixedArray = [1, 2, 3]
		let array3: FixedArray = [1, 2, 3, 4]
		let hash1 = array1.hashValue
		let hash2 = array2.hashValue
		let hash3 = array3.hashValue

		XCTAssertEqual(hash1, hash2)
		XCTAssertNotEqual(hash1, hash3)
		XCTAssertNotEqual(hash2, hash3)
	}

	func testCodable() {
		let array1: FixedArray = [1, 2, 3]
		let array2: FixedArray = [1, 2, 3, 4]

		let encoding1 = try! JSONEncoder().encode(array1)
		let array3 = try! JSONDecoder().decode(FixedArray<Int>.self, from: encoding1)

		let encoding2 = try! JSONEncoder().encode(array2)
		let array4 = try! JSONDecoder().decode(FixedArray<Int>.self, from: encoding2)

		XCTAssertEqual(array1, array3)
		XCTAssertEqual(array2, array4)
		XCTAssertNotEqual(array3, array4)
	}

	func testSorted() {
		let array1: FixedArray = [3, 2, 1]
		let array2: FixedArray = [1, 2, 3]

		XCTAssertEqual(array1.sorted(), [1, 2, 3])
		XCTAssertEqual(array1, [3, 2, 1])
		XCTAssertEqual(array2.sorted(), [1, 2, 3])
	}

	func testZipToClass() {
		let array1: FixedArray = [3, 2, 1]
		let array2: FixedArray = [1, 2, 3]

		for (a, b) in zipToClass(array1, array2) {
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
		("testCodable", testCodable),
		("testSorted", testSorted),
		("testZipToClass", testZipToClass),
		]
}
