data class TestableRange(
	val lowerBound: Int,
	val upperBound: Int
	)
{
	constructor(range: IntRange): this(range.start, range.endInclusive) { }
}

class ExtensionsTest(): Test("ExtensionsTest") {
	override fun runAllTests() {
		testStringSplit()
		testOccurrencesOfSubstring()
		testRemoveTrailingWhitespace()
		super.runAllTests()
	}

	fun testStringSplit() {
		XCTAssertEqual(
			"->".split(separator = "->"),
			mutableListOf<String>())
		XCTAssertEqual(
			"->->".split(separator = "->"),
			mutableListOf<String>())
		XCTAssertEqual(
			"a->b".split(separator = "->"),
			mutableListOf<String>("a", "b"))
		XCTAssertEqual(
			"a->b->c".split(separator = "->"),
			mutableListOf<String>("a", "b", "c"))
		XCTAssertEqual(
			"->b->c".split(separator = "->"),
			mutableListOf<String>("b", "c"))
		XCTAssertEqual(
			"->->c".split(separator = "->"),
			mutableListOf<String>("c"))
		XCTAssertEqual(
			"a->b->".split(separator = "->"),
			mutableListOf<String>("a", "b"))
		XCTAssertEqual(
			"a->->".split(separator = "->"),
			mutableListOf<String>("a"))
		XCTAssertEqual(
			"a->->b".split(separator = "->"),
			mutableListOf<String>("a", "b"))
		XCTAssertEqual(
			"abc".split(separator = "->"),
			mutableListOf<String>("abc"))
		XCTAssertEqual(
			"->(Int, (String) -> Int) ->-> Int ->"
				.split(separator = "->"),
			mutableListOf<String>("(Int, (String) ", " Int) ", " Int "))

		// Omit empty subsequences
		XCTAssertEqual(
			"->".split(separator = "->", omittingEmptySubsequences = false),
			mutableListOf<String>("", ""))
		XCTAssertEqual(
			"->->".split(separator = "->", omittingEmptySubsequences = false),
			mutableListOf<String>("", "", ""))
		XCTAssertEqual(
			"a->b".split(separator = "->", omittingEmptySubsequences = false),
			mutableListOf<String>("a", "b"))
		XCTAssertEqual(
			"a->b->c".split(separator = "->", omittingEmptySubsequences = false),
			mutableListOf<String>("a", "b", "c"))
		XCTAssertEqual(
			"->b->c".split(separator = "->", omittingEmptySubsequences = false),
			mutableListOf<String>("", "b", "c"))
		XCTAssertEqual(
			"->->c".split(separator = "->", omittingEmptySubsequences = false),
			mutableListOf<String>("", "", "c"))
		XCTAssertEqual(
			"a->b->".split(separator = "->", omittingEmptySubsequences = false),
			mutableListOf<String>("a", "b", ""))
		XCTAssertEqual(
			"a->->".split(separator = "->", omittingEmptySubsequences = false),
			mutableListOf<String>("a", "", ""))
		XCTAssertEqual(
			"a->->b".split(separator = "->", omittingEmptySubsequences = false),
			mutableListOf<String>("a", "", "b"))
		XCTAssertEqual(
			"abc".split(separator = "->", omittingEmptySubsequences = false),
			mutableListOf<String>("abc"))
		XCTAssertEqual(
			"->(Int, (String) -> Int) ->-> Int ->"
				.split(separator = "->", omittingEmptySubsequences = false),
			mutableListOf<String>("", "(Int, (String) ", " Int) ", "", " Int ", ""))

		// Max splits
		XCTAssertEqual(
			"->".split(separator = "->", maxSplits = 3, omittingEmptySubsequences = false),
			mutableListOf<String>("", ""))
		XCTAssertEqual(
			"->->".split(separator = "->", maxSplits = 1, omittingEmptySubsequences = false),
			mutableListOf<String>("", "->"))
		XCTAssertEqual(
			"a->b".split(separator = "->", maxSplits = 0, omittingEmptySubsequences = false),
			mutableListOf<String>("a->b"))
		XCTAssertEqual(
			"a->b->c".split(
				separator = "->", maxSplits = 2, omittingEmptySubsequences = false),
			mutableListOf<String>("a", "b", "c"))
		XCTAssertEqual(
			"a->b->c->d".split(
				separator = "->", maxSplits = 2, omittingEmptySubsequences = false),
			mutableListOf<String>("a", "b", "c->d"))
		XCTAssertEqual(
			"a->b->c->d".split(
				separator = "->", maxSplits = 1, omittingEmptySubsequences = false),
			mutableListOf<String>("a", "b->c->d"))
		XCTAssertEqual(
			"->b->c".split(separator = "->", maxSplits = 1),
			mutableListOf<String>("b->c"))
		XCTAssertEqual(
			"->->c".split(separator = "->", maxSplits = 1),
			mutableListOf<String>("->c"))
		XCTAssertEqual(
			"a->b->".split(separator = "->", maxSplits = 1),
			mutableListOf<String>("a", "b->"))
		XCTAssertEqual(
			"a->->".split(separator = "->", maxSplits = 1),
			mutableListOf<String>("a", "->"))
		XCTAssertEqual(
			"a->->b".split(separator = "->", maxSplits = 1),
			mutableListOf<String>("a", "->b"))
		XCTAssertEqual(
			"abc".split(separator = "->", maxSplits = 0),
			mutableListOf<String>("abc"))
		XCTAssertEqual(
			"abc".split(separator = "->", maxSplits = 1),
			mutableListOf<String>("abc"))
		XCTAssertEqual(
			"->(Int, (String) -> Int) ->-> Int ->"
				.split(separator = "->", maxSplits = 3, omittingEmptySubsequences = false),
			mutableListOf<String>("", "(Int, (String) ", " Int) ", "-> Int ->"))
		XCTAssertEqual(
			"->(Int, (String) -> Int) ->-> Int ->"
				.split(separator = "->", maxSplits = 3),
			mutableListOf<String>("(Int, (String) ", " Int) ", "-> Int ->"))
	}

