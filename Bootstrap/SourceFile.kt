class SourceFile {
	var path: String
	val lines: MutableList<String>

	constructor(path: String, contents: String) {
		this.path = path
		this.lines = contents.split(separator = '\n', omittingEmptySubsequences = false)
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
