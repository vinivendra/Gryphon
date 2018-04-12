@testable import GryphonLib
import XCTest

class GRYPrintableAsTreeTest: XCTestCase {
	func testPrinting() {
		let root = GRYPrintableTree(description: "root")
		let a = GRYPrintableTree(description: "a")
		let b = GRYPrintableTree(description: "b")
		let c = GRYPrintableTree(description: "c")
		let d = GRYPrintableTree(description: "d")
		
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
	
	func testStrings() {
		let root = GRYPrintableTree(description: "root")
		let a = GRYPrintableTree(description: "a")
		let b = GRYPrintableTree(description: "b")
		
		root.addChild(a)
		a.addChild(b)
		b.addChild("c")
		root.addChild("d")
		
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
	
	func testArrays() {
		let root = GRYPrintableTree(description: "root")
		let a = GRYPrintableTree(description: "a")
		
		root.addChild(a)
		root.addChild("d")
		a.addChild(["b", "c"])
		
		var result = ""
		root.prettyPrint {
			result += $0
		}
		XCTAssertEqual(result, """
			 root
			 ├─ a
			 │  └─ Array
			 │     ├─ b
			 │     └─ c
			 └─ d\n
			""")
	}
	
	static var allTests = [
		("testPrinting", testPrinting),
		("testStrings", testStrings),
		("testArrays", testArrays)
	]
}
