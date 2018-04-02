//class GRYAstCallExpression {
//	/// Caller should have read "(call_expr"
//	internal static func initialize(parser: GRYSExpressionParser) -> GRYAstCallExpression {
//		let type: String
//		let location: String
//
//		parser.readIdentifier("implicit")
//		parser.readIdentifier("type=")
//		type = parser.readSingleQuotedString()
//		parser.readIdentifier("location=")
//		parser.readIdentifier()
//		parser.readIdentifier("range=")
//		location = parser.readStringInBrackets()
//		parser.readIdentifier("nothrow")
//		parser.readIdentifier("arg_labels=")
//
//		if let argumentLabels = parser.attemptToReadIdentifier(oneOf: ["_builtinIntegerLiteral:"]) {
//			switch argumentLabels {
//			case "_builtinIntegerLiteral:":
//
//			}
//		}
//	}
//}
