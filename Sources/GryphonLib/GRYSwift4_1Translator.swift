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

	private func translate(subtrees: [GRYSwiftAST]) -> [GRYAst] {
		return subtrees.compactMap { translate(subtree: $0) }
	}

	private func translate(subtree: GRYSwiftAST) -> GRYAst? {
		var result: GRYAst?

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
//		case "Function Declaration":
//			result = translate(
//				functionDeclaration: subtree,
//				withIndentation: indentation)
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
//		case "Guard Statement":
//			result = translate(
//				ifStatement: subtree,
//				asGuard: true,
//				withIndentation: indentation)
//		case "If Statement":
//			result = translate(
//				ifStatement: subtree,
//				withIndentation: indentation)
		case "Pattern Binding Declaration":
			result = process(patternBindingDeclaration: subtree)
//		case "Return Statement":
//			result = translate(
//				returnStatement: subtree,
//				withIndentation: indentation)
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
			result = nil
//			if subtree.name.hasSuffix("Expression") {
//				if let string = translate(expression: subtree).stringValue {
//					result = .translation(indentation + string + "\n")
//				}
//				else {
//					result = .failed
//				}
//			}
//			else {
//				diagnostics?.logUnknownTranslation(subtree.name)
//				result = .failed
//			}
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
//		case "Declaration Reference Expression":
//			return translate(declarationReferenceExpression: expression)
//		case "Dot Syntax Call Expression":
//			return translate(dotSyntaxCallExpression: expression)
//		case "String Literal Expression":
//			return translate(stringLiteralExpression: expression)
//		case "Interpolated String Literal Expression":
//			return translate(interpolatedStringLiteralExpression: expression)
//		case "Erasure Expression":
//			if let lastExpression = expression.subtrees.last {
//				return translate(expression: lastExpression)
//			}
//			else {
//				return .failed
//			}
//		case "Prefix Unary Expression":
//			return translate(prefixUnaryExpression: expression)
//		case "Type Expression":
//			return translate(typeExpression: expression)
//		case "Member Reference Expression":
//			return translate(memberReferenceExpression: expression)
//		case "Subscript Expression":
//			return translate(subscriptExpression: expression)
//		case "Parentheses Expression":
//			if let firstExpression = expression.subtree(at: 0),
//				let expressionString = translate(expression: firstExpression).stringValue
//			{
//				diagnostics?.logSuccessfulTranslation(expression.name)
//				return .translation("(" + expressionString + ")")
//			}
//			else {
//				diagnostics?.logUnknownTranslation(expression.name)
//				return .failed
//			}
//		case "Force Value Expression":
//			if let firstExpression = expression.subtree(at: 0),
//				let expressionString = translate(expression: firstExpression).stringValue
//			{
//				diagnostics?.logSuccessfulTranslation(expression.name)
//				return .translation(expressionString  + "!!")
//			}
//			else {
//				diagnostics?.logUnknownTranslation(expression.name)
//				return .failed
//			}
//		case "Autoclosure Expression",
//			 "Inject Into Optional",
//			 "Inout Expression",
//			 "Load Expression":
//			if let lastExpression = expression.subtrees.last {
//				return translate(expression: lastExpression)
//			}
//			else {
//				return .failed
//			}
		default:
			return nil
		}
	}

	private func process(patternBindingDeclaration: GRYSwiftAST) -> GRYAst? {
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

	private func translate(topLevelCode: GRYSwiftAST) -> GRYAst? {
		precondition(topLevelCode.name == "Top Level Code Declaration")

		guard let braceStatement = topLevelCode.subtree(named: "Brace Statement") else {
			fatalError("Expected to always work")
		}

		let subtrees = translate(subtrees: braceStatement.subtrees)
		assert(subtrees.count <= 1)
		return subtrees.first
	}

	private func translate(variableDeclaration: GRYSwiftAST) -> GRYAst? {
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
		if let argumentLabels = callExpression["arg_labels"],
			argumentLabels == "_builtinIntegerLiteral:"
		{
			return translate(asNumericLiteral: callExpression)
		}

		return nil
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
