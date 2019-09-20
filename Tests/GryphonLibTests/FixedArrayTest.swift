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
	func testEquality() {
		let array1: FixedArray = [1, 2, 3]
		let array2: FixedArray = [1, 2, 3]
		let array3: FixedArray = [3, 2, 1]

		XCTAssertEqual(array1, array2)
		XCTAssertNotEqual(array1, array3)
	}

	func testInitializers() {
		// init(_ array:)
		let array1: FixedArray<Int> = FixedArray([1, 2, 3])
		// init(_ fixedArray:)
		let array2 = FixedArray(array1)
		let arrayAny: FixedArray<Any> = FixedArray(array1)
		let array3: FixedArray<Int> = FixedArray(arrayAny)
		// init()
		let array4 = FixedArray<Int>()
		// init(arrayLiteral:)
		let array5: FixedArray<Int> = []
		let array6: FixedArray<Int> = [1, 2, 3]

		XCTAssertEqual(array1, array2)
		XCTAssertEqual(array1, array3)
		XCTAssertEqual(array4, array5)
		XCTAssertEqual(array1, array6)
	}

	func testAsCasting() {
		let array1: FixedArray = [1, 2, 3]
		guard let arrayAny = array1.as(FixedArray<Any>.self) else {
			XCTFail("Int is a subtype of Any, this cast should never fail.")
			return
		}
		let array3 = arrayAny.as(FixedArray<Int>.self)
		let array4 = array1.as(FixedArray<String>.self)

		XCTAssertEqual(array1, array3)
		XCTAssertEqual(array4, nil)
	}

	func testSubscript() {
		let array1: FixedArray = [1, 2, 3]

		XCTAssertEqual(array1[0], 1)
		XCTAssertEqual(array1[1], 2)
		XCTAssertEqual(array1[2], 3)
	}

	func testCollection() {
		let array: FixedArray = [1, 2, 3]
		let emptyArray: FixedArray<Int> = []

		var i = 1
		for item in array {
			XCTAssertEqual(item, i)
			i += 1
		}

		XCTAssertFalse(array.isEmpty)
		XCTAssert(emptyArray.isEmpty)

		XCTAssertEqual(array.first, 1)
		XCTAssertEqual(emptyArray.first, nil)

		XCTAssertEqual(array.last, 3)
		XCTAssertEqual(emptyArray.last, nil)
	}

	func testFunctionalMethods() {
		let array: FixedArray = [1, 2, 3]
		let appendedArray = array.appending(4)
		let filteredArray = array.filter { $0 > 2 }
		let mappedArray = array.map { "\($0)" }
		let compactMappedArray = array.compactMap { ($0 > 2) ? $0 : nil }
		let flatMappedArray = array.flatMap { [$0, $0 + 1] }

		XCTAssertEqual(appendedArray, [1, 2, 3, 4])
		XCTAssertEqual(filteredArray, [3])
		XCTAssertEqual(mappedArray, ["1", "2", "3"])
		XCTAssertEqual(compactMappedArray, [3])
		XCTAssertEqual(flatMappedArray, [1, 2, 2, 3, 3, 4])
	}

	func testSorting() {
		let array: FixedArray = [2, 3, 1]

		XCTAssertEqual(array.sorted(by: >), [3, 2, 1])
		XCTAssertEqual(array.sorted(), [1, 2, 3])
	}

	func testSequences() {
		let array = [1, 2, 3]
		let fixedArray1 = FixedArray(array)
		let fixedArray2 = fixedArray1.appending(contentsOf: array)

		XCTAssertEqual(fixedArray1, [1, 2, 3])
		XCTAssertEqual(fixedArray2, [1, 2, 3, 1, 2, 3])
	}

	func testReversed() {
		let array: FixedArray = [1, 2, 3]

		XCTAssertEqual(array.reversed(), [3, 2, 1])
	}

	func testIndices() {
		let array: FixedArray = [1, 2, 3]

		var i = 0
		for index in array.indices {
			XCTAssertEqual(index, i)
			i += 1
		}
	}

	func testIndexOf() {
		let array: FixedArray = [1, 2, 3]

		XCTAssertEqual(array.index(of: 1), 0)
		XCTAssertEqual(array.index(of: 2), 1)
		XCTAssertEqual(array.index(of: 3), 2)
		XCTAssertEqual(array.index(of: 4), nil)
	}

	static var allTests = [
		("testEquality", testEquality),
		("testInitializers", testInitializers),
		("testAsCasting", testAsCasting),
		("testSubscript", testSubscript),
		("testCollection", testCollection),
		("testFunctionalMethods", testFunctionalMethods),
		("testSorting", testSorting),
		("testSequences", testSequences),
		("testReversed", testReversed),
		("testIndices", testIndices),
		("testIndexOf", testIndexOf),
	]
}
