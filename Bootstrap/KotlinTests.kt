open class Test(val className: String) {
	var allTestsSucceeded = true

	open fun runAllTests() {
		if (allTestsSucceeded) {
			println("${className}: All tests succeeded!")
		}
	}

	fun XCTAssert(condition: Boolean, test: String = "") {
		if (!condition) {
			allTestsSucceeded = false
			println("${className} - XCTAssert failed: ${test}.")
		}
	}

	fun XCTAssertFalse(condition: Boolean, test: String = "") {
		if (condition) {
			allTestsSucceeded = false
			println("${className} - XCTAssertFalse failed: ${test}.")
		}
	}

	fun <T> XCTAssertEqual(a: T, b: T, test: String = "") {
    	if (a != b) {
    		allTestsSucceeded = false
    		println("${className} - XCTAssertEqual failed: ${test}.\n\"${a}\"\nis not equal to\n\"${b}\"\n--")
    	}
	}

	fun <T> XCTAssertNil(a: T?, test: String = "") {
    	if (a != null) {
    		allTestsSucceeded = false
    		println("${className} - XCTAssertNil failed: ${test}.")	
    	}
	}
}
