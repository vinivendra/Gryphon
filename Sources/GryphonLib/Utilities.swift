//
// Copyright 2018 Vinicius Jorge Vendramini
//
// Licensed under the Hippocratic License, Version 2.1;
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://firstdonoharm.dev/version/2/1/license
//
// To the full extent allowed by law, this software comes "AS IS,"
// WITHOUT ANY WARRANTY, EXPRESS OR IMPLIED, and licensor and any other
// contributor shall not be liable to anyone for any damages or other
// liability arising from, out of, or in connection with the sotfware
// or this license, under any kind of legal claim.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

// MARK: - Instruments logs

#if canImport(os)
import os

// Logs for macOS's Instruments
internal class Log {
	static private let os_log = OSLog(
		subsystem: "com.gryphon.app",
		category: "PointsOfInterest"
	)

	struct LogInfo {
		let name: StaticString
		let id: Any
	}

	static func startLog(name: StaticString) -> LogInfo {
		if #available(OSX 10.14, *) {
			let id = OSSignpostID(log: os_log)
			os_signpost(
				.begin,
				log: Log.os_log,
				name: name,
				signpostID: id)
			return LogInfo(name: name, id: id)
		}
		else {
			return LogInfo(name: "", id: 0)
		}
	}

	static func endLog(info: LogInfo) {
		if #available(OSX 10.14, *) {
			os_signpost(
				.end,
				log: Log.os_log,
				name: info.name,
				signpostID: info.id as! OSSignpostID)
		}
	}
}

#else

// Do nothing on Linux
internal class Log {
	struct LogInfo {
		let name: StaticString
		let id: Any
	}

	static func startLog(name: StaticString) -> LogInfo {
		return LogInfo(name: "", id: 0)
	}

	static func endLog(info: LogInfo) { }
}

#endif

// MARK: - Concurrency

/// Used for synchronizing anything that prints to either stdout or stderr
internal let printingLock = NSLock()

class Atomic<Value> {
    private var value: Value
	private let lock = NSLock()

	init(_ value: Value) {
        self.value = value
    }

	/// Access this value atomically.
    var atomic: Value {
        get {
			lock.lock()
			let result = value
			lock.unlock()
			return result
		}
        set {
			lock.lock()
			value = newValue
			lock.unlock()
		}
    }

	/// Use this to mutate the value (to guarantee that the get and set are atomic). Returns the new
	/// value.
	@discardableResult
	func mutateAtomically<Result>(_ closure: (inout Value) throws -> (Result)) rethrows -> Result {
		lock.lock()
		let result = try closure(&value)
		lock.unlock()
		return result
	}
}

extension List {

	/// Meant for concurrently executing a map in an array with few elements and with an expensive
	/// transform.
	/// Technically it's O(n lg(n)) since the array has to be sorted at the end, but it's expected
	/// that the transforms will take much longer than the sorting.
	public func parallelMap<Result>(_ transform: @escaping (Element) throws -> Result)
	throws -> List<Result>
	{
		guard self.count > 1 else {
			return try self.map(transform)
		}

		let concurrentQueue = DispatchQueue(
			label: "com.gryphon.ParallelMap", attributes: .concurrent)

		var thrownError: Error?

		let lock = NSLock()
		let group = DispatchGroup()
		for _ in self {
			group.enter()
		}

		let selfEnumerated = MutableList<(offset: Int, element: Element)>(self.enumerated())
		let unsortedResult: MutableList<(index: Int, element: Result)> = []

		concurrentQueue.async {
			DispatchQueue.concurrentPerform(iterations: selfEnumerated.count)
			{ (threadIndex: Int) in
				let enumeratedItem = selfEnumerated[threadIndex]
				let index = enumeratedItem.offset
				let oldElement = enumeratedItem.element

				do {
					// This is the line that takes a while
					let newElement = try transform(oldElement)

					// Avoid accessing the result array simultaneously. This should be quick and
					// rare.
					lock.lock()
					unsortedResult.append((index: index, element: newElement))
					lock.unlock()
				}
				catch let error {
					thrownError = error
				}

				group.leave()
			}
		}

		// Wait for all elements to finish processing
		group.wait()

		if let thrownError = thrownError {
			throw thrownError
		}

		// Elements may have been added in any order. We have to re-sort the array.
		let result = unsortedResult.sorted { (leftIndexedElement, rightIndexedELement) -> Bool in
			leftIndexedElement.index < rightIndexedELement.index
		}.map {
			$0.element
		}

		return result
	}
}

