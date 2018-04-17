public class GRYKotlinTranslator {
	public func translateAST(_ ast: GRYAst) -> String {
		var result = ""
		
		for subTree in ast.subTrees {
			switch subTree.name {
			case "Function Declaration":
				let string = translate(functionDeclaration: subTree, withIndentation: "")
				result += string + "\n"
			default:
				result += "<Unknown: \(subTree.name)>\n\n"
			}
		}
		
		return result
	}
	
	// TODO: Functions with different parameter/API names
	private func translate(functionDeclaration: GRYAst, withIndentation indentation: String) -> String {
		assert(functionDeclaration.name == "Function Declaration")
		
		var indentation = indentation
		var result = ""
		
		result += indentation
		
		if let access = functionDeclaration["access"] {
			result += access + " "
		}
		
		result += "fun "
		
		let functionName = functionDeclaration.standaloneAttributes[0]
		let functionNamePrefix = functionName.prefix { $0 != "(" }
		
		result += functionNamePrefix + "("
		
		var parameterStrings = [String]()
		if let parameterList = functionDeclaration.subTree(named: "Parameter List") {
			for parameter in parameterList.subTrees {
				let name = parameter["apiName"]!
				let type = parameter["interface type"]!
				parameterStrings.append(name + ": " + type)
			}
		}
		
		result += parameterStrings.joined(separator: ", ")
		
		result += ")"
		
		// TODO: Doesn't allow to return function types
		let returnType = functionDeclaration["interface type"]!.split(withStringSeparator: " -> ").last!
		if returnType != "()" {
			result += ": " + returnType
		}
		
		result += " {\n"
		
		indentation = increaseIndentation(indentation)
		
		let braceStatement = functionDeclaration.subTree(named: "Brace Statement")!
		result += translate(statements: braceStatement.subTrees, withIndentation: indentation)
		
		indentation = decreaseIndentation(indentation)
		
		result += indentation + "}\n"
		
		return result
	}
	
	//
	private func translate(statements: [GRYAst], withIndentation indentation: String) -> String {
		var result = ""
		
		var i = 0
		while i < statements.count {
			defer { i += 1 }
			
			let statement = statements[i]
			
			switch statement.name {
			case "Pattern Binding Declaration":
				let variableDeclaration = statements[i + 1]
				i += 1 // skip the variable declaration
				assert(variableDeclaration.name == "Variable Declaration")
				result += translate(patternBindingDeclaration: statement,
									variableDeclaration: variableDeclaration,
									withIndentation: indentation)
			case "Return Statement":
				result += translate(returnStatement: statement, withIndentation: indentation)
			default:
				result += indentation + "<Unknown statement: \(statement.name)>\n"
			}
		}
		
		return result
	}
	
	private func translate(returnStatement: GRYAst,
						   withIndentation indentation: String) -> String
	{
		assert(returnStatement.name == "Return Statement")
		var result = indentation
		
		let expression = translate(expression: returnStatement.subTrees.last!)
		
		result += "return " + expression + "\n"
		
		return result
	}
	
	private func translate(patternBindingDeclaration: GRYAst,
						   variableDeclaration: GRYAst,
						   withIndentation indentation: String) -> String
	{
		assert(patternBindingDeclaration.name == "Pattern Binding Declaration")
		assert(variableDeclaration.name == "Variable Declaration")
		var result = indentation
		
		let identifier = variableDeclaration.standaloneAttributes[0]
		let type = variableDeclaration["interface type"]!
		
		let varOrValKeyword: String
		if variableDeclaration.standaloneAttributes.contains("let") {
			varOrValKeyword = "val"
		}
		else {
			varOrValKeyword = "var"
		}
		
		result += varOrValKeyword + " " + identifier + ": " + type + " = "
		
		result += translate(expression: patternBindingDeclaration.subTree(named: "Call Expression")!)
		
		result += "\n"
		
		return result
	}
	
	//
	private func translate(expression: GRYAst) -> String {
		switch expression.name {
		case "Call Expression":
			if let argumentLabels = expression["arg_labels"],
				argumentLabels == "_builtinIntegerLiteral:",
				let tupleExpression = expression.subTree(named: "Tuple Expression"),
				let integerLiteralExpression = tupleExpression.subTree(named: "Integer Literal Expression"),
				let value = integerLiteralExpression["value"]
			{
				return value
			}
			else {
				return "<Unknown expression: \(expression.name)>"
			}
		case "Declref Expression":
			let decl = expression["decl"]!
			
			var matchIterator = decl =~ "^([^@\\s]*?)@"
			let match = matchIterator.next()!
			let matchedString = match.captureGroup(1)!.matchedString
			
			let components = matchedString.split(separator: ".")
			let identifier = components.last!
			
			return String(identifier)
		default:
			return "<Unknown expression: \(expression.name)>"
		}
	}
	
	//
	func increaseIndentation(_ indentation: String) -> String {
		return indentation + "\t"
	}
	
	func decreaseIndentation(_ indentation: String) -> String {
		return String(indentation.dropLast())
	}
}
