public class GRYAst: GRYPrintableAsTree {
	public var items = [GRYAstItem]()
	
	convenience public init(fileContents: String) {
		let parser = GRYSExpressionParser(fileContents: fileContents)
		self.init(parser: parser)
	}
	
	internal init(parser: GRYSExpressionParser) {
		parser.readOpenParentheses()
		parser.readIdentifier("source_file")
		
		while parser.canReadOpenParentheses() {
			parser.readOpenParentheses()
			let itemName = parser.readIdentifier(oneOf: ["func_decl"])
			
			switch itemName {
			case "func_decl":
				let functionDeclaration = GRYAstFunctionDeclaration(parser: parser)
				items.append(functionDeclaration)
			default: fatalError() // Exhaustive switch
			}
		}
	}
	
	//
	public private(set) var treeDescription = "Source File"
	public var printableSubTrees: [GRYPrintableAsTree] { return items }
}
