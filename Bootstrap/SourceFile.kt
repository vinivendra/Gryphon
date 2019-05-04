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

    data class Comment(
        val key: String,
        val value: String
    )
}

public fun SourceFile.getCommentFromLine(lineNumber: Int): SourceFile.Comment? {
    val line: String? = getLine(lineNumber)

    line ?: return null

    val lineComponents: MutableList<String> = line.split(separator = "// ", maxSplits = 1, omittingEmptySubsequences = false)

    if (lineComponents.size != 2) {
        return null
    }

    val comment: String = lineComponents[1]
    val commentComponents: MutableList<String> = comment.split(separator = ": ", maxSplits = 1, omittingEmptySubsequences = false)

    if (commentComponents.size != 2) {
        val key: String? = commentComponents.firstOrNull()
        if (key != null && key == "declaration:" || key == "insert:") {
            return SourceFile.Comment(key = key.dropLast(1), value = "")
        }
        return null
    }

    val key: String = commentComponents[0]
    val value: String = commentComponents[1]

    return SourceFile.Comment(key = key, value = value)
}

data class SourceFileRange(
    val lineStart: Int,
    val lineEnd: Int,
    val columnStart: Int,
    val columnEnd: Int
)