	fun testOccurrencesOfSubstring() {
		XCTAssertEqual(
			"->".occurrences("->").map({ TestableRange(it) }),
			mutableListOf<TestableRange>(TestableRange(0, 2)))
		XCTAssertEqual(
			"a->b".occurrences("->").map({ TestableRange(it) }),
			mutableListOf<TestableRange>(TestableRange(1, 3)))
		XCTAssertEqual(
			"a->b->c".occurrences("->").map({ TestableRange(it) }),
			mutableListOf<TestableRange>(TestableRange(1, 3), TestableRange(4, 6)))
		XCTAssertEqual(
			"->b->c".occurrences("->").map({ TestableRange(it) }),
			mutableListOf<TestableRange>(TestableRange(0, 2), TestableRange(3, 5)))
		XCTAssertEqual(
			"->->c".occurrences("->").map({ TestableRange(it) }),
			mutableListOf<TestableRange>(TestableRange(0, 2), TestableRange(2, 4)))
		XCTAssertEqual(
			"a->b->".occurrences("->").map({ TestableRange(it) }),
			mutableListOf<TestableRange>(TestableRange(1, 3), TestableRange(4, 6)))
		XCTAssertEqual(
			"a->->".occurrences("->").map({ TestableRange(it) }),
			mutableListOf<TestableRange>(TestableRange(1, 3), TestableRange(3, 5)))
		XCTAssertEqual(
			"a->->b".occurrences("->").map({ TestableRange(it) }),
			mutableListOf<TestableRange>(TestableRange(1, 3), TestableRange(3, 5)))
		XCTAssertEqual(
			"abc".occurrences("->").map({ TestableRange(it) }),
			mutableListOf<TestableRange>())
		XCTAssertEqual(
			"->(Int, (String) -> Int) ->-> Int ->"
				.occurrences("->").map({ TestableRange(it) }),
			mutableListOf<TestableRange>(
				TestableRange(0, 2),
				TestableRange(17, 19),
				TestableRange(25, 27),
				TestableRange(27, 29),
				TestableRange(34, 36)))
	}

	fun testRemoveTrailingWhitespace() {
		XCTAssertEqual("", "".removeTrailingWhitespace())
		XCTAssertEqual("a", "a".removeTrailingWhitespace())
		XCTAssertEqual("abcde", "abcde".removeTrailingWhitespace())
		XCTAssertEqual("abcde", "abcde".removeTrailingWhitespace())
		XCTAssertEqual("abcde", "abcde  \t\t  ".removeTrailingWhitespace())
		XCTAssertEqual("abcde  \t\t  abcde", "abcde  \t\t  abcde".removeTrailingWhitespace())
		XCTAssertEqual("abcde  \t\t  abcde", "abcde  \t\t  abcde  ".removeTrailingWhitespace())
		XCTAssertEqual("abcde  \t\t  abcde", "abcde  \t\t  abcde \t ".removeTrailingWhitespace())
	}
}