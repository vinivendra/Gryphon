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

public final class SwiftAST: PrintableAsTree, Equatable, CustomStringConvertible {
	let name: String
	let standaloneAttributes: ArrayReference<String>
	let keyValueAttributes: [String: String]
	let subtrees: ArrayReference<SwiftAST>

	//
	static public var horizontalLimitWhenPrinting = Int.max

	//
	internal init(_ name: String, _ subtrees: ArrayReference<SwiftAST> = []) {
		self.name = name
		self.standaloneAttributes = []
		self.keyValueAttributes = [:]
		self.subtrees = subtrees
	}

	internal init(
		_ name: String,
		_ standaloneAttributes: ArrayReference<String>,
		_ keyValueAttributes: [String: String],
		_ subtrees: ArrayReference<SwiftAST> = [])
	{
		self.name = name
		self.standaloneAttributes = standaloneAttributes
		self.keyValueAttributes = keyValueAttributes
		self.subtrees = subtrees
	}

	// MARK: - Init from Swift AST dump
	public convenience init(decodeFromSwiftASTDumpInFile astFilePath: String) throws {
		let rawASTDump = try String(contentsOfFile: astFilePath)

		// Information in stored files has placeholders for file paths that must be replaced
		let swiftFilePath = Utilities.changeExtension(of: astFilePath, to: .swift)
		let processedASTDump =
			rawASTDump.replacingOccurrences(of: "<<testFilePath>>", with: swiftFilePath)

		let decoder = ASTDumpDecoder(encodedString: processedASTDump)
		try self.init(decodingFromASTDumpWith: decoder)
	}

	// TODO: This logic should probably be in the decoder as a factory method of some sort.
	internal init(decodingFromASTDumpWith decoder: ASTDumpDecoder) throws {
		let standaloneAttributes: ArrayReference<String> = []
		var keyValueAttributes = [String: String]()
		let subtrees: ArrayReference<SwiftAST> = []

		try decoder.readOpeningParenthesis()
		let name = decoder.readIdentifier()
		self.name = Utilities.expandSwiftAbbreviation(name)

		// The loop stops: all branches tell the decoder to read, therefore the input string must
		// end eventually
		while true {
			// Add subtree
			if decoder.canReadOpeningParenthesis() {
				// Parse subtrees
				let subtree = try SwiftAST(decodingFromASTDumpWith: decoder)
				subtrees.append(subtree)
			}
			// Finish this branch
			else if decoder.canReadClosingParenthesis() {
				try decoder.readClosingParenthesis()
				break
			}
			// Add key-value attributes
			else if let key = decoder.readKey() {
				if key == "location" && decoder.canReadLocation() {
					keyValueAttributes[key] = decoder.readLocation()
				}
				else if key == "decl",
					let string = decoder.readDeclarationLocation() ?? decoder.readDeclaration()
				{
					keyValueAttributes[key] = string
				}
				else if key == "bind"
				{
					let string = decoder.readDeclarationLocation() ?? decoder.readIdentifier()
					keyValueAttributes[key] = string
				}
				else if key == "inherits" {
					let string = decoder.readIdentifierList()
					keyValueAttributes[key] = string
				}
				else {
					keyValueAttributes[key] = decoder.readStandaloneAttribute()
				}
			}
			// Add standalone attributes
			else {
				let attribute = decoder.readStandaloneAttribute()
				standaloneAttributes.append(attribute)
			}
		}

		self.subtrees = subtrees
		self.standaloneAttributes = standaloneAttributes
		self.keyValueAttributes = keyValueAttributes
	}

	// MARK: - Convenience accessors
	subscript (key: String) -> String? {
		return keyValueAttributes[key]
	}

	func subtree(named name: String) -> SwiftAST? {
		return subtrees.first { $0.name == name }
	}

	func subtree(at index: Int) -> SwiftAST? {
		guard index >= 0, index < subtrees.count else {
			return nil
		}
		return subtrees[index]
	}

	func subtree(at index: Int, named name: String) -> SwiftAST? {
		guard index >= 0, index < subtrees.count else {
			return nil
		}

		let subtree = subtrees[index]
		guard subtree.name == name else {
			return nil
		}

		return subtree
	}

	// MARK: - PrintableAsTree
	public var treeDescription: String {
		return name
	}

	public var printableSubtrees: ArrayReference<PrintableAsTree?> {
		let keyValueStrings = keyValueAttributes
			.map { "\($0.key) → \($0.value)" }.sorted().map(PrintableTree.init)
		let keyValueArray = ArrayReference<PrintableAsTree?>(array: keyValueStrings)
		let standaloneAttributesArray =
			ArrayReference<PrintableAsTree?>(standaloneAttributes.map(PrintableTree.init))
		let subtreesArray = ArrayReference<PrintableAsTree?>(subtrees)

		let result: ArrayReference<PrintableAsTree?> =
			standaloneAttributesArray + keyValueArray + subtreesArray
		return result
	}

	// MARK: - Descriptions
	public var description: String {
		var result = ""
		self.prettyPrint { result += $0 }
		return result
	}

	public func description(withHorizontalLimit horizontalLimit: Int) -> String {
		var result = ""
		self.prettyPrint(horizontalLimit: horizontalLimit) { result += $0 }
		return result
	}

	// MARK: - Equatable
	public static func == (lhs: SwiftAST, rhs: SwiftAST) -> Bool {
		return lhs.name == rhs.name &&
			lhs.standaloneAttributes == rhs.standaloneAttributes &&
			lhs.keyValueAttributes == rhs.keyValueAttributes &&
			lhs.subtrees == rhs.subtrees
	}
}
