typealias OutputFileMapBuffer = MutableMap<String, MutableMap<OutputFileMap.OutputType, String>>

class OutputFileMap {
	public enum class OutputType {
		AST_DUMP,
		SWIFT_AST,
		GRYPHON_AST_RAW,
		GRYPHON_AST,
		KOTLIN;

		companion object {
			operator fun invoke(rawValue: String): OutputType? {
				return when (rawValue) {
					"ast-dump" -> OutputType.AST_DUMP
					"swiftAST" -> OutputType.SWIFT_AST
					"gryphonASTRaw" -> OutputType.GRYPHON_AST_RAW
					"gryphonAST" -> OutputType.GRYPHON_AST
					"kotlin" -> OutputType.KOTLIN
					else -> null
				}
			}
		}

		val rawValue: String
			get() {
				return when (this) {
					OutputType.AST_DUMP -> "ast-dump"
					OutputType.SWIFT_AST -> "swiftAST"
					OutputType.GRYPHON_AST_RAW -> "gryphonASTRaw"
					OutputType.GRYPHON_AST -> "gryphonAST"
					OutputType.KOTLIN -> "kotlin"
				}
			}
	}

	var buffer: OutputFileMapBuffer

	constructor(buffer: OutputFileMapBuffer) {
		this.buffer = buffer
	}

	public fun getFileMap(file: String): MutableMap<OutputFileMap.OutputType, String>? {
		return buffer[file]
	}

	public fun getOutputFile(file: String, outputType: OutputFileMap.OutputType): String? {
		val fileMap: MutableMap<OutputFileMap.OutputType, String>? = getFileMap(file = file)
		fileMap ?: return null
		return fileMap[outputType]
	}
}
