/*
* Copyright 2018 Vinícius Jorge Vendramini
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

public class GRYSwift4Translator {
	// MARK: - Properties
	var danglingPatternBinding: (identifier: String, type: String, expression: GRYExpression?)?

	var errors = [String]()

	// MARK: - Interface
	public init() { }

	public func translateAST(_ ast: GRYSwiftAST) throws -> GRYAST {
		// First, translate declarations that shouldn't be inside the main function
		let declarationNames = [
			"Protocol",
			"Class Declaration",
			"Extension Declaration",
			"Function Declaration",
			"Enum Declaration",
		]
		let isDeclaration = { (ast: GRYSwiftAST) -> Bool in declarationNames.contains(ast.name) }

		let swiftDeclarations = ast.subtrees.filter(isDeclaration)
		let declarations = try translate(subtrees: swiftDeclarations.array)

		// Then, translate the remaining statements (if there are any) and wrap them in the main
		// function
		let swiftStatements = ast.subtrees.filter({ !isDeclaration($0) })
		let statements = try translate(subtrees: swiftStatements.array)

		return GRYAST(declarations: declarations, statements: statements)
	}

	// MARK: - Top-level translations
	internal func translate(subtrees: [GRYSwiftAST]) throws -> [GRYTopLevelNode] {
		return try subtrees.reduce([], { (result, subtree) -> [GRYTopLevelNode] in
			try result + translate(subtree: subtree).compactMap { $0 }
		})
	}

	internal func translate(subtree: GRYSwiftAST) throws -> [GRYTopLevelNode?] {
		var result: GRYTopLevelNode?

		switch subtree.name {
		case "Top Level Code Declaration":
			result = try translate(topLevelCode: subtree)
		case "Import Declaration":
			result = .importDeclaration(name: subtree.standaloneAttributes[0])
		case "Class Declaration":
			result = try translate(classDeclaration: subtree)
		case "Enum Declaration":
			result = try translate(enumDeclaration: subtree)
		case "Extension Declaration":
			result = try translate(extensionDeclaration: subtree)
		case "For Each Statement":
			result = try translate(forEachStatement: subtree)
		case "Function Declaration", "Constructor Declaration":
			result = try translate(functionDeclaration: subtree)
		case "Protocol":
			result = try translate(protocolDeclaration: subtree)
		case "Throw Statement":
			result = try translate(throwStatement: subtree)
		case "Variable Declaration":
			result = try translate(variableDeclaration: subtree)
		case "Assign Expression":
			result = try translate(assignExpression: subtree)
		case "If Statement", "Guard Statement":
			result = try translate(ifStatement: subtree)
		case "Pattern Binding Declaration":
			try process(patternBindingDeclaration: subtree)
			return []
		case "Return Statement":
			result = try translate(returnStatement: subtree)
		default:
			if subtree.name.hasSuffix("Expression") {
				let expression = try translate(expression: subtree)
				result = .expression(expression: expression)
			}
			else {
				result = nil
			}
		}

		return [result]
	}

	internal func translate(expression: GRYSwiftAST) throws -> GRYExpression {

		switch expression.name {
		case "Array Expression":
			return try translate(arrayExpression: expression)
		case "Binary Expression":
			return try translate(binaryExpression: expression)
		case "Call Expression":
			return try translate(callExpression: expression)
		case "Closure Expression":
			return try translate(closureExpression: expression)
		case "Declaration Reference Expression":
			return try translate(declarationReferenceExpression: expression)
		case "Dot Syntax Call Expression":
			return try translate(dotSyntaxCallExpression: expression)
		case "String Literal Expression":
			return try translate(stringLiteralExpression: expression)
		case "Interpolated String Literal Expression":
			return try translate(interpolatedStringLiteralExpression: expression)
		case "Erasure Expression":
			if let lastExpression = expression.subtrees.last {
				return try translate(expression: lastExpression)
			}
			else {
				throw unexpectedASTStructureError(
					"Unrecognized structure in automatic expression",
					AST: expression)
			}
		case "Prefix Unary Expression":
			return try translate(prefixUnaryExpression: expression)
		case "Postfix Unary Expression":
			return try translate(postfixUnaryExpression: expression)
		case "Type Expression":
			return try translate(typeExpression: expression)
		case "Member Reference Expression":
			return try translate(memberReferenceExpression: expression)
		case "Subscript Expression":
			return try translate(subscriptExpression: expression)
		case "Open Existential Expression":
			let processedExpression = try process(openExistentialExpression: expression)
			return try translate(expression: processedExpression)
		case "Parentheses Expression":
			if let innerExpression = expression.subtree(at: 0) {
				// Swift 5: Compiler-created parentheses expressions may be marked with "implicit"
				if expression.standaloneAttributes.contains("implicit") {
					return try translate(expression: innerExpression)
				}
				else {
					return .parenthesesExpression(
						expression: try translate(expression: innerExpression))
				}
			}
			else {
				throw unexpectedASTStructureError(
					"Expected parentheses expression to have at least one subtree",
					AST: expression)
			}
		case "Force Value Expression":
			if let firstExpression = expression.subtree(at: 0) {
				let expression = try translate(expression: firstExpression)
				return .forceValueExpression(expression: expression)
			}
			else {
				throw unexpectedASTStructureError(
					"Expected force value expression to have at least one subtree",
					AST: expression)
			}
		case "Bind Optional Expression":
			if let firstExpression = expression.subtree(at: 0) {
				let expression = try translate(expression: firstExpression)
				return .optionalExpression(expression: expression)
			}
			else {
				throw unexpectedASTStructureError(
					"Expected optional expression to have at least one subtree",
					AST: expression)
			}
		case "Autoclosure Expression",
			 "Inject Into Optional",
			 "Optional Evaluation Expression",
			 "Inout Expression",
			 "Load Expression",
			 "Function Conversion Expression",
			 "Try Expression":
			if let lastExpression = expression.subtrees.last {
				return try translate(expression: lastExpression)
			}
			else {
				throw unexpectedASTStructureError(
					"Unrecognized structure in automatic expression",
					AST: expression)
			}
		case "Collection Upcast Expression":
			if let firstExpression = expression.subtrees.first {
				return try translate(expression: firstExpression)
			}
			else {
				throw unexpectedASTStructureError(
					"Unrecognized structure in automatic expression",
					AST: expression)
			}
		default:
			throw unexpectedASTStructureError("Unknown expression", AST: expression)
		}
	}

	// MARK: - Leaf translations
	internal func translate(protocolDeclaration: GRYSwiftAST) throws -> GRYTopLevelNode {
		try ensure(AST: protocolDeclaration, isNamed: "Protocol")

		guard let protocolName = protocolDeclaration.standaloneAttributes.first else {
			throw unexpectedASTStructureError(
				"Unrecognized structure",
				AST: protocolDeclaration)
		}

		let members = try translate(subtrees: protocolDeclaration.subtrees.array)

		return .protocolDeclaration(name: protocolName, members: members)
	}

	internal func translate(assignExpression: GRYSwiftAST) throws -> GRYTopLevelNode {
		try ensure(AST: assignExpression, isNamed: "Assign Expression")

		if let leftExpression = assignExpression.subtree(at: 0),
			let rightExpression = assignExpression.subtree(at: 1)
		{
			let leftTranslation = try translate(expression: leftExpression)
			let rightTranslation = try translate(expression: rightExpression)

			return .assignmentStatement(leftHand: leftTranslation, rightHand: rightTranslation)
		}
		else {
			throw unexpectedASTStructureError(
				"Unrecognized structure",
				AST: assignExpression)
		}
	}

	internal func translate(classDeclaration: GRYSwiftAST) throws -> GRYTopLevelNode {
		try ensure(AST: classDeclaration, isNamed: "Class Declaration")

		// Get the class name
		let name = classDeclaration.standaloneAttributes.first!

		// Check for inheritance
		let inheritanceArray: [String]
		if let inheritanceList = classDeclaration["inherits"] {
			inheritanceArray = inheritanceList.split(withStringSeparator: ", ")
		}
		else {
			inheritanceArray = []
		}

		guard !inheritanceArray.contains("GRYIgnore") else {
			return .classDeclaration(name: name, inherits: inheritanceArray, members: [])
		}

		// Translate the contents
		let classContents = try translate(subtrees: classDeclaration.subtrees.array)

		return .classDeclaration(name: name, inherits: inheritanceArray, members: classContents)
	}

	internal func translate(throwStatement: GRYSwiftAST) throws -> GRYTopLevelNode {
		try ensure(AST: throwStatement, isNamed: "Throw Statement")

		if let expression = throwStatement.subtrees.last {
			let expressionTranslation = try translate(expression: expression)
			return .throwStatement(expression: expressionTranslation)
		}
		else {
			throw unexpectedASTStructureError(
				"Unrecognized structure",
				AST: throwStatement)
		}
	}

	internal func translate(extensionDeclaration: GRYSwiftAST) throws -> GRYTopLevelNode {
		let type = cleanUpType(extensionDeclaration.standaloneAttributes[0])
		let members = try translate(subtrees: extensionDeclaration.subtrees.array)
		return .extensionDeclaration(type: type, members: members)
	}

	internal func translate(enumDeclaration: GRYSwiftAST) throws -> GRYTopLevelNode {
		try ensure(AST: enumDeclaration, isNamed: "Enum Declaration")

		let access = enumDeclaration["access"]

		let name = enumDeclaration.standaloneAttributes.first!

		let inheritanceArray: [String]
		if let inheritanceList = enumDeclaration["inherits"] {
			inheritanceArray = inheritanceList.split(withStringSeparator: ", ")
		}
		else {
			inheritanceArray = []
		}

		guard !inheritanceArray.contains("GRYIgnore") else {
			return .enumDeclaration(
				access: access,
				name: name,
				inherits: inheritanceArray,
				elements: [])
		}

		var elements = [String]()
		let enumElementDeclarations =
			enumDeclaration.subtrees.filter { $0.name == "Enum Element Declaration" }
		for enumElementDeclaration in enumElementDeclarations {
			guard let elementName = enumElementDeclaration.standaloneAttributes.first else {
				throw unexpectedASTStructureError(
					"Unrecognized enum element",
					AST: enumDeclaration)
			}

			elements.append(elementName)
		}

		return .enumDeclaration(
			access: access,
			name: name,
			inherits: inheritanceArray,
			elements: elements)
	}

	internal func translate(memberReferenceExpression: GRYSwiftAST) throws -> GRYExpression {
		try ensure(AST: memberReferenceExpression, isNamed: "Member Reference Expression")

		if let declaration = memberReferenceExpression["decl"],
			let memberOwner = memberReferenceExpression.subtree(at: 0),
			let rawType = memberReferenceExpression["type"]
		{
			let type = cleanUpType(rawType)
			let leftHand = try translate(expression: memberOwner)
			let (member, isStandardLibrary) = getIdentifierFromDeclaration(declaration)
			let isImplicit = memberReferenceExpression.standaloneAttributes.contains("implicit")
			let rightHand = GRYExpression.declarationReferenceExpression(
				identifier: member, type: type, isStandardLibrary: isStandardLibrary,
				isImplicit: isImplicit)
			return .dotExpression(leftExpression: leftHand,
								  rightExpression: rightHand)
		}
		else {
			throw unexpectedASTStructureError(
				"Unrecognized structure",
				AST: memberReferenceExpression)
		}
	}

	internal func translate(prefixUnaryExpression: GRYSwiftAST) throws -> GRYExpression {
		try ensure(AST: prefixUnaryExpression, isNamed: "Prefix Unary Expression")

		if let rawType = prefixUnaryExpression["type"],
			let declaration = prefixUnaryExpression
			.subtree(named: "Dot Syntax Call Expression")?
			.subtree(named: "Declaration Reference Expression")?["decl"],
			let expression = prefixUnaryExpression.subtree(at: 1)
		{
			let type = cleanUpType(rawType)
			let expressionTranslation = try translate(expression: expression)
			let (operatorIdentifier, _) = getIdentifierFromDeclaration(declaration)

			return .prefixUnaryExpression(
				expression: expressionTranslation, operatorSymbol: operatorIdentifier, type: type)
		}
		else {
			throw unexpectedASTStructureError(
				"Expected Prefix Unary Expression to have a Dot Syntax Call Expression with a " +
				"Declaration Reference Expression, for the operator, and expected it to have " +
				"a second expression as the operand.",
				AST: prefixUnaryExpression)
		}
	}

	internal func translate(postfixUnaryExpression: GRYSwiftAST) throws -> GRYExpression {
		try ensure(AST: postfixUnaryExpression, isNamed: "Postfix Unary Expression")

		if let rawType = postfixUnaryExpression["type"],
			let declaration = postfixUnaryExpression
				.subtree(named: "Dot Syntax Call Expression")?
				.subtree(named: "Declaration Reference Expression")?["decl"],
			let expression = postfixUnaryExpression.subtree(at: 1)
		{
			let type = cleanUpType(rawType)
			let expressionTranslation = try translate(expression: expression)
			let (operatorIdentifier, _) = getIdentifierFromDeclaration(declaration)

			return .postfixUnaryExpression(
				expression: expressionTranslation, operatorSymbol: operatorIdentifier, type: type)
		}
		else {
			throw unexpectedASTStructureError(
				"Expected Postfix Unary Expression to have a Dot Syntax Call Expression with a " +
				"Declaration Reference Expression, for the operator, and expected it to have " +
				"a second expression as the operand.",
				AST: postfixUnaryExpression)
		}
	}

	internal func translate(binaryExpression: GRYSwiftAST) throws -> GRYExpression {
		try ensure(AST: binaryExpression, isNamed: "Binary Expression")

		let operatorIdentifier: String

		if let rawType = binaryExpression["type"],
			let declaration = binaryExpression
			.subtree(named: "Dot Syntax Call Expression")?
			.subtree(named: "Declaration Reference Expression")?["decl"],
			let tupleExpression = binaryExpression.subtree(named: "Tuple Expression"),
			let leftHandExpression = tupleExpression.subtree(at: 0),
			let rightHandExpression = tupleExpression.subtree(at: 1)
		{
			let type = cleanUpType(rawType)
			(operatorIdentifier, _) = getIdentifierFromDeclaration(declaration)
			let leftHandTranslation = try translate(expression: leftHandExpression)
			let rightHandTranslation = try translate(expression: rightHandExpression)

			return .binaryOperatorExpression(
				leftExpression: leftHandTranslation,
				rightExpression: rightHandTranslation,
				operatorSymbol: operatorIdentifier,
				type: type)
		}
		else {
			throw unexpectedASTStructureError(
				"Unrecognized structure",
				AST: binaryExpression)
		}
	}

	internal func translate(typeExpression: GRYSwiftAST) throws -> GRYExpression {
		try ensure(AST: typeExpression, isNamed: "Type Expression")

		guard let type = typeExpression["typerepr"] else {
			throw unexpectedASTStructureError(
				"Unrecognized structure",
				AST: typeExpression)
		}

		return .typeExpression(type: cleanUpType(type))
	}

	internal func translate(dotSyntaxCallExpression: GRYSwiftAST) throws -> GRYExpression {
		try ensure(AST: dotSyntaxCallExpression, isNamed: "Dot Syntax Call Expression")

		if let leftHandTree = dotSyntaxCallExpression.subtree(at: 1),
			let rightHandExpression = dotSyntaxCallExpression.subtree(at: 0)
		{
			let rightHand = try translate(expression: rightHandExpression)
			let leftHand = try translate(typeExpression: leftHandTree)

			// Swift 4.2
			if case .typeExpression(type: _) = leftHand,
				case let .declarationReferenceExpression(
					identifier: identifier, type: _, isStandardLibrary: _,
					isImplicit: _) = rightHand,
				identifier == "none"
			{
				return .nilLiteralExpression
			}

			return .dotExpression(leftExpression: leftHand, rightExpression: rightHand)
		}
		else {
			throw unexpectedASTStructureError(
				"Unrecognized structure",
				AST: dotSyntaxCallExpression)
		}
	}

	internal func translate(returnStatement: GRYSwiftAST) throws -> GRYTopLevelNode {
		try ensure(AST: returnStatement, isNamed: "Return Statement")

		if let expression = returnStatement.subtrees.last {
			let expression = try translate(expression: expression)
			return .returnStatement(expression: expression)
		}
		else {
			return .returnStatement(expression: nil)
		}
	}

	internal func translate(forEachStatement: GRYSwiftAST) throws -> GRYTopLevelNode {
		try ensure(AST: forEachStatement, isNamed: "For Each Statement")

		guard let variableSubtree = forEachStatement.subtree(named: "Pattern Named"),
			let variableName = variableSubtree.standaloneAttributes.first,
			let rawType = variableSubtree["type"],
			let collectionExpression = forEachStatement.subtree(at: 2) else
		{
			throw unexpectedASTStructureError(
				"Unable to detect variable or collection",
				AST: forEachStatement)
		}

		let variableType = cleanUpType(rawType)

		guard let braceStatement = forEachStatement.subtrees.last,
			braceStatement.name == "Brace Statement" else
		{
			throw unexpectedASTStructureError(
				"Unable to detect body of statements",
				AST: forEachStatement)
		}

		let variable = GRYExpression.declarationReferenceExpression(
			identifier: variableName, type: variableType, isStandardLibrary: false,
			isImplicit: false)
		let collectionTranslation = try translate(expression: collectionExpression)
		let statements = try translate(subtrees: braceStatement.subtrees.array)

		return .forEachStatement(
			collection: collectionTranslation,
			variable: variable,
			statements: statements)
	}

	internal func translate(ifStatement: GRYSwiftAST) throws -> GRYTopLevelNode {
		guard ifStatement.name == "If Statement" || ifStatement.name == "Guard Statement" else {
			throw unexpectedASTStructureError(
				"Trying to translate \(ifStatement.name) as an if or guard statement",
				AST: ifStatement)
		}

		let isGuard = (ifStatement.name == "Guard Statement")

		let (letDeclarations, conditions) = try translateDeclarationsAndConditions(
			forIfStatement: ifStatement)

		let braceStatement: GRYSwiftAST
		let elseIfStatement: GRYTopLevelNode?
		let elseStatement: GRYTopLevelNode?

		if ifStatement.subtrees.count > 2,
			let unwrappedBraceStatement = ifStatement.subtrees.secondToLast,
			unwrappedBraceStatement.name == "Brace Statement",
			let elseIfAST = ifStatement.subtrees.last,
			elseIfAST.name == "If Statement"
		{
			braceStatement = unwrappedBraceStatement
			elseIfStatement = try translate(ifStatement: elseIfAST)
			elseStatement = nil
		}
		else if ifStatement.subtrees.count > 2,
			let unwrappedBraceStatement = ifStatement.subtrees.secondToLast,
			unwrappedBraceStatement.name == "Brace Statement",
			let elseAST = ifStatement.subtrees.last,
			elseAST.name == "Brace Statement"
		{
			braceStatement = unwrappedBraceStatement
			elseIfStatement = nil

			let statements = try translate(subtrees: elseAST.subtrees.array)
			elseStatement = .ifStatement(
				conditions: [], declarations: [],
				statements: statements,
				elseStatement: nil,
				isGuard: false)
		}
		else if let unwrappedBraceStatement = ifStatement.subtrees.last,
			unwrappedBraceStatement.name == "Brace Statement"
		{
			braceStatement = unwrappedBraceStatement
			elseIfStatement = nil
			elseStatement = nil
		}
		else {
			throw unexpectedASTStructureError(
				"Unable to detect body of statements",
				AST: ifStatement)
		}

		let statements = braceStatement.subtrees
		let statementsResult = try translate(subtrees: statements.array)

		return .ifStatement(
			conditions: conditions,
			declarations: letDeclarations,
			statements: statementsResult,
			elseStatement: elseIfStatement ?? elseStatement,
			isGuard: isGuard)
	}

	internal func translateDeclarationsAndConditions(
		forIfStatement ifStatement: GRYSwiftAST) throws
		-> (declarations: [GRYTopLevelNode], conditions: [GRYExpression])
	{
		guard ifStatement.name == "If Statement" || ifStatement.name == "Guard Statement" else {
			throw unexpectedASTStructureError(
				"Trying to translate \(ifStatement.name) as an if or guard statement",
				AST: ifStatement)
		}

		var conditionsResult = [GRYExpression]()
		var declarationsResult = [GRYTopLevelNode]()

		let conditions = ifStatement.subtrees.filter {
			$0.name != "If Statement" && $0.name != "Brace Statement"
		}

		for condition in conditions {
			// If it's an if-let
			if condition.name == "Pattern",
				let optionalSomeElement =
					condition.subtree(named: "Optional Some Element") ?? // Swift 4.1
					condition.subtree(named: "Pattern Optional Some") // Swift 4.2
			{
				let patternNamed: GRYSwiftAST
				let isLet: Bool
				if let patternLet = optionalSomeElement.subtree(named: "Pattern Let"),
					let unwrapped = patternLet.subtree(named: "Pattern Named")
				{
					patternNamed = unwrapped
					isLet = true
				}
				else if let unwrapped = optionalSomeElement
					.subtree(named: "Pattern Variable")?
					.subtree(named: "Pattern Named")
				{
					patternNamed = unwrapped
					isLet = false
				}
				else {
					throw unexpectedASTStructureError(
						"Unable to detect pattern in let declaration",
						AST: ifStatement)
				}

				guard let rawType = optionalSomeElement["type"] else {
					throw unexpectedASTStructureError(
						"Unable to detect type in let declaration",
						AST: ifStatement)
				}

				let type = cleanUpType(rawType)

				guard let name = patternNamed.standaloneAttributes.first,
					let lastCondition = condition.subtrees.last else
				{
					throw unexpectedASTStructureError(
						"Unable to get expression in let declaration",
						AST: ifStatement)
				}

				let expression = try translate(expression: lastCondition)

				declarationsResult.append(.variableDeclaration(
					identifier: name,
					typeName: type,
					expression: expression,
					getter: nil, setter: nil,
					isLet: isLet,
					extendsType: nil,
					annotations: nil))
			}
			else {
				conditionsResult.append(try translate(expression: condition))
			}
		}

		return (declarations: declarationsResult, conditions: conditionsResult)
	}

	internal func translate(functionDeclaration: GRYSwiftAST) throws -> GRYTopLevelNode? {
		try ensure(
			AST: functionDeclaration, isNamed: ["Function Declaration", "Constructor Declaration"])

		// Getters and setters will appear again in the Variable Declaration AST and get translated
		let isGetterOrSetter =
			(functionDeclaration["getter_for"] != nil) || (functionDeclaration["setter_for"] != nil)
		let isImplicit = functionDeclaration.standaloneAttributes.contains("implicit")
		guard !isImplicit && !isGetterOrSetter else {
			return nil
		}

		let functionName = functionDeclaration.standaloneAttributes.first ?? ""

		let access = functionDeclaration["access"]

		// Find out if it's static
		guard let interfaceTypeComponents = functionDeclaration["interface type"]?
				.split(withStringSeparator: " -> "),
			let firstInterfaceTypeComponent = interfaceTypeComponents.first else
		{
			throw unexpectedASTStructureError(
				"Unable to find out if function is static", AST: functionDeclaration)
		}
		let isStatic = firstInterfaceTypeComponent.contains(".Type")

		let functionNamePrefix = functionName.prefix { $0 != "(" }

		// Get the function parameters.
		let parameterList: GRYSwiftAST?

		// If it's a method, it includes an extra Parameter List with only `self`
		if let list = functionDeclaration.subtree(named: "Parameter List"),
			let name = list.subtree(at: 0, named: "Parameter")?.standaloneAttributes.first,
			name != "self"
		{
			parameterList = list
		}
		else if let unwrapped = functionDeclaration.subtree(at: 1, named: "Parameter List") {
			parameterList = unwrapped
		}
		else {
			parameterList = nil
		}

		var parameterNames = [String]()
		var parameterTypes = [String]()
		var defaultValues = [GRYExpression?]()

		// Translate the parameters
		if let parameterList = parameterList {
			for parameter in parameterList.subtrees {
				if let name = parameter.standaloneAttributes.first,
					let type = parameter["interface type"]
				{
					guard name != "self" else {
						continue
					}

					parameterNames.append(name)
					parameterTypes.append(cleanUpType(type))

					if let defaultValueTree = parameter.subtrees.first {
						try defaultValues.append(translate(expression: defaultValueTree))
					}
					else {
						defaultValues.append(nil)
					}
				}
				else {
					throw unexpectedASTStructureError(
						"Unable to detect name or attribute for a parameter",
						AST: functionDeclaration)
				}
			}
		}

		// Translate the return type
		// FIXME: Doesn't allow to return function types
		guard let returnType = interfaceTypeComponents.last else
		{
			throw unexpectedASTStructureError(
				"Unable to get return type", AST: functionDeclaration)
		}

		// Translate the function body
		let statements: [GRYTopLevelNode]
		if let braceStatement = functionDeclaration.subtree(named: "Brace Statement") {
			statements = try translate(subtrees: braceStatement.subtrees.array)
		}
		else {
			statements = []
		}

		return .functionDeclaration(
			prefix: String(functionNamePrefix),
			parameterNames: parameterNames,
			parameterTypes: parameterTypes,
			defaultValues: defaultValues,
			returnType: returnType,
			isImplicit: isImplicit,
			isStatic: isStatic,
			extendsType: nil,
			statements: statements,
			access: access)
	}

	internal func translate(topLevelCode topLevelCodeDeclaration: GRYSwiftAST) throws
		-> GRYTopLevelNode?
	{
		try ensure(AST: topLevelCodeDeclaration, isNamed: "Top Level Code Declaration")

		guard let braceStatement = topLevelCodeDeclaration.subtree(named: "Brace Statement") else {
			throw unexpectedASTStructureError(
				"Unrecognized structure", AST: topLevelCodeDeclaration)
		}

		let subtrees = try translate(subtrees: braceStatement.subtrees.array)

		return subtrees.first
	}

	internal func translate(variableDeclaration: GRYSwiftAST) throws -> GRYTopLevelNode {
		try ensure(AST: variableDeclaration, isNamed: "Variable Declaration")

		if let identifier = variableDeclaration.standaloneAttributes.first,
			let rawType = variableDeclaration["interface type"]
		{
			let isLet = variableDeclaration.standaloneAttributes.contains("let")
			let type = cleanUpType(rawType)

			let expression: GRYExpression?
			if let patternBindingExpression = danglingPatternBinding,
				patternBindingExpression.identifier == identifier,
				patternBindingExpression.type == type
			{
				expression = patternBindingExpression.expression
				danglingPatternBinding = nil
			}
			else {
				expression = nil
			}

			var getter: GRYTopLevelNode?
			var setter: GRYTopLevelNode?
			for subtree in variableDeclaration.subtrees
				where !subtree.standaloneAttributes.contains("implicit")
			{
				let access = subtree["access"]

				let statements: [GRYSwiftAST] =
					subtree.subtree(named: "Brace Statement")?.subtrees.array ?? []
				let statementsTranslation = try translate(subtrees: statements)

				// Swift 5: "get_for" and "set_for" are the terms used in the Swift 5 AST
				if subtree["getter_for"] != nil || subtree["get_for"] != nil {
					getter = .functionDeclaration(
						prefix: "get",
						parameterNames: [], parameterTypes: [],
						defaultValues: [],
						returnType: type,
						isImplicit: false,
						isStatic: false,
						extendsType: nil,
						statements: statementsTranslation,
						access: access)
				}
				else if subtree["materializeForSet_for"] != nil ||
					subtree["setter_for"] != nil ||
					subtree["set_for"] != nil
				{
					setter = .functionDeclaration(
						prefix: "set",
						parameterNames: ["newValue"],
						parameterTypes: [type],
						defaultValues: [],
						returnType: "()",
						isImplicit: false,
						isStatic: false,
						extendsType: nil,
						statements: statementsTranslation,
						access: access)
				}
			}

			return .variableDeclaration(
				identifier: identifier,
				typeName: type,
				expression: expression,
				getter: getter,
				setter: setter,
				isLet: isLet,
				extendsType: nil,
				annotations: nil)
		}
		else {
			throw unexpectedASTStructureError(
				"Failed to get identifier and type", AST: variableDeclaration)
		}
	}

	internal func translate(callExpression: GRYSwiftAST) throws -> GRYExpression {
		try ensure(AST: callExpression, isNamed: "Call Expression")

		// If the call expression corresponds to an integer literal
		if let argumentLabels = callExpression["arg_labels"] {
			if argumentLabels == "_builtinIntegerLiteral:" {
				return try translate(asNumericLiteral: callExpression)
			}
			else if argumentLabels == "_builtinBooleanLiteral:" {
				return try translate(asBooleanLiteral: callExpression)
			}
			else if argumentLabels == "nilLiteral:" {
				return .nilLiteralExpression
			}
		}

		let function: GRYExpression

		// If it's an empty expression used in an "if" condition
		if callExpression.standaloneAttributes.contains("implicit"),
			callExpression["arg_labels"] == "",
			callExpression["type"] == "Int1",
			let containedExpression = callExpression
				.subtree(named: "Dot Syntax Call Expression")?
				.subtrees.last
		{
			return try translate(expression: containedExpression)
		}

		guard let rawType = callExpression["type"] else {
			throw unexpectedASTStructureError(
				"Failed to recognize type", AST: callExpression)
		}
		let type = cleanUpType(rawType)

		if let declarationReferenceExpression = callExpression
			.subtree(named: "Declaration Reference Expression")
		{
			function = try translate(
				declarationReferenceExpression: declarationReferenceExpression)
		}
		else if let dotSyntaxCallExpression = callExpression
				.subtree(named: "Dot Syntax Call Expression"),
			let methodName = dotSyntaxCallExpression
				.subtree(at: 0, named: "Declaration Reference Expression"),
			let methodOwner = dotSyntaxCallExpression.subtree(at: 1)
		{
			let methodName = try translate(declarationReferenceExpression: methodName)
			let methodOwner = try translate(expression: methodOwner)
			function = .dotExpression(leftExpression: methodOwner, rightExpression: methodName)
		}
		else if let typeExpression = callExpression
			.subtree(named: "Constructor Reference Call Expression")?
			.subtree(named: "Type Expression")
		{
			function = try translate(typeExpression: typeExpression)
		}
		else {
			throw unexpectedASTStructureError(
				"Failed to recognize function name", AST: callExpression)
		}

		let parameters = try translate(callExpressionParameters: callExpression)

		return .callExpression(function: function, parameters: parameters, type: type)
	}

	internal func translate(closureExpression: GRYSwiftAST) throws -> GRYExpression {
		try ensure(AST: closureExpression, isNamed: "Closure Expression")

		// Get the parameters.
		let parameterList: GRYSwiftAST?

		if let unwrapped = closureExpression.subtree(at: 0, named: "Parameter List") {
			parameterList = unwrapped
		}
		else {
			parameterList = nil
		}

		var parameterNames = [String]()
		var parameterTypes = [String]()

		// Translate the parameters
		if let parameterList = parameterList {
			for parameter in parameterList.subtrees {
				if let name = parameter.standaloneAttributes.first,
					let type = parameter["interface type"]
				{
					parameterNames.append(name)
					parameterTypes.append(cleanUpType(type))
				}
				else {
					throw unexpectedASTStructureError(
						"Unable to detect name or attribute for a parameter",
						AST: closureExpression)
				}
			}
		}

		// Translate the return type
		// FIXME: Doesn't allow to return function types
		guard let type = closureExpression["type"] else
		{
			throw unexpectedASTStructureError(
				"Unable to get type or return type", AST: closureExpression)
		}

		// Translate the closure body
		guard let lastSubtree = closureExpression.subtrees.last else {
			throw unexpectedASTStructureError(
				"Unable to get closure body", AST: closureExpression)
		}

		let statements: [GRYTopLevelNode]
		if lastSubtree.name == "Brace Statement" {
			statements = try translate(subtrees: lastSubtree.subtrees.array)
		}
		else {
			let expression = try translate(expression: lastSubtree)
			statements = [GRYTopLevelNode.expression(expression: expression)]
		}

		return .closureExpression(
				parameterNames: parameterNames,
				parameterTypes: parameterTypes,
				statements: statements,
				type: cleanUpType(type))
	}

	internal func translate(callExpressionParameters callExpression: GRYSwiftAST) throws
		-> GRYExpression
	{
		try ensure(AST: callExpression, isNamed: "Call Expression")

		let parameters: GRYExpression
		if let parenthesesExpression = callExpression.subtree(named: "Parentheses Expression") {
			let expression = try translate(expression: parenthesesExpression)
			parameters = .tupleExpression(
				pairs: [GRYExpression.TuplePair(name: nil, expression: expression)])
		}
		else if let tupleExpression = callExpression.subtree(named: "Tuple Expression") {
			parameters = try translate(tupleExpression: tupleExpression)
		}
		else if let tupleShuffleExpression = callExpression
			.subtree(named: "Tuple Shuffle Expression")
		{
			if let tupleExpression = tupleShuffleExpression.subtree(named: "Tuple Expression") {
				parameters = try translate(tupleExpression: tupleExpression)
			}
			else if let parenthesesExpression = tupleShuffleExpression
				.subtree(named: "Parentheses Expression")
			{
				let expression = try translate(expression: parenthesesExpression)
				parameters = .tupleExpression(
					pairs: [GRYExpression.TuplePair(name: nil, expression: expression)])
			}
			else {
				throw unexpectedASTStructureError(
					"Unrecognized structure in parameters", AST: callExpression)
			}
		}
		else {
			throw unexpectedASTStructureError(
				"Unrecognized structure in parameters", AST: callExpression)
		}

		return parameters
	}

	internal func translate(tupleExpression: GRYSwiftAST) throws -> GRYExpression {
		try ensure(AST: tupleExpression, isNamed: "Tuple Expression")

		// Only empty tuples don't have a list of names
		guard let names = tupleExpression["names"] else {
			return .tupleExpression(pairs: [])
		}

		let namesArray = names.split(separator: ",")

		var tuplePairs = [GRYExpression.TuplePair]()

		for (name, expression) in zip(namesArray, tupleExpression.subtrees) {
			let expression = try translate(expression: expression)

			// Empty names (like the underscore in "foo(_:)") are represented by ''
			if name == "_" {
				tuplePairs.append(GRYExpression.TuplePair(name: nil, expression: expression))
			}
			else {
				tuplePairs.append(
					GRYExpression.TuplePair(name: String(name), expression: expression))
			}
		}

		return .tupleExpression(pairs: tuplePairs)
	}

	internal func translate(asNumericLiteral callExpression: GRYSwiftAST) throws -> GRYExpression {
		try ensure(AST: callExpression, isNamed: "Call Expression")

		if let tupleExpression = callExpression.subtree(named: "Tuple Expression"),
			let integerLiteralExpression = tupleExpression
				.subtree(named: "Integer Literal Expression"),
			let value = integerLiteralExpression["value"],

			let constructorReferenceCallExpression = callExpression
				.subtree(named: "Constructor Reference Call Expression"),
			let typeExpression = constructorReferenceCallExpression
				.subtree(named: "Type Expression"),
			let rawType = typeExpression["typerepr"]
		{
			let type = cleanUpType(rawType)
			if type == "Double" {
				return .literalDoubleExpression(value: Double(value)!)
			}
			else {
				return .literalIntExpression(value: Int(value)!)
			}
		}
		else {
			throw unexpectedASTStructureError(
				"Unrecognized structure for numeric literal", AST: callExpression)
		}
	}

	internal func translate(asBooleanLiteral callExpression: GRYSwiftAST) throws
		-> GRYExpression
	{
		try ensure(AST: callExpression, isNamed: "Call Expression")

		if let tupleExpression = callExpression.subtree(named: "Tuple Expression"),
			let booleanLiteralExpression = tupleExpression
				.subtree(named: "Boolean Literal Expression"),
			let value = booleanLiteralExpression["value"]
		{
			return .literalBoolExpression(value: (value == "true"))
		}
		else {
			throw unexpectedASTStructureError(
				"Unrecognized structure for boolean literal", AST: callExpression)
		}
	}

	internal func translate(stringLiteralExpression: GRYSwiftAST) throws -> GRYExpression {
		try ensure(AST: stringLiteralExpression, isNamed: "String Literal Expression")

		if let value = stringLiteralExpression["value"] {
			return .literalStringExpression(value: value)
		}
		else {
			throw unexpectedASTStructureError(
				"Unrecognized structure", AST: stringLiteralExpression)
		}
	}

	internal func translate(interpolatedStringLiteralExpression: GRYSwiftAST) throws
		-> GRYExpression
	{
		try ensure(
			AST: interpolatedStringLiteralExpression,
			isNamed: "Interpolated String Literal Expression")

		var expressions = [GRYExpression]()

		for expression in interpolatedStringLiteralExpression.subtrees {
			if expression.name == "String Literal Expression" {
				let expression = try translate(stringLiteralExpression: expression)
				guard case let .literalStringExpression(value: string) = expression else {
					throw unexpectedASTStructureError(
						"Failed to translate string literal",
						AST: interpolatedStringLiteralExpression)
				}

				// Empty strings, as a special case, are represented by the swift ast dump
				// as two double quotes with nothing between them, instead of an actual empty string
				guard string != "\"\"" else {
					continue
				}

				expressions.append(.literalStringExpression(value: string))
			}
			else {
				expressions.append(try translate(expression: expression))
			}
		}

		return .interpolatedStringLiteralExpression(expressions: expressions)
	}

	internal func translate(declarationReferenceExpression: GRYSwiftAST) throws
		-> GRYExpression
	{
		try ensure(AST: declarationReferenceExpression, isNamed: "Declaration Reference Expression")

		guard let rawType = declarationReferenceExpression["type"] else {
			throw unexpectedASTStructureError(
				"Failed to recognize type", AST: declarationReferenceExpression)
		}
		let type = cleanUpType(rawType)

		let isImplicit = declarationReferenceExpression.standaloneAttributes.contains("implicit")

		if let discriminator = declarationReferenceExpression["discriminator"] {
			let (identifier, isStandardLibrary) = getIdentifierFromDeclaration(discriminator)
			return .declarationReferenceExpression(
				identifier: identifier, type: type, isStandardLibrary: isStandardLibrary,
				isImplicit: isImplicit)
		}
		else if let codeDeclaration = declarationReferenceExpression.standaloneAttributes.first,
			codeDeclaration.hasPrefix("code.")
		{
			let (identifier, isStandardLibrary) = getIdentifierFromDeclaration(codeDeclaration)
			return .declarationReferenceExpression(
				identifier: identifier, type: type, isStandardLibrary: isStandardLibrary,
				isImplicit: isImplicit)
		}
		else if let declaration = declarationReferenceExpression["decl"] {
			let (identifier, isStandardLibrary) = getIdentifierFromDeclaration(declaration)
			return .declarationReferenceExpression(
				identifier: identifier, type: type, isStandardLibrary: isStandardLibrary,
				isImplicit: isImplicit)
		}
		else {
			throw unexpectedASTStructureError(
				"Unrecognized structure", AST: declarationReferenceExpression)
		}
	}

	internal func translate(subscriptExpression: GRYSwiftAST) throws -> GRYExpression {
		try ensure(AST: subscriptExpression, isNamed: "Subscript Expression")

		if let rawType = subscriptExpression["type"],
			let parenthesesExpression = subscriptExpression.subtree(
			at: 1,
			named: "Parentheses Expression"),
			let subscriptContents = parenthesesExpression.subtree(at: 0),
			let subscriptedExpression = subscriptExpression.subtree(at: 0)
		{
			let type = cleanUpType(rawType)
			let subscriptContentsTranslation = try translate(expression: subscriptContents)
			let subscriptedExpressionTranslation = try translate(expression: subscriptedExpression)

			return .subscriptExpression(
				subscriptedExpression: subscriptedExpressionTranslation,
				indexExpression: subscriptContentsTranslation, type: type)
		}
		else {
			throw unexpectedASTStructureError(
				"Unrecognized structure", AST: subscriptExpression)
		}
	}

	internal func translate(arrayExpression: GRYSwiftAST) throws -> GRYExpression {
		try ensure(AST: arrayExpression, isNamed: "Array Expression")

		let expressionsArray = try arrayExpression.subtrees.map(translate(expression:))

		guard let rawType = arrayExpression["type"] else {
			throw unexpectedASTStructureError(
				"Failed to get type", AST: arrayExpression)
		}
		let type = cleanUpType(rawType)

		return .arrayExpression(elements: expressionsArray.array, type: type)
	}

	// MARK: - Supporting methods
	internal func process(openExistentialExpression: GRYSwiftAST) throws -> GRYSwiftAST {
		try ensure(AST: openExistentialExpression, isNamed: "Open Existential Expression")

		guard let replacementSubtree = openExistentialExpression.subtree(at: 1),
			let resultSubtree = openExistentialExpression.subtrees.last else
		{
			throw unexpectedASTStructureError(
				"Expected the AST to contain 3 subtrees: an Opaque Value Expression, an " +
				"expression to replace the opaque value, and an expression containing opaque " +
				"values to be replaced.",
				AST: openExistentialExpression)
		}

		return astReplacingOpaqueValues(in: resultSubtree, with: replacementSubtree)
	}

	internal func astReplacingOpaqueValues(in ast: GRYSwiftAST, with replacementAST: GRYSwiftAST)
		-> GRYSwiftAST
	{
		if ast.name == "Opaque Value Expression" {
			return replacementAST
		}

		var newSubtrees = [GRYSwiftAST]()
		for subtree in ast.subtrees {
			newSubtrees.append(astReplacingOpaqueValues(in: subtree, with: replacementAST))
		}

		return GRYSwiftAST(
			ast.name, ast.standaloneAttributes, ast.keyValueAttributes,
			ArrayReference(array: newSubtrees))
	}

	internal func process(patternBindingDeclaration: GRYSwiftAST) throws {
		try ensure(AST: patternBindingDeclaration, isNamed: "Pattern Binding Declaration")

		// Some patternBindingDeclarations are empty, and that's ok. See the classes.swift test
		// case.
		guard let expression = patternBindingDeclaration.subtrees.last,
			ASTIsExpression(expression) else
		{
			return
		}

		let translatedExpression = try translate(expression: expression)

		let binding: GRYSwiftAST

		if let unwrappedBinding = patternBindingDeclaration
			.subtree(named: "Pattern Typed")?
			.subtree(named: "Pattern Named")
		{
			binding = unwrappedBinding
		}
		else if let unwrappedBinding = patternBindingDeclaration.subtree(named: "Pattern Named") {
			binding = unwrappedBinding
		}
		else {
			throw unexpectedASTStructureError(
				"Pattern not recognized", AST: patternBindingDeclaration)
		}

		guard let identifier = binding.standaloneAttributes.first,
			let rawType = binding["type"] else
		{
			throw unexpectedASTStructureError(
				"Type not recognized", AST: patternBindingDeclaration)
		}

		let type = cleanUpType(rawType)

		danglingPatternBinding =
			(identifier: identifier,
			 type: type,
			 expression: translatedExpression)

		return
	}

	internal func getIdentifierFromDeclaration(_ declaration: String)
		-> (declaration: String, isStandardLibrary: Bool)
	{
		let isStandardLibrary = declaration.hasPrefix("Swift")

		var index = declaration.startIndex
		var lastPeriodIndex = declaration.startIndex
		while index != declaration.endIndex {
			let character = declaration[index]

			if character == "." {
				lastPeriodIndex = index
			}
			if character == "@" {
				break
			}

			index = declaration.index(after: index)
		}

		let identifierStartIndex = declaration.index(after: lastPeriodIndex)

		let identifier = declaration[identifierStartIndex..<index]

		return (declaration: String(identifier), isStandardLibrary: isStandardLibrary)
	}

	internal func cleanUpType(_ type: String) -> String {
		if type.hasPrefix("@lvalue ") {
			return String(type.suffix(from: "@lvalue ".endIndex))
		}
		else if type.hasPrefix("("), type.hasSuffix(")"), !type.contains("->") {
			return String(type.dropFirst().dropLast())
		}
		else {
			return type
		}
	}

	internal func ASTIsExpression(_ ast: GRYSwiftAST) -> Bool {
		return ast.name.hasSuffix("Expression") || ast.name == "Inject Into Optional"
	}
}

enum GRYSwiftTranslatorError: Error, CustomStringConvertible {
	case unexpectedASTStructure(
		file: String,
		line: Int,
		function: String,
		message: String,
		AST: GRYSwiftAST)

	var description: String {
		switch self {
		case let .unexpectedASTStructure(
			file: file, line: line, function: function, message: message, AST: ast):

			var nodeDescription = ""
			ast.prettyPrint {
				nodeDescription += $0
			}

			return "Translation error: failed to translate Swift AST into Gryphon AST.\n" +
				"On file \(file), line \(line), function \(function).\n" +
				message + ".\n" +
			"Thrown when translating the following AST node:\n\(nodeDescription)"
		}
	}
}

func unexpectedASTStructureError(
	file: String = #file, line: Int = #line, function: String = #function, _ message: String,
	AST ast: GRYSwiftAST) -> GRYSwiftTranslatorError
{
	return GRYSwiftTranslatorError.unexpectedASTStructure(
		file: file, line: line, function: function, message: message, AST: ast)
}

func ensure(
	file: String = #file, line: Int = #line, function: String = #function,
	AST ast: GRYSwiftAST, isNamed expectedASTName: String) throws
{
	if ast.name != expectedASTName {
		throw GRYSwiftTranslatorError.unexpectedASTStructure(
			file: file, line: line, function: function,
			message: "Trying to translate \(ast.name) as '\(expectedASTName)'", AST: ast)
	}
}

func ensure(
	file: String = #file, line: Int = #line, function: String = #function,
	AST ast: GRYSwiftAST, isNamed expectedASTNames: [String]) throws
{
	var isValidName = false
	for expectedASTName in expectedASTNames {
		if ast.name == expectedASTName {
			isValidName = true
		}
	}

	if !isValidName {
		throw GRYSwiftTranslatorError.unexpectedASTStructure(
			file: file, line: line, function: function,
			message: "Trying to translate \(ast.name) as '\(expectedASTNames[0])'", AST: ast)
	}
}
