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

// gryphon output: Bootstrap/SharedTestUtilities.kt

// gryphon insert: import kotlin.system.*

import Foundation

#if !GRYPHON
@testable import GryphonLib
import XCTest
#endif

class TestError: Error {
	// gryphon insert: constructor(): super() { }
}

extension TranspilationContext {
	/// Cache for toolchains that use each Swift version (the key is the swift version, the value is
	/// the toolchain). Swift versions inserted here should be supported. The default toolchain is
	/// represented as "".
	static private var swiftVersionToolchains: MutableMap<String, String> = [:]

	/// Returns the name of a toolchain that uses the given Swift version. The first call to this
	/// function triggers an eager calculation of a toolchain name for each supported Swift version.
	/// The default toolchain is represented as ""; a `nil` value indicates no toolchain was found
	/// for the given Swift version.
	static internal func getToolchain(forSwiftVersion swiftVersion: String) throws -> String? {
		if swiftVersionToolchains.isEmpty {
			let defaultVersion = try getVersionOfToolchain(nil)
			swiftVersionToolchains[defaultVersion] = ""

			for swiftVersion in supportedSwiftVersions {
				if swiftVersion == defaultVersion {
					continue
				}

				let possibleToolchainName = "swift \(swiftVersion)"
				let versionOfPossibleToolchain =
					try getVersionOfToolchain(possibleToolchainName)
				if versionOfPossibleToolchain == swiftVersion {
					swiftVersionToolchains[swiftVersion] = possibleToolchainName
				}
			}
		}

		return swiftVersionToolchains[swiftVersion]
	}
}

class TestUtilities {
	// MARK: - Diffs
	static let testCasesPath: String = Utilities.getCurrentFolder() + "/Test cases/"

	static func diff(_ string1: String, _ string2: String) -> String {
		do {
			let diffResult = try withTemporaryFile(fileName: "file1.txt", contents: string1)
				{ file1Path in
					try withTemporaryFile(fileName: "file2.txt", contents: string2)
						{ file2Path in
							TestUtilities.diffFiles(file1Path, file2Path)
						}
				}

			if let diffResult = diffResult {
				return diffResult
			}
			else {
				return "Diff timed out. Printing full result.\n" +
					"\n===\nDiff string 1:\n\n\(string1)===\n" +
					"\n===\nDiff string 2:\n\n\(string2)===\n"
			}
		}
		catch {
			return "Diff timed out. Printing full result.\n" +
				"\n===\nDiff string 1:\n\n\(string1)===\n" +
				"\n===\nDiff string 2:\n\n\(string2)===\n"
		}
	}

	static func diffFiles(_ file1Path: String, _ file2Path: String) -> String? {
		let command: List = ["diff", file1Path, file2Path]
		let commandResult = Shell.runShellCommand(command)
		return "\n\n===\n\(commandResult.standardOutput)===\n"
	}

	static func withTemporaryFile<T>(
		fileName: String,
		contents: String,
		closure: (String) throws -> T)
		throws -> T
	{
		let temporaryDirectory = ".tmp"

		let filePath = try Utilities.createFile(
			named: fileName,
			inDirectory: temporaryDirectory,
			containing: contents)
		return try closure(filePath)
	}

	public static let kotlinBuildFolder =
		"\(SupportingFile.gryphonBuildFolder)/kotlinBuild-\(OS.systemIdentifier)"

	static private var testCasesHaveBeenUpdated = false

	static public func updateASTsForTestCases() throws {
		guard !testCasesHaveBeenUpdated else {
			return
		}

		for swiftVersion in TranspilationContext.supportedSwiftVersions {
			guard let toolchain =
				try TranspilationContext.getToolchain(forSwiftVersion: swiftVersion) else
			{
				print("🚨 Toolchain for Swift \(swiftVersion) not found.")
				continue
			}

			Compiler.log("\t* Updating ASTs for test cases...")

			let swiftVersion = try TranspilationContext.getVersionOfToolchain(toolchain)

			let testCasesFolder = "Test cases"
			if Utilities.needsToDumpASTForSwiftFiles(
				in: testCasesFolder,
				forSwiftVersion: swiftVersion)
			{
				let testFiles = Utilities.getFiles(
					inDirectory: testCasesFolder,
					withExtension: .swift)

				for testFile in testFiles {
					try Driver.updateASTDumps(
						forFiles: [testFile],
						usingXcode: false,
						usingToolchain: toolchain)
				}

				if Utilities.needsToDumpASTForSwiftFiles(
					in: testCasesFolder,
					forSwiftVersion: swiftVersion)
				{
					throw GryphonError(errorMessage:
						"Failed to update the AST of at least one file in the \(testCasesFolder) " +
						"folder")
				}
			}

			testCasesHaveBeenUpdated = true

			Compiler.log("\t- Done!")
		}
    }

	// MARK: - Test cases
	static let testCases: List = [
		"access",
		"assignments",
		"classes",
		"closures",
		"enums",
		"extensions",
		"functionCalls",
		"generics",
		"ifStatement",
		"inits",
		"kotlinLiterals",
		"logicOperators",
		"misc",
		"numericLiterals",
		"openAndFinal",
		"openAndFinal-default-final",
		"operators",
		"standardLibrary",
		"strings",
		"structs",
		"switches",
	]
}
