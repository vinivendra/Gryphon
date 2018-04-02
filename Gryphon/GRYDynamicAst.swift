class GRYDynamicAst {
    public var name = ""
    public var attributes = ""
    public var subTrees = [GRYDynamicAst]()
	
	convenience public init(fileContents: String) {
		let parser = GRYSExpressionParser(fileContents: fileContents)
		self.init(parser: parser)
	}
	
	internal init(parser: GRYSExpressionParser) {
		parser.readOpenParentheses()
		self.name = parser.readIdentifier()
		
		for _ in 0..<1_000 { // To avoid infinite loops
			
			if parser.canReadOpenParentheses() {
				let subTree = GRYDynamicAst(parser: parser)
				subTrees.append(subTree)
			}
			else if parser.canReadCloseParentheses() {
				parser.readCloseParentheses()
				return
			}
			else {
				let string = parser.readIdentifierOrString()
				attributes += string
				attributes += " "
			}
		}
		
		fatalError("Error creating dynamic AST") // If the loop was infinite
	}
}

extension GRYDynamicAst: GRYPrintableAsTree {
    public var treeDescription: String {
		let improvedName = Utils.expandSwiftAbbreviation(name)
		
		if attributes.isEmpty {
			return " \(improvedName)"
		}
		else {
			return " \(improvedName): \(attributes)"
		}
    }
    
    public var printableSubTrees: [GRYPrintableAsTree] { return subTrees }
}
