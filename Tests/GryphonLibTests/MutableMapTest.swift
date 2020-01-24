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

class MutableMapTest: XCTestCase {

	func testEquatable() {
		let dictionary1: MutableMap = [1: 10, 2: 20]
		let dictionary2: MutableMap = [1: 10, 2: 20]
		let dictionary3: MutableMap = [3: 30, 4: 40]

		XCTAssert(dictionary1 == dictionary2)
		XCTAssertFalse(dictionary2 == dictionary3)
	}

	func testInits() {
		let dictionary1: MutableMap = [1: 10, 2: 20]
		let dictionary2: MutableMap = MutableMap([1: 10, 2: 20])
		let dictionary3: MutableMap = MutableMap<Int, Int>(dictionary1)
		let dictionary4: MutableMap<Int, Int> = MutableMap()
		let dictionary5: MutableMap<Int, Int> = [:]

		XCTAssertEqual(dictionary1, dictionary2)
		XCTAssertEqual(dictionary1, dictionary3)
		XCTAssertEqual(dictionary4, dictionary5)

		dictionary1[3] = 30
		dictionary4[3] = 30

		XCTAssertNotEqual(dictionary1, dictionary2)
		XCTAssertNotEqual(dictionary1, dictionary3)
		XCTAssertNotEqual(dictionary4, dictionary5)
		XCTAssertEqual(dictionary2, dictionary3)
	}

	func testPassingByReference() {
		let dictionary1: MutableMap = [1: 10, 2: 20]
		let dictionary2 = dictionary1
		dictionary1[3] = 30
		XCTAssertEqual(dictionary1, dictionary2)
	}

	func testCasting() {
		let dictionary1: MutableMap<Int, Any> = [1: 10, 2: 20]

		let failedCast: MutableMap<Int, String>? =
			dictionary1.as(MutableMap<Int, String>.self)
		let successfulCast: MutableMap<Int, Int>? =
			dictionary1.as(MutableMap<Int, Int>.self)

		XCTAssertNil(failedCast)
		XCTAssertNotNil(successfulCast)
		XCTAssertEqual(successfulCast, [1: 10, 2: 20])
	}

	func testCopy() {
		let dictionary1: MutableMap = [1: 10, 2: 20]
		let dictionary2 = dictionary1.toMutableMap()
		dictionary1[3] = 30
		XCTAssertNotEqual(dictionary1, dictionary2)
	}

	func testToFixedDictionary() {
		let dictionary1: MutableMap = [1: 10, 2: 20]
		let dictionary2: MutableMap = [1: 10, 2: 20, 3: 30]
		let fixedDictionary: Map = dictionary1.toMap()

		XCTAssert(dictionary1 == fixedDictionary)
		XCTAssert(fixedDictionary == dictionary1)
		XCTAssert(dictionary2 != fixedDictionary)
		XCTAssert(fixedDictionary != dictionary2)
	}

	func testSubscript() {
		let dictionary1: MutableMap = [1: 10, 2: 20]
		let dictionary2: MutableMap = [1: 100, 2: 20]
		dictionary1[1] = 100

		XCTAssertEqual(dictionary1, dictionary2)

		XCTAssertEqual(dictionary1[1], 100)
		XCTAssertEqual(dictionary1[2], 20)
	}

	func testDescription() {
		let dictionary: MutableMap = [1: 10, 2: 20]

		XCTAssert(dictionary.description.contains("1"))
		XCTAssert(dictionary.description.contains("10"))
		XCTAssert(dictionary.description.contains("2"))
		XCTAssert(dictionary.description.contains("20"))
		XCTAssert(!dictionary.description.contains("3"))
	}

	func testDebugDescription() {
		let dictionary: MutableMap = [1: 10, 2: 20]

		XCTAssert(dictionary.debugDescription.contains("1"))
		XCTAssert(dictionary.debugDescription.contains("10"))
		XCTAssert(dictionary.debugDescription.contains("2"))
		XCTAssert(dictionary.debugDescription.contains("20"))
		XCTAssert(!dictionary.debugDescription.contains("3"))
	}

