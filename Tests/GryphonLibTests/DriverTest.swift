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

// gryphon output: Bootstrap/DriverTest.kt

#if !GRYPHON
@testable import GryphonLib
import XCTest
#endif

// gryphon insert: import kotlin.system.exitProcess

class DriverTest: XCTestCase {
	// gryphon insert: constructor(): super() { }

	public func getClassName() -> String { // gryphon annotation: override
		return "DriverTest"
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
		DriverTest.setUp()
		testUsageString()
		testNoMainFile()
		testContinueOnErrors()
		testIndentation()
	}

	/// Tests to be run when using Swift on Linux
	static var allTests = [ // gryphon ignore
		("testUsageString", testUsageString),
		("testNoMainFile", testNoMainFile),
		("testContinueOnErrors", testContinueOnErrors),
		("testIndentation", testIndentation),
	]

	// MARK: - Tests
	func testUsageString() {
		for argument in Driver.supportedArguments {
			XCTAssert(
				Driver.usageString.contains(argument),
				"No help information for the argument \(argument)")
		}

		for argument in Driver.supportedArgumentsWithParameters {
			XCTAssert(
				Driver.usageString.contains(argument),
				"No help information for the argument \(argument)")
		}
	}

	func testNoMainFile() {
		do {
			let testCasePath = TestUtilities.testCasesPath + "classes.swift"

			//
			let driverResult1 = try Driver.run(withArguments:
				["-skipASTDumps",
				 "-emit-kotlin",
				 "--indentation=t",
				 "--write-to-console",
				 testCasePath, ])
			let resultArray1 = driverResult1 as? List<Any?>
			let kotlinTranslations1 = resultArray1?.as(List<Driver.KotlinTranslation>.self)

			guard let kotlinTranslation1 = kotlinTranslations1?.first else {
				XCTFail("Error generating Kotlin code.\n" +
					"Driver result: \(driverResult1 ?? "nil")")
				return
			}

			let kotlinCode1 = kotlinTranslation1.kotlinCode

			XCTAssert(kotlinCode1.contains("fun main(args: Array<String>) {"))

			//
			let driverResult2 = try Driver.run(withArguments:
				["-skipASTDumps",
				 "-emit-kotlin",
				 "--indentation=t",
				 "--no-main-file",
				 "--write-to-console",
				 testCasePath, ])
			let resultArray2 = driverResult2 as? List<Any?>
			let kotlinTranslations2 = resultArray2?.as(List<Driver.KotlinTranslation>.self)

			guard let kotlinTranslation2 = kotlinTranslations2?.first else {
				XCTFail("Error generating Kotlin code.\n" +
					"Driver result: \(driverResult2 ?? "nil")")
				return
			}

			let kotlinCode2 = kotlinTranslation2.kotlinCode

			XCTAssertFalse(kotlinCode2.contains("fun main(args: Array<String>) {"))

		}
		catch let error {
			XCTFail("🚨 Test failed with error:\n\(error)")
		}

		XCTAssertFalse(Compiler.hasIssues())
		Compiler.printErrorsAndWarnings()
	}

	func testContinueOnErrors() {
		do {
			let testCasePath = TestUtilities.testCasesPath + "errors.swift"

			//
			Compiler.clearIssues()

			_ = try Driver.run(withArguments:
				["-skipASTDumps",
				 "-emit-kotlin",
				 "--indentation=t",
				 "--continue-on-error",
				 "--write-to-console",
				 testCasePath, ])

			XCTAssert(Compiler.numberOfErrors == 2)

			//
			Compiler.clearIssues()

			_ = try Driver.run(withArguments:
				["-skipASTDumps",
				 "-emit-kotlin",
				 "--indentation=t",
				 "--no-main-file",
				 "--write-to-console",
				 testCasePath, ])

			XCTFail("Expected Driver to throw an error.")
		}
		catch {
			// If the Driver threw an error then it's working correctly.
		}

		Compiler.clearIssues()
	}

	func testIndentation() {
		do {
			let testCasePath = TestUtilities.testCasesPath + "classes.swift"

			//
			let driverResult1 = try Driver.run(withArguments:
				["-skipASTDumps",
				 "-emit-kotlin",
				 "--indentation=t",
				 "--write-to-console",
				 testCasePath, ])
			let resultArray1 = driverResult1 as? List<Any?>
			let kotlinTranslations1 = resultArray1?.as(List<Driver.KotlinTranslation>.self)

			guard let kotlinTranslation1 = kotlinTranslations1?.first else {
				XCTFail("Error generating Kotlin code.\n" +
					"Driver result: \(driverResult1 ?? "nil")")
				return
			}

			let kotlinCode1 = kotlinTranslation1.kotlinCode

			XCTAssert(kotlinCode1.contains("\t"))
			XCTAssertFalse(kotlinCode1.contains("    "))

			//
			let driverResult2 = try Driver.run(withArguments:
				["-skipASTDumps",
				 "-emit-kotlin",
				 "--indentation=4",
				 "--write-to-console",
				 testCasePath, ])
			let resultArray2 = driverResult2 as? List<Any?>
			let kotlinTranslations2 = resultArray2?.as(List<Driver.KotlinTranslation>.self)

			guard let kotlinTranslation2 = kotlinTranslations2?.first else {
				XCTFail("Error generating Kotlin code.\n" +
					"Driver result: \(driverResult2 ?? "nil")")
				return
			}

			let kotlinCode2 = kotlinTranslation2.kotlinCode

			XCTAssert(kotlinCode2.contains("    "))
			XCTAssertFalse(kotlinCode2.contains("\t"))

		}
		catch let error {
			XCTFail("🚨 Test failed with error:\n\(error)")
		}

		XCTAssertFalse(Compiler.hasIssues())
		Compiler.printErrorsAndWarnings()
	}
}
