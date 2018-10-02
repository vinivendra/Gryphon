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
	fileprivate var parents = [Either<GRYTopLevelNode, GRYExpression>]()
	fileprivate var parent: Either<GRYTopLevelNode, GRYExpression> {
		return parents.secondToLast!
	}

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
		parents.append(.left(node))
		defer { parents.removeLast() }

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
		parents.append(.right(expression))
		defer { parents.removeLast() }

		switch expression {
		case let .literalCodeExpression(string: string):
			return replaceLiteralCodeExpression(string: string)
		case let .parenthesesExpression(expression: expression):
			return replaceParenthesesExpression(expression: expression)
		case let .forceValueExpression(expression: expression):
			return replaceForcevalueExpression(expression: expression)
		case let .declarationReferenceExpression(identifier: identifier, type: type):
			return replaceDeclarationreferenceExpression(identifier: identifier, type: type)
		case let .typeExpression(type: type):
			return replaceTypeExpression(type: type)
		case let .subscriptExpression(
			subscriptedExpression: subscriptedExpression, indexExpression: indexExpression,
			type: type):

			return replaceSubscriptExpression(
				subscriptedExpression: subscriptedExpression, indexExpression: indexExpression,
				type: type)
		case let .arrayExpression(elements: elements, type: type):
			return replaceArrayExpression(elements: elements, type: type)
		case let .dotExpression(leftExpression: leftExpression, rightExpression: rightExpression):
			return replaceDotExpression(
				leftExpression: leftExpression, rightExpression: rightExpression)
		case let .binaryOperatorExpression(
			leftExpression: leftExpression, rightExpression: rightExpression,
			operatorSymbol: operatorSymbol, type: type):

			return replaceBinaryOperatorExpression(
				leftExpression: leftExpression, rightExpression: rightExpression,
				operatorSymbol: operatorSymbol, type: type)
		case let .unaryOperatorExpression(
			expression: expression, operatorSymbol: operatorSymbol, type: type):
			return replaceUnaryOperatorExpression(
				expression: expression, operatorSymbol: operatorSymbol, type: type)
		case let .callExpression(function: function, parameters: parameters, type: type):
			return replaceCallExpression(function: function, parameters: parameters, type: type)
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

	func replaceLiteralCodeExpression(string: String) -> GRYExpression {
		return .literalCodeExpression(string: string)
	}

	func replaceParenthesesExpression(expression: GRYExpression) -> GRYExpression {
		return .parenthesesExpression(expression: replaceExpression(expression))
	}

	func replaceForcevalueExpression(expression: GRYExpression) -> GRYExpression {
		return .forceValueExpression(expression: replaceExpression(expression))
	}

	func replaceDeclarationreferenceExpression(identifier: String, type: String) -> GRYExpression {
		return .declarationReferenceExpression(identifier: identifier, type: type)
	}

	func replaceTypeExpression(type: String) -> GRYExpression {
		return .typeExpression(type: type)
	}

	func replaceSubscriptExpression(
		subscriptedExpression: GRYExpression, indexExpression: GRYExpression, type: String)
		-> GRYExpression
	{
		return .subscriptExpression(
			subscriptedExpression: replaceExpression(subscriptedExpression),
			indexExpression: replaceExpression(indexExpression), type: type)
	}

	func replaceArrayExpression(elements: [GRYExpression], type: String) -> GRYExpression {
		return .arrayExpression(elements: elements.map(replaceExpression), type: type)
	}

	func replaceDotExpression(leftExpression: GRYExpression, rightExpression: GRYExpression)
		-> GRYExpression
	{
		return .dotExpression(
			leftExpression: replaceExpression(leftExpression),
			rightExpression: replaceExpression(rightExpression))
	}

	func replaceBinaryOperatorExpression(
		leftExpression: GRYExpression, rightExpression: GRYExpression, operatorSymbol: String,
		type: String) -> GRYExpression
	{
		return .binaryOperatorExpression(
			leftExpression: replaceExpression(leftExpression),
			rightExpression: replaceExpression(rightExpression),
			operatorSymbol: operatorSymbol,
			type: type)
	}

	func replaceUnaryOperatorExpression(
		expression: GRYExpression, operatorSymbol: String, type: String) -> GRYExpression
	{
		return .unaryOperatorExpression(
			expression: replaceExpression(expression), operatorSymbol: operatorSymbol, type: type)
	}

	func replaceCallExpression(function: GRYExpression, parameters: GRYExpression, type: String)
		-> GRYExpression
	{
		return .callExpression(
			function: replaceExpression(function), parameters: replaceExpression(parameters),
			type: type)
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

public class GRYStandardLibraryTranspilationPass: GRYTranspilationPass {
	override func replaceCallExpression(
		function: GRYExpression, parameters: GRYExpression, type: String) -> GRYExpression
	{
		if case let .declarationReferenceExpression(identifier: identifier, type: _) = function,
			identifier == "print(_:separator:terminator:)"
		{
			return .callExpression(
				function: .declarationReferenceExpression(identifier: "println()", type: ""),
				parameters: replaceExpression(parameters), type: type)
		}
		else {
			return .callExpression(
				function: replaceExpression(function), parameters: replaceExpression(parameters),
				type: type)
		}
	}
}

public class GRYRemoveParenthesesTranspilationPass: GRYTranspilationPass {
	override func replaceParenthesesExpression(expression: GRYExpression) -> GRYExpression {

		if case let .right(parentExpression) = parent {
			switch parentExpression {
			case .tupleExpression, .interpolatedStringLiteralExpression:
				return replaceExpression(expression)
			default:
				break
			}
		}

		return .parenthesesExpression(expression: replaceExpression(expression))
	}
}

public class GRYInsertCodeLiteralsTranspilationPass: GRYTranspilationPass {
	override func replaceCallExpression(
		function: GRYExpression, parameters: GRYExpression, type: String) -> GRYExpression
	{
		if case let .declarationReferenceExpression(identifier: identifier, type: _) = function,
			identifier.hasPrefix("GRYInsert") ||
				identifier.hasPrefix("GRYAlternative"),
			case let .tupleExpression(pairs: pairs) = parameters,
			let lastPair = pairs.last,
			case let .literalStringExpression(value: value) = lastPair.expression
		{
			return .literalCodeExpression(string: value)
		}

		return .callExpression(function: function, parameters: parameters, type: type)
	}
}

public class GRYIgnoreNextTranspilationPass: GRYTranspilationPass {
	var shouldIgnoreNext = false

	override func replaceCallExpression(
		function: GRYExpression, parameters: GRYExpression, type: String) -> GRYExpression
	{
		if case let .declarationReferenceExpression(identifier: identifier, type: _) = function,
			identifier.hasPrefix("GRYIgnoreNext")
		{
			shouldIgnoreNext = true
			return .literalCodeExpression(string: "")
		}

		return .callExpression(function: function, parameters: parameters, type: type)
	}

	override func replaceTopLevelNode(_ node: GRYTopLevelNode) -> GRYTopLevelNode {
		if shouldIgnoreNext {
			shouldIgnoreNext = false
			return .expression(expression: .literalCodeExpression(string: ""))
		}
		else {
			return super.replaceTopLevelNode(node)
		}
	}
}

public class GRYRecordEnumsTranspilationPass: GRYTranspilationPass {
	override func replaceEnumDeclaration(
		access: String?, name: String, inherits: [String], elements: [String]) -> GRYTopLevelNode
	{
		GRYKotlinTranslator.addEnum(name)
		return .enumDeclaration(access: access, name: name, inherits: inherits, elements: elements)
	}
}

public extension GRYTranspilationPass {
	static func runAllPasses(on sourceFile: GRYAst) -> GRYAst {
		var result = sourceFile
		result = GRYRemoveParenthesesTranspilationPass().run(on: result)
		result = GRYIgnoreNextTranspilationPass().run(on: result)
		result = GRYInsertCodeLiteralsTranspilationPass().run(on: result)
		result = GRYStandardLibraryTranspilationPass().run(on: result)
		result = GRYRecordEnumsTranspilationPass().run(on: result)
		return result
	}

	func printParents() {
		print("[")
		for parent in parents {
			switch parent {
			case let .left(node):
				print("\t\(node.name),")
			case let .right(expression):
				print("\t\(expression.name),")
			}
		}
		print("]")
	}
}

private enum Either<Left, Right> {
	case left(_ value: Left)
	case right(_ value: Right)
}
