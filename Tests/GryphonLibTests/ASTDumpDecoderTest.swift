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

class ASTDumpDecoderTest: XCTestCase {
	func testDecoderCanRead() {
		XCTAssert(ASTDumpDecoder(encodedString:
			"(foo)").canReadOpeningParenthesis())
		XCTAssertFalse(ASTDumpDecoder(encodedString:
			"foo)").canReadOpeningParenthesis())

		XCTAssert(ASTDumpDecoder(encodedString:
			") foo").canReadClosingParenthesis())
		XCTAssertFalse(ASTDumpDecoder(encodedString:
			"(foo)").canReadClosingParenthesis())

		XCTAssert(ASTDumpDecoder(encodedString:
			"[0]").canReadOpeningBracket())
		XCTAssertFalse(ASTDumpDecoder(encodedString:
			"0]").canReadOpeningBracket())

		XCTAssert(ASTDumpDecoder(encodedString:
			"] foo").canReadClosingBracket())
		XCTAssertFalse(ASTDumpDecoder(encodedString:
			"[foo]").canReadClosingBracket())

		XCTAssert(ASTDumpDecoder(encodedString:
			"{0 1}").canReadOpeningBrace())
		XCTAssertFalse(ASTDumpDecoder(encodedString:
			"0 1}").canReadOpeningBrace())

		XCTAssert(ASTDumpDecoder(encodedString:
			"} 0 1").canReadClosingBrace())
		XCTAssertFalse(ASTDumpDecoder(encodedString:
			"{0 1}").canReadClosingBrace())

		XCTAssert(ASTDumpDecoder(encodedString:
			"\"foo\")").canReadDoubleQuotedString())
		XCTAssertFalse(ASTDumpDecoder(encodedString:
			"(\"foo\")").canReadDoubleQuotedString())

		XCTAssert(ASTDumpDecoder(encodedString:
			"'foo')").canReadSingleQuotedString())
		XCTAssertFalse(ASTDumpDecoder(encodedString:
			"('foo')").canReadSingleQuotedString())

		XCTAssert(ASTDumpDecoder(encodedString:
			"[foo])").canReadStringInBrackets())
		XCTAssertFalse(ASTDumpDecoder(encodedString:
			"([foo])").canReadStringInBrackets())

		XCTAssert(ASTDumpDecoder(encodedString:
			"/foo/bar baz/test.swift:5:16)").canReadLocation())
		XCTAssertFalse(ASTDumpDecoder(encodedString:
			"(/foo/bar baz/test.swift:5:16))").canReadLocation())
	}

