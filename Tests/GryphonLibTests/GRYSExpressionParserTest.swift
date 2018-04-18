@testable import GryphonLib
import XCTest

class GRYSExpressionParserTest: XCTestCase {
	func testCanRead() {
		XCTAssert(GRYSExpressionParser(fileContents:
			"(foo)").canReadOpenParentheses())
		XCTAssert(GRYSExpressionParser(fileContents:
			"  \n\t(foo)").canReadOpenParentheses())
		XCTAssertFalse(GRYSExpressionParser(fileContents:
			"foo)").canReadOpenParentheses())
		
		XCTAssert(GRYSExpressionParser(fileContents:
			") foo").canReadCloseParentheses())
		XCTAssert(GRYSExpressionParser(fileContents:
			"  \n\t)foo").canReadCloseParentheses())
		XCTAssertFalse(GRYSExpressionParser(fileContents:
			"(foo)").canReadCloseParentheses())
		
		XCTAssert(GRYSExpressionParser(fileContents:
			"foo=bar )").canReadKey())
		XCTAssert(GRYSExpressionParser(fileContents:
			"  \n\tfoo=\"bar\"").canReadKey())
		XCTAssertFalse(GRYSExpressionParser(fileContents:
			"(foo=bar)").canReadKey())
		
		XCTAssert(GRYSExpressionParser(fileContents:
			"foo)").canReadIdentifier())
		XCTAssert(GRYSExpressionParser(fileContents:
			"  \n\tfoo").canReadIdentifier())
		XCTAssertFalse(GRYSExpressionParser(fileContents:
			"(foo)").canReadIdentifier())
		
		XCTAssert(GRYSExpressionParser(fileContents:
			"\"foo\")").canReadDoubleQuotedString())
		XCTAssert(GRYSExpressionParser(fileContents:
			"  \n\t\"foo\"").canReadDoubleQuotedString())
		XCTAssertFalse(GRYSExpressionParser(fileContents:
			"(\"foo\")").canReadDoubleQuotedString())
		
		XCTAssert(GRYSExpressionParser(fileContents:
			"'foo')").canReadSingleQuotedString())
		XCTAssert(GRYSExpressionParser(fileContents:
			"  \n\t'foo'").canReadSingleQuotedString())
		XCTAssertFalse(GRYSExpressionParser(fileContents:
			"('foo')").canReadSingleQuotedString())
		
		XCTAssert(GRYSExpressionParser(fileContents:
			"[foo])").canReadStringInBrackets())
		XCTAssert(GRYSExpressionParser(fileContents:
			"  \n\t[foo]").canReadStringInBrackets())
		XCTAssertFalse(GRYSExpressionParser(fileContents:
			"([foo])").canReadStringInBrackets())
		
		XCTAssert(GRYSExpressionParser(fileContents:
			"/foo/bar baz/test.swift:5:16)").canReadLocation())
		XCTAssert(GRYSExpressionParser(fileContents:
			"  \n\t/foo/bar baz/test.swift:5:16)").canReadLocation())
		XCTAssertFalse(GRYSExpressionParser(fileContents:
			"(/foo/bar baz/test.swift:5:16))").canReadLocation())
		
		XCTAssert(GRYSExpressionParser(fileContents:
			"test.(file).Bla.foo(bar:baz:).x@/blah/blah blah/test.swift 4:13)").canReadDeclarationLocation())
		XCTAssert(GRYSExpressionParser(fileContents:
			"  \n\ttest.(file).Bla.foo(bar:baz:).x@/blah/blah blah/test.swift 4:13)").canReadDeclarationLocation())
		XCTAssertFalse(GRYSExpressionParser(fileContents:
			"(test.(file).Bla.foo(bar:baz:).x@/blah/blah blah/test.swift 4:13)").canReadDeclarationLocation())
	}
	
