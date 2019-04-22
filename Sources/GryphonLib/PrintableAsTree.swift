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

public class PrintableTree: PrintableAsTree {
	public var treeDescription: String // annotation: override
	public var printableSubtrees: ArrayClass<PrintableAsTree?> // annotation: override

	init(_ description: String) {
		self.treeDescription = description
		self.printableSubtrees = []
	}

	init(_ description: String, _ subtrees: ArrayClass<PrintableAsTree?>) {
		self.treeDescription = description
		self.printableSubtrees = subtrees
	}

	init(_ description: String, _ subtrees: ArrayClass<String?>) { // kotlin: ignore
		let stringToTree: (String?) -> (PrintableAsTree?) = { string in
			if let string = string {
				return PrintableTree(string)
			}
			else {
				return nil
			}
		}

		self.treeDescription = description
		self.printableSubtrees = subtrees.map(stringToTree)
	}

	init(_ array: ArrayClass<PrintableAsTree?>) {
		self.treeDescription = "Array"
		self.printableSubtrees = array
	}

	static func initOrNil(
		_ description: String, _ subtreesOrNil: ArrayClass<PrintableAsTree?>)
		-> PrintableTree?
	{
		let subtrees: ArrayClass<PrintableAsTree?> = []
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

	func addChild(_ child: PrintableAsTree?) {
		printableSubtrees.append(child)
	}
}

public protocol PrintableAsTree {
	var treeDescription: String { get }
	var printableSubtrees: ArrayClass<PrintableAsTree?> { get }
}

public extension PrintableAsTree {
	func prettyPrint(
		indentation: ArrayClass<String> = [],
		isLast: Bool = true,
		horizontalLimit: Int? = nil,
		printFunction: (String) -> () = { print($0, terminator: "") })
	{
		let horizontalLimit = horizontalLimit ?? Int.max

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

		let subtrees: ArrayClass<PrintableAsTree> = []
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

	// TODO: replace this in other places that use this method
	func prettyDescription(horizontalLimit: Int? = nil) -> String {
		var result = ""
		prettyPrint(horizontalLimit: horizontalLimit) { result += $0 }
		return result
	}
}
