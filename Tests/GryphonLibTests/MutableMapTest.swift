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

class MutableMapTest: XCTestCase {
	public func getClassName() -> String {
		return "MutableMapTest"
	}

	/// Tests to be run by the translated Kotlin version.
	public func runAllTests() {
		testEquatable()
		testInits()
		testPassingByReference()
		testCasting()
		testCopy()
		testToMap()
		testSubscript()
		testDescription()
		// testDebugDescription()
		// testCollectionIndices()
		testCount()
		testIsEmpty()
		testMap()
		// testMapValues()
		// testSortedBy()
		// testHash()
	}

	/// Tests to be run when using Swift on Linux
	static var allTests = [ // gryphon ignore
		("testEquatable", testEquatable),
		("testInits", testInits),
		("testPassingByReference", testPassingByReference),
		("testCasting", testCasting),
		("testCopy", testCopy),
		("testToMap", testToMap),
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

	// MARK: - Tests
	func testEquatable() {
		let dictionary1: MutableMap = [1: 10, 2: 20]
		let dictionary2: MutableMap = [1: 10, 2: 20]
		let dictionary3: MutableMap = [3: 30, 4: 40]

		XCTAssert(dictionary1 == dictionary2)
		XCTAssertFalse(dictionary2 == dictionary3)
	}

	func testInits() {
		let dictionary1: MutableMap<Int, Int> = [1: 10, 2: 20]
		let dictionary2: MutableMap<Int, Int> = MutableMap<Int, Int>([1: 10, 2: 20])
		let dictionary4: MutableMap<Int, Int> = MutableMap<Int, Int>()
		let dictionary5: MutableMap<Int, Int> = [:]

		XCTAssertEqual(dictionary1, dictionary2)
		XCTAssertEqual(dictionary4, dictionary5)

		dictionary1[3] = 30
		dictionary4[3] = 30

		XCTAssertNotEqual(dictionary1, dictionary2)
		XCTAssertNotEqual(dictionary4, dictionary5)
	}

	func testPassingByReference() {
		let dictionary1: MutableMap = [1: 10, 2: 20]
		let dictionary2 = dictionary1
		dictionary1[3] = 30
		XCTAssertEqual(dictionary1, dictionary2)
	}

	func testCasting() {
		let mapOfAnys: Map<AnyHashable, AnyHashable> = [1: "1", 2: "2"]
		let mutableMapOfAnys: MutableMap<AnyHashable, AnyHashable> = [1: "1", 2: "2"]
		let mapOfDifferentTypes: Map<AnyHashable, AnyHashable> = [1: "1", "2": 2]
		let mutableMapOfDifferentTypes: MutableMap<AnyHashable, AnyHashable> = [1: "1", "2": 2]

		// Downcasts succeed
		let downcastMapIM: MutableMap<Int, String>? =
			mapOfAnys.as(MutableMap<Int, String>.self)
		let downcastMapMI: Map<Int, String>? =
			mutableMapOfAnys.as(Map<Int, String>.self)
		let downcastMapMM: MutableMap<Int, String>? =
			mutableMapOfAnys.as(MutableMap<Int, String>.self)
		XCTAssertEqual(downcastMapIM, [1: "1", 2: "2"])
		XCTAssertEqual(downcastMapMI, [1: "1", 2: "2"])
		XCTAssertEqual(downcastMapMM, [1: "1", 2: "2"])

		// Casts to unrelated types fail
		let failedMapIM1: MutableMap<String, Int>? =
			mapOfAnys.as(MutableMap<String, Int>.self)
		let failedMapMI1: Map<String, Int>? =
			mutableMapOfAnys.as(Map<String, Int>.self)
		let failedMapMM1: MutableMap<String, Int>? =
			mutableMapOfAnys.as(MutableMap<String, Int>.self)
		XCTAssertNil(failedMapIM1)
		XCTAssertNil(failedMapMI1)
		XCTAssertNil(failedMapMM1)

		// Compatible casts succeed even if types are optional
		let optionalMapIM: MutableMap<Int?, String?>? =
			mapOfAnys.as(MutableMap<Int?, String?>.self)
		let optionalMapMI: Map<Int?, String?>? =
			mutableMapOfAnys.as(Map<Int?, String?>.self)
		let optionalMapMM: MutableMap<Int?, String?>? =
			mutableMapOfAnys.as(MutableMap<Int?, String?>.self)
		XCTAssertEqual(optionalMapIM, [1: "1", 2: "2"])
		XCTAssertEqual(optionalMapMI, [1: "1", 2: "2"])
		XCTAssertEqual(optionalMapMM, [1: "1", 2: "2"])

		// Incompatible casts fail even if types are optional
		let failedMapIM2: MutableMap<String?, Int?>? =
			mapOfAnys.as(MutableMap<String?, Int?>.self)
		let failedMapMI2: Map<String?, Int?>? =
			mutableMapOfAnys.as(Map<String?, Int?>.self)
		let failedMapMM2: MutableMap<String?, Int?>? =
			mutableMapOfAnys.as(MutableMap<String?, Int?>.self)
		XCTAssertNil(failedMapIM2)
		XCTAssertNil(failedMapMI2)
		XCTAssertNil(failedMapMM2)

		// Casts fail unless all elements match the casted type
		let failedMapIM3: MutableMap<String, Int>? =
			mapOfDifferentTypes.as(MutableMap<String, Int>.self)
		let failedMapMI3: Map<String, Int>? =
			mutableMapOfDifferentTypes.as(Map<String, Int>.self)
		let failedMapMM3: MutableMap<String, Int>? =
			mutableMapOfDifferentTypes.as(MutableMap<String, Int>.self)
		let failedMapIM4: MutableMap<Int, String>? =
			mapOfDifferentTypes.as(MutableMap<Int, String>.self)
		let failedMapMI4: Map<Int, String>? =
			mutableMapOfDifferentTypes.as(Map<Int, String>.self)
		let failedMapMM4: MutableMap<Int, String>? =
			mutableMapOfDifferentTypes.as(MutableMap<Int, String>.self)
		XCTAssertNil(failedMapIM3)
		XCTAssertNil(failedMapMI3)
		XCTAssertNil(failedMapMM3)
		XCTAssertNil(failedMapIM4)
		XCTAssertNil(failedMapMI4)
		XCTAssertNil(failedMapMM4)

		// Forced downcasts succeed
		let forcedDowncastMapIM: MutableMap<Int, String> =
			mapOfAnys.forceCast(to: MutableMap<Int, String>.self)
		let forcedDowncastMapMI: Map<Int, String> =
			mutableMapOfAnys.forceCast(to: Map<Int, String>.self)
		let forcedDowncastMapMM: MutableMap<Int, String> =
			mutableMapOfAnys.forceCast(to: MutableMap<Int, String>.self)
		XCTAssertEqual(forcedDowncastMapIM, [1: "1", 2: "2"])
		XCTAssertEqual(forcedDowncastMapMI, [1: "1", 2: "2"])
		XCTAssertEqual(forcedDowncastMapMM, [1: "1", 2: "2"])

		// Compatible forced casts succeed even if types are optional
		let forceOptionalMapIM: MutableMap<Int?, String?> =
			mapOfAnys.forceCast(to: MutableMap<Int?, String?>.self)
		let forceOptionalMapMI: Map<Int?, String?> =
			mutableMapOfAnys.forceCast(to: Map<Int?, String?>.self)
		let forceOptionalMapMM: MutableMap<Int?, String?> =
			mutableMapOfAnys.forceCast(to: MutableMap<Int?, String?>.self)
		XCTAssertEqual(forceOptionalMapIM, [1: "1", 2: "2"])
		XCTAssertEqual(forceOptionalMapMI, [1: "1", 2: "2"])
		XCTAssertEqual(forceOptionalMapMM, [1: "1", 2: "2"])
	}

	func testCopy() {
		let dictionary1: MutableMap = [1: 10, 2: 20]
		let dictionary2 = dictionary1.toMutableMap()
		dictionary1[3] = 30
		XCTAssertNotEqual(dictionary1, dictionary2)
	}

	func testToMap() {
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

	func testDebugDescription() { // gryphon ignore
		let dictionary: MutableMap = [1: 10, 2: 20]

		XCTAssert(dictionary.debugDescription.contains("1"))
		XCTAssert(dictionary.debugDescription.contains("10"))
		XCTAssert(dictionary.debugDescription.contains("2"))
		XCTAssert(dictionary.debugDescription.contains("20"))
		XCTAssert(!dictionary.debugDescription.contains("3"))
	}

	func testCollectionIndices() { // gryphon ignore
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

		let answer1: List = [11, 22]
		let answer2: List = [22, 11]
		XCTAssert((mappedDictionary == answer1) || (mappedDictionary == answer2))

		XCTAssertEqual(dictionary, [1: 10, 2: 20])
	}

	func testMapValues() { // gryphon ignore
		let dictionary: MutableMap = [1: 10, 2: 20]
		let mappedDictionary = dictionary.mapValues { $0 * 10 }

		XCTAssertEqual(mappedDictionary, [1: 100, 2: 200])
		XCTAssertEqual(dictionary, [1: 10, 2: 20])
	}

	func testSortedBy() { // gryphon ignore
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

	func testHash() { // gryphon ignore
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
}
