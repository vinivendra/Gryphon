//
// Copyright 2018 Vinicius Jorge Vendramini
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

// gryphon output: Bootstrap/MutableListTest.kt

#if !GRYPHON
@testable import GryphonLib
import XCTest
#else
import Foundation
#endif

class MutableListTest: XCTestCase {
	// gryphon insert: constructor(): super() { }

	public func getClassName() -> String { // gryphon annotation: override
		return "MutableListTest"
	}

	/// Tests to be run by the translated Kotlin version.
	public func runAllTests() { // gryphon annotation: override
		testEquatable()
		testInits()
		testPassingByReference()
		testCasting()
		testCopy()
		testToList()
		testSubscript()
		testDescription()
		// testDebugDescription()
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
		// testHash()
		testSorted()
		testZip()
	}

	/// Tests to be run when using Swift on Linux
	static var allTests = [ // gryphon ignore
		("testEquatable", testEquatable),
		("testInits", testInits),
		("testPassingByReference", testPassingByReference),
		("testCasting", testCasting),
		("testCopy", testCopy),
		("testToList", testToList),
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
		("testSorted", testSorted),
		("testZip", testZip),
	]

	// MARK: - Tests
	func testEquatable() {
		let list1: MutableList = [1, 2, 3]
		let list2: MutableList = [1, 2, 3]
		let list3: MutableList = [4, 5, 6]

		XCTAssert(list1 == list2)
		XCTAssertFalse(list2 == list3)
	}

	func testInits() {
		let list1: MutableList = [1, 2, 3]
		let list2: MutableList = MutableList<Int>([1, 2, 3])
		let list3: MutableList = MutableList(list1) // gryphon ignore
		let sequence = AnySequence([1, 2, 3]) // gryphon ignore
		let list4: MutableList = MutableList<Int>(sequence) // gryphon ignore
		let list5: MutableList = MutableList<Int>()
		let list6: MutableList<Int> = []

		XCTAssertEqual(list1, list2)
		XCTAssertEqual(list1, list3) // gryphon ignore
		XCTAssertEqual(list1, list4) // gryphon ignore
		XCTAssertEqual(list5, list6)

		list1.append(4)
		list5.append(4)

		XCTAssertNotEqual(list1, list2)
		XCTAssertNotEqual(list1, list3) // gryphon ignore
		XCTAssertNotEqual(list1, list4) // gryphon ignore
		XCTAssertNotEqual(list5, list6)
		XCTAssertEqual(list2, [1, 2, 3])
		XCTAssertEqual(list2, list3) // gryphon ignore
		XCTAssertEqual(list2, list4) // gryphon ignore
	}

	func testPassingByReference() {
		let list1: MutableList = [1, 2, 3]
		let list2 = list1
		list1[0] = 10
		XCTAssertEqual(list1, list2)
	}

	func testCasting() {
		let listOfAnys: List<Any> = [1, 2, 3]
		let mutableListOfAnys: MutableList<Any> = [1, 2, 3]

		let downcastLM: MutableList<Int>? = listOfAnys.as(MutableList<Int>.self)
		let downcastML: List<Int>? = mutableListOfAnys.as(List<Int>.self)
		let downcastMM: MutableList<Int>? = mutableListOfAnys.as(MutableList<Int>.self)
		XCTAssertEqual(downcastLM, [1, 2, 3])
		XCTAssertEqual(downcastML, [1, 2, 3])
		XCTAssertEqual(downcastMM, [1, 2, 3])

		let failedLM: MutableList<String>? = listOfAnys.as(MutableList<String>.self)
		let failedML: List<String>? = mutableListOfAnys.as(List<String>.self)
		let failedMM: MutableList<String>? = mutableListOfAnys.as(MutableList<String>.self)
		XCTAssertNil(failedLM)
		XCTAssertNil(failedML)
		XCTAssertNil(failedMM)

		let optionalLM: MutableList<Int?>? = listOfAnys.as(MutableList<Int?>.self)
		let optionalML: List<Int?>? = mutableListOfAnys.as(List<Int?>.self)
		let optionalMM: MutableList<Int?>? = mutableListOfAnys.as(MutableList<Int?>.self)
		XCTAssertEqual(optionalLM, [1, 2, 3])
		XCTAssertEqual(optionalML, [1, 2, 3])
		XCTAssertEqual(optionalMM, [1, 2, 3])
	}

