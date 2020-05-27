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
			try TestUtilities.updateASTsForTestCases()
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
		for swiftVersion in TranspilationContext.supportedSwiftVersions {
			do {
				// If we're on linux, skip testing any versions that aren't the default version
				if OS.osType == .linux,
					try swiftVersion != TranspilationContext.getVersionOfToolchain(nil)
				{
					continue
				}

				guard let toolchainString =
					try TranspilationContext.getToolchain(forSwiftVersion: swiftVersion) else
				{
					print("⚠️Unable to find toolchain for Swift \(swiftVersion)")
					continue
				}

				let toolchain = (toolchainString == "") ? nil : toolchainString

				print("⛓ Using Swift \(swiftVersion)")

				Compiler.clearIssues()

				let tests = TestUtilities.testCases
				for testName in tests {
					print("- Testing \(testName)...")

					do {
						// Generate kotlin code using the whole compiler
						let testCasePath = TestUtilities.testCasesPath + testName
						let astDumpFilePath =
							SupportingFile.pathOfSwiftASTDumpFile(
								forSwiftFile: testCasePath,
								swiftVersion: swiftVersion)
						let defaultsToFinal = testName.hasSuffix("-default-final")
						let generatedKotlinCode = try Compiler.transpileKotlinCode(
							fromASTDumpFiles: [astDumpFilePath],
							withContext: TranspilationContext(
								toolchainName: toolchain,
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
				XCTAssert(
					unexpectedWarnings.isEmpty,
					"Unexpected warnings in integration tests:\n" +
					"\(unexpectedWarnings.map { $0.fullMessage }.joined(separator: "\n\n"))")

				if Compiler.numberOfErrors != 0 {
					XCTFail("🚨 Integration test found errors:\n")
					Compiler.printIssues()
				}
			}
			catch let error {
				XCTFail("Error finding toolchain for swift version \(swiftVersion): \(error)")
			}
		}
	}

	func testWarnings() {
		for swiftVersion in TranspilationContext.supportedSwiftVersions {
			do {
				guard let toolchainString =
					try TranspilationContext.getToolchain(forSwiftVersion: swiftVersion) else
				{
					print("⚠️Unable to find toolchain for Swift \(swiftVersion)")
					continue
				}

				let toolchain = (toolchainString == "") ? nil : toolchainString

				print("⛓ Using Swift \(swiftVersion)")

				Compiler.clearIssues()

				// Generate kotlin code using the whole compiler
				let testCasePath = TestUtilities.testCasesPath + "warnings"
				let astDumpFilePath =
					SupportingFile.pathOfSwiftASTDumpFile(
						forSwiftFile: testCasePath,
						swiftVersion: swiftVersion)
				_ = try Compiler.transpileKotlinCode(
					fromASTDumpFiles: [astDumpFilePath],
					withContext: TranspilationContext(
						toolchainName: toolchain,
						indentationString: "\t",
						defaultsToFinal: false)).first!

				XCTAssert(
					Compiler.numberOfErrors == 0,
					"Expected no errors, found \(Compiler.numberOfErrors):\n" +
						Compiler.issues.filter { $0.isError }.map { $0.fullMessage }
							.joined(separator: "\n"))

				// Make sure the comment for muting warnings is working
				XCTAssert(
					Compiler.numberOfWarnings == 11,
					"Expected 11 warnings, found \(Compiler.numberOfErrors):\n" +
						Compiler.issues.filter { !$0.isError }.map { $0.fullMessage }
							.joined(separator: "\n"))

				var warnings =
					Compiler.issues.filter { $0.fullMessage.contains("mutable variables") }
				XCTAssertEqual(
					warnings.count, 1,
					"Expected 1 warning containing \"mutable variables\", " +
						"found \(warnings.count) (printed below, if any).\n" +
						warnings.map { $0.fullMessage }.joined(separator: "\n"))

				warnings = Compiler.issues.filter { $0.fullMessage.contains("mutating methods") }
				XCTAssertEqual(
					warnings.count, 2,
					"Expected 2 warnings containing \"mutating methods\", " +
						"found \(warnings.count) (printed below, if any).\n" +
						warnings.map { $0.fullMessage }.joined(separator: "\n"))

				warnings = Compiler.issues.filter { $0.fullMessage.contains("Native type") }
				XCTAssertEqual(
					warnings.count, 2,
					"Expected 2 warnings containing \"Native type\", " +
						"found \(warnings.count) (printed below, if any).\n" +
						warnings.map { $0.fullMessage }.joined(separator: "\n"))

				warnings = Compiler.issues.filter { $0.fullMessage.contains("fileprivate") }
				XCTAssertEqual(
					warnings.count, 1,
					"Expected 1 warning containing \"fileprivate\", " +
						"found \(warnings.count) (printed below, if any).\n" +
						warnings.map { $0.fullMessage }.joined(separator: "\n"))

				warnings = Compiler.issues.filter { $0.fullMessage.contains("If condition") }
				XCTAssertEqual(
					warnings.count, 2,
					"Expected 2 warnings containing \"If condition\", " +
						"found \(warnings.count) (printed below, if any).\n" +
						warnings.map { $0.fullMessage }.joined(separator: "\n"))

				warnings = Compiler.issues.filter { $0.fullMessage.contains("Double optionals") }
				XCTAssertEqual(
					warnings.count, 1,
					"Expected 1 warning containing \"Double optionals\", " +
						"found \(warnings.count) (printed below, if any).\n" +
						warnings.map { $0.fullMessage }.joined(separator: "\n"))

				warnings =
					Compiler.issues.filter { $0.fullMessage.contains("superclass's initializer") }
				XCTAssertEqual(
					warnings.count, 2,
					"Expected 2 warnings containing \"superclass's initializer\", " +
						"found \(warnings.count) (printed below, if any).\n" +
						warnings.map { $0.fullMessage }.joined(separator: "\n"))
			}
			catch let error {
				XCTFail("🚨 Test failed with error:\n\(error)")
			}
		}
	}
}
