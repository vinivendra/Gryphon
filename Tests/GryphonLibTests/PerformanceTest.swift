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

@testable import GryphonLib
import XCTest

class PerformanceTest: XCTestCase {
	static let toolchain: String? = nil
	static let swiftVersion: String = try! TranspilationContext.getVersionOfToolchain(toolchain)

	func testASTDumpDecoder() {
		let tests = TestUtilities.testCases

		let astDumpContents: List<String> = tests.map { testName in
			let testCasePath = TestUtilities.testCasesPath + testName
			let astDumpFilePath = SupportingFile.pathOfSwiftASTDumpFile(
				forSwiftFile: testCasePath,
				swiftVersion: PerformanceTest.swiftVersion)
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
			let astDumpFilePath = SupportingFile.pathOfSwiftASTDumpFile(
				forSwiftFile: testCasePath,
				swiftVersion: PerformanceTest.swiftVersion)
			return try! Compiler.transpileSwiftAST(fromASTDumpFile: astDumpFilePath)
		}

		measure {
			for swiftASTs in swiftASTs {
				do {
					_ = try Compiler.generateGryphonRawAST(
						fromSwiftAST: swiftASTs,
						asMainFile: false,
						withContext: TranspilationContext(
							toolchainName: PerformanceTest.toolchain,
							indentationString: "\t",
							defaultsToFinal: false))
				}
				catch let error {
					XCTFail("🚨 Test failed with error:\n\(error)")
				}
			}
		}
	}

	func testFirstTranspilationPasses() {
		let tests = TestUtilities.testCases

		let testCasePaths = tests.map {
			TestUtilities.testCasesPath + $0
		}
		let astDumpFilePaths: List<String> = testCasePaths.map {
			return SupportingFile.pathOfSwiftASTDumpFile(
				forSwiftFile: $0,
				swiftVersion: PerformanceTest.swiftVersion)
		}

		let rawASTs = try! Compiler.transpileGryphonRawASTs(
			fromInputFiles: testCasePaths,
			fromASTDumpFiles: astDumpFilePaths,
			withContext: TranspilationContext(
				toolchainName: PerformanceTest.toolchain,
				indentationString: "\t",
				defaultsToFinal: false),
			usingSwiftSyntax: true)

		measure {
			for rawAST in rawASTs {
				do {
					_ = try Compiler.generateGryphonASTAfterFirstPasses(
						fromGryphonRawAST: rawAST,
						withContext: TranspilationContext(
							toolchainName: PerformanceTest.toolchain,
							indentationString: "\t",
							defaultsToFinal: false))
				}
				catch let error {
					XCTFail("🚨 Test failed with error:\n\(error)")
				}
			}
		}
	}

	func testSecondTranspilationPasses() {
		do {
			let tests = TestUtilities.testCases

			let testCasePaths = tests.map {
				TestUtilities.testCasesPath + $0
			}
			let astDumpFilePaths: List<String> = tests.map { testName in
				let testCasePath = TestUtilities.testCasesPath + testName
				return SupportingFile.pathOfSwiftASTDumpFile(
					forSwiftFile: testCasePath,
					swiftVersion: PerformanceTest.swiftVersion)
			}

			let context = try TranspilationContext(
				toolchainName: PerformanceTest.toolchain,
				indentationString: "\t",
				defaultsToFinal: false)
			let semiRawASTs = try! Compiler.transpileGryphonRawASTs(
				fromInputFiles: testCasePaths,
				fromASTDumpFiles: astDumpFilePaths,
				withContext: context,
				usingSwiftSyntax: false)
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
								toolchainName: PerformanceTest.toolchain,
								indentationString: "\t",
								defaultsToFinal: false))
					}
					catch let error {
						XCTFail("🚨 Test failed with error:\n\(error)")
					}
				}
			}
		}
		catch let error {
			XCTFail("🚨 Failed to create ASTs or contexts: \(error)")
			return
		}
	}

	func testAllTranspilationPasses() {
		let tests = TestUtilities.testCases

		let testCasePaths = tests.map {
			TestUtilities.testCasesPath + $0
		}
		let astDumpFilePaths: List<String> = tests.map { testName in
			let testCasePath = TestUtilities.testCasesPath + testName
			return SupportingFile.pathOfSwiftASTDumpFile(
				forSwiftFile: testCasePath,
				swiftVersion: PerformanceTest.swiftVersion)
		}

		let rawASTs = try! Compiler.transpileGryphonRawASTs(
			fromInputFiles: testCasePaths,
			fromASTDumpFiles: astDumpFilePaths,
			withContext: TranspilationContext(
				toolchainName: PerformanceTest.toolchain,
				indentationString: "\t",
				defaultsToFinal: false),
			usingSwiftSyntax: false)

		measure {
			for rawAST in rawASTs {
				do {
					_ = try Compiler.generateGryphonAST(
						fromGryphonRawAST: rawAST,
						withContext: TranspilationContext(
							toolchainName: PerformanceTest.toolchain,
							indentationString: "\t",
							defaultsToFinal: false))
				}
				catch let error {
					XCTFail("🚨 Test failed with error:\n\(error)")
				}
			}
		}
	}

	func testKotlinTranslator() {
		let tests = TestUtilities.testCases

		do {
			let astsAndContexts: List<(GryphonAST, TranspilationContext)> = try tests.map
				{ testName in
					let testCasePath = TestUtilities.testCasesPath + testName
					let astDumpFilePath =
						SupportingFile.pathOfSwiftASTDumpFile(
							forSwiftFile: testCasePath,
							swiftVersion: PerformanceTest.swiftVersion)
					let context = try TranspilationContext(
						toolchainName: PerformanceTest.toolchain,
						indentationString: "\t",
						defaultsToFinal: false)
					let ast = try Compiler.transpileGryphonASTs(
						fromInputFiles: [testCasePath],
						fromASTDumpFiles: [astDumpFilePath],
						withContext: context,
						usingSwiftSyntax: false).first!
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
		catch let error {
			XCTFail("🚨 Failed to create ASTs or contexts: \(error)")
			return
		}
	}

	func testFullTranspilation() {
		let tests = TestUtilities.testCases

		measure {
			for testName in tests {
				do {
					let testCasePath = TestUtilities.testCasesPath + testName
					let astDumpFilePath = SupportingFile.pathOfSwiftASTDumpFile(
						forSwiftFile: testCasePath,
						swiftVersion: PerformanceTest.swiftVersion)
					_ = try Compiler.transpileKotlinCode(
						fromInputFiles: [testCasePath],
						fromASTDumpFiles: [astDumpFilePath],
						withContext: TranspilationContext(
							toolchainName: PerformanceTest.toolchain,
							indentationString: "\t",
							defaultsToFinal: false),
						usingSwiftSyntax: false)
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
