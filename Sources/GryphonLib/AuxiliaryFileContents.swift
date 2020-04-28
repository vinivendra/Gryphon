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

// gryphon output: Sources/GryphonLib/AuxiliaryFileContents.swiftAST
// gryphon output: Sources/GryphonLib/AuxiliaryFileContents.gryphonASTRaw
// gryphon output: Sources/GryphonLib/AuxiliaryFileContents.gryphonAST
// gryphon output: Bootstrap/AuxiliaryFileContents.kt

let dollarSign = "$" // gryphon value: "\\$"
let kotlinStringInterpolation = "{_string}"

// gryphon multiline
internal let gryphonXCTestFileContents = """
// Replacement for Comparable
private struct _Compare: Comparable {
	static func < (lhs: _Compare, rhs: _Compare) -> Bool {
		return false
	}
}

// Replacement for Optional
private struct _Optional { }

class XCTestCase { // gryphon ignore
	class func setUp() { }
	class func tearDown() { }

	public func XCTAssert(_ condition: Bool, _ message: String = "") { }
	public func XCTAssertEqual<T>(_ a: T, _ b: T, _ message: String = "") where T : Equatable { }
	public func XCTAssertNotEqual<T>(_ a: T, _ b: T, _ message: String = "") where T : Equatable { }
	public func XCTAssertFalse(_ condition: Bool, _ message: String = "") { }
	public func XCTAssertNil<T>(_ expression: T?, _ message: String = "") { }
	public func XCTAssertNotNil<T>(_ expression: T?, _ message: String = "") { }
	public func XCTAssertNoThrow<T>(
		_ expression: @autoclosure () throws -> T,
		_ message: String = "") { }
	public func XCTAssertThrowsError<T>(
		_ expression: @autoclosure () throws -> T,
		_ message: String = "") { }
	public func XCTFail(_ message: String = "") { }
}

extension XCTestCase {
	private func gryphonTemplates() {
		let _bool = true
		let _string = ""
		let _any1: _Compare = _Compare()
		let _any2: _Compare = _Compare()
		let _optional: _Optional? = _Optional()

		XCTAssert(_bool)
		_ = "XCTAssert(_bool)"

		XCTAssert(_bool, _string)
		_ = "XCTAssert(_bool, _string)"

		XCTAssertFalse(_bool)
		_ = "XCTAssertFalse(_bool)"

		XCTAssertFalse(_bool, _string)
		_ = "XCTAssertFalse(_bool, _string)"

		XCTAssertNil(_optional)
		_ = "XCTAssertNil(_optional)"

		XCTAssertNil(_optional, _string)
		_ = "XCTAssertNil(_optional, _string)"

		XCTAssertEqual(_any1, _any2, _string)
		_ = "XCTAssertEqual(_any1, _any2, _string)"

		XCTAssertEqual(_any1, _any2)
		_ = "XCTAssertEqual(_any1, _any2)"
	}
}

"""

