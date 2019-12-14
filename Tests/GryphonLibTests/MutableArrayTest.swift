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

// gryphon output: Bootstrap/MutableArrayTest.kt

#if !IS_DUMPING_ASTS
@testable import GryphonLib
import XCTest
#else
import Foundation
#endif

class MutableArrayTest: XCTestCase {
	// declaration: constructor(): super() { }

	public func getClassName() -> String { // annotation: override
		return "MutableArrayTest"
	}

	override public func runAllTests() { // annotation: override
		testEquatable()
		testInits()
		testPassingByReference()
		testCasting()
		testCopy()
		testToFixedArray()
		testSubscript()
		testDescription()
		testCollectionIndices()
		testIsEmpty()
		testFirst()
		testLast()
		testIndexBefore()
		testAppendContentsOf()
		testAppend()
		testAppending()
		testInsert()
		testFilter()
		testMap()
		testCompactMap()
		testFlatMap()
		testSortedBy()
		testAppendingContentsOf()
		testRemoveFirst()
		testRemoveLast()
		testReverse()
		testIndices()
		testIndexOfElement()
		testSorted()
		testZipToClass()
	}

	static var allTests = [ // kotlin: ignore
		("testEquatable", testEquatable),
		("testInits", testInits),
		("testPassingByReference", testPassingByReference),
		("testCasting", testCasting),
		("testCopy", testCopy),
		("testToFixedArray", testToFixedArray),
		("testSubscript", testSubscript),
		("testDescription", testDescription),
		("testDebugDescription", testDebugDescription),
		("testCollectionIndices", testCollectionIndices),
		("testIsEmpty", testIsEmpty),
		("testFirst", testFirst),
		("testLast", testLast),
		("testIndexBefore", testIndexBefore),
		("testAppendContentsOf", testAppendContentsOf),
		("testAppend", testAppend),
		("testAppending", testAppending),
		("testInsert", testInsert),
		("testFilter", testFilter),
		("testMap", testMap),
		("testCompactMap", testCompactMap),
		("testFlatMap", testFlatMap),
		("testSortedBy", testSortedBy),
		("testAppendingContentsOf", testAppendingContentsOf),
		("testRemoveFirst", testRemoveFirst),
		("testRemoveLast", testRemoveLast),
		("testReverse", testReverse),
		("testIndices", testIndices),
		("testIndexOfElement", testIndexOfElement),
		("testHash", testHash),
		("testCodable", testCodable),
		("testSorted", testSorted),
		("testZipToClass", testZipToClass),
	]

	// MARK: - Tests
	func testEquatable() {
		let array1: MutableArray<Int> = [1, 2, 3]
		let array2: MutableArray<Int> = [1, 2, 3]
		let array3: MutableArray<Int> = [4, 5, 6]

		XCTAssert(array1 == array2)
		XCTAssertFalse(array2 == array3)
	}

	func testInits() {
		let array1: MutableArray<Int> = [1, 2, 3]
		let array2: MutableArray<Int> = MutableArray<Int>([1, 2, 3])
		let array3: MutableArray = MutableArray(array1) // kotlin: ignore
		let sequence = AnySequence([1, 2, 3]) // kotlin: ignore
		let array4: MutableArray<Int> = MutableArray<Int>(sequence) // kotlin: ignore
		let array5: MutableArray<Int> = MutableArray<Int>()
		let array6: MutableArray<Int> = []

		XCTAssertEqual(array1, array2)
		XCTAssertEqual(array1, array3) // kotlin: ignore
		XCTAssertEqual(array1, array4) // kotlin: ignore
		XCTAssertEqual(array5, array6)

		array1.append(4)
		array5.append(4)

		XCTAssertNotEqual(array1, array2)
		XCTAssertNotEqual(array1, array3) // kotlin: ignore
		XCTAssertNotEqual(array1, array4) // kotlin: ignore
		XCTAssertNotEqual(array5, array6)
		XCTAssertEqual(array2, [1, 2, 3])
		XCTAssertEqual(array2, array3) // kotlin: ignore
		XCTAssertEqual(array2, array4) // kotlin: ignore
	}

	func testPassingByReference() {
		let array1: MutableArray<Int> = [1, 2, 3]
		let array2 = array1
		array1[0] = 10
		XCTAssertEqual(array1, array2)
	}

	func testCasting() {
		let array1: MutableArray<Any> = [1, 2, 3]

		let failedCast: MutableArray<String>? = array1.as(MutableArray<String>.self)
		let successfulCast: MutableArray<Int>? = array1.as(MutableArray<Int>.self)

		XCTAssertNil(failedCast)
		XCTAssertNotNil(successfulCast)
		XCTAssertEqual(successfulCast, [1, 2, 3])
	}

