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

public final class SwiftAST: PrintableAsTree, Equatable, CustomStringConvertible {
	let name: String
	let standaloneAttributes: MutableList<String>
	let keyValueAttributes: MutableMap<String, String>
	let subtrees: MutableList<SwiftAST>

	//
	static public var horizontalLimitWhenPrinting = Int.max

	//
	internal init(_ name: String, _ subtrees: MutableList<SwiftAST> = []) {
		self.name = name
		self.standaloneAttributes = []
		self.keyValueAttributes = [:]
		self.subtrees = subtrees
	}

	internal init(
		_ name: String,
		_ standaloneAttributes: MutableList<String>,
		_ keyValueAttributes: MutableMap<String, String>,
		_ subtrees: MutableList<SwiftAST> = [])
	{
		self.name = name
		self.standaloneAttributes = standaloneAttributes
		self.keyValueAttributes = keyValueAttributes
		self.subtrees = subtrees
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

	public var printableSubtrees: List<PrintableAsTree?> {
		let keyValueStrings = keyValueAttributes
			.map { "\($0.key) -> \($0.value)" }.sorted().map { PrintableTree($0) }
		let keyValueArray = keyValueStrings.forceCast(to: List<PrintableAsTree?>.self)
		let standaloneAttributesArray = standaloneAttributes
			.map { PrintableTree($0) }
			.forceCast(to: MutableList<PrintableAsTree?>.self)
		let subtreesArray = subtrees.forceCast(to: List<PrintableAsTree?>.self)

		let result = standaloneAttributesArray
		result.append(contentsOf: keyValueArray)
		result.append(contentsOf: subtreesArray)

		return result
	}

	// MARK: - Descriptions
	public var description: String {
		return self.prettyDescription()
	}

	// MARK: - Equatable
	public static func == (lhs: SwiftAST, rhs: SwiftAST) -> Bool {
		return lhs.name == rhs.name &&
			lhs.standaloneAttributes == rhs.standaloneAttributes &&
			lhs.keyValueAttributes == rhs.keyValueAttributes &&
			lhs.subtrees == rhs.subtrees
	}
}
