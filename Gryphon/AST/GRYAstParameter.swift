//public class GRYAstParameter: GRYPrintableAsTree {
//	public let apiName: String
//	public let type: String
//
//	internal init(parser: GRYSExpressionParser) {
//		let apiName: String
//		var type: String?
//
//		apiName = parser.readDoubleQuotedString()
//		
//		while let attribute = parser.attemptToReadIdentifier(oneOf: ["apiName=", "type=", "interface type="]) {
//			switch attribute {
//			case "type=":
//				type = parser.readSingleQuotedString()
//			case "apiName=": parser.readIdentifier()
//			case "interface type=": parser.readSingleQuotedString()
//			default: fatalError() // Exhaustive switch
//			}
//		}
//
//		parser.readCloseParentheses()
//
//		self.apiName = apiName
//		self.type = type!
//	}
//
//	//
//	public var treeDescription: String { return "Parameter" }
//	public var printableSubTrees: [GRYPrintableAsTree] {
//		return ["API Name: \(apiName)", "Type: \(type)"]
//	}
//}
