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

class GRYCodableTest: XCTestCase {
	struct TestObject: Equatable {
		let x: Int
		let y: Int

		func encode(into encoder: GRYEncoder) throws {
			try x.encode(into: encoder)
			try y.encode(into: encoder)
		}

		static func decode(from decoder: GRYDecoder) throws -> TestObject {
			return TestObject(
				x: try Int.decode(from: decoder), y: try Int.decode(from: decoder))
		}
	}

	// MARK: - Decoder tests
	func testDecoderCanRead() {
		XCTAssert(GRYDecoder(encodedString:
			"(foo)").canReadOpeningParenthesis())
		XCTAssertFalse(GRYDecoder(encodedString:
			"foo)").canReadOpeningParenthesis())

		XCTAssert(GRYDecoder(encodedString:
			") foo").canReadClosingParenthesis())
		XCTAssertFalse(GRYDecoder(encodedString:
			"(foo)").canReadClosingParenthesis())

		XCTAssert(GRYDecoder(encodedString:
			"[0]").canReadOpeningBracket())
		XCTAssertFalse(GRYDecoder(encodedString:
			"0]").canReadOpeningBracket())

		XCTAssert(GRYDecoder(encodedString:
			"] foo").canReadClosingBracket())
		XCTAssertFalse(GRYDecoder(encodedString:
			"[foo]").canReadClosingBracket())

		XCTAssert(GRYDecoder(encodedString:
			"{0 1}").canReadOpeningBrace())
		XCTAssertFalse(GRYDecoder(encodedString:
			"0 1}").canReadOpeningBrace())

		XCTAssert(GRYDecoder(encodedString:
			"} 0 1").canReadClosingBrace())
		XCTAssertFalse(GRYDecoder(encodedString:
			"{0 1}").canReadClosingBrace())

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

	func testDecoderRead() {
		var decoder: GRYDecoder
		var string: String
		var optionalString: String?

		// Parentheses
		decoder = GRYDecoder(encodedString: "(foo")
		XCTAssertNoThrow(try decoder.readOpeningParenthesis())
		XCTAssertEqual(decoder.remainingBuffer, "foo")

		decoder = GRYDecoder(encodedString: ") foo")
		XCTAssertNoThrow(try decoder.readClosingParenthesis())
		XCTAssertEqual(decoder.remainingBuffer, "foo")

		// Brackets
		decoder = GRYDecoder(encodedString: "[foo")
		XCTAssertNoThrow(try decoder.readOpeningBracket())
		XCTAssertEqual(decoder.remainingBuffer, "foo")

		decoder = GRYDecoder(encodedString: "] foo")
		XCTAssertNoThrow(try decoder.readClosingBracket())
		XCTAssertEqual(decoder.remainingBuffer, "foo")

		// Braces
		decoder = GRYDecoder(encodedString: "{foo")
		XCTAssertNoThrow(try decoder.readOpeningBrace())
		XCTAssertEqual(decoder.remainingBuffer, "foo")

		decoder = GRYDecoder(encodedString: "} foo")
		XCTAssertNoThrow(try decoder.readClosingBrace())
		XCTAssertEqual(decoder.remainingBuffer, "foo")

		// Identifier
		decoder = GRYDecoder(encodedString: "foo bla)")
		string = decoder.readIdentifier()
		XCTAssertEqual(string, "foo")
		XCTAssertEqual(decoder.remainingBuffer, "bla)")

		decoder = GRYDecoder(encodedString: "foo(baz)bar)")
		string = decoder.readIdentifier()
		XCTAssertEqual(string, "foo(baz)bar")
		XCTAssertEqual(decoder.remainingBuffer, ")")

		// Location
		decoder = GRYDecoder(encodedString: "/foo/bar baz/test.swift:5:16 )")
		string = decoder.readLocation()
		XCTAssertEqual(string, "/foo/bar baz/test.swift:5:16")
		XCTAssertEqual(decoder.remainingBuffer, ")")

		// Declaration location
		decoder = GRYDecoder(
			encodedString: "test.(file).Bla.foo(bar:baz:).x@/foo/bar baz/test.swift:5:16  )")
		optionalString = decoder.readDeclarationLocation()
		XCTAssertEqual(
			optionalString, "test.(file).Bla.foo(bar:baz:).x@/foo/bar baz/test.swift:5:16")
		XCTAssertEqual(decoder.remainingBuffer, ")")

		decoder = GRYDecoder(
			encodedString: "(test.(file).Bla.foo(bar:baz:).x@/blah/blah blah/test.swift 4:13)")
		optionalString = decoder.readDeclarationLocation()
		XCTAssertNil(optionalString)

		// Double quoted string
		decoder = GRYDecoder(encodedString: "\"bla\" foo)")
		string = decoder.readDoubleQuotedString()
		XCTAssertEqual(string, "bla")
		XCTAssertEqual(decoder.remainingBuffer, "foo)")

		// Single quoted string
		decoder = GRYDecoder(encodedString: "'bla' foo)")
		string = decoder.readSingleQuotedString()
		XCTAssertEqual(string, "bla")
		XCTAssertEqual(decoder.remainingBuffer, "foo)")

		// String in brackets
		decoder = GRYDecoder(encodedString: "[bla] foo)")
		string = decoder.readStringInBrackets()
		XCTAssertEqual(string, "bla")
		XCTAssertEqual(decoder.remainingBuffer, "foo)")

		//
		// Test that a Swift compiler bug is being handled correctly. See `readIdentifier`'s docs.
		decoder = GRYDecoder(encodedString: "foo\nbar)")
		string = decoder.readIdentifier()
		XCTAssertEqual(string, "foobar")
		XCTAssertEqual(decoder.remainingBuffer, ")")

		decoder = GRYDecoder(encodedString: "foo\n  bar)")
		string = decoder.readIdentifier()
		XCTAssertEqual(string, "foo")
		XCTAssertEqual(decoder.remainingBuffer, "bar)")

		decoder = GRYDecoder(
			encodedString: "test.(file).Bl\na.foo(bar:baz:).x)")
		optionalString = decoder.readDeclaration()
		XCTAssertEqual(
			optionalString, "test.(file).Bla.foo(bar:baz:).x")
		XCTAssertEqual(decoder.remainingBuffer, ")")

		decoder = GRYDecoder(
			encodedString: "test.(file).Bla.foo(bar:baz:).x\n  )")
		optionalString = decoder.readDeclaration()
		XCTAssertEqual(
			optionalString, "test.(file).Bla.foo(bar:baz:).x")
		XCTAssertEqual(decoder.remainingBuffer, ")")
	}

	// MARK: - Encoding and decoding tests
	// Tests that check if the encoding and the decoding processes aren't corrupting the data.

	/// Ensure the GRYSwiftAST produced by reading Swift's AST dump is the same as the one produced
	/// from decoding the Gryphon cache file.
	func testSwiftASTDumpVersusGryphonEncoding() {
		let tests = TestUtils.allTestCases

		do {
			for testName in tests {
				print("- Testing \(testName)...")

				// Decode the AST from Swift's AST dump
				let testFilePath = TestUtils.testFilesPath + testName
				let swiftDumpAST =
					try GRYSwiftAST(decodeFromSwiftASTDumpInFile: testFilePath + .swiftASTDump)

				// Decode the AST from a Gryphon encoding
				let gryphonEncodingAST =
					try GRYSwiftAST(decodeFromFile: testFilePath + .grySwiftAST)

				// Compare the two
				XCTAssert(
					swiftDumpAST == gryphonEncodingAST,
					"Test \(testName): the coding process failed to produce expected result. Diff:"
						+ TestUtils.diff(swiftDumpAST.description, gryphonEncodingAST.description))

				print("\t- Done!")
			}
		}
		catch let error {
			XCTFail("🚨 Test failed with error:\n\(error)")
		}
	}

	func testSimpleTypesConformance() {
		let intMin = Int(Int32.min)
		let intMax = Int(Int32.max)
		let randomInt = TestUtils.rng.random(intMin..<intMax)
		let randomDouble = TestUtils.rng.randomClosed()
		let randomString = TestUtils.rng.randomString(
			fromCharacterSet: TestUtils.characterSets[TestUtils.rng.random(0..<3)],
			withLength: TestUtils.rng.random(1...10))
		// Note: the random string created above mustn't use the separator character set because
		// then we'd have to manually escape its backslashes and double quotes.

		do {
			// Encode instances into a String
			let encoder = GRYEncoder()
			encoder.startNewObject(named: "test name")

			try 0.encode(into: encoder)
			try 1.encode(into: encoder)
			try randomInt.encode(into: encoder)

			try (0.0).encode(into: encoder)
			try (0.5).encode(into: encoder)
			try (-3.2).encode(into: encoder)
			try randomDouble.encode(into: encoder)

			try true.encode(into: encoder)
			try false.encode(into: encoder)

			try "hello, world!".encode(into: encoder)
			try "escaped \\\" quotes and \\\\ backslashes".encode(into: encoder)
			try randomString.encode(into: encoder)

			try ("1" as String?).encode(into: encoder)
			try (nil as String?).encode(into: encoder)

			try [1, 2, 3].encode(into: encoder)
			try ([] as [String]).encode(into: encoder)

			try ["1": 2].encode(into: encoder)

			try TestObject(x: 0, y: 1).encode(into: encoder)

			encoder.endObject()
			let encodingResult = encoder.result
			// Decode String back into instances
			let decoder = GRYDecoder(encodedString: encodingResult)
			try decoder.readOpeningParenthesis()
			XCTAssertEqual(decoder.readDoubleQuotedString(), "test name")

			XCTAssertEqual(0, try Int.decode(from: decoder))
			XCTAssertEqual(1, try Int.decode(from: decoder))
			XCTAssertEqual(randomInt, try Int.decode(from: decoder))

			XCTAssertEqual((0.0), try Double.decode(from: decoder))
			XCTAssertEqual((0.5), try Double.decode(from: decoder))
			XCTAssertEqual((-3.2), try Double.decode(from: decoder))
			XCTAssertEqual(randomDouble, try Double.decode(from: decoder))

			XCTAssertEqual(true, try Bool.decode(from: decoder))
			XCTAssertEqual(false, try Bool.decode(from: decoder))

			XCTAssertEqual("hello, world!", try String.decode(from: decoder))
			XCTAssertEqual(
				"escaped \\\" quotes and \\\\ backslashes", try String.decode(from: decoder))
			XCTAssertEqual(randomString, try String.decode(from: decoder))

			XCTAssertEqual(("1" as String?), try String?.decode(from: decoder))
			XCTAssertEqual((nil as String?), try String?.decode(from: decoder))

			XCTAssertEqual([1, 2, 3], try [Int].decode(from: decoder))
			XCTAssertEqual(([] as [String]), try [String].decode(from: decoder))

			XCTAssertEqual(["1": 2], try [String: Int].decode(from: decoder))

			XCTAssertEqual(TestObject(x: 0, y: 1), try TestObject.decode(from: decoder))

			try decoder.readClosingParenthesis()

		}
		catch let error {
			XCTFail("🚨 Test failed with error:\n\(error)")
		}
	}

	func testGRYSwiftASTConformance() {
		let tests = TestUtils.allTestCases

		for testName in tests {

			do {
				print("- Testing \(testName)...")

				// Parse an AST from the dump file
				let testFilePath = TestUtils.testFilesPath + testName
				let expectedAST =
					try GRYSwiftAST(decodeFromSwiftASTDumpInFile: testFilePath + .swiftASTDump)

				// Encode the parsed AST into a String and then decode it back
				let encoder = GRYEncoder()
				try expectedAST.encode(into: encoder)
				let decoder = GRYDecoder(encodedString: encoder.result)
				let createdAST = try GRYSwiftAST.decode(from: decoder)

				// Compare the two
				XCTAssert(
					createdAST == expectedAST,
					"Test \(testName): the coding process failed to produce expected result. Diff:"
						+ TestUtils.diff(createdAST.description, expectedAST.description))

				print("\t- Done!")
			}
			catch let error {
				XCTFail("🚨 Test failed with error:\n\(error)")
			}
		}
	}

	func testGRYASTConformance() {
		let tests = TestUtils.allTestCases

		for testName in tests {
			do {
				print("- Testing \(testName)...")

				// Create an AST from scratch
				let testFilePath = TestUtils.testFilesPath + testName
				let expectedAST =
					try GRYCompiler.generateGryphonAST(forFileAt: testFilePath + .swift)

				// Write cached AST to file and parse it back
				let encoder = GRYEncoder()
				try expectedAST.encode(into: encoder)
				let decoder = GRYDecoder(encodedString: encoder.result)
				let createdAST = try GRYAST.decode(from: decoder)

				// Compare the two
				XCTAssert(
					createdAST == expectedAST,
					"Test \(testName): the coding process failed to produce expected result. Diff:"
						+ TestUtils.diff(createdAST.description, expectedAST.description))

				print("\t- Done!")
			}
			catch let error {
				XCTFail("🚨 Test failed with error:\n\(error)")
			}
		}
	}

	static var allTests = [
		("testDecoderCanRead", testDecoderCanRead),
		("testDecoderRead", testDecoderRead),
		("testSwiftASTDumpVersusGryphonEncoding", testSwiftASTDumpVersusGryphonEncoding),
		("testSimpleTypesConformance", testSimpleTypesConformance),
		("testGRYSwiftASTConformance", testGRYSwiftASTConformance),
		("testGRYASTConformance", testGRYASTConformance),
	]

	override static func setUp() {
		do {
			try GRYUtils.updateTestFiles()
		}
		catch let error {
			print(error)
			fatalError("Failed to update test files.")
		}
	}

	override static func tearDown() {
		XCTAssertFalse(GRYCompiler.hasErrorsOrWarnings())
		if GRYCompiler.hasErrorsOrWarnings() {
			GRYCompiler.printErrorsAndWarnings()
			GRYCompiler.clearErrorsAndWarnings()
		}
	}
}
