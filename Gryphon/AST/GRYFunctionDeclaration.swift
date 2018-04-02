//public class GRYAstFunctionDeclaration: GRYAstDeclaration {
//	public let identifier: String
//	public let type: String
//	public let access: String
//	public let parameters: [GRYAstParameter]
//	public let body: [GRYAstStatement]
//	
//	internal init(parser: GRYSExpressionParser) {
//		let identifier: String
//		var type: String?
//		var access: String?
//		var parameters = [GRYAstParameter]()
//		var body: [GRYAstStatement]?
//		
//		identifier = parser.readDoubleQuotedString()
//		
//		while let attribute = parser.attemptToReadIdentifier(oneOf: ["interface type=", "access="]) {
//			switch attribute {
//			case "interface type=":
//				type = parser.readSingleQuotedString()
//			case "access=":
//				access = parser.readIdentifier()
//			default: fatalError() // Exhaustive switch
//			}
//		}
//		
//		while parser.canReadOpenParentheses() {
//			parser.readOpenParentheses()
//			let itemName = parser.readIdentifier(oneOf: ["parameter_list", "brace_stmt"])
//			switch itemName {
//			case "parameter_list":
//				let parameterList = GRYAstFunctionDeclaration.readParameterList(withParser: parser)
//				parameters.append(contentsOf: parameterList)
//			case "brace_stmt":
//				assert(body == nil)
//				body = GRYAstFunctionDeclaration.readStatementList(withParser: parser)
//			default: fatalError() // Exhaustive switch
//			}
//		}
//		
//		// Initialize
//		self.identifier = identifier
//		self.type = type!
//		self.access = access!
//		self.parameters = parameters
//		self.body = body!
//		super.init()
//	}
//	
//	private static func readParameterList(withParser parser: GRYSExpressionParser) -> [GRYAstParameter] {
//		var result = [GRYAstParameter]()
//		
//		while parser.canReadOpenParentheses() {
//			parser.readOpenParentheses()
//			parser.readIdentifier("parameter")
//			let parameter = GRYAstParameter(parser: parser)
//			result.append(parameter)
//		}
//		
//		parser.readCloseParentheses()
//		
//		return result
//	}
//	
//	private static func readStatementList(withParser parser: GRYSExpressionParser) -> [GRYAstStatement] {
//		var result = [GRYAstStatement]()
//		
//		while parser.canReadOpenParentheses() {
//			let statement = GRYAstStatement.initialize(parser: parser)
//			result.append(statement)
//		}
//		
//		parser.readCloseParentheses()
//		
//		return result
//	}
//	
//	//
//	public override var treeDescription: String { return "Function Declaration" }
//	public override var printableSubTrees: [GRYPrintableAsTree] {
//		return [
//			"Identifier: \(identifier)",
//			"Type: \(type)",
//			"Access: \(access)",
//			GRYPrintableTree(description: "Parameters", subTrees: parameters),
//			GRYPrintableTree(description: "Statements", subTrees: body)]
//	}
//}
