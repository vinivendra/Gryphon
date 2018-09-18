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

public class GRYSwift4_1Translator {

	// MARK: - Properties
	var danglingPatternBinding: (identifier: String, type: String, expression: GRYExpression?)?

	var extendingType: String?

	// MARK: - Interface
	public init() { }

	public func translateAST(_ ast: GRYSwiftAst) -> GRYSourceFile? {
		// First, translate declarations that shouldn't be inside the main function
		let declarationNames = [
			"Protocol",
			"Class Declaration",
			"Extension Declaration",
			"Function Declaration",
			"Enum Declaration",
		]
		let isDeclaration = { (ast: GRYSwiftAst) -> Bool in declarationNames.contains(ast.name) }

		let swiftDeclarations = ast.subtrees.filter(isDeclaration)
		let declarations = translate(subtrees: swiftDeclarations)

		// Then, translate the remaining statements (if there are any) and wrap them in the main
		// function
		let swiftStatements = ast.subtrees.filter({ !isDeclaration($0) })
		let statements = translate(subtrees: swiftStatements)

		return GRYSourceFile(declarations: declarations, statements: statements)
	}

	// MARK: - Top-level translations
	private func translate(subtrees: [GRYSwiftAst]) -> [GRYTopLevelNode] {
		return subtrees.reduce([], { (result, subtree) -> [GRYTopLevelNode] in
			result + translate(subtree: subtree).compactMap { $0 }
		})
	}

	private func translate(subtree: GRYSwiftAst) -> [GRYTopLevelNode?] {
		var result: GRYTopLevelNode?

		switch subtree.name {
		case "Top Level Code Declaration":
			result = translate(topLevelCode: subtree)
		case "Import Declaration":
			result = GRYImportDeclaration(subtree.standaloneAttributes[0])
		case "Class Declaration":
			result = translate(classDeclaration: subtree)
//		case "Constructor Declaration":
//			result = translate(
//				constructorDeclaration: subtree,
//				withIndentation: indentation)
//		case "Destructor Declaration":
//			result = translate(
//				destructorDeclaration: subtree,
//				withIndentation: indentation)
		case "Enum Declaration":
			result = translate(enumDeclaration: subtree)
		case "Extension Declaration":
			self.extendingType = subtree.standaloneAttributes[0]
			let result = translate(subtrees: subtree.subtrees)
			self.extendingType = nil
			return result
		case "For Each Statement":
			result = translate(forEachStatement: subtree)
		case "Function Declaration":
			result = translate(functionDeclaration: subtree)
		case "Protocol":
			result = translate(protocolDeclaration: subtree)
		case "Throw Statement":
			result = translate(throwStatement: subtree)
//		case "Struct Declaration":
//			result = translate(
//				structDeclaration: subtree,
//				withIndentation: indentation)
		case "Variable Declaration":
			result = translate(variableDeclaration: subtree)
		case "Assign Expression":
			result = translate(assignExpression: subtree)
		case "If Statement", "Guard Statement":
			result = translate(ifStatement: subtree)
		case "Pattern Binding Declaration":
			result = process(patternBindingDeclaration: subtree)
		case "Return Statement":
			result = translate(returnStatement: subtree)
		case "Call Expression":
			result = translate(callExpression: subtree)
		default:
			if subtree.name.hasSuffix("Expression"),
				let expression = translate(expression: subtree)
			{
				result = expression
			}
			else {
				result = nil
			}
		}

		return [result]
	}

