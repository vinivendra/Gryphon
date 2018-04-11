@testable import GryphonLib
import XCTest

struct TestableRange: Equatable {
    let lowerBound: Int
    let upperBound: Int
    
    init(_ range: Range<String.Index>) {
        self.lowerBound = range.lowerBound.encodedOffset
        self.upperBound = range.upperBound.encodedOffset
    }
    
    init(_ lowerBound: Int, _ upperBound: Int) {
        self.lowerBound = lowerBound
        self.upperBound = upperBound
    }
}

class GRYExtensionTest: XCTestCase {
    func testStringSplit() {
        XCTAssertEqual("->".split(withStringSeparator: "->"),
                       [])
        XCTAssertEqual("a->b".split(withStringSeparator: "->"),
                       ["a", "b"])
        XCTAssertEqual("a->b->c".split(withStringSeparator: "->"),
                       ["a", "b", "c"])
        XCTAssertEqual("->b->c".split(withStringSeparator: "->"),
                       ["b", "c"])
        XCTAssertEqual("a->b->".split(withStringSeparator: "->"),
                       ["a", "b"])
        XCTAssertEqual("a->->b".split(withStringSeparator: "->"),
                       ["a", "b"])
        XCTAssertEqual("abc".split(withStringSeparator: "->"),
                       ["abc"])
        XCTAssertEqual(
            "->(Int, (String) -> Int) ->-> Int ->"
                .split(withStringSeparator: "->"),
            ["(Int, (String) ", " Int) ", " Int "])
    }
    
    func testOccurrencesOfSubstring() {
        XCTAssertEqual("->".occurrences(of: "->").map(TestableRange.init),
                       [TestableRange(0, 2)])
        XCTAssertEqual("a->b".occurrences(of: "->").map(TestableRange.init),
                       [TestableRange(1, 3)])
        XCTAssertEqual("a->b->c".occurrences(of: "->").map(TestableRange.init),
                       [TestableRange(1, 3), TestableRange(4, 6)])
        XCTAssertEqual("->b->c".occurrences(of: "->").map(TestableRange.init),
                       [TestableRange(0, 2), TestableRange(3, 5)])
        XCTAssertEqual("a->b->".occurrences(of: "->").map(TestableRange.init),
                       [TestableRange(1, 3), TestableRange(4, 6)])
        XCTAssertEqual("a->->b".occurrences(of: "->").map(TestableRange.init),
                       [TestableRange(1, 3), TestableRange(3, 5)])
        XCTAssertEqual("abc".occurrences(of: "->").map(TestableRange.init),
                       [])
        XCTAssertEqual(
            "->(Int, (String) -> Int) ->-> Int ->"
                .occurrences(of: "->").map(TestableRange.init),
            [TestableRange(0, 2), TestableRange(17, 19), TestableRange(25, 27),
             TestableRange(27, 29), TestableRange(34, 36)])
    }
    
    static var allTests = [
        ("testStringSplit", testStringSplit),
        ("testOccurrencesOfSubstring", testOccurrencesOfSubstring)
        ]
}
