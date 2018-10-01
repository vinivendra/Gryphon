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

public class GRYTranspilationPass {
	func run(on sourceFile: GRYAst) -> GRYAst {
		var replacedStatements = [GRYTopLevelNode]()
		for statement in sourceFile.statements {
			let replacedStatement = replaceTopLevelNode(statement)
			replacedStatements.append(replacedStatement)
		}

		var replacedDeclarations = [GRYTopLevelNode]()
		for declaration in sourceFile.declarations {
			let replacedDeclaration = replaceTopLevelNode(declaration)
			replacedDeclarations.append(replacedDeclaration)
		}

		return GRYAst(declarations: replacedDeclarations, statements: replacedStatements)
	}

	func replaceTopLevelNode(_ node: GRYTopLevelNode) -> GRYTopLevelNode {
		switch node {
		case let .expression(expression: expression):
			return replaceExpression(expression: expression)
		case let .importDeclaration(name: name):
			return replaceImportDeclaration(name: name)
		case let .classDeclaration(name: name, inherits: inherits, members: members):
			return replaceClassDeclaration(name: name, inherits: inherits, members: members)
		case let .enumDeclaration(
			access: access, name: name, inherits: inherits, elements: elements):

			return replaceEnumDeclaration(
				access: access, name: name, inherits: inherits, elements: elements)
		case let .protocolDeclaration(name: name):
			return replaceProtocolDeclaration(name: name)
		case let .structDeclaration(name: name):
			return replaceStructDeclaration(name: name)
		case let .functionDeclaration(
			prefix: prefix, parameterNames: parameterNames, parameterTypes: parameterTypes,
			returnType: returnType, isImplicit: isImplicit, statements: statements, access: access):

			return replaceFunctionDeclaration(
				prefix: prefix, parameterNames: parameterNames, parameterTypes: parameterTypes,
				returnType: returnType, isImplicit: isImplicit, statements: statements,
				access: access)
		case let .variableDeclaration(
			identifier: identifier, typeName: typeName, expression: expression, getter: getter,
			setter: setter, isLet: isLet, extendsType: extendsType):

			return replaceVariableDeclaration(
				identifier: identifier, typeName: typeName, expression: expression, getter: getter,
				setter: setter, isLet: isLet, extendsType: extendsType)
		case let .forEachStatement(
			collection: collection, variable: variable, statements: statements):

			return replaceForEachStatement(
				collection: collection, variable: variable, statements: statements)
		case let .ifStatement(
			conditions: conditions, declarations: declarations, statements: statements,
			elseStatement: elseStatement, isGuard: isGuard):

			return replaceIfStatement(
				conditions: conditions, declarations: declarations, statements: statements,
				elseStatement: elseStatement, isGuard: isGuard)
		case let .throwStatement(expression: expression):
			return replaceThrowStatement(expression: expression)
		case let .returnStatement(expression: expression):
			return replaceReturnStatement(expression: expression)
		case let .assignmentStatement(leftHand: leftHand, rightHand: rightHand):
			return replaceAssignmentStatement(leftHand: leftHand, rightHand: rightHand)
		}
	}

	func replaceExpression(expression: GRYExpression) -> GRYTopLevelNode {
		return .expression(expression: replaceExpression(expression))
	}

	func replaceImportDeclaration(name: String) -> GRYTopLevelNode {
		return .importDeclaration(name: name)
	}

	func replaceClassDeclaration(name: String, inherits: [String], members: [GRYTopLevelNode])
		-> GRYTopLevelNode
	{
		return .classDeclaration(
			name: name, inherits: inherits, members: members.map(replaceTopLevelNode))
	}

	func replaceEnumDeclaration(
		access: String?, name: String, inherits: [String], elements: [String]) -> GRYTopLevelNode
	{
		return .enumDeclaration(access: access, name: name, inherits: inherits, elements: elements)
	}

	func replaceProtocolDeclaration(name: String) -> GRYTopLevelNode {
		return .protocolDeclaration(name: name)
	}

	func replaceStructDeclaration(name: String) -> GRYTopLevelNode {
		return .structDeclaration(name: name)
	}

