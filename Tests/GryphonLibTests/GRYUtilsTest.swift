@testable import GryphonLib
import XCTest

class GRYUtilsTest: XCTestCase {
	/// If coverage is too small, the test will fail. If it's too big, an indexOutOfBounds will trigger.
	func testRandomCoverage() {
		let count = 100
		
		var numbersHit = [Bool](repeating: false, count: count)
		
		for _ in 0..<10_000 {
			let randomNumber = TestUtils.rng.random(0...(count - 1))
			numbersHit[randomNumber] = true
		}
		
		let failedResults = numbersHit.enumerated().compactMap { $0.element ? nil : $0.offset }
		
		XCTAssert(failedResults.isEmpty, "Random range didn't hit the numbers \(failedResults)! This is a probabilistic test, you might want to try running it again. If it succeeds at least once, the function is working.")
	}
	
	/// If coverage is too small, the test will fail. If it's too big, an indexOutOfBounds will trigger.
	func testRandomClosedRangeCoverage() {
		let count = 100
		
		var numbersHit = [Bool](repeating: false, count: count)
		
		for _ in 0..<10_000 {
			let randomNumber = TestUtils.rng.random(0..<count)
			numbersHit[randomNumber] = true
		}
		
		let failedResults = numbersHit.enumerated().compactMap { $0.element ? nil : $0.offset }
		
		XCTAssert(failedResults.isEmpty, "Random countable range didn't hit the numbers \(failedResults)! This is a probabilistic test, you might want to try running it again. If it succeeds at least once, the function is working.")
	}
	
	func testRandomBoolCoverage() {
		var hadTrueResult = false
		var hadFalseResult = false
		
		for _ in 0..<100 {
			let randomBoolean = TestUtils.rng.randomBool()
			hadTrueResult = hadTrueResult || randomBoolean
			hadFalseResult = hadFalseResult || !randomBoolean
			
			if hadTrueResult && hadFalseResult { break }
		}
		
		XCTAssert(hadTrueResult && hadFalseResult)
	}
	
	static var allTests = [
		("testRandomCoverage", testRandomCoverage),
		("testRandomClosedRangeCoverage", testRandomClosedRangeCoverage),
		("testRandomBoolCoverage", testRandomBoolCoverage)
	]
}
