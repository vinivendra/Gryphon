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

// gryphon output: Bootstrap/PrintableAsTreeTest.kt

#if !GRYPHON
@testable import GryphonLib
import XCTest
#endif

class PrintableAsTreeTest: XCTestCase {
	// insert: constructor(): super() { }

	public func getClassName() -> String { // annotation: override
		return "PrintableAsTreeTest"
	}

	/// Tests to be run by the translated Kotlin version.
	public func runAllTests() { // annotation: override
		testPrinting()
		testHorizontalLimit()
		testInitOrNil()
	}

	/// Tests to be run when using Swift on Linux
	static var allTests = [ // ignore: ignore
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

		var result = ""
		root.prettyPrint {
			result += $0
		}
		XCTAssertEqual(result, """
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

		var result = ""
		root.prettyPrint(horizontalLimit: 15) {
			result += $0
		}
		XCTAssertEqual(result, """
			 root
			 ├─ aaaaaaaaaa…
			 │  └─ bbbbbbb…
			 │     └─ cccc…
			 └─ dddddddddd…\n
			""")
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
