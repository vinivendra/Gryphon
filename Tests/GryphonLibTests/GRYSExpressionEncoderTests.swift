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

class GRYSExpressionEncoderTest: XCTestCase {
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

	func testSimpleTypes() {
		let intMin = Int(Int32.min)
		let intMax = Int(Int32.max)

		// Note: the random string can't use the separator character set because strings are assumed
		// to have all backslashes and double quotes escaped.
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

		do {
			// Encode into String
			let encoder = GRYEncoder()
			encoder.startNewObject(named: "test name")
			for testObject in tests {
				try testObject.encode(into: encoder)
			}
			encoder.endObject()
			let encodingResult = encoder.result

			// Decode back into objects
			let decoder = GRYDecoder(sExpression: encodingResult)
			decoder.readOpenParentheses()
			XCTAssertEqual(decoder.readDoubleQuotedString(), "test name")
			for testObject in tests {
				let createdObject = try type(of: testObject).decode(from: decoder)
				// Can't compare the objects themselves because we can't be sure they're the same
				// type here, so we can't use the `==` operator. Compare their types and
				// descriptions instead.
				XCTAssert(
					type(of: createdObject) == type(of: testObject),
					"Expected the type of the decoded object \(createdObject) " +
					"to be equal to the type of the original object \(testObject)")
				XCTAssert(
					String(describing: createdObject) == String(describing: testObject),
					"Expected the description of the decoded object \(createdObject) " +
					"to be equal to the description of the original object \(testObject)")
			}
			decoder.readCloseParentheses()

		}
		catch let error {
			XCTFail("Error thrown in tests: \(error)")
		}
	}

	// TODO: Handle these throws better
	func testSwiftAST() {
		let tests = TestUtils.allTestCases

		for testName in tests {
			print("- Testing \(testName)...")

			// Load a cached AST from file
			let testFilePath = TestUtils.testFilesPath + testName
			let expectedAST = GRYSwiftAst(astFile: testFilePath + .swiftAstDump)

			// Encode the cached AST into a String and then decode it back
			let encoder = GRYEncoder()
			try! expectedAST.encode(into: encoder)
			let decoder = GRYDecoder(sExpression: encoder.result)
			let createdAST = try! GRYSwiftAst.decode(from: decoder)

			// Compare the two
			XCTAssert(
				createdAST == expectedAST,
				"Test \(testName): parser failed to produce expected result. Diff:" +
					TestUtils.diff(createdAST.description, expectedAST.description))

			print("\t- Done!")
		}
	}

	func testGRYAst() {
		let tests = TestUtils.allTestCases

		for testName in tests {
			print("- Testing \(testName)...")

			// TODO: ⚠️ If we remove JSON, how do we get a reliable AST? Run the whole compiler?
			// Load a cached AST from file
			let testFilePath = TestUtils.testFilesPath + testName
			let expectedAST = GRYAst.initialize(fromJsonInFile: testFilePath + .gryAstJson)

			// Write cached AST to file and parse it back
			expectedAST.writeAsSExpression(toFile: testFilePath + .grySwiftAstSExpression)
			let createdAST = GRYAst.initialize(
				fromSExpressionInFile: testFilePath + .grySwiftAstSExpression)

			// Compare the two
			XCTAssert(
				createdAST == expectedAST,
				"Test \(testName): parser failed to produce expected result. Diff:" +
					TestUtils.diff(createdAST.description, expectedAST.description))

			print("\t- Done!")
		}
	}

	static var allTests = [
		("testSimpleTypes", testSimpleTypes),
		("testSwiftAST", testSwiftAST),
		("testGRYAst", testGRYAst),
	]

	override static func setUp() {
		try! GRYUtils.updateTestFiles()
	}
}
