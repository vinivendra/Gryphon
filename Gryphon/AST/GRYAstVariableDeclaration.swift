public class GRYAstVariableDeclaration: GRYAstStatement {
	let type: String
	let identifier: String
	let access: String
	
	/// Caller should have opened and read "(pattern_binding_decl"
	internal init(parser: GRYSExpressionParser) {
		let type: String
		let identifier: String
		var access: String?
		
		// Read info from parser
		parser.readOpenParentheses() // open pattern_type
		parser.readIdentifier("pattern_typed")
		parser.readIdentifier("type=")
		type = parser.readSingleQuotedString()
		
		parser.readOpenParentheses() // open pattern_named
		parser.readIdentifier("pattern_named")
		parser.readIdentifier("type=")
		parser.readSingleQuotedString()
		identifier = parser.readSingleQuotedString()
		parser.readCloseParentheses() // close pattern_named
		
		parser.readOpenParentheses() // open type_ident
		parser.readUntilCloseParentheses() // close type_ident
		
		parser.readCloseParentheses() // close pattern_typed
		parser.readCloseParentheses() // close pattern_binding_decl (opened by caller)
		
		parser.readOpenParentheses() // open var_decl
		parser.readIdentifier("var_decl")
		parser.readDoubleQuotedString()
		while let itemName = parser.attemptToReadIdentifier(oneOf: ["type=", "interface type=", "access=", "storage_kind="]) {
			switch itemName {
			case "access=":
				access = parser.readIdentifier()
			case "storage_kind=": parser.readIdentifier()
			case "type=", "interface type=": parser.readSingleQuotedString()
			default: fatalError() // Exhaustive switch
			}
		}
		parser.readCloseParentheses() // close var_decl
		
		// Initialize
		self.type = type
		self.identifier = identifier
		self.access = access!
		super.init()
	}
	
	//
	public override var treeDescription: String { return "Variable Declaration" }
	public override var printableSubTrees: [GRYPrintableAsTree] {
		return [
			"Identifier: \(identifier)",
			"Type: \(type)",
			"Access: \(access)"]
	}
}