// gryphon multiline
internal let gryphonTemplatesLibraryFileContents = """
// WARNING: Any changes to this file should be reflected in the literal string in
// AuxiliaryFileContents.swift

import Foundation

// MARK: - Define special types as stand-ins for some protocols and other types

// Replacement for Hashable
private struct _Hash: Hashable { }

// Replacement for Comparable
private struct _Compare: Comparable {
	static func < (lhs: _Compare, rhs: _Compare) -> Bool {
		return false
	}
}

// Replacement for Optional
private struct _Optional { }

// Replacement for Any
private struct _Any: CustomStringConvertible, LosslessStringConvertible {
	init() { }

	var description: String = ""

	init?(_ description: String) {
		return nil
	}
}

// MARK: - Define the templates
private func gryphonTemplates() {

	// MARK: Declare placeholder variables to use in the templates
	var _bool: Bool = true
	var _strArray: [String] = []
	var _array: [Any] = []
	var _array1: [Any] = []
	var _array2: [Any] = []
	let _array3: [Any] = []
	var _arrayOfOptionals: [Any?] = []
	var _comparableArray: [_Compare] = []
	let _compare = _Compare()
	var _index: String.Index = "abc".endIndex
	let _index1: String.Index = "abc".startIndex
	let _index2: String.Index = "abc".startIndex
	var _string: String = "abc"
	var _string1: String = "abc"
	let _string2: String = "abc"
	let _string3: String = "abc"
	let _character: Character = "a"
	let _substring: Substring = "abc".dropLast()
	let _range: Range<String.Index> = _string.startIndex..<_string.endIndex
	let _any: Any = "abc"
	let _anyType: _Any = _Any()
	let _optional: _Optional? = _Optional()
	let _double: Double = 0
	let _double1: Double = 0
	let _double2: Double = 0
	let _int: Int = 0
	let _int1: Int = 0
	let _int2: Int = 0
	let _dictionary: [_Hash: Any] = [:]
	let _closure: (Any, Any) -> Any = { a, b in a }
	let _closure2: (Any) -> Any = { a in a }
	let _closure3: (Any) -> Bool = { _ in true }
	let _closure4: (_Optional) -> Any = { _ in true }
	let _closure5: (Character) -> Bool = { _ in true }
	let _closure6: (Any) -> Any? = { a in a }
	let _closure7: (_Compare, _Compare) -> Bool = { _, _ in true }

	// MARK: Declare the templates

	// System
	_ = print(_any)
	_ = "println(_any)"

	_ = print(_any, terminator: "")
	_ = "print(_any)"

	_ = fatalError(_string)
	_ = "println(\\\"Fatal error: \(dollarSign)\(kotlinStringInterpolation)\\\"); exitProcess(-1)"

	_ = assert(_bool)
	_ = "assert(_bool)"

	// Darwin
	_ = sqrt(_double)
	_ = "Math.sqrt(_double)"

	// String
	_ = String(_anyType)
	_ = "_anyType.toString()"

	_ = _anyType.description
	_ = "_anyType.toString()"

	_ = _string.isEmpty
	_ = "_string.isEmpty()"

	_ = _string.count
	_ = "_string.length"

	_ = _string.first
	_ = "_string.firstOrNull()"

	_ = _string.last
	_ = "_string.lastOrNull()"

	_ = Double(_string)
	_ = "_string.toDouble()"

	_ = Float(_string)
	_ = "_string.toFloat()"

	_ = UInt64(_string)
	_ = "_string.toULong()"

	_ = Int64(_string)
	_ = "_string.toLong()"

	_ = Int(_string)
	_ = "_string.toIntOrNull()"

	_ = _string.dropLast()
	_ = "_string.dropLast(1)"

	_ = _string.dropLast(_int)
	_ = "_string.dropLast(_int)"

	_ = _string.dropFirst()
	_ = "_string.drop(1)"

	_ = _string.dropFirst(_int)
	_ = "_string.drop(_int)"

	_ = _string.indices
	_ = "_string.indices"

	_ = _string.firstIndex(of: _character)!
	_ = "_string.indexOf(_character)"

	_ = _string.contains(where: _closure5)
	_ = "(_string.find _closure5 != null)"

	_ = _string.firstIndex(of: _character)
	_ = "_string.indexOrNull(_character)"

	_ = _string.prefix(_int)
	_ = "_string.substring(0, _int)"

	_ = _string.prefix(upTo: _index)
	_ = "_string.substring(0, _index)"

	_ = _string[_index...]
	_ = "_string.substring(_index)"

	_ = _string[..<_index]
	_ = "_string.substring(0, _index)"

	_ = _string[..._index]
	_ = "_string.substring(0, _index + 1)"

	_ = _string[_index1..<_index2]
	_ = "_string.substring(_index1, _index2)"

	_ = _string[_index1..._index2]
	_ = "_string.substring(_index1, _index2 + 1)"

	_ = String(_substring)
	_ = "_substring"

	_ = _string.endIndex
	_ = "_string.length"

	_ = _string.startIndex
	_ = "0"

	_ = _string.formIndex(before: &_index)
	_ = "_index -= 1"

	_ = _string.index(after: _index)
	_ = "_index + 1"

	_ = _string.index(before: _index)
	_ = "_index - 1"

	_ = _string.index(_index, offsetBy: _int)
	_ = "_index + _int"

	_ = _substring.index(_index, offsetBy: _int)
	_ = "_index + _int"

	_ = _string1.replacingOccurrences(of: _string2, with: _string3)
	_ = "_string1.replace(_string2, _string3)"

	_ = _string1.prefix(while: _closure5)
	_ = "_string1.takeWhile _closure5"

	_ = _string1.hasPrefix(_string2)
	_ = "_string1.startsWith(_string2)"

	_ = _string1.hasSuffix(_string2)
	_ = "_string1.endsWith(_string2)"

	_ = _range.lowerBound
	_ = "_range.start"

	_ = _range.upperBound
	_ = "_range.endInclusive"

	_ = Range<String.Index>(uncheckedBounds: (lower: _index1, upper: _index2))
	_ = "IntRange(_index1, _index2)"

	_ = _string1.append(_string2)
	_ = "_string1 += _string2"

	_ = _string.append(_character)
	_ = "_string += _character"

	_ = _string.capitalized
	_ = "_string.capitalize()"

	_ = _string.uppercased()
	_ = "_string.toUpperCase()"

	// Character
	_ = _character.uppercased()
	_ = "_character.toUpperCase()"

	// Array
	_ = _array.append(_any)
	_ = "_array.add(_any)"

	_ = _array.insert(_any, at: _int)
	_ = "_array.add(_int, _any)"

	_ = _arrayOfOptionals.append(nil)
	_ = "_arrayOfOptionals.add(null)"

	_ = _array1.append(contentsOf: _array2)
	_ = "_array1.addAll(_array2)"

	_ = _array1.append(contentsOf: _array3)
	_ = "_array1.addAll(_array3)"

	_ = _array.isEmpty
	_ = "_array.isEmpty()"

	_ = _strArray.joined(separator: _string)
	_ = "_strArray.joinToString(separator = _string)"

	_ = _strArray.joined()
	_ = "_strArray.joinToString(separator = \\\"\\\")"

	_ = _array.count
	_ = "_array.size"

	_ = _array.indices
	_ = "_array.indices"

	_ = _array.startIndex
	_ = "0"

	_ = _array.endIndex
	_ = "_array.size"

	_ = _array.index(after: _int)
	_ = "_int + 1"

	_ = _array.index(before: _int)
	_ = "_int - 1"

	_ = _array.first
	_ = "_array.firstOrNull()"

	_ = _array.first(where: _closure3)
	_ = "_array.find _closure3"

	_ = _array.last(where: _closure3)
	_ = "_array.findLast _closure3"

	_ = _array.last
	_ = "_array.lastOrNull()"

	_ = _array.prefix(while: _closure3)
	_ = "_array.takeWhile _closure3"

	_ = _array.removeFirst()
	_ = "_array.removeAt(0)"

	_ = _array.remove(at: _int)
	_ = "_array.removeAt(_int)"

	_ = _array.dropFirst()
	_ = "_array.drop(1)"

	_ = _array.dropLast()
	_ = "_array.dropLast(1)"

	_ = _array.map(_closure2)
	_ = "_array.map _closure2"

	_ = _array.flatMap(_closure6)
	_ = "_array.flatMap _closure6"

	_ = _array.compactMap(_closure2)
	_ = "_array.map _closure2.filterNotNull()"

	_ = _array.filter(_closure3)
	_ = "_array.filter _closure3"

	_ = _array.reduce(_any, _closure)
	_ = "_array.fold(_any) _closure"

	_ = zip(_array1, _array2)
	_ = "_array1.zip(_array2)"

	_ = _array.firstIndex(where: _closure3)
	_ = "_array.indexOfFirst _closure3"

	_ = _array.contains(where: _closure3)
	_ = "(_array.find _closure3 != null)"

	_ = _comparableArray.sorted()
	_ = "_comparableArray.sorted()"

	_ = _comparableArray.contains(_compare)
	_ = "_comparableArray.contains(_compare)"

	_ = _comparableArray.firstIndex(of: _compare)
	_ = "_comparableArray.indexOf(_compare)"

	// Dictionary
	_ = _dictionary.count
	_ = "_dictionary.size"

	_ = _dictionary.isEmpty
	_ = "_dictionary.isEmpty()"

	_ = _dictionary.map(_closure2)
	_ = "_dictionary.map _closure2"

	// Int
	_ = Int.max
	_ = "Int.MAX_VALUE"

	_ = Int.min
	_ = "Int.MIN_VALUE"

	_ = min(_int1, _int2)
	_ = "Math.min(_int1, _int2)"

	_ = _int1..._int2
	_ = "_int1.._int2"

	_ = _int1..<_int2
	_ = "_int1 until _int2"

	// Double
	_ = _double1..._double2
	_ = "(_double1).rangeTo(_double2)"

	// Optional
	_ = _optional.map(_closure4)
	_ = "_optional?.let _closure4"
}

"""

