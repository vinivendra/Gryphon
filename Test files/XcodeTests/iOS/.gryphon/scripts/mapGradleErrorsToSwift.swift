// WARNING: Any changes to this file should be reflected in the literal string in
// AuxiliaryFileContents.swift

// This script should be run on a folder initialized by Gryphon (i.e. containing the relevant
// `.gryphon` folder)

// Examples of compatible errors:
//e: /path/to/Model.kt: (15, 2): Expecting member declaration
//e: /path/to/Model.kt: (12, 44): Unresolved reference: foo

import Foundation

func getAbsoultePath(forFile file: String) -> String {
	return "/" + URL(fileURLWithPath: file).pathComponents.dropFirst().joined(separator: "/")
}

func getRelativePath(forFile file: String) -> String {
	let currentDirectoryPath = FileManager.default.currentDirectoryPath
	let absoluteFilePath = getAbsoultePath(forFile: file)
	return String(absoluteFilePath.dropFirst(currentDirectoryPath.count + 1))
}

struct ErrorInformation {
	let filePath: String
	let lineNumber: Int
	let columnNumber: Int
	let errorMessage: String
	let isError: Bool
}

func getInformation(fromString string: String) -> ErrorInformation? {
	let components = string.split(separator: ":")
	let filePath = String(components[1].dropFirst()) // Drop the first space
	let lineAndColumn = components[2].dropFirst(2).dropLast().split(separator: ",")

	guard let lineNumber = Int(lineAndColumn[0]),
		let columnNumber = Int(lineAndColumn[1].dropFirst()) else
	{
		return nil
	}

	return ErrorInformation(
		filePath: getRelativePath(forFile: filePath),
		lineNumber: lineNumber,
		columnNumber: columnNumber,
		errorMessage: String(components[3...].joined(separator: ":")),
		isError: components[0] == "e")
}

struct SourceFileRange {
	let lineStart: Int
	let columnStart: Int
	let lineEnd: Int
	let columnEnd: Int
}

struct Mapping {
	let kotlinRange: SourceFileRange
	let swiftRange: SourceFileRange
}

struct ErrorMap {
	let kotlinFilePath: String
	let swiftFilePath: String
	let mappings: [Mapping]

	init(kotlinFilePath: String, contents: String) {
		self.kotlinFilePath = kotlinFilePath

		let components = contents.split(separator: "\n")
		self.swiftFilePath = String(components[0])

		self.mappings = components.dropFirst().map { string in
			let mappingComponents = string.split(separator: ":")
			let kotlinRange = SourceFileRange(
				lineStart: Int(mappingComponents[0])!,
				columnStart: Int(mappingComponents[1])!,
				lineEnd: Int(mappingComponents[2])!,
				columnEnd: Int(mappingComponents[3])!)
			let swiftRange = SourceFileRange(
				lineStart: Int(mappingComponents[4])!,
				columnStart: Int(mappingComponents[5])!,
				lineEnd: Int(mappingComponents[6])!,
				columnEnd: Int(mappingComponents[7])!)
			return Mapping(kotlinRange: kotlinRange, swiftRange: swiftRange)
		}
	}

	func getSwiftRange(forKotlinLine line: Int, column: Int) -> SourceFileRange? {
		for mapping in mappings {
			if compare(
					line1: mapping.kotlinRange.lineStart,
					column1: mapping.kotlinRange.columnStart,
					isBeforeLine2: line,
					column2: column),
				compare(
					line1: line,
					column1: column,
					isBeforeLine2: mapping.kotlinRange.lineEnd,
					column2: mapping.kotlinRange.columnEnd)
			{
				return mapping.swiftRange
			}
		}

		return nil
	}

	func compare(line1: Int, column1: Int, isBeforeLine2 line2: Int, column2: Int) -> Bool {
		if line1 < line2 {
			return true
		}
		else if line1 == line2 {
			if column1 <= column2 {
				return true
			}
		}

		return false
	}
}

/// Maps Kotlin errors to hints about how to fix them
let errorHints: [(kotlinError: String, hint: String)] = [
	("type has a constructor, and thus must be initialized here",
		"try explicitly declaring an initializer for this type"),
	("type argument expected for class",
		"try adding a \"// gryphon generics:\" comment")]

func getHint(forErrorMessage errorMessage: String) -> String? {
	return errorHints.first(where: { errorHint in
			errorMessage.contains(errorHint.kotlinError)
		})?.hint
}

////////////////////////////////////////////////////////////////////////////////////////////////////
var input: [String] = []

// Read all the input, separated into lines
while let nextLine = readLine(strippingNewline: false) {
	input.append(nextLine)
}

// Get only lines with errors and warnings
var errors = input.filter { $0.hasPrefix("e: ") || $0.hasPrefix("w: ") }

// Handle the errors
var errorMaps: [String: ErrorMap] = [:]
for error in errors {
	guard let errorInformation = getInformation(fromString: error) else {
		print("🚨 Unrecognized error:")
		print(error)
		continue
	}

	let errorMapPath =
		".gryphon/KotlinErrorMaps/" + errorInformation.filePath.dropLast(2) +
		"kotlinErrorMap"

	if errorMaps[errorMapPath] == nil {
		if let fileContents = try? String(contentsOfFile: errorMapPath) {
			errorMaps[errorMapPath] = ErrorMap(
				kotlinFilePath: errorInformation.filePath,
				contents: fileContents)
		}
		else {
			// Print error with the available information
			let errorString = errorInformation.isError ? "error" : "warning"
			print("\(getAbsoultePath(forFile: errorInformation.filePath)):" +
				"\(errorInformation.lineNumber):" +
				"\(errorInformation.columnNumber): " +
				"\(errorString):\(errorInformation.errorMessage)")
			continue
		}
	}

	let errorMap = errorMaps[errorMapPath]!

	let errorString = errorInformation.isError ? "error" : "warning"

	if let swiftRange = errorMap.getSwiftRange(
		forKotlinLine: errorInformation.lineNumber,
		column: errorInformation.columnNumber)
	{
		if let hint = getHint(forErrorMessage: errorInformation.errorMessage) {
			let lines = errorInformation.errorMessage.split(separator: "\n")
			let errorMessage = lines[0] + " (Gryphon hint: \(hint))\n" +
				lines.dropFirst().joined(separator: "\n")

			print("\(getAbsoultePath(forFile: errorMap.swiftFilePath)):\(swiftRange.lineStart):" +
				"\(swiftRange.columnStart): \(errorString):\(errorMessage)")
		}
		else {
			print("\(getAbsoultePath(forFile: errorMap.swiftFilePath)):\(swiftRange.lineStart):" +
				"\(swiftRange.columnStart): \(errorString):\(errorInformation.errorMessage)")
		}
	}
	else {
		// Print error with the available information
		print("\(getAbsoultePath(forFile: errorMap.swiftFilePath)):" +
			"0:0: \(errorString):\(errorInformation.errorMessage)")
	}
}

if !errors.isEmpty {
	exit(-1)
}
