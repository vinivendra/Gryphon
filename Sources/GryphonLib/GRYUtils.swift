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
	case swiftASTDump
	case grySwiftASTJson

	case expectedGrySwiftASTJson
	case output

	case kt
	case swift

	//
	static func +(string: String, fileExtension: GRYFileExtension) -> String {
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

////////////////////////////////////////////////////////////////////////////////////////////////////
public class GRYHistogram<T>: CustomStringConvertible
	where T: Hashable
{
	private var buffer = [T: Int]()

	public func increaseOccurence(of element: T) {
		if let count = buffer[element] {
			buffer[element] = count + 1
		}
		else {
			buffer[element] = 1
		}
	}

	public var description: String {
		if buffer.isEmpty {
			return ""
		}

		var longestNameLength = "Subtree Name".count
		var longestNumberLength = "#".count
		for (key, value) in buffer {
			longestNameLength = max("\(key)".count, longestNameLength)
			longestNumberLength = max("\(value)".count, longestNumberLength)
		}

		let keyHeaderSpaces = longestNameLength - "Subtree Name".count
		let valueHeaderSpaces = longestNumberLength - "#".count
		var result = "| Subtree Name" + keyHeaderSpaces.times(" ") + " | #" + valueHeaderSpaces.times(" ") + " |\n"
		result += "|" + (longestNameLength + 2).times("-") + "|" + (longestNumberLength + 2).times("-") + "|\n"

		for (key, value) in buffer {
			let nameSpaces = longestNameLength - "\(key)".count
			result += "| \(key)"
			for _ in 0..<nameSpaces {
				result += " "
			}

			let numberSpaces = longestNumberLength - "\(value)".count
			result += " | \(value)"
			for _ in 0..<numberSpaces {
				result += " "
			}

			result += " |\n"
		}
		return result
	}
}

fileprivate extension Int {
	func times(_ string: String) -> String {
		var result = ""
		for _ in 0..<self {
			result += string
		}
		return result
	}
}
