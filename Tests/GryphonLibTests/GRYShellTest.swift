@testable import GryphonLib
import XCTest

class GRYShellTest: XCTestCase {
	func testEcho() {
		let command = ["echo", "foo bar baz"]
		let commandResult = GRYShell.runShellCommand(command)
		XCTAssertEqual(commandResult.standardOutput, "foo bar baz\n")
		XCTAssertEqual(commandResult.standardError, "")
		XCTAssertEqual(commandResult.status, 0)
	}
	
	func testSwiftc() {
		let command1 = ["swiftc", "-dump-ast"]
		let command1Result = GRYShell.runShellCommand(command1)
		XCTAssertEqual(command1Result.standardOutput, "")
		XCTAssertEqual(command1Result.standardError, "<unknown>:0: error: no input files\n")
		XCTAssertNotEqual(command1Result.status, 0)
		
		let command2 = ["swiftc", "--help"]
		let command2Result = GRYShell.runShellCommand(command2)
		XCTAssert(command2Result.standardOutput.contains("-dump-ast"))
		XCTAssertEqual(command2Result.standardError, "")
		XCTAssertEqual(command2Result.status, 0)
	}
	
	static var allTests = [
		("testEcho", testEcho),
		("testSwiftc", testSwiftc)
	]
}
