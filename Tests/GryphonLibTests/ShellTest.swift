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

// gryphon output: Bootstrap/ShellTest.kt

#if !GRYPHON
@testable import GryphonLib
import XCTest
#endif

class ShellTest: XCTestCase {
	// gryphon insert: constructor(): super() { }

	public func getClassName() -> String { // gryphon annotation: override
		return "ShellTest"
	}

	/// Tests to be run by the translated Kotlin version.
	public func runAllTests() { // gryphon annotation: override
		testEcho()
		testSwiftc()
	}

	/// Tests to be run when using Swift on Linux
	static var allTests = [ // gryphon ignore
		("testEcho", testEcho),
		("testSwiftc", testSwiftc),
	]

	// MARK: - Tests
	func testEcho() {
		let command: List = ["echo", "foo bar baz"]
		guard let commandResult = Shell.runShellCommand(command) else {
			XCTFail("Timed out.")
			return
		}
		XCTAssertEqual(commandResult.standardOutput, "foo bar baz\n")
		XCTAssertEqual(commandResult.standardError, "")
		XCTAssertEqual(commandResult.status, 0)
	}

	func testSwiftc() {
		let command1: List = ["swiftc", "-dump-ast"]
		guard let command1Result = Shell.runShellCommand(command1) else {
			XCTFail("Timed out.")
			return
		}
		XCTAssertEqual(command1Result.standardOutput, "")
		XCTAssert(command1Result.standardError.contains("<unknown>:0: error: no input files\n"))
		XCTAssertNotEqual(command1Result.status, 0)

		let command2: List = ["swiftc", "--help"]
		guard let command2Result = Shell.runShellCommand(command2) else {
			XCTFail("Timed out.")
			return
		}
		XCTAssert(command2Result.standardOutput.contains("-dump-ast"))
		XCTAssertEqual(command2Result.standardError, "")
		XCTAssertEqual(command2Result.status, 0)
	}
}
