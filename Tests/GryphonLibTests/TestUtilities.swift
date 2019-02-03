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

extension RandomGenerator {
	func randomString(fromCharacterSet characterSet: [Character], withLength length: Int)
		-> String
	{
		var result = ""
		for _ in 0..<length {
			result.append(characterSet.randomElement())
		}
		return result
	}
}

enum TestUtils {
	static let characterSets: [[Character]]
		= [["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "A", "S", "D", "F", "G", "H", "J",
			"K", "L", "Z", "X", "C", "V", "B", "N", "M", ],
		   ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p", "a", "s", "d", "f", "g", "h", "j",
			"k", "l", "z", "x", "c", "v", "b", "n", "m", ],
		   ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"],
		   ["~", "!", "@", "#", "$", "%", "^", "&", "*", "(", ")", "_", "+", "`", "-", "=", "[",
			"]", "{", "}", "\\", "|", ";", ":", "'", "\"", ",", "<", ".", ">", "/", "?", ],
		   ["\n", " ", "\t"], ]

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
	static let acceptanceTestCases: [String] = [
		"arrays",
		"assignments",
		"bhaskara",
		"classes",
		"extensions",
		"functionCalls",
		"ifStatement",
		"inits",
		"kotlinLiterals",
		"logicOperators",
		"numericLiterals",
		"operators",
		"print",
		"staticMembers",
	]
	static let allTestCases = acceptanceTestCases + [
		"enums",
		"functionDefinitions",
		"strings",
	]
}
