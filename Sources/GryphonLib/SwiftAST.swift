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

public final class SwiftAST: PrintableAsTree, Equatable, CustomStringConvertible {
	let name: String
	let standaloneAttributes: ArrayClass<String>
	let keyValueAttributes: DictionaryClass<String, String>
	let subtrees: ArrayClass<SwiftAST>

	//
	static public var horizontalLimitWhenPrinting = Int.max

	//
	internal init(_ name: String, _ subtrees: ArrayClass<SwiftAST> = []) {
		self.name = name
		self.standaloneAttributes = []
		self.keyValueAttributes = [:]
		self.subtrees = subtrees
	}

	internal init(
		_ name: String,
		_ standaloneAttributes: ArrayClass<String>,
		_ keyValueAttributes: DictionaryClass<String, String>,
		_ subtrees: ArrayClass<SwiftAST> = [])
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

	func subtree(named name: String) -> SwiftAST? { // gryphon: pure
		return subtrees.first { $0.name == name }
	}

	func subtree(at index: Int) -> SwiftAST? { // gryphon: pure
		guard index >= 0, index < subtrees.count else {
			return nil
		}
		return subtrees[index]
	}

	func subtree(at index: Int, named name: String) -> SwiftAST? { // gryphon: pure
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
	public var treeDescription: String { // annotation: override
		return name
	}

	public var printableSubtrees: ArrayClass<PrintableAsTree?> { // annotation: override
		let keyValueStrings = keyValueAttributes
			.map { "\($0.key) → \($0.value)" }.sorted().map { PrintableTree($0) }
		let keyValueArray = ArrayClass<PrintableAsTree?>(keyValueStrings)
		let standaloneAttributesArray =
			ArrayClass<PrintableAsTree?>(standaloneAttributes.map { PrintableTree($0) })
		let subtreesArray = ArrayClass<PrintableAsTree?>(subtrees)

		let result = standaloneAttributesArray
		result.append(contentsOf: keyValueArray)
		result.append(contentsOf: subtreesArray)

		return result
	}

	// MARK: - Descriptions
	public var description: String { // annotation: override
		return self.prettyDescription()
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
