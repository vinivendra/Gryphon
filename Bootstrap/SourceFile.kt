class SourceFile {
	var path: String
	val lines: MutableList<String>

	constructor(path: String, contents: String) {
		this.path = path
		this.lines = contents.split(separator = "\n", omittingEmptySubsequences = false) as MutableList<String>
	}

	val numberOfLines: Int
		get() {
			return lines.size
		}
}