	func testCopy() {
		let list1: MutableList = [1, 2, 3]
		let list2 = list1.toMutableList()
		list1[0] = 10
		XCTAssertNotEqual(list1, list2)
	}

	func testToList() {
		let list1: MutableList = [1, 2, 3]
		let list2: MutableList = [1, 2, 3, 4]
		let list = list1.toList()

		XCTAssert(list1 == list)
		XCTAssert(list == list1)
		XCTAssert(list2 != list)
		XCTAssert(list != list2)
	}

	func testSubscript() {
		let list1: MutableList = [1, 2, 3]
		let list2: MutableList = [10, 2, 3]
		list1[0] = 10

		XCTAssertEqual(list1, list2)

		XCTAssertEqual(list1[0], 10)
		XCTAssertEqual(list1[1], 2)
		XCTAssertEqual(list1[2], 3)
	}

	func testDescription() {
		let list: MutableList = [1, 2, 3]

		XCTAssert(list.description.contains("1"))
		XCTAssert(list.description.contains("2"))
		XCTAssert(list.description.contains("3"))
		XCTAssert(!list.description.contains("4"))
	}

	func testDebugDescription() { // gryphon ignore
		let list: MutableList = [1, 2, 3]

		XCTAssert(list.debugDescription.contains("1"))
		XCTAssert(list.debugDescription.contains("2"))
		XCTAssert(list.debugDescription.contains("3"))
		XCTAssert(!list.debugDescription.contains("4"))
	}

	func testCollectionIndices() {
		let list: MutableList = [1, 2, 3]
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
		let list: MutableList = [1, 2, 3]
		let emptyArray: MutableList<Int> = []

		XCTAssert(!list.isEmpty)
		XCTAssert(emptyArray.isEmpty)
	}

	func testFirst() {
		let list: MutableList = [1, 2, 3]
		let emptyArray: MutableList<Int> = []

		XCTAssertEqual(list.first, 1)
		XCTAssertEqual(emptyArray.first, nil)
	}

	func testLast() {
		let list: MutableList = [1, 2, 3]
		let emptyArray: MutableList<Int> = []

		XCTAssertEqual(list.last, 3)
		XCTAssertEqual(emptyArray.last, nil)
	}

	func testIndexBefore() {
		let list: MutableList = [1, 2, 3]
		let lastIndex = list.index(before: list.endIndex)

		XCTAssertEqual(list[lastIndex], 3)
	}

	func testAppendContentsOf() {
		let list1: MutableList = [1, 2, 3]
		let list2: MutableList = [4, 5, 6]

		list1.append(contentsOf: list2)
		XCTAssertEqual(list1, [1, 2, 3, 4, 5, 6])
	}

	func testAppend() {
		let list1: MutableList = [1, 2, 3]
		list1.append(4)
		XCTAssertEqual(list1, [1, 2, 3, 4])
	}

	func testAppending() {
		let list1: MutableList = [1, 2, 3]
		let list2 = list1.appending(4)
		XCTAssertEqual(list2, [1, 2, 3, 4])
		XCTAssertEqual(list1, [1, 2, 3])
	}

	func testInsert() {
		let list1: MutableList = [1, 2, 3]

		list1.insert(0, at: 0)
		XCTAssertEqual(list1, [0, 1, 2, 3])

		list1.insert(10, at: 2)
		XCTAssertEqual(list1, [0, 1, 10, 2, 3])

		list1.insert(10, at: 5)
		XCTAssertEqual(list1, [0, 1, 10, 2, 3, 10])
	}

	func testFilter() {
		let list1: MutableList = [1, 2, 3]
		let list2 = list1.filter { $0 > 1 }
		XCTAssertEqual(list1, [1, 2, 3])
		XCTAssertEqual(list2, [2, 3])
	}

	func testMap() {
		let list1: MutableList = [1, 2, 3]
		let list2 = list1.map { $0 * 2 }
		XCTAssertEqual(list1, [1, 2, 3])
		XCTAssertEqual(list2, [2, 4, 6])
	}

	func testCompactMap() {
		let list1: MutableList = [1, 2, 3]
		let list2 = list1.compactMap { (e: Int) -> Int? in (e == 2) ? e : nil }
		XCTAssertEqual(list1, [1, 2, 3])
		XCTAssertEqual(list2, [2])
	}