	func replaceFunctionDeclaration(
		prefix: String, parameterNames: [String], parameterTypes: [String], returnType: String,
		isImplicit: Bool, statements: [GRYTopLevelNode], access: String?) -> GRYTopLevelNode
	{
		return .functionDeclaration(
			prefix: prefix, parameterNames: parameterNames, parameterTypes: parameterTypes,
			returnType: returnType, isImplicit: isImplicit,
			statements: statements.map(replaceTopLevelNode), access: access)
	}

	func replaceVariableDeclaration(
		identifier: String, typeName: String, expression: GRYExpression?, getter: GRYTopLevelNode?,
		setter: GRYTopLevelNode?, isLet: Bool, extendsType: String?) -> GRYTopLevelNode
	{
		return .variableDeclaration(
			identifier: identifier, typeName: typeName,
			expression: expression.map(replaceExpression),
			getter: getter.map(replaceTopLevelNode),
			setter: setter.map(replaceTopLevelNode),
			isLet: isLet, extendsType: extendsType)
	}

	func replaceForEachStatement(
		collection: GRYExpression, variable: GRYExpression, statements: [GRYTopLevelNode])
		-> GRYTopLevelNode
	{
		return .forEachStatement(
			collection: replaceExpression(collection),
			variable: replaceExpression(variable),
			statements: statements.map(replaceTopLevelNode))
	}

	func replaceIfStatement(
		conditions: [GRYExpression], declarations: [GRYTopLevelNode], statements: [GRYTopLevelNode],
		elseStatement: GRYTopLevelNode?, isGuard: Bool) -> GRYTopLevelNode
	{
		return .ifStatement(
			conditions: conditions.map(replaceExpression),
			declarations: declarations.map(replaceTopLevelNode),
			statements: statements.map(replaceTopLevelNode),
			elseStatement: elseStatement.map(replaceTopLevelNode),
			isGuard: isGuard)
	}

	func replaceThrowStatement(expression: GRYExpression) -> GRYTopLevelNode {
		return .throwStatement(expression: replaceExpression(expression))
	}

	func replaceReturnStatement(expression: GRYExpression?) -> GRYTopLevelNode {
		return .returnStatement(expression: expression.map(replaceExpression))
	}

	func replaceAssignmentStatement(leftHand: GRYExpression, rightHand: GRYExpression)
		-> GRYTopLevelNode
	{
		return .assignmentStatement(
			leftHand: replaceExpression(leftHand), rightHand: replaceExpression(rightHand))
	}

	func replaceExpression(_ expression: GRYExpression) -> GRYExpression {
		switch expression {
		case let .parenthesesExpression(expression: expression):
			return replaceParenthesesExpression(expression: expression)
		case let .forceValueExpression(expression: expression):
			return replaceForcevalueExpression(expression: expression)
		case let .declarationReferenceExpression(identifier: identifier):
			return replaceDeclarationreferenceExpression(identifier: identifier)
		case let .typeExpression(type: type):
			return replaceTypeExpression(type: type)
		case let .subscriptExpression(
			subscriptedExpression: subscriptedExpression, indexExpression: indexExpression):

			return replaceSubscriptExpression(
				subscriptedExpression: subscriptedExpression, indexExpression: indexExpression)
		case let .arrayExpression(elements: elements):
			return replaceArrayExpression(elements: elements)
		case let .dotExpression(leftExpression: leftExpression, rightExpression: rightExpression):
			return replaceDotExpression(
				leftExpression: leftExpression, rightExpression: rightExpression)
		case let .binaryOperatorExpression(
			leftExpression: leftExpression, rightExpression: rightExpression,
			operatorSymbol: operatorSymbol):

			return replaceBinaryOperatorExpression(
				leftExpression: leftExpression, rightExpression: rightExpression,
				operatorSymbol: operatorSymbol)
		case let .unaryOperatorExpression(expression: expression, operatorSymbol: operatorSymbol):
			return replaceUnaryOperatorExpression(
				expression: expression, operatorSymbol: operatorSymbol)
		case let .callExpression(function: function, parameters: parameters):
			return replaceCallExpression(function: function, parameters: parameters)
		case let .literalIntExpression(value: value):
			return replaceLiteralIntExpression(value: value)
		case let .literalDoubleExpression(value: value):
			return replaceLiteralDoubleExpression(value: value)
		case let .literalBoolExpression(value: value):
			return replaceLiteralBoolExpression(value: value)
		case let .literalStringExpression(value: value):
			return replaceLiteralStringExpression(value: value)
		case .nilLiteralExpression:
			return replaceNilLiteralExpression()
		case let .interpolatedStringLiteralExpression(expressions: expressions):
			return replaceInterpolatedStringLiteralExpression(expressions: expressions)
		case let .tupleExpression(pairs: pairs):
			return replaceTupleExpression(pairs: pairs)
		}
	}

