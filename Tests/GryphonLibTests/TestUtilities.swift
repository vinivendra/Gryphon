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
				return commandResult.standardOutput
			}
		}
	}
	
	static func withTemporaryFile<T>(named fileName: String, containing contents: String, _ closure: (String) throws -> T) rethrows -> T
	{
		let temporaryDirectory = ".tmp"
		
		let fileManager = FileManager.default
		
		try! fileManager.createDirectory(atPath: temporaryDirectory, withIntermediateDirectories: true)
		
		let filePath = temporaryDirectory + "/" + fileName
		let fileURL = URL(fileURLWithPath: filePath)
		
		// Remove it if it already exists
		try? fileManager.removeItem(at: fileURL)
		
		let success = fileManager.createFile(atPath: filePath, contents: Data(contents.utf8))
		assert(success)
		
		defer { try? fileManager.removeItem(at: fileURL) }
		
		return try closure(filePath)
	}
}
