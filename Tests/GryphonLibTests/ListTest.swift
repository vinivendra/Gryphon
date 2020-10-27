//
// Copyright 2018 Vinicius Jorge Vendramini
//
// Licensed under the Hippocratic License, Version 2.1;
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://firstdonoharm.dev/version/2/1/license.md
//
// To the full extent allowed by law, this software comes "AS IS,"
// WITHOUT ANY WARRANTY, EXPRESS OR IMPLIED, and licensor and any other
// contributor shall not be liable to anyone for any damages or other
// liability arising from, out of, or in connection with the sotfware
// or this license, under any kind of legal claim.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#if !GRYPHON
@testable import GryphonLib
import XCTest
#else
import Foundation
#endif

class ListTest: XCTestCase {
	public func getClassName() -> String {
		return "ListTest"
	}

	/// Tests to be run by the translated Kotlin version.
	public func runAllTests() {
		testEquatable()
		testInits()
		testCasting()
		testToMutableList()
		testSubscript()
		testDescription()
		// testDebugDescription()
		testCollectionIndices()
		testIsEmpty()
		testFirst()
		testLast()
		testIndexBefore()
		testAppending()
		testFilter()
		testMap()
		testCompactMap()
		testFlatMap()
		testSortedBy()
		testAppendingContentsOf()
		testIndices()
		testIndexOfElement()
		// testHash()
		testSorted()
		testZip()
		testPlus()
	}

	/// Tests to be run when using Swift on Linux
	static var allTests = [ // gryphon ignore
		("testEquatable", testEquatable),
		("testInits", testInits),
		("testCasting", testCasting),
		("testToMutableList", testToMutableList),
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
		("testZip", testZip),
		("testPlus", testPlus),
		]

	// MARK: - Tests
	func testEquatable() {
		let list1: List = [1, 2, 3]
		let list2: List = [1, 2, 3]
		let list3: List = [4, 5, 6]

		XCTAssert(list1 == list2)
		XCTAssertFalse(list2 == list3)
	}

	func testInits() {
		let list1: List = [1, 2, 3]
		let list2: List = List<Int>([1, 2, 3])
		let list3: List = List(list1) // gryphon ignore
		let sequence = AnySequence([1, 2, 3]) // gryphon ignore
		let list4: List = List(sequence) // gryphon ignore
		let list5: List = List<Int>()
		let list6: List<Int> = []

		XCTAssertEqual(list1, list2)
		XCTAssertEqual(list1, list3) // gryphon ignore
		XCTAssertEqual(list1, list4) // gryphon ignore
		XCTAssertNotEqual(list1, list5)
		XCTAssertNotEqual(list1, list6)
		XCTAssertEqual(list5, list6)
	}

	func testCasting() {
		let listOfAnys: List<Any> = [1, 2, 3]
		let listOfDifferentTypes: List<Any> = [1, "2", 3]

		// Downcasts succeed
		let downcastList: List<Int>? = listOfAnys.as(List<Int>.self)
		XCTAssertEqual(downcastList, [1, 2, 3])

		// Casts to unrelated types fail
		let failedCastList1: List<String>? = listOfAnys.as(List<String>.self)
		XCTAssertNil(failedCastList1)

		// Compatible casts succeed even if types are optional
		let optionalCastList: List<Int?>? = listOfAnys.as(List<Int?>.self)
		XCTAssertEqual(optionalCastList, [1, 2, 3])

		// Incompatible casts fail even if types are optional
		let failedCastList2: List<String?>? = listOfAnys.as(List<String?>.self)
		XCTAssertNil(failedCastList2)

		// Casts fail unless all elements match the casted type
		let failedCastList3: List<Int>? = listOfDifferentTypes.as(List<Int>.self)
		let failedCastList4: List<String>? = listOfDifferentTypes.as(List<String>.self)
		XCTAssertNil(failedCastList3)
		XCTAssertNil(failedCastList4)

		// Force downcasts succeed
		let forcedDowncastList: List<Int> = listOfAnys.forceCast(to: List<Int>.self)
		XCTAssertEqual(forcedDowncastList, [1, 2, 3])

		// Compatible forced casts succeed even if types are optional
		let forcedOptionalCastList: List<Int?> = listOfAnys.forceCast(to: List<Int?>.self)
		XCTAssertEqual(forcedOptionalCastList, [1, 2, 3])
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

	func testDebugDescription() { // gryphon ignore
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
		let list2 = list1.flatMap { List<Int>([$0, 10 * $0]) }
		XCTAssertEqual(list1, [1, 2, 3])
		XCTAssertEqual(list2, [1, 10, 2, 20, 3, 30])
	}

	func testSortedBy() {
		let list1: List = [3, 1, 2]
		let list2: List = [1, 2, 3]
		let sortedArray1 = list1.sorted { a, b in a < b }
		let sortedArray2 = list2.sorted { a, b in a < b }
		let sortedArray2Descending = list2.sorted { a, b in a > b }

		XCTAssertEqual(sortedArray1, [1, 2, 3])
		XCTAssertEqual(list1, [3, 1, 2])
		XCTAssertEqual(sortedArray2, [1, 2, 3])
		XCTAssertEqual(sortedArray2Descending, [3, 2, 1])
	}

	func testAppendingContentsOf() {
		let list1: List = [1, 2, 3]
		let list2: List = [4, 5, 6]
		let list3: List = [7, 8, 9]

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
		XCTAssertEqual(list.firstIndex(of: 1), 0)
		XCTAssertEqual(list.firstIndex(of: 2), 1)
		XCTAssertEqual(list.firstIndex(of: 10), 2)
	}

	func testHash() { // gryphon ignore
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

		XCTAssertEqual(list1.sorted(), List<Int>([1, 2, 3]))
		XCTAssertEqual(list1, [3, 2, 1])
		XCTAssertEqual(list2.sorted(), List<Int>([1, 2, 3]))
	}

	func testZip() {
		let array1: [Int] = [3, 2, 1] // gryphon mute
		let array2: [Int] = [1, 2, 3] // gryphon mute
		let list1: List = [3, 2, 1]
		let list2: List = [1, 2, 3]

		for (a, b) in zip(list1, list2) {
			XCTAssertEqual(a + b, 4)
		}

		for (a, b) in zip(array1, list2) { // gryphon mute
			XCTAssertEqual(a + b, 4)
		}

		for (a, b) in zip(list1, array2) { // gryphon mute
			XCTAssertEqual(a + b, 4)
		}
	}

	func testPlus() {
		let list1: List = [1, 2, 3]
		let list2: List = [4, 5, 6]
		let list3: List = [7, 8, 9]

		XCTAssertEqual(list1 + list2, [1, 2, 3, 4, 5, 6])
		XCTAssertEqual(list1, [1, 2, 3])
		XCTAssertEqual(list2, [4, 5, 6])

		XCTAssertEqual(list1 + list3, [1, 2, 3, 7, 8, 9])
		XCTAssertEqual(list1, [1, 2, 3])
		XCTAssertEqual(list3, [7, 8, 9])
	}
}
