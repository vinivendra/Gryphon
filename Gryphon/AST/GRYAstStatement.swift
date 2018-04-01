public class GRYAstStatement: GRYAstItem {
	internal static func initialize(parser: GRYSExpressionParser) -> GRYAstStatement {
		parser.readOpenParentheses()
		let itemName = parser.readIdentifier(oneOf: ["pattern_binding_decl"])
		
		switch itemName {
		case "pattern_binding_decl":
			return GRYAstVariableDeclaration(parser: parser)
		default: fatalError() // Exhaustive switch
		}
	}
}
