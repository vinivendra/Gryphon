class SourceFile {
	var path: String
	val lines: MutableList<String>

	constructor(path: String, contents: String) {
		this.path = path
		this.lines = contents.split(separator = '\n', omittingEmptySubsequences = false) as MutableList<String>
	}

	val numberOfLines: Int
		get() {
			return lines.size
		}

	public fun getLine(lineNumber: Int): String? {
		val line: String? = lines.getSafe(lineNumber - 1)
		if (line != null) {
			return line
		}
		else {
			return null
		}
	}
}

data class SourceFileRange(
	val lineStart: Int,
	val lineEnd: Int,
	val columnStart: Int,
	val columnEnd: Int
)
