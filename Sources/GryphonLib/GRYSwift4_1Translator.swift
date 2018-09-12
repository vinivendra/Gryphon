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

	var danglingPatternBinding: (identifier: String, type: String, expression: GRYExpression?)?

	public init() { }

	public func translateAST(_ ast: GRYSwiftAST) -> GRYSourceFile? {
		// First, translate declarations that shouldn't be inside the main function
		let declarationNames = [
			"Class Declaration",
			"Extension Declaration",
			"Function Declaration",
			"Enum Declaration",
		]
		let isDeclaration = { (ast: GRYSwiftAST) -> Bool in declarationNames.contains(ast.name) }

		let swiftDeclarations = ast.subtrees.filter(isDeclaration)
		let declarations = translate(subtrees: swiftDeclarations)

		// Then, translate the remaining statements (if there are any) and wrap them in the main
		// function
		let swiftStatements = ast.subtrees.filter({ !isDeclaration($0) })
		let statements = translate(subtrees: swiftStatements)

		return GRYSourceFile(declarations: declarations, statements: statements)
	}

	private func translate(subtrees: [GRYSwiftAST]) -> [GRYTopLevelNode] {
		return subtrees.compactMap { translate(subtree: $0) }
	}

	private func translate(subtree: GRYSwiftAST) -> GRYTopLevelNode? {
		var result: GRYTopLevelNode?

		switch subtree.name {
		case "Top Level Code Declaration":
			return translate(topLevelCode: subtree)
//		case "Import Declaration":
//			diagnostics?.logSuccessfulTranslation(subtree.name)
//			result = .translation("")
//		case "Class Declaration":
//			result = translate(
//				classDeclaration: subtree,
//				withIndentation: indentation)
//		case "Constructor Declaration":
//			result = translate(
//				constructorDeclaration: subtree,
//				withIndentation: indentation)
//		case "Destructor Declaration":
//			result = translate(
//				destructorDeclaration: subtree,
//				withIndentation: indentation)
//		case "Enum Declaration":
//			result = translate(
//				enumDeclaration: subtree,
//				withIndentation: indentation)
//		case "Extension Declaration":
//			diagnostics?.logSuccessfulTranslation(subtree.name)
//			result = translate(
//				subtrees: subtree.subtrees,
//				withIndentation: indentation)
//		case "For Each Statement":
//			result = translate(
//				forEachStatement: subtree,
//				withIndentation: indentation)
		case "Function Declaration":
			result = translate(functionDeclaration: subtree)
//		case "Protocol":
//			result = translate(
//				protocolDeclaration: subtree,
//				withIndentation: indentation)
//		case "Throw Statement":
//			result = translate(
//				throwStatement: subtree,
//				withIndentation: indentation)
//		case "Struct Declaration":
//			result = translate(
//				structDeclaration: subtree,
//				withIndentation: indentation)
		case "Variable Declaration":
			result = translate(variableDeclaration: subtree)
//		case "Assign Expression":
//			result = translate(
//				assignExpression: subtree,
//				withIndentation: indentation)
		case "If Statement", "Guard Statement":
			result = translate(ifStatement: subtree)
		case "Pattern Binding Declaration":
			result = process(patternBindingDeclaration: subtree)
		case "Return Statement":
			result = translate(returnStatement: subtree)
//		case "Call Expression":
//			if let string = translate(callExpression: subtree).stringValue {
//				if !string.isEmpty {
//					result = .translation(indentation + string + "\n")
//				}
//				else {
//					// GRYIgnoreNext() results in an empty translation
//					result = .translation("")
//				}
//			}
//			else {
//				result = .failed
//			}
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

		return result
	}

	private func translate(expression: GRYSwiftAST) -> GRYExpression? {
		// Most diagnostics are logged by the child subTrees; others represent wrapper expressions
		// with little value in logging. There are a few expections.

		switch expression.name {
//		case "Array Expression":
//			return translate(arrayExpression: expression)
//		case "Binary Expression":
//			return translate(binaryExpression: expression)
		case "Call Expression":
			return translate(callExpression: expression)
		case "Declaration Reference Expression":
			return translate(declarationReferenceExpression: expression)
//		case "Dot Syntax Call Expression":
//			return translate(dotSyntaxCallExpression: expression)
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
//		case "Prefix Unary Expression":
//			return translate(prefixUnaryExpression: expression)
//		case "Type Expression":
//			return translate(typeExpression: expression)
//		case "Member Reference Expression":
//			return translate(memberReferenceExpression: expression)
//		case "Subscript Expression":
//			return translate(subscriptExpression: expression)
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

	private func translate(returnStatement: GRYSwiftAST) -> GRYReturnStatement? {
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

	private func translate(ifStatement: GRYSwiftAST) -> GRYIfStatement? {
		precondition(ifStatement.name == "If Statement" || ifStatement.name == "Guard Statement")

		let isGuard = (ifStatement.name == "Guard Statement")

		let (letDeclarations, conditions) = translateDeclarationsAndConditions(
			forIfStatement: ifStatement)!

		let braceStatement: GRYSwiftAST
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
		forIfStatement ifStatement: GRYSwiftAST)
		-> (declarations: [GRYDeclaration], conditions: [GRYExpression])?
	{
		precondition(ifStatement.name == "If Statement" || ifStatement.name == "Guard Statement")

		var conditionsResult = [GRYExpression]()
		var declarationsResult = [GRYDeclaration]()

		let conditions = ifStatement.subtrees.filter {
			$0.name != "If Statement" && $0.name != "Brace Statement"
		}

		for condition in conditions {
			// If it's an if-let
			if condition.name == "Pattern",
				let optionalSomeElement = condition.subtree(named: "Optional Some Element")
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
					return nil
				}

				let type: String
				if let rawType = optionalSomeElement["type"] {
					type = translateType(rawType)
				}
				else {
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

	private func translate(functionDeclaration: GRYSwiftAST) -> GRYFunctionDeclaration? {
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

		// Translate the parameters
		if let parameterList = parameterList {
			for parameter in parameterList.subtrees {
				if let name = parameter.standaloneAttributes.first,
					let rawType = parameter["interface type"]
				{
					guard name != "self" else {
						continue
					}

					let type = translateType(rawType)
					parameterNames.append(name)
					parameterTypes.append(type)
				}
				else {
					return nil
				}
			}
		}

		let returnType: String
		// Translate the return type
		// TODO: Doesn't allow to return function types
		if let rawType = functionDeclaration["interface type"]?
			.split(withStringSeparator: " -> ").last
		{
			returnType = translateType(rawType)
		}
		else {
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

		// FIXME: Not sure if access defaults to internal
		return GRYFunctionDeclaration(
			prefix: String(functionNamePrefix),
			parameterNames: parameterNames,
			parameterTypes: parameterTypes,
			returnType: returnType,
			isImplicit: isImplicit,
			statements: statements,
			access: access ?? "internal")
	}

	private func process(patternBindingDeclaration: GRYSwiftAST) -> GRYTopLevelNode? {
		precondition(patternBindingDeclaration.name == "Pattern Binding Declaration")

		// Some patternBindingDeclarations are empty, and that's ok. See the classes.swift test
		// case.
		guard let expression = patternBindingDeclaration.subtrees.last,
			ASTIsExpression(expression) else
		{
			return nil
		}

		let translatedExpression = translate(expression: expression)

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
			assertionFailure("Expected to always work")
			return nil
		}

		guard let identifier = binding.standaloneAttributes.first,
			let rawType = binding.keyValueAttributes["type"] else
		{
			assertionFailure("Expected to always work")
			return nil
		}

		let type = translateType(rawType)

		danglingPatternBinding =
			(identifier: identifier,
			 type: type,
			 expression: translatedExpression)

		return nil
	}

	private func translate(topLevelCode: GRYSwiftAST) -> GRYTopLevelNode? {
		precondition(topLevelCode.name == "Top Level Code Declaration")

		guard let braceStatement = topLevelCode.subtree(named: "Brace Statement") else {
			fatalError("Expected to always work")
		}

		let subtrees = translate(subtrees: braceStatement.subtrees)
		assert(subtrees.count <= 1)
		return subtrees.first
	}

	private func translate(variableDeclaration: GRYSwiftAST) -> GRYTopLevelNode? {
		precondition(variableDeclaration.name == "Variable Declaration")

		let expression: GRYExpression?
		let getter: GRYFunctionDeclaration?
		let setter: GRYFunctionDeclaration?
		let isLet: Bool
		let extendsType: String?

		if let identifier = variableDeclaration.standaloneAttributes.first,
			let rawType = variableDeclaration["interface type"]
		{
			let type = translateType(rawType)

//			let hasGetter = variableDeclaration.subtrees.contains(where:
//			{ (subtree: GRYSwiftAST) -> Bool in
//				subtree.name == "Function Declaration" &&
//					!subtree.standaloneAttributes.contains("implicit") &&
//					subtree.keyValueAttributes["getter_for"] != nil
//			})
//			let hasSetter = variableDeclaration.subtrees.contains(where:
//			{ (subtree: GRYSwiftAST) -> Bool in
//				subtree.name == "Function Declaration" &&
//					!subtree.standaloneAttributes.contains("implicit") &&
//					subtree.keyValueAttributes["setter_for"] != nil
//			})

			isLet = variableDeclaration.standaloneAttributes.contains("let")
			extendsType = variableDeclaration["extends_type"]

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

//			result += translateGetterAndSetter(
//				forVariableDeclaration: variableDeclaration,
//				withIndentation: indentation)
			getter = nil
			setter = nil

			return GRYVariableDeclaration(
				expression: expression,
				identifier: identifier,
				type: type,
				getter: getter,
				setter: setter,
				isLet: isLet,
				extendsType: extendsType)
		}
		else {
			return nil
		}
	}

	private func translate(callExpression: GRYSwiftAST) -> GRYExpression? {
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
//			else if let typeExpression = callExpression
//				.subtree(named: "Constructor Reference Call Expression")?
//				.subtree(named: "Type Expression")
//			{
//				if let expression = translate(typeExpression: typeExpression) {
//					function = expression
//				}
//				else {
//					return nil
//				}
//			}
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

	private func translate(callExpressionParameters callExpression: GRYSwiftAST)
		-> GRYTupleExpression?
	{
		let parameters: GRYTupleExpression
		if let parenthesesExpression = callExpression.subtree(named: "Parentheses Expression") {
			let expression = translate(expression: parenthesesExpression)!
			parameters = [(name: nil, expression: expression)]
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
				parameters = [(name: nil, expression: expression)]
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

	private func translate(tupleExpression: GRYSwiftAST) -> GRYTupleExpression? {
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
				tuplePairs.append((name: nil, expression: expression))
			}
			else {
				tuplePairs.append((name: String(name), expression: expression))
			}
		}

		return GRYTupleExpression(pairs: tuplePairs)
	}

	private func translate(asNumericLiteral callExpression: GRYSwiftAST) -> GRYExpression? {
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

	private func translate(asBooleanLiteral callExpression: GRYSwiftAST) -> GRYExpression? {
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

	private func translate(stringLiteralExpression: GRYSwiftAST) -> GRYLiteralExpression<String>? {
		if let value = stringLiteralExpression["value"] {
			return GRYLiteralExpression(value: value)
		}
		else {
			return nil
		}
	}

	private func translate(interpolatedStringLiteralExpression: GRYSwiftAST)
		-> GRYInterpolatedStringLiteralExpression?
	{
		precondition(
			interpolatedStringLiteralExpression.name == "Interpolated String Literal Expression")

		var expressions = [GRYExpression]()

		for expression in interpolatedStringLiteralExpression.subtrees {
			if expression.name == "String Literal Expression" {
				guard let quotedString = translate(stringLiteralExpression: expression)?.value else
				{
					return nil
				}

				let unquotedString = quotedString.dropLast().dropFirst()

				// Empty strings, as a special case, are represented by the swift ast dump
				// as two double quotes with nothing between them, instead of an actual empty string
				guard unquotedString != "\"\"" else {
					continue
				}

				expressions.append(GRYLiteralExpression(value: String(unquotedString)))
			}
			else {
				expressions.append(translate(expression: expression)!)
			}
		}

		return GRYInterpolatedStringLiteralExpression(expressions: expressions)
	}

	private func translate(declarationReferenceExpression: GRYSwiftAST)
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

	private func ASTIsExpression(_ ast: GRYSwiftAST) -> Bool {
		return ast.name.hasSuffix("Expression") || ast.name == "Inject Into Optional"
	}

	private func translateType(_ type: String) -> String {
		if type.hasPrefix("[") {
			let innerType = String(type.dropLast().dropFirst())
			let translatedInnerType = translateType(innerType)
			return "MutableList<\(translatedInnerType)>"
		}
		else if type.hasPrefix("ArrayReference<") {
			let innerType = String(type.dropLast().dropFirst("ArrayReference<".count))
			let translatedInnerType = translateType(innerType)
			return "MutableList<\(translatedInnerType)>"
		}
		else {
			return GRYKotlinTranslator.typeMappings[type] ?? type
		}
	}
}
