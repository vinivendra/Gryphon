internal fun String.split(
	separator: String,
	maxSplits: Int = Int.MAX_VALUE,
	omittingEmptySubsequences: Boolean = true)
	: MutableList<String>
{
	var result: MutableList<String> = mutableListOf()
	var splits: Int = 0
	var previousIndex: Int = 0
	val separators: MutableList<IntRange> = this.occurrences(separator)

	for (separator in separators) {
		if (splits >= maxSplits) {
			splits += 1
			break
		}

		val substring: String = this.substring(previousIndex, separator.start)

		if (omittingEmptySubsequences) {
			if (substring.isEmpty()) {
				splits += 1
				previousIndex = separator.endInclusive
				continue
			}
		}

		result.add(substring)

		splits += 1

		previousIndex = separator.endInclusive
	}

	val substring: String = this.substring(previousIndex, this.length)

	if (!(substring.isEmpty() && omittingEmptySubsequences)) {
		result.add(substring)
	}

	return result
}

fun String.occurrences(substring: String): MutableList<IntRange> {
	var result: MutableList<IntRange> = mutableListOf()

	var currentString = this
	var currentOffset = 0

	while (currentOffset < this.length) {
		val foundIndex = currentString.indexOf(substring)
		if (foundIndex == -1) {
			break
		}
		else {
			val occurenceStartIndex = foundIndex + currentOffset
			val occurenceEndIndex = occurenceStartIndex + substring.length
			result.add(IntRange(occurenceStartIndex, occurenceEndIndex))
			currentOffset = occurenceEndIndex
			currentString = this.substring(currentOffset)
		}
	}

	return result
}

internal fun String.removeTrailingWhitespace(): String {
	if (this.isEmpty()) {
		return ""
	}

	var lastValidIndex: Int = this.length - 1

	while (lastValidIndex != 0) {
		val character: Char = this[lastValidIndex]
		if (character != ' ' && character != '\t') {
			break
		}
		lastValidIndex -= 1
	}

	return this.substring(0, lastValidIndex + 1)
}
