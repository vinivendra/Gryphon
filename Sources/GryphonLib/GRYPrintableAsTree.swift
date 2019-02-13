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

public class GRYPrintableTree: GRYPrintableAsTree {
	public var treeDescription: String = GRYAnnotations("override", "")
	public var printableSubtrees: ArrayReference<GRYPrintableAsTree?> =
		GRYAnnotations("override", [])

	init(_ description: String) {
		self.treeDescription = description
	}

	init(_ description: String, _ subtrees: ArrayReference<GRYPrintableAsTree?>) {
		self.treeDescription = description
		self.printableSubtrees = subtrees
	}

	init(_ description: String, _ subtrees: ArrayReference<String?>) {
		GRYIgnoreThisFunction()

		let stringToTree: (String?) -> (GRYPrintableAsTree?) = { string in
			if let string = string {
				return GRYPrintableTree(string)
			}
			else {
				return nil
			}
		}

		self.treeDescription = description
		self.printableSubtrees = subtrees.map(stringToTree)
	}

	init(_ array: ArrayReference<GRYPrintableAsTree?>) {
		self.treeDescription = "Array"
		self.printableSubtrees = array
	}

	static func initOrNil(
		_ description: String, _ subtreesOrNil: ArrayReference<GRYPrintableAsTree?>)
		-> GRYPrintableTree?
	{
		let subtrees: ArrayReference<GRYPrintableAsTree?> = []
		for subtree in subtreesOrNil {
			if let unwrapped = subtree {
				subtrees.append(unwrapped)
			}
		}

		guard !subtrees.isEmpty else {
			return nil
		}

		return GRYPrintableTree(description, subtrees)
	}

	static func initOrNil(_ description: String?) -> GRYPrintableTree? {
		if let description = description {
			return GRYPrintableTree(description)
		}
		else {
			return nil
		}
	}

	func addChild(_ child: GRYPrintableAsTree?) {
		printableSubtrees.append(child)
	}
}

public protocol GRYPrintableAsTree {
	var treeDescription: String { get }
	var printableSubtrees: ArrayReference<GRYPrintableAsTree?> { get }
}

public extension GRYPrintableAsTree {
	func prettyPrint(
		indentation: ArrayReference<String> = [],
		isLast: Bool = true,
		horizontalLimit: Int = Int.max,
		printFunction: (String) -> () = { print($0, terminator: "") })
	{
		// Print the indentation
		let indentationString = indentation.joined(separator: "")

		let rawLine = "\(indentationString) \(treeDescription)"
		let line: String
		if rawLine.count > horizontalLimit {
			line = rawLine.prefix(horizontalLimit - 1) + "…"
		}
		else {
			line = rawLine
		}

		printFunction(line + "\n")

		// Correct the indentation for this level
		if !indentation.isEmpty {
			// If I'm the last branch, don't print a line in my level anymore.
			if isLast {
				indentation[indentation.count - 1] = "   "
			}
			// If there are more branches after me, keep printing the line
			// so my siblings can be correctly printed later.
			else {
				indentation[indentation.count - 1] = " │ "
			}
		}

		let subtrees: ArrayReference<GRYPrintableAsTree> = []
		for element in printableSubtrees {
			if let unwrapped = element {
				subtrees.append(unwrapped)
			}
		}

		for subtree in subtrees.dropLast() {
			let newIndentation = indentation.copy()
			newIndentation.append(" ├─")
			subtree.prettyPrint(
				indentation: newIndentation,
				isLast: false,
				horizontalLimit: horizontalLimit,
				printFunction: printFunction)
		}
		let newIndentation = indentation.copy()
		newIndentation.append(" └─")
		subtrees.last?.prettyPrint(
			indentation: newIndentation,
			isLast: true,
			horizontalLimit: horizontalLimit,
			printFunction: printFunction)
	}
}
