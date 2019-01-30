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

public enum GRYUtils {
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

public enum GRYFileExtension: String {
	// This should be the same as the extension in the dump-ast.pl and separateASTs.pl files
	case swiftAstDump
	case grySwiftAst
	case gryRawAst
	case gryAst

	case output

	case kt
	case swift

	//
	static func + (string: String, fileExtension: GRYFileExtension) -> String {
		return string + "." + fileExtension.rawValue
	}
}

extension GRYUtils {
	public static func changeExtension(of filePath: String, to newExtension: GRYFileExtension)
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

extension GRYUtils {
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

	public static let buildFolder = ".kotlinBuild-\(GRYUtils.systemIdentifier)"

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

extension GRYUtils {
	enum GRYFileError: Error, CustomStringConvertible {
		case outdatedFile(filePath: String)

		var description: String {
			switch self {
			case let .outdatedFile(filePath: filePath):
				return "Outdated file: \(filePath)\n" +
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

		let folder = "Library Templates"
		print("Updating files...")

		try updateFiles(in: folder, from: .swift, to: .swiftAstDump)
		{ (_: String, astFilePath: String) in
			// The swiftAstDump files must be updated externally by the perl script. If any files
			// are out of date, this closure gets called and informs the user how to update them.
			throw GRYFileError.outdatedFile(filePath: astFilePath)
		}

		try updateFiles(in: folder, from: .swiftAstDump, to: .grySwiftAst)
		{ (dumpFilePath: String, cacheFilePath: String) in
			let ast = try GRYSwiftAST(decodeFromSwiftASTDumpInFile: dumpFilePath)
			try ast.encode(intoFile: cacheFilePath)
		}

		try updateFiles(in: folder, from: .grySwiftAst, to: .gryRawAst)
		{ (swiftASTFilePath: String, gryphonASTRawFilePath: String) in
			let swiftAST = try GRYSwiftAST(decodeFromFile: swiftASTFilePath)
			let gryphonAST = try GRYSwift4Translator().translateAST(swiftAST)
			try gryphonAST.encode(intoFile: gryphonASTRawFilePath)
		}

		libraryFilesHaveBeenUpdated = true

		print("Done!")
	}

	static private var testFilesHaveBeenUpdated = false

	static public func updateTestFiles() throws {
		guard !testFilesHaveBeenUpdated else {
			return
		}

		try updateLibraryFiles()

		let folder = "Test Files"
		print("Updating files...")

		try updateFiles(in: folder, from: .swift, to: .swiftAstDump)
		{ (_: String, astFilePath: String) in
			// The swiftAstDump files must be updated externally by the perl script. If any files
			// are out of date, this closure gets called and informs the user how to update them.
			throw GRYFileError.outdatedFile(filePath: astFilePath)
		}

		try updateFiles(in: folder, from: .swiftAstDump, to: .grySwiftAst)
		{ (dumpFilePath: String, cacheFilePath: String) in
			let ast = try GRYSwiftAST(decodeFromSwiftASTDumpInFile: dumpFilePath)
			try ast.encode(intoFile: cacheFilePath)
		}

		try updateFiles(in: folder, from: .grySwiftAst, to: .gryRawAst)
		{ (swiftASTFilePath: String, gryphonASTRawFilePath: String) in
			let swiftAST = try GRYSwiftAST(decodeFromFile: swiftASTFilePath)
			let gryphonAST = try GRYSwift4Translator().translateAST(swiftAST)
			try gryphonAST.encode(intoFile: gryphonASTRawFilePath)
		}

		try updateFiles(in: folder, from: .gryRawAst, to: .gryAst)
		{ (gryphonASTRawFilePath: String, gryphonASTFilePath: String) throws in
			let gryphonASTRaw = try GRYAST(decodeFromFile: gryphonASTRawFilePath)
			let gryphonAST = GRYTranspilationPass.runAllPasses(on: gryphonASTRaw)
			try gryphonAST.encode(intoFile: gryphonASTFilePath)
		}

		testFilesHaveBeenUpdated = true

		print("Done!")
	}

	static private func updateFiles(
		in folder: String,
		from originExtension: GRYFileExtension,
		to destinationExtension: GRYFileExtension,
		withUpdateClosure update: (String, String) throws -> ()) rethrows
	{
		let currentURL = URL(fileURLWithPath: Process().currentDirectoryPath + "/" + folder)
		let fileURLs = try! FileManager.default.contentsOfDirectory(
			at: currentURL,
			includingPropertiesForKeys: nil)
		let testFiles = fileURLs.filter { $0.pathExtension == originExtension.rawValue }.sorted
		{ (url1: URL, url2: URL) -> Bool in
			url1.absoluteString < url2.absoluteString
		}

		for originFile in testFiles {
			let originFilePath = originFile.path
			let destinationFilePath =
				GRYUtils.changeExtension(of: originFilePath, to: destinationExtension)

			let destinationFileWasJustCreated =
				GRYUtils.createFileIfNeeded(at: destinationFilePath, containing: "")
			let destinationFileIsOutdated = destinationFileWasJustCreated ||
				GRYUtils.file(originFilePath, wasModifiedLaterThan: destinationFilePath)

			if destinationFileIsOutdated {
				print("\tUpdating \(destinationFilePath)...")
				try update(originFilePath, destinationFilePath)
			}
		}
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////
extension GRYUtils {
	internal static var rng: RandomGenerator = Xoroshiro()
}

internal extension RandomGenerator {
	mutating func random(_ range: Range<Int>) -> Int {
		let rangeSize = range.upperBound - range.lowerBound
		let randomNumber = Int(random32()) % rangeSize
		return range.lowerBound + randomNumber
	}

	mutating func random(_ range: ClosedRange<Int>) -> Int {
		let rangeSize = range.upperBound - range.lowerBound + 1
		let randomNumber = Int(random32()) % rangeSize
		return range.lowerBound + randomNumber
	}

	mutating func randomBool() -> Bool {
		return random(0...1) == 0
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////
internal extension RandomAccessCollection where Index == Int {
	func randomElement() -> Element {
		let index = GRYUtils.rng.random(0..<count)
		return self[index]
	}
}

internal extension RandomAccessCollection where Element: Equatable, Index == Int {
	func distinctRandomElements() -> (Element, Element) {
		precondition(count > 1)
		let first = randomElement()
		while true {
			let second = randomElement()
			if second != first {
				return (first, second)
			}
		}
	}
}