	private func translate(expression: GRYSwiftAst) -> GRYExpression? {
		// Most diagnostics are logged by the child subTrees; others represent wrapper expressions
		// with little value in logging. There are a few expections.

		switch expression.name {
		case "Array Expression":
			return translate(arrayExpression: expression)
		case "Binary Expression":
			return translate(binaryExpression: expression)
		case "Call Expression":
			return translate(callExpression: expression)
		case "Declaration Reference Expression":
			return translate(declarationReferenceExpression: expression)
		case "Dot Syntax Call Expression":
			return translate(dotSyntaxCallExpression: expression)
		case "String Literal Expression":
			return translate(stringLiteralExpression: expression)
		case "Interpolated String Literal Expression":
			return translate(interpolatedStringLiteralExpression: expression)
		case "Erasure Expression":
			if let lastExpression = expression.subtrees.last {
				return translate(expression: lastExpression)
			}
			else {
				return nil
			}
		case "Prefix Unary Expression":
			return translate(prefixUnaryExpression: expression)
		case "Type Expression":
			return translate(typeExpression: expression)
		case "Member Reference Expression":
			return translate(memberReferenceExpression: expression)
		case "Subscript Expression":
			return translate(subscriptExpression: expression)
		case "Parentheses Expression":
			if let firstExpression = expression.subtree(at: 0) {
				return translate(expression: firstExpression)
			}
			else {
				return nil
			}
		case "Force Value Expression":
			if let firstExpression = expression.subtree(at: 0),
				let expression = translate(expression: firstExpression)
			{
				return GRYForceValueExpression(expression: expression)
			}
			else {
				return nil
			}
		case "Autoclosure Expression",
			 "Inject Into Optional",
			 "Inout Expression",
			 "Load Expression":
			if let lastExpression = expression.subtrees.last {
				return translate(expression: lastExpression)
			}
			else {
				return nil
			}
		default:
			return nil
		}
	}

	// MARK: - Leaf translations
	private func translate(protocolDeclaration: GRYSwiftAst) -> GRYProtocolDeclaration? {
		precondition(protocolDeclaration.name == "Protocol")

		guard let protocolName = protocolDeclaration.standaloneAttributes.first else {
			return nil
		}

		return GRYProtocolDeclaration(name: protocolName)
	}

	private func translate(assignExpression: GRYSwiftAst) -> GRYAssignmentStatement? {
		precondition(assignExpression.name == "Assign Expression")

		if let leftExpression = assignExpression.subtree(at: 0),
			let rightExpression = assignExpression.subtree(at: 1)
		{
			let leftTranslation = translate(expression: leftExpression)!
			let rightTranslation = translate(expression: rightExpression)!

			return GRYAssignmentStatement(leftHand: leftTranslation, rightHand: rightTranslation)
		}
		else {
			return nil
		}
	}

	private func translate(classDeclaration: GRYSwiftAst) -> GRYClassDeclaration? {
		precondition(classDeclaration.name == "Class Declaration")

		// Get the class name
		let name = classDeclaration.standaloneAttributes.first!

		// Check for inheritance
		let inheritanceArray: [String]
		if let inheritanceList = classDeclaration.keyValueAttributes["inherits"] {
			inheritanceArray = inheritanceList.split(withStringSeparator: ", ")
		}
		else {
			inheritanceArray = []
		}

		guard !inheritanceArray.contains("GRYIgnore") else {
			return GRYClassDeclaration(name: name, inherits: inheritanceArray, members: [])
		}

		// Translate the contents
		let classContents = translate(subtrees: classDeclaration.subtrees)

		return GRYClassDeclaration(name: name, inherits: inheritanceArray, members: classContents)
	}

	private func translate(throwStatement: GRYSwiftAst) -> GRYThrowStatement? {
		precondition(throwStatement.name == "Throw Statement")

		if let expression = throwStatement.subtrees.last,
			let expressionTranslation = translate(expression: expression)
		{
			return GRYThrowStatement(expression: expressionTranslation)
		}
		else {
			return nil
		}
	}

	private func translate(enumDeclaration: GRYSwiftAst) -> GRYEnumDeclaration? {
		precondition(enumDeclaration.name == "Enum Declaration")

		let access = enumDeclaration.keyValueAttributes["access"]

		let name = enumDeclaration.standaloneAttributes.first!

		let inheritanceArray: [String]
		if let inheritanceList = enumDeclaration.keyValueAttributes["inherits"] {
			inheritanceArray = inheritanceList.split(withStringSeparator: ", ")
		}
		else {
			inheritanceArray = []
		}

		guard !inheritanceArray.contains("GRYIgnore") else {
			return GRYEnumDeclaration(
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
				return nil
			}

			elements.append(elementName)
		}

		return GRYEnumDeclaration(
			access: access,
			name: name,
			inherits: inheritanceArray,
			elements: elements)
	}

