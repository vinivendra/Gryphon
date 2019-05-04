import java.io.File
import java.io.FileWriter
import java.util.stream.Collectors
import java.util.stream.Stream

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
    SWIFT_AST,
    OUTPUT,
    KT,
    SWIFT;

    companion object {
        operator fun invoke(rawValue: String): FileExtension? {
            return when (rawValue) {
                "swiftASTDump" -> FileExtension.SWIFT_AST_DUMP
                "swiftAST" -> FileExtension.SWIFT_AST
                "output" -> FileExtension.OUTPUT
                "kt" -> FileExtension.KT
                "swift" -> FileExtension.SWIFT
                else -> null
            }
        }
    }

    val rawValue: String
        get() {
            return when (this) {
                FileExtension.SWIFT_AST_DUMP -> "swiftASTDump"
                FileExtension.SWIFT_AST -> "swiftAST"
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

public class OS {
	companion object {
		val javaOSName = System.getProperty("os.name")
		val osName = if (javaOSName == "Mac OS X") { "macOS" } else { "Linux" }

		val javaArchitecture = System.getProperty("os.arch")
		val architecture = if (javaArchitecture == "x86_64") { "x86_64" }
			else { "i386" }

		val systemIdentifier: String = osName + "-" + architecture
		val buildFolder = ".kotlinBuild-${systemIdentifier}"
	}
}

fun Utilities.Companion.readFile(filePath: String): String {
	return File(filePath).readText()
}

fun Utilities.Companion.createFileAndDirectory(
	fileName: String,
	directory: String,
	contents: String): String
{
	// Create directory (and intermediate directories if needed)
	val directoryFile = File(directory)
	directoryFile.mkdirs()

	// Create file path
	val filePath = directory + "/" + fileName

	// Delete file if it exists, do nothing if it doesn't
	val file = File(filePath)
	file.delete()

	// Create the file and write to it
	val success = file.createNewFile()
	assert(success)
	val writer = FileWriter(file)
	writer.write(contents)
	writer.close()

	return filePath
}

fun Utilities.Companion.createFile(filePath: String, contents: String) {
	val file = File(filePath)
	file.createNewFile()
	val writer = FileWriter(file)
	writer.write(contents)
	writer.close()
}

fun Utilities.Companion.createFileIfNeeded(filePath: String): Boolean {
	val file = File(filePath)
	if (!file.exists()) {
		val success = file.createNewFile()
		assert(success)
		return true
	}
	else {
		return false
	}
}

internal sealed class FileError: Exception() {
    class OutdatedFile(val inFolder: String): FileError()

    override fun toString(): String {
        return when (this) {
            is FileError.OutdatedFile -> {
                val folder: String = this.inFolder
                "One of the files in the ${folder} folder is outdated.\n" + "Try running the preBuildScript.sh and the test suite to update compilation " + "files."
            }
        }
    }
}

var libraryFilesHaveBeenUpdated: Boolean = false
var testFilesHaveBeenUpdated: Boolean = false

fun Utilities.Companion.getFiles(
	selectedFiles: MutableList<String>? = null,
	directory: String,
	fileExtension: FileExtension): MutableList<String>
{
	val contentsOfDirectory = File(directory).listFiles()
	val allFilesInDirectory = contentsOfDirectory.filter { it.isFile() }
	val filteredFiles = allFilesInDirectory.filter {
		it.absolutePath.endsWith(".${fileExtension.rawValue}")
	}
	val sortedFiles = filteredFiles.sortedBy { it.absolutePath }

	var selectedURLs: List<File>
	if (selectedFiles != null) {
		val selectedFilesWithExtensions = selectedFiles.map {
			it + ".${fileExtension.rawValue}"
		}

		selectedURLs = sortedFiles.filter {
			selectedFilesWithExtensions.contains(it.getName())
		}
	}
	else {
		selectedURLs = sortedFiles
	}

	return selectedURLs.map { it.absolutePath }.toMutableList()
}

public fun Utilities.Companion.getAbsoultePath(file: String): String {
    return File(file).getAbsoluteFile().normalize().absolutePath
}

public fun Utilities.Companion.updateTestFiles() {
    if (testFilesHaveBeenUpdated) {
        return
    }

    println("\t* Updating unit test files...")

    val testFilesFolder: String = "Test Files"

    if (Utilities.needsToUpdateFiles(folder = testFilesFolder, originExtension = FileExtension.SWIFT, destinationExtension = FileExtension.SWIFT_AST_DUMP)) {
        throw FileError.OutdatedFile(inFolder = testFilesFolder)
    }

    testFilesHaveBeenUpdated = true

    println("\t* Done!")
}

internal fun Utilities.Companion.needsToUpdateFiles(
    files: MutableList<String>? = null,
    folder: String,
    originExtension: FileExtension,
    destinationExtension: FileExtension,
    outputFileMap: OutputFileMap? = null)
    : Boolean
{
    val testFiles: MutableList<String> = getFiles(selectedFiles = files, directory = folder, fileExtension = originExtension)
    for (originFile in testFiles) {
        val destinationFilePath: String = outputFileMap?.getOutputFile(
            file = originFile,
            outputType = OutputFileMap.OutputType(fileExtension = destinationExtension)!!) ?: Utilities.changeExtension(filePath = originFile, newExtension = destinationExtension)
        val destinationFileWasJustCreated: Boolean = Utilities.createFileIfNeeded(filePath = destinationFilePath)
        val destinationFileIsOutdated: Boolean = destinationFileWasJustCreated || Utilities.fileWasModifiedLaterThan(originFile, destinationFilePath)

        if (destinationFileIsOutdated) {
            return true
        }
    }
    return false
}

fun <Element, Result> MutableList<Element>.parallelMap(
	transform: (Element) -> Result): MutableList<Result>
{
	return this.parallelStream().map(transform).collect(Collectors.toList())
		.toMutableList()
}

internal fun Utilities.Companion.splitTypeList(
    typeList: String,
    separators: MutableList<String> = mutableListOf(",", ":"))
    : MutableList<String>
{
    var bracketsLevel: Int = 0
    var result: MutableList<String> = mutableListOf()
    var currentResult: String = ""
    var remainingString: String = typeList
    var index: Int = 0

    while (index < typeList.length) {
        val character: Char = typeList[index]
        val foundSeparator: String? = separators.find { remainingString.startsWith(it) }

        if (bracketsLevel <= 0 && foundSeparator != null) {
            index = index + foundSeparator.length - 1
            result.add(currentResult)
            currentResult = ""
        }
        else if (character == '<' || character == '[' || character == '(') {
            bracketsLevel += 1
            currentResult += character
        }
        else if (character == '>' || character == ']' || character == ')') {
            bracketsLevel -= 1
            currentResult += character
        }
        else if (character == ' ') {
            if (bracketsLevel > 0) {
                currentResult += character
            }
        }
        else {
            currentResult += character
        }

        remainingString = remainingString.drop(1)
        index = index + 1
    }

    if (!currentResult.isEmpty()) {
        result.add(currentResult)
    }

    return result
}

internal fun Utilities.Companion.isInEnvelopingParentheses(typeName: String): Boolean {
    var parenthesesLevel: Int = 0

    if (!(typeName.startsWith("(") && typeName.endsWith(")"))) {
        return false
    }

    val lastValidIndex: Int = typeName.length - 1

    for (index in typeName.indices) {
        val character: Char = typeName[index]
        if (character == '(') {
            parenthesesLevel += 1
        }
        else if (character == ')') {
            parenthesesLevel -= 1
        }
        if (parenthesesLevel == 0 && index != lastValidIndex) {
            return false
        }
    }

    return true
}

internal fun Utilities.Companion.getTypeMapping(typeName: String): String? {
    val typeMappings: MutableMap<String, String> = mutableMapOf("Bool" to "Boolean", "Error" to "Exception", "UInt8" to "UByte", "UInt16" to "UShort", "UInt32" to "UInt", "UInt64" to "ULong", "Int8" to "Byte", "Int16" to "Short", "Int32" to "Int", "Int64" to "Long", "Float32" to "Float", "Float64" to "Double", "Character" to "Char", "String.Index" to "Int", "Substring.Index" to "Int", "Substring" to "String", "String.SubSequence" to "String", "Substring.SubSequence" to "String", "Substring.Element" to "Char", "String.Element" to "Char", "Range<String.Index>" to "IntRange", "Range<Int>" to "IntRange", "Array<Element>.Index" to "Int")
    return typeMappings[typeName]
}
