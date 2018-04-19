public class GRYKotlinTranslator {
	
	// MARK: - Interface

	/**
	Translates the swift statements in the `ast` into kotlin code wrapped in a `main` function.
	
	This is meant to be used to translate a "main" swift file, with executable top-level statements,
	into an analogous "main" kotlin file with an executable main function.
	
	- Parameter ast: The AST, obtained from swift, to be translated into kotlin. It's expected to
	contain top-level statements.
	- Returns: A kotlin translation of the contents of the AST, wrapped in a `main`
	function that can serve as an entry point for a kotlin program.
	- SeeAlso: To translate swift declarations into kotlin declarations without the `main` function
	wrapping, see translateAST(_ ast: GRYAst).
	*/
	public func translateASTWithMain(_ ast: GRYAst) -> String {
		var result = "fun main(args : Array<String>) {\n"
		
		let indentation = increaseIndentation("")
		
		for subTree in ast.subTrees {
			switch subTree.name {
			case "Top Level Code Declaration":
				let string = translate(topLevelCode: subTree, withIndentation: indentation)
				result += string
			case "Variable Declaration":
				let string = translate(variableDeclaration: subTree, withIndentation: indentation)
				result += string
			default:
				result += "<Unknown: \(subTree.name)>\n\n"
			}
		}
		
		result += "}\n"
		
		return result
	}
	
	/**
	Translates the swift declarations in the `ast` into kotlin code.
	- Parameter ast: The AST, obtained from swift, to be translated into kotlin.
	- Returns: A kotlin translation of the contents of the AST.
	- SeeAlso: To translate statements into executable kotlin code (i.e. inside a main function),
	see `translateASTWithMain(_:)`.
	*/
	public func translateAST(_ ast: GRYAst) -> String {
		var result = ""
		
		for subTree in ast.subTrees {
			switch subTree.name {
			case "Function Declaration":
				let string = translate(functionDeclaration: subTree, withIndentation: "")
				result += string
			default:
				result += "<Unknown: \(subTree.name)>\n\n"
			}
		}
		
		return result
	}
	
	// MARK: - Implementation
	
	/// Swift variables declared with a value, such as `var x = 0`, are represented in a weird way in the AST:
	/// first comes a `Pattern Binding Declaration` containing the variable's name, its type, and
	/// its initial value; then comes the actual `Variable Declaration`, but in a different branch of the AST and
	/// with no information on the previously mentioned initial value.
	/// Since both of them have essential information, we need both at the same time to translate a variable
	/// declaration. However, since they are in unpredictably different branches, it's hard to find the Variable
	/// Declaration when we first read the Pattern Binding Declaration.
	///
	/// The solution then is to temporarily save the Pattern Binding Declaration's information on this variable. Then,
	/// once we find the Variable Declaration, we check to see if the stored value is appropriate
	/// and then use all the information available to complete the translation process. This variable is then reset to nil.
	///
	/// - SeeAlso: translate(variableDeclaration:, withIndentation:)
	var danglingPatternBinding: (identifier: String, type: String, translatedExpression: String)?
	
	/**
	Translates a swift top-level statement into kotlin code.
	- Parameter topLevelCode: An AST representing a `Top Level Code Declaration` (which is a type
	of node in the swift AST).
	- Parameter indentation: A string containing the indentation level to be added to the left of the generated code.
	- Returns: A kotlin translation of the statement.
	- Precondition: The `topLevelCode` parameter must be a valid `Top Level Code Declaration` ast.
	*/
	private func translate(topLevelCode: GRYAst, withIndentation indentation: String) -> String {
		precondition(topLevelCode.name == "Top Level Code Declaration")
		
		let braceStatement = topLevelCode.subTree(named: "Brace Statement")!
		return translate(statements: braceStatement.subTrees, withIndentation: indentation)
	}
	
	// TODO: Functions with different parameter/API names
	
	/**
	Translates a swift function declaration into kotlin code.
	- Parameter functionDeclaration: An AST representing a function declaration.
	- Parameter indentation: A string containing the indentation level to be added to the left of the generated code.
	- Returns: A kotlin translation of the function declaration.
	- Precondition: The `functionDeclaration` parameter must be a valid function declaration.
	*/
	private func translate(functionDeclaration: GRYAst, withIndentation indentation: String) -> String {
		precondition(functionDeclaration.name == "Function Declaration")
		
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
	
	/**
	Translates a series of swift statements into kotlin code.
	- Parameter statements: ASTs representing swift statements.
	- Parameter indentation: A string containing the indentation level to be added to the left of the generated code.
	- Returns: A kotlin translation of the given statements.
	*/
	private func translate(statements: [GRYAst], withIndentation indentation: String) -> String {
		var result = ""
		
		var i = 0
		while i < statements.count {
			defer { i += 1 }
			
			let statement = statements[i]
			
			switch statement.name {
			case "Pattern Binding Declaration":
				if let expression = statement.subTree(named: "Call Expression") {

					let binding = statement.subTree(named: "Pattern Typed")!.subTree(named: "Pattern Named")!
					let identifier = binding.standaloneAttributes[0]
					let type = binding.keyValueAttributes["type"]!
				
					danglingPatternBinding = (identifier: identifier,
														type: type,
														translatedExpression: translate(expression: expression))
				}
			case "Variable Declaration":
				result += translate(variableDeclaration: statement, withIndentation: indentation)
			case "Return Statement":
				result += translate(returnStatement: statement, withIndentation: indentation)
			default:
				result += indentation + "<Unknown statement: \(statement.name)>\n"
			}
		}
		
		return result
	}
	
	/**
	Translates a swift return statement into kotlin code.
	- Parameter returnStatement: An AST representing a return statement.
	- Parameter indentation: A string containing the indentation level to be added to the left of the generated code.
	- Returns: A kotlin translation of the return statement.
	- Precondition: The `returnStatement` parameter must be a valid return statement.
	*/
	private func translate(returnStatement: GRYAst,
						   withIndentation indentation: String) -> String
	{
		precondition(returnStatement.name == "Return Statement")
		var result = indentation
		
		let expression = translate(expression: returnStatement.subTrees.last!)
		
		result += "return " + expression + "\n"
		
		return result
	}
	
	/**
	Translates a swift variable declaration into kotlin code.
	
	This function checks the value stored in `danglingPatternBinding`. If a value is present and it's
	consistent with this variable declaration (same identifier and type), we use the expression
	inside it as the initial value for the variable (and the `danglingPatternBinding` is reset to
	`nil`). Otherwise, the variable is declared without an initial value.
	
	- Parameter variableDeclaration: An AST representing a variable declaration.
	- Parameter indentation: A string containing the indentation level to be added to the left of the generated code.
	- Returns: A kotlin translation of the variable declaration.
	- Precondition: The `variableDeclaration` parameter must be a valid variable declaration.
	*/
	private func translate(variableDeclaration: GRYAst,
						   withIndentation indentation: String) -> String
	{
		precondition(variableDeclaration.name == "Variable Declaration")
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
		
		result += varOrValKeyword + " " + identifier + ": " + type
		
		if let patternBindingExpression = danglingPatternBinding,
			patternBindingExpression.identifier == identifier,
			patternBindingExpression.type == type
		{
			result += " = " + patternBindingExpression.translatedExpression
			danglingPatternBinding = nil
		}
		
		result += "\n"
		
		return result
	}
	
	// TODO: refactor this method and document it better.
	
	/**
	Translates a swift expression into kotlin code.
	
	- Parameter expression: An AST representing a swift expression. Many types of expressions are supported.
	- Returns: A kotlin translation of the expression.
	*/
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
	/**
	Increases the indentation level. This function is used together with `decreaseIndentation(_:)`
	(instead of manually increasing and decreasing indentation throughout the code) to guarantee
	the resulting code's indentation for the translation will be consistent.
	- Parameter indentation: A string representing the current indentation (a series of `tab` characters).
	- Returns: An indentation string that's one level deeper than the given string.
	*/
	func increaseIndentation(_ indentation: String) -> String {
		return indentation + "\t"
	}
	
	/**
	Decreases the indentation level. This function is used together with `increaseIndentation(_:)`
	(instead of manually increasing and decreasing indentation throughout the code) to guarantee
	the resulting code's indentation for the translation will be consistent.
	- Parameter indentation: A string representing the current indentation (a series of `tab` characters).
	- Returns: An indentation string that's one level less than the given string.
	*/
	func decreaseIndentation(_ indentation: String) -> String {
		return String(indentation.dropLast())
	}
}
