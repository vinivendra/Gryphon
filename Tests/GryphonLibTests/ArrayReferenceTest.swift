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

class ArrayReferenceTest: XCTestCase {
	func testReference() {
		let array1: ArrayReference = [1, 2, 3]
		let array2 = array1
		array1[0] = 10
		XCTAssertEqual(array1, array2)
	}

	func testCopy() {
		let array1: ArrayReference = [1, 2, 3]
		let array2 = array1.copy()
		array1[0] = 10
		XCTAssertNotEqual(array1, array2)
	}
}
