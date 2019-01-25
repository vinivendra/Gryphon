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

// TODO: Change all `Ast`s into `AST`s
class GRYCodableTest: XCTestCase {
	struct TestObject: GRYCodable {
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

	func testDecoderRead() {
		var decoder: GRYDecoder
		var string: String
		var optionalString: String?

		// Open parentheses
		decoder = GRYDecoder(encodedString: "(foo")
		XCTAssertNoThrow(try decoder.readOpenParentheses())
		XCTAssertEqual(decoder.remainingBuffer, "foo")

		// Close parentheses
		decoder = GRYDecoder(encodedString: ") foo")
		XCTAssertNoThrow(try decoder.readCloseParentheses())
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
					try GRYSwiftAst(decodeFromSwiftASTDumpInFile: testFilePath + .swiftAstDump)

				// Decode the AST from a Gryphon encoding
				let gryphonEncodingAST =
					try GRYSwiftAst(decodeFromFile: testFilePath + .grySwiftAst)

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

		let tests: [GRYCodable] = [
			0, 1, 2, -3,
			0.0, 0.5, 1.0, -3.2,
			true, false,
			"hello, world!", "escaped \\\" quotes and \\\\ backslashes", "",
			"1" as String?, nil as String?,
			1 as Int?, nil as Int?,
			1.0 as Double?, nil as Double?,
			[1, 2, 3],
			[] as [String],
			[1: 2],
			["1": 2, "3": 4],
			[:] as [String: String],
			TestObject(x: 0, y: 1),
			TestUtils.rng.random(intMin..<intMax),
			TestUtils.rng.random(intMin..<intMax),
			TestUtils.rng.randomClosed(), TestUtils.rng.randomClosed(),
			TestUtils.rng.randomBool(),
			TestUtils.rng.randomString(
				fromCharacterSet: TestUtils.characterSets[TestUtils.rng.random(0..<3)],
				withLength: TestUtils.rng.random(1...10)),
		]
		// Note: the random string created above mustn't use the separator character set because
		// then we'd have to manually escape its backslashes and double quotes.

		do {
			// Encode instances into a String
			let encoder = GRYEncoder()
			encoder.startNewObject(named: "test name")
			for testObject in tests {
				try testObject.encode(into: encoder)
			}
			encoder.endObject()
			let encodingResult = encoder.result

			// Decode String back into instances
			let decoder = GRYDecoder(encodedString: encodingResult)
			try decoder.readOpenParentheses()
			XCTAssertEqual(decoder.readDoubleQuotedString(), "test name")
			for testInstance in tests {
				let createdInstance = try type(of: testInstance).decode(from: decoder)
				// We can't compare the instances themselves directly because we can't be sure
				// they're the same type here, so there's no way to use the `==` operator. We
				// compare their types and descriptions instead.
				XCTAssert(
					type(of: createdInstance) == type(of: testInstance),
					"Expected the type of the decoded object \(createdInstance) " +
					"to be equal to the type of the original object \(testInstance)")
				XCTAssert(
					String(describing: createdInstance) == String(describing: testInstance),
					"Expected the description of the decoded object \(createdInstance) " +
					"to be equal to the description of the original object \(testInstance)")
			}
			try decoder.readCloseParentheses()

		}
		catch let error {
			XCTFail("🚨 Test failed with error:\n\(error)")
		}
	}

	func testGRYSwiftAstConformance() {
		let tests = TestUtils.allTestCases

		for testName in tests {

			do {
				print("- Testing \(testName)...")

				// Parse an AST from the dump file
				let testFilePath = TestUtils.testFilesPath + testName
				let expectedAST =
					try GRYSwiftAst(decodeFromSwiftASTDumpInFile: testFilePath + .swiftAstDump)

				// Encode the parsed AST into a String and then decode it back
				let encoder = GRYEncoder()
				try expectedAST.encode(into: encoder)
				let decoder = GRYDecoder(encodedString: encoder.result)
				let createdAST = try GRYSwiftAst.decode(from: decoder)

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

	func testGRYAstConformance() {
		let tests = TestUtils.allTestCases

		for testName in tests {
			do {
				print("- Testing \(testName)...")

				// Create an AST from scratch
				let testFilePath = TestUtils.testFilesPath + testName
				let expectedAST =
					try GRYCompiler.generateGryphonAst(forFileAt: testFilePath + .swift)

				// Write cached AST to file and parse it back
				let encoder = GRYEncoder()
				try expectedAST.encode(into: encoder)
				let decoder = GRYDecoder(encodedString: encoder.result)
				let createdAST = try GRYAst.decode(from: decoder)

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
		("testGRYSwiftAstConformance", testGRYSwiftAstConformance),
		("testGRYAstConformance", testGRYAstConformance),
	]

	override static func setUp() {
		try! GRYUtils.updateTestFiles()
	}
}
