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

class PrintableAsTreeTest(): XCTestCase() {
	override fun getClassName(): String {
		return "PrintableAsTreeTest"
	}
	
	override fun runAllTests() {
		testPrinting()
		testHorizontalLimit()
		super.runAllTests()
	}

	fun testPrinting() {
		val root = PrintableTree(description = "root")
		val a = PrintableTree(description = "a")
		val b = PrintableTree(description = "b")
		val c = PrintableTree(description = "c")
		val d = PrintableTree(description = "d")

		root.addChild(a)
		a.addChild(b)
		b.addChild(c)
		root.addChild(d)

		var result = ""
		root.prettyPrint {
			result += it
		}
		XCTAssertEqual(result, 
""" root
 ├─ a
 │  └─ b
 │     └─ c
 └─ d
""", "testPrinting")
	}

	fun testHorizontalLimit() {
		val root = PrintableTree(description = "root")
		val a = PrintableTree(description = "aaaaaaaaaaaaaaaaaa")
		val b = PrintableTree(description = "bbbbbbbbbbbbbbbbbb")
		val c = PrintableTree(description = "cccccccccccccccccc")
		val d = PrintableTree(description = "dddddddddddddddddd")

		root.addChild(a)
		a.addChild(b)
		b.addChild(c)
		root.addChild(d)

		var result = ""
		root.prettyPrint(horizontalLimit = 15) {
			result += it
		}
		XCTAssertEqual(result,
""" root
 ├─ aaaaaaaaaa…
 │  └─ bbbbbbb…
 │     └─ cccc…
 └─ dddddddddd…
""")
	}
}