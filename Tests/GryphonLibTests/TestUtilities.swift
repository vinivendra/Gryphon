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

enum TestUtils {
	static let testFilesPath: String = Process().currentDirectoryPath + "/Test Files/"

	static func diff(_ string1: String, _ string2: String) -> String {
		return withTemporaryFile(named: "file1.txt", containing: string1) { file1Path in
			withTemporaryFile(named: "file2.txt", containing: string2) { file2Path in
				let command: ArrayClass = ["diff", file1Path, file2Path]
				let commandResult = Shell.runShellCommand(command)
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

		let filePath = Utilities.createFile(
			named: fileName,
			inDirectory: temporaryDirectory,
			containing: contents)
		return try closure(filePath)
	}
}

extension TestUtils {
	static let testCasesForAcceptanceTest: ArrayClass<String> = [
		"arrays",
		"assignments",
		"bhaskara",
		"classes",
		"closures",
		"dictionaries",
		"extensions",
		"functionCalls",
		"ifStatement",
		"inits",
		"kotlinLiterals",
		"logicOperators",
		"misc",
		"numericLiterals",
		"operators",
		"print",
		"standardLibrary",
		"staticMembers",
		"structs",
		"switches",
	]
	static let testCasesForAllTests = testCasesForAcceptanceTest + [
		"enums",
		"functionDefinitions",
		"strings",
	]
	static let testCasesForTranspilationPassTest = testCasesForAllTests + [
		"warnings",
	]
	static let allTestCases = testCasesForTranspilationPassTest
}
