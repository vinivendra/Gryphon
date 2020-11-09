//
// Copyright 2018 Vinicius Jorge Vendramini
//
// Licensed under the Hippocratic License, Version 2.1;
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://firstdonoharm.dev/version/2/1/license.md
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

private func gryphonTemplates() throws {
    let _string1 = ""
    let _string2 = ""
    let _string3 = ""
    let _stringArray: List<String>? = []
    let _stringArray1: MutableList<String> = []
    let _stringArray2: MutableList<String> = []
    let _fileExtension1 = FileExtension.swift

    _ = Utilities.file(_string1, wasModifiedLaterThan: _string2)
	_ = GRYTemplate.call(.dot("Utilities", "fileWasModifiedLaterThan"), ["_string1", "_string2"])

    _ = Utilities.files(_stringArray1, wereModifiedLaterThan: _stringArray2)
	_ = GRYTemplate.call(
		.dot("Utilities", "filesWereModifiedLaterThan"), ["_stringArray1", "_stringArray2"])

    _ = try Utilities.createFile(named: _string1, inDirectory: _string2, containing: _string3)
	_ = GRYTemplate.call(
		.dot("Utilities", "createFileAndDirectory"),
		[.labeledParameter("fileName", "_string1"),
		 .labeledParameter("directory", "_string2"),
		 .labeledParameter("contents", "_string3")])

    _ = Utilities.getFiles(_stringArray, inDirectory: _string1, withExtension: _fileExtension1)
	_ = GRYTemplate.call(
		.dot("Utilities", "getFiles"),
		[.labeledParameter("selectedFiles", "_stringArray"),
		 .labeledParameter("directory", "_string1"),
		 .labeledParameter("fileExtension", "_fileExtension1")])

    _ = Utilities.getFiles(inDirectory: _string1, withExtension: _fileExtension1)
	_ = GRYTemplate.call(
		.dot("Utilities", "getFiles"),
		[.labeledParameter("directory", "_string1"),
		 .labeledParameter("fileExtension", "_fileExtension1")])

    _ = Utilities.getAbsoultePath(forFile: _string1)
	_ = GRYTemplate.call(
		.dot("Utilities", "getAbsoultePath"),
		[.labeledParameter("file", "_string1")])

	_ = Utilities.fileExists(at: _string1)
	_ = GRYTemplate.call(
		.dot("Utilities", "fileExists"),
		[.labeledParameter("filePath", "_string1")])

    _ = Utilities.createFileIfNeeded(at: _string1)
	_ = GRYTemplate.call(
		.dot("Utilities", "createFileIfNeeded"),
		[.labeledParameter("filePath", "_string1")])

	Utilities.createFolderIfNeeded(at: _string1)
	_ = GRYTemplate.call(
		.dot("Utilities", "createFolderIfNeeded"),
		[.labeledParameter("path", "_string1")])

    try Utilities.createFile(atPath: _string1, containing: _string2)
	_ = GRYTemplate.call(
		.dot("Utilities", "createFile"),
		[.labeledParameter("filePath", "_string1"),
		 .labeledParameter("contents", "_string2")])

	Utilities.deleteFolder(at: _string1)
	_ = GRYTemplate.call(
		.dot("Utilities", "deleteFolder"),
		[.labeledParameter("path", "_string1")])

	Utilities.deleteFile(at: _string1)
	_ = GRYTemplate.call(
		.dot("Utilities", "deleteFolder"),
		[.labeledParameter("path", "_string1")])

    // Shell translations
    _ = Shell.runShellCommand(
        _string1, arguments: _stringArray1, fromFolder: _string2)
	_ = GRYTemplate.call(
		.dot("Shell", "runShellCommand"),
		["_string1",
		 .labeledParameter("arguments", "_stringArray1"),
		 .labeledParameter("currentFolder", "_string2")])

    _ = Shell.runShellCommand(
        _string1, arguments: _stringArray1)
	_ = GRYTemplate.call(
		.dot("Shell", "runShellCommand"),
		["_string1",
		 .labeledParameter("arguments", "_stringArray1")])

    //
    _ = Shell.runShellCommand(_stringArray1, fromFolder: _string1)
	_ = GRYTemplate.call(
		.dot("Shell", "runShellCommand"),
		["_stringArray1",
		 .labeledParameter("currentFolder", "_string1")])

    _ = Shell.runShellCommand(_stringArray1)
	_ = GRYTemplate.call(.dot("Shell", "runShellCommand"), ["_stringArray1"])

	//
	_ = OS.OSType.macOS
	_ = GRYTemplate.dot(.dot("OS", "OSType"), "MAC_OS")

	_ = OS.OSType.linux
	_ = GRYTemplate.dot(.dot("OS", "OSType"), "LINUX")
}

