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

public final class GRYSwiftAST: GRYPrintableAsTree, GRYCodable, Equatable, CustomStringConvertible {
	let name: String
	let standaloneAttributes: ArrayReference<String>
	let keyValueAttributes: [String: String]
	let subtrees: ArrayReference<GRYSwiftAST>

	//
	static public var horizontalLimitWhenPrinting = Int.max

	//
	internal init(_ name: String, _ subtrees: ArrayReference<GRYSwiftAST> = []) {
		self.name = name
		self.standaloneAttributes = []
		self.keyValueAttributes = [:]
		self.subtrees = subtrees
	}

	internal init(
		_ name: String,
		_ standaloneAttributes: ArrayReference<String>,
		_ keyValueAttributes: [String: String],
		_ subtrees: ArrayReference<GRYSwiftAST> = [])
	{
		self.name = name
		self.standaloneAttributes = standaloneAttributes
		self.keyValueAttributes = keyValueAttributes
		self.subtrees = subtrees
	}

	// MARK: - GRYCodable
	func encode(into encoder: GRYEncoder) throws {
		encoder.startNewObject(named: name)
		for attribute in standaloneAttributes {
			try attribute.encode(into: encoder)
		}
		for (key, value) in keyValueAttributes {
			encoder.addKey(key)
			try value.encode(into: encoder)
		}
		for subtree in subtrees {
			try subtree.encode(into: encoder)
		}
		encoder.endObject()
	}

	static func decode(from decoder: GRYDecoder) throws -> GRYSwiftAST {
		let standaloneAttributes: ArrayReference<String> = []
		var keyValueAttributes = [String: String]()
		let subtrees: ArrayReference<GRYSwiftAST> = []

		try decoder.readOpeningParenthesis()
		let name = decoder.readDoubleQuotedString()

		// The loop stops: all branches tell the decoder to read, therefore the input string must
		// end eventually
		while true {
			// Add subtree
			if decoder.canReadOpeningParenthesis() {
				// Parse subtrees
				let subtree = try GRYSwiftAST.decode(from: decoder)
				subtrees.append(subtree)
			}
			// Finish this branch
			else if decoder.canReadClosingParenthesis() {
				try decoder.readClosingParenthesis()
				break
			}
			// Add key-value attributes
			else if let key = decoder.readKey() {
				keyValueAttributes[key] = decoder.readDoubleQuotedString()
			}
			// Add standalone attributes
			else {
				let attribute = decoder.readDoubleQuotedString()
				standaloneAttributes.append(attribute)
			}
		}

		return GRYSwiftAST(name, standaloneAttributes, keyValueAttributes, subtrees)
	}

	// MARK: - Init from Swift AST dump
	public convenience init(decodeFromSwiftASTDumpInFile astFilePath: String) throws {
		let rawASTDump = try String(contentsOfFile: astFilePath)

		// Information in stored files has placeholders for file paths that must be replaced
		let swiftFilePath = GRYUtils.changeExtension(of: astFilePath, to: .swift)
		let processedASTDump =
			rawASTDump.replacingOccurrences(of: "<<testFilePath>>", with: swiftFilePath)

		let decoder = GRYDecoder(encodedString: processedASTDump)
		try self.init(decodingFromASTDumpWith: decoder)
	}

	internal init(decodingFromASTDumpWith decoder: GRYDecoder) throws {
		let standaloneAttributes: ArrayReference<String> = []
		var keyValueAttributes = [String: String]()
		let subtrees: ArrayReference<GRYSwiftAST> = []

		try decoder.readOpeningParenthesis()
		let name = decoder.readName()
		self.name = GRYUtils.expandSwiftAbbreviation(name)

		// The loop stops: all branches tell the decoder to read, therefore the input string must
		// end eventually
		while true {
			// Add subtree
			if decoder.canReadOpeningParenthesis() {
				// Parse subtrees
				let subtree = try GRYSwiftAST(decodingFromASTDumpWith: decoder)
				subtrees.append(subtree)

				// FIXME: This is a hack to fix Swift 4's unbalanced parentheses when dumping the
				// AST for a literal dictionary expression
				if self.name == "Dictionary Expression" {
					break
				}
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

	func subtree(named name: String) -> GRYSwiftAST? {
		return subtrees.first { $0.name == name }
	}

	func subtree(at index: Int) -> GRYSwiftAST? {
		guard index >= 0, index < subtrees.count else {
			return nil
		}
		return subtrees[index]
	}

	func subtree(at index: Int, named name: String) -> GRYSwiftAST? {
		guard index >= 0, index < subtrees.count else {
			return nil
		}

		let subtree = subtrees[index]
		guard subtree.name == name else {
			return nil
		}

		return subtree
	}

	// MARK: - GRYPrintableAsTree
	public var treeDescription: String {
		return name
	}

	public var printableSubtrees: ArrayReference<GRYPrintableAsTree?> {
		let keyValueStrings = keyValueAttributes.map { "\($0.key) → \($0.value)" }.sorted()
		let keyValueArray = ArrayReference<GRYPrintableAsTree?>(array: keyValueStrings)
		let standaloneAttributesArray = ArrayReference<GRYPrintableAsTree?>(standaloneAttributes)
		let subtreesArray = ArrayReference<GRYPrintableAsTree?>(subtrees)

		let result: ArrayReference<GRYPrintableAsTree?> =
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
	public static func == (lhs: GRYSwiftAST, rhs: GRYSwiftAST) -> Bool {
		return lhs.name == rhs.name &&
			lhs.standaloneAttributes == rhs.standaloneAttributes &&
			lhs.keyValueAttributes == rhs.keyValueAttributes &&
			lhs.subtrees == rhs.subtrees
	}
}
