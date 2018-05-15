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
		("testSwiftc", testSwiftc)
	]
}
