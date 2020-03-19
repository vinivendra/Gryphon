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
		let tests = TestUtilities.testCases

		let astDumpContents: List<String> = tests.map { testName in
			let testCasePath = TestUtilities.testCasesPath + testName
			let astDumpFilePath = SupportingFile.pathOfSwiftASTDumpFile(forSwiftFile: testCasePath)
			return try! String(contentsOfFile: astDumpFilePath)
		}

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
		let tests = TestUtilities.testCases

		let swiftASTs: List<SwiftAST> = tests.map { testName in
			let testCasePath = TestUtilities.testCasesPath + testName
			let astDumpFilePath = SupportingFile.pathOfSwiftASTDumpFile(forSwiftFile: testCasePath)
			return try! Compiler.transpileSwiftAST(fromASTDumpFile: astDumpFilePath)
		}

		measure {
			for swiftASTs in swiftASTs {
				do {
					_ = try Compiler.generateGryphonRawAST(
						fromSwiftAST: swiftASTs,
						asMainFile: false,
						withContext: TranspilationContext(
							indentationString: "\t",
							defaultFinal: false))
				}
				catch let error {
					XCTFail("🚨 Test failed with error:\n\(error)")
				}
			}
		}
	}

	func testFirstTranspilationPasses() {
		let tests = TestUtilities.testCases

		let astDumpFilePaths: List<String> = tests.map { testName in
			let testCasePath = TestUtilities.testCasesPath + testName
			return SupportingFile.pathOfSwiftASTDumpFile(forSwiftFile: testCasePath)
		}

		let rawASTs = try! Compiler.transpileGryphonRawASTs(
			fromASTDumpFiles: astDumpFilePaths,
			withContext: TranspilationContext(
				indentationString: "\t",
				defaultFinal: false))

		measure {
			for rawAST in rawASTs {
				do {
					_ = try Compiler.generateGryphonASTAfterFirstPasses(
						fromGryphonRawAST: rawAST,
						withContext: TranspilationContext(
							indentationString: "\t",
							defaultFinal: false))
				}
				catch let error {
					XCTFail("🚨 Test failed with error:\n\(error)")
				}
			}
		}
	}

	func testSecondTranspilationPasses() {
		let tests = TestUtilities.testCases

		let astDumpFilePaths: List<String> = tests.map { testName in
			let testCasePath = TestUtilities.testCasesPath + testName
			return SupportingFile.pathOfSwiftASTDumpFile(forSwiftFile: testCasePath)
		}

		let context = TranspilationContext(indentationString: "\t", defaultFinal: false)
		let semiRawASTs = try! Compiler.transpileGryphonRawASTs(
			fromASTDumpFiles: astDumpFilePaths,
			withContext: context)
			.map {
				try! Compiler.generateGryphonASTAfterFirstPasses(
					fromGryphonRawAST: $0,
					withContext: context)
			}

		measure {
			for semiRawAST in semiRawASTs {
				do {
					_ = try Compiler.generateGryphonASTAfterSecondPasses(
						fromGryphonRawAST: semiRawAST,
						withContext: TranspilationContext(
							indentationString: "\t",
							defaultFinal: false))
				}
				catch let error {
					XCTFail("🚨 Test failed with error:\n\(error)")
				}
			}
		}
	}

	func testAllTranspilationPasses() {
		let tests = TestUtilities.testCases

		let astDumpFilePaths: List<String> = tests.map { testName in
			let testCasePath = TestUtilities.testCasesPath + testName
			return SupportingFile.pathOfSwiftASTDumpFile(forSwiftFile: testCasePath)
		}

		let rawASTs = try! Compiler.transpileGryphonRawASTs(
			fromASTDumpFiles: astDumpFilePaths,
			withContext: TranspilationContext(
				indentationString: "\t",
				defaultFinal: false))

		measure {
			for rawAST in rawASTs {
				do {
					_ = try Compiler.generateGryphonAST(
						fromGryphonRawAST: rawAST,
						withContext: TranspilationContext(
							indentationString: "\t",
							defaultFinal: false))
				}
				catch let error {
					XCTFail("🚨 Test failed with error:\n\(error)")
				}
			}
		}
	}

	func testKotlinTranslator() {
		let tests = TestUtilities.testCases

		let astsAndContexts: List<(GryphonAST, TranspilationContext)> = tests.map
			{ testName in
				let testCasePath = TestUtilities.testCasesPath + testName
				let astDumpFilePath =
					SupportingFile.pathOfSwiftASTDumpFile(forSwiftFile: testCasePath)
				let context = TranspilationContext(indentationString: "\t", defaultFinal: false)
				let ast = try! Compiler.transpileGryphonASTs(
					fromASTDumpFiles: [astDumpFilePath],
					withContext: context).first!
				return (ast, context)
			}

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
		let tests = TestUtilities.testCases

		measure {
			for testName in tests {
				do {
					let testCasePath = TestUtilities.testCasesPath + testName
					let astDumpFilePath = SupportingFile.pathOfSwiftASTDumpFile(
						forSwiftFile: testCasePath)
					_ = try Compiler.transpileKotlinCode(
						fromASTDumpFiles: [astDumpFilePath],
						withContext: TranspilationContext(
							indentationString: "\t",
							defaultFinal: false))
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
			try TestUtilities.updateASTsForTestCases()
		}
		catch let error {
			print(error)
			fatalError("Failed to update test files.")
		}
	}
}