	func testDecoderRead() {
		var decoder: ASTDumpDecoder
		var string: String
		var optionalString: String?

		// Parentheses
		decoder = ASTDumpDecoder(encodedString: "(foo")
		XCTAssertNoThrow(try decoder.readOpeningParenthesis())
		XCTAssertEqual(decoder.remainingBuffer, "foo")

		decoder = ASTDumpDecoder(encodedString: ") foo")
		XCTAssertNoThrow(try decoder.readClosingParenthesis())
		XCTAssertEqual(decoder.remainingBuffer, "foo")

		// Brackets
		decoder = ASTDumpDecoder(encodedString: "[foo")
		XCTAssertNoThrow(try decoder.readOpeningBracket())
		XCTAssertEqual(decoder.remainingBuffer, "foo")

		decoder = ASTDumpDecoder(encodedString: "] foo")
		XCTAssertNoThrow(try decoder.readClosingBracket())
		XCTAssertEqual(decoder.remainingBuffer, "foo")

		// Braces
		decoder = ASTDumpDecoder(encodedString: "{foo")
		XCTAssertNoThrow(try decoder.readOpeningBrace())
		XCTAssertEqual(decoder.remainingBuffer, "foo")

		decoder = ASTDumpDecoder(encodedString: "} foo")
		XCTAssertNoThrow(try decoder.readClosingBrace())
		XCTAssertEqual(decoder.remainingBuffer, "foo")

		// Identifier
		decoder = ASTDumpDecoder(encodedString: "foo bla)")
		string = decoder.readIdentifier()
		XCTAssertEqual(string, "foo")
		XCTAssertEqual(decoder.remainingBuffer, "bla)")

		decoder = ASTDumpDecoder(encodedString: "foo(baz)bar)")
		string = decoder.readIdentifier()
		XCTAssertEqual(string, "foo(baz)bar")
		XCTAssertEqual(decoder.remainingBuffer, ")")

		// Location
		decoder = ASTDumpDecoder(encodedString: "/foo/bar baz/test.swift:5:16 )")
		string = decoder.readLocation()
		XCTAssertEqual(string, "/foo/bar baz/test.swift:5:16")
		XCTAssertEqual(decoder.remainingBuffer, ")")

		// Declaration location
		decoder = ASTDumpDecoder(
			encodedString: "test.(file).Bla.foo(bar:baz:).x@/foo/bar baz/test.swift:5:16  )")
		optionalString = decoder.readDeclarationLocation()
		XCTAssertEqual(
			optionalString, "test.(file).Bla.foo(bar:baz:).x@/foo/bar baz/test.swift:5:16")
		XCTAssertEqual(decoder.remainingBuffer, ")")

		decoder = ASTDumpDecoder(
			encodedString: "(test.(file).Bla.foo(bar:baz:).x@/blah/blah blah/test.swift 4:13)")
		optionalString = decoder.readDeclarationLocation()
		XCTAssertNil(optionalString)

		// Double quoted string
		decoder = ASTDumpDecoder(encodedString: "\"bla\" foo)")
		string = decoder.readDoubleQuotedString()
		XCTAssertEqual(string, "bla")
		XCTAssertEqual(decoder.remainingBuffer, "foo)")

		// Single quoted string
		decoder = ASTDumpDecoder(encodedString: "'bla' foo)")
		string = decoder.readSingleQuotedString()
		XCTAssertEqual(string, "bla")
		XCTAssertEqual(decoder.remainingBuffer, "foo)")

		// String in brackets
		decoder = ASTDumpDecoder(encodedString: "[bla] foo)")
		string = decoder.readStringInBrackets()
		XCTAssertEqual(string, "bla")
		XCTAssertEqual(decoder.remainingBuffer, "foo)")

		//
		// Test that a Swift compiler bug is being handled correctly. See `readIdentifier`'s docs.
		decoder = ASTDumpDecoder(encodedString: "foo\nbar)")
		string = decoder.readIdentifier()
		XCTAssertEqual(string, "foobar")
		XCTAssertEqual(decoder.remainingBuffer, ")")

		decoder = ASTDumpDecoder(encodedString: "foo\n  bar)")
		string = decoder.readIdentifier()
		XCTAssertEqual(string, "foo")
		XCTAssertEqual(decoder.remainingBuffer, "bar)")

		decoder = ASTDumpDecoder(
			encodedString: "test.(file).Bl\na.foo(bar:baz:).x)")
		optionalString = decoder.readDeclaration()
		XCTAssertEqual(
			optionalString, "test.(file).Bla.foo(bar:baz:).x")
		XCTAssertEqual(decoder.remainingBuffer, ")")

		decoder = ASTDumpDecoder(
			encodedString: "test.(file).Bla.foo(bar:baz:).x\n  )")
		optionalString = decoder.readDeclaration()
		XCTAssertEqual(
			optionalString, "test.(file).Bla.foo(bar:baz:).x")
		XCTAssertEqual(decoder.remainingBuffer, ")")
	}

	static var allTests = [
		("testDecoderCanRead", testDecoderCanRead),
		("testDecoderRead", testDecoderRead),
	]

	override static func setUp() {
		do {
			try Utilities.updateTestFiles()
		}
		catch let error {
			print(error)
			fatalError("Failed to update test files.")
		}
	}

	override func setUp() {
		Compiler.clearErrorsAndWarnings()
	}
}
