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
			return withTemporaryFile(named: "file2.txt", containing: string2) { file2Path in
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
	
	static func withTemporaryFile<T>(named fileName: String, containing contents: String, _ closure: (String) throws -> T) rethrows -> T
	{
		let temporaryDirectory = ".tmp"
		
		let filePath = GRYUtils.createFile(named: fileName, inDirectory: temporaryDirectory, containing: contents)
		return try closure(filePath)
	}
}

extension TestUtils {
	static let acceptanceTestCases = [
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
		"print"
	]
	static let allTestCases = acceptanceTestCases + [
		"enums",
		"functionDefinitions",
		"strings"
	]
}
