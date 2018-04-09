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
    
    func addChild(_ child: GRYPrintableTree) {
        printableSubTrees.append(child)
    }
}

public protocol GRYPrintableAsTree {
    var treeDescription: String { get }
    var printableSubTrees: [GRYPrintableAsTree] { get }
}

public extension GRYPrintableAsTree {
    func prettyPrint(indentation: [String] = [], isLast: Bool = true) {
        var indentation = indentation
        
        // Print the indentation
        let indentationString = indentation.joined(separator: "")
        print(indentationString, terminator: "")
        
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
        
        print(" " + treeDescription)
        
        for subTree in printableSubTrees.dropLast() {
            var newIndentation = indentation
            newIndentation.append(" ├─")
            subTree.prettyPrint(indentation: newIndentation,
                                isLast: false)
        }
        var newIndentation = indentation
        newIndentation.append(" └─")
        printableSubTrees.last?.prettyPrint(indentation: newIndentation,
                                            isLast: true)
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
