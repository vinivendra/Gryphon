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

public class TranspilationPass {
	fileprivate var parents = [ASTNode]()
	fileprivate var parent: ASTNode {
		return parents.secondToLast!
	}

	func run(on ast: GryphonAST) -> GryphonAST {
		let replacedStatements = replaceStatements(ast.statements)
		let replacedDeclarations = replaceStatements(ast.declarations)
		return GryphonAST(declarations: replacedDeclarations, statements: replacedStatements)
	}

	func replaceStatements(_ statements: [Statement]) -> [Statement] {
		return statements.flatMap(replaceStatement)
	}

	func replaceStatement(_ statement: Statement) -> [Statement] {
		parents.append(.statement(statement))
		defer { parents.removeLast() }

		switch statement {
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
		case let .structDeclaration(
			annotations: annotations, name: name, inherits: inherits, members: members):

			return replaceStructDeclaration(
				annotations: annotations, name: name, inherits: inherits, members: members)
		case let .functionDeclaration(value: functionDeclaration):
			return replaceFunctionDeclaration(functionDeclaration)
		case let .variableDeclaration(value: variableDeclaration):

			return replaceVariableDeclaration(variableDeclaration)
		case let .forEachStatement(
			collection: collection, variable: variable, statements: statements):

			return replaceForEachStatement(
				collection: collection, variable: variable, statements: statements)
		case let .whileStatement(expression: expression, statements: statements):
			return replaceWhileStatement(expression: expression, statements: statements)
		case let .ifStatement(value: ifStatement):
			return replaceIfStatement(ifStatement)
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

	func replaceExpression(expression: Expression) -> [Statement] {
		return [.expression(expression: replaceExpression(expression))]
	}

	func replaceExtension(type: String, members: [Statement]) -> [Statement] {
		return [.extensionDeclaration(type: type, members: replaceStatements(members))]
	}

	func replaceImportDeclaration(name: String) -> [Statement] {
		return [.importDeclaration(name: name)]
	}

	func replaceTypealiasDeclaration(identifier: String, type: String, isImplicit: Bool)
		-> [Statement]
	{
		return [.typealiasDeclaration(identifier: identifier, type: type, isImplicit: isImplicit)]
	}

	func replaceClassDeclaration(name: String, inherits: [String], members: [Statement])
		-> [Statement]
	{
		return [.classDeclaration(
			name: name, inherits: inherits, members: replaceStatements(members)), ]
	}

	func replaceCompanionObject(members: [Statement]) -> [Statement] {
		return [.companionObject(members: replaceStatements(members))]
	}

	func replaceEnumDeclaration(
		access: String?, name: String, inherits: [String], elements: [EnumElement],
		members: [Statement], isImplicit: Bool) -> [Statement]
	{
		return [
			.enumDeclaration(
				access: access, name: name, inherits: inherits,
				elements: elements.flatMap {
						replaceEnumElementDeclaration(
							name: $0.name,
							associatedValues: $0.associatedValues,
							annotations: $0.annotations)
					},
				members: replaceStatements(members), isImplicit: isImplicit), ]
	}

	func replaceEnumElementDeclaration(
		name: String, associatedValues: [LabeledType], annotations: String?)
		-> [EnumElement]
	{
		return [EnumElement(
			name: name, associatedValues: associatedValues, annotations: annotations), ]
	}

	func replaceProtocolDeclaration(name: String, members: [Statement]) -> [Statement] {
		return [.protocolDeclaration(name: name, members: replaceStatements(members))]
	}

	func replaceStructDeclaration(
		annotations: String?, name: String, inherits: [String], members: [Statement]) -> [Statement]
	{
		return [.structDeclaration(
			annotations: annotations,
			name: name,
			inherits: inherits,
			members: replaceStatements(members)), ]
	}

	func replaceFunctionDeclaration(_ functionDeclaration: FunctionDeclaration)
		-> [Statement]
	{
		let replacedParameters = functionDeclaration.parameters
			.map {
				FunctionParameter(
					label: $0.label,
					apiLabel: $0.apiLabel,
					type: $0.type,
					value: $0.value.map(replaceExpression))
			}

		var functionDeclaration = functionDeclaration
		functionDeclaration.parameters = replacedParameters
		functionDeclaration.statements = functionDeclaration.statements.map(replaceStatements)
		return [.functionDeclaration(value: functionDeclaration)]
	}

	func replaceVariableDeclaration(_ variableDeclaration: VariableDeclaration)
		-> [Statement]
	{
		return [.variableDeclaration(value: replaceVariableDeclaration(variableDeclaration))]
	}

	func replaceVariableDeclaration(_ variableDeclaration: VariableDeclaration)
		-> VariableDeclaration
	{
		var variableDeclaration = variableDeclaration
		variableDeclaration.expression = variableDeclaration.expression.map(replaceExpression)
		variableDeclaration.getter = variableDeclaration.getter.map(replaceStatement)?.first
		variableDeclaration.setter = variableDeclaration.setter.map(replaceStatement)?.first
		return variableDeclaration
	}

	func replaceForEachStatement(
		collection: Expression, variable: Expression, statements: [Statement])
		-> [Statement]
	{
		return [.forEachStatement(
			collection: replaceExpression(collection),
			variable: replaceExpression(variable),
			statements: replaceStatements(statements)), ]
	}

	func replaceWhileStatement(expression: Expression, statements: [Statement]) -> [Statement] {
		return [.whileStatement(
			expression: replaceExpression(expression),
			statements: replaceStatements(statements)), ]
	}

	func replaceIfStatement(_ ifStatement: IfStatement) -> [Statement] {
		return [Statement.ifStatement(value: replaceIfStatement(ifStatement))]
	}

	func replaceIfStatement(_ ifStatement: IfStatement) -> IfStatement {
		let ifStatement = ifStatement.copy()
		ifStatement.conditions = ifStatement.conditions.map(replaceExpression)
		ifStatement.declarations = ifStatement.declarations.map(replaceVariableDeclaration)
		ifStatement.statements = replaceStatements(ifStatement.statements)
		ifStatement.elseStatement = ifStatement.elseStatement.map(replaceIfStatement)
		return ifStatement
	}

	func replaceSwitchStatement(
		convertsToExpression: Statement?, expression: Expression,
		cases: [SwitchCase]) -> [Statement]
	{
		let replacedConvertsToExpression: Statement?
		if let convertsToExpression = convertsToExpression,
			let replacedExpression = replaceStatement(convertsToExpression).first
		{
			replacedConvertsToExpression = replacedExpression
		}
		else {
			replacedConvertsToExpression = nil
		}

		let replacedCases = cases.map
		{ (switchCase: SwitchCase) -> SwitchCase in
			let newExpression = (switchCase.expression != nil) ?
				replaceExpression(switchCase.expression!) :
				nil
			return SwitchCase(
				expression: newExpression, statements: replaceStatements(switchCase.statements))
		}

		return [.switchStatement(
			convertsToExpression: replacedConvertsToExpression,
			expression: replaceExpression(expression),
			cases: replacedCases), ]
	}

	func replaceThrowStatement(expression: Expression) -> [Statement] {
		return [.throwStatement(expression: replaceExpression(expression))]
	}

	func replaceReturnStatement(expression: Expression?) -> [Statement] {
		return [.returnStatement(expression: expression.map(replaceExpression))]
	}

	func replaceAssignmentStatement(leftHand: Expression, rightHand: Expression)
		-> [Statement]
	{
		return [.assignmentStatement(
			leftHand: replaceExpression(leftHand), rightHand: replaceExpression(rightHand)), ]
	}

	func replaceExpression(_ expression: Expression) -> Expression {
		parents.append(.expression(expression))
		defer { parents.removeLast() }

		switch expression {
		case let .templateExpression(pattern: pattern, matches: matches):
			return replaceTemplateExpression(pattern: pattern, matches: matches)
		case .literalCodeExpression(string: let string),
			.literalDeclarationExpression(string: let string):

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
		case let .conditionalCastExpression(
			declarationReference: declarationReference, castedToType: castedToType):

			return replaceConditionalCastExpression(
				declarationReference: declarationReference, castedToType: castedToType)
		case let .isExpression(declarationReference: declarationReference, typeName: typeName):
			return replaceIsExpression(
				declarationReference: declarationReference, typeName: typeName)
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
		case let .returnExpression(expression: innerExpression):
			return replaceReturnExpression(innerExpression: innerExpression)
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
		case let .literalCharacterExpression(value: value):
			return replaceLiteralCharacterExpression(value: value)
		case .nilLiteralExpression:
			return replaceNilLiteralExpression()
		case let .interpolatedStringLiteralExpression(expressions: expressions):
			return replaceInterpolatedStringLiteralExpression(expressions: expressions)
		case let .tupleExpression(pairs: pairs):
			return replaceTupleExpression(pairs: pairs)
		case let .tupleShuffleExpression(
			labels: labels, indices: indices, expressions: expressions):

			return replaceTupleShuffleExpression(
				labels: labels, indices: indices, expressions: expressions)
		case .error:
			return .error
		}
	}

	func replaceTemplateExpression(pattern: String, matches: [String: Expression])
		-> Expression
	{
		return .templateExpression(pattern: pattern, matches: matches.mapValues(replaceExpression))
	}

	func replaceLiteralCodeExpression(string: String) -> Expression {
		return .literalCodeExpression(string: string)
	}

	func replaceParenthesesExpression(expression: Expression) -> Expression {
		return .parenthesesExpression(expression: replaceExpression(expression))
	}

	func replaceForceValueExpression(expression: Expression) -> Expression {
		return .forceValueExpression(expression: replaceExpression(expression))
	}

	func replaceOptionalExpression(expression: Expression) -> Expression {
		return .optionalExpression(expression: replaceExpression(expression))
	}

	func replaceDeclarationReferenceExpression(
		identifier: String, type: String, isStandardLibrary: Bool, isImplicit: Bool)
		-> Expression
	{
		return .declarationReferenceExpression(
			identifier: identifier, type: type, isStandardLibrary: isStandardLibrary,
			isImplicit: isImplicit)
	}

	func replaceConditionalCastExpression(
		declarationReference: Expression, castedToType: String) -> Expression
	{
		return .conditionalCastExpression(
			declarationReference: replaceExpression(declarationReference),
			castedToType: castedToType)
	}

	func replaceIsExpression(
		declarationReference: Expression, typeName: String) -> Expression
	{
		return .isExpression(
			declarationReference: replaceExpression(declarationReference), typeName: typeName)
	}

	func replaceTypeExpression(type: String) -> Expression {
		return .typeExpression(type: type)
	}

	func replaceSubscriptExpression(
		subscriptedExpression: Expression, indexExpression: Expression, type: String)
		-> Expression
	{
		return .subscriptExpression(
			subscriptedExpression: replaceExpression(subscriptedExpression),
			indexExpression: replaceExpression(indexExpression), type: type)
	}

	func replaceArrayExpression(elements: [Expression], type: String) -> Expression {
		return .arrayExpression(elements: elements.map(replaceExpression), type: type)
	}

	func replaceDictionaryExpression(keys: [Expression], values: [Expression], type: String)
		-> Expression
	{
		return .dictionaryExpression(keys: keys, values: values, type: type)
	}

	func replaceReturnExpression(innerExpression: Expression?) -> Expression {
		return .returnExpression(expression: innerExpression.map(replaceExpression))
	}

	func replaceDotExpression(leftExpression: Expression, rightExpression: Expression)
		-> Expression
	{
		return .dotExpression(
			leftExpression: replaceExpression(leftExpression),
			rightExpression: replaceExpression(rightExpression))
	}

	func replaceBinaryOperatorExpression(
		leftExpression: Expression, rightExpression: Expression, operatorSymbol: String,
		type: String) -> Expression
	{
		return .binaryOperatorExpression(
			leftExpression: replaceExpression(leftExpression),
			rightExpression: replaceExpression(rightExpression),
			operatorSymbol: operatorSymbol,
			type: type)
	}

	func replacePrefixUnaryExpression(
		expression: Expression, operatorSymbol: String, type: String) -> Expression
	{
		return .prefixUnaryExpression(
			expression: replaceExpression(expression), operatorSymbol: operatorSymbol, type: type)
	}

	func replacePostfixUnaryExpression(
		expression: Expression, operatorSymbol: String, type: String) -> Expression
	{
		return .postfixUnaryExpression(
			expression: replaceExpression(expression), operatorSymbol: operatorSymbol, type: type)
	}

	func replaceCallExpression(function: Expression, parameters: Expression, type: String)
		-> Expression
	{
		return .callExpression(
			function: replaceExpression(function), parameters: replaceExpression(parameters),
			type: type)
	}

	func replaceClosureExpression(
		parameters: [LabeledType], statements: [Statement], type: String)
		-> Expression
	{
		return .closureExpression(
			parameters: parameters, statements: replaceStatements(statements), type: type)
	}

	func replaceLiteralIntExpression(value: Int64) -> Expression {
		return .literalIntExpression(value: value)
	}

	func replaceLiteralUIntExpression(value: UInt64) -> Expression {
		return .literalUIntExpression(value: value)
	}

	func replaceLiteralDoubleExpression(value: Double) -> Expression {
		return .literalDoubleExpression(value: value)
	}

	func replaceLiteralFloatExpression(value: Float) -> Expression {
		return .literalFloatExpression(value: value)
	}

	func replaceLiteralBoolExpression(value: Bool) -> Expression {
		return .literalBoolExpression(value: value)
	}

	func replaceLiteralStringExpression(value: String) -> Expression {
		return .literalStringExpression(value: value)
	}

	func replaceLiteralCharacterExpression(value: String) -> Expression {
		return .literalCharacterExpression(value: value)
	}

	func replaceNilLiteralExpression() -> Expression {
		return .nilLiteralExpression
	}

	func replaceInterpolatedStringLiteralExpression(expressions: [Expression]) -> Expression {
		return .interpolatedStringLiteralExpression(expressions: expressions.map(replaceExpression))
	}

	func replaceTupleExpression(pairs: [LabeledExpression]) -> Expression {
		return .tupleExpression( pairs: pairs.map {
			LabeledExpression(label: $0.label, expression: replaceExpression($0.expression))
		})
	}

	func replaceTupleShuffleExpression(
		labels: [String], indices: [TupleShuffleIndex], expressions: [Expression])
		-> Expression
	{
		return .tupleShuffleExpression(
			labels: labels, indices: indices, expressions: expressions.map(replaceExpression))
	}
}

public class RemoveParenthesesTranspilationPass: TranspilationPass {
	override func replaceParenthesesExpression(expression: Expression) -> Expression {

		if case let .expression(parentExpression) = parent {
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

/// Removes implicit declarations so that they don't show up on the translation
public class RemoveImplicitDeclarationsTranspilationPass: TranspilationPass {
	override func replaceEnumDeclaration(
		access: String?, name: String, inherits: [String], elements: [EnumElement],
		members: [Statement], isImplicit: Bool) -> [Statement]
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
		identifier: String, type: String, isImplicit: Bool) -> [Statement]
	{
		if isImplicit {
			return []
		}
		else {
			return super.replaceTypealiasDeclaration(
				identifier: identifier, type: type, isImplicit: isImplicit)
		}
	}

	override func replaceVariableDeclaration(_ variableDeclaration: VariableDeclaration)
		-> [Statement]
	{
		if variableDeclaration.isImplicit {
			return []
		}
		else {
			return super.replaceVariableDeclaration(variableDeclaration)
		}
	}
}

/// Optional initializers can be translated as `invoke` operators to have similar syntax and
/// funcitonality.
public class OptionalInitsTranspilationPass: TranspilationPass {
	private var isFailableInitializer: Bool = false

	override func replaceFunctionDeclaration(_ functionDeclaration: FunctionDeclaration)
		-> [Statement]
	{
		if functionDeclaration.isStatic == true,
			functionDeclaration.extendsType == nil,
			functionDeclaration.prefix == "init"
		{
			if functionDeclaration.returnType.hasSuffix("?") {
				var functionDeclaration = functionDeclaration

				isFailableInitializer = true
				let newStatements = replaceStatements(functionDeclaration.statements ?? [])
				isFailableInitializer = false

				functionDeclaration.prefix = "invoke"
				functionDeclaration.statements = newStatements
				return [.functionDeclaration(value: functionDeclaration)]
			}
		}

		return super.replaceFunctionDeclaration(functionDeclaration)
	}

	override func replaceAssignmentStatement(leftHand: Expression, rightHand: Expression)
		-> [Statement]
	{
		if isFailableInitializer,
			case .declarationReferenceExpression(
			identifier: "self",
			type: _, isStandardLibrary: _, isImplicit: _) = leftHand
		{
			return [.returnStatement(expression: rightHand)]
		}
		else {
			return super.replaceAssignmentStatement(leftHand: leftHand, rightHand: rightHand)
		}
	}
}

public class RemoveExtraReturnsInInitsTranspilationPass: TranspilationPass {
	override func replaceFunctionDeclaration(_ functionDeclaration: FunctionDeclaration)
		-> [Statement]
	{
		if functionDeclaration.isStatic == true,
			functionDeclaration.extendsType == nil,
			functionDeclaration.prefix == "init",
			let lastStatement = functionDeclaration.statements?.last,
			case .returnStatement(expression: nil) = lastStatement
		{
			var functionDeclaration = functionDeclaration
			functionDeclaration.statements?.removeLast()
			return [.functionDeclaration(value: functionDeclaration)]
		}

		return [.functionDeclaration(value: functionDeclaration)]
	}
}

/// The static functions and variables in a class must all be placed inside a single companion
/// object.
public class StaticMembersTranspilationPass: TranspilationPass {
	private func sendStaticMembersToCompanionObject(_ members: [Statement]) -> [Statement] {
		let isStaticMember = { (member: Statement) -> Bool in
			if case let .functionDeclaration(value: functionDeclaration) = member,
				functionDeclaration.isStatic == true,
				functionDeclaration.extendsType == nil,
				functionDeclaration.prefix != "init"
			{
				return true
			}
			else if case let .variableDeclaration(value: variableDeclaration) = member,
				variableDeclaration.isStatic
			{
				return true
			}
			else {
				return false
			}
		}

		let staticMembers = members.filter(isStaticMember)

		guard !staticMembers.isEmpty else {
			return members
		}

		let nonStaticMembers = members.filter { !isStaticMember($0) }

		let newMembers = [.companionObject(members: staticMembers)] + nonStaticMembers
		return newMembers
	}

	override func replaceClassDeclaration(
		name: String, inherits: [String], members: [Statement]) -> [Statement]
	{
		let newMembers = sendStaticMembersToCompanionObject(members)
		return super.replaceClassDeclaration(name: name, inherits: inherits, members: newMembers)
	}

	override func replaceStructDeclaration(
		annotations: String?, name: String, inherits: [String], members: [Statement]) -> [Statement]
	{
		let newMembers = sendStaticMembersToCompanionObject(members)
		return super.replaceStructDeclaration(
			annotations: annotations,
			name: name,
			inherits: inherits,
			members: newMembers)
	}

	override func replaceEnumDeclaration(
		access: String?, name: String, inherits: [String], elements: [EnumElement],
		members: [Statement], isImplicit: Bool) -> [Statement]
	{
		let newMembers = sendStaticMembersToCompanionObject(members)
		return super.replaceEnumDeclaration(
			access: access,
			name: name,
			inherits: inherits,
			elements: elements,
			members: newMembers,
			isImplicit: isImplicit)
	}
}

/// Removes the unnecessary prefixes for inner types.
///
/// For instance:
/// ````
/// class A {
/// 	class B { }
/// 	let x = A.B() // This becomes just B()
/// }
/// ````
public class InnerTypePrefixesTranspilationPass: TranspilationPass {
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
		name: String, inherits: [String], members: [Statement]) -> [Statement]
	{
		typeNamesStack.append(name)
		let result = super.replaceClassDeclaration(name: name, inherits: inherits, members: members)
		typeNamesStack.removeLast()
		return result
	}

	override func replaceStructDeclaration(
		annotations: String?, name: String, inherits: [String], members: [Statement])
		-> [Statement]
	{
		typeNamesStack.append(name)
		let result = super.replaceStructDeclaration(
			annotations: annotations, name: name, inherits: inherits, members: members)
		typeNamesStack.removeLast()
		return result
	}

	override func replaceVariableDeclaration(_ variableDeclaration: VariableDeclaration)
		-> VariableDeclaration
	{
		var variableDeclaration = variableDeclaration
		variableDeclaration.typeName = removePrefixes(variableDeclaration.typeName)
		return super.replaceVariableDeclaration(variableDeclaration)
	}

	override func replaceTypeExpression(type: String) -> Expression {
		return .typeExpression(type: removePrefixes(type))
	}
}

// TODO: test
/// Capitalizes references to enums (since enum cases in Kotlin are conventionally written in
/// capitalized forms)
public class CapitalizeEnumsTranspilationPass: TranspilationPass {
	override func replaceDotExpression(
		leftExpression: Expression, rightExpression: Expression) -> Expression
	{
		if case let .typeExpression(type: enumType) = leftExpression,
			case let .declarationReferenceExpression(
				identifier: enumCase,
				type: enumFunctionType,
				isStandardLibrary: isStandardLibrary,
				isImplicit: isImplicit) = rightExpression
		{
			if KotlinTranslator.sealedClasses.contains(enumType) {
				return .dotExpression(
					leftExpression: .typeExpression(type: enumType),
					rightExpression: .declarationReferenceExpression(
						identifier: enumCase.capitalizedAsCamelCase,
						type: enumFunctionType,
						isStandardLibrary: isStandardLibrary,
						isImplicit: isImplicit))
			}
			else if KotlinTranslator.enumClasses.contains(enumType) {
				return .dotExpression(
					leftExpression: .typeExpression(type: enumType),
					rightExpression: .declarationReferenceExpression(
						identifier: enumCase.upperSnakeCase(),
						type: enumFunctionType,
						isStandardLibrary: isStandardLibrary,
						isImplicit: isImplicit))
			}
		}

		return super.replaceDotExpression(
			leftExpression: leftExpression, rightExpression: rightExpression)
	}
}

/// Some enum prefixes can be omitted. For instance, there's no need to include `MyEnum.` before
/// `ENUM_CASE` in the variable declarations or function returns below:
///
/// enum class MyEnum {
/// 	ENUM_CASE
/// }
/// var x: MyEnum = ENUM_CASE
/// fun f(): MyEnum {
/// 	ENUM_CASE
/// }
///
/// Assumes subtrees like the one below are references to enums (see also
/// CapitalizeAllEnumsTranspilationPass).
///
///	    ...
///        └─ dotExpression
///          ├─ left
///          │  └─ typeExpression
///          │     └─ MyEnum
///          └─ right
///             └─ declarationReferenceExpression
///                ├─ (MyEnum.Type) -> MyEnum
///                └─ myEnum
// TODO: test
// TODO: add support for return whens (maybe put this before the when pass)
public class OmitImplicitEnumPrefixesTranspilationPass: TranspilationPass {
	private var returnTypesStack: [String] = []

	private func removePrefixFromPossibleEnumReference(
		leftExpression: Expression, rightExpression: Expression) -> Expression
	{
		if case let .typeExpression(type: enumType) = leftExpression,
			case let .declarationReferenceExpression(
				identifier: enumCase,
				type: enumFunctionType,
				isStandardLibrary: isStandardLibrary,
				isImplicit: isImplicit) = rightExpression,
			enumFunctionType == "(\(enumType).Type) -> \(enumType)",
			!KotlinTranslator.sealedClasses.contains(enumType)
		{
			return .declarationReferenceExpression(
				identifier: enumCase,
				type: enumFunctionType,
				isStandardLibrary: isStandardLibrary,
				isImplicit: isImplicit)
		}
		else {
			return super.replaceDotExpression(
				leftExpression: leftExpression, rightExpression: rightExpression)
		}
	}

	override func replaceFunctionDeclaration(_ functionDeclaration: FunctionDeclaration)
		-> [Statement]
	{
		returnTypesStack.append(functionDeclaration.returnType)
		defer { returnTypesStack.removeLast() }
		return super.replaceFunctionDeclaration(functionDeclaration)
	}

	override func replaceReturnStatement(expression: Expression?) -> [Statement] {
		if let returnType = returnTypesStack.last,
			let expression = expression,
			case let .dotExpression(
				leftExpression: leftExpression,
				rightExpression: rightExpression) = expression,
			case let .typeExpression(type: typeExpression) = leftExpression
		{
			// It's ok to omit if the return type is an optional enum too
			var returnType = returnType
			if returnType.hasSuffix("?") {
				returnType.removeLast("?".count)
			}

			if typeExpression == returnType {
				let newExpression = removePrefixFromPossibleEnumReference(
					leftExpression: leftExpression, rightExpression: rightExpression)
				return [.returnStatement(expression: newExpression)]
			}
		}

		return [.returnStatement(expression: expression)]
	}
}

public class RenameOperatorsTranspilationPass: TranspilationPass {
	override func replaceBinaryOperatorExpression(
		leftExpression: Expression, rightExpression: Expression, operatorSymbol: String,
		type: String) -> Expression
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

public class SelfToThisTranspilationPass: TranspilationPass {
	override func replaceDotExpression(
		leftExpression: Expression, rightExpression: Expression) -> Expression
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
		-> Expression
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

/// Declarations can't conform to Swift-only protocols like Codable and Equatable, and enums can't
/// inherit from types Strings and Ints.
public class CleanInheritancesTranspilationPass: TranspilationPass {
	private func isNotASwiftProtocol(_ protocolName: String) -> Bool {
		return ![
			"Equatable", "Codable", "Decodable", "Encodable", "CustomStringConvertible",
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
		access: String?, name: String, inherits: [String], elements: [EnumElement],
		members: [Statement], isImplicit: Bool) -> [Statement]
	{
		return [.enumDeclaration(
			access: access, name: name,
			inherits: inherits.filter {
				isNotASwiftProtocol($0) && isNotASwiftRawRepresentableType($0)
			},
			elements: elements,
			members: super.replaceStatements(members),
			isImplicit: isImplicit), ]
	}

	override func replaceStructDeclaration(
		annotations: String?, name: String, inherits: [String], members: [Statement]) -> [Statement]
	{
		return [.structDeclaration(
			annotations: annotations,
			name: name,
			inherits: inherits.filter(isNotASwiftProtocol),
			members: super.replaceStatements(members)), ]
	}
}

/// The "anonymous parameter" `$0` has to be replaced by `it`
public class AnonymousParametersTranspilationPass: TranspilationPass {
	override func replaceDeclarationReferenceExpression(
		identifier: String, type: String, isStandardLibrary: Bool, isImplicit: Bool)
		-> Expression
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
		parameters: [LabeledType], statements: [Statement], type: String)
		-> Expression
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
public class ReturnsInLambdasTranspilationPass: TranspilationPass {
	var isInClosure = false

	override func replaceClosureExpression(
		parameters: [LabeledType], statements: [Statement], type: String)
		-> Expression
	{
		isInClosure = true
		defer { isInClosure = false }
		return super.replaceClosureExpression(
			parameters: parameters, statements: statements, type: type)
	}

	override func replaceReturnStatement(expression: Expression?) -> [Statement] {
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
public class SwitchesToExpressionsTranspilationPass: TranspilationPass {
	/// Detect switches whose bodies all end in the same returns or assignments
	override func replaceSwitchStatement(
		convertsToExpression: Statement?, expression: Expression,
		cases: [SwitchCase]) -> [Statement]
	{
		var hasAllReturnCases = true
		var hasAllAssignmentCases = true
		var assignmentExpression: Expression?

		for statements in cases.map({ $0.statements }) {
			// TODO: breaks in switches are ignored, which will be incorrect if there's code after
			// the break. Throw a warning.
			guard let lastStatement = statements.last else {
				hasAllReturnCases = false
				hasAllAssignmentCases = false
				break
			}

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
				break
			}
		}

		if hasAllReturnCases {
			var newCases = [SwitchCase]()
			for switchCase in cases {
				// Swift switches must have at least one statement
				let lastStatement = switchCase.statements.last!
				if case let .returnStatement(expression: maybeExpression) = lastStatement,
					let returnExpression = maybeExpression
				{
					var newStatements = Array(switchCase.statements.dropLast())
					newStatements.append(.expression(expression: returnExpression))
					newCases.append(SwitchCase(
						expression: switchCase.expression, statements: newStatements))
				}
			}
			let conversionExpression =
				Statement.returnStatement(expression: .nilLiteralExpression)
			return [.switchStatement(
				convertsToExpression: conversionExpression, expression: expression,
				cases: newCases), ]
		}
		else if hasAllAssignmentCases, let assignmentExpression = assignmentExpression {
			var newCases = [SwitchCase]()
			for switchCase in cases {
				// Swift switches must have at least one statement
				let lastStatement = switchCase.statements.last!
				if case let .assignmentStatement(leftHand: _, rightHand: rightHand) = lastStatement
				{
					var newStatements = Array(switchCase.statements.dropLast())
					newStatements.append(.expression(expression: rightHand))
					newCases.append(SwitchCase(
						expression: switchCase.expression, statements: newStatements))
				}
			}
			let conversionExpression = Statement.assignmentStatement(
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
	override func replaceStatements(_ oldStatement: [Statement]) -> [Statement] {
		var statements = super.replaceStatements(oldStatement)

		var result = [Statement]()

		var i = 0
		while i < (statements.count - 1) {
			let currentStatement = statements[i]
			let nextStatement = statements[i + 1]
			if case var .variableDeclaration(value: variableDeclaration) = currentStatement,
				variableDeclaration.isImplicit == false,
				variableDeclaration.extendsType == nil,
				case let .switchStatement(
					convertsToExpression: maybeConversion, expression: switchExpression,
					cases: cases) = nextStatement,
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
					Statement.variableDeclaration(value: variableDeclaration)
				result.append(.switchStatement(
					convertsToExpression: newConversionExpression, expression: switchExpression,
					cases: cases))

				// Skip appending variable declaration and the switch declaration, thus replacing
				// both with the new switch declaration
				i += 2
			}
			else {
				result.append(currentStatement)
				i += 1
			}
		}

		if let lastStatement = statements.last {
			result.append(lastStatement)
		}

		return result
	}
}

public class RemoveExtensionsTranspilationPass: TranspilationPass {
	var extendingType: String?

	override func replaceExtension(type: String, members: [Statement]) -> [Statement] {
		extendingType = type
		let members = replaceStatements(members)
		extendingType = nil
		return members
	}

	override func replaceStatement(_ statement: Statement) -> [Statement] {
		switch statement {
		case let .extensionDeclaration(type: type, members: members):
			return replaceExtension(type: type, members: members)
		case let .functionDeclaration(value: functionDeclaration):
			return replaceFunctionDeclaration(functionDeclaration)
		case let .variableDeclaration(value: variableDeclaration):
			return replaceVariableDeclaration(variableDeclaration)
		default:
			return [statement]
		}
	}

	override func replaceFunctionDeclaration(_ functionDeclaration: FunctionDeclaration)
		-> [Statement]
	{
		var functionDeclaration = functionDeclaration
		functionDeclaration.extendsType = self.extendingType
		return [Statement.functionDeclaration(value: functionDeclaration)]
	}

	override func replaceVariableDeclaration(_ variableDeclaration: VariableDeclaration)
		-> VariableDeclaration
	{
		var variableDeclaration = variableDeclaration
		variableDeclaration.extendsType = self.extendingType
		return variableDeclaration
	}
}

/// Swift functions (both declarations and calls) have to be translated using their internal
/// parameter names, not their API names. This is both for correctness and readability. Since calls
/// only contain the API names, we need a way to use the API names to retrieve the internal names.
/// KotlinTranslator has an array of "translations" exactly for this purpose: it uses the Swift
/// name (with API labels) and the type to look up the "translation" and stores the prefix and the
/// internal names it should return.
/// This pass goes through all the function declarations it finds and stores the information needed
/// to translate these functions correctly later.
public class RecordFunctionTranslationsTranspilationPass: TranspilationPass {
	override func replaceFunctionDeclaration(
		_ functionDeclaration: FunctionDeclaration) -> [Statement]
	{
		let swiftAPIName = functionDeclaration.prefix + "(" +
			functionDeclaration.parameters.map { ($0.apiLabel ?? $0.label) + ":" }.joined() + ")"

		KotlinTranslator.addFunctionTranslation(KotlinTranslator.FunctionTranslation(
			swiftAPIName: swiftAPIName,
			type: functionDeclaration.functionType,
			prefix: functionDeclaration.prefix,
			parameters: functionDeclaration.parameters.map { $0.label }))
		return super.replaceFunctionDeclaration(functionDeclaration)
	}
}

public class RecordEnumsTranspilationPass: TranspilationPass {
	override func replaceEnumDeclaration(
		access: String?, name: String, inherits: [String], elements: [EnumElement],
		members: [Statement], isImplicit: Bool) -> [Statement]
	{
		let isEnumClass = inherits.isEmpty && elements.reduce(true)
		{ (acc: Bool, element: EnumElement) -> Bool in
			acc && element.associatedValues.isEmpty
		}

		if isEnumClass {
			KotlinTranslator.addEnumClass(name)
		}
		else {
			KotlinTranslator.addSealedClass(name)
		}

		return [.enumDeclaration(
			access: access, name: name, inherits: inherits, elements: elements, members: members,
			isImplicit: isImplicit), ]
	}
}

public class RaiseStandardLibraryWarningsTranspilationPass: TranspilationPass {
	override func replaceDeclarationReferenceExpression(
		identifier: String, type: String, isStandardLibrary: Bool, isImplicit: Bool)
		-> Expression
	{
		if isStandardLibrary {
			Compiler.handleWarning(
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
public class RaiseMutableValueTypesWarningsTranspilationPass: TranspilationPass {
	override func replaceStructDeclaration(
		annotations: String?, name: String, inherits: [String], members: [Statement]) -> [Statement]
	{
		for member in members {
			if case let .variableDeclaration(value: variableDeclaration) = member,
				!variableDeclaration.isImplicit,
				!variableDeclaration.isStatic,
				!variableDeclaration.isLet,
				variableDeclaration.getter == nil
			{
				Compiler.handleWarning(
					"No support for mutable variables in value types: found variable " +
					"\(variableDeclaration.identifier) inside struct \(name)")
			}
			else if case let .functionDeclaration(value: functionDeclaration) = member,
				functionDeclaration.isMutating
			{
				let methodName = functionDeclaration.prefix + "(" +
					functionDeclaration.parameters.map { $0.label + ":" }
						.joined(separator: ", ") + ")"
				Compiler.handleWarning(
					"No support for mutating methods in value types: found method " +
					"\(methodName) inside struct \(name)")
			}
		}

		return super.replaceStructDeclaration(
			annotations: annotations, name: name, inherits: inherits, members: members)
	}

	override func replaceEnumDeclaration(
		access: String?, name: String, inherits: [String], elements: [EnumElement],
		members: [Statement], isImplicit: Bool) -> [Statement]
	{
		for member in members {
			if case let .functionDeclaration(value: functionDeclaration) = member,
				functionDeclaration.isMutating
			{
				let methodName = functionDeclaration.prefix + "(" +
					functionDeclaration.parameters.map { $0.label + ":" }
						.joined(separator: ", ") + ")"
				Compiler.handleWarning(
					"No support for mutating methods in value types: found method " +
					"\(methodName) inside enum \(name)")
			}
		}

		return super.replaceEnumDeclaration(
			access: access, name: name, inherits: inherits, elements: elements, members: members,
			isImplicit: isImplicit)
	}
}

public class RearrangeIfLetsTranspilationPass: TranspilationPass {

	/// Add conditions (`x != null`) for all let declarations
	override func replaceIfStatement(_ ifStatement: IfStatement) -> IfStatement {
		var letConditions = [Expression]()

		for declaration in ifStatement.declarations {
			letConditions.append(
				.binaryOperatorExpression(
					leftExpression: .declarationReferenceExpression(
						identifier: declaration.identifier,
						type: declaration.typeName,
						isStandardLibrary: false, isImplicit: false),
					rightExpression: .nilLiteralExpression, operatorSymbol: "!=",
					type: "Boolean"))
		}

		let ifStatement = ifStatement.copy()
		ifStatement.conditions = letConditions + ifStatement.conditions
		return super.replaceIfStatement(ifStatement)
	}

	/// Gather the let declarations from the if statement and its else( if)s into a single array
	private func gatherLetDeclarations(_ ifStatement: IfStatement?) -> [VariableDeclaration] {
		guard let ifStatement = ifStatement else {
			return []
		}

		let letDeclarations = ifStatement.declarations.filter { declaration in
			// If it's a shadowing identifier there's no need to declare it in Kotlin
			// (i.e. `if let x = x { }`)
			if let declarationExpression = declaration.expression,
				case .declarationReferenceExpression(
					identifier: declaration.identifier,
					type: _,
					isStandardLibrary: _,
					isImplicit: _) = declarationExpression
			{
				return false
			}
			else {
				return true
			}
		}

		let elseLetDeclarations = gatherLetDeclarations(ifStatement.elseStatement)

		return letDeclarations + elseLetDeclarations
	}

	/// Send the let declarations to before the if statement
	override func replaceIfStatement(_ ifStatement: IfStatement) -> [Statement] {
		let letDeclarations = gatherLetDeclarations(ifStatement)
			.map { Statement.variableDeclaration(value: $0) }
		return letDeclarations + super.replaceIfStatement(ifStatement)
	}
}

/// Guards are translated as if statements with a ! at the start of the condition. Sometimes, the
/// ! combines with a != or even another !, causing a double negative in the condition that can
/// be removed (or turned into a single ==). This pass performs that transformation.
public class DoubleNegativesInGuardsTranspilationPass: TranspilationPass {
	override func replaceIfStatement(_ ifStatement: IfStatement) -> IfStatement {
		if ifStatement.isGuard, ifStatement.conditions.count == 1 {
			let condition = ifStatement.conditions[0]
			let shouldStillBeGuard: Bool
			let newCondition: Expression
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

			let ifStatement = ifStatement.copy()
			ifStatement.conditions = [newCondition]
			ifStatement.isGuard = shouldStillBeGuard
			return super.replaceIfStatement(ifStatement)
		}
		else {
			return super.replaceIfStatement(ifStatement)
		}
	}
}

/// Statements of the type `if (a == null) { return }` in Swift can be translated as `a ?: return`
/// in Kotlin.
public class ReturnIfNilTranspilationPass: TranspilationPass {
	override func replaceStatement(_ statement: Statement) -> [Statement] {
		if case let .ifStatement(value: ifStatement) = statement,
			ifStatement.conditions.count == 1,
			let onlyCondition = ifStatement.conditions.first,
			case let .binaryOperatorExpression(
				leftExpression: declarationReference,
				rightExpression: Expression.nilLiteralExpression,
				operatorSymbol: "==",
				type: _) = onlyCondition,
			case let .declarationReferenceExpression(
				identifier: _,
				type: type,
				isStandardLibrary: _,
				isImplicit: _) = declarationReference,
			ifStatement.statements.count == 1,
			let onlyStatement = ifStatement.statements.first,
			case let .returnStatement(expression: returnExpression) = onlyStatement
		{
			return [.expression(expression:
				.binaryOperatorExpression(
					leftExpression: declarationReference,
					rightExpression: .returnExpression(expression: returnExpression),
					operatorSymbol: "?:",
					type: type)), ]
		}
		else {
			return super.replaceStatement(statement)
		}
	}
}

public class FixProtocolContentsTranspilationPass: TranspilationPass {
	var isInProtocol = false

	override func replaceProtocolDeclaration(
		name: String, members: [Statement]) -> [Statement]
	{
		isInProtocol = true
		let result = super.replaceProtocolDeclaration(name: name, members: members)
		isInProtocol = false

		return result
	}

	override func replaceFunctionDeclaration(_ functionDeclaration: FunctionDeclaration)
		-> [Statement]
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

public extension TranspilationPass {
	static func runAllPasses(on sourceFile: GryphonAST) -> GryphonAST {
		var result = sourceFile
		result = LibraryTranspilationPass().run(on: result)
		result = RemoveImplicitDeclarationsTranspilationPass().run(on: result)
		result = RemoveParenthesesTranspilationPass().run(on: result)

		result = RemoveExtraReturnsInInitsTranspilationPass().run(on: result)
		result = OptionalInitsTranspilationPass().run(on: result)
		result = StaticMembersTranspilationPass().run(on: result)
		result = FixProtocolContentsTranspilationPass().run(on: result)
		result = CleanInheritancesTranspilationPass().run(on: result)
		result = AnonymousParametersTranspilationPass().run(on: result)
		result = SelfToThisTranspilationPass().run(on: result)

		result = RecordFunctionTranslationsTranspilationPass().run(on: result)
		result = RecordEnumsTranspilationPass().run(on: result)
		result = CapitalizeEnumsTranspilationPass().run(on: result)
		result = OmitImplicitEnumPrefixesTranspilationPass().run(on: result)
		result = SwitchesToExpressionsTranspilationPass().run(on: result)

		result = ReturnsInLambdasTranspilationPass().run(on: result)
		result = InnerTypePrefixesTranspilationPass().run(on: result)
		result = RenameOperatorsTranspilationPass().run(on: result)
		result = RemoveExtensionsTranspilationPass().run(on: result)

		result = RearrangeIfLetsTranspilationPass().run(on: result)
		result = DoubleNegativesInGuardsTranspilationPass().run(on: result)
		result = ReturnIfNilTranspilationPass().run(on: result)

		result = RaiseStandardLibraryWarningsTranspilationPass().run(on: result)
		result = RaiseMutableValueTypesWarningsTranspilationPass().run(on: result)

		return result
	}

	func printParents() {
		print("[")
		for parent in parents {
			switch parent {
			case let .statement(statement):
				print("\t\(statement.name),")
			case let .expression(expression):
				print("\t\(expression.name),")
			}
		}
		print("]")
	}
}

//
internal enum ASTNode {
	case statement(Statement)
	case expression(Expression)
}
