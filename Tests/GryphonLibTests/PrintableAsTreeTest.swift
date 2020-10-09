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

// gryphon output: Bootstrap/PrintableAsTreeTest.kt

#if !GRYPHON
@testable import GryphonLib
import XCTest
#endif

class PrintableAsTreeTest: XCTestCase {
	// gryphon insert: constructor(): super() { }

	// gryphon annotation: override
	public func getClassName() -> String {
		return "PrintableAsTreeTest"
	}

	/// Tests to be run by the translated Kotlin version.
	// gryphon annotation: override
	public func runAllTests() {
		testPrinting()
		testHorizontalLimit()
		testInitOrNil()
	}

	/// Tests to be run when using Swift on Linux
	// gryphon ignore
	static var allTests = [
		("testPrinting", testPrinting),
		("testHorizontalLimit", testHorizontalLimit),
		("testInitOrNil", testInitOrNil),
	]

	// MARK: - Tests
	func testPrinting() {
		let root = PrintableTree(
			"root", [
			PrintableTree(
				"a",
				[PrintableTree(
					"b",
					[PrintableTree(
						"c"), ]), ]),
			PrintableTree(
				"d"), ])

		XCTAssertEqual(root.prettyDescription(), """
			 root
			 ├─ a
			 │  └─ b
			 │     └─ c
			 └─ d\n
			""")
	}

	func testHorizontalLimit() {
		let root = PrintableTree(
		"root", [
		PrintableTree(
			"aaaaaaaaaaaaaaaaaa",
			[PrintableTree(
				"bbbbbbbbbbbbbbbbbb",
				[PrintableTree(
					"cccccccccccccccccc"), ]), ]),
		PrintableTree(
			"dddddddddddddddddd"), ])

		let oldHorizontalLimit = printableAsTreeHorizontalLimit
		printableAsTreeHorizontalLimit = 15

		XCTAssertEqual(root.prettyDescription(), """
			 root
			 ├─ aaaaaaaaaa…
			 │  └─ bbbbbbb…
			 │     └─ cccc…
			 └─ dddddddddd…\n
			""")

		printableAsTreeHorizontalLimit = oldHorizontalLimit
	}

    func testInitOrNil() {
        let subtree: PrintableAsTree? = PrintableTree("")

        let noDescription: PrintableAsTree? = PrintableTree.initOrNil(nil)
        let noChildren: PrintableAsTree? = PrintableTree.initOrNil("", [nil])
        let okTree: PrintableAsTree? = PrintableTree.initOrNil("", [subtree])

        XCTAssertNil(noDescription)
        XCTAssertNil(noChildren)
        XCTAssertNotNil(okTree)
    }
}