// MARK: - OS-specific constants

public class OS {
	enum OSType {
		case macOS
		case linux
	}

	#if os(macOS)
	static let osName = "macOS"
	static let osType = OSType.macOS
	#else
	static let osName = "Linux"
	static let osType = OSType.linux
	#endif

	#if arch(x86_64)
	static let architecture = "x86_64"
	#elseif arch(i386)
	static let architecture = "i386"
	#elseif arch(arm)
	static let architecture = "arm"
	#elseif arch(arm64)
	static let architecture = "arm64"
	#else
	static let architecture = "unknownArch"
	#endif

	public static let systemIdentifier: String = osName + "-" + architecture

  static let kotlinCompilerPath = ProcessInfo.processInfo.environment["KOTLINC_PATH"]
    ?? ((osType == .linux) ?
      "/opt/kotlinc/bin/kotlinc" :
      "/usr/local/bin/kotlinc")
}

// MARK: - Error handling

public struct GryphonError: Error, CustomStringConvertible {
	let errorMessage: String

	public var description: String {
		return errorMessage
	}

	init(errorMessage: String) {
		self.errorMessage = errorMessage
	}
}

// MARK: - Misc Utilities

extension String {
	func isArrayDeclaration() -> Bool {
		if (self.hasPrefix("[") && !self.contains(":")) ||
			self == "Array" ||
			self.hasPrefix("Array<")
		{
			return true
		}
		else {
			return false
		}
	}

	func isDictionaryDeclaration() -> Bool {
		if (self.hasPrefix("[") && self.contains(":")) ||
			self == "Dictionary" ||
			self.hasPrefix("Dictionary<")
		{
			return true
		}
		else {
			return false
		}
	}
}

public class Utilities {
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

	/// Splits a type using the given separators, taking into consideration possible brackets.
	/// For instance, "A, (B, C)" becomes ["A", "(B, C)"] rather than ["A", "(B", "C)"].
	static func splitTypeList(
		_ typeList: String,
		separators: List<String> = [",", ":"])
	-> MutableList<String>
	{
		var bracketsLevel = 0
		let result: MutableList<String> = []
		var currentResult = ""
		var remainingString = Substring(typeList)

		var index = typeList.startIndex

		while index < typeList.endIndex {
			let character = typeList[index]

			// If we're not inside brackets and we've found a separator
			if bracketsLevel <= 0,
			   let foundSeparator = separators.first(where: { remainingString.hasPrefix($0) })
			{
				// Skip the separator
				index = typeList.index(index, offsetBy: foundSeparator.count)
				remainingString = typeList[index...]

				// Add the built result to the array
				result.append(currentResult.trimmingWhitespaces())
				currentResult = ""
				continue
			}
			else if remainingString.hasPrefix("->") {
				// Avoid having the '>' in "->" be counted as a closing '>'
				currentResult.append("->")
				index = typeList.index(index, offsetBy: 2)
				remainingString = typeList[index...]
				continue
			}
			else if character == "<" || character == "[" || character == "(" {
				bracketsLevel += 1
				currentResult.append(character)
			}
			else if character == ">" || character == "]" || character == ")" {
				bracketsLevel -= 1
				currentResult.append(character)
			}
			else {
				currentResult.append(character)
			}

			remainingString = remainingString.dropFirst()
			index = typeList.index(after: index)
		}

		// Add the last result that was being built
		if !currentResult.isEmpty {
			result.append(currentResult.trimmingWhitespaces())
		}

		return result
	}

	static func isInEnvelopingParentheses(_ typeName: String) -> Bool {
		var parenthesesLevel = 0

		guard typeName.hasPrefix("("), typeName.hasSuffix(")") else {
			return false
		}

		let lastValidIndex = typeName.index(before: typeName.endIndex)

		for index in typeName.indices {
			let character = typeName[index]

			if character == "(" {
				parenthesesLevel += 1
			}
			else if character == ")" {
				parenthesesLevel -= 1
			}

			// If the first parentheses closes before the end of the string
			if parenthesesLevel == 0, index != lastValidIndex {
				return false
			}
		}

		return true
	}

