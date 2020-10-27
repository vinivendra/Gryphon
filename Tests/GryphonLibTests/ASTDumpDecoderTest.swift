//
// Copyright 2018 Vinicius Jorge Vendramini
//
// Licensed under the Hippocratic License, Version 2.1;
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://firstdonoharm.dev/version/2/1/license.md
//
// To the full extent allowed by law, this software comes "AS IS,"
// WITHOUT ANY WARRANTY, EXPRESS OR IMPLIED, and licensor and any other
// contributor shall not be liable to anyone for any damages or other
// liability arising from, out of, or in connection with the sotfware
// or this license, under any kind of legal claim.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#if !GRYPHON
@testable import GryphonLib
import XCTest
#endif

class ASTDumpDecoderTest: XCTestCase {
	public func getClassName() -> String {
		return "ASTDumpDecoderTest"
	}

	/// Tests to be run by the translated Kotlin version.
	public func runAllTests() {
		testDecoderCanRead()
		testDecoderRead()
	}

	/// Tests to be run when using Swift on Linux
	static var allTests = [ // gryphon ignore
		("testDecoderCanRead", testDecoderCanRead),
		("testDecoderRead", testDecoderRead),
	]

	// MARK: - Tests
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

		// Identifier
		decoder = ASTDumpDecoder(encodedString: "foo bla)")
		string = decoder.readIdentifier()
		XCTAssertEqual(string, "foo")
		XCTAssertEqual(decoder.remainingBuffer, "bla)")

		decoder = ASTDumpDecoder(encodedString: "foo(baz)bar)")
		string = decoder.readIdentifier()
		XCTAssertEqual(string, "foo(baz)bar")
		XCTAssertEqual(decoder.remainingBuffer, ")")

		decoder = ASTDumpDecoder(encodedString: "foo\nbar)")
		string = decoder.readIdentifier()
		XCTAssertEqual(string, "foobar")
		XCTAssertEqual(decoder.remainingBuffer, ")")

		decoder = ASTDumpDecoder(encodedString: "foo\n  bar)")
		string = decoder.readIdentifier()
		XCTAssertEqual(string, "foo")
		XCTAssertEqual(decoder.remainingBuffer, "bar)")

		// Identifier list
		decoder = ASTDumpDecoder(encodedString: "foo,bla bar)")
		string = decoder.readIdentifier()
		XCTAssertEqual(string, "foo,bla")
		XCTAssertEqual(decoder.remainingBuffer, "bar)")

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

		// Declaration
		decoder = ASTDumpDecoder(
			encodedString: "test.(file).Bla.foo(bar:baz:).x)")
		optionalString = decoder.readDeclaration()
		XCTAssertEqual(
			optionalString, "test.(file).Bla.foo(bar:baz:).x")
		XCTAssertEqual(decoder.remainingBuffer, ")")

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

		decoder = ASTDumpDecoder(
			encodedString: "Swift.(file).Collection extension.dropLast foobarbazfoobarbaz")
		optionalString = decoder.readDeclaration()
		XCTAssertEqual(
			optionalString, "Swift.(file).Collection extension.dropLast")
		XCTAssertEqual(decoder.remainingBuffer, "foobarbazfoobarbaz")

		decoder = ASTDumpDecoder(
			encodedString: "Swift.(file).Collection exte\nnsion.dropLast foobarbazfoobarbaz")
		optionalString = decoder.readDeclaration()
		XCTAssertEqual(
			optionalString, "Swift.(file).Collection extension.dropLast")
		XCTAssertEqual(decoder.remainingBuffer, "foobarbazfoobarbaz")

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

		// String in angle brackets
		decoder = ASTDumpDecoder(encodedString: "<bla> foo)")
		string = decoder.readStringInAngleBrackets()
		XCTAssertEqual(string, "<bla>")
		XCTAssertEqual(decoder.remainingBuffer, "foo)")
	}
}
