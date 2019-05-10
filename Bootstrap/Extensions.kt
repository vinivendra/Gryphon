internal fun String.split(
	separator: Char,
	maxSplits: Int = Int.MAX_VALUE,
	omittingEmptySubsequences: Boolean = true)
	: MutableList<String>
{
	return this.split(separator = separator.toString(),
		maxSplits = maxSplits,
		omittingEmptySubsequences = omittingEmptySubsequences)
}

internal fun String.split(
    separator: String,
    maxSplits: Int = Int.MAX_VALUE,
    omittingEmptySubsequences: Boolean = true)
    : MutableList<String>
{
    val result: MutableList<String> = mutableListOf()
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
    val result: MutableList<IntRange> = mutableListOf()
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
            if (nextIndex != this.length && !this[nextIndex].isUppercase && this[nextIndex] != '_') {
                result += '_'
            }
            else if (index > 0) {
                val previousIndex: Int = index - 1
                if (!this[previousIndex].isUppercase && this[previousIndex] != '_') {
                    result += '_'
                }
            }
            result += currentCharacter
        }
        else {
            result += currentCharacter.toUpperCase()
        }
    }

    return result
}

internal fun String.capitalizedAsCamelCase(): String {
    val firstCharacter: Char = this.firstOrNull()!!
    val capitalizedFirstCharacter: String = firstCharacter.toString().toUpperCase()
    return capitalizedFirstCharacter + this.drop(1)
}

val String.removingBackslashEscapes: String
    get() {
        var result: String = ""
        var isEscaping: Boolean = false

        for (character in this) {
            if (!isEscaping) {
                if (character == '\\') {
                    isEscaping = true
                }
                else {
                    result += character
                }
            }
            else {
                when (character) {
                    '\\' -> result += '\\'
                    'n' -> result += '\n'
                    't' -> result += '\t'
                    else -> {
                        result += character
                        isEscaping = false
                    }
                }
                isEscaping = false
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

internal fun <Element> MutableList<Element>.getSafe(index: Int): Element? {
    if (index >= 0 && index < this.size) {
        return this[index]
    }
    else {
        return null
    }
}

val <Element> MutableList<Element>.secondToLast: Element?
    get() {
        return this.dropLast(1).lastOrNull()
    }

internal fun <Element> MutableList<Element>.rotated(): MutableList<Element> {
    val first: Element? = this.firstOrNull()

    first ?: return this

    var newArray: MutableList<Element> = mutableListOf()

    newArray.addAll(this.drop(1))
    newArray.add(first)

    return newArray
}

internal fun <Element, Key> MutableList<Element>.group(
    getKey: (Element) -> Key)
    : MutableMap<Key, MutableList<Element>>
{
    val result: MutableMap<Key, MutableList<Element>> = mutableMapOf()
    for (element in this) {
        val key: Key = getKey(element)
        val array: MutableList<Element> = result[key] ?: mutableListOf()

        array.add(element)

        result[key] = array
    }
    return result
}

internal fun PrintableTree.Companion.ofStrings(
    description: String,
    subtrees: MutableList<String>)
    : PrintableAsTree?
{
    val newSubtrees: MutableList<PrintableAsTree?> = subtrees.map { string -> PrintableTree(string) }.toMutableList()
    return PrintableTree.initOrNil(description, newSubtrees)
}
