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
		testUpperSnakeCase()
		testSafeIndex()
		testSecondToLast()
		testRotated()
		testGroupBy()
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

	fun testUpperSnakeCase() {
		XCTAssertEqual("ABC", "abc".upperSnakeCase())
		XCTAssertEqual("FOO_BAR", "fooBar".upperSnakeCase())
		XCTAssertEqual("FOO_BAR", "FooBar".upperSnakeCase())
		XCTAssertEqual("HTTPS_BAR", "HTTPSBar".upperSnakeCase())
	}

	fun testSafeIndex() {
		val array = mutableListOf(1, 2, 3)
		XCTAssert(array.getSafe(0) == 1)
		XCTAssert(array.getSafe(1) == 2)
		XCTAssert(array.getSafe(2) == 3)
		XCTAssert(array.getSafe(3) == null)
		XCTAssert(array.getSafe(-1) == null)
	}

	fun testSecondToLast() {
		val array1 = mutableListOf(1, 2, 3)
		val array2 = mutableListOf(1)
		XCTAssert(array1.secondToLast == 2)
		XCTAssert(array2.secondToLast == null)
	}

	fun testRotated() {
		val array = mutableListOf(1, 2, 3)
		val array1 = array.rotated()
		val array2 = array1.rotated()
		val array3 = array2.rotated()
		XCTAssertEqual(array1, mutableListOf(2, 3, 1))
		XCTAssertEqual(array2, mutableListOf(3, 1, 2))
		XCTAssertEqual(array3, mutableListOf(1, 2, 3))
	}

	fun testGroupBy() {
		val array = mutableListOf(1, 2, 3, 2, 3, 1, 2, 3)

		val histogram = array.group(getKey = { "${it}" })
		XCTAssertEqual(
			histogram,
			mutableMapOf(
				"1" to mutableListOf(1, 1),
				"2" to mutableListOf(2, 2, 2),
				"3" to mutableListOf(3, 3, 3)))

		val isEvenHistogram = array.group(getKey = { it % 2 == 0 })
		XCTAssertEqual(
			isEvenHistogram,
			mutableMapOf(
				true to mutableListOf(2, 2, 2),
				false to mutableListOf(1, 3, 3, 1, 3)))
	}
}