// gryphon multiline
internal let mapKotlinErrorsToSwiftFileContents = """
// WARNING: Any changes to this file should be reflected in the literal string in
// AuxiliaryFileContents.swift

// Examples of compatible errors:
//
//main.kt:2:5: error: conflicting declarations: var result: String, var result: String
//var result: String = ""
//    ^
//main.kt:3:5: error: conflicting declarations: var result: String, var result: String
//var result = result
//    ^

import Foundation

func getAbsoultePath(forFile file: String) -> String {
	return "/" + URL(fileURLWithPath: file).pathComponents.dropFirst().joined(separator: "/")
}

struct ErrorInformation {
	let filePath: String
	let lineNumber: Int
	let columnNumber: Int
	let errorMessage: String
}

func getInformation(fromString string: String) -> ErrorInformation {
	let components = string.split(separator: ":")
	return ErrorInformation(
		filePath: String(components[0]),
		lineNumber: Int(components[1])!,
		columnNumber: Int(components[2])!,
		errorMessage: String(components[3...].joined(separator: ":")))
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

		let components = contents.split(separator: "\\n")
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

////////////////////////////////////////////////////////////////////////////////////////////////////
var input: [String] = []

// Read all the input, separated into lines
while let nextLine = readLine(strippingNewline: false) {
	input.append(nextLine)
}

// Join the lines into errors/warnings
var errors: [String] = []
var currentError = ""
for line in input {
	if line.contains(": error: ") || line.contains(": warning: ") {
		if !currentError.isEmpty {
			errors.append(currentError)
		}
		currentError = line
	}
	else {
		currentError += line
	}
}
if !currentError.isEmpty {
	errors.append(currentError)
}

// Handle the errors
var errorMaps: [String: ErrorMap] = [:]
for error in errors {
	let errorInformation = getInformation(fromString: error)
	let errorMapPath =
		"\(SupportingFile.kotlinErrorMapsFolder)/" + errorInformation.filePath.dropLast(2) +
		"kotlinErrorMap"

	if errorMaps[errorMapPath] == nil {
		if let fileContents = try? String(contentsOfFile: errorMapPath) {
			errorMaps[errorMapPath] = ErrorMap(
				kotlinFilePath: errorInformation.filePath,
				contents: fileContents)
		}
		else {
			print(error)
			continue
		}
	}

	let errorMap = errorMaps[errorMapPath]!

	if let swiftRange = errorMap.getSwiftRange(
		forKotlinLine: errorInformation.lineNumber,
		column: errorInformation.columnNumber)
	{
		print("\\(getAbsoultePath(forFile: errorMap.swiftFilePath)):\\(swiftRange.lineStart):" +
			"\\(swiftRange.columnStart):\\(errorInformation.errorMessage)")
	}
	else {
		print(error)
	}
}

"""

