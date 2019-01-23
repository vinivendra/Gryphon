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

// TODO: Change parser naming
class GRYSExpressionParserTest: XCTestCase {
	func testCanRead() {
		XCTAssert(GRYDecoder(encodedString:
			"(foo)").canReadOpenParentheses())
		XCTAssertFalse(GRYDecoder(encodedString:
			"foo)").canReadOpenParentheses())

		XCTAssert(GRYDecoder(encodedString:
			") foo").canReadCloseParentheses())
		XCTAssertFalse(GRYDecoder(encodedString:
			"(foo)").canReadCloseParentheses())

		XCTAssert(GRYDecoder(encodedString:
			"\"foo\")").canReadDoubleQuotedString())
		XCTAssertFalse(GRYDecoder(encodedString:
			"(\"foo\")").canReadDoubleQuotedString())

		XCTAssert(GRYDecoder(encodedString:
			"'foo')").canReadSingleQuotedString())
		XCTAssertFalse(GRYDecoder(encodedString:
			"('foo')").canReadSingleQuotedString())

		XCTAssert(GRYDecoder(encodedString:
			"[foo])").canReadStringInBrackets())
		XCTAssertFalse(GRYDecoder(encodedString:
			"([foo])").canReadStringInBrackets())

		XCTAssert(GRYDecoder(encodedString:
			"/foo/bar baz/test.swift:5:16)").canReadLocation())
		XCTAssertFalse(GRYDecoder(encodedString:
			"(/foo/bar baz/test.swift:5:16))").canReadLocation())
	}

	func testRead() {
		var parser: GRYDecoder
		var string: String
		var optionalString: String?

		// Open parentheses
		parser = GRYDecoder(encodedString: "(foo")
		XCTAssertNoThrow(try parser.readOpenParentheses())
		XCTAssertEqual(parser.remainingBuffer, "foo")

		// Close parentheses
		parser = GRYDecoder(encodedString: ") foo")
		XCTAssertNoThrow(try parser.readCloseParentheses())
		XCTAssertEqual(parser.remainingBuffer, "foo")

		// Identifier
		parser = GRYDecoder(encodedString: "foo bla)")
		string = parser.readIdentifier()
		XCTAssertEqual(string, "foo")
		XCTAssertEqual(parser.remainingBuffer, "bla)")

		parser = GRYDecoder(encodedString: "foo(baz)bar)")
		string = parser.readIdentifier()
		XCTAssertEqual(string, "foo(baz)bar")
		XCTAssertEqual(parser.remainingBuffer, ")")

		// Location
		parser = GRYDecoder(encodedString: "/foo/bar baz/test.swift:5:16 )")
		string = parser.readLocation()
		XCTAssertEqual(string, "/foo/bar baz/test.swift:5:16")
		XCTAssertEqual(parser.remainingBuffer, ")")

		// Declaration location
		parser = GRYDecoder(
			encodedString: "test.(file).Bla.foo(bar:baz:).x@/foo/bar baz/test.swift:5:16  )")
		optionalString = parser.readDeclarationLocation()
		XCTAssertEqual(
			optionalString, "test.(file).Bla.foo(bar:baz:).x@/foo/bar baz/test.swift:5:16")
		XCTAssertEqual(parser.remainingBuffer, ")")

		parser = GRYDecoder(
			encodedString: "(test.(file).Bla.foo(bar:baz:).x@/blah/blah blah/test.swift 4:13)")
		optionalString = parser.readDeclarationLocation()
		XCTAssertNil(optionalString)

		// Double quoted string
		parser = GRYDecoder(encodedString: "\"bla\" foo)")
		string = parser.readDoubleQuotedString()
		XCTAssertEqual(string, "bla")
		XCTAssertEqual(parser.remainingBuffer, "foo)")

		// Single quoted string
		parser = GRYDecoder(encodedString: "'bla' foo)")
		string = parser.readSingleQuotedString()
		XCTAssertEqual(string, "bla")
		XCTAssertEqual(parser.remainingBuffer, "foo)")

		// String in brackets
		parser = GRYDecoder(encodedString: "[bla] foo)")
		string = parser.readStringInBrackets()
		XCTAssertEqual(string, "bla")
		XCTAssertEqual(parser.remainingBuffer, "foo)")
	}

	func testParser() {
		let tests = TestUtils.allTestCases

		do {
			for testName in tests {
				print("- Testing \(testName)...")

				// Create a new AST using the parser
				let testFilePath = TestUtils.testFilesPath + testName
				let createdAST = try GRYSwiftAst(astFile: testFilePath + .swiftAstDump)

				// Load a cached AST from file
				let expectedAST = try GRYSwiftAst.initialize(decodingFile: testFilePath + .grySwiftAst)

				// Compare the two
				XCTAssert(
					createdAST == expectedAST,
					"Test \(testName): parser failed to produce expected result. Diff:" +
						TestUtils.diff(createdAST.description, expectedAST.description))

				print("\t- Done!")
			}
		}
		catch let error {
			XCTFail("🚨 Test failed with error:\n\(error)")
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
