public class GRYAst: GRYPrintableAsTree, Equatable {
	let name: String
	let standaloneAttributes: [String]
	let keyValueAttributes: [String: String]
	let subTrees: [GRYAst]
	
	public convenience init(fileContents: String) {
		let parser = GRYSExpressionParser(fileContents: fileContents)
		self.init(parser: parser)
	}
	
	internal init(parser: GRYSExpressionParser) {
		var standaloneAttributes = [String]()
		var keyValueAttributes = [String: String]()
		var subTrees = [GRYAst]()
		
		parser.readOpenParentheses()
		let name = parser.readIdentifier()
		self.name = Utils.expandSwiftAbbreviation(name)

		// The loop stops: all branches tell the parser to read, and the input string must end eventually.
		while true {
			if parser.canReadKey() {
				let key = parser.readKey()
                if key == "location" && parser.canReadLocation() {
                    keyValueAttributes[key] = parser.readLocation()
                }
                else if key == "decl" && parser.canReadDeclarationLocation() {
                    keyValueAttributes[key] = parser.readDeclarationLocation()
                }
                else {
                    keyValueAttributes[key] = parser.readIdentifierOrString()
                }
			}
			else if parser.canReadIdentifierOrString() {
				let attribute = parser.readIdentifierOrString()
				standaloneAttributes.append(attribute)
			}
			else if parser.canReadOpenParentheses() {
				let subTree = GRYAst(parser: parser)
				subTrees.append(subTree)
			}
			else {
				parser.readCloseParentheses()
				break
			}
		}

		self.standaloneAttributes = standaloneAttributes
		self.keyValueAttributes = keyValueAttributes
		self.subTrees = subTrees
	}
	
    //
    subscript (key: String) -> String? {
        return keyValueAttributes[key]
    }
    
    func subTree(named name: String) -> GRYAst? {
        for subTree in subTrees {
            if subTree.name == name {
                return subTree
            }
        }
        
        return nil
    }
    
	//
	public var treeDescription: String {
		return name
	}
	public var printableSubTrees: [GRYPrintableAsTree] {
		let keyValueStrings: [GRYPrintableAsTree] = keyValueAttributes.map {
			"\($0.key) → \($0.value)"
		}
		let result: [GRYPrintableAsTree] =
			(standaloneAttributes as [GRYPrintableAsTree]) +
			keyValueStrings + subTrees
		return result
	}
	
	// MARK: - Testing
	internal init(_ name: String,
				  _ subTrees: [GRYAst] = [])
	{
		self.name = name
		self.standaloneAttributes = []
		self.keyValueAttributes = [:]
		self.subTrees = subTrees
	}
	
	internal init(_ name: String,
				  _ standaloneAttributes: [String],
				  _ keyValueAttributes: [String: String],
				  _ subTrees: [GRYAst] = [])
	{
		self.name = name
		self.standaloneAttributes = standaloneAttributes
		self.keyValueAttributes = keyValueAttributes
		self.subTrees = subTrees
	}
	
	public static func == (lhs: GRYAst, rhs: GRYAst) -> Bool {
		return lhs.name == rhs.name &&
			lhs.standaloneAttributes == rhs.standaloneAttributes &&
			lhs.keyValueAttributes == rhs.keyValueAttributes &&
			lhs.subTrees == rhs.subTrees
	}
}