// gryphon multiline
internal let mapGradleErrorsToSwiftFileContents = """
// WARNING: Any changes to this file should be reflected in the literal string in
// AuxiliaryFileContents.swift

// This script should be run on a folder initialized by Gryphon (i.e. containing the relevant
// `\(SupportingFile.gryphonBuildFolder)` folder)

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

func getInformation(fromString string: String) -> ErrorInformation {
	let components = string.split(separator: ":")
	let filePath = String(components[1].dropFirst()) // Drop the first space
	let lineAndColumn = components[2].dropFirst(2).dropLast().split(separator: ",")
	let line = Int(lineAndColumn[0])!
	let column = Int(lineAndColumn[1].dropFirst())!
	return ErrorInformation(
		filePath: getRelativePath(forFile: filePath),
		lineNumber: line,
		columnNumber: column,
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

		let components = contents.split(separator: "\\n")
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

////////////////////////////////////////////////////////////////////////////////////////////////////
var input: [String] = []

// Read all the input, separated into lines
while let nextLine = readLine(strippingNewline: false) {
	input.append(nextLine)
}

// Get only lines with errors and warnings
var errors = input.filter { \(dollarSign)0.hasPrefix("e: ") || \(dollarSign)0.hasPrefix("w: ") }

// Handle the errors
var errorMaps: [String: ErrorMap] = [:]
for error in errors {
	let errorInformation = getInformation(fromString: error)
	let errorMapPath =
		"\(SupportingFile.kotlinErrorMapsFolder)/" + errorInformation.filePath.dropLast(2) +
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
			print("\\(getAbsoultePath(forFile: errorInformation.filePath)):" +
				"\\(errorInformation.lineNumber):" +
				"\\(errorInformation.columnNumber): " +
				"\\(errorString):\\(errorInformation.errorMessage)")
			continue
		}
	}

	let errorMap = errorMaps[errorMapPath]!

	if let swiftRange = errorMap.getSwiftRange(
		forKotlinLine: errorInformation.lineNumber,
		column: errorInformation.columnNumber)
	{
		let errorString = errorInformation.isError ? "error" : "warning"
		print("\\(getAbsoultePath(forFile: errorMap.swiftFilePath)):\\(swiftRange.lineStart):" +
			"\\(swiftRange.columnStart): \\(errorString):\\(errorInformation.errorMessage)")
	}
	else {
		// Print error with the available information
		let errorString = errorInformation.isError ? "error" : "warning"
		print("\\(getAbsoultePath(forFile: errorMap.swiftFilePath)):" +
			"0:0: \\(errorString):\\(errorInformation.errorMessage)")
	}
}

if !errors.isEmpty {
	exit(-1)
}

"""

