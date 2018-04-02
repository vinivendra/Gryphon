//public class GRYAstExpression: GRYPrintableAsTree {
//	public let type: String
//	public let location: String
//
//	internal init(type: String, location: String) {
//		self.type = type
//		self.location = location
//	}
//
//	/// Caller should be about to read "(call_expr" or similar and should have checked the open parentheses exists
////	internal static func initialize(parser: GRYSExpressionParser) -> GRYAstExpression {
////		parser.readOpenParentheses()
////		let expressionType = parser.readIdentifier(oneOf: ["call_expr"])
////
////		switch expressionType {
////		case "call_expr":
////			let expression = GRYAstCallExpression(parser: parser)
////		default: fatalError() // Exhaustive switch
////		}
////	}
//	
//	//
//	public var treeDescription: String { return "<Expression>" }
//	public var printableSubTrees: [GRYPrintableAsTree] { return [] }
//}
