import java.io.File

class Utilities {
	companion object {
		internal fun expandSwiftAbbreviation(name: String): String {
			var nameComponents: MutableList<String> = name.split(separator = "_").map { it.capitalize() }.toMutableList()
			nameComponents = nameComponents.map { word ->
					when (word) {
						"Decl" -> "Declaration"
						"Declref" -> "Declaration Reference"
						"Expr" -> "Expression"
						"Func" -> "Function"
						"Ident" -> "Identity"
						"Paren" -> "Parentheses"
						"Ref" -> "Reference"
						"Stmt" -> "Statement"
						"Var" -> "Variable"
						else -> word
					}
				}.toMutableList()
			return nameComponents.joinToString(separator = " ")
		}
	}
}

public enum class FileExtension {
	SWIFT_AST_DUMP,
	OUTPUT,
	KT,
	SWIFT;

	val rawValue: String
		get() {
			return when (this) {
				FileExtension.SWIFT_AST_DUMP -> "swiftASTDump"
				FileExtension.OUTPUT -> "output"
				FileExtension.KT -> "kt"
				FileExtension.SWIFT -> "swift"
			}
		}
}

internal fun String.withExtension(fileExtension: FileExtension): String {
	return this + "." + fileExtension.rawValue
}

public fun Utilities.Companion.changeExtension(
	filePath: String,
	newExtension: FileExtension)
	: String
{
	val components: MutableList<String> = filePath.split(separator = "/", omittingEmptySubsequences = false)
	var newComponents: MutableList<String> = components.dropLast(1).map { it }.toMutableList()
	val nameComponent: String = components.lastOrNull()!!
	val nameComponents: MutableList<String> = nameComponent.split(separator = ".", omittingEmptySubsequences = false)

	if (!(nameComponents.size > 1)) {
		return filePath.withExtension(newExtension)
	}

	val nameWithoutExtension: String = nameComponents.dropLast(1).joinToString(separator = ".")
	val newName: String = nameWithoutExtension.withExtension(newExtension)

	newComponents.add(newName)

	return newComponents.joinToString(separator = "/")
}

fun Utilities.Companion.fileWasModifiedLaterThan(
	filePath: String, otherFilePath: String): Boolean
{
	val file = File(filePath)
	val fileModifiedDate = file.lastModified()
	val otherFile = File(otherFilePath)
	val otherFileModifiedDate = otherFile.lastModified()
	val isAfter = fileModifiedDate > otherFileModifiedDate
	return isAfter
}