	private func translate(memberReferenceExpression: GRYSwiftAst) -> GRYDotExpression? {
		precondition(memberReferenceExpression.name == "Member Reference Expression")

		if let declaration = memberReferenceExpression["decl"],
			let memberOwner = memberReferenceExpression.subtree(at: 0),
			let leftHand = translate(expression: memberOwner)
		{
			let member = getIdentifierFromDeclaration(declaration)
			let rightHand = GRYDeclarationReferenceExpression(identifier: member)
			return GRYDotExpression(leftExpression: leftHand,
									rightExpression: rightHand)
		}
		else {
			return nil
		}
	}

	private func translate(prefixUnaryExpression: GRYSwiftAst) -> GRYUnaryOperatorExpression? {
		precondition(prefixUnaryExpression.name == "Prefix Unary Expression")

		if let declaration = prefixUnaryExpression
			.subtree(named: "Dot Syntax Call Expression")?
			.subtree(named: "Declaration Reference Expression")?["decl"],
			let expression = prefixUnaryExpression.subtree(at: 1),
			let expressionTranslation = translate(expression: expression)
		{
			let operatorIdentifier = getIdentifierFromDeclaration(declaration)

			return GRYUnaryOperatorExpression(
				expression: expressionTranslation,
				operatorSymbol: operatorIdentifier)
		}
		else {
			return nil
		}
	}

	private func translate(binaryExpression: GRYSwiftAst) -> GRYBinaryOperatorExpression? {
		precondition(binaryExpression.name == "Binary Expression")

		let operatorIdentifier: String

		if let declaration = binaryExpression
			.subtree(named: "Dot Syntax Call Expression")?
			.subtree(named: "Declaration Reference Expression")?["decl"],
			let tupleExpression = binaryExpression.subtree(named: "Tuple Expression"),
			let leftHandExpression = tupleExpression.subtree(at: 0),
			let rightHandExpression = tupleExpression.subtree(at: 1)
		{
			operatorIdentifier = getIdentifierFromDeclaration(declaration)
			let leftHandTranslation = translate(expression: leftHandExpression)!
			let rightHandTranslation = translate(expression: rightHandExpression)!

			return GRYBinaryOperatorExpression(
				leftExpression: leftHandTranslation,
				rightExpression: rightHandTranslation,
				operatorSymbol: operatorIdentifier)
		}
		else {
			return nil
		}
	}

	private func translate(typeExpression: GRYSwiftAst) -> GRYTypeExpression? {
		precondition(typeExpression.name == "Type Expression")

		guard let type = typeExpression.keyValueAttributes["typerepr"] else {
			return nil
		}

		return GRYTypeExpression(type: type)
	}

	private func translate(dotSyntaxCallExpression: GRYSwiftAst) -> GRYDotExpression? {
		precondition(dotSyntaxCallExpression.name == "Dot Syntax Call Expression")

		if let leftHandTree = dotSyntaxCallExpression.subtree(at: 1),
			let rightHandExpression = dotSyntaxCallExpression.subtree(at: 0)
		{
			let rightHand = translate(expression: rightHandExpression)!
			let leftHand = translate(typeExpression: leftHandTree)!

			return GRYDotExpression(leftExpression: leftHand, rightExpression: rightHand)
		}

		return nil
	}

	private func translate(returnStatement: GRYSwiftAst) -> GRYReturnStatement? {
		precondition(returnStatement.name == "Return Statement")

		if let expression = returnStatement.subtrees.last {
			if let expression = translate(expression: expression) {
				return GRYReturnStatement(expression: expression)
			}
			else {
				return nil
			}
		}
		else {
			return GRYReturnStatement(expression: nil)
		}
	}

	private func translate(forEachStatement: GRYSwiftAst) -> GRYForEachStatement? {
		precondition(forEachStatement.name == "For Each Statement")

		guard let variableName = forEachStatement
			.subtree(named: "Pattern Named")?
			.standaloneAttributes.first,
			let collectionExpression = forEachStatement.subtree(at: 2),
			let collectionTranslation = translate(expression: collectionExpression) else
		{
			return nil
		}

		guard let braceStatement = forEachStatement.subtrees.last,
			braceStatement.name == "Brace Statement" else
		{
			return nil
		}

		let statements = translate(subtrees: braceStatement.subtrees)
		let variable = GRYDeclarationReferenceExpression(identifier: variableName)

		return GRYForEachStatement(
			collection: collectionTranslation,
			variable: variable,
			statements: statements)
	}