	func testCollectionIndices() {
		let dictionary: MutableMap = [1: 10, 2: 20]
		let lastIndex = dictionary.index(after: dictionary.startIndex)

		// startIndex and indexAfter
		let key1 = dictionary[dictionary.startIndex].0
		let key2 = dictionary[lastIndex].0
		let value1 = dictionary[dictionary.startIndex].1
		let value2 = dictionary[lastIndex].1

		XCTAssert((key1 == 1 && key2 == 2) || (key1 == 2 && key2 == 1))
		XCTAssert((value1 == 10 && value2 == 20) || (value1 == 20 && value2 == 10))

		// endIndex
		let endIndex = dictionary.index(after: lastIndex)
		XCTAssertEqual(endIndex, dictionary.endIndex)

		// formIndex
		var index = dictionary.startIndex
		dictionary.formIndex(after: &index)
		XCTAssertEqual(index, lastIndex)
	}

	func testCount() {
		let dictionary1: MutableMap<Int, Int> = [:]
		let dictionary2: MutableMap = [1: 10]
		let dictionary3: MutableMap = [1: 10, 2: 20]
		let dictionary4: MutableMap = [1: 10, 2: 20, 3: 30]

		XCTAssertEqual(dictionary1.count, 0)
		XCTAssertEqual(dictionary2.count, 1)
		XCTAssertEqual(dictionary3.count, 2)
		XCTAssertEqual(dictionary4.count, 3)
	}

	func testIsEmpty() {
		let dictionary: MutableMap = [1: 10, 2: 20]
		let emptyDictionary: MutableMap<Int, Int> = [:]

		XCTAssert(!dictionary.isEmpty)
		XCTAssert(emptyDictionary.isEmpty)
	}

	func testMap() {
		let dictionary: MutableMap = [1: 10, 2: 20]
		let mappedDictionary = dictionary.map { $0.0 + $0.1 }

		let answer1: MutableList = [11, 22]
		let answer2: MutableList = [22, 11]
		XCTAssert((mappedDictionary == answer1) || (mappedDictionary == answer2))

		XCTAssertEqual(dictionary, [1: 10, 2: 20])
	}

	func testMapValues() {
		let dictionary: MutableMap = [1: 10, 2: 20]
		let mappedDictionary = dictionary.mapValues { $0 * 10 }

		XCTAssertEqual(mappedDictionary, [1: 100, 2: 200])
		XCTAssertEqual(dictionary, [1: 10, 2: 20])
	}

	func testSortedBy() {
		let dictionary: MutableMap = [1: 20, 2: 10]

		let keySorted = dictionary.sorted { $0.0 < $1.0 }
		let keySortedKeys = keySorted.map { $0.0 }
		let keySortedValues = keySorted.map { $0.1 }

		let valueSorted = dictionary.sorted { $0.1 < $1.1 }
		let valueSortedKeys = valueSorted.map { $0.0 }
		let valueSortedValues = valueSorted.map { $0.1 }

		let reverseSorted = dictionary.sorted { $0.0 > $1.0 }
		let reverseSortedKeys = reverseSorted.map { $0.0 }
		let reverseSortedValues = reverseSorted.map { $0.1 }

		XCTAssertEqual(keySortedKeys, [1, 2])
		XCTAssertEqual(keySortedValues, [20, 10])
		XCTAssertEqual(valueSortedKeys, [2, 1])
		XCTAssertEqual(valueSortedValues, [10, 20])
		XCTAssertEqual(reverseSortedKeys, [2, 1])
		XCTAssertEqual(reverseSortedValues, [10, 20])

		XCTAssertEqual(dictionary, [1: 20, 2: 10])
	}

	func testHash() {
		let dictionary1: MutableMap = [1: 20, 2: 10]
		let dictionary2: MutableMap = [1: 20, 2: 10]
		let dictionary3: MutableMap = [1: 20, 2: 10, 3: 30]
		let hash1 = dictionary1.hashValue
		let hash2 = dictionary2.hashValue
		let hash3 = dictionary3.hashValue

		XCTAssertEqual(hash1, hash2)
		XCTAssertNotEqual(hash1, hash3)
		XCTAssertNotEqual(hash2, hash3)
	}

	static var allTests = [
		("testEquatable", testEquatable),
		("testInits", testInits),
		("testPassingByReference", testPassingByReference),
		("testCasting", testCasting),
		("testCopy", testCopy),
		("testToFixedDictionary", testToFixedDictionary),
		("testSubscript", testSubscript),
		("testDescription", testDescription),
		("testDebugDescription", testDebugDescription),
		("testCollectionIndices", testCollectionIndices),
		("testCount", testCount),
		("testIsEmpty", testIsEmpty),
		("testMap", testMap),
		("testMapValues", testMapValues),
		("testSortedBy", testSortedBy),
		("testHash", testHash),
		]
}
