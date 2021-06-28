//
// Copyright 2018 Vinicius Jorge Vendramini
//
// Licensed under the Hippocratic License, Version 2.1;
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://firstdonoharm.dev/version/2/1/license
//
// To the full extent allowed by law, this software comes "AS IS,"
// WITHOUT ANY WARRANTY, EXPRESS OR IMPLIED, and licensor and any other
// contributor shall not be liable to anyone for any damages or other
// liability arising from, out of, or in connection with the sotfware
// or this license, under any kind of legal claim.
// See the License for the specific language governing permissions and
// limitations under the License.
//

@testable import GryphonLib
import XCTest

class SortedListTest: XCTestCase {
	/// Tests to be run when using Swift on Linux
	static var allTests = [
		("testInit", testInit),
		("testListInit", testListInit),
		("testSearch", testSearch),
		("testInitComparable", testInitComparable),
		("testSearchComparable", testSearchComparable),
	]

	// MARK: - Tests
	func testInit() {
		let sortedList1 = SortedList([3, 2, 1]) { $0 < $1 }
		let sortedList2 = SortedList([1, 2, 3]) { $0 > $1 }

		XCTAssertEqual(sortedList1, List([1, 2, 3]))
		XCTAssertEqual(sortedList2, List([3, 2, 1]))
	}

	func testListInit() {
		let sortedList1 = SortedList(List([3, 2, 1])) { $0 < $1 }
		let sortedList2 = SortedList(List([1, 2, 3])) { $0 > $1 }

		XCTAssertEqual(sortedList1, List([1, 2, 3]))
		XCTAssertEqual(sortedList2, List([3, 2, 1]))
	}

	func testSearch() {
		let sortedList1 = SortedList(List([3, 2, 1])) { $0 < $1 }
		XCTAssertEqual(sortedList1.search(predicate: makePredicate(toSearchFor: 1)), 1)
		XCTAssertEqual(sortedList1.search(predicate: makePredicate(toSearchFor: 2)), 2)
		XCTAssertEqual(sortedList1.search(predicate: makePredicate(toSearchFor: 3)), 3)
		XCTAssertEqual(sortedList1.search(predicate: makePredicate(toSearchFor: 4)), nil)
	}

	func makePredicate(toSearchFor searchedElement: Int) -> ((Int) -> ComparisonResult) {
		return { (element: Int) -> ComparisonResult in
			if element < searchedElement {
				return .orderedAscending
			}
			else if element > searchedElement {
				return .orderedDescending
			}
			else {
				return .orderedSame
			}
		}
	}

	func testInitComparable() {
		let sortedList1 = SortedList(of: [3, 2, 1])
		XCTAssertEqual(sortedList1, List([1, 2, 3]))
	}

	func testSearchComparable() {
		let sortedList1 = SortedList(of: [3, 2, 1])
		XCTAssertEqual(sortedList1.search(for: 1), 1)
		XCTAssertEqual(sortedList1.search(for: 2), 2)
		XCTAssertEqual(sortedList1.search(for: 3), 3)
		XCTAssertEqual(sortedList1.search(for: 4), nil)
	}
}