	func testRead() {
		var parser: GRYSExpressionParser
		var string: String
		
		// Open parentheses
		parser = GRYSExpressionParser(fileContents: "(foo")
		parser.readOpenParentheses()
		XCTAssertEqual(parser.contents, "foo")
		
		// Close parentheses
		parser = GRYSExpressionParser(fileContents: ") foo")
		parser.readCloseParentheses()
		XCTAssertEqual(parser.contents, " foo")
		
		// Identifier
		parser = GRYSExpressionParser(fileContents: "foo bla)")
		string = parser.readIdentifier()
		XCTAssertEqual(string, "foo")
		XCTAssertEqual(parser.contents, " bla)")
		
		parser = GRYSExpressionParser(fileContents: "foo(baz)bar)")
		string = parser.readIdentifier()
		XCTAssertEqual(string, "foo(baz)bar")
		XCTAssertEqual(parser.contents, ")")
		
		parser = GRYSExpressionParser(fileContents: "foo\"bar\"")
		string = parser.readIdentifier()
		XCTAssertEqual(string, "foo")
		XCTAssertEqual(parser.contents, "\"bar\"")
		
		parser = GRYSExpressionParser(fileContents: "foo'bar'")
		string = parser.readIdentifier()
		XCTAssertEqual(string, "foo")
		XCTAssertEqual(parser.contents, "'bar'")
		
		// Key
		parser = GRYSExpressionParser(fileContents: "foo='bar'")
		string = parser.readKey()
		XCTAssertEqual(string, "foo")
		XCTAssertEqual(parser.contents, "'bar'")
		
		parser = GRYSExpressionParser(fileContents: "interface type='bar'")
		string = parser.readKey()
		XCTAssertEqual(string, "interface type")
		XCTAssertEqual(parser.contents, "'bar'")
		
		// Location
		parser = GRYSExpressionParser(fileContents: "/foo/bar baz/test.swift:5:16)")
		string = parser.readLocation()
		XCTAssertEqual(string, "/foo/bar baz/test.swift:5:16")
		XCTAssertEqual(parser.contents, ")")
		
		// Declaration location
		parser = GRYSExpressionParser(fileContents: "test.(file).Bla.foo(bar:baz:).x@/foo/bar baz/test.swift:5:16)")
		string = parser.readDeclarationLocation()
		XCTAssertEqual(string, "test.(file).Bla.foo(bar:baz:).x@/foo/bar baz/test.swift:5:16")
		XCTAssertEqual(parser.contents, ")")
		
		// Double quoted string
		parser = GRYSExpressionParser(fileContents: "\"bla\" foo)")
		string = parser.readDoubleQuotedString()
		XCTAssertEqual(string, "bla")
		XCTAssertEqual(parser.contents, " foo)")
		
		// Single quoted string
		parser = GRYSExpressionParser(fileContents: "'bla' foo)")
		string = parser.readSingleQuotedString()
		XCTAssertEqual(string, "bla")
		XCTAssertEqual(parser.contents, " foo)")
		
		// String in brackets
		parser = GRYSExpressionParser(fileContents: "[bla] foo)")
		string = parser.readStringInBrackets()
		XCTAssertEqual(string, "bla")
		XCTAssertEqual(parser.contents, " foo)")
	}
	
	func testParser() {
		let tests = ["emptyFunction", "functionWithAssignment", "functionWithParameters", "functionWithReturn", "functionWithVariable"]
		
		for testName in tests {
			// Create an AST using the parser
			let testFilePath = TestUtils.testFilesPath + testName
			let swiftASTDump = GRYCompiler.getSwiftASTDump(forFileAt: testFilePath + ".swift")
			let createdAST = GRYAst(fileContents: swiftASTDump)
			
			// Load the previously stored AST from file
			let astRawJSON = try! String(contentsOfFile: testFilePath + ".json")
			let astProcessedJSON = Utils.replacePlaceholders(in: astRawJSON, withFilePath: testFilePath + ".swift")
			let astData = Data(astProcessedJSON.utf8)
			let expectedAST = try! JSONDecoder().decode(GRYAst.self, from: astData)
			
			XCTAssert(createdAST == expectedAST, "Test \(testName): parser failed to produce expected result. Diff:\n\n===\n\(TestUtils.diff(createdAST.description, expectedAST.description))===\n")
		}
	}
	
	static var allTests = [
		("testCanRead", testCanRead),
		("testRead", testRead),
		("testParser", testParser)
	]
}