	private func translate(ifStatement: GRYSwiftAst) -> GRYIfStatement? {
		precondition(ifStatement.name == "If Statement" || ifStatement.name == "Guard Statement")

		let isGuard = (ifStatement.name == "Guard Statement")

		let (letDeclarations, conditions) = translateDeclarationsAndConditions(
			forIfStatement: ifStatement)!

		let braceStatement: GRYSwiftAst
		let elseIfStatement: GRYIfStatement?
		let elseStatement: GRYIfStatement?

		if ifStatement.subtrees.count > 2,
			let unwrappedBraceStatement = ifStatement.subtrees.secondToLast,
			unwrappedBraceStatement.name == "Brace Statement",
			let elseIfAST = ifStatement.subtrees.last,
			elseIfAST.name == "If Statement"
		{
			braceStatement = unwrappedBraceStatement
			elseIfStatement = translate(ifStatement: elseIfAST)
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

			let statements = translate(subtrees: elseAST.subtrees)
			elseStatement = GRYIfStatement(
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
			return nil
		}

		let statements = braceStatement.subtrees
		let statementsResult = translate(subtrees: statements)

		return GRYIfStatement(
			conditions: conditions,
			declarations: letDeclarations,
			statements: statementsResult,
			elseStatement: elseIfStatement ?? elseStatement,
			isGuard: isGuard)
	}

	private func translateDeclarationsAndConditions(
		forIfStatement ifStatement: GRYSwiftAst)
		-> (declarations: [GRYTopLevelNode], conditions: [GRYExpression])?
	{
		precondition(ifStatement.name == "If Statement" || ifStatement.name == "Guard Statement")

		var conditionsResult = [GRYExpression]()
		var declarationsResult = [GRYTopLevelNode]()

		let conditions = ifStatement.subtrees.filter {
			$0.name != "If Statement" && $0.name != "Brace Statement"
		}

		for condition in conditions {
			// If it's an if-let
			if condition.name == "Pattern",
				let optionalSomeElement = condition.subtree(named: "Optional Some Element")
			{
				let patternNamed: GRYSwiftAst
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
					return nil
				}

				guard let type = optionalSomeElement["type"] else {
					return nil
				}

				guard let name = patternNamed.standaloneAttributes.first,
					let lastCondition = condition.subtrees.last,
					let expression = translate(expression: lastCondition) else
				{
					return nil
				}

				declarationsResult.append(GRYVariableDeclaration(
					expression: expression,
					identifier: name,
					type: type,
					getter: nil, setter: nil,
					isLet: isLet,
					extendsType: nil))
			}
			else {
				conditionsResult.append(translate(expression: condition)!)
			}
		}

		return (declarations: declarationsResult, conditions: conditionsResult)
	}