// gryphon multiline
internal let makeGryphonTargetsFileContents = """
require 'xcodeproj'

if ARGV.length < 1
    STDERR.puts "Error: please specify the path to the Xcode project as an argument."
    exit(false)
end

project_path = ARGV[0]
project = Xcodeproj::Project.open(project_path)

gryphonTargetName = "Gryphon"
gryphonBuildPhaseName = "Call Gryphon"
kotlinTargetName = "Kotlin"
kotlinBuildPhaseName = "Compile Kotlin"

####################################################################################################
# Make the Gryphon target

# Create the new target (or fetch it if it exists)
gryphonTarget = project.targets.detect { |target| target.name == gryphonTargetName }
if gryphonTarget == nil
	puts "	Creating new Gryphon target..."
	gryphonTarget = project.new_aggregate_target(gryphonTargetName)
else
	puts "	Updating Gryphon target..."
end

# Set the product name of the target (otherwise Xcode may complain)
# Set the build settings so that only the "My Mac" platform is available
gryphonTarget.build_configurations.each do |config|
	config.build_settings["PRODUCT_NAME"] = "Gryphon"
	config.build_settings["SUPPORTED_PLATFORMS"] = "macosx"
	config.build_settings["SUPPORTS_MACCATALYST"] = "FALSE"
end

# Create a new run script build phase (or fetch it if it exists)
gryphonBuildPhase = gryphonTarget.shell_script_build_phases.detect { |buildPhase|
	buildPhase.name == gryphonBuildPhaseName
}
if gryphonBuildPhase == nil
	puts "	Creating new Run Script build phase..."
	gryphonBuildPhase = gryphonTarget.new_shell_script_build_phase(gryphonBuildPhaseName)
else
	puts "	Updating Run Script build phase..."
end

# Set the script we want to run
if ARGV.length > 1
	# If we specified a toolchain
    gryphonBuildPhase.shell_script =
		"gryphon \(dollarSign){PROJECT_NAME}.xcodeproj \(dollarSign)SCRIPT_INPUT_FILE_LIST_0" +
		" --toolchain=\\"" + ARGV[1] + "\\""
else
	# If we're using the default toolchain
    gryphonBuildPhase.shell_script =
		"gryphon \(dollarSign){PROJECT_NAME}.xcodeproj \(dollarSign)SCRIPT_INPUT_FILE_LIST_0"
end

# Set the path to the input file list
gryphonBuildPhase.input_file_list_paths = [
	"\(dollarSign){SRCROOT}/\(SupportingFile.xcFileList.relativePath)"]


####################################################################################################
# Make the Kotlin target

# Create the new target (or fetch it if it exists)
kotlinTarget = project.targets.detect { |target| target.name == kotlinTargetName }
if kotlinTarget == nil
	puts "	Creating new Kotlin target..."
	kotlinTarget = project.new_aggregate_target(kotlinTargetName)
else
	puts "	Updating Kotlin target..."
end

# Set the product name of the target (otherwise Xcode may complain)
# Set the build settings so that only the "My Mac" platform is available
# Create a new build setting for setting the Android project's folder
kotlinTarget.build_configurations.each do |config|
	config.build_settings["PRODUCT_NAME"] = "Koltin"
	config.build_settings["SUPPORTED_PLATFORMS"] = "macosx"
	config.build_settings["SUPPORTS_MACCATALYST"] = "FALSE"
	config.build_settings["ANDROID_ROOT"] = "../Android"
end

# Create a new run script build phase (or fetch it if it exists)
kotlinBuildPhase = kotlinTarget.shell_script_build_phases.detect { |buildPhase|
	buildPhase.name == kotlinBuildPhaseName
}
if kotlinBuildPhase == nil
	puts "	Creating new Run Script build phase..."
	kotlinBuildPhase = kotlinTarget.new_shell_script_build_phase(kotlinBuildPhaseName)
else
	puts "	Updating Run Script build phase..."
end

# Set the script we want to run
kotlinBuildPhase.shell_script =
	"bash \(SupportingFile.compileKotlinRelativePath)"

####################################################################################################
# Save the changes to disk
project.save()

"""