	func testFlatMap() {
		let list1: MutableList = [1, 2, 3]
		let list2 = list1.flatMap { MutableList<Int>([$0, 10 * $0]) }
		XCTAssertEqual(list1, [1, 2, 3])
		XCTAssertEqual(list2, [1, 10, 2, 20, 3, 30])
	}

	func testSortedBy() {
		let list1: MutableList = [3, 1, 2]
		let list2: MutableList = [1, 2, 3]
		let sortedArray1 = list1.sorted { a, b in a < b }
		let sortedArray2 = list2.sorted { a, b in a < b }
		let sortedArray2Descending = list2.sorted { a, b in a > b }

		XCTAssertEqual(sortedArray1, [1, 2, 3])
		XCTAssertEqual(list1, [3, 1, 2])
		XCTAssertEqual(sortedArray2, [1, 2, 3])
		XCTAssertEqual(sortedArray2Descending, [3, 2, 1])
	}

	func testAppendingContentsOf() {
		let list1: MutableList = [1, 2, 3]
		let list2: MutableList = [4, 5, 6]
		let list3: MutableList = [7, 8, 9]

		XCTAssertEqual(list1.appending(contentsOf: list2), [1, 2, 3, 4, 5, 6])
		XCTAssertEqual(list1, [1, 2, 3])
		XCTAssertEqual(list2, [4, 5, 6])

		XCTAssertEqual(list1.appending(contentsOf: list3), [1, 2, 3, 7, 8, 9])
		XCTAssertEqual(list1, [1, 2, 3])
		XCTAssertEqual(list3, [7, 8, 9])
	}

	func testRemoveFirst() {
		let list: MutableList = [1, 2, 3]
		list.removeFirst()

		XCTAssertEqual(list, [2, 3])
	}

	func testRemoveLast() {
		let list: MutableList = [1, 2, 3]
		list.removeLast()

		XCTAssertEqual(list, [1, 2])
	}

	func testReverse() {
		let list: MutableList = [1, 2, 3]
		list.reverse()

		XCTAssertEqual(list, [3, 2, 1])
	}

	func testIndices() {
		let list: MutableList = [1, 2, 3]
		XCTAssertEqual(list.indices, 0..<3)
	}

	func testIndexOfElement() {
		let list: MutableList = [1, 2, 10]
		XCTAssertEqual(list.firstIndex(of: 1), 0)
		XCTAssertEqual(list.firstIndex(of: 2), 1)
		XCTAssertEqual(list.firstIndex(of: 10), 2)
	}

	func testHash() { // gryphon ignore
		let list1: MutableList = [1, 2, 3]
		let list2: MutableList = [1, 2, 3]
		let list3: MutableList = [1, 2, 3, 4]
		let hash1 = list1.hashValue
		let hash2 = list2.hashValue
		let hash3 = list3.hashValue

		XCTAssertEqual(hash1, hash2)
		XCTAssertNotEqual(hash1, hash3)
		XCTAssertNotEqual(hash2, hash3)
	}

	func testSorted() {
		let list1: MutableList = [3, 2, 1]
		let list2: MutableList = [1, 2, 3]

		XCTAssertEqual(list1.sorted(), MutableList<Int>([1, 2, 3]))
		XCTAssertEqual(list1, [3, 2, 1])
		XCTAssertEqual(list2.sorted(), MutableList<Int>([1, 2, 3]))
	}

	func testZip() {
		let array1: [Int] = [3, 2, 1] // gryphon mute
		let array2: [Int] = [1, 2, 3] // gryphon mute
		let list1: MutableList = [3, 2, 1]
		let list2: MutableList = [1, 2, 3]

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
		let list2: MutableList = [4, 5, 6]
		let list3: MutableList = [7, 8, 9]

		XCTAssertEqual(list1 + list2, [1, 2, 3, 4, 5, 6])
		XCTAssertEqual(list1, [1, 2, 3])
		XCTAssertEqual(list2, [4, 5, 6])

		XCTAssertEqual(list2 + list1, [4, 5, 6, 1, 2, 3])
		XCTAssertEqual(list1, [1, 2, 3])
		XCTAssertEqual(list2, [4, 5, 6])

		XCTAssertEqual(list2 + list3, [4, 5, 6, 7, 8, 9])
		XCTAssertEqual(list2, [4, 5, 6])
		XCTAssertEqual(list3, [7, 8, 9])
	}
}
