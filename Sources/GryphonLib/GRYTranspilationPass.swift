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

	func run(on sourceFile: GRYAST) -> GRYAST {
		var replacedStatements = [GRYTopLevelNode]()
		for statement in sourceFile.statements {
			let replacedStatement = replaceTopLevelNode(statement)
			replacedStatements.append(contentsOf: replacedStatement)
		}

		var replacedDeclarations = [GRYTopLevelNode]()
		for declaration in sourceFile.declarations {
			let replacedDeclaration = replaceTopLevelNode(declaration)
			replacedDeclarations.append(contentsOf: replacedDeclaration)
		}

		return GRYAST(declarations: replacedDeclarations, statements: replacedStatements)
	}

	func replaceTopLevelNode(_ node: GRYTopLevelNode) -> [GRYTopLevelNode] {
		parents.append(.left(node))
		defer { parents.removeLast() }

		switch node {
		case let .expression(expression: expression):
			return replaceExpression(expression: expression)
		case let .extensionDeclaration(type: type, members: members):
			return replaceExtension(type: type, members: members)
		case let .importDeclaration(name: name):
			return replaceImportDeclaration(name: name)
		case let .classDeclaration(name: name, inherits: inherits, members: members):
			return replaceClassDeclaration(name: name, inherits: inherits, members: members)
		case let .companionObject(members: members):
			return replaceCompanionObject(members: members)
		case let .enumDeclaration(
			access: access, name: name, inherits: inherits, elements: elements):

			return replaceEnumDeclaration(
				access: access, name: name, inherits: inherits, elements: elements)
		case let .protocolDeclaration(name: name, members: members):
			return replaceProtocolDeclaration(name: name, members: members)
		case let .structDeclaration(name: name):
			return replaceStructDeclaration(name: name)
		case let .functionDeclaration(
			prefix: prefix, parameterNames: parameterNames, parameterTypes: parameterTypes,
			returnType: returnType, isImplicit: isImplicit, isStatic: isStatic,
			statements: statements, access: access):

			return replaceFunctionDeclaration(
				prefix: prefix, parameterNames: parameterNames, parameterTypes: parameterTypes,
				returnType: returnType, isImplicit: isImplicit, isStatic: isStatic,
				statements: statements, access: access)
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

	func replaceExpression(expression: GRYExpression) -> [GRYTopLevelNode] {
		return [.expression(expression: replaceExpression(expression))]
	}

	func replaceExtension(type: String, members: [GRYTopLevelNode]) -> [GRYTopLevelNode] {
		return [.extensionDeclaration(type: type, members: members)]
	}

	func replaceImportDeclaration(name: String) -> [GRYTopLevelNode] {
		return [.importDeclaration(name: name)]
	}

	func replaceClassDeclaration(name: String, inherits: [String], members: [GRYTopLevelNode])
		-> [GRYTopLevelNode]
	{
		return [.classDeclaration(
			name: name, inherits: inherits, members: members.flatMap(replaceTopLevelNode)), ]
	}

	func replaceCompanionObject(members: [GRYTopLevelNode]) -> [GRYTopLevelNode] {
		return [.companionObject(members: members.flatMap(replaceTopLevelNode))]
	}

	func replaceEnumDeclaration(
		access: String?, name: String, inherits: [String], elements: [String]) -> [GRYTopLevelNode]
	{
		return [
			.enumDeclaration(access: access, name: name, inherits: inherits, elements: elements), ]
	}

	func replaceProtocolDeclaration(name: String, members: [GRYTopLevelNode]) -> [GRYTopLevelNode] {
		return [.protocolDeclaration(name: name, members: members.flatMap(replaceTopLevelNode))]
	}

	func replaceStructDeclaration(name: String) -> [GRYTopLevelNode] {
		return [.structDeclaration(name: name)]
	}

	func replaceFunctionDeclaration(
		prefix: String, parameterNames: [String], parameterTypes: [String], returnType: String,
		isImplicit: Bool, isStatic: Bool, statements: [GRYTopLevelNode]?, access: String?)
		-> [GRYTopLevelNode]
	{
		return [.functionDeclaration(
			prefix: prefix, parameterNames: parameterNames, parameterTypes: parameterTypes,
			returnType: returnType, isImplicit: isImplicit, isStatic: isStatic,
			statements: statements.map { $0.flatMap(replaceTopLevelNode) }, access: access), ]
	}

	func replaceVariableDeclaration(
		identifier: String, typeName: String, expression: GRYExpression?, getter: GRYTopLevelNode?,
		setter: GRYTopLevelNode?, isLet: Bool, extendsType: String?) -> [GRYTopLevelNode]
	{
		return [.variableDeclaration(
			identifier: identifier, typeName: typeName,
			expression: expression.map(replaceExpression),
			getter: getter.map(replaceTopLevelNode)?.first,
			setter: setter.map(replaceTopLevelNode)?.first,
			isLet: isLet, extendsType: extendsType), ]
	}

	func replaceForEachStatement(
		collection: GRYExpression, variable: GRYExpression, statements: [GRYTopLevelNode])
		-> [GRYTopLevelNode]
	{
		return [.forEachStatement(
			collection: replaceExpression(collection),
			variable: replaceExpression(variable),
			statements: statements.flatMap(replaceTopLevelNode)), ]
	}

	func replaceIfStatement(
		conditions: [GRYExpression], declarations: [GRYTopLevelNode], statements: [GRYTopLevelNode],
		elseStatement: GRYTopLevelNode?, isGuard: Bool) -> [GRYTopLevelNode]
	{
		return [.ifStatement(
			conditions: conditions.map(replaceExpression),
			declarations: declarations.flatMap(replaceTopLevelNode),
			statements: statements.flatMap(replaceTopLevelNode),
			elseStatement: elseStatement.map(replaceTopLevelNode)?.first,
			isGuard: isGuard), ]
	}

	func replaceThrowStatement(expression: GRYExpression) -> [GRYTopLevelNode] {
		return [.throwStatement(expression: replaceExpression(expression))]
	}

	func replaceReturnStatement(expression: GRYExpression?) -> [GRYTopLevelNode] {
		return [.returnStatement(expression: expression.map(replaceExpression))]
	}

	func replaceAssignmentStatement(leftHand: GRYExpression, rightHand: GRYExpression)
		-> [GRYTopLevelNode]
	{
		return [.assignmentStatement(
			leftHand: replaceExpression(leftHand), rightHand: replaceExpression(rightHand)), ]
	}

	func replaceExpression(_ expression: GRYExpression) -> GRYExpression {
		parents.append(.right(expression))
		defer { parents.removeLast() }

		switch expression {
		case let .templateExpression(pattern: pattern, matches: matches):
			return replaceTemplateExpression(pattern: pattern, matches: matches)
		case let .literalCodeExpression(string: string):
			return replaceLiteralCodeExpression(string: string)
		case let .parenthesesExpression(expression: expression):
			return replaceParenthesesExpression(expression: expression)
		case let .forceValueExpression(expression: expression):
			return replaceForcevalueExpression(expression: expression)
		case let .declarationReferenceExpression(
			identifier: identifier, type: type, isStandardLibrary: isStandardLibrary,
			isImplicit: isImplicit):

			return replaceDeclarationreferenceExpression(
				identifier: identifier, type: type, isStandardLibrary: isStandardLibrary,
				isImplicit: isImplicit)
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

	func replaceTemplateExpression(pattern: String, matches: [String: GRYExpression])
		-> GRYExpression
	{
		return .templateExpression(pattern: pattern, matches: matches.mapValues(replaceExpression))
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

	func replaceDeclarationreferenceExpression(
		identifier: String, type: String, isStandardLibrary: Bool, isImplicit: Bool)
		-> GRYExpression
	{
		return .declarationReferenceExpression(
			identifier: identifier, type: type, isStandardLibrary: isStandardLibrary,
			isImplicit: isImplicit)
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
		if case let .declarationReferenceExpression(
				identifier: identifier, type: _, isStandardLibrary: _, isImplicit: _) = function,
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
		if case let .declarationReferenceExpression(
				identifier: identifier, type: _, isStandardLibrary: _, isImplicit: _) = function,
			identifier.hasPrefix("GRYIgnoreNext")
		{
			shouldIgnoreNext = true
			return .literalCodeExpression(string: "")
		}

		return .callExpression(function: function, parameters: parameters, type: type)
	}

	override func replaceTopLevelNode(_ node: GRYTopLevelNode) -> [GRYTopLevelNode] {
		if shouldIgnoreNext {
			shouldIgnoreNext = false
			return []
		}
		else {
			return super.replaceTopLevelNode(node)
		}
	}
}

public class GRYDeclarationsTranspilationPass: GRYTranspilationPass {
	override func replaceFunctionDeclaration(
		prefix: String, parameterNames: [String], parameterTypes: [String], returnType: String,
		isImplicit: Bool, isStatic: Bool, statements: [GRYTopLevelNode]?, access: String?)
		-> [GRYTopLevelNode]
	{
		if prefix.hasPrefix("GRYDeclarations"), let statements = statements {
			return statements
		}
		else {
			return super.replaceFunctionDeclaration(
				prefix: prefix, parameterNames: parameterNames, parameterTypes: parameterTypes,
				returnType: returnType, isImplicit: isImplicit, isStatic: isStatic,
				statements: statements, access: access)
		}
	}
}

public class GRYRemoveGryphonDeclarationsTranspilationPass: GRYTranspilationPass {
	override func replaceFunctionDeclaration(
		prefix: String, parameterNames: [String], parameterTypes: [String], returnType: String,
		isImplicit: Bool, isStatic: Bool, statements: [GRYTopLevelNode]?, access: String?)
		-> [GRYTopLevelNode]
	{
		if prefix.hasPrefix("GRYInsert") || prefix.hasPrefix("GRYAlternative") ||
			prefix.hasPrefix("GRYIgnoreNext")
		{
			return []
		}
		else {
			return super.replaceFunctionDeclaration(
				prefix: prefix, parameterNames: parameterNames, parameterTypes: parameterTypes,
				returnType: returnType, isImplicit: isImplicit, isStatic: isStatic,
				statements: statements, access: access)
		}
	}

	override func replaceProtocolDeclaration(name: String, members: [GRYTopLevelNode])
		-> [GRYTopLevelNode]
	{
		if name == "GRYIgnore" {
			return []
		}
		else {
			return super.replaceProtocolDeclaration(name: name, members: members)
		}
	}
}

public class GRYRemoveIgnoredDeclarationsTranspilationPass: GRYTranspilationPass {
	override func replaceClassDeclaration(
		name: String, inherits: [String], members: [GRYTopLevelNode]) -> [GRYTopLevelNode]
	{
		if inherits.contains("GRYIgnore") {
			return []
		}
		else {
			return super.replaceClassDeclaration(name: name, inherits: inherits, members: members)
		}
	}

	override func replaceEnumDeclaration(
		access: String?, name: String, inherits: [String], elements: [String]) -> [GRYTopLevelNode]
	{
		if inherits.contains("GRYIgnore") {
			return []
		}
		else {
			return super.replaceEnumDeclaration(
				access: access, name: name, inherits: inherits, elements: elements)
		}
	}
}

public class GRYSelfToThisTranspilationPass: GRYTranspilationPass {
	override func replaceDotExpression(
		leftExpression: GRYExpression, rightExpression: GRYExpression) -> GRYExpression
	{
		if case .declarationReferenceExpression(
			identifier: "self", type: _, isStandardLibrary: _, isImplicit: true) = leftExpression
		{
			return replaceExpression(rightExpression)
		}
		else {
			return .dotExpression(
				leftExpression: replaceExpression(leftExpression),
				rightExpression: replaceExpression(rightExpression))
		}
	}

	override func replaceDeclarationreferenceExpression(
		identifier: String, type: String, isStandardLibrary: Bool, isImplicit: Bool)
		-> GRYExpression
	{
		if identifier == "self" {
			assert(!isImplicit)
			return .declarationReferenceExpression(
				identifier: "this", type: type, isStandardLibrary: isStandardLibrary,
				isImplicit: isImplicit)
		}
		return super.replaceDeclarationreferenceExpression(
			identifier: identifier, type: type, isStandardLibrary: isStandardLibrary,
			isImplicit: isImplicit)
	}
}

public class GRYRemoveExtensionsTranspilationPass: GRYTranspilationPass {
	var extendingType: String?

	override func replaceExtension(type: String, members: [GRYTopLevelNode]) -> [GRYTopLevelNode] {
		extendingType = type
		let members = members.flatMap(replaceTopLevelNode)
		extendingType = nil
		return members
	}

	override func replaceVariableDeclaration(
		identifier: String, typeName: String, expression: GRYExpression?, getter: GRYTopLevelNode?,
		setter: GRYTopLevelNode?, isLet: Bool, extendsType: String?) -> [GRYTopLevelNode]
	{
		return [GRYTopLevelNode.variableDeclaration(
			identifier: identifier, typeName: typeName, expression: expression, getter: getter,
			setter: setter, isLet: isLet, extendsType: self.extendingType), ]
	}
}

public class GRYRecordEnumsTranspilationPass: GRYTranspilationPass {
	override func replaceEnumDeclaration(
		access: String?, name: String, inherits: [String], elements: [String]) -> [GRYTopLevelNode]
	{
		GRYKotlinTranslator.addEnum(name)
		return [.enumDeclaration(
			access: access, name: name, inherits: inherits, elements: elements), ]
	}
}

public class GRYRaiseStandardLibraryWarningsTranspilationPass: GRYTranspilationPass {
	override func replaceDeclarationreferenceExpression(
		identifier: String, type: String, isStandardLibrary: Bool, isImplicit: Bool)
		-> GRYExpression
	{
		if isStandardLibrary {
			GRYTranspilationPass.recordWarning(
				"Reference to standard library \"\(identifier)\" was not translated.")
		}
		return super.replaceDeclarationreferenceExpression(
			identifier: identifier, type: type, isStandardLibrary: isStandardLibrary,
			isImplicit: isImplicit)
	}
}

public class GRYRearrangeIfLetsTranspilationPass: GRYTranspilationPass {
	override func replaceIfStatement(
		conditions: [GRYExpression], declarations: [GRYTopLevelNode], statements: [GRYTopLevelNode],
		elseStatement: GRYTopLevelNode?, isGuard: Bool) -> [GRYTopLevelNode]
	{
		var letConditions = [GRYExpression]()
		var letDeclarations = [GRYTopLevelNode]()
		var remainingDeclarations = [GRYTopLevelNode]()

		for declaration in declarations {
			if case let .variableDeclaration(
				identifier: identifier, typeName: typeName, expression: _, getter: _, setter: _,
				isLet: _, extendsType: _) = declaration
			{
				letDeclarations.append(declaration)
				letConditions.append(
					.binaryOperatorExpression(
						leftExpression: .declarationReferenceExpression(
							identifier: identifier, type: typeName, isStandardLibrary: false,
							isImplicit: false),
						rightExpression: .nilLiteralExpression, operatorSymbol: "!=",
						type: "Boolean"))
			}
			else {
				remainingDeclarations.append(declaration)
			}
		}

		return letDeclarations + super.replaceIfStatement(
			conditions: letConditions + conditions, declarations: remainingDeclarations,
			statements: statements, elseStatement: elseStatement, isGuard: isGuard)
	}
}

public class GRYFixProtocolContentsTranspilationPass: GRYTranspilationPass {
	var isInProtocol = false

	override func replaceProtocolDeclaration(
		name: String, members: [GRYTopLevelNode]) -> [GRYTopLevelNode]
	{
		isInProtocol = true
		let result = super.replaceProtocolDeclaration(name: name, members: members)
		isInProtocol = false

		return result
	}

	override func replaceFunctionDeclaration(
		prefix: String, parameterNames: [String], parameterTypes: [String], returnType: String,
		isImplicit: Bool, isStatic: Bool, statements: [GRYTopLevelNode]?, access: String?)
		-> [GRYTopLevelNode]
	{
		if isInProtocol {
			return super.replaceFunctionDeclaration(
				prefix: prefix, parameterNames: parameterNames, parameterTypes: parameterTypes,
				returnType: returnType, isImplicit: isImplicit, isStatic: isStatic,
				statements: nil, access: access)
		}
		else {
			return super.replaceFunctionDeclaration(
				prefix: prefix, parameterNames: parameterNames, parameterTypes: parameterTypes,
				returnType: returnType, isImplicit: isImplicit, isStatic: isStatic,
				statements: statements, access: access)
		}
	}
}

public extension GRYTranspilationPass {
	static func runAllPasses(on sourceFile: GRYAST) -> GRYAST {
		var result = sourceFile
		result = GRYLibraryTranspilationPass().run(on: result)
		result = GRYRemoveGryphonDeclarationsTranspilationPass().run(on: result)
		result = GRYRemoveIgnoredDeclarationsTranspilationPass().run(on: result)
		result = GRYRemoveParenthesesTranspilationPass().run(on: result)
		result = GRYIgnoreNextTranspilationPass().run(on: result)
		result = GRYInsertCodeLiteralsTranspilationPass().run(on: result)
		result = GRYDeclarationsTranspilationPass().run(on: result)

		result = GRYFixProtocolContentsTranspilationPass().run(on: result)
		result = GRYSelfToThisTranspilationPass().run(on: result)
		result = GRYRemoveExtensionsTranspilationPass().run(on: result)
		result = GRYRearrangeIfLetsTranspilationPass().run(on: result)

		result = GRYRecordEnumsTranspilationPass().run(on: result)
		result = GRYRaiseStandardLibraryWarningsTranspilationPass().run(on: result)
		return result
	}

	static private(set) var warnings = [String]()

	static func recordWarning(_ warning: String) {
		warnings.append(warning)
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