	static func getTypeMapping(for typeName: String) -> String? {
		let typeMappings: MutableMap = [
			"Bool": "Boolean",
			"Error": "Exception",
			"UInt8": "UByte",
			"UInt16": "UShort",
			"UInt32": "UInt",
			"UInt64": "ULong",
			"Int8": "Byte",
			"Int16": "Short",
			"Int32": "Int",
			"Int64": "Long",
			"Float32": "Float",
			"Float64": "Double",
			"Character": "Char",

			"AnyHashable": "Any",

			"String.Index": "Int",
			"DefaultIndices<String>.Element": "Int",
			"Substring.Index": "Int",
			"Substring": "String",
			"String.SubSequence": "String",
			"Substring.SubSequence": "String",
			"Substring.Element": "Char",
			"String.Element": "Char",
			"Range<String.Index>": "IntRange",
			"Range<Int>": "IntRange",
			"Range<Int>.Element": "Int",
		]

		if let result = typeMappings[typeName] {
			return result
		}

		// Handle arrays that can contain any element type
		if typeName.hasPrefix("Array<") ||
			typeName.hasPrefix("List<") ||
			typeName.hasPrefix("MutableList<")
		{
			if typeName.hasSuffix(">.Index") {
				return "Int"
			}
			else if typeName.hasSuffix(">.ArrayLiteralElement") {
				let prefix = typeName.prefix { $0 != "<" }
				let elementType = String(typeName
											.dropFirst(prefix.count + 1)
											.dropLast(">.ArrayLiteralElement".count))
				return elementType
			}
		}

		return nil
	}
}

// MARK: - File handling

public enum FileExtension: String {
	case swiftAST
	case gryphonASTRaw
	case gryphonAST
	case output
	case kotlinErrorMap
	case kt
	case swift

	case xcfilelist
	case xcodeproj
	case config
}

extension String {
	func withExtension(_ fileExtension: FileExtension) -> String {
		return self + "." + fileExtension.rawValue
	}
}

extension Utilities {
	public static func changeExtension(
		of filePath: String,
		to newExtension: FileExtension)
	-> String
	{
		let components = filePath.split(withStringSeparator: "/", omittingEmptySubsequences: false)
		let newComponents = components.dropLast().toMutableList()
		let nameComponent = components.last!
		let nameComponents =
			nameComponent.split(withStringSeparator: ".", omittingEmptySubsequences: false)

		// If there's no extension
		guard nameComponents.count > 1 else {
			return filePath.withExtension(newExtension)
		}

		let nameWithoutExtension = nameComponents.dropLast().joined(separator: ".")
		let newName = nameWithoutExtension.withExtension(newExtension)
		newComponents.append(newName)
		return newComponents.joined(separator: "/")
	}

	public static func getExtension(of filePath: String) -> FileExtension? {
		let components = filePath.split(withStringSeparator: "/", omittingEmptySubsequences: false)
		let nameComponent = components.last!
		let nameComponents =
			nameComponent.split(withStringSeparator: ".", omittingEmptySubsequences: false)

		// If there's no extension
		guard let extensionString = nameComponents.last else {
			return nil
		}

		return FileExtension(rawValue: extensionString)
	}

	public static func fileHasExtension(_ filePath: String, _ testExtension: FileExtension) -> Bool
	{
		if let fileExtension = getExtension(of: filePath),
		   fileExtension == testExtension
		{
			return true
		}
		else {
			return false
		}
	}

	public static func file(
		_ filePath: String, wasModifiedLaterThan otherFilePath: String) -> Bool
	{
		let fileManager = FileManager.default
		let fileAttributes = try! fileManager.attributesOfItem(atPath: filePath)
		let otherFileAttributes = try! fileManager.attributesOfItem(atPath: otherFilePath)

		let fileModifiedDate = fileAttributes[.modificationDate] as! Date
		let otherFileModifiedDate = otherFileAttributes[.modificationDate] as! Date

		let howMuchLater = fileModifiedDate.timeIntervalSince(otherFileModifiedDate)

		return howMuchLater > 0
	}

	internal static func readFile(_ filePath: String) throws -> String {
		do {
			let result = try String(contentsOfFile: filePath)
			return result
		}
		catch let error {
			throw GryphonError(errorMessage: "Error reading file \(filePath).\n\(error)")
		}
	}

