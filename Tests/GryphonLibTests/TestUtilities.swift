import Foundation
import GryphonLib

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
}
