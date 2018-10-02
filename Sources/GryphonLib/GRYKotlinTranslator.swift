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

public class GRYKotlinTranslator {
	/// Used for the translation of Swift types into Kotlin types.
	static let typeMappings = ["Bool": "Boolean", "Error": "Exception"]

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

	/**
	This variable is used to store enum definitions in order to allow the translator
	to translate them as sealed classes (see the `translate(dotSyntaxCallExpression)` method).
	*/
	private static var enums = [String]()

	public static func addEnum(_ enumName: String) {
		enums.append(enumName)
	}

	/**
	This variable is used to allow calls to the `GRYIgnoreNext` function to ignore
	the next swift statement. When a call to that function is detected, this variable is set
	to true. Then, when the next statement comes along, the translator will see that this
	variable is set to true, ignore that statement, and then reset it to false to continue
	translation.
	*/
	private var shouldIgnoreNext = false

	// MARK: - Interface

	public func translateAST(_ sourceFile: GRYAst) -> String {
		let declarationsTranslation =
			translate(subtrees: sourceFile.declarations, withIndentation: "")

		let indentation = increaseIndentation("")
		let statementsTranslation =
			translate(subtrees: sourceFile.statements, withIndentation: indentation)

		var result = declarationsTranslation

		guard !statementsTranslation.isEmpty else {
			return result
		}

		// Add newline between declarations and the main function, if needed
		if !declarationsTranslation.isEmpty {
			result += "\n"
		}

		result += "fun main(args: Array<String>) {\n\(statementsTranslation)}\n"

		return result
	}

	// MARK: - Implementation

	private func translate(subtree: GRYTopLevelNode, withIndentation indentation: String)
		-> String
	{
		let result: String

		switch subtree {
		case .importDeclaration(name: _):
			result = ""
		case let .classDeclaration(name: name, inherits: inherits, members: members):
			result = translateClassDeclaration(
				name: name, inherits: inherits, members: members, withIndentation: indentation)
		case let .enumDeclaration(
			access: access, name: name, inherits: inherits, elements: elements):

			result = translateEnumDeclaration(
				access: access, name: name, inherits: inherits, elements: elements,
				withIndentation: indentation)
		case let .forEachStatement(
			collection: collection, variable: variable, statements: statements):

			result = translateForEachStatement(
				collection: collection, variable: variable, statements: statements,
				withIndentation: indentation)
		case let .functionDeclaration(
			prefix: prefix, parameterNames: parameterNames, parameterTypes: parameterTypes,
			returnType: returnType, isImplicit: isImplicit, statements: statements, access: access):

			result = translateFunctionDeclaration(
				prefix: prefix, parameterNames: parameterNames, parameterTypes: parameterTypes,
				returnType: returnType, isImplicit: isImplicit, statements: statements,
				access: access, withIndentation: indentation)
		case let .protocolDeclaration(name: name):
			result = translateProtocolDeclaration(name: name, withIndentation: indentation)
		case let .throwStatement(expression: expression):
			result = translateThrowStatement(expression: expression, withIndentation: indentation)
		case .structDeclaration(name: _):
			return ""
		case let .variableDeclaration(
			identifier: identifier, typeName: typeName, expression: expression, getter: getter,
			setter: setter, isLet: isLet, extendsType: extendsType):

			result = translateVariableDeclaration(
				identifier: identifier, typeName: typeName, expression: expression, getter: getter,
				setter: setter, isLet: isLet, extendsType: extendsType,
				withIndentation: indentation)
		case let .assignmentStatement(leftHand: leftHand, rightHand: rightHand):
			result = translateAssignmentStatement(
				leftHand: leftHand, rightHand: rightHand, withIndentation: indentation)
		case let .ifStatement(
			conditions: conditions, declarations: declarations, statements: statements,
			elseStatement: elseStatement, isGuard: isGuard):

			result = translateIfStatement(
				conditions: conditions, declarations: declarations, statements: statements,
				elseStatement: elseStatement, isGuard: isGuard, isElseIf: false,
				withIndentation: indentation)
		case let .returnStatement(expression: expression):
			result = translateReturnStatement(expression: expression, withIndentation: indentation)
		case let .expression(expression: expression):
			let expressionTranslation = translateExpression(expression)
			if !expressionTranslation.isEmpty {
				return indentation + expressionTranslation + "\n"
			}
			else {
				return ""
			}
		}

		return result
	}