	private func translate(functionDeclaration: GRYSwiftAst) -> GRYFunctionDeclaration? {
		precondition(functionDeclaration.name == "Function Declaration")

		// Getters and setters will appear again in the Variable Declaration AST and get translated
		let isGetterOrSetter =
			(functionDeclaration["getter_for"] != nil) || (functionDeclaration["setter_for"] != nil)
		let isImplicit = functionDeclaration.standaloneAttributes.contains("implicit")
		guard !isImplicit && !isGetterOrSetter else {
			return nil
		}

		let functionName = functionDeclaration.standaloneAttributes.first ?? ""

		// If this function should be ignored
//		guard !functionName.hasPrefix("GRYInsert(") &&
//			!functionName.hasPrefix("GRYAlternative(") &&
//			!functionName.hasPrefix("GRYIgnoreNext(") else
//		{
//			return .translation("")
//		}

		// If it's GRYDeclarations, we want to add its contents as top-level statements
//		guard !functionName.hasPrefix("GRYDeclarations(") else {
//			if let braceStatement = functionDeclaration.subtree(named: "Brace Statement") {
//				diagnostics?.logSuccessfulTranslation(functionDeclaration.name)
//				return translate(subtrees: braceStatement.subtrees, withIndentation: indentation)
//			}
//			else {
//				diagnostics?.logUnknownTranslation(functionDeclaration.name)
//				return .failed
//			}
//		}

//		var indentation = indentation
//		var result = TranslationResult.translation("")
//
//		result += indentation

		let access = functionDeclaration["access"]

		let functionNamePrefix = functionName.prefix { $0 != "(" }

		// Get the function parameters.
		let parameterList: GRYSwiftAst?

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
					parameterTypes.append(type)
				}
				else {
					return nil
				}
			}
		}

		// Translate the return type
		// TODO: Doesn't allow to return function types
		guard let returnType = functionDeclaration["interface type"]?
			.split(withStringSeparator: " -> ").last else
		{
			return nil
		}

		let statements: [GRYTopLevelNode]
		// Translate the function body
		if let braceStatement = functionDeclaration.subtree(named: "Brace Statement") {
			statements = translate(subtrees: braceStatement.subtrees)
		}
		else {
			return nil
		}

		return GRYFunctionDeclaration(
			prefix: String(functionNamePrefix),
			parameterNames: parameterNames,
			parameterTypes: parameterTypes,
			returnType: returnType,
			isImplicit: isImplicit,
			statements: statements,
			access: access)
	}

	private func translate(topLevelCode: GRYSwiftAst) -> GRYTopLevelNode? {
		precondition(topLevelCode.name == "Top Level Code Declaration")

		guard let braceStatement = topLevelCode.subtree(named: "Brace Statement") else {
			fatalError("Expected to always work")
		}

		let subtrees = translate(subtrees: braceStatement.subtrees)
		assert(subtrees.count <= 1)
		return subtrees.first
	}

	private func translate(variableDeclaration: GRYSwiftAst) -> GRYTopLevelNode? {
		precondition(variableDeclaration.name == "Variable Declaration")

		if let identifier = variableDeclaration.standaloneAttributes.first,
			let type = variableDeclaration["interface type"]
		{
			let isLet = variableDeclaration.standaloneAttributes.contains("let")

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

			var getter: GRYFunctionDeclaration?
			var setter: GRYFunctionDeclaration?
			for subtree in variableDeclaration.subtrees
				where !subtree.standaloneAttributes.contains("implicit")
			{
				guard let statements = subtree.subtree(named: "Brace Statement")?.subtrees else {
					return nil
				}

				let access = subtree["access"]
				let statementsTranslation = translate(subtrees: statements)

				if subtree["getter_for"] != nil {
					getter = GRYFunctionDeclaration(
						prefix: "get",
						parameterNames: [], parameterTypes: [],
						returnType: type,
						isImplicit: false,
						statements: statementsTranslation,
						access: access)
				}
				else {
					setter = GRYFunctionDeclaration(
						prefix: "set",
						parameterNames: ["newValue"],
						parameterTypes: [type],
						returnType: "()",
						isImplicit: false,
						statements: statementsTranslation,
						access: access)
				}
			}

			return GRYVariableDeclaration(
				expression: expression,
				identifier: identifier,
				type: type,
				getter: getter,
				setter: setter,
				isLet: isLet,
				extendsType: self.extendingType)
		}
		else {
			return nil
		}
	}

	private func translate(callExpression: GRYSwiftAst) -> GRYExpression? {
		precondition(callExpression.name == "Call Expression")

		// If the call expression corresponds to an integer literal
		if let argumentLabels = callExpression["arg_labels"] {
			if argumentLabels == "_builtinIntegerLiteral:" {
				return translate(asNumericLiteral: callExpression)
			}
			else if argumentLabels == "_builtinBooleanLiteral:" {
				return translate(asBooleanLiteral: callExpression)
			}
			else if argumentLabels == "nilLiteral:" {
				return GRYNilLiteralExpression()
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
			return translate(expression: containedExpression)
		}

		if let declarationReferenceExpression = callExpression
			.subtree(named: "Declaration Reference Expression")
		{
			if let expression = translate(
				declarationReferenceExpression: declarationReferenceExpression)
			{
				function = expression
			}
			else {
				return nil
			}
		}
		else if let dotSyntaxCallExpression = callExpression
				.subtree(named: "Dot Syntax Call Expression"),
			let methodName = dotSyntaxCallExpression
				.subtree(at: 0, named: "Declaration Reference Expression"),
			let methodOwner = dotSyntaxCallExpression.subtree(at: 1)
		{
			if let methodName =
				translate(declarationReferenceExpression: methodName),
				let methodOwner = translate(expression: methodOwner)
			{
				function = GRYDotExpression(
					leftExpression: methodOwner, rightExpression: methodName)
			}
			else {
				return nil
			}
		}
		else if let typeExpression = callExpression
			.subtree(named: "Constructor Reference Call Expression")?
			.subtree(named: "Type Expression")
		{
			if let expression = translate(typeExpression: typeExpression) {
				function = expression
			}
			else {
				return nil
			}
		}
		else if let declaration = callExpression["decl"] {
			function = GRYDeclarationReferenceExpression(
				identifier: getIdentifierFromDeclaration(declaration))
		}
		else {
			return nil
		}

//			let functionNamePrefix = functionName.prefix(while: { $0 != "(" })

		let parameters = translate(callExpressionParameters: callExpression)

		return GRYCallExpression(function: function, parameters: parameters!)
	}

	private func translate(callExpressionParameters callExpression: GRYSwiftAst)
		-> GRYTupleExpression?
	{
		let parameters: GRYTupleExpression
		if let parenthesesExpression = callExpression.subtree(named: "Parentheses Expression") {
			let expression = translate(expression: parenthesesExpression)!
			parameters = [GRYTupleExpression.Pair(name: nil, expression: expression)]
		}
		else if let tupleExpression = callExpression.subtree(named: "Tuple Expression") {
			parameters = translate(tupleExpression: tupleExpression)!
		}
		else if let tupleShuffleExpression = callExpression
			.subtree(named: "Tuple Shuffle Expression")
		{
			if let tupleExpression = tupleShuffleExpression.subtree(named: "Tuple Expression") {
				parameters = translate(tupleExpression: tupleExpression)!
			}
			else if let parenthesesExpression = tupleShuffleExpression
				.subtree(named: "Parentheses Expression")
			{
				let expression = translate(expression: parenthesesExpression)!
				parameters = [GRYTupleExpression.Pair(name: nil, expression: expression)]
			}
			else {
				return nil
			}
		}
		else {
			return nil
		}

		return parameters
	}

	private func translate(tupleExpression: GRYSwiftAst) -> GRYTupleExpression? {
		precondition(tupleExpression.name == "Tuple Expression")

		// Only empty tuples don't have a list of names
		guard let names = tupleExpression["names"] else {
			return GRYTupleExpression(pairs: [])
		}

		let namesArray = names.split(separator: ",")

		var tuplePairs = [GRYTupleExpression.Pair]()

		for (name, expression) in zip(namesArray, tupleExpression.subtrees) {
			let expression = translate(expression: expression)!

			// Empty names (like the underscore in "foo(_:)") are represented by ''
			if name == "_" {
				tuplePairs.append(GRYTupleExpression.Pair(name: nil, expression: expression))
			}
			else {
				tuplePairs.append(
					GRYTupleExpression.Pair(name: String(name), expression: expression))
			}
		}

		return GRYTupleExpression(pairs: tuplePairs)
	}

	private func translate(asNumericLiteral callExpression: GRYSwiftAst) -> GRYExpression? {
		precondition(callExpression.name == "Call Expression")

		if let tupleExpression = callExpression.subtree(named: "Tuple Expression"),
			let integerLiteralExpression = tupleExpression
				.subtree(named: "Integer Literal Expression"),
			let value = integerLiteralExpression["value"],

			let constructorReferenceCallExpression = callExpression
				.subtree(named: "Constructor Reference Call Expression"),
			let typeExpression = constructorReferenceCallExpression
				.subtree(named: "Type Expression"),
			let type = typeExpression["typerepr"]
		{
			if type == "Double" {
				return GRYLiteralExpression(value: Double(value)!)
			}
			else {
				return GRYLiteralExpression(value: Int(value)!)
			}
		}
		else {
			return nil
		}
	}

	private func translate(asBooleanLiteral callExpression: GRYSwiftAst)
		-> GRYLiteralExpression<Bool>?
	{
		precondition(callExpression.name == "Call Expression")

		if let tupleExpression = callExpression.subtree(named: "Tuple Expression"),
			let booleanLiteralExpression = tupleExpression
				.subtree(named: "Boolean Literal Expression"),
			let value = booleanLiteralExpression["value"]
		{
			return GRYLiteralExpression<Bool>(value: (value == "true"))
		}
		else {
			return nil
		}
	}

	private func translate(stringLiteralExpression: GRYSwiftAst) -> GRYLiteralExpression<String>? {
		if let value = stringLiteralExpression["value"] {
			return GRYLiteralExpression(value: value)
		}
		else {
			return nil
		}
	}

	private func translate(interpolatedStringLiteralExpression: GRYSwiftAst)
		-> GRYInterpolatedStringLiteralExpression?
	{
		precondition(
			interpolatedStringLiteralExpression.name == "Interpolated String Literal Expression")

		var expressions = [GRYExpression]()

		for expression in interpolatedStringLiteralExpression.subtrees {
			if expression.name == "String Literal Expression" {
				guard let string = translate(stringLiteralExpression: expression)?.value else
				{
					return nil
				}

				// Empty strings, as a special case, are represented by the swift ast dump
				// as two double quotes with nothing between them, instead of an actual empty string
				guard string != "\"\"" else {
					continue
				}

				expressions.append(GRYLiteralExpression(value: string))
			}
			else {
				expressions.append(translate(expression: expression)!)
			}
		}

		return GRYInterpolatedStringLiteralExpression(expressions: expressions)
	}

	private func translate(declarationReferenceExpression: GRYSwiftAst)
		-> GRYDeclarationReferenceExpression?
	{
		precondition(declarationReferenceExpression.name == "Declaration Reference Expression")

		if let codeDeclaration = declarationReferenceExpression.standaloneAttributes.first,
			codeDeclaration.hasPrefix("code.")
		{
			let identifier = getIdentifierFromDeclaration(codeDeclaration)
			return GRYDeclarationReferenceExpression(identifier: identifier)
		}
		else if let declaration = declarationReferenceExpression["decl"] {
			let identifier = getIdentifierFromDeclaration(declaration)
			return GRYDeclarationReferenceExpression(identifier: identifier)
		}
		else {
			return nil
		}
	}

	private func translate(subscriptExpression: GRYSwiftAst) -> GRYSubscriptExpression? {
		precondition(subscriptExpression.name == "Subscript Expression")

		if let parenthesesExpression = subscriptExpression.subtree(
			at: 1,
			named: "Parentheses Expression"),
			let subscriptContents = parenthesesExpression.subtree(at: 0),
			let subscriptedExpression = subscriptExpression.subtree(at: 0)
		{
			let subscriptContentsTranslation = translate(expression: subscriptContents)!
			let subscriptedExpressionTranslation = translate(expression: subscriptedExpression)!

			return GRYSubscriptExpression(
				subscriptedExpression: subscriptedExpressionTranslation,
				indexExpression: subscriptContentsTranslation)
		}
		else {
			return nil
		}
	}

	private func translate(arrayExpression: GRYSwiftAst) -> GRYArrayExpression? {
		precondition(arrayExpression.name == "Array Expression")

		let expressionsArray = arrayExpression.subtrees.map(translate(expression:))

		if let expressionsArray = expressionsArray as? [GRYExpression] {
			return GRYArrayExpression(elements: expressionsArray)
		}
		else {
			return nil
		}
	}

	// MARK: - Supporting methods
	private func process(patternBindingDeclaration: GRYSwiftAst) -> GRYTopLevelNode? {
		precondition(patternBindingDeclaration.name == "Pattern Binding Declaration")

		// Some patternBindingDeclarations are empty, and that's ok. See the classes.swift test
		// case.
		guard let expression = patternBindingDeclaration.subtrees.last,
			ASTIsExpression(expression) else
		{
			return nil
		}

		let translatedExpression = translate(expression: expression)

		let binding: GRYSwiftAst

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
			assertionFailure("Expected to always work")
			return nil
		}

		guard let identifier = binding.standaloneAttributes.first,
			let type = binding.keyValueAttributes["type"] else
		{
			assertionFailure("Expected to always work")
			return nil
		}

		danglingPatternBinding =
			(identifier: identifier,
			 type: type,
			 expression: translatedExpression)

		return nil
	}

	private func getIdentifierFromDeclaration(_ declaration: String) -> String {
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

		if identifier == "self" {
			return "this"
		}
		else {
			return String(identifier)
		}
	}

	private func ASTIsExpression(_ ast: GRYSwiftAst) -> Bool {
		return ast.name.hasSuffix("Expression") || ast.name == "Inject Into Optional"
	}
}
