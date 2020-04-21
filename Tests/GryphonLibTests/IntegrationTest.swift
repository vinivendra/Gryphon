//
// Copyright 2018 Vinicius Jorge Vendramini
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

// gryphon output: Bootstrap/IntegrationTest.kt

#if !GRYPHON
@testable import GryphonLib
import XCTest
#endif

// gryphon insert: import kotlin.system.exitProcess

class IntegrationTest: XCTestCase {
	// gryphon insert: constructor(): super() { }

	public func getClassName() -> String { // gryphon annotation: override
		return "IntegrationTest"
	}

	override static func setUp() {
		do {
			try TestUtilities.updateASTsForTestCases(usingToolchain: nil)
		}
		catch let error {
			print(error)
			fatalError("Failed to update test files.")
		}
	}

	/// Tests to be run by the translated Kotlin version.
	public func runAllTests() { // gryphon annotation: override
		IntegrationTest.setUp()
		test()
		testWarnings()
	}

	/// Tests to be run when using Swift on Linux
	static var allTests = [ // gryphon ignore
		("test", test),
		("testWarnings", testWarnings),
	]

	// MARK: - Tests
	func test() {
			let tests = TestUtilities.testCases
			for testName in tests {
				print("- Testing \(testName)...")

				do {
					// Generate kotlin code using the whole compiler
					let testCasePath = TestUtilities.testCasesPath + testName
					let astDumpFilePath =
						SupportingFile.pathOfSwiftASTDumpFile(
							forSwiftFile: testCasePath,
							swiftVersion: "5.2")
					let defaultsToFinal = testName.hasSuffix("-default-final")
					let generatedKotlinCode = try Compiler.transpileKotlinCode(
						fromASTDumpFiles: [astDumpFilePath],
						withContext: TranspilationContext(
							toolchainName: nil,
							indentationString: "\t",
							defaultsToFinal: defaultsToFinal)).first!

					// Load the previously stored kotlin code from file
					let expectedKotlinCode =
						try! Utilities.readFile(testCasePath.withExtension(.kt))

					XCTAssert(
						generatedKotlinCode == expectedKotlinCode,
						"Test \(testName): the transpiler failed to produce expected result. " +
							"Printing diff ('<' means generated, '>' means expected):" +
							TestUtilities.diff(generatedKotlinCode, expectedKotlinCode))

					print("\t- Done!")
				}
				catch let error {
					XCTFail("🚨 Test failed with error:\n\(error)")
				}
			}

			let unexpectedWarnings = Compiler.issues.filter {
					!$0.isError &&
					!$0.fullMessage.contains("Native type") &&
					!$0.fullMessage.contains("fileprivate declarations")
				}
			XCTAssert(unexpectedWarnings.isEmpty, "Unexpected warnings in integration tests:\n" +
				"\(unexpectedWarnings.map { $0.fullMessage }.joined(separator: "\n\n"))")

			if Compiler.numberOfErrors != 0 {
				XCTFail("🚨 Integration test found errors:\n")
				Compiler.printErrorsAndWarnings()
			}
	}

	func testWarnings() {
		do {
			Compiler.clearIssues()

			// Generate kotlin code using the whole compiler
			let testCasePath = TestUtilities.testCasesPath + "warnings"
			let astDumpFilePath =
				SupportingFile.pathOfSwiftASTDumpFile(
					forSwiftFile: testCasePath,
					swiftVersion: "5.2")
			_ = try Compiler.transpileKotlinCode(
				fromASTDumpFiles: [astDumpFilePath],
				withContext: TranspilationContext(
					toolchainName: nil,
					indentationString: "\t",
					defaultsToFinal: false)).first!

			Compiler.printErrorsAndWarnings()

			XCTAssert(Compiler.numberOfErrors == 0)

			// Make sure the comment for muting warnings is working
			XCTAssert(Compiler.numberOfWarnings == 11)

			XCTAssertEqual(
				Compiler.issues.filter { $0.fullMessage.contains("mutable variables") }.count,
				1)
			XCTAssertEqual(
				Compiler.issues.filter { $0.fullMessage.contains("mutating methods") }.count,
				2)
			XCTAssertEqual(
				Compiler.issues.filter { $0.fullMessage.contains("Native type") }.count,
				2)
			XCTAssertEqual(
				Compiler.issues.filter { $0.fullMessage.contains("fileprivate") }.count,
				1)
			XCTAssertEqual(
				Compiler.issues.filter { $0.fullMessage.contains("If condition") }.count,
				2)
			XCTAssertEqual(
				Compiler.issues.filter { $0.fullMessage.contains("Double optionals") }.count,
				1)
			XCTAssertEqual(
				Compiler.issues.filter
					{ $0.fullMessage.contains("superclass's initializer") }.count,
				2)
		}
		catch let error {
			XCTFail("🚨 Test failed with error:\n\(error)")
		}
	}
}
