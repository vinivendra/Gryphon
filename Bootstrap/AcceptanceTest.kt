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
import kotlin.system.exitProcess

open class AcceptanceTest: XCTestCase {
    companion object {
        internal fun setUp() {
            try {
                Utilities.updateTestCases()
            }
            catch (error: Exception) {
                println(error)
                println("Fatal error: ${"Failed to update test files."}"); exitProcess(-1)
            }
        }
    }

    constructor(): super() { }

    override public fun getClassName(): String {
        return "AcceptanceTest"
    }

    /// Tests to be run by the translated Kotlin version.
    override public fun runAllTests() {
        AcceptanceTest.setUp()
        test()
    }

    /// Tests to be run when using Swift on Linux
    // MARK: - Tests
    internal fun test() {
        val tests: List<String> = TestUtilities.testCasesForAcceptanceTest
        for (testName in tests) {
            println("- Testing ${testName}...")
            try {
                // Translate the swift code to kotlin, compile the resulting kotlin code, run it,
                // and get its output
                val testCasePath: String = TestUtilities.testCasesPath + testName
                val astDumpFilePath: String = Utilities.pathOfSwiftASTDumpFile(swiftFile = testCasePath)
                val compilationResult: Shell.CommandOutput? = Compiler.transpileCompileAndRun(
                    inputFiles = mutableListOf(astDumpFilePath),
                    context = TranspilationContext(indentationString = "\t"))

                if (compilationResult == null) {
                    XCTFail("Test ${testName} - compilation error. " + "It's possible a command timed out.")
                    continue
                }

                // Load the previously stored kotlin code from file
                val expectedOutput: String = Utilities.readFile(testCasePath.withExtension(FileExtension.OUTPUT))

                XCTAssert(
                    compilationResult.standardError == "",
                    "Test ${testName}: the compiler encountered an error: " + "${compilationResult.standardError}.")
                XCTAssert(
                    compilationResult.status == 0,
                    "Test ${testName}: the compiler exited with value " + "${compilationResult.status}.")
                XCTAssert(
                    compilationResult.standardOutput == expectedOutput,
                    "Test ${testName}: program failed to produce expected result. Diff:" + TestUtilities.diff(compilationResult.standardOutput, expectedOutput))

                println("\t- Done!")
            }
            catch (error: Exception) {
                XCTFail("🚨 Test failed with error:\n${error}")
            }
        }
    }
}
