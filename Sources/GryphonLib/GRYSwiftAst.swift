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

public class GRYSwiftAst: GRYPrintableAsTree, Equatable, CustomStringConvertible {
	let name: String
	let standaloneAttributes: [String]
	let keyValueAttributes: [String: String]
	let subtrees: [GRYSwiftAst]

	//
	static public var horizontalLimitWhenPrinting = Int.max

	//
	public convenience init(astFile astFilePath: String) throws {
		do {
			let rawAstDump = try String(contentsOfFile: astFilePath)

			// Information in stored files has placeholders for file paths that must be replaced
			let swiftFilePath = GRYUtils.changeExtension(of: astFilePath, to: .swift)
			let processedAstDump =
				rawAstDump.replacingOccurrences(of: "<<testFilePath>>", with: swiftFilePath)

			let parser = GRYDecoder(encodedString: processedAstDump)
			try self.init(decodingFromAstDumpWith: parser)
		}
		catch {
			fatalError("Error opening \(astFilePath)." +
				" If the file doesn't exist, please use dump-ast.pl to generate it.")
		}
	}

	internal init(decodingFromAstDumpWith decoder: GRYDecoder) throws {
		var standaloneAttributes = [String]()
		var keyValueAttributes = [String: String]()
		var subtrees = [GRYSwiftAst]()

		try decoder.readOpenParentheses()
		let name = decoder.readIdentifier()
		self.name = GRYUtils.expandSwiftAbbreviation(name)

		// The loop stops: all branches tell the parser to read, therefore the input string must end
		// eventually
		while true {
			// Add subtree
			if decoder.canReadOpenParentheses() {
				// Parse subtrees
				let subtree = try GRYSwiftAst(decodingFromAstDumpWith: decoder)
				subtrees.append(subtree)

				// FIXME: This is a hack to fix Swift 4's unbalanced parentheses when dumping the
				// AST for a literal dictionary expression
				if self.name == "Dictionary Expression" {
					break
				}
			}
			// Finish this branch
			else if decoder.canReadCloseParentheses() {
				try decoder.readCloseParentheses()
				break
			}
				// Add key-value attributes
			else if let key = decoder.readKey() {
				if key == "location" && decoder.canReadLocation() {
					keyValueAttributes[key] = decoder.readLocation()
				}
				else if key == "decl",
					let string = decoder.readDeclarationLocation()
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

	static public func initialize(decodingFile filePath: String) throws -> GRYSwiftAst {
		do {
			let rawSExpressionDump = try String(contentsOfFile: filePath)

			// Information in stored files has placeholders for file paths that must be replaced
			let swiftFilePath = GRYUtils.changeExtension(of: filePath, to: .swift)
			let processedSExpressionDump =
				rawSExpressionDump.replacingOccurrences(of: "<<testFilePath>>", with: swiftFilePath)

			let decoder = GRYDecoder(encodedString: processedSExpressionDump)
			return try GRYSwiftAst.decode(from: decoder)
		}
		catch {
			fatalError("Error opening \(filePath)." +
				" If the file doesn't exist, please use dump-ast.pl to generate it.")
		}
	}

	static func decode(from decoder: GRYDecoder) throws -> GRYSwiftAst {
		var standaloneAttributes = [String]()
		var keyValueAttributes = [String: String]()
		var subtrees = [GRYSwiftAst]()

		try decoder.readOpenParentheses()
		let name = decoder.readDoubleQuotedString()

		// The loop stops: all branches tell the parser to read, therefore the input string must end
		// eventually
		while true {
			// Add subtree
			if decoder.canReadOpenParentheses() {
				// Parse subtrees
				let subtree = try GRYSwiftAst.decode(from: decoder)
				subtrees.append(subtree)
			}
			// Finish this branch
			else if decoder.canReadCloseParentheses() {
				try decoder.readCloseParentheses()
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

		return GRYSwiftAst(name, standaloneAttributes, keyValueAttributes, subtrees)
	}

	internal init(_ name: String, _ subtrees: [GRYSwiftAst] = []) {
		self.name = name
		self.standaloneAttributes = []
		self.keyValueAttributes = [:]
		self.subtrees = subtrees
	}

	internal init(
		_ name: String,
		_ standaloneAttributes: [String],
		_ keyValueAttributes: [String: String],
		_ subtrees: [GRYSwiftAst] = [])
	{
		self.name = name
		self.standaloneAttributes = standaloneAttributes
		self.keyValueAttributes = keyValueAttributes
		self.subtrees = subtrees
	}

	//
	subscript (key: String) -> String? {
		return keyValueAttributes[key]
	}

	func subtree(named name: String) -> GRYSwiftAst? {
		return subtrees.first { $0.name == name }
	}

	func subtree(at index: Int) -> GRYSwiftAst? {
		return subtrees[safe: index]
	}

	func subtree(at index: Int, named name: String) -> GRYSwiftAst? {
		guard let subtree = subtrees[safe: index],
			subtree.name == name else
		{
			return nil
		}
		return subtree
	}

	//
	// TODO: Rename these methods
	public func writeAsSExpression(
		toFile filePath: String,
		withEncoder encoder: GRYEncoder = GRYEncoder())
	{
		let encoder = GRYEncoder()
		try! self.encode(into: encoder)
		let rawSExpressionString = encoder.result

		// Absolute file paths must be replaced with placeholders before writing to file.
		let swiftFilePath = GRYUtils.changeExtension(of: filePath, to: .swift)
		let escapedFilePath = swiftFilePath.replacingOccurrences(of: "/", with: "\\/")
		let processedSExpressionString =
			rawSExpressionString.replacingOccurrences(of: escapedFilePath, with: "<<testFilePath>>")

		try! processedSExpressionString.write(toFile: filePath, atomically: true, encoding: .utf8)
	}

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

	//
	public var treeDescription: String {
		return name
	}

	public var printableSubtrees: [GRYPrintableAsTree?] {
		let keyValueStrings = keyValueAttributes.map { "\($0.key) → \($0.value)" }
			.sorted() as [GRYPrintableAsTree]

		let standaloneStrings = standaloneAttributes as [GRYPrintableAsTree]

		let result: [GRYPrintableAsTree] = standaloneStrings + keyValueStrings + subtrees
		return result
	}

	//
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

	public static func == (lhs: GRYSwiftAst, rhs: GRYSwiftAst) -> Bool {
		return lhs.name == rhs.name &&
			lhs.standaloneAttributes == rhs.standaloneAttributes &&
			lhs.keyValueAttributes == rhs.keyValueAttributes &&
			lhs.subtrees == rhs.subtrees
	}
}
