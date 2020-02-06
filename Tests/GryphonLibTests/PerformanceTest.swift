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

@testable import GryphonLib
import XCTest

class PerformanceTest: XCTestCase {
	func testASTDumpDecoder() {
		let tests = TestUtilities.testCasesForAllTests

		let astDumpContents: MutableList<String> = tests.map { testName in
			let testFilePath = TestUtilities.testFilesPath + testName
			let astDumpFilePath = Utilities.pathOfSwiftASTDumpFile(forSwiftFile: testFilePath)
			return try! String(contentsOfFile: astDumpFilePath)
		}.toMutableList()

		measure {
			for astDump in astDumpContents {
				do {
					_ = try Compiler.generateSwiftAST(fromASTDump: astDump)
				}
				catch let error {
					XCTFail("🚨 Test failed with error:\n\(error)")
				}
			}
		}
	}

	func testSwiftTranslator() {
		let tests = TestUtilities.testCasesForAllTests

		let swiftASTs: MutableList<SwiftAST> = tests.map { testName in
			let testFilePath = TestUtilities.testFilesPath + testName
			let astDumpFilePath = Utilities.pathOfSwiftASTDumpFile(forSwiftFile: testFilePath)
			return try! Compiler.transpileSwiftAST(fromASTDumpFile: astDumpFilePath)
		}.toMutableList()

		measure {
			for swiftASTs in swiftASTs {
				do {
					_ = try Compiler.generateGryphonRawAST(
						fromSwiftAST: swiftASTs,
						asMainFile: false)
				}
				catch let error {
					XCTFail("🚨 Test failed with error:\n\(error)")
				}
			}
		}
	}

	func testFirstTranspilationPasses() {
		let tests = TestUtilities.testCasesForAllTests

		let astDumpFilePaths: MutableList<String> = tests.map { testName in
			let testFilePath = TestUtilities.testFilesPath + testName
			return Utilities.pathOfSwiftASTDumpFile(forSwiftFile: testFilePath)
		}.toMutableList()

		let rawASTs = try! Compiler.transpileGryphonRawASTs(fromASTDumpFiles: astDumpFilePaths)

		measure {
			for rawAST in rawASTs {
				do {
					_ = try Compiler.generateGryphonASTAfterFirstPasses(
						fromGryphonRawAST: rawAST,
						withContext: TranspilationContext(indentationString: "\t"))
				}
				catch let error {
					XCTFail("🚨 Test failed with error:\n\(error)")
				}
			}
		}
	}

	func testSecondTranspilationPasses() {
		let tests = TestUtilities.testCasesForAllTests

		let astDumpFilePaths: MutableList<String> = tests.map { testName in
			let testFilePath = TestUtilities.testFilesPath + testName
			return Utilities.pathOfSwiftASTDumpFile(forSwiftFile: testFilePath)
		}.toMutableList()

		let semiRawASTs =
			try! Compiler.transpileGryphonRawASTs(fromASTDumpFiles: astDumpFilePaths).map {
				try! Compiler.generateGryphonASTAfterFirstPasses(
					fromGryphonRawAST: $0,
					withContext: TranspilationContext(indentationString: "\t"))
			}

		measure {
			for semiRawAST in semiRawASTs {
				do {
					_ = try Compiler.generateGryphonASTAfterSecondPasses(
						fromGryphonRawAST: semiRawAST,
						withContext: TranspilationContext(indentationString: "\t"))
				}
				catch let error {
					XCTFail("🚨 Test failed with error:\n\(error)")
				}
			}
		}
	}

	func testAllTranspilationPasses() {
		let tests = TestUtilities.testCasesForAllTests

		let astDumpFilePaths: MutableList<String> = tests.map { testName in
			let testFilePath = TestUtilities.testFilesPath + testName
			return Utilities.pathOfSwiftASTDumpFile(forSwiftFile: testFilePath)
		}.toMutableList()

		let rawASTs = try! Compiler.transpileGryphonRawASTs(fromASTDumpFiles: astDumpFilePaths)

		measure {
			for rawAST in rawASTs {
				do {
					_ = try Compiler.generateGryphonAST(
						fromGryphonRawAST: rawAST,
						withContext: TranspilationContext(indentationString: "\t"))
				}
				catch let error {
					XCTFail("🚨 Test failed with error:\n\(error)")
				}
			}
		}
	}

	func testKotlinTranslator() {
		let tests = TestUtilities.testCasesForAllTests

		let astsAndContexts: MutableList<(GryphonAST, TranspilationContext)> = tests.map
			{ testName in
				let testFilePath = TestUtilities.testFilesPath + testName
				let astDumpFilePath = Utilities.pathOfSwiftASTDumpFile(forSwiftFile: testFilePath)
				let context = TranspilationContext(indentationString: "\t")
				let ast = try! Compiler.transpileGryphonASTs(
					fromASTDumpFiles: [astDumpFilePath],
					withContext: context).first!
				return (ast, context)
			}.toMutableList()

		measure {
			for astAndContext in astsAndContexts {
				do {
					let (ast, context) = astAndContext
					_ = try Compiler.generateKotlinCode(
						fromGryphonAST: ast,
						withContext: context)
				}
				catch let error {
					XCTFail("🚨 Test failed with error:\n\(error)")
				}
			}
		}
	}

	func testFullTranspilation() {
		let tests = TestUtilities.testCasesForAllTests

		measure {
			for testName in tests {
				do {
					let testFilePath = TestUtilities.testFilesPath + testName
					let astDumpFilePath = Utilities.pathOfSwiftASTDumpFile(
						forSwiftFile: testFilePath)
					_ = try Compiler.transpileKotlinCode(
						fromASTDumpFiles: [astDumpFilePath],
						withContext: TranspilationContext(indentationString: "\t"))
				}
				catch let error {
					XCTFail("🚨 Test failed with error:\n\(error)")
				}
			}
		}
	}

	static var allTests = [
		("testASTDumpDecoder", testASTDumpDecoder),
		("testSwiftTranslator", testSwiftTranslator),
		("testFirstTranspilationPasses", testFirstTranspilationPasses),
		("testSecondTranspilationPasses", testSecondTranspilationPasses),
		("testAllTranspilationPasses", testAllTranspilationPasses),
		("testKotlinTranslator", testKotlinTranslator),
		("testFullTranspilation", testFullTranspilation),
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
}