	func testCopy() {
		let array1: MutableArray<Int> = [1, 2, 3]
		let array2 = array1.copy()
		array1[0] = 10
		XCTAssertNotEqual(array1, array2)
	}

	func testToFixedArray() {
		let array1: MutableArray<Int> = [1, 2, 3]
		let array2: MutableArray<Int> = [1, 2, 3, 4]
		let fixedArray: FixedArray<Int> = array1.toFixedArray()

		XCTAssert(array1 == fixedArray)
		XCTAssert(fixedArray == array1)
		XCTAssert(array2 != fixedArray)
		XCTAssert(fixedArray != array2)
	}

	func testSubscript() {
		let array1: MutableArray<Int> = [1, 2, 3]
		let array2: MutableArray<Int> = [10, 2, 3]
		array1[0] = 10

		XCTAssertEqual(array1, array2)

		XCTAssertEqual(array1[0], 10)
		XCTAssertEqual(array1[1], 2)
		XCTAssertEqual(array1[2], 3)
	}

	func testDescription() {
		let array: MutableArray<Int> = [1, 2, 3]

		XCTAssert(array.description.contains("1"))
		XCTAssert(array.description.contains("2"))
		XCTAssert(array.description.contains("3"))
		XCTAssert(!array.description.contains("4"))
	}

	func testDebugDescription() { // kotlin: ignore
		let array: MutableArray<Int> = [1, 2, 3]

		XCTAssert(array.debugDescription.contains("1"))
		XCTAssert(array.debugDescription.contains("2"))
		XCTAssert(array.debugDescription.contains("3"))
		XCTAssert(!array.debugDescription.contains("4"))
	}

	func testCollectionIndices() {
		let array: MutableArray<Int> = [1, 2, 3]
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
		let array: MutableArray<Int> = [1, 2, 3]
		let emptyArray: MutableArray<Int> = []

		XCTAssert(!array.isEmpty)
		XCTAssert(emptyArray.isEmpty)
	}

	func testFirst() {
		let array: MutableArray<Int> = [1, 2, 3]
		let emptyArray: MutableArray<Int> = []

		XCTAssertEqual(array.first, 1)
		XCTAssertEqual(emptyArray.first, nil)
	}

	func testLast() {
		let array: MutableArray<Int> = [1, 2, 3]
		let emptyArray: MutableArray<Int> = []

		XCTAssertEqual(array.last, 3)
		XCTAssertEqual(emptyArray.last, nil)
	}

	func testIndexBefore() {
		let array: MutableArray<Int> = [1, 2, 3]
		let lastIndex = array.index(before: array.endIndex)

		XCTAssertEqual(array[lastIndex], 3)
	}

	func testAppendContentsOf() {
		let array1: MutableArray<Int> = [1, 2, 3]
		let array2: MutableArray<Int> = [4, 5, 6]

		array1.append(contentsOf: array2)
		XCTAssertEqual(array1, [1, 2, 3, 4, 5, 6])
	}

	func testAppend() {
		let array1: MutableArray<Int> = [1, 2, 3]
		array1.append(4)
		XCTAssertEqual(array1, [1, 2, 3, 4])
	}

	func testAppending() {
		let array1: MutableArray<Int> = [1, 2, 3]
		let array2 = array1.appending(4)
		XCTAssertEqual(array2, [1, 2, 3, 4])
		XCTAssertEqual(array1, [1, 2, 3])
	}

	func testInsert() {
		let array1: MutableArray<Int> = [1, 2, 3]

		array1.insert(0, at: 0)
		XCTAssertEqual(array1, [0, 1, 2, 3])

		array1.insert(10, at: 2)
		XCTAssertEqual(array1, [0, 1, 10, 2, 3])

		array1.insert(10, at: 5)
		XCTAssertEqual(array1, [0, 1, 10, 2, 3, 10])
	}

	func testFilter() {
		let array1: MutableArray<Int> = [1, 2, 3]
		let array2 = array1.filter { $0 > 1 }
		XCTAssertEqual(array1, [1, 2, 3])
		XCTAssertEqual(array2, [2, 3])
	}

	func testMap() {
		let array1: MutableArray<Int> = [1, 2, 3]
		let array2 = array1.map { $0 * 2 }
		XCTAssertEqual(array1, [1, 2, 3])
		XCTAssertEqual(array2, [2, 4, 6])
	}

