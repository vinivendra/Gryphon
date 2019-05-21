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

class ArrayClassTest: XCTestCase {
	func testReference() {
		let array1: ArrayClass = [1, 2, 3]
		let array2 = array1
		array1[0] = 10
		XCTAssertEqual(array1, array2)
	}

	func testCopy() {
		let array1: ArrayClass = [1, 2, 3]
		let array2 = array1.copy()
		array1[0] = 10
		XCTAssertNotEqual(array1, array2)
	}

	func testAppend() {
		let array1: ArrayClass = [1, 2, 3]
		array1.append(4)
		XCTAssertEqual(array1, [1, 2, 3, 4])
	}

	func testFilter() {
		var array1: ArrayClass = [1, 2, 3]
		array1 = array1.filter { $0 > 1 }
		XCTAssertEqual(array1, [2, 3])
	}

	func testMap() {
		var array1: ArrayClass = [1, 2, 3]
		array1 = array1.map { $0 * 2 }
		XCTAssertEqual(array1, [2, 4, 6])
	}

	func testEquatable() {
		let array1: ArrayClass = [1, 2, 3]
		let array2: ArrayClass = [1, 2, 3]
		let array3: ArrayClass = [4, 5, 6]

		XCTAssert(array1 == array2)
		XCTAssertFalse(array2 == array3)
	}

	func testAppendingContentsOf() {
		let arrayRef1: ArrayClass = [1, 2, 3]
		let arrayRef2: ArrayClass = [4, 5, 6]
		let array: ArrayClass<Int> = [7, 8, 9]

		XCTAssertEqual(arrayRef1.appending(contentsOf: arrayRef2), [1, 2, 3, 4, 5, 6])
		XCTAssertEqual(arrayRef1, [1, 2, 3])
		XCTAssertEqual(arrayRef2, [4, 5, 6])

		XCTAssertEqual(arrayRef1.appending(contentsOf: array), [1, 2, 3, 7, 8, 9])
		XCTAssertEqual(arrayRef1, [1, 2, 3])
		XCTAssertEqual(array, [7, 8, 9])
	}

	func testAppending() {
		let array1: ArrayClass = [1, 2, 3]
		XCTAssertEqual(array1.appending(4), [1, 2, 3, 4])
		XCTAssertEqual(array1, [1, 2, 3])
	}

	static var allTests = [
		("testReference", testReference),
		("testCopy", testCopy),
		("testAppend", testAppend),
		("testFilter", testFilter),
		("testMap", testMap),
		("testEquatable", testEquatable),
		("testAppendingContentsOf", testAppendingContentsOf),
		("testAppending", testAppending),
		]
}
