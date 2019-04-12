import java.io.File
import java.io.FileWriter

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

class OS {
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
	destinationExtension: FileExtension)
	: Boolean
{
	val testFiles: MutableList<String> = getFiles(selectedFiles = files, directory = folder, fileExtension = originExtension)
	for (originFile in testFiles) {
		val destinationFilePath: String = Utilities.changeExtension(filePath = originFile, newExtension = destinationExtension)
		val destinationFileWasJustCreated: Boolean = Utilities.createFileIfNeeded(filePath = destinationFilePath)
		val destinationFileIsOutdated: Boolean = destinationFileWasJustCreated || Utilities.fileWasModifiedLaterThan(originFile, destinationFilePath)

		if (destinationFileIsOutdated) {
			return true
		}
	}
	return false
}
