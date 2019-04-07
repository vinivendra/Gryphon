internal fun String.split(
	separator: String,
	maxSplits: Int = Int.MAX_VALUE,
	omittingEmptySubsequences: Boolean = true)
	: MutableList<String>
{
	var result: MutableList<String> = mutableListOf()
	var splits: Int = 0
	var previousIndex: Int = 0
	val separators: MutableList<IntRange> = this.occurrences(searchedSubstring = separator)

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

internal fun String.occurrences(searchedSubstring: String): MutableList<IntRange> {
	var result: MutableList<IntRange> = mutableListOf()
	var currentSubstring: String = this
	var substringOffset: Int = 0

	while (substringOffset < this.length) {
		var maybeIndex: Int? = currentSubstring.indexOf(searchedSubstring)
		maybeIndex = if (maybeIndex == -1) { null } else { maybeIndex }

		val foundIndex: Int? = maybeIndex

		if (foundIndex == null) {
			break
		}

		val occurenceStartIndex: Int = foundIndex + substringOffset
		val occurenceEndIndex: Int = occurenceStartIndex + searchedSubstring.length

		result.add(IntRange(occurenceStartIndex, occurenceEndIndex))

		substringOffset = occurenceEndIndex
		currentSubstring = this.substring(substringOffset)
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

internal fun String.upperSnakeCase(): String {
	if (this.isEmpty()) {
		return this
	}

	var result: String = ""

	result += this[0].toUpperCase()

	val indicesWithoutTheFirstOne = this.indices.drop(1)

	for (index in indicesWithoutTheFirstOne) {
		val currentCharacter: Char = this[index]
		if (currentCharacter.isUppercase) {
			val nextIndex: Int = index + 1
			if (nextIndex != this.length && !this[nextIndex].isUppercase) {
				result += "_"
			}
			result += currentCharacter
		}
		else {
			result += currentCharacter.toUpperCase()
		}
	}

	return result
}

val Char.isNumber: Boolean
	get() {
		return this == '0' || this == '1' || this == '2' || this == '3' || this == '4' || this == '5' || this == '6' || this == '7' || this == '8' || this == '9'
	}
val Char.isUppercase: Boolean
	get() {
		return this == 'A' || this == 'B' || this == 'C' || this == 'D' || this == 'E' || this == 'F' || this == 'G' || this == 'H' || this == 'I' || this == 'J' || this == 'K' || this == 'L' || this == 'M' || this == 'N' || this == 'O' || this == 'P' || this == 'Q' || this == 'R' || this == 'S' || this == 'T' || this == 'U' || this == 'V' || this == 'W' || this == 'X' || this == 'Y' || this == 'Z'
	}
