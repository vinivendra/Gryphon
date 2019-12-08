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

class PrintableAsTreeTest: XCTestCase {
	func testPrinting() {
		let root = PrintableTree("root")
		let a = PrintableTree("a")
		let b = PrintableTree("b")
		let c = PrintableTree("c")
		let d = PrintableTree("d")

		root.addChild(a)
		a.addChild(b)
		b.addChild(c)
		root.addChild(d)

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
		let root = PrintableTree("root")
		let a = PrintableTree("aaaaaaaaaaaaaaaaaa")
		let b = PrintableTree("bbbbbbbbbbbbbbbbbb")
		let c = PrintableTree("cccccccccccccccccc")
		let d = PrintableTree("dddddddddddddddddd")

		root.addChild(a)
		a.addChild(b)
		b.addChild(c)
		root.addChild(d)

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

	static var allTests = [
		("testPrinting", testPrinting),
		("testHorizontalLimit", testHorizontalLimit),
		("testInitOrNil", testInitOrNil),
	]
}
