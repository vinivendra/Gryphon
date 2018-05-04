public class GRYPrintableTree: GRYPrintableAsTree {
	public var treeDescription: String
	public var printableSubTrees = [GRYPrintableAsTree]()
	
	init(description: String) {
		self.treeDescription = description
	}
	
	init(description: String, subTrees: [GRYPrintableAsTree]) {
		self.treeDescription = description
		self.printableSubTrees = subTrees
	}
	
	func addChild(_ child: GRYPrintableAsTree) {
		printableSubTrees.append(child)
	}
}

public protocol GRYPrintableAsTree {
	var treeDescription: String { get }
	var printableSubTrees: [GRYPrintableAsTree] { get }
}

public extension GRYPrintableAsTree {
	func prettyPrint(indentation: [String] = [], isLast: Bool = true, horizontalLimit: Int = Int.max, printFunction: (String) -> () = { print($0, terminator: "") })
	{
		var indentation = indentation
		
		// Print the indentation
		let indentationString = indentation.joined(separator: "")
		
		let rawLine = "\(indentationString) \(treeDescription)"
		let line = (rawLine.count > horizontalLimit) ?
			rawLine.prefix(horizontalLimit - 1) + "…" :
			rawLine
		
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
		
		for subTree in printableSubTrees.dropLast() {
			var newIndentation = indentation
			newIndentation.append(" ├─")
			subTree.prettyPrint(indentation: newIndentation,
								isLast: false,
								horizontalLimit: horizontalLimit,
								printFunction: printFunction)
		}
		var newIndentation = indentation
		newIndentation.append(" └─")
		printableSubTrees.last?.prettyPrint(indentation: newIndentation,
											isLast: true,
											horizontalLimit: horizontalLimit,
											printFunction: printFunction)
	}
}

// MARK: Common Types

extension String: GRYPrintableAsTree {
	public var treeDescription: String { return self }
	public var printableSubTrees: [GRYPrintableAsTree] { return [] }
}

extension Array: GRYPrintableAsTree where Element: GRYPrintableAsTree {
	public var treeDescription: String { return "Array" }
	public var printableSubTrees: [GRYPrintableAsTree] { return self }
}
