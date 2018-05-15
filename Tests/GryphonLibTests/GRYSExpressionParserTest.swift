@testable import GryphonLib
import XCTest

class GRYSExpressionParserTest: XCTestCase {
	func testCanRead() {
		XCTAssert(GRYSExpressionParser(sExpression:
			"(foo)").canReadOpenParentheses())
		XCTAssertFalse(GRYSExpressionParser(sExpression:
			"foo)").canReadOpenParentheses())
		
		XCTAssert(GRYSExpressionParser(sExpression:
			") foo").canReadCloseParentheses())
		XCTAssertFalse(GRYSExpressionParser(sExpression:
			"(foo)").canReadCloseParentheses())
		
		XCTAssert(GRYSExpressionParser(sExpression:
			"\"foo\")").canReadDoubleQuotedString())
		XCTAssertFalse(GRYSExpressionParser(sExpression:
			"(\"foo\")").canReadDoubleQuotedString())
		
		XCTAssert(GRYSExpressionParser(sExpression:
			"'foo')").canReadSingleQuotedString())
		XCTAssertFalse(GRYSExpressionParser(sExpression:
			"('foo')").canReadSingleQuotedString())
		
		XCTAssert(GRYSExpressionParser(sExpression:
			"[foo])").canReadStringInBrackets())
		XCTAssertFalse(GRYSExpressionParser(sExpression:
			"([foo])").canReadStringInBrackets())
		
		XCTAssert(GRYSExpressionParser(sExpression:
			"/foo/bar baz/test.swift:5:16)").canReadLocation())
		XCTAssertFalse(GRYSExpressionParser(sExpression:
			"(/foo/bar baz/test.swift:5:16))").canReadLocation())
		
		XCTAssert(GRYSExpressionParser(sExpression:
			"test.(file).Bla.foo(bar:baz:).x@/blah/blah blah/test.swift 4:13)").canReadDeclarationLocation())
		XCTAssertFalse(GRYSExpressionParser(sExpression:
			"(test.(file).Bla.foo(bar:baz:).x@/blah/blah blah/test.swift 4:13)").canReadDeclarationLocation())
	}
	
	func testRead() {
		var parser: GRYSExpressionParser
		var string: String
		
		// Open parentheses
		parser = GRYSExpressionParser(sExpression: "(foo")
		parser.readOpenParentheses()
		XCTAssertEqual(parser.remainingBuffer, "foo")
		
		// Close parentheses
		parser = GRYSExpressionParser(sExpression: ") foo")
		parser.readCloseParentheses()
		XCTAssertEqual(parser.remainingBuffer, "foo")
		
		// Identifier
		parser = GRYSExpressionParser(sExpression: "foo bla)")
		string = parser.readIdentifier()
		XCTAssertEqual(string, "foo")
		XCTAssertEqual(parser.remainingBuffer, "bla)")
		
		parser = GRYSExpressionParser(sExpression: "foo(baz)bar)")
		string = parser.readIdentifier()
		XCTAssertEqual(string, "foo(baz)bar")
		XCTAssertEqual(parser.remainingBuffer, ")")
		
		// Location
		parser = GRYSExpressionParser(sExpression: "/foo/bar baz/test.swift:5:16 )")
		string = parser.readLocation()
		XCTAssertEqual(string, "/foo/bar baz/test.swift:5:16")
		XCTAssertEqual(parser.remainingBuffer, ")")
		
		// Declaration location
		parser = GRYSExpressionParser(sExpression: "test.(file).Bla.foo(bar:baz:).x@/foo/bar baz/test.swift:5:16  )")
		string = parser.readDeclarationLocation()
		XCTAssertEqual(string, "test.(file).Bla.foo(bar:baz:).x@/foo/bar baz/test.swift:5:16")
		XCTAssertEqual(parser.remainingBuffer, ")")
		
		// Double quoted string
		parser = GRYSExpressionParser(sExpression: "\"bla\" foo)")
		string = parser.readDoubleQuotedString()
		XCTAssertEqual(string, "bla")
		XCTAssertEqual(parser.remainingBuffer, "foo)")
		
		// Single quoted string
		parser = GRYSExpressionParser(sExpression: "'bla' foo)")
		string = parser.readSingleQuotedString()
		XCTAssertEqual(string, "bla")
		XCTAssertEqual(parser.remainingBuffer, "foo)")
		
		// String in brackets
		parser = GRYSExpressionParser(sExpression: "[bla] foo)")
		string = parser.readStringInBrackets()
		XCTAssertEqual(string, "bla")
		XCTAssertEqual(parser.remainingBuffer, "foo)")
	}
	
	func testParser() {
		let tests = TestUtils.allTestCases
		
		for testName in tests {
			print("\t Testing \(testName)...", terminator: "")

			// Create an AST using the parser
			let testFilePath = TestUtils.testFilesPath + testName
			let createdAST = GRYAst(astFile: testFilePath + ".ast")

			// Load the previously stored AST from file
			let expectedAST = GRYAst.initialize(fromJsonInFile: testFilePath + ".expectedJson")

			XCTAssert(createdAST == expectedAST, "Test \(testName): parser failed to produce expected result. Diff:\(TestUtils.diff(createdAST.description, expectedAST.description))")

			print(" Done!")
		}
	}
	
	static var allTests = [
		("testCanRead", testCanRead),
		("testRead", testRead),
		("testParser", testParser)
	]
}