	func replaceParenthesesExpression(expression: GRYExpression) -> GRYExpression {
		return .parenthesesExpression(expression: replaceExpression(expression))
	}

	func replaceForcevalueExpression(expression: GRYExpression) -> GRYExpression {
		return .forceValueExpression(expression: replaceExpression(expression))
	}

	func replaceDeclarationreferenceExpression(identifier: String) -> GRYExpression {
		return .declarationReferenceExpression(identifier: identifier)
	}

	func replaceTypeExpression(type: String) -> GRYExpression {
		return .typeExpression(type: type)
	}

	func replaceSubscriptExpression(
		subscriptedExpression: GRYExpression, indexExpression: GRYExpression) -> GRYExpression
	{
		return .subscriptExpression(
			subscriptedExpression: replaceExpression(subscriptedExpression),
			indexExpression: replaceExpression(indexExpression))
	}

	func replaceArrayExpression(elements: [GRYExpression]) -> GRYExpression {
		return .arrayExpression(elements: elements.map(replaceExpression))
	}

	func replaceDotExpression(leftExpression: GRYExpression, rightExpression: GRYExpression)
		-> GRYExpression
	{
		return .dotExpression(
			leftExpression: replaceExpression(leftExpression),
			rightExpression: replaceExpression(rightExpression))
	}

	func replaceBinaryOperatorExpression(
		leftExpression: GRYExpression, rightExpression: GRYExpression, operatorSymbol: String)
		-> GRYExpression
	{
		return .binaryOperatorExpression(
			leftExpression: replaceExpression(leftExpression),
			rightExpression: replaceExpression(rightExpression),
			operatorSymbol: operatorSymbol)
	}

	func replaceUnaryOperatorExpression(expression: GRYExpression, operatorSymbol: String)
		-> GRYExpression
	{
		return .unaryOperatorExpression(
			expression: replaceExpression(expression), operatorSymbol: operatorSymbol)
	}

	func replaceCallExpression(function: GRYExpression, parameters: GRYExpression) -> GRYExpression
	{
		return .callExpression(
			function: replaceExpression(function), parameters: replaceExpression(parameters))
	}

	func replaceLiteralIntExpression(value: Int) -> GRYExpression {
		return .literalIntExpression(value: value)
	}

	func replaceLiteralDoubleExpression(value: Double) -> GRYExpression {
		return .literalDoubleExpression(value: value)
	}

	func replaceLiteralBoolExpression(value: Bool) -> GRYExpression {
		return .literalBoolExpression(value: value)
	}

	func replaceLiteralStringExpression(value: String) -> GRYExpression {
		return .literalStringExpression(value: value)
	}

	func replaceNilLiteralExpression() -> GRYExpression {
		return .nilLiteralExpression
	}

	func replaceInterpolatedStringLiteralExpression(expressions: [GRYExpression]) -> GRYExpression {
		return .interpolatedStringLiteralExpression(expressions: expressions.map(replaceExpression))
	}

	func replaceTupleExpression(pairs: [GRYExpression.TuplePair]) -> GRYExpression {
		return .tupleExpression( pairs: pairs.map {
			GRYExpression.TuplePair(name: $0.name, expression: replaceExpression($0.expression))
		})
	}
}

// TODO: Add a test for this
public class GRYStandardLibraryTranspilationPass: GRYTranspilationPass {
	override func replaceCallExpression(function: GRYExpression, parameters: GRYExpression)
		-> GRYExpression
	{
		if case let .declarationReferenceExpression(identifier: identifier) = function,
			identifier == "print(_:separator:terminator:)"
		{
			return .callExpression(
				function: .declarationReferenceExpression(identifier: "println()"),
				parameters: replaceExpression(parameters))
		}
		else {
			return .callExpression(
				function: replaceExpression(function), parameters: replaceExpression(parameters))
		}
	}
}

public extension GRYTranspilationPass {
	static func runAllPasses(on sourceFile: GRYAst) -> GRYAst {
		var result = sourceFile
		result = GRYStandardLibraryTranspilationPass().run(on: result)
		return result
	}
}