	private func translate(subtrees: [GRYTopLevelNode], withIndentation indentation: String)
		-> String
	{
		var result = ""

		for subtree in subtrees {
			if shouldIgnoreNext {
				shouldIgnoreNext = false
				continue
			}

			result += translate(subtree: subtree, withIndentation: indentation)
		}

		return result
	}

	private func translateEnumDeclaration(
		access: String?, name: String, inherits: [String], elements: [String],
		withIndentation indentation: String) -> String
	{
		guard !inherits.contains("GRYIgnore") else {
			return ""
		}

		var result: String

		if let access = access {
			result = "\(indentation)\(access) sealed class " + name
		}
		else {
			result = "\(indentation)sealed class " + name
		}

		if !inherits.isEmpty {
			var translatedInheritedTypes = inherits.map(translateType)
			translatedInheritedTypes[0] = translatedInheritedTypes[0] + "()"
			result += ": \(translatedInheritedTypes.joined(separator: ", "))"
		}

		result += " {\n"

		let increasedIndentation = increaseIndentation(indentation)

		for element in elements {
			let capitalizedElementName = element.capitalizedAsCamelCase

			result += "\(increasedIndentation)class \(capitalizedElementName): \(name)()\n"
		}

		result += "\(indentation)}\n"

		return result
	}

	private func translateProtocolDeclaration(name: String, withIndentation indentation: String)
		-> String
	{
		precondition(name == "GRYIgnore")
		return ""
	}

	private func translateClassDeclaration(
		name: String, inherits: [String], members: [GRYTopLevelNode],
		withIndentation indentation: String) -> String
	{

		guard !inherits.contains("GRYIgnore") else {
			return ""
		}

		var result = "\(indentation)class \(name)"

		if !inherits.isEmpty {
			let translatedInheritances = inherits.map(translateType)
			result += ": " + translatedInheritances.joined(separator: ", ")
		}

		result += " {\n"

		let increasedIndentation = increaseIndentation(indentation)

		let classContents = translate(
			subtrees: members,
			withIndentation: increasedIndentation)

		result += classContents + "\(indentation)}\n"

		return result
	}

	private func translateFunctionDeclaration(
		prefix: String, parameterNames: [String], parameterTypes: [String], returnType: String,
		isImplicit: Bool, statements: [GRYTopLevelNode], access: String?,
		withIndentation indentation: String) -> String
	{
		guard !isImplicit else {
			return ""
		}

		guard prefix != "GRYInsert",
			prefix != "GRYAlternative",
			prefix != "GRYIgnoreNext" else
		{
			return ""
		}

		// If it's GRYDeclarations, we want to add its contents as top-level statements
		guard prefix != "GRYDeclarations" else {
			return translate(subtrees: statements, withIndentation: indentation)
		}

		var indentation = indentation
		var result = indentation

		if let access = access {
			result += access + " "
		}

		result += "fun "

		result += prefix + "("

		let parameters = zip(parameterNames, parameterTypes).map { $0.0 + ": " + $0.1 }

		result += parameters.joined(separator: ", ")

		result += ")"

		if returnType != "()" {
			let translatedReturnType = translateType(returnType)
			result += ": \(translatedReturnType)"
		}

		result += " {\n"

		indentation = increaseIndentation(indentation)

		result += translate(subtrees: statements, withIndentation: indentation)

		indentation = decreaseIndentation(indentation)
		result += indentation + "}\n"

		return result
	}

