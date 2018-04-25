public class GRYKotlinTranslator {
	
	private var shouldIgnoreNext = false
	
	// MARK: - Interface

	/**
	Translates the swift statements in the `ast` into kotlin code.
	
	The swift AST may contain either top-level statements (such as in a "main" file), declarations
	(i.e. function or class declarations), or both. Any declarations will be translated at the beggining
	of the file, and any top-level statements will be wrapped in a `main` function and added to the end
	of the file.
	
	If no top-level statements are found, the main function is ommited.
	
	This function should be given the AST of a single source file, and should provide a translation of that
	source file's contents.
	
	- Parameter ast: The AST, obtained from swift, containing a "Source File" node at the root.
	- Returns: A kotlin translation of the contents of the AST.
	*/
	public func translateAST(_ ast: GRYAst) -> String {
		// First, translate declarations that shouldn't be inside the main function
		let declarationNames = ["Function Declaration"]
		let isDeclaration = { (ast: GRYAst) -> Bool in declarationNames.contains(ast.name) }
		
		let declarations = ast.subTrees.filter(isDeclaration)
		let declarationsAST = GRYAst("Source File", declarations)
		
		var result = translateASTDeclarations(declarationsAST)
		
		// Then, translate the remaining statements (if there are any) and wrap them in the main function
		let statements = ast.subTrees.filter({!isDeclaration($0)})
		
		guard !statements.isEmpty else { return result }
		if !declarations.isEmpty {
			result += "\n"
		}
		
		result += "fun main(args: Array<String>) {\n"
		
		let indentation = increaseIndentation("")
		
		for statement in statements {
			if shouldIgnoreNext {
				shouldIgnoreNext = false
				continue
			}
			
			switch statement.name {
			case "Top Level Code Declaration":
				let string = translate(topLevelCode: statement, withIndentation: indentation)
				result += string
			case "Variable Declaration":
				let string = translate(variableDeclaration: statement, withIndentation: indentation)
				result += string
			default:
				result += "<Unknown: \(statement.name)>\n\n"
			}
		}
		
		result += "}\n"
		
		return result
	}
	
	// MARK: - Implementation
	
	private func translateASTDeclarations(_ ast: GRYAst) -> String {
		var result = ""
		
		for subTree in ast.subTrees {
			if shouldIgnoreNext {
				shouldIgnoreNext = false
				continue
			}
			
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
	
	/**
	Swift variables declared with a value, such as `var x = 0`, are represented in a weird way in the AST:
	first comes a `Pattern Binding Declaration` containing the variable's name, its type, and
	its initial value; then comes the actual `Variable Declaration`, but in a different branch of the AST and
	with no information on the previously mentioned initial value.
	Since both of them have essential information, we need both at the same time to translate a variable
	declaration. However, since they are in unpredictably different branches, it's hard to find the Variable
	Declaration when we first read the Pattern Binding Declaration.
	
	The solution then is to temporarily save the Pattern Binding Declaration's information on this variable. Then,
	once we find the Variable Declaration, we check to see if the stored value is appropriate
	and then use all the information available to complete the translation process. This variable is then reset to nil.
	
	- SeeAlso: translate(variableDeclaration:, withIndentation:)
	*/
	var danglingPatternBinding: (identifier: String, type: String, translatedExpression: String)?
	
	private func translate(topLevelCode: GRYAst, withIndentation indentation: String) -> String {
		precondition(topLevelCode.name == "Top Level Code Declaration")
		
		let braceStatement = topLevelCode.subTree(named: "Brace Statement")!
		return translate(statements: braceStatement.subTrees, withIndentation: indentation)
	}
	
	private func translate(functionDeclaration: GRYAst, withIndentation indentation: String) -> String {
		precondition(functionDeclaration.name == "Function Declaration")
		
		let functionName = functionDeclaration.standaloneAttributes[0]
		
		guard !functionName.hasPrefix("GRYKotlinLiteral(") &&
			!functionName.hasPrefix("GRYKotlinIgnoreNext(") else { return "" }
		
		guard functionDeclaration.standaloneAttributes.count <= 1 else {
			return "// <Generic function declaration: \(functionName)>"
		}
		
		var indentation = indentation
		var result = ""
		
		result += indentation
		
		if let access = functionDeclaration["access"] {
			result += access + " "
		}
		
		result += "fun "
		
		let functionNamePrefix = functionName.prefix { $0 != "(" }
		
		result += functionNamePrefix + "("
		
		var parameterStrings = [String]()
		if let parameterList = functionDeclaration.subTree(named: "Parameter List") {
			for parameter in parameterList.subTrees {
				let name = parameter.standaloneAttributes[0]
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
	
	private func translate(statements: [GRYAst], withIndentation indentation: String) -> String {
		var result = ""
		
		for statement in statements {
			
			switch statement.name {
			case "Pattern Binding Declaration":
				if statement.subTrees.count > 1,
					statement.subTrees[1].name.hasSuffix("Expression")
				{
					let expression = statement.subTrees[1]

					let binding: GRYAst
					if let unwrappedBinding = statement.subTree(named: "Pattern Typed")?.subTree(named: "Pattern Named") {
						binding = unwrappedBinding
					}
					else {
						binding = statement.subTree(named: "Pattern Named")!
					}
					
					
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
			case "Call Expression":
				result += indentation + translate(callExpression: statement) + "\n"
			default:
				result += indentation + "<Unknown statement: \(statement.name)>\n"
			}
		}
		
		return result
	}
	
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
	
	private func translate(expression: GRYAst) -> String {
		switch expression.name {
		case "Binary Expression":
			return translate(binaryExpression: expression)
		case "Call Expression":
			return translate(callExpression: expression)
		case "Declaration Reference Expression":
			return translate(declarationReferenceExpression: expression)
		case "String Literal Expression":
			return translate(stringLiteralExpression: expression)
		case "Interpolated String Literal Expression":
			return translate(interpolatedStringLiteralExpression: expression)
		case "Erasure Expression":
			return translate(expression: expression.subTrees[0])
		case "Parentheses Expression":
			return "(" + translate(expression: expression.subTrees[0]) + ")"
		case "Load Expression":
			return translate(expression: expression.subTree(named: "Declaration Reference Expression")!)
		default:
			return "<Unknown expression: \(expression.name)>"
		}
	}
	
	private func translate(binaryExpression: GRYAst) -> String {
		precondition(binaryExpression.name == "Binary Expression")
		
		let dotCallExpression = binaryExpression.subTree(named: "Dot Syntax Call Expression")!
		let declarationReferenceExpression = dotCallExpression.subTree(named: "Declaration Reference Expression")!
		let operatorIdentifier = getIdentifierFromDeclaration(declarationReferenceExpression["decl"]!)
		
		let tupleExpression = binaryExpression.subTree(named: "Tuple Expression")!
		let leftHandSide = translate(expression: tupleExpression.subTrees[0])
		let rightHandSide = translate(expression: tupleExpression.subTrees[1])
		
		return "\(leftHandSide) \(operatorIdentifier) \(rightHandSide)"
	}
	
	/**
	Translates a swift call expression into kotlin code.
	
	A call expression is a function call, but it can be explicit (as usual) or implicit (i.e. integer literals).
	Currently, the only implicit calls supported are integer literals.
	
	As a special case, a call to the `print` function gets renamed to `println` for compatibility with kotlin.
	In the future, this will be done by a more complex system, but for now it allows integration tests to exist.
	*/
	private func translate(callExpression: GRYAst) -> String {
		precondition(callExpression.name == "Call Expression")
		
		// If the call expression corresponds to an integer literal
		if let argumentLabels = callExpression["arg_labels"],
			argumentLabels == "_builtinIntegerLiteral:",
			let tupleExpression = callExpression.subTree(named: "Tuple Expression"),
			let integerLiteralExpression = tupleExpression.subTree(named: "Integer Literal Expression"),
			let value = integerLiteralExpression["value"]
		{
			return value
		}
		// If the call expression corresponds to an explicit function call
		else {
			let functionName: String
			if let declarationReferenceExpression = callExpression.subTree(named: "Declaration Reference Expression") {
				functionName = translate(declarationReferenceExpression: declarationReferenceExpression)
			}
			else {
				functionName = getIdentifierFromDeclaration(callExpression["decl"]!)
			}
			let rawFunctionNamePrefix = functionName.prefix(while: { $0 != "(" })
			
			guard rawFunctionNamePrefix != "GRYKotlinLiteral" else {
				let parameterExpression: GRYAst
				let terminatorString: String

				// Version with both the swift value and the kotlin literal
				if let unwrappedExpression = callExpression.subTree(named: "Tuple Expression") {
					parameterExpression = unwrappedExpression
					terminatorString = ""
				}
				// Version with just the kotlin literal
				else if let unwrappedExpression = callExpression.subTree(named: "Parentheses Expression") {
					parameterExpression = unwrappedExpression
					terminatorString = "\n"
				}
				else {
					fatalError("Unknown kotlin literal function called.")
				}
				
				let stringExpression = parameterExpression.subTrees.last!
				let string = translate(stringLiteralExpression: stringExpression)
				let unquotedString = String(string.dropLast().dropFirst())
				let unescapedString = removeBackslashEscapes(unquotedString)
				return unescapedString + terminatorString
			}
			
			guard rawFunctionNamePrefix != "GRYKotlinIgnoreNext" else {
				shouldIgnoreNext = true
				return ""
			}
			
			let functionNamePrefix = (rawFunctionNamePrefix == "print") ?
				"println" : String(rawFunctionNamePrefix)
			
			let parameters: String
			if let parenthesesExpression = callExpression.subTree(named: "Parentheses Expression") {
				parameters = translate(expression: parenthesesExpression)
			}
			else if let tupleExpression = callExpression.subTree(named: "Tuple Expression") {
				parameters = translate(tupleExpression: tupleExpression)
			}
			else if let tupleShuffleExpression = callExpression.subTree(named: "Tuple Shuffle Expression") {
				if let tupleExpression = tupleShuffleExpression.subTree(named: "Tuple Expression") {
					parameters = translate(tupleExpression: tupleExpression)
				}
				else {
					let parenthesesExpression = tupleShuffleExpression.subTree(named: "Parentheses Expression")!
					parameters = translate(expression: parenthesesExpression)
				}
			}
			else {
				return " <Unknown expression for parameters>"
			}
			
			return "\(functionNamePrefix)\(parameters)"
		}
	}
	
	private func translate(declarationReferenceExpression: GRYAst) -> String {
		precondition(declarationReferenceExpression.name == "Declaration Reference Expression")
		let declaration = declarationReferenceExpression["decl"]!
		return getIdentifierFromDeclaration(declaration)
	}
	
	/**
	Recovers an identifier formatted as a swift AST declaration.
	
	Declaration references are represented in the swift AST Dump in a rather complex format, so a few operations are used to
	extract only the relevant identifier.
	
	For instance: a declaration reference expression referring to the variable `x`, inside the `foo` function,
	in the /Users/Me/Documents/myFile.swift file, will be something like
	`myFile.(file).foo().x@/Users/Me/Documents/MyFile.swift:2:6`, but a declaration reference for the print function
	doesn't have the '@' or anything after it.
	
	Note that this function's job (in the example above) is to extract only the actual `x` identifier.
	*/
	private func getIdentifierFromDeclaration(_ declaration: String) -> String {
		var declaration = declaration
		
		// Attempt to discard useless info after the '@'
		// (both the '@' and the info after it may not be there)
		declaration =~ "^([^@\\s]*?)@.*" => "$1"
		
		// Separate the remaining components
		let components = declaration.split(separator: ".")
		
		// Extract only the identifier
		let identifier = components.last!
		
		return String(identifier)
	}
	
	private func translate(tupleExpression: GRYAst) -> String {
		precondition(tupleExpression.name == "Tuple Expression")
		
		// Only empty tuples don't have a list of names
		guard let names = tupleExpression["names"] else {
			return "()"
		}
		
		let namesArray = names.split(separator: ",")
		
		var result = [String]()
		
		for (name, expression) in zip(namesArray, tupleExpression.subTrees) {
			let expressionString = translate(expression: expression)
			
			// Empty names (like the underscore in "foo(_:)") are represented by ''
			if name == "''" {
				result.append("\(expressionString)")
			}
			else {
				result.append("\(name) = \(expressionString)")
			}
		}
		
		return "(" + result.joined(separator: ", ") + ")"
	}

	private func translate(stringLiteralExpression: GRYAst) -> String {
		let value = stringLiteralExpression["value"]!
		return "\"\(value)\""
	}
	
	private func translate(interpolatedStringLiteralExpression: GRYAst) -> String {
		precondition(interpolatedStringLiteralExpression.name == "Interpolated String Literal Expression")
		
		var result = "\""
		
		for expression in interpolatedStringLiteralExpression.subTrees {
			if expression.name == "String Literal Expression" {
				let quotedString = translate(stringLiteralExpression: expression)
				let unquotedString = quotedString.dropLast().dropFirst()
				result += unquotedString
			}
			else {
				let expressionString = translate(expression: expression)
				result += "${\(expressionString)}"
			}
		}
		
		result += "\""
		return result
	}
	
	func removeBackslashEscapes(_ string: String) -> String {
		var result = ""
		
		var isEscaping = false
		loop: for character in string {
			switch character {
			case "\\":
				if isEscaping {
					result.append(character)
					isEscaping = false
				}
				else {
					isEscaping = true
				}
			default:
				result.append(character)
				isEscaping = false
			}
		}
		
		return result
	}
	
	func increaseIndentation(_ indentation: String) -> String {
		return indentation + "\t"
	}
	
	func decreaseIndentation(_ indentation: String) -> String {
		return String(indentation.dropLast())
	}
}
