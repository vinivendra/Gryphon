//
// Copyright 2018 Vinícius Jorge Vendramini
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import java.io.File
import java.io.FileWriter
import java.util.stream.Collectors
import java.util.stream.Stream
import java.util.concurrent.Semaphore

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

fun Utilities.Companion.filesWereModifiedLaterThan(
	filePaths: MutableList<String>, otherFilePaths: MutableList<String>): Boolean
{
	if (!(!filePaths.isEmpty() && !otherFilePaths.isEmpty())) {
		return true
	}

	// Get the latest modification date among the first files
	var latestDate: Long? = null
	for (filePath in filePaths) {
		val file = File(filePath)
		val fileModifiedDate = file.lastModified()

		if (latestDate != null &&
			(latestDate < fileModifiedDate))
		{
			latestDate = fileModifiedDate
		}
		else {
			latestDate = fileModifiedDate
		}
	}

	// Ensure that latest date is still before all dates from other files
	for (filePath in otherFilePaths) {
		val file = File(filePath)
		val fileModifiedDate = file.lastModified()

		if (latestDate!! > fileModifiedDate) {
			return true
		}
	}

	return false
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

fun Utilities.Companion.createFolderIfNeeded(path: String) {
	val directoryFile = File(path)
	directoryFile.mkdirs()
}

fun Utilities.Companion.deleteFolder(path: String) {
	var directoryFile = File(path)
    directoryFile.deleteRecursively()
}

////////////////////////////////////////////////////////////////////////////////////////////////////

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

val libraryUpdateLock: Semaphore = Semaphore(1)

////////////////////////////////////////////////////////////////////////////////////////////////////

fun <Element, Result> MutableList<Element>.parallelMap(
	transform: (Element) -> Result): MutableList<Result>
{
	return this.parallelStream().map(transform).collect(Collectors.toList())
		.toMutableList()
}
