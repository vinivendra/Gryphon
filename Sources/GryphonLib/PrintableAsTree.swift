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

// gryphon output: Sources/GryphonLib/PrintableAsTree.swiftAST
// gryphon output: Sources/GryphonLib/PrintableAsTree.gryphonASTRaw
// gryphon output: Sources/GryphonLib/PrintableAsTree.gryphonAST
// gryphon output: Bootstrap/PrintableAsTree.kt

public class PrintableTree: PrintableAsTree {
	public var treeDescription: String // gryphon annotation: override
	public var printableSubtrees: List<PrintableAsTree?> // gryphon annotation: override

	init(_ description: String) {
		self.treeDescription = description
		self.printableSubtrees = []
	}

	init(_ description: String, _ subtrees: List<PrintableAsTree?>) {
		self.treeDescription = description
		self.printableSubtrees = subtrees
	}

	init(_ array: List<PrintableAsTree?>) {
		self.treeDescription = "Array"
		self.printableSubtrees = array
	}

	static func ofTrees(
		_ description: String,
		_ subtrees: List<PrintableTree>)
		-> PrintableAsTree?
	{
		let newSubtrees = subtrees.forceCast(to: List<PrintableAsTree?>.self)
		return PrintableTree.initOrNil(description, newSubtrees)
	}

	static func initOrNil(
		_ description: String,
		_ subtreesOrNil: List<PrintableAsTree?>)
		-> PrintableTree?
	{
		let subtrees: MutableList<PrintableAsTree?> = []
		for subtree in subtreesOrNil {
			if let unwrapped = subtree {
				subtrees.append(unwrapped)
			}
		}

		guard !subtrees.isEmpty else {
			return nil
		}

		return PrintableTree(description, subtrees)
	}

	static func initOrNil(_ description: String?) -> PrintableTree? {
		if let description = description {
			return PrintableTree(description)
		}
		else {
			return nil
		}
	}
}

public protocol PrintableAsTree {
	var treeDescription: String { get }
	var printableSubtrees: List<PrintableAsTree?> { get }
}

public var printableAsTreeHorizontalLimit: Int?

public extension PrintableAsTree {
	func prettyPrint(
		indentation: MutableList<String> = [],
		isLast: Bool = true,
		printFunction: (String) -> () = { print($0, terminator: "") })
	{
		let verticalBar = Compiler.shouldAvoidUnicodeCharacters ? "|" : "│"
		let verticalRightBar = Compiler.shouldAvoidUnicodeCharacters ? "|" : "├"
		let cornerBar = Compiler.shouldAvoidUnicodeCharacters ? "|" : "└"
		let horizontalBar = Compiler.shouldAvoidUnicodeCharacters ? "-" : "─"
		let ellipsis = Compiler.shouldAvoidUnicodeCharacters ? "..." : "…"

		let horizontalLimit = printableAsTreeHorizontalLimit ?? Int.max

		// Print the indentation
		let indentationString = indentation.joined(separator: "")

		// Create the line
		let rawLine = "\(indentationString) \(treeDescription)"

		// Cut the line the horizontal limit, then add ellipsis if necessary
		let line: String
		if rawLine.count > horizontalLimit {
			line = rawLine.prefix(horizontalLimit - ellipsis.count) + ellipsis
		}
		else {
			line = rawLine
		}

		// Print the line
		printFunction(line + "\n")

		// Check if this is the last sibling, so we know whether to print this level's line while
		// printing the subtrees
		if !indentation.isEmpty {
			// If I'm the last branch, don't print a line in my level anymore.
			if isLast {
				indentation[indentation.count - 1] = "   "
			}
			// If there are more branches after me, keep printing the line
			// so my siblings can be correctly printed later.
			else {
				indentation[indentation.count - 1] = " \(verticalBar) "
			}
		}

		// Filter the subtrees to remove nil's
		let subtrees = printableSubtrees.compactMap { $0 }

		// Print each non-nil subtree except the last one
		for subtree in subtrees.dropLast() {
			let newIndentation = indentation.toMutableList()
			newIndentation.append(" \(verticalRightBar)\(horizontalBar)")
			subtree.prettyPrint(
				indentation: newIndentation,
				isLast: false,
				printFunction: printFunction)
		}

		// Print the last subtree
		let newIndentation = indentation.toMutableList()
		newIndentation.append(" \(cornerBar)\(horizontalBar)")
		subtrees.last?.prettyPrint(
			indentation: newIndentation,
			isLast: true,
			printFunction: printFunction)
	}

	func prettyDescription() -> String {
		var result = ""
		prettyPrint { result += $0 }
		return result
	}
}
