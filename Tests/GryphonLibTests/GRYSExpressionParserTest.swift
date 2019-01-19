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

class GRYSExpressionParserTest: XCTestCase {
	func testCanRead() {
		XCTAssert(GRYDecoder(sExpression:
			"(foo)").canReadOpenParentheses())
		XCTAssertFalse(GRYDecoder(sExpression:
			"foo)").canReadOpenParentheses())

		XCTAssert(GRYDecoder(sExpression:
			") foo").canReadCloseParentheses())
		XCTAssertFalse(GRYDecoder(sExpression:
			"(foo)").canReadCloseParentheses())

		XCTAssert(GRYDecoder(sExpression:
			"\"foo\")").canReadDoubleQuotedString())
		XCTAssertFalse(GRYDecoder(sExpression:
			"(\"foo\")").canReadDoubleQuotedString())

		XCTAssert(GRYDecoder(sExpression:
			"'foo')").canReadSingleQuotedString())
		XCTAssertFalse(GRYDecoder(sExpression:
			"('foo')").canReadSingleQuotedString())

		XCTAssert(GRYDecoder(sExpression:
			"[foo])").canReadStringInBrackets())
		XCTAssertFalse(GRYDecoder(sExpression:
			"([foo])").canReadStringInBrackets())

		XCTAssert(GRYDecoder(sExpression:
			"/foo/bar baz/test.swift:5:16)").canReadLocation())
		XCTAssertFalse(GRYDecoder(sExpression:
			"(/foo/bar baz/test.swift:5:16))").canReadLocation())
	}

	func testRead() {
		var parser: GRYDecoder
		var string: String
		var optionalString: String?

		// Open parentheses
		parser = GRYDecoder(sExpression: "(foo")
		parser.readOpenParentheses()
		XCTAssertEqual(parser.remainingBuffer, "foo")

		// Close parentheses
		parser = GRYDecoder(sExpression: ") foo")
		parser.readCloseParentheses()
		XCTAssertEqual(parser.remainingBuffer, "foo")

		// Identifier
		parser = GRYDecoder(sExpression: "foo bla)")
		string = parser.readIdentifier()
		XCTAssertEqual(string, "foo")
		XCTAssertEqual(parser.remainingBuffer, "bla)")

		parser = GRYDecoder(sExpression: "foo(baz)bar)")
		string = parser.readIdentifier()
		XCTAssertEqual(string, "foo(baz)bar")
		XCTAssertEqual(parser.remainingBuffer, ")")

		// Location
		parser = GRYDecoder(sExpression: "/foo/bar baz/test.swift:5:16 )")
		string = parser.readLocation()
		XCTAssertEqual(string, "/foo/bar baz/test.swift:5:16")
		XCTAssertEqual(parser.remainingBuffer, ")")

		// Declaration location
		parser = GRYDecoder(
			sExpression: "test.(file).Bla.foo(bar:baz:).x@/foo/bar baz/test.swift:5:16  )")
		optionalString = parser.readDeclarationLocation()
		XCTAssertEqual(
			optionalString, "test.(file).Bla.foo(bar:baz:).x@/foo/bar baz/test.swift:5:16")
		XCTAssertEqual(parser.remainingBuffer, ")")

		parser = GRYDecoder(
			sExpression: "(test.(file).Bla.foo(bar:baz:).x@/blah/blah blah/test.swift 4:13)")
		optionalString = parser.readDeclarationLocation()
		XCTAssertNil(optionalString)

		// Double quoted string
		parser = GRYDecoder(sExpression: "\"bla\" foo)")
		string = parser.readDoubleQuotedString()
		XCTAssertEqual(string, "bla")
		XCTAssertEqual(parser.remainingBuffer, "foo)")

		// Single quoted string
		parser = GRYDecoder(sExpression: "'bla' foo)")
		string = parser.readSingleQuotedString()
		XCTAssertEqual(string, "bla")
		XCTAssertEqual(parser.remainingBuffer, "foo)")

		// String in brackets
		parser = GRYDecoder(sExpression: "[bla] foo)")
		string = parser.readStringInBrackets()
		XCTAssertEqual(string, "bla")
		XCTAssertEqual(parser.remainingBuffer, "foo)")
	}

	func testParser() {
		let tests = TestUtils.allTestCases

		for testName in tests {
			print("- Testing \(testName)...")

			// Create a new AST using the parser
			let testFilePath = TestUtils.testFilesPath + testName
			let createdAST = GRYSwiftAst(astFile: testFilePath + .swiftAstDump)

			// Load a cached AST from file
			let expectedAST = GRYSwiftAst.initialize(
				fromJsonInFile: testFilePath + .grySwiftAstJson)

			// Compare the two
			XCTAssert(
				createdAST == expectedAST,
				"Test \(testName): parser failed to produce expected result. Diff:" +
					TestUtils.diff(createdAST.description, expectedAST.description))

			print("\t- Done!")
		}
	}

	static var allTests = [
		("testCanRead", testCanRead),
		("testRead", testRead),
		("testParser", testParser),
	]

	static override func setUp() {
		try! GRYUtils.updateTestFiles()
	}
}