public struct GryphonError: Error, CustomStringConvertible {
	let errorMessage: String

	public var description: String {
		return errorMessage
	}

	init(errorMessage: String) {
		self.errorMessage = errorMessage
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
}

public enum FileExtension: String {
    case swiftASTDump
    case swiftAST
    case gryphonASTRaw
    case gryphonAST
    case output
	case kotlinErrorMap
    case kt
    case swift

	case xcfilelist
	case xcodeproj
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
}

////////////////////////////////////////////////////////////////////////////////////////////////////

extension Utilities {
	static public func processGryphonTemplatesLibrary(
		for transpilationContext: TranspilationContext)
		throws
	{
        libraryUpdateLock.lock()

        defer {
            libraryUpdateLock.unlock()
        }

		Compiler.logStart("🧑‍💻  Processing the templates library...")

		if !transpilationContext.isUsingSwiftSyntax {
			if Utilities.needsToDumpASTForSwiftFiles(
				[SupportingFile.gryphonTemplatesLibrary.name],
				in: SupportingFile.gryphonTemplatesLibrary.folder ?? ".",
				forSwiftVersion: transpilationContext.swiftVersion)
			{
				Compiler.logStart("🧑‍💻  Updating the templates library's AST dump...")
				try Driver.updateASTDumps(
					forFiles: [SupportingFile.gryphonTemplatesLibrary.relativePath],
					forXcodeProject: nil,
					forTarget: nil,
					usingToolchain: transpilationContext.toolchainName,
					shouldTryToRecoverFromErrors: true)
				Compiler.logEnd("✅  Done updating the templates library's AST dump.")

				if Utilities.needsToDumpASTForSwiftFiles(
					[SupportingFile.gryphonTemplatesLibrary.name],
					in: SupportingFile.gryphonTemplatesLibrary.folder ?? ".",
					forSwiftVersion: transpilationContext.swiftVersion)
				{
					throw GryphonError(errorMessage:
						"Failed to update AST dump for the Gryphon Templates library.")
				}
			}
		}

		Compiler.logStart("🧑‍💻  Transpiling and running passes...")
		let astArray = try Compiler.transpileGryphonRawASTs(
			fromInputFiles: [SupportingFile.gryphonTemplatesLibrary.relativePath],
			fromASTDumpFiles: [
				SupportingFile.pathOfSwiftASTDumpFile(
					forSwiftFile: SupportingFile.gryphonTemplatesLibrary.relativePath,
					swiftVersion: transpilationContext.swiftVersion), ],
			withContext: transpilationContext)

		let ast = astArray[0]
		_ = RecordTemplatesTranspilationPass(
			ast: ast,
			context: transpilationContext).run()
		Compiler.logEnd("✅  Done transpiling and running passes.")

		Compiler.logEnd("✅  Done processing the templates library.")
    }

	static internal func needsToDumpASTForSwiftFiles(
		_ swiftFiles: List<String>? = nil,
		in folder: String,
		forSwiftVersion swiftVersion: String)
		-> Bool
    {
		let files = getFiles(swiftFiles, inDirectory: folder, withExtension: .swift)

        for swiftFile in files {
			let astDumpFilePath = SupportingFile.pathOfSwiftASTDumpFile(
				forSwiftFile: swiftFile,
				swiftVersion: swiftVersion)

            let astDumpFileExists = Utilities.fileExists(at: astDumpFilePath)
            let astDumpFileIsOutdated = !astDumpFileExists ||
                Utilities.file(swiftFile, wasModifiedLaterThan: astDumpFilePath)

            if astDumpFileIsOutdated {
                return true
            }
        }

        return false
    }

	public static func getRelativePath(forFile file: String) -> String {
		let currentDirectoryPath = Utilities.getCurrentFolder()
		let absoluteFilePath = getAbsoultePath(forFile: file)
		return String(absoluteFilePath.dropFirst(currentDirectoryPath.count + 1))
	}
}

extension Utilities {
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

extension String {
	func isArrayDeclaration() -> Bool {
		if self.hasPrefix("[") {
			return self.contains(":") == false
		} else {
			return self.hasPrefix("Array")
		}
	}
	
	func isDictionaryDeclaration() -> Bool {
		if self.hasPrefix("[") {
			return self.contains(":")
		} else {
			return self.hasPrefix("Dictionary")
		}
	}
}

