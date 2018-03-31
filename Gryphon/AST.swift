class SourceFile: PrintableAsTree, SExpressionParseable {
	var items = [Item]()
	
	required init(parser: SExpressionParser) {
		parser.readOpenParentheses()
		parser.readIdentifier("source_file")
		
		while parser.canReadOpenParentheses() {
			parser.readOpenParentheses()
			let itemName = parser.readIdentifier(oneOf: ["func_decl"])
			
			switch itemName {
			case "func_decl":
				let functionDeclaration = FunctionDeclaration(parser: parser)
				items.append(functionDeclaration)
			default: fatalError() // Exhaustive switch
			}
		}
	}
	
	//
	var treeDescription = "Source File"
	var printableSubTrees: [PrintableAsTree] { return items }
}

class Item: PrintableAsTree {
	private(set) var treeDescription = "<Item>"
	private(set) var printableSubTrees = [PrintableAsTree]()
}

class Declaration: Item { }

class FunctionDeclaration: Declaration {
	var identifier: String
	var type: String!
	var access: String!
	var parameters = [Parameter]()
	
	init(parser: SExpressionParser) {
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
			case "brace_stmt": break
			default: fatalError() // Exhaustive switch
			}
		}
	}
	
	func readParameterList(withParser parser: SExpressionParser) -> [Parameter] {
		var result = [Parameter]()
		
		while parser.canReadOpenParentheses() {
			parser.readOpenParentheses()
			parser.readIdentifier("parameter")
			let parameter = Parameter(parser: parser)
			result.append(parameter)
		}
		
		return result
	}
	
	//
	override var treeDescription: String { return "Function Declaration" }
	override var printableSubTrees: [PrintableAsTree] {
		return [
			"Identifier: \(identifier)",
			"Type: \(type!)",
			"Access: \(access!)",
			PrintableTree(description: "Parameters", subTrees: parameters)]
	}
}

class Parameter: PrintableAsTree {
	var apiName: String
	var type: String!
	
	init(parser: SExpressionParser) {
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
	var treeDescription: String { return "Parameter" }
	var printableSubTrees: [PrintableAsTree] {
		return ["API Name: \(apiName)", "Type: \(type!)"]
	}
}
