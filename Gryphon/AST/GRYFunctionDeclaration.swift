public class GRYAstFunctionDeclaration: GRYAstDeclaration {
	public var identifier: String
	public var type: String!
	public var access: String!
	public var parameters = [GRYAstParameter]()
	public var body: [GRYAstStatement]!
	
	internal init(parser: GRYSExpressionParser) {
		self.identifier = parser.readDoubleQuotedString()
		
		super.init()
		
		while let attribute = parser.attemptToReadIdentifier(oneOf: ["interface type=", "access="]) {
			switch attribute {
			case "interface type=":
				self.type = parser.readSingleQuotedString()
			case "access=":
				self.access = parser.readIdentifier()
			default: fatalError() // Exhaustive switch
			}
		}
		
		while parser.canReadOpenParentheses() {
			parser.readOpenParentheses()
			let itemName = parser.readIdentifier(oneOf: ["parameter_list", "brace_stmt"])
			switch itemName {
			case "parameter_list":
				let parameters = readParameterList(withParser: parser)
				self.parameters.append(contentsOf: parameters)
			case "brace_stmt":
				assert(body == nil)
				self.body = readStatementList(withParser: parser)
			default: fatalError() // Exhaustive switch
			}
		}
		
		assert(type != nil && access != nil && body != nil)
	}
	
	private func readParameterList(withParser parser: GRYSExpressionParser) -> [GRYAstParameter] {
		var result = [GRYAstParameter]()
		
		while parser.canReadOpenParentheses() {
			parser.readOpenParentheses()
			parser.readIdentifier("parameter")
			let parameter = GRYAstParameter(parser: parser)
			result.append(parameter)
		}
		
		parser.readCloseParentheses()
		
		return result
	}
	
	private func readStatementList(withParser parser: GRYSExpressionParser) -> [GRYAstStatement] {
		var result = [GRYAstStatement]()
		
		while parser.canReadOpenParentheses() {
			parser.readOpenParentheses()
			parser.readIdentifier("brace_stmt")
			let statement = GRYAstStatement(parser: parser)
			result.append(statement)
		}
		
		parser.readCloseParentheses()
		
		return result
	}
	
	//
	public override var treeDescription: String { return "Function Declaration" }
	public override var printableSubTrees: [GRYPrintableAsTree] {
		return [
			"Identifier: \(identifier)",
			"Type: \(type!)",
			"Access: \(access!)",
			GRYPrintableTree(description: "Parameters", subTrees: parameters),
			GRYPrintableTree(description: "Statements", subTrees: body)]
	}
}
