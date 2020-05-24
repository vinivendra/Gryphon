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

open class XCTestCase() {
    open fun getClassName(): String {
        return "XCTestCase"
    }

    var allTestsSucceeded = true

    fun run() {
        println("➡️  Running ${getClassName()}...")

        runAllTests()

        println("↪️  ${getClassName()} done.\n")

        if (allTestsSucceeded) {
            XCTestCase.passedTests.add(getClassName())
        }
        else {
            XCTestCase.failedTests.add(getClassName())
        }
    }    

    open fun runAllTests() { }

    companion object {
        var passedTests = mutableListOf<String>()
        var failedTests = mutableListOf<String>()
    }

    //
    fun XCTAssert(condition: Boolean, test: String = "No message") {
        if (!condition) {
            allTestsSucceeded = false
            System.err.println("${getClassName()} - XCTAssert failed: ${test}.")
            Exception().printStackTrace()
        }
    }

    fun XCTAssertFalse(condition: Boolean, test: String = "No message") {
        if (condition) {
            allTestsSucceeded = false
            System.err.println("${getClassName()} - XCTAssertFalse failed: ${test}.")
            Exception().printStackTrace()
        }
    }

    fun <T> XCTAssertEqual(a: T, b: T, test: String = "No message") {
        if (a != b) {
            allTestsSucceeded = false
            System.err.println("${getClassName()} - XCTAssertEqual failed: ${test}.\n\"${a}\"\nis not equal to\n\"${b}\"\n--")
            Exception().printStackTrace()
        }
    }

    fun <T> XCTAssertNotEqual(a: T, b: T, test: String = "No message") {
        if (a == b) {
            allTestsSucceeded = false
            System.err.println("${getClassName()} - XCTAssertNotEqual failed: ${test}.\n\"${a}\"\nis equal to\n\"${b}\"\n--")
            Exception().printStackTrace()
        }
    }

    fun <T> XCTAssertNil(a: T?, test: String = "No message") {
        if (a != null) {
            allTestsSucceeded = false
            System.err.println("${getClassName()} - XCTAssertNil failed: ${test}.")    
            Exception().printStackTrace()
        }
    }

    fun <T> XCTAssertNotNil(a: T?, test: String = "No message") {
        if (a == null) {
            allTestsSucceeded = false
            System.err.println("${getClassName()} - XCTAssertNotNil failed: ${test}.")    
            Exception().printStackTrace()
        }
    }

    fun XCTFail(test: String = "No message") {
        allTestsSucceeded = false
        System.err.println("${getClassName()} - XCTFail: ${test}.")    
        Exception().printStackTrace()
    }

    fun XCTAssertNoThrow(closure: () -> Unit) {
        try {
            closure()
        }
        catch (error: Exception) {
            allTestsSucceeded = false
            System.err.println("${getClassName()} - XCTAssertNoThrow failed.")
            Exception().printStackTrace()
            System.err.println("Error thrown:")
            System.err.println(error)
        }
    }

    fun XCTAssertThrowsError(closure: () -> Unit) {
        try {
            closure()
            // If the error is thrown, the closure returns early and this isn't
            // run:
            allTestsSucceeded = false
            System.err.println("${getClassName()} - XCTAssertNoThrow failed.")
            Exception().printStackTrace()
        } catch (error: Exception) {
        }
    }
}