	private func translateForEachStatement(
		collection: GRYExpression, variable: GRYExpression, statements: [GRYTopLevelNode],
		withIndentation indentation: String) -> String
	{
		var result = "\(indentation)for ("

		let variableTranslation = translateExpression(variable)

		result += variableTranslation + " in "

		let collectionTranslation = translateExpression(collection)

		result += collectionTranslation + ") {\n"

		let increasedIndentation = increaseIndentation(indentation)
		let statementsTranslation = translate(
			subtrees: statements, withIndentation: increasedIndentation)

		result += statementsTranslation

		result += indentation + "}\n"
		return result
	}

	private func translateIfStatement(
		conditions: [GRYExpression], declarations: [GRYTopLevelNode], statements: [GRYTopLevelNode],
		elseStatement: GRYTopLevelNode?, isGuard: Bool, isElseIf: Bool,
		withIndentation indentation: String) -> String
	{
		let declarationsTranslation =
			translate(subtrees: declarations, withIndentation: indentation)

		var result = declarationsTranslation + indentation

		let keyword = (conditions.isEmpty && declarations.isEmpty) ?
			"else" :
			(isElseIf ? "else if" : "if")

		result += keyword + " "

		let increasedIndentation = increaseIndentation(indentation)

		// TODO: Turn this into an ast pass
		let explicitConditionsTranslations = conditions.map(translateExpression)
		let declarationConditionsTranslations = declarations.map
		{ (declaration: GRYTopLevelNode) -> String in
			guard case let .variableDeclaration(
				identifier: identifier, typeName: _, expression: _, getter: _, setter: _, isLet: _,
				extendsType: _) = declaration else
			{
				preconditionFailure()
			}
			return identifier + " != null"
		}
		let allConditions = declarationConditionsTranslations + explicitConditionsTranslations
		let conditionsTranslation = allConditions.joined(separator: " && ")

		if keyword != "else" {
			let parenthesizedCondition = isGuard ?
				("(!(" + conditionsTranslation + ")) ") :
				("(" + conditionsTranslation + ") ")

			result += parenthesizedCondition
		}

		result += "{\n"

		let statementsString =
			translate(subtrees: statements, withIndentation: increasedIndentation)

		result += statementsString + indentation + "}\n"

		if let unwrappedElse = elseStatement {
			guard case let .ifStatement(
				conditions: conditions, declarations: declarations, statements: statements,
				elseStatement: elseStatement, isGuard: isGuard) = unwrappedElse else
			{
				preconditionFailure()
			}
			result += translateIfStatement(
				conditions: conditions, declarations: declarations, statements: statements,
				elseStatement: elseStatement, isGuard: isGuard, isElseIf: true,
				withIndentation: indentation)
		}

		return result
	}

	private func translateThrowStatement(
		expression: GRYExpression, withIndentation indentation: String) -> String
	{
		let expressionString = translateExpression(expression)
		return "\(indentation)throw \(expressionString)\n"
	}

	private func translateReturnStatement(
		expression: GRYExpression?, withIndentation indentation: String) -> String
	{
		if let expression = expression {
			let expressionString = translateExpression(expression)
			return "\(indentation)return \(expressionString)\n"
		}
		else {
			return "\(indentation)return\n"
		}
	}

	private func translateVariableDeclaration(
		identifier: String, typeName: String, expression: GRYExpression?, getter: GRYTopLevelNode?,
		setter: GRYTopLevelNode?, isLet: Bool, extendsType: String?,
		withIndentation indentation: String) -> String
	{
		var result = indentation

		var keyword: String
		if getter != nil && setter != nil {
			keyword = "var"
		}
		else if getter != nil && setter == nil {
			keyword = "val"
		}
		else {
			if isLet {
				keyword = "val"
			}
			else {
				keyword = "var"
			}
		}

		result += "\(keyword) "

		let extensionPrefix: String
		if let extendsType = extendsType {
			let translatedExtendedType = translateType(extendsType)
			extensionPrefix = "\(translatedExtendedType)."
		}
		else {
			extensionPrefix = ""
		}

		result += "\(extensionPrefix)\(identifier): "

		let translatedType = translateType(typeName)
		result += translatedType

		if let expression = expression {
			let expressionTranslation = translateExpression(expression)
			result += " = " + expressionTranslation
		}

		result += "\n"

		let indentation1 = increaseIndentation(indentation)
		let indentation2 = increaseIndentation(indentation1)
		if let getter = getter {
			guard case let .functionDeclaration(
				prefix: _, parameterNames: _, parameterTypes: _, returnType: _, isImplicit: _,
				statements: statements, access: _) = getter else
			{
				preconditionFailure()
			}

			result += indentation1 + "get() {\n"
			result += translate(subtrees: statements, withIndentation: indentation2)
			result += indentation1 + "}\n"
		}

		if let setter = setter {
			guard case let .functionDeclaration(
				prefix: _, parameterNames: _, parameterTypes: _, returnType: _, isImplicit: _,
				statements: statements, access: _) = setter else
			{
				preconditionFailure()
			}

			result += indentation1 + "set(newValue) {\n"
			result += translate(subtrees: statements, withIndentation: indentation2)
			result += indentation1 + "}\n"
		}

		return result
	}

