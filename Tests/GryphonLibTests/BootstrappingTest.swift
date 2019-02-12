/*
* Copyright 2018 Vinícius Jorge Vendramini
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

@testable import GryphonLib
import XCTest

class BootstrappingTest: XCTestCase {
	func test() {
		// Compile the Kotlin version of the transpiler
		let compilationCommand = [
			GRYCompiler.kotlinCompilerPath,
			"-include-runtime", "-d", "kotlin.jar",
			"GRYPrintableAsTree.kt", "GRYPrintableAsTreeTests.kt",
			"GRYKotlinTests.kt", "main.kt", ]
		guard let compilationResult =
			GRYShell.runShellCommand(compilationCommand, fromFolder: "Bootstrap") else
		{
			XCTFail("Timed out.")
			return
		}
		guard compilationResult.standardOutput == "",
			compilationResult.standardError == "",
			compilationResult.status == 0 else
		{
			XCTFail("Failed to compile Kotlin bootstrap tests.\n" +
				"Output:\n\(compilationResult.standardOutput)\n" +
				"Error:\n\(compilationResult.standardError)\n" +
				"Exit status: \(compilationResult.status)\n")
			return
		}

		// Run the Kotlin version's tests
		let runCommand = ["java", "-jar", "kotlin.jar", ]
		guard let runResult =
			GRYShell.runShellCommand(runCommand, fromFolder: "Bootstrap") else
		{
			XCTFail("Timed out.")
			return
		}
		guard runResult.standardError == "",
			runResult.status == 0 else
		{
			XCTFail("Failed to run Kotlin bootstrap tests.\n" +
				"Output:\n\(runResult.standardOutput)\n" +
				"Error:\n\(runResult.standardError)\n" +
				"Exit status: \(runResult.status)\n")
			return
		}

		let testMessages = runResult.standardOutput.split(separator: "\n")
		for testMessage in testMessages {
			if !testMessage.hasSuffix("All tests succeeded!") {
				XCTFail(String(testMessage))
			}
		}
	}

	static var allTests = [
		("test", test),
	]

	override static func setUp() {
		do {
			try GRYUtils.updateTestFiles()
		}
		catch let error {
			print(error)
			fatalError("Failed to update test files.")
		}
	}
}
