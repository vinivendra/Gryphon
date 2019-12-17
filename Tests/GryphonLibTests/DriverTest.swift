//
// Copyright 2018 Vinícius Jorge Vendramini
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

#if !IS_DUMPING_ASTS
@testable import GryphonLib
import XCTest
#endif

class DriverTest: XCTestCase {
	// declaration: constructor(): super() { }

	public func getClassName() -> String { // annotation: override
		return "DriverTest"
	}

	override public func runAllTests() { // annotation: override
		testUsageString()
		testNoMainFile()
		testContinueOnErrors()
		testIndentation()
	}

	static var allTests = [ // kotlin: ignore
		("testUsageString", testUsageString),
		("testNoMainFile", testNoMainFile),
		("testContinueOnErrors", testContinueOnErrors),
		("testIndentation", testIndentation),
	]

	// MARK: - Tests
	func testUsageString() {
		for argument in Driver.supportedArguments {
			XCTAssert(Driver.usageString.contains(argument))
		}

		for argument in Driver.supportedArgumentsWithParameters {
			XCTAssert(Driver.usageString.contains(argument))
		}
	}

	func testNoMainFile() {
		do {
			let testFilePath = TestUtilities.testFilesPath + "arrays.swift"

			//
			let driverResult1 = try Driver.run(withArguments:
				["-skipASTDumps",
				 "-emit-kotlin",
				 "-indentation=t",
				 "-q", "-Q",
				 testFilePath, ])
			let resultArray1 = driverResult1 as? MutableList<Any?>
			let kotlinTranslations1 = resultArray1?.as(MutableList<Driver.KotlinTranslation>.self)

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
				 "-indentation=t",
				 "-no-main-file",
				 "-q", "-Q",
				 testFilePath, ])
			let resultArray2 = driverResult2 as? MutableList<Any?>
			let kotlinTranslations2 = resultArray2?.as(MutableList<Driver.KotlinTranslation>.self)

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

		XCTAssertFalse(Compiler.hasErrorsOrWarnings())
		Compiler.printErrorsAndWarnings()
	}

	func testContinueOnErrors() {
		do {
			let testFilePath = TestUtilities.testFilesPath + "errors.swift"

			//
			Compiler.clearErrorsAndWarnings()

			_ = try Driver.run(withArguments:
				["-skipASTDumps",
				 "-emit-kotlin",
				 "-indentation=t",
				 "-continue-on-error",
				 "-q", "-Q",
				 testFilePath, ])

			XCTAssert(Compiler.errors.count == 2)

			//
			Compiler.clearErrorsAndWarnings()

			_ = try Driver.run(withArguments:
				["-skipASTDumps",
				 "-emit-kotlin",
				 "-indentation=t",
				 "-no-main-file",
				 "-q", "-Q",
				 testFilePath, ])

			XCTFail("Expected Driver to throw an error.")
		}
		catch {
			// If the Driver threw an error then it's working correctly.
		}

		Compiler.clearErrorsAndWarnings()
	}

	func testIndentation() {
		do {
			let testFilePath = TestUtilities.testFilesPath + "arrays.swift"

			//
			let driverResult1 = try Driver.run(withArguments:
				["-skipASTDumps",
				 "-emit-kotlin",
				 "-indentation=t",
				 "-q", "-Q",
				 testFilePath, ])
			let resultArray1 = driverResult1 as? MutableList<Any?>
			let kotlinTranslations1 = resultArray1?.as(MutableList<Driver.KotlinTranslation>.self)

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
				 "-indentation=4",
				 "-q", "-Q",
				 testFilePath, ])
			let resultArray2 = driverResult2 as? MutableList<Any?>
			let kotlinTranslations2 = resultArray2?.as(MutableList<Driver.KotlinTranslation>.self)

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

		XCTAssertFalse(Compiler.hasErrorsOrWarnings())
		Compiler.printErrorsAndWarnings()
	}
}
