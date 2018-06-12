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

class GRYShellTest: XCTestCase {
	func testEcho() {
		let command = ["echo", "foo bar baz"]
		guard let commandResult = GRYShell.runShellCommand(command) else {
			XCTFail("Timed out.")
			return
		}
		XCTAssertEqual(commandResult.standardOutput, "foo bar baz\n")
		XCTAssertEqual(commandResult.standardError, "")
		XCTAssertEqual(commandResult.status, 0)
	}

	func testSwiftc() {
		let command1 = ["swiftc", "-dump-ast"]
		guard let command1Result = GRYShell.runShellCommand(command1) else {
			XCTFail("Timed out.")
			return
		}
		XCTAssertEqual(command1Result.standardOutput, "")
		XCTAssertEqual(command1Result.standardError, "<unknown>:0: error: no input files\n")
		XCTAssertNotEqual(command1Result.status, 0)

		let command2 = ["swiftc", "--help"]
		guard let command2Result = GRYShell.runShellCommand(command2) else {
			XCTFail("Timed out.")
			return
		}
		XCTAssert(command2Result.standardOutput.contains("-dump-ast"))
		XCTAssertEqual(command2Result.standardError, "")
		XCTAssertEqual(command2Result.status, 0)
	}

	static var allTests = [
		("testEcho", testEcho),
		("testSwiftc", testSwiftc),
	]
}