// gryphon multiline
internal let compileKotlinFileContents = """
# Remove old logs
# The `-f` option is here to avoid reporting errors when the files are not found
rm -f "\(dollarSign)SRCROOT/\(SupportingFile.gryphonBuildFolder)/gradleOutput.txt"
rm -f "\(dollarSign)SRCROOT/\(SupportingFile.gryphonBuildFolder)/gradleErrors.txt"

# Switch to the Android folder so we can use pre-built gradle info to speed up the compilation.
cd "\(dollarSign)ANDROID_ROOT"

# Compile the Android sources and save the logs gack to the iOS folder
./gradlew compileDebugSources > \
	"\(dollarSign)SRCROOT/\(SupportingFile.gryphonBuildFolder)/gradleOutput.txt" 2> \
	"\(dollarSign)SRCROOT/\(SupportingFile.gryphonBuildFolder)/gradleErrors.txt"

# Switch back to the iOS folder
cd \(dollarSign)SRCROOT

# Map the Kotlin errors back to Swift
EXITSTATUS=0

swift \(SupportingFile.mapGradleErrorsToSwiftRelativePath) < \
	\(SupportingFile.gryphonBuildFolder)/gradleOutput.txt
if test "\(dollarSign)?" -ne "0" ; then
	EXITSTATUS=-1
fi

swift \(SupportingFile.mapGradleErrorsToSwiftRelativePath) < \
	\(SupportingFile.gryphonBuildFolder)/gradleErrors.txt
if test "\(dollarSign)?" -ne "0" ; then
	EXITSTATUS=-1
fi

exit \(dollarSign)EXITSTATUS

"""

/// Stores all hard-coded file names and paths. Changes to these paths might need to be reflected in
/// prepareForBootstrapTests.sh
public class SupportingFile {
	let name: String
	/// The folder where this file should be. A value of `nil` corresponds to the current directory.
	let folder: String?
	let contents: String?

	private init(_ name: String, folder: String?, contents: String?) {
		self.name = name
		self.folder = folder
		self.contents = contents
	}