	func testCompactMap() {
		let array1: MutableArray<Int> = [1, 2, 3]
		let array2 = array1.compactMap { (e: Int) -> Int? in (e == 2) ? e : nil }
		XCTAssertEqual(array1, [1, 2, 3])
		XCTAssertEqual(array2, [2])
	}

	func testFlatMap() {
		let array1: MutableArray<Int> = [1, 2, 3]
		let array2 = array1.flatMap { [$0, 10 * $0] }
		XCTAssertEqual(array1, [1, 2, 3])
		XCTAssertEqual(array2, [1, 10, 2, 20, 3, 30])
	}

	func testSortedBy() {
		let array1: MutableArray<Int> = [3, 1, 2]
		let array2: MutableArray<Int> = [1, 2, 3]
		let sortedArray1 = array1.sorted { a, b in a < b }
		let sortedArray2 = array2.sorted { a, b in a < b }
		let sortedArray2Descending = array2.sorted { a, b in a > b }

		XCTAssertEqual(sortedArray1, [1, 2, 3])
		XCTAssertEqual(array1, [3, 1, 2])
		XCTAssertEqual(sortedArray2, [1, 2, 3])
		XCTAssertEqual(sortedArray2Descending, [3, 2, 1])
	}

	func testAppendingContentsOf() {
		let array1: MutableArray<Int> = [1, 2, 3]
		let array2: MutableArray<Int> = [4, 5, 6]
		let array3: MutableArray<Int> = [7, 8, 9]

		XCTAssertEqual(array1.appending(contentsOf: array2), [1, 2, 3, 4, 5, 6])
		XCTAssertEqual(array1, [1, 2, 3])
		XCTAssertEqual(array2, [4, 5, 6])

		XCTAssertEqual(array1.appending(contentsOf: array3), [1, 2, 3, 7, 8, 9])
		XCTAssertEqual(array1, [1, 2, 3])
		XCTAssertEqual(array3, [7, 8, 9])
	}

	func testRemoveFirst() {
		let array: MutableArray<Int> = [1, 2, 3]
		array.removeFirst()

		XCTAssertEqual(array, [2, 3])
	}

	func testRemoveLast() {
		let array: MutableArray<Int> = [1, 2, 3]
		array.removeLast()

		XCTAssertEqual(array, [1, 2])
	}

	func testReverse() {
		let array: MutableArray<Int> = [1, 2, 3]
		array.reverse()

		XCTAssertEqual(array, [3, 2, 1])
	}

	func testIndices() {
		let array: MutableArray<Int> = [1, 2, 3]
		XCTAssertEqual(array.indices, 0..<3)
	}

	func testIndexOfElement() {
		let array: MutableArray<Int> = [1, 2, 10]
		XCTAssertEqual(array.index(of: 1), 0)
		XCTAssertEqual(array.index(of: 2), 1)
		XCTAssertEqual(array.index(of: 10), 2)
	}

	func testHash() { // kotlin: ignore
		let array1: MutableArray<Int> = [1, 2, 3]
		let array2: MutableArray<Int> = [1, 2, 3]
		let array3: MutableArray<Int> = [1, 2, 3, 4]
		let hash1 = array1.hashValue
		let hash2 = array2.hashValue
		let hash3 = array3.hashValue

		XCTAssertEqual(hash1, hash2)
		XCTAssertNotEqual(hash1, hash3)
		XCTAssertNotEqual(hash2, hash3)
	}

	func testCodable() { // kotlin: ignore
		let array1: MutableArray<Int> = [1, 2, 3]
		let array2: MutableArray<Int> = [1, 2, 3, 4]

		let encoding1 = try! JSONEncoder().encode(array1)
		let array3 = try! JSONDecoder().decode(MutableArray<Int>.self, from: encoding1)

		let encoding2 = try! JSONEncoder().encode(array2)
		let array4 = try! JSONDecoder().decode(MutableArray<Int>.self, from: encoding2)

		XCTAssertEqual(array1, array3)
		XCTAssertEqual(array2, array4)
		XCTAssertNotEqual(array3, array4)
	}

	func testSorted() {
		let array1: MutableArray<Int> = [3, 2, 1]
		let array2: MutableArray<Int> = [1, 2, 3]

		XCTAssertEqual(array1.sorted(), [1, 2, 3])
		XCTAssertEqual(array1, [3, 2, 1])
		XCTAssertEqual(array2.sorted(), [1, 2, 3])
	}

	func testZipToClass() {
		let array1: MutableArray<Int> = [3, 2, 1]
		let array2: MutableArray<Int> = [1, 2, 3]

		for (a, b) in zipToClass(array1, array2) {
			XCTAssertEqual(a + b, 4)
		}
	}
}
