public class GRYAstParameter: GRYPrintableAsTree {
	public var apiName: String
	public var type: String!
	
	internal init(parser: GRYSExpressionParser) {
		self.apiName = parser.readDoubleQuotedString()
		
		while let attribute = parser.attemptToReadIdentifier(oneOf: ["apiName=", "type=", "interface type="]) {
			switch attribute {
			case "type=":
				self.type = parser.readSingleQuotedString()
			case "apiName=": parser.readIdentifier()
			case "interface type=": parser.readSingleQuotedString()
			default: fatalError() // Exhaustive switch
			}
		}
		
		parser.readCloseParentheses()
	}
	
	//
	public var treeDescription: String { return "Parameter" }
	public var printableSubTrees: [GRYPrintableAsTree] {
		return ["API Name: \(apiName)", "Type: \(type!)"]
	}
}
