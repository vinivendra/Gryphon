/*
* Copyright 2018 Vinícius Jorge Vendramini
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

import Foundation

public enum Utilities {
	internal static func expandSwiftAbbreviation(_ name: String) -> String {
		// Separate snake case and capitalize
		var nameComponents = name.split(withStringSeparator: "_").map { $0.capitalized }

		// Expand swift abbreviations
		nameComponents = nameComponents.map { (word: String) -> String in
			switch word {
			case "Decl": return "Declaration"
			case "Declref": return "Declaration Reference"
			case "Expr": return "Expression"
			case "Func": return "Function"
			case "Ident": return "Identity"
			case "Paren": return "Parentheses"
			case "Ref": return "Reference"
			case "Stmt": return "Statement"
			case "Var": return "Variable"
			default: return word
			}
		}

		// Join words into a single string
		return nameComponents.joined(separator: " ")
	}
}

public enum FileExtension: String {
	// This should be the same as the extension in the dumpAST.pl and separateASTs.pl files
	case swiftASTDump
	case output
	case kt
	case swift

	//
	static func + (string: String, fileExtension: FileExtension) -> String {
		return string + "." + fileExtension.rawValue
	}
}

extension Utilities {
	public static func changeExtension(of filePath: String, to newExtension: FileExtension)
		-> String
	{
		let url = URL(fileURLWithPath: filePath)
		let urlWithoutExtension = url.deletingPathExtension()
		let newURL = urlWithoutExtension.appendingPathExtension(newExtension.rawValue)
		return newURL.path
	}

	public static func file(_ filePath: String, wasModifiedLaterThan otherFilePath: String) -> Bool
	{
		let fileManager = FileManager.default
		let fileAttributes = try! fileManager.attributesOfItem(atPath: filePath)
		let otherFileAttributes = try! fileManager.attributesOfItem(atPath: otherFilePath)

		let fileModifiedDate = fileAttributes[.modificationDate] as! Date
		let otherFileModifiedDate = otherFileAttributes[.modificationDate] as! Date

		let howMuchLater = fileModifiedDate.timeIntervalSince(otherFileModifiedDate)

		return howMuchLater > 0
	}
}

extension Utilities {
	public static let systemIdentifier: String = {
		#if os(macOS)
		let osName = "macOS"
		#elseif os(Linux)
		let osName = "Linux"
		#endif

		#if arch(i386)
		let arch = "i386"
		#elseif arch(x86_64)
		let arch = "x86_64"
		#endif

		return osName + "-" + arch
	}()

	public static let buildFolder = ".kotlinBuild-\(Utilities.systemIdentifier)"

	@discardableResult
	internal static func createFile(
		named fileName: String,
		inDirectory directory: String,
		containing contents: String) -> String
	{
		let fileManager = FileManager.default

		try! fileManager.createDirectory(atPath: directory, withIntermediateDirectories: true)

		let filePath = directory + "/" + fileName
		let fileURL = URL(fileURLWithPath: filePath)

		// Remove it if it already exists
		try? fileManager.removeItem(at: fileURL)

		let success = fileManager.createFile(atPath: filePath, contents: Data(contents.utf8))
		assert(success)

		return filePath
	}

	/// - Returns: `true` if the file was created, `false` if it already existed.
	public static func createFileIfNeeded(at filePath: String, containing contents: String) -> Bool
	{
		let fileManager = FileManager.default

		if !fileManager.fileExists(atPath: filePath) {
			let success = fileManager.createFile(atPath: filePath, contents: Data(contents.utf8))
			assert(success)
			return true
		}
		else {
			return false
		}
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////

extension Utilities {
	enum FileError: Error, CustomStringConvertible {
		case outdatedFile(inFolder: String)

		var description: String {
			switch self {
			case let .outdatedFile(inFolder: folder):
				return "One of the files in the \(folder) folder is outdated.\n" +
					"Try running the preBuildScript.sh and the test suite to update compilation " +
					"files."
			}
		}
	}

	static private var libraryFilesHaveBeenUpdated = false

	static public func updateLibraryFiles() throws {
		guard !libraryFilesHaveBeenUpdated else {
			return
		}

		let libraryTemplatesFolder = "Library Templates"
		if needsToUpdateFiles(in: libraryTemplatesFolder, from: .swift, to: .swiftASTDump) {
			throw FileError.outdatedFile(inFolder: libraryTemplatesFolder)
		}

		print("\t* Updating library files...")

		let libraryFilesPath = Process().currentDirectoryPath + "/\(libraryTemplatesFolder)/"
		let currentURL = URL(fileURLWithPath: libraryFilesPath)
		let fileURLs = try! FileManager.default.contentsOfDirectory(
			at: currentURL,
			includingPropertiesForKeys: nil)
		let templateFiles = fileURLs.filter {
			$0.pathExtension == FileExtension.swiftASTDump.rawValue
			}.sorted { (url1: URL, url2: URL) -> Bool in
				url1.absoluteString < url2.absoluteString
		}
		for templateFile in templateFiles {
			let ast = try Compiler.generateGryphonAST(forFileAt: templateFile.path)
			_ = RecordTemplatesTranspilationPass().run(on: ast)
		}

		libraryFilesHaveBeenUpdated = true

		print("\t* Done!")
	}

	static private var testFilesHaveBeenUpdated = false

	static public func updateTestFiles() throws {
		guard !testFilesHaveBeenUpdated else {
			return
		}

		try updateLibraryFiles()

		print("\t* Updating unit test files...")

		let testFilesFolder = "Test Files"
		if needsToUpdateFiles(in: testFilesFolder, from: .swift, to: .swiftASTDump) {
			throw FileError.outdatedFile(inFolder: testFilesFolder)
		}

		print("\t* Done!")
		print("\t* Updating bootstrap test files...")

		let bootstrapFolderName = "Bootstrap"
		let bootstrappedFiles = ["StandardLibrary", "PrintableAsTree", "ASTDumpDecoder"]
		let bootstrappedFilesPaths = bootstrappedFiles.map { bootstrapFolderName + "/" + $0 }
		if needsToUpdateFiles(
			bootstrappedFiles,
			in: bootstrapFolderName,
			from: .swiftASTDump,
			to: .kt)
		{
			try Compiler.generateKotlinCode(
				forFilesAt: bootstrappedFilesPaths, outputFolder: bootstrapFolderName)
		}

		testFilesHaveBeenUpdated = true

		print("\t* Done!")
	}

	static private func needsToUpdateFiles(
		_ files: [String]? = nil,
		in folder: String,
		from originExtension: FileExtension,
		to destinationExtension: FileExtension) -> Bool
	{
		var testFiles = getFilesInFolder(folder)
		testFiles = testFiles.filter { $0.pathExtension == originExtension.rawValue }

		if let files = files {
			testFiles = testFiles.filter {
					files.contains($0.deletingPathExtension().lastPathComponent)
				}
		}

		for originFile in testFiles {
			let originFilePath = originFile.path
			let destinationFilePath =
				Utilities.changeExtension(of: originFilePath, to: destinationExtension)

			let destinationFileWasJustCreated =
				Utilities.createFileIfNeeded(at: destinationFilePath, containing: "")
			let destinationFileIsOutdated = destinationFileWasJustCreated ||
				Utilities.file(originFilePath, wasModifiedLaterThan: destinationFilePath)

			if destinationFileIsOutdated {
				return true
			}
		}

		return false
	}

	static public func getFilesInFolder(_ folder: String) -> [URL] {
		let currentURL = URL(fileURLWithPath: Process().currentDirectoryPath + "/" + folder)
		let fileURLs = try! FileManager.default.contentsOfDirectory(
			at: currentURL,
			includingPropertiesForKeys: nil)
		return fileURLs.sorted { (url1: URL, url2: URL) -> Bool in
			url1.path < url2.path
		}
	}
}
