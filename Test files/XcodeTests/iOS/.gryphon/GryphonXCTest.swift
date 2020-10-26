// Replacement for Comparable
private struct _Comparable: Comparable {
	static func < (lhs: _Comparable, rhs: _Comparable) -> Bool {
		return false
	}
}

// Replacement for Optional
private struct _Optional { }

// gryphon ignore
class XCTestCase {
	class func setUp() { }
	class func tearDown() { }

	public func XCTAssert(_ condition: Bool, _ message: String = "") { }
	public func XCTAssertEqual<T>(_ a: T, _ b: T, _ message: String = "") where T : Equatable { }
	public func XCTAssertNotEqual<T>(_ a: T, _ b: T, _ message: String = "") where T : Equatable { }
	public func XCTAssertFalse(_ condition: Bool, _ message: String = "") { }
	public func XCTAssertNil<T>(_ expression: T?, _ message: String = "") { }
	public func XCTAssertNotNil<T>(_ expression: T?, _ message: String = "") { }
	public func XCTAssertNoThrow<T>(
		_ expression: @autoclosure () throws -> T,
		_ message: String = "") { }
	public func XCTAssertThrowsError<T>(
		_ expression: @autoclosure () throws -> T,
		_ message: String = "") { }
	public func XCTFail(_ message: String = "") { }
}

extension XCTestCase {
	private func gryphonTemplates() {
		let _bool = true
		let _string = ""
		let _any1: _Comparable = _Comparable()
		let _any2: _Comparable = _Comparable()
		let _optional: _Optional? = _Optional()

		XCTAssert(_bool)
		_ = "XCTAssert(_bool)"

		XCTAssert(_bool, _string)
		_ = "XCTAssert(_bool, _string)"

		XCTAssertFalse(_bool)
		_ = "XCTAssertFalse(_bool)"

		XCTAssertFalse(_bool, _string)
		_ = "XCTAssertFalse(_bool, _string)"

		XCTAssertNil(_optional)
		_ = "XCTAssertNil(_optional)"

		XCTAssertNil(_optional, _string)
		_ = "XCTAssertNil(_optional, _string)"

		XCTAssertEqual(_any1, _any2, _string)
		_ = "XCTAssertEqual(_any1, _any2, _string)"

		XCTAssertEqual(_any1, _any2)
		_ = "XCTAssertEqual(_any1, _any2)"
	}
}
