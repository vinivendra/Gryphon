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

@testable import GryphonLib
import XCTest

class DriverTest: XCTestCase {
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
			let testFilePath = TestUtils.testFilesPath + "arrays.swift"

			//
			let driverResult1 = try Driver.run(withArguments:
				["-skipASTDumps",
				 "-emit-kotlin",
				 "-indentation=t",
				 "-q", "-Q",
				 testFilePath, ])
			guard let resultArray1 = driverResult1 as? MutableArray<Any?>,
				let kotlinCodes1 = resultArray1
					.as(MutableArray<Driver.KotlinTranslation>.self)?
					.map({ $0.kotlinCode }),
				let kotlinCode1 = kotlinCodes1.first else
			{
				XCTFail("Error generating Kotlin code.\n" +
					"Driver result: \(driverResult1 ?? "nil")")
				return
			}

			XCTAssert(kotlinCode1.contains("fun main(args: Array<String>) {"))

			//
			let driverResult2 = try Driver.run(withArguments:
				["-skipASTDumps",
				 "-emit-kotlin",
				 "-indentation=t",
				 "-no-main-file",
				 "-q", "-Q",
				 testFilePath, ])
			guard let resultArray2 = driverResult2 as? MutableArray<Any?>,
				let kotlinCodes2 = resultArray2
					.as(MutableArray<Driver.KotlinTranslation>.self)?
					.map({ $0.kotlinCode }),
				let kotlinCode2 = kotlinCodes2.first else
			{
				XCTFail("Error generating Kotlin code.\n" +
					"Driver result: \(driverResult2 ?? "nil")")
				return
			}

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
			let testFilePath = TestUtils.testFilesPath + "errors.swift"

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
			let testFilePath = TestUtils.testFilesPath + "arrays.swift"

			//
			let driverResult1 = try Driver.run(withArguments:
				["-skipASTDumps",
				 "-emit-kotlin",
				 "-indentation=t",
				 "-q", "-Q",
				 testFilePath, ])
			guard let resultArray1 = driverResult1 as? MutableArray<Any?>,
				let kotlinCodes1 = resultArray1
					.as(MutableArray<Driver.KotlinTranslation>.self)?
					.map({ $0.kotlinCode }),
				let kotlinCode1 = kotlinCodes1.first else
			{
				XCTFail("Error generating Kotlin code.\n" +
					"Driver result: \(driverResult1 ?? "nil")")
				return
			}

			XCTAssert(kotlinCode1.contains("\t"))
			XCTAssertFalse(kotlinCode1.contains("    "))

			//
			let driverResult2 = try Driver.run(withArguments:
				["-skipASTDumps",
				 "-emit-kotlin",
				 "-indentation=4",
				 "-q", "-Q",
				 testFilePath, ])
			guard let resultArray2 = driverResult2 as? MutableArray<Any?>,
				let kotlinCodes2 = resultArray2
					.as(MutableArray<Driver.KotlinTranslation>.self)?
					.map({ $0.kotlinCode }),
				let kotlinCode2 = kotlinCodes2.first else
			{
				XCTFail("Error generating Kotlin code.\n" +
					"Driver result: \(driverResult2 ?? "nil")")
				return
			}

			XCTAssert(kotlinCode2.contains("    "))
			XCTAssertFalse(kotlinCode2.contains("\t"))

		}
		catch let error {
			XCTFail("🚨 Test failed with error:\n\(error)")
		}

		XCTAssertFalse(Compiler.hasErrorsOrWarnings())
		Compiler.printErrorsAndWarnings()
	}

	static var allTests = [
		("testUsageString", testUsageString),
		("testNoMainFile", testNoMainFile),
		("testContinueOnErrors", testContinueOnErrors),
		("testIndentation", testIndentation),
	]
}
