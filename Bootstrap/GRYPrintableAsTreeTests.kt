class GRYPrintableAsTreeTests(): GRYTest("GRYPrintableAsTreeTests") {
	override fun runAllTests() {
		testPrinting()
		testHorizontalLimit()
		super.runAllTests()
	}

	fun testPrinting() {
		val root = GRYPrintableTree(description = "root")
		val a = GRYPrintableTree(description = "a")
		val b = GRYPrintableTree(description = "b")
		val c = GRYPrintableTree(description = "c")
		val d = GRYPrintableTree(description = "d")

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
		val root = GRYPrintableTree(description = "root")
		val a = GRYPrintableTree(description = "aaaaaaaaaaaaaaaaaa")
		val b = GRYPrintableTree(description = "bbbbbbbbbbbbbbbbbb")
		val c = GRYPrintableTree(description = "cccccccccccccccccc")
		val d = GRYPrintableTree(description = "dddddddddddddddddd")

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