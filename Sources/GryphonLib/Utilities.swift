//
// Copyright 2018 Vinicius Jorge Vendramini
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

import Foundation

typealias Semaphore = NSLock

extension Utilities {
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
}

extension Utilities {
	public static func files(
		_ filePaths: MutableList<String>,
		wereModifiedLaterThan otherFilePaths: MutableList<String>)
		-> Bool
	{
		guard !filePaths.isEmpty, !otherFilePaths.isEmpty else {
			return true
		}

		let fileManager = FileManager.default

		// Get the latest modification date among the first files
		var latestDate = Date.distantPast
		for filePath in filePaths {
			let fileAttributes = try! fileManager.attributesOfItem(atPath: filePath)
			let fileModifiedDate = fileAttributes[.modificationDate] as! Date

			if !latestDate.isAfter(fileModifiedDate) {
				latestDate = fileModifiedDate
			}
		}

		// Ensure that latest date is still before all dates from other files
		for filePath in otherFilePaths {
			let fileAttributes = try! fileManager.attributesOfItem(atPath: filePath)
			let fileModifiedDate = fileAttributes[.modificationDate] as! Date

			if latestDate.isAfter(fileModifiedDate) {
				return true
			}
		}

		return false
	}
}

fileprivate extension Date {
	func isAfter(_ other: Date) -> Bool {
		return (self.timeIntervalSince(other) > 0)
	}
}

extension Utilities {
	internal static func readFile(_ filePath: String) throws -> String {
		return try String(contentsOfFile: filePath)
	}
}

extension Utilities {
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
		try createFile(atPath: filePath, containing: contents)

		return filePath
	}

	internal static func createFile(atPath filePath: String, containing contents: String) throws {
		let fileManager = FileManager.default
		let successful = fileManager.createFile(atPath: filePath, contents: Data(contents.utf8))
		if !successful {
			throw GryphonError(errorMessage: "Error writing to file \(filePath)")
		}
	}
}

extension Utilities {
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

	public static func createFolderIfNeeded(at path: String) {
		let fileManager = FileManager.default
		try! fileManager.createDirectory(atPath: path, withIntermediateDirectories: true)
	}
}

extension Utilities {
	public static func deleteFolder(at path: String) {
		let fileManager = FileManager.default
		try? fileManager.removeItem(atPath: path)
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////

extension Utilities {
	static func getCurrentFolder() -> String {
		return FileManager.default.currentDirectoryPath
	}

	static func getFiles(
		_ selectedFiles: MutableList<String>? = nil,
		inDirectory directory: String,
		withExtension fileExtension: FileExtension)
		-> MutableList<String>
	{
		let directoryPath = Utilities.getCurrentFolder() + "/\(directory)/"
		let currentURL = URL(fileURLWithPath: directoryPath)
		let allURLs = MutableList<URL>(try! FileManager.default.contentsOfDirectory(
			at: currentURL,
			includingPropertiesForKeys: nil))
		let filteredURLs = allURLs.filter { $0.pathExtension == fileExtension.rawValue }
		let sortedURLs = filteredURLs.sorted { (url1: URL, url2: URL) -> Bool in
				url1.absoluteString < url2.absoluteString
		}

		let selectedURLs: MutableList<URL>
		if let selectedFiles = selectedFiles {
			selectedURLs = sortedURLs.filter { url in
				let fileName = url.deletingPathExtension().lastPathComponent
				return selectedFiles.contains(fileName)
			}.toMutableList()
		}
		else {
			selectedURLs = sortedURLs.toMutableList()
		}

		return selectedURLs.map { $0.path }.toMutableList()
	}
}

extension Utilities {
	public static func getAbsoultePath(forFile file: String) -> String {
		return "/" + URL(fileURLWithPath: file).pathComponents.dropFirst().joined(separator: "/")
	}
}

internal let libraryUpdateLock: Semaphore = NSLock()

//
extension List {

	/// Meant for concurrently executing a map in an array with few elements and with an expensive
	/// transform.
	/// Technically it's O(n lg(n)) since the array has to be sorted at the end, but it's expected
	/// that the transforms will take much longer than the sorting.
	public func parallelMap<Result>(_ transform: @escaping (Element) throws -> Result)
		throws -> MutableList<Result>
	{
		guard self.count > 1 else {
			return try self.map(transform).toMutableList()
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

		return result.toMutableList()
	}
}
