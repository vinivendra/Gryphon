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

public class GRYAstItem: GRYPrintableAsTree {
	public private(set) var treeDescription = "<Item>"
	public private(set) var printableSubTrees = [GRYPrintableAsTree]()
}

public class GRYAstDeclaration: GRYAstItem { }

public class GRYAstFunctionDeclaration: GRYAstDeclaration {
	public var identifier: String
	public var type: String!
	public var access: String!
	public var parameters = [GRYAstParameter]()
	
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
			case "brace_stmt": break
			default: fatalError() // Exhaustive switch
			}
		}
	}
	
	private func readParameterList(withParser parser: GRYSExpressionParser) -> [GRYAstParameter] {
		var result = [GRYAstParameter]()
		
		while parser.canReadOpenParentheses() {
			parser.readOpenParentheses()
			parser.readIdentifier("parameter")
			let parameter = GRYAstParameter(parser: parser)
			result.append(parameter)
		}
		
		return result
	}
	
	//
	public override var treeDescription: String { return "Function Declaration" }
	public override var printableSubTrees: [GRYPrintableAsTree] {
		return [
			"Identifier: \(identifier)",
			"Type: \(type!)",
			"Access: \(access!)",
			GRYPrintableTree(description: "Parameters", subTrees: parameters)]
	}
}

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