	var relativePath: String {
		if let folder = self.folder {
			return "\(folder)/\(name)"
		}
		else {
			return name
		}
	}

	var absolutePath: String {
		return Utilities.getAbsoultePath(forFile: relativePath)
	}

	//
	static public func pathOfSwiftASTDumpFile(
		forSwiftFile swiftFile: String,
		swiftVersion: String)
		-> String
	{
		let relativePath = Utilities.getRelativePath(forFile: swiftFile)
		let pathInGryphonFolder = "\(astDumpsFolder)-Swift-\(swiftVersion)/\(relativePath)"
		let astDumpPath = Utilities.changeExtension(of: pathInGryphonFolder, to: .swiftASTDump)
		return astDumpPath
	}

	static public func pathOfKotlinErrorMapFile(forKotlinFile kotlinFile: String) -> String {
		let relativePath = Utilities.getRelativePath(forFile: kotlinFile)
		let pathInGryphonFolder = "\(kotlinErrorMapsFolder)/\(relativePath)"
		let errorMapPath = Utilities.changeExtension(of: pathInGryphonFolder, to: .kotlinErrorMap)
		return errorMapPath
	}

	// Folders
	public static let gryphonBuildFolder = ".gryphon"
	public static let gryphonScriptsFolder = "\(gryphonBuildFolder)/scripts"
	public static let kotlinErrorMapsFolder = "\(gryphonBuildFolder)/KotlinErrorMaps"
	public static let astDumpsFolder = "\(gryphonBuildFolder)/ASTDumps"

	// Files in the project folder
	public static let xcFileList = SupportingFile(
		"gryphonInputFiles.xcfilelist",
		folder: nil,
		contents: "")

	// Files in the Gryphon build folder ("/path/to/project/.gryphon")
	public static let gryphonTemplatesLibrary = SupportingFile(
		"GryphonTemplatesLibrary.swift",
		folder: SupportingFile.gryphonBuildFolder,
		contents: gryphonTemplatesLibraryFileContents)
	public static let temporaryOutputFileMap = SupportingFile(
		"output-file-map.json",
		folder: SupportingFile.gryphonBuildFolder,
		contents: nil)
	public static let astDumpsScript = SupportingFile(
		"updateASTDumps.sh",
		folder: SupportingFile.gryphonBuildFolder,
		contents: nil)
	public static let gryphonXCTest = SupportingFile(
		"GryphonXCTest.swift",
		folder: SupportingFile.gryphonBuildFolder,
		contents: gryphonXCTestFileContents)

	// Files in the Gryphon scripts folder ("/path/to/project/.gryphon/scripts")
	public static let mapKotlinErrorsToSwift = SupportingFile(
		"mapKotlinErrorsToSwift.swift",
		folder: SupportingFile.gryphonScriptsFolder,
		contents: mapKotlinErrorsToSwiftFileContents)

	internal static let mapGradleErrorsToSwiftRelativePath =
		".gryphon/scripts/mapGradleErrorsToSwift.swift"
	public static let mapGradleErrorsToSwift = SupportingFile(
		"mapGradleErrorsToSwift.swift",
		folder: SupportingFile.gryphonScriptsFolder,
		contents: mapGradleErrorsToSwiftFileContents)

	public static let makeGryphonTargets = SupportingFile(
		"makeGryphonTargets.rb",
		folder: SupportingFile.gryphonScriptsFolder,
		contents: makeGryphonTargetsFileContents)

	internal static let compileKotlinRelativePath =
		".gryphon/scripts/compileKotlin.sh"
	public static let compileKotlin = SupportingFile(
		"compileKotlin.sh",
		folder: SupportingFile.gryphonScriptsFolder,
		contents: compileKotlinFileContents)

	/// Files that should be created on every init
	static let filesForInitialization: List = [
		gryphonTemplatesLibrary,
		gryphonXCTest,
	]

	static let filesForXcodeInitialization: List = [
		gryphonTemplatesLibrary,
		gryphonXCTest,
		mapKotlinErrorsToSwift,
		mapGradleErrorsToSwift,
		makeGryphonTargets,
		compileKotlin,
	]
}
