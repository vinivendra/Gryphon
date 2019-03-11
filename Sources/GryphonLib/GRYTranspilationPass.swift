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
		let replacedStatements = replaceTopLevelNodes(sourceFile.statements)
		let replacedDeclarations = replaceTopLevelNodes(sourceFile.declarations)
		return GRYAST(declarations: replacedDeclarations, statements: replacedStatements)
	}

	func replaceTopLevelNodes(_ nodes: [GRYTopLevelNode]) -> [GRYTopLevelNode] {
		return nodes.flatMap(replaceTopLevelNode)
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
		case let .typealiasDeclaration(identifier: identifier, type: type, isImplicit: isImplicit):
			return replaceTypealiasDeclaration(
				identifier: identifier, type: type, isImplicit: isImplicit)
		case let .classDeclaration(name: name, inherits: inherits, members: members):
			return replaceClassDeclaration(name: name, inherits: inherits, members: members)
		case let .companionObject(members: members):
			return replaceCompanionObject(members: members)
		case let .enumDeclaration(
			access: access, name: name, inherits: inherits, elements: elements, members: members,
			isImplicit: isImplicit):

			return replaceEnumDeclaration(
				access: access, name: name, inherits: inherits, elements: elements,
				members: members, isImplicit: isImplicit)
		case let .protocolDeclaration(name: name, members: members):
			return replaceProtocolDeclaration(name: name, members: members)
		case let .structDeclaration(name: name, inherits: inherits, members: members):
			return replaceStructDeclaration(name: name, inherits: inherits, members: members)
		case let .functionDeclaration(value: functionDeclaration):
			return replaceFunctionDeclaration(functionDeclaration)
		case let .variableDeclaration(value: variableDeclaration):

			return replaceVariableDeclaration(variableDeclaration)
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
		case let .switchStatement(
			convertsToExpression: convertsToExpression, expression: expression, cases: cases):

			return replaceSwitchStatement(
				convertsToExpression: convertsToExpression, expression: expression, cases: cases)
		case let .throwStatement(expression: expression):
			return replaceThrowStatement(expression: expression)
		case let .returnStatement(expression: expression):
			return replaceReturnStatement(expression: expression)
		case let .assignmentStatement(leftHand: leftHand, rightHand: rightHand):
			return replaceAssignmentStatement(leftHand: leftHand, rightHand: rightHand)
		case .error:
			return [.error]
		}
	}

	func replaceExpression(expression: GRYExpression) -> [GRYTopLevelNode] {
		return [.expression(expression: replaceExpression(expression))]
	}

	func replaceExtension(type: String, members: [GRYTopLevelNode]) -> [GRYTopLevelNode] {
		return [.extensionDeclaration(type: type, members: replaceTopLevelNodes(members))]
	}

	func replaceImportDeclaration(name: String) -> [GRYTopLevelNode] {
		return [.importDeclaration(name: name)]
	}

	func replaceTypealiasDeclaration(identifier: String, type: String, isImplicit: Bool)
		-> [GRYTopLevelNode]
	{
		return [.typealiasDeclaration(identifier: identifier, type: type, isImplicit: isImplicit)]
	}

	func replaceClassDeclaration(name: String, inherits: [String], members: [GRYTopLevelNode])
		-> [GRYTopLevelNode]
	{
		return [.classDeclaration(
			name: name, inherits: inherits, members: replaceTopLevelNodes(members)), ]
	}

	func replaceCompanionObject(members: [GRYTopLevelNode]) -> [GRYTopLevelNode] {
		return [.companionObject(members: replaceTopLevelNodes(members))]
	}

	func replaceEnumDeclaration(
		access: String?, name: String, inherits: [String], elements: [GRYASTEnumElement],
		members: [GRYTopLevelNode], isImplicit: Bool) -> [GRYTopLevelNode]
	{
		return [
			.enumDeclaration(
				access: access, name: name, inherits: inherits, elements: elements,
				members: replaceTopLevelNodes(members), isImplicit: isImplicit), ]
	}

	func replaceEnumElementDeclaration(
		name: String, associatedValues: [GRYASTLabeledType]) -> [GRYASTEnumElement]
	{
		return [GRYASTEnumElement(name: name, associatedValues: associatedValues)]
	}

	func replaceProtocolDeclaration(name: String, members: [GRYTopLevelNode]) -> [GRYTopLevelNode] {
		return [.protocolDeclaration(name: name, members: replaceTopLevelNodes(members))]
	}

	func replaceStructDeclaration(name: String, inherits: [String], members: [GRYTopLevelNode])
		-> [GRYTopLevelNode]
	{
		return [.structDeclaration(
			name: name, inherits: inherits, members: replaceTopLevelNodes(members)),
		]
	}

	func replaceFunctionDeclaration(_ functionDeclaration: GRYASTFunctionDeclaration)
		-> [GRYTopLevelNode]
	{
		let replacedParameters = functionDeclaration.parameters
			.map {
				GRYASTLabeledTypeWithValue(
					label: $0.label, type: $0.type, value: $0.value.map(replaceExpression))
			}

		var functionDeclaration = functionDeclaration
		functionDeclaration.parameters = replacedParameters
		functionDeclaration.statements = functionDeclaration.statements.map(replaceTopLevelNodes)
		return [.functionDeclaration(value: functionDeclaration)]
	}

	func replaceVariableDeclaration(_ variableDeclaration: GRYASTVariableDeclaration)
		-> [GRYTopLevelNode]
	{
		var variableDeclaration = variableDeclaration
		variableDeclaration.expression = variableDeclaration.expression.map(replaceExpression)
		variableDeclaration.getter = variableDeclaration.getter.map(replaceTopLevelNode)?.first
		variableDeclaration.setter = variableDeclaration.setter.map(replaceTopLevelNode)?.first
		return [.variableDeclaration(value: variableDeclaration), ]
	}

	func replaceForEachStatement(
		collection: GRYExpression, variable: GRYExpression, statements: [GRYTopLevelNode])
		-> [GRYTopLevelNode]
	{
		return [.forEachStatement(
			collection: replaceExpression(collection),
			variable: replaceExpression(variable),
			statements: replaceTopLevelNodes(statements)), ]
	}

	func replaceIfStatement(
		conditions: [GRYExpression], declarations: [GRYTopLevelNode], statements: [GRYTopLevelNode],
		elseStatement: GRYTopLevelNode?, isGuard: Bool) -> [GRYTopLevelNode]
	{
		return [.ifStatement(
			conditions: conditions.map(replaceExpression),
			declarations: replaceTopLevelNodes(declarations),
			statements: replaceTopLevelNodes(statements),
			elseStatement: elseStatement.map(replaceTopLevelNode)?.first,
			isGuard: isGuard), ]
	}

	func replaceSwitchStatement(
		convertsToExpression: GRYTopLevelNode?, expression: GRYExpression,
		cases: [GRYASTSwitchCase]) -> [GRYTopLevelNode]
	{
		let replacedConvertsToExpression: GRYTopLevelNode?
		if let convertsToExpression = convertsToExpression,
			let replacedExpression = replaceTopLevelNode(convertsToExpression).first
		{
			replacedConvertsToExpression = replacedExpression
		}
		else {
			replacedConvertsToExpression = nil
		}

		let replacedCases = cases.map
		{ (switchCase: GRYASTSwitchCase) -> GRYASTSwitchCase in
			let newExpression = (switchCase.expression != nil) ?
				replaceExpression(switchCase.expression!) :
				nil
			return GRYASTSwitchCase(
				expression: newExpression, statements: replaceTopLevelNodes(switchCase.statements))
		}

		return [.switchStatement(
			convertsToExpression: replacedConvertsToExpression, expression: expression,
			cases: replacedCases), ]
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
			return replaceForceValueExpression(expression: expression)
		case let .optionalExpression(expression: expression):
			return replaceOptionalExpression(expression: expression)
		case let .declarationReferenceExpression(
			identifier: identifier, type: type, isStandardLibrary: isStandardLibrary,
			isImplicit: isImplicit):

			return replaceDeclarationReferenceExpression(
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
		case let .dictionaryExpression(keys: keys, values: values, type: type):
			return replaceDictionaryExpression(keys: keys, values: values, type: type)
		case let .dotExpression(leftExpression: leftExpression, rightExpression: rightExpression):
			return replaceDotExpression(
				leftExpression: leftExpression, rightExpression: rightExpression)
		case let .binaryOperatorExpression(
			leftExpression: leftExpression, rightExpression: rightExpression,
			operatorSymbol: operatorSymbol, type: type):

			return replaceBinaryOperatorExpression(
				leftExpression: leftExpression, rightExpression: rightExpression,
				operatorSymbol: operatorSymbol, type: type)
		case let .prefixUnaryExpression(
			expression: expression, operatorSymbol: operatorSymbol, type: type):
			return replacePrefixUnaryExpression(
				expression: expression, operatorSymbol: operatorSymbol, type: type)
		case let .postfixUnaryExpression(
			expression: expression, operatorSymbol: operatorSymbol, type: type):
			return replacePostfixUnaryExpression(
				expression: expression, operatorSymbol: operatorSymbol, type: type)
		case let .callExpression(function: function, parameters: parameters, type: type):
			return replaceCallExpression(function: function, parameters: parameters, type: type)
		case let .closureExpression(parameters: parameters, statements: statements, type: type):
			return replaceClosureExpression(
				parameters: parameters, statements: statements, type: type)
		case let .literalIntExpression(value: value):
			return replaceLiteralIntExpression(value: value)
		case let .literalUIntExpression(value: value):
			return replaceLiteralUIntExpression(value: value)
		case let .literalDoubleExpression(value: value):
			return replaceLiteralDoubleExpression(value: value)
		case let .literalFloatExpression(value: value):
			return replaceLiteralFloatExpression(value: value)
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
		case .error:
			return .error
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

	func replaceForceValueExpression(expression: GRYExpression) -> GRYExpression {
		return .forceValueExpression(expression: replaceExpression(expression))
	}

	func replaceOptionalExpression(expression: GRYExpression) -> GRYExpression {
		return .optionalExpression(expression: replaceExpression(expression))
	}

	func replaceDeclarationReferenceExpression(
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

	func replaceDictionaryExpression(keys: [GRYExpression], values: [GRYExpression], type: String)
		-> GRYExpression
	{
		return .dictionaryExpression(keys: keys, values: values, type: type)
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

	func replacePrefixUnaryExpression(
		expression: GRYExpression, operatorSymbol: String, type: String) -> GRYExpression
	{
		return .prefixUnaryExpression(
			expression: replaceExpression(expression), operatorSymbol: operatorSymbol, type: type)
	}

	func replacePostfixUnaryExpression(
		expression: GRYExpression, operatorSymbol: String, type: String) -> GRYExpression
	{
		return .postfixUnaryExpression(
			expression: replaceExpression(expression), operatorSymbol: operatorSymbol, type: type)
	}

	func replaceCallExpression(function: GRYExpression, parameters: GRYExpression, type: String)
		-> GRYExpression
	{
		return .callExpression(
			function: replaceExpression(function), parameters: replaceExpression(parameters),
			type: type)
	}

	func replaceClosureExpression(
		parameters: [GRYASTLabeledType], statements: [GRYTopLevelNode], type: String)
		-> GRYExpression
	{
		return .closureExpression(
			parameters: parameters, statements: replaceTopLevelNodes(statements), type: type)
	}

	func replaceLiteralIntExpression(value: Int64) -> GRYExpression {
		return .literalIntExpression(value: value)
	}

	func replaceLiteralUIntExpression(value: UInt64) -> GRYExpression {
		return .literalUIntExpression(value: value)
	}

	func replaceLiteralDoubleExpression(value: Double) -> GRYExpression {
		return .literalDoubleExpression(value: value)
	}

	func replaceLiteralFloatExpression(value: Float) -> GRYExpression {
		return .literalFloatExpression(value: value)
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

	func replaceTupleExpression(pairs: [GRYASTLabeledExpression]) -> GRYExpression {
		return .tupleExpression( pairs: pairs.map {
			GRYASTLabeledExpression(label: $0.label, expression: replaceExpression($0.expression))
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
	override func replaceFunctionDeclaration(_ functionDeclaration: GRYASTFunctionDeclaration)
		-> [GRYTopLevelNode]
	{
		if functionDeclaration.prefix.hasPrefix("GRYDeclarations"),
			let statements = functionDeclaration.statements
		{
			return statements
		}
		else {
			return super.replaceFunctionDeclaration(functionDeclaration)
		}
	}
}

public class GRYRemoveGryphonDeclarationsTranspilationPass: GRYTranspilationPass {
	override func replaceFunctionDeclaration(_ functionDeclaration: GRYASTFunctionDeclaration)
		-> [GRYTopLevelNode]
	{
		let prefix = functionDeclaration.prefix
		if prefix.hasPrefix("GRYInsert") || prefix.hasPrefix("GRYAlternative") ||
			prefix.hasPrefix("GRYIgnoreNext") || prefix.hasPrefix("GRYAnnotations") ||
			prefix.hasPrefix("GRYIgnoreThisFunction")
		{
			return []
		}
		else {
			return super.replaceFunctionDeclaration(functionDeclaration)
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
		access: String?, name: String, inherits: [String], elements: [GRYASTEnumElement],
		members: [GRYTopLevelNode], isImplicit: Bool) -> [GRYTopLevelNode]
	{
		if inherits.contains("GRYIgnore") {
			return []
		}
		else {
			return super.replaceEnumDeclaration(
				access: access, name: name, inherits: inherits, elements: elements,
				members: members, isImplicit: isImplicit)
		}
	}

	override func replaceFunctionDeclaration(_ functionDeclaration: GRYASTFunctionDeclaration)
		-> [GRYTopLevelNode]
	{
		if let statements = functionDeclaration.statements,
			let firstStatement = statements.first,
			case let .expression(expression: callExpression) = firstStatement,
			case let .callExpression(
				function: functionExpression, parameters: _, type: _) = callExpression,
			case let .declarationReferenceExpression(
				identifier: identifier, type: _, isStandardLibrary: _,
				isImplicit: _) = functionExpression,
			identifier.hasPrefix("GRYIgnoreThisFunction")
		{
			return []
		}
		else {
			return super.replaceFunctionDeclaration(functionDeclaration)
		}
	}
}

/// Removes implicit declarations so that they don't show up on the translation
public class GRYRemoveImplicitDeclarationsTranspilationPass: GRYTranspilationPass {
	override func replaceEnumDeclaration(
		access: String?, name: String, inherits: [String], elements: [GRYASTEnumElement],
		members: [GRYTopLevelNode], isImplicit: Bool) -> [GRYTopLevelNode]
	{
		if isImplicit {
			return []
		}
		else {
			return super.replaceEnumDeclaration(
				access: access, name: name, inherits: inherits, elements: elements,
				members: members, isImplicit: isImplicit)
		}
	}

	override func replaceTypealiasDeclaration(
		identifier: String, type: String, isImplicit: Bool) -> [GRYTopLevelNode]
	{
		if isImplicit {
			return []
		}
		else {
			return super.replaceTypealiasDeclaration(
				identifier: identifier, type: type, isImplicit: isImplicit)
		}
	}
}

/// Annotations added manually via a call to GRYAnnotations must be sent into their proper place
/// in the data structure, and the function call must be removed.
public class GRYAddAnnotationsTranspilationPass: GRYTranspilationPass {
	override func replaceVariableDeclaration(_ variableDeclaration: GRYASTVariableDeclaration)
		-> [GRYTopLevelNode]
	{
		if let expression = variableDeclaration.expression,
			case let .callExpression(
				function: function, parameters: parameters, type: _) = expression,
			case let .declarationReferenceExpression(
				identifier: gryAnnotationsIdentifier, type: _, isStandardLibrary: false,
				isImplicit: false) = function,
			gryAnnotationsIdentifier == "GRYAnnotations",
			case let .tupleExpression(pairs: pairs) = parameters,
			let annotationsExpression = pairs.first?.expression,
			case let .literalStringExpression(value: newAnnotations) = annotationsExpression,
			let newExpression = pairs.last?.expression
		{
			var variableDeclaration = variableDeclaration
			variableDeclaration.expression = newExpression
			variableDeclaration.annotations = newAnnotations
			return [.variableDeclaration(value: variableDeclaration)]
		}

		return [.variableDeclaration(value: variableDeclaration)]
	}
}

/// The static functions and variables in a class must all be placed inside a single companion
/// object.
public class GRYStaticMembersTranspilationPass: GRYTranspilationPass {
	override func replaceClassDeclaration(
		name: String, inherits: [String], members: [GRYTopLevelNode]) -> [GRYTopLevelNode]
	{
		var staticMembers = [GRYTopLevelNode]()
		var otherMembers = [GRYTopLevelNode]()

		for member in members {
			if case let .functionDeclaration(value: functionDeclaration) = member,
				functionDeclaration.isStatic == true,
				functionDeclaration.extendsType == nil,
				functionDeclaration.prefix != "init"
			{
				staticMembers.append(member)
			}
			else if case let .variableDeclaration(value: variableDeclaration) = member,
				variableDeclaration.isStatic
			{
				staticMembers.append(member)
			}
			else {
				otherMembers.append(member)
			}
		}

		guard !staticMembers.isEmpty else {
			return [.classDeclaration(name: name, inherits: inherits, members: members)]
		}

		let newMembers = [.companionObject(members: staticMembers)] + otherMembers

		return [.classDeclaration(name: name, inherits: inherits, members: newMembers)]
	}
}

// TODO: test
/// Removes the unnecessary prefixes for inner types.
///
/// For instance:
/// ````
/// class A {
/// 	class B { }
/// 	let x = A.B() // This becomes just B()
/// }
/// ````
public class GRYInnerTypePrefixesTranspilationPass: GRYTranspilationPass {
	var typeNamesStack = [String]()

	func removePrefixes(_ typeName: String) -> String {
		var result = typeName
		for type in typeNamesStack {
			let prefix = type + "."
			if result.hasPrefix(prefix) {
				result.removeFirst(prefix.count)
			}
			else {
				return result
			}
		}

		return result
	}

	override func replaceClassDeclaration(
		name: String, inherits: [String], members: [GRYTopLevelNode]) -> [GRYTopLevelNode]
	{
		typeNamesStack.append(name)
		let result = super.replaceClassDeclaration(name: name, inherits: inherits, members: members)
		typeNamesStack.removeLast()
		return result
	}

	override func replaceVariableDeclaration(_ variableDeclaration: GRYASTVariableDeclaration)
		-> [GRYTopLevelNode]
	{
		var variableDeclaration = variableDeclaration
		variableDeclaration.typeName = removePrefixes(variableDeclaration.typeName)
		return super.replaceVariableDeclaration(variableDeclaration)
	}

	override func replaceTypeExpression(type: String) -> GRYExpression {
		return .typeExpression(type: removePrefixes(type))
	}
}

public class GRYRenameOperatorsTranspilationPass: GRYTranspilationPass {
	override func replaceBinaryOperatorExpression(
		leftExpression: GRYExpression, rightExpression: GRYExpression, operatorSymbol: String,
		type: String) -> GRYExpression
	{
		if operatorSymbol == "??" {
			return .binaryOperatorExpression(
				leftExpression: leftExpression, rightExpression: rightExpression,
				operatorSymbol: "?:", type: type)
		}
		else {
			return .binaryOperatorExpression(
				leftExpression: leftExpression, rightExpression: rightExpression,
				operatorSymbol: operatorSymbol, type: type)
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

	override func replaceDeclarationReferenceExpression(
		identifier: String, type: String, isStandardLibrary: Bool, isImplicit: Bool)
		-> GRYExpression
	{
		if identifier == "self" {
			assert(!isImplicit)
			return .declarationReferenceExpression(
				identifier: "this", type: type, isStandardLibrary: isStandardLibrary,
				isImplicit: isImplicit)
		}
		return super.replaceDeclarationReferenceExpression(
			identifier: identifier, type: type, isStandardLibrary: isStandardLibrary,
			isImplicit: isImplicit)
	}
}

// TODO: test
/// Declarations can't conform to Swift-only protocols like Codable and Equatable, and enums can't
/// inherit from types Strings and Ints.
public class GRYCleanInheritancesTranspilationPass: GRYTranspilationPass {
	private func isNotASwiftProtocol(_ protocolName: String) -> Bool {
		return ![
			"Equatable", "Codable",
			].contains(protocolName)
	}

	private func isNotASwiftRawRepresentableType(_ typeName: String) -> Bool {
		return ![
			"String",
			"Int", "Int8", "Int16", "Int32", "Int64",
			"UInt", "UInt8", "UInt16", "UInt32", "UInt64",
			"Float", "Float32", "Float64", "Float80", "Double",
			].contains(typeName)
	}

	override func replaceEnumDeclaration(
		access: String?, name: String, inherits: [String], elements: [GRYASTEnumElement],
		members: [GRYTopLevelNode], isImplicit: Bool) -> [GRYTopLevelNode]
	{
		return [.enumDeclaration(
			access: access, name: name,
			inherits: inherits.filter {
				isNotASwiftProtocol($0) && isNotASwiftRawRepresentableType($0)
			}, elements: elements, members: members, isImplicit: isImplicit), ]
	}

	override func replaceStructDeclaration(
		name: String, inherits: [String], members: [GRYTopLevelNode]) -> [GRYTopLevelNode]
	{
		return [.structDeclaration(
			name: name, inherits: inherits.filter(isNotASwiftProtocol), members: members), ]
	}
}

/// The "anonymous parameter" `$0` has to be replaced by `it`
public class GRYAnonymousParametersTranspilationPass: GRYTranspilationPass {
	override func replaceDeclarationReferenceExpression(
		identifier: String, type: String, isStandardLibrary: Bool, isImplicit: Bool)
		-> GRYExpression
	{
		if identifier == "$0" {
			return .declarationReferenceExpression(
				identifier: "it", type: type, isStandardLibrary: isStandardLibrary,
				isImplicit: isImplicit)
		}
		else {
			return super.replaceDeclarationReferenceExpression(
				identifier: identifier, type: type, isStandardLibrary: isStandardLibrary,
				isImplicit: isImplicit)
		}
	}

	override func replaceClosureExpression(
		parameters: [GRYASTLabeledType], statements: [GRYTopLevelNode], type: String)
		-> GRYExpression
	{
		if parameters.count == 1,
			parameters[0].label == "$0"
		{
			return super.replaceClosureExpression(
				parameters: [], statements: statements, type: type)
		}
		else {
			return super.replaceClosureExpression(
				parameters: parameters, statements: statements, type: type)
		}
	}
}

/// Closures in kotlin can't have normal "return" statements. Instead, they must have return@f
/// statements (not yet implemented) or just standalone expressions (easier to implement but more
/// error-prone). This pass turns return statements in closures into standalone expressions
public class GRYReturnsInLambdasTranspilationPass: GRYTranspilationPass {
	var isInClosure = false

	override func replaceClosureExpression(
		parameters: [GRYASTLabeledType], statements: [GRYTopLevelNode], type: String)
		-> GRYExpression
	{
		isInClosure = true
		defer { isInClosure = false }
		return super.replaceClosureExpression(
			parameters: parameters, statements: statements, type: type)
	}

	override func replaceReturnStatement(expression: GRYExpression?) -> [GRYTopLevelNode] {
		if isInClosure, let expression = expression {
			return [.expression(expression: expression)]
		}
		else {
			return [.returnStatement(expression: expression)]
		}
	}
}

/// When statements in Kotlin can be used as expressions, for instance in return statements or in
/// assignments. This pass turns switch statements whose bodies all end in the same return or
/// assignment into those expressions. It also turns a variable declaration followed by a switch
/// statement that assigns to that variable into a single variable declaration with the switch
/// statement as its expression.
///
/// An ideal conversion would somehow check if the last expressions in a switch were similar in a
/// more generic way, thus allowing this conversion to happen (for instance) inside the parameter of
/// a function call. However, that would be much more complicated and it's not clear that it would
/// be desirable.
public class GRYSwitchesToExpressionsTranspilationPass: GRYTranspilationPass {
	/// Detect switches whose bodies all end in the same returns or assignments
	override func replaceSwitchStatement(
		convertsToExpression: GRYTopLevelNode?, expression: GRYExpression,
		cases: [GRYASTSwitchCase]) -> [GRYTopLevelNode]
	{
		var hasAllReturnCases = true
		var hasAllAssignmentCases = true
		var assignmentExpression: GRYExpression?

		for statements in cases.map({ $0.statements }) {
			// Swift switches must have at least one statement
			let lastStatement = statements.last!
			if case let .returnStatement(expression: expression) = lastStatement,
				expression != nil
			{
				hasAllAssignmentCases = false
			}
			else if case let .assignmentStatement(leftHand: leftHand, rightHand: _) = lastStatement,
				assignmentExpression == nil || assignmentExpression == leftHand
			{
				hasAllReturnCases = false
				assignmentExpression = leftHand
			}
			else {
				hasAllReturnCases = false
				hasAllAssignmentCases = false
			}
		}

		if hasAllReturnCases {
			var newCases = [GRYASTSwitchCase]()
			for switchCase in cases {
				// Swift switches must have at least one statement
				let lastStatement = switchCase.statements.last!
				if case let .returnStatement(expression: maybeExpression) = lastStatement,
					let returnExpression = maybeExpression
				{
					var newStatements = Array(switchCase.statements.dropLast())
					newStatements.append(.expression(expression: returnExpression))
					newCases.append(GRYASTSwitchCase(
						expression: switchCase.expression, statements: newStatements))
				}
			}
			let conversionExpression =
				GRYTopLevelNode.returnStatement(expression: .nilLiteralExpression)
			return [.switchStatement(
				convertsToExpression: conversionExpression, expression: expression,
				cases: newCases), ]
		}
		else if hasAllAssignmentCases, let assignmentExpression = assignmentExpression {
			var newCases = [GRYASTSwitchCase]()
			for switchCase in cases {
				// Swift switches must have at least one statement
				let lastStatement = switchCase.statements.last!
				if case let .assignmentStatement(leftHand: _, rightHand: rightHand) = lastStatement
				{
					var newStatements = Array(switchCase.statements.dropLast())
					newStatements.append(.expression(expression: rightHand))
					newCases.append(GRYASTSwitchCase(
						expression: switchCase.expression, statements: newStatements))
				}
			}
			let conversionExpression = GRYTopLevelNode.assignmentStatement(
				leftHand: assignmentExpression, rightHand: .nilLiteralExpression)
			return [.switchStatement(
				convertsToExpression: conversionExpression, expression: expression,
				cases: newCases), ]
		}
		else {
			return super.replaceSwitchStatement(
				convertsToExpression: nil, expression: expression, cases: cases)
		}
	}

	/// Replace variable declarations followed by switch statements assignments
	override func replaceTopLevelNodes(_ oldNodes: [GRYTopLevelNode]) -> [GRYTopLevelNode] {
		var nodes = super.replaceTopLevelNodes(oldNodes)

		var result = [GRYTopLevelNode]()

		var i = 0
		while i < (nodes.count - 1) {
			let currentNode = nodes[i]
			let nextNode = nodes[i + 1]
			if case var .variableDeclaration(value: variableDeclaration) = currentNode,
				variableDeclaration.isImplicit == false,
				variableDeclaration.extendsType == nil,
				case let .switchStatement(
					convertsToExpression: maybeConversion, expression: switchExpression,
					cases: cases) = nextNode,
				let switchConversion = maybeConversion,
				case let .assignmentStatement(leftHand: leftHand, rightHand: _) = switchConversion,
				case let .declarationReferenceExpression(

					identifier: assignmentIdentifier, type: _, isStandardLibrary: false,
					isImplicit: false) = leftHand,
				assignmentIdentifier == variableDeclaration.identifier
			{
				variableDeclaration.expression = .nilLiteralExpression
				variableDeclaration.getter = nil
				variableDeclaration.setter = nil
				variableDeclaration.isStatic = false
				let newConversionExpression =
					GRYTopLevelNode.variableDeclaration(value: variableDeclaration)
				result.append(.switchStatement(
					convertsToExpression: newConversionExpression, expression: switchExpression,
					cases: cases))

				// Skip appending variable declaration and the switch declaration, thus replacing
				// both with the new switch declaration
				i += 2
			}
			else {
				result.append(currentNode)
				i += 1
			}
		}

		if let lastStatement = nodes.last {
			result.append(lastStatement)
		}

		return result
	}
}

public class GRYRemoveExtensionsTranspilationPass: GRYTranspilationPass {
	var extendingType: String?

	override func replaceExtension(type: String, members: [GRYTopLevelNode]) -> [GRYTopLevelNode] {
		extendingType = type
		let members = replaceTopLevelNodes(members)
		extendingType = nil
		return members
	}

	override func replaceTopLevelNode(_ node: GRYTopLevelNode) -> [GRYTopLevelNode] {
		switch node {
		case let .extensionDeclaration(type: type, members: members):
			return replaceExtension(type: type, members: members)
		case let .functionDeclaration(value: functionDeclaration):
			return replaceFunctionDeclaration(functionDeclaration)
		case let .variableDeclaration(value: variableDeclaration):
			return replaceVariableDeclaration(variableDeclaration)
		default:
			return [node]
		}
	}

	override func replaceFunctionDeclaration(_ functionDeclaration: GRYASTFunctionDeclaration)
		-> [GRYTopLevelNode]
	{
		var functionDeclaration = functionDeclaration
		functionDeclaration.extendsType = self.extendingType
		return [GRYTopLevelNode.functionDeclaration(value: functionDeclaration)]
	}

	override func replaceVariableDeclaration(_ variableDeclaration: GRYASTVariableDeclaration)
		-> [GRYTopLevelNode]
	{
		var variableDeclaration = variableDeclaration
		variableDeclaration.extendsType = self.extendingType
		return [GRYTopLevelNode.variableDeclaration(value: variableDeclaration)]
	}
}

public class GRYRecordEnumsTranspilationPass: GRYTranspilationPass {
	override func replaceEnumDeclaration(
		access: String?, name: String, inherits: [String], elements: [GRYASTEnumElement],
		members: [GRYTopLevelNode], isImplicit: Bool) -> [GRYTopLevelNode]
	{
		GRYKotlinTranslator.addEnum(name)
		return [.enumDeclaration(
			access: access, name: name, inherits: inherits, elements: elements, members: members,
			isImplicit: isImplicit), ]
	}
}

public class GRYRaiseStandardLibraryWarningsTranspilationPass: GRYTranspilationPass {
	override func replaceDeclarationReferenceExpression(
		identifier: String, type: String, isStandardLibrary: Bool, isImplicit: Bool)
		-> GRYExpression
	{
		if isStandardLibrary {
			GRYCompiler.handleWarning(
				"Reference to standard library \"\(identifier)\" was not translated.")
		}
		return super.replaceDeclarationReferenceExpression(
			identifier: identifier, type: type, isStandardLibrary: isStandardLibrary,
			isImplicit: isImplicit)
	}
}

/// If a value type's members are all immutable, that value type can safely be translated as a
/// class. Otherwise, the translation can cause inconsistencies, so this pass raises warnings.
/// Source: https://forums.swift.org/t/are-immutable-structs-like-classes/16270
public class GRYRaiseMutableValueTypesWarningsTranspilationPass: GRYTranspilationPass {
	override func replaceStructDeclaration(
		name: String, inherits: [String], members: [GRYTopLevelNode]) -> [GRYTopLevelNode]
	{
		for member in members {
			// TODO: Computed variables are OK
			if case let .variableDeclaration(value: variableDeclaration) = member,
				!variableDeclaration.isImplicit,
				!variableDeclaration.isStatic
			{
				if !variableDeclaration.isLet {
					GRYCompiler.handleWarning(
						"No support for mutable variables in value types: found variable " +
						"\(variableDeclaration.identifier) inside struct \(name)")
				}
			}
			else if case let .functionDeclaration(value: functionDeclaration) = member
			{
				if functionDeclaration.isMutating {
					let methodName = functionDeclaration.prefix + "(" +
						functionDeclaration.parameters.map { $0.label + ":" }
							.joined(separator: ", ") + ")"
					GRYCompiler.handleWarning(
						"No support for mutating methods in value types: found method " +
						"\(methodName) inside struct \(name)")
				}
			}
		}

		return [.structDeclaration(name: name, inherits: inherits, members: members)]
	}

	override func replaceEnumDeclaration(
		access: String?, name: String, inherits: [String], elements: [GRYASTEnumElement],
		members: [GRYTopLevelNode], isImplicit: Bool) -> [GRYTopLevelNode]
	{
		for member in members {
			if case let .functionDeclaration(value: functionDeclaration) = member
			{
				if functionDeclaration.isMutating {
					let methodName = functionDeclaration.prefix + "(" +
						functionDeclaration.parameters.map { $0.label + ":" }
							.joined(separator: ", ") + ")"
					GRYCompiler.handleWarning(
						"No support for mutating methods in value types: found method " +
						"\(methodName) inside enum \(name)")
				}
			}
		}

		return [.enumDeclaration(
			access: access, name: name, inherits: inherits, elements: elements, members: members,
			isImplicit: isImplicit), ]
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
			if case let .variableDeclaration(value: variableDeclaration) = declaration
			{
				// If it's a shadowing identifier there's no need to declare it in Kotlin
				// (i.e. `if let x = x { }`)
				if let declarationExpression = variableDeclaration.expression,
					case .declarationReferenceExpression(
						identifier: variableDeclaration.identifier,
						type: _,
						isStandardLibrary: _,
						isImplicit: _) = declarationExpression
				{
				}
				else {
					letDeclarations.append(declaration)
				}

				letConditions.append(
					.binaryOperatorExpression(
						leftExpression: .declarationReferenceExpression(
							identifier: variableDeclaration.identifier,
							type: variableDeclaration.typeName,
							isStandardLibrary: false, isImplicit: false),
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

// TODO: test
/// Guards are translated as if statements with a ! at the start of the condition. Sometimes, the
/// ! combines with a != or even another !, causing a double negative in the condition that can
/// be removed (or turned into a single ==). This pass performs that transformation.
public class GRYDoubleNegativesInGuardsTranspilationPass: GRYTranspilationPass {
	override func replaceIfStatement(
		conditions: [GRYExpression], declarations: [GRYTopLevelNode], statements: [GRYTopLevelNode],
		elseStatement: GRYTopLevelNode?, isGuard: Bool) -> [GRYTopLevelNode]
	{
		if isGuard, conditions.count == 1 {
			let condition = conditions[0]
			let shouldStillBeGuard: Bool
			let newCondition: GRYExpression
			if case let .prefixUnaryExpression(
				expression: innerExpression, operatorSymbol: "!", type: _) = condition
			{
				newCondition = innerExpression
				shouldStillBeGuard = false
			}
			else if case let .binaryOperatorExpression(
				leftExpression: leftExpression, rightExpression: rightExpression,
				operatorSymbol: "!=", type: type) = condition
			{
				newCondition = .binaryOperatorExpression(
					leftExpression: leftExpression, rightExpression: rightExpression,
					operatorSymbol: "==", type: type)
				shouldStillBeGuard = false
			}
			else if case let .binaryOperatorExpression(
				leftExpression: leftExpression, rightExpression: rightExpression,
				operatorSymbol: "==", type: type) = condition
			{
				newCondition = .binaryOperatorExpression(
					leftExpression: leftExpression, rightExpression: rightExpression,
					operatorSymbol: "!=", type: type)
				shouldStillBeGuard = false
			}
			else {
				newCondition = condition
				shouldStillBeGuard = true
			}

			return super.replaceIfStatement(
				conditions: [newCondition], declarations: declarations, statements: statements,
				elseStatement: elseStatement, isGuard: shouldStillBeGuard)
		}
		else {
			return super.replaceIfStatement(
				conditions: conditions, declarations: declarations, statements: statements,
				elseStatement: elseStatement, isGuard: isGuard)
		}
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

	override func replaceFunctionDeclaration(_ functionDeclaration: GRYASTFunctionDeclaration)
		-> [GRYTopLevelNode]
	{
		if isInProtocol {
			var functionDeclaration = functionDeclaration
			functionDeclaration.statements = nil
			return super.replaceFunctionDeclaration(functionDeclaration)
		}
		else {
			return super.replaceFunctionDeclaration(functionDeclaration)
		}
	}
}

public extension GRYTranspilationPass {
	static func runAllPasses(on sourceFile: GRYAST) -> GRYAST {
		var result = sourceFile
		result = GRYLibraryTranspilationPass().run(on: result)
		result = GRYRemoveGryphonDeclarationsTranspilationPass().run(on: result)
		result = GRYRemoveIgnoredDeclarationsTranspilationPass().run(on: result)
		result = GRYRemoveImplicitDeclarationsTranspilationPass().run(on: result)
		result = GRYAddAnnotationsTranspilationPass().run(on: result)
		result = GRYRemoveParenthesesTranspilationPass().run(on: result)
		result = GRYIgnoreNextTranspilationPass().run(on: result)
		result = GRYInsertCodeLiteralsTranspilationPass().run(on: result)
		result = GRYDeclarationsTranspilationPass().run(on: result)

		result = GRYStaticMembersTranspilationPass().run(on: result)
		result = GRYFixProtocolContentsTranspilationPass().run(on: result)
		result = GRYCleanInheritancesTranspilationPass().run(on: result)
		result = GRYAnonymousParametersTranspilationPass().run(on: result)
		result = GRYSwitchesToExpressionsTranspilationPass().run(on: result)
		result = GRYReturnsInLambdasTranspilationPass().run(on: result)
		result = GRYInnerTypePrefixesTranspilationPass().run(on: result)
		result = GRYRenameOperatorsTranspilationPass().run(on: result)
		result = GRYSelfToThisTranspilationPass().run(on: result)
		result = GRYRemoveExtensionsTranspilationPass().run(on: result)

		result = GRYRearrangeIfLetsTranspilationPass().run(on: result)
		result = GRYDoubleNegativesInGuardsTranspilationPass().run(on: result)

		result = GRYRecordEnumsTranspilationPass().run(on: result)
		result = GRYRaiseStandardLibraryWarningsTranspilationPass().run(on: result)
		result = GRYRaiseMutableValueTypesWarningsTranspilationPass().run(on: result)

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
