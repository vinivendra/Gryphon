class PrintableTree: PrintableAsTree {
    var treeDescription: String
    var printableSubTrees = [PrintableAsTree]()
    
    var parent: PrintableTree?
    
    init(description: String) {
        self.treeDescription = description
    }
	
	init(description: String, subTrees: [PrintableAsTree]) {
		self.treeDescription = description
		self.printableSubTrees = subTrees
	}
    
    func addChild(_ child: PrintableTree) {
        printableSubTrees.append(child)
        child.parent = self
    }
    
    func addSibling(_ sibling: PrintableTree) {
        parent!.addChild(sibling)
    }
}

protocol PrintableAsTree {
    var treeDescription: String { get }
    var printableSubTrees: [PrintableAsTree] { get }
}

extension PrintableAsTree {
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
        
        print(treeDescription)
        
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

extension String: PrintableAsTree {
	var treeDescription: String { return self }
	var printableSubTrees: [PrintableAsTree] { return [] }
}

extension Array: PrintableAsTree where Element: PrintableAsTree {
	var treeDescription: String { return "Array" }
	var printableSubTrees: [PrintableAsTree] { return self }
}