	@discardableResult
	internal static func createFile(
		named fileName: String,
		inDirectory directory: String,
		containing contents: String)
		throws -> String
	{
		// Create directory (and intermediate directories if needed)
		let fileManager = FileManager.default
		try! fileManager.createDirectory(atPath: directory, withIntermediateDirectories: true)

		// Create file path
		let filePath = directory + "/" + fileName
		let fileURL = URL(fileURLWithPath: filePath)

		// Delete file if it exists, do nothing if it doesn't
		try? fileManager.removeItem(at: fileURL)

		// Create the file and write to it
		try createFile(atPath: filePath, containing: contents, createIntermediateFolders: false)

		return filePath
	}

	internal static func createFile(
		atPath filePath: String,
		containing contents: String,
		createIntermediateFolders: Bool)
		throws
	{
		if createIntermediateFolders {
			let folderPath = filePath.split(separator: "/").dropLast().joined(separator: "/")
			createFolderIfNeeded(at: folderPath)
		}

		let fileManager = FileManager.default
		let successful = fileManager.createFile(atPath: filePath, contents: Data(contents.utf8))
		if !successful {
			if createIntermediateFolders {
				throw GryphonError(errorMessage: "Error writing to file \(filePath)")
			}
			else {
				throw GryphonError(errorMessage:
					"Error writing to file \(filePath).\n" +
					"If the file path is right but the folder doesn't exist, try using the " +
					"`--create-folders` argument to create any necessary intermediate folders.")
			}
		}
	}

	public static func fileExists(at filePath: String) -> Bool {
		let fileManager = FileManager.default
		return fileManager.fileExists(atPath: filePath)
	}

	/// - Returns: `true` if the file was created, `false` if it already existed.
	public static func createFileIfNeeded(at filePath: String) -> Bool {
        if !Utilities.fileExists(at: filePath) {
            let fileManager = FileManager.default
			let success = fileManager.createFile(atPath: filePath, contents: nil)
			assert(success)
			return true
		}
		else {
			return false
		}
	}

	/// Creates the folder if needed, as well as any nonexistent parent folders
	public static func createFolderIfNeeded(at path: String) {
		let fileManager = FileManager.default
		try! fileManager.createDirectory(atPath: path, withIntermediateDirectories: true)
	}

	public static func deleteFolder(at path: String) {
		let fileManager = FileManager.default
		try? fileManager.removeItem(atPath: path)
	}

	public static func deleteFile(at path: String) {
		let fileManager = FileManager.default
		try? fileManager.removeItem(atPath: path)
	}

	/// The absolute path to the current folder
	static func getCurrentFolder() -> String {
		return FileManager.default.currentDirectoryPath
	}

	static func getFiles(
		_ selectedFiles: List<String>? = nil,
		inDirectory directory: String,
		withExtension fileExtension: FileExtension)
		-> List<String>
	{
		let directoryPath = Utilities.getCurrentFolder() + "/\(directory)/"
		let currentURL = URL(fileURLWithPath: directoryPath)
		let allURLs = List<URL>(try! FileManager.default.contentsOfDirectory(
			at: currentURL,
			includingPropertiesForKeys: nil))
		let filteredURLs = allURLs.filter { $0.pathExtension == fileExtension.rawValue }
		let sortedURLs = filteredURLs.sorted { (url1: URL, url2: URL) -> Bool in
				url1.absoluteString < url2.absoluteString
		}

		let selectedURLs: List<URL>
		if let selectedFiles = selectedFiles {
			selectedURLs = sortedURLs.filter { url in
				let fileName = url.lastPathComponent
				let fileNameWithoutExtension = url.deletingPathExtension().lastPathComponent
				return selectedFiles.contains(fileName) ||
					selectedFiles.contains(fileNameWithoutExtension)
			}
		}
		else {
			selectedURLs = sortedURLs
		}

		return selectedURLs.map { $0.path }
	}

	public static func getAbsolutePath(forFile file: String) -> String {
		return "/" + URL(fileURLWithPath: file).pathComponents.dropFirst().joined(separator: "/")
	}

	public static func getRelativePath(forFile file: String) -> String {
		let currentDirectoryPath = Utilities.getCurrentFolder()
		let absoluteFilePath = getAbsolutePath(forFile: file)
		return String(absoluteFilePath.dropFirst(currentDirectoryPath.count + 1))
	}
}
