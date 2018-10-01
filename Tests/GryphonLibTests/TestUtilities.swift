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
import Foundation

func seedFromCurrentHour() -> (UInt64, UInt64) {
	let calendar = Calendar.current
	let now = Date()
	let year = calendar.component(.year, from: now)
	let month = calendar.component(.month, from: now)
	let weekOfYear = calendar.component(.weekOfYear, from: now)
	let weekday = calendar.component(.weekday, from: now)
	let day = calendar.component(.day, from: now)
	let hour = calendar.component(.hour, from: now)

	let int1 = year + month + weekOfYear
	let int2 = weekday + day + hour

	return (UInt64(int1), UInt64(int2))
}

func seedFromLastHour() -> (UInt64, UInt64) {
	let calendar = Calendar.current
	let now = Date()
	let year = calendar.component(.year, from: now)
	let month = calendar.component(.month, from: now)
	let weekOfYear = calendar.component(.weekOfYear, from: now)
	let weekday = calendar.component(.weekday, from: now)
	let day = calendar.component(.day, from: now)
	let lastHour = (calendar.component(.hour, from: now) + 23) % 24

	let int1 = year + month + weekOfYear
	let int2 = weekday + day + lastHour

	return (UInt64(int1), UInt64(int2))
}

enum TestUtils {
	static var rng: RandomGenerator = Xoroshiro(seed: seedFromCurrentHour())

	static let testFilesPath: String = Process().currentDirectoryPath + "/Test Files/"

	static func diff(_ string1: String, _ string2: String) -> String {
		return withTemporaryFile(named: "file1.txt", containing: string1) { file1Path in
			withTemporaryFile(named: "file2.txt", containing: string2) { file2Path in
				let command = ["diff", file1Path, file2Path]
				let commandResult = GRYShell.runShellCommand(command)
				if let commandResult = commandResult {
					return "\n\n===\n\(commandResult.standardOutput)===\n"
				}
				else {
					return " timed out."
				}
			}
		}
	}

	static func withTemporaryFile<T>(
		named fileName: String,
		containing contents: String,
		_ closure: (String) throws -> T)
		rethrows -> T
	{
		let temporaryDirectory = ".tmp"

		let filePath = GRYUtils.createFile(
			named: fileName,
			inDirectory: temporaryDirectory,
			containing: contents)
		return try closure(filePath)
	}
}

extension TestUtils {
	static private var testFilesHaveBeenUpdated = false

	static public func updateFiles() throws {

		guard !testFilesHaveBeenUpdated else {
			return
		}

		let folder = "Test Files"
		print("Updating files...")

		updateFiles(in: folder, from: .swift, to: .swiftAstDump)
		{ (_: String, astFilePath: String) in
			// The swiftAstDump files must be updated externally by the perl script. If any files
			// are out of date, this closure gets called and informs the user how to update them.
			fatalError("Please update ast file \(astFilePath) with the `dump-ast.pl` perl script.")
		}

		updateFiles(in: folder, from: .swiftAstDump, to: .grySwiftAstJson)
		{ (dumpFilePath: String, jsonFilePath: String) in
			let ast = GRYSwiftAst(astFile: dumpFilePath)
			ast.writeAsJSON(toFile: jsonFilePath)
		}

		try updateFiles(in: folder, from: .grySwiftAstJson, to: .gryRawAstJson)
		{ (swiftAstFilePath: String, gryphonAstRawFilePath: String) in
			let swiftAst = GRYSwiftAst.initialize(fromJsonInFile: swiftAstFilePath)
			let gryphonAst = try GRYSwift4Translator().translateAST(swiftAst)
			gryphonAst.writeAsJSON(toFile: gryphonAstRawFilePath)
		}

		try updateFiles(in: folder, from: .gryRawAstJson, to: .gryAstJson)
		{ (gryphonAstRawFilePath: String, gryphonAstFilePath: String) throws in
			let gryphonAstRaw = GRYAst.initialize(fromJsonInFile: gryphonAstRawFilePath)
			let gryphonAst = GRYTranspilationPass.runAllPasses(on: gryphonAstRaw)
			gryphonAst.writeAsJSON(toFile: gryphonAstFilePath)
		}

		testFilesHaveBeenUpdated = true

		print("Done!")
	}

	static private func updateFiles(
		in folder: String,
		from originExtension: GRYFileExtension,
		to destinationExtension: GRYFileExtension,
		withUpdateClosure update: (String, String) throws -> ()) rethrows
	{
		let currentURL = URL(fileURLWithPath: Process().currentDirectoryPath + "/" + folder)
		let fileURLs = try! FileManager.default.contentsOfDirectory(
			at: currentURL,
			includingPropertiesForKeys: nil)
		let testFiles = fileURLs.filter { $0.pathExtension == originExtension.rawValue }.sorted
		{ (url1: URL, url2: URL) -> Bool in
			url1.absoluteString < url2.absoluteString
		}

		for originFile in testFiles {
			let originFilePath = originFile.path
			let destinationFilePath =
				GRYUtils.changeExtension(of: originFilePath, to: destinationExtension)

			let destinationFileWasJustCreated =
				GRYUtils.createFileIfNeeded(at: destinationFilePath, containing: "")
			let destinationFileIsOutdated = destinationFileWasJustCreated ||
				GRYUtils.file(originFilePath, wasModifiedLaterThan: destinationFilePath)

			if destinationFileIsOutdated {
				print("\tUpdating \(destinationFilePath)...")
				try update(originFilePath, destinationFilePath)
			}
		}
	}
}

extension TestUtils {
	static let acceptanceTestCases: [String] = [
		"arrays",
		"assignments",
		"bhaskara",
		"classes",
		"extensions",
		"functionCalls",
		"ifStatement",
		"kotlinLiterals",
		"logicOperators",
		"numericLiterals",
		"operators",
		"print",
	]
	static let allTestCases = acceptanceTestCases + [
		"enums",
		"functionDefinitions",
		"strings",
	]
}