	private func translateAssignmentStatement(
		leftHand: GRYExpression, rightHand: GRYExpression, withIndentation indentation: String)
		-> String
	{
		let leftTranslation = translateExpression(leftHand)
		let rightTranslation = translateExpression(rightHand)
		return "\(indentation)\(leftTranslation) = \(rightTranslation)\n"
	}

	private func translateExpression(_ expression: GRYExpression) -> String {
		switch expression {
		case let .arrayExpression(elements: elements):
			return translateArrayExpression(elements: elements)
		case let .binaryOperatorExpression(
			leftExpression: leftExpression,
			rightExpression: rightExpression,
			operatorSymbol: operatorSymbol,
			type: type):

			return translateBinaryOperatorExpression(
				leftExpression: leftExpression,
				rightExpression: rightExpression,
				operatorSymbol: operatorSymbol,
				type: type)
		case let .callExpression(function: function, parameters: parameters, type: type):
			return translateCallExpression(function: function, parameters: parameters, type: type)
		case let .declarationReferenceExpression(identifier: identifier, type: type):
			return translateDeclarationReferenceExpression(identifier: identifier, type: type)
		case let .dotExpression(leftExpression: leftExpression, rightExpression: rightExpression):
			return translateDotSyntaxCallExpression(
				leftExpression: leftExpression, rightExpression: rightExpression)
		case let .literalStringExpression(value: value):
			return translateStringLiteral(value: value)
		case let .interpolatedStringLiteralExpression(expressions: expressions):
			return translateInterpolatedStringLiteralExpression(expressions: expressions)
		case let .unaryOperatorExpression(
			expression: expression, operatorSymbol: operatorSymbol, type: type):

			return translatePrefixUnaryExpression(
				expression: expression, operatorSymbol: operatorSymbol, type: type)
		case let .typeExpression(type: type):
			return translateType(type)
		case let .subscriptExpression(
			subscriptedExpression: subscriptedExpression, indexExpression: indexExpression):

			return translateSubscriptExpression(
				subscriptedExpression: subscriptedExpression, indexExpression: indexExpression)
		case let .parenthesesExpression(expression: expression):
			return "(" + translateExpression(expression) + ")"
		case let .forceValueExpression(expression: expression):
			return translateExpression(expression) + "!!"
		case let .literalIntExpression(value: value):
			return String(value)
		case let .literalDoubleExpression(value: value):
			return String(value)
		case let .literalBoolExpression(value: value):
			return String(value)
		case .nilLiteralExpression:
			return "null"
		case let .tupleExpression(pairs: pairs):
			return translateTupleExpression(pairs: pairs)
		}
	}

	private func translateSubscriptExpression(
		subscriptedExpression: GRYExpression, indexExpression: GRYExpression) -> String
	{
		return translateExpression(subscriptedExpression) +
			"[\(translateExpression(indexExpression))]"
	}

	private func translateArrayExpression(elements: [GRYExpression]) -> String {
		let expressionsString = elements.map {
			translateExpression($0)
		}.joined(separator: ", ")

		return "mutableListOf(\(expressionsString))"
	}

