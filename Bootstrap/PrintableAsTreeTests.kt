class PrintableAsTreeTests(): Test("PrintableAsTreeTests") {
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