	private func translateDotSyntaxCallExpression(
		leftExpression: GRYExpression, rightExpression: GRYExpression) -> String
	{
		let leftHandString = translateExpression(leftExpression)
		let rightHandString = translateExpression(rightExpression)

		if GRYKotlinTranslator.enums.contains(leftHandString) {
			let capitalizedEnumCase = rightHandString.capitalizedAsCamelCase
			return "\(leftHandString).\(capitalizedEnumCase)()"
		}
		else {
			return "\(leftHandString).\(rightHandString)"
		}
	}

	private func translateBinaryOperatorExpression(
		leftExpression: GRYExpression, rightExpression: GRYExpression, operatorSymbol: String,
		type: String) -> String
	{
		let leftTranslation = translateExpression(leftExpression)
		let rightTranslation = translateExpression(rightExpression)
		return "\(leftTranslation) \(operatorSymbol) \(rightTranslation)"
	}

	private func translatePrefixUnaryExpression(
		expression: GRYExpression, operatorSymbol: String, type: String) -> String
	{
		let expressionTranslation = translateExpression(expression)
		return operatorSymbol + expressionTranslation
	}

	private func translateCallExpression(
		function: GRYExpression, parameters: GRYExpression, type: String) -> String
	{
		guard case let .tupleExpression(pairs: pairs) = parameters else {
			preconditionFailure()
		}

		let functionTranslation = translateExpression(function)

		if functionTranslation == "GRYInsert" || functionTranslation == "GRYAlternative" {
			return translateAsKotlinLiteral(
				functionTranslation: functionTranslation,
				parameters: parameters)
		}
		else if functionTranslation == "GRYIgnoreNext" {
			shouldIgnoreNext = true
			return ""
		}

		let parametersTranslation = translateTupleExpression(pairs: pairs)

		return functionTranslation + parametersTranslation
	}

	private func translateAsKotlinLiteral(
		functionTranslation: String,
		parameters: GRYExpression) -> String
	{
		let string: String
		if case let .tupleExpression(pairs: pairs) = parameters,
			let lastPair = pairs.last
		{
			if case let .literalStringExpression(value: value) = lastPair.expression {
				string = value
			}
			else {
				preconditionFailure()
			}

			let unescapedString = removeBackslashEscapes(string)
			return unescapedString
		}

		preconditionFailure()
	}

	private func translateDeclarationReferenceExpression(identifier: String, type: String) -> String {
		return String(identifier.prefix { $0 != "(" })
	}

	private func translateTupleExpression(pairs: [GRYExpression.TuplePair]) -> String {
		guard !pairs.isEmpty else {
			return "()"
		}

		let contents = pairs.map { (pair: GRYExpression.TuplePair) -> String in

			// TODO: Turn this into an Ast pass
			let expression: String
			if case let .parenthesesExpression(expression: innerExpression) = pair.expression {
				expression = translateExpression(innerExpression)
			}
			else {
				expression = translateExpression(pair.expression)
			}

			if let name = pair.name {
				return "\(name) = \(expression)"
			}
			else {
				return expression
			}
		}.joined(separator: ", ")

		return "(\(contents))"
	}

	private func translateStringLiteral(value: String) -> String {
		return "\"\(value)\""
	}

	private func translateInterpolatedStringLiteralExpression(expressions: [GRYExpression])
		-> String
	{
		var result = "\""

		for expression in expressions {
			if case let .literalStringExpression(value: string) = expression {
				// Empty strings, as a special case, are represented by the swift ast dump
				// as two double quotes with nothing between them, instead of an actual empty string
				guard string != "\"\"" else {
					continue
				}

				result += string
			}
			else {
				result += "${" + translateExpression(expression) + "}"
			}
		}

		result += "\""

		return result
	}

	// MARK: - Supporting methods
	private func removeBackslashEscapes(_ string: String) -> String {
		var result = ""

		var isEscaping = false
		for character in string {
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

extension String {
	var capitalizedAsCamelCase: String {
		let firstCharacter = self.first!
		let capitalizedFirstCharacter = String(firstCharacter).uppercased()
		return String(capitalizedFirstCharacter + self.dropFirst())
	}
}
