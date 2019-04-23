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
	internal static func isASwiftRawRepresentableType(_ typeName: String) -> Bool {
		return [
			"String",
			"Int", "Int8", "Int16", "Int32", "Int64",
			"UInt", "UInt8", "UInt16", "UInt32", "UInt64",
			"Float", "Float32", "Float64", "Float80", "Double",
			].contains(typeName)
	}

	//
	var ast: GryphonAST

	fileprivate var parents = ArrayClass<ASTNode>()
	fileprivate var parent: ASTNode {
		return parents.secondToLast!
	}

	init(ast: GryphonAST) {
		self.ast = ast
	}

	func run() -> GryphonAST {
		let replacedStatements = replaceStatements(ast.statements)
		let replacedDeclarations = replaceStatements(ast.declarations)
		return GryphonAST(
			sourceFile: ast.sourceFile,
			declarations: replacedDeclarations,
			statements: replacedStatements)
	}

	func replaceStatements(_ statements: ArrayClass<Statement>) -> ArrayClass<Statement> {
		return statements.flatMap(replaceStatement)
	}

	func replaceStatement(_ statement: Statement) -> ArrayClass<Statement> {
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
		case let .functionDeclaration(data: functionDeclaration):
			return replaceFunctionDeclaration(functionDeclaration)
		case let .variableDeclaration(data: variableDeclaration):

			return replaceVariableDeclaration(variableDeclaration)
		case let .forEachStatement(
			collection: collection, variable: variable, statements: statements):

			return replaceForEachStatement(
				collection: collection, variable: variable, statements: statements)
		case let .whileStatement(expression: expression, statements: statements):
			return replaceWhileStatement(expression: expression, statements: statements)
		case let .ifStatement(data: ifStatement):
			return replaceIfStatement(ifStatement)
		case let .switchStatement(
			convertsToExpression: convertsToExpression, expression: expression, cases: cases):

			return replaceSwitchStatement(
				convertsToExpression: convertsToExpression, expression: expression, cases: cases)
		case let .deferStatement(statements: statements):
			return replaceDeferStatement(statements: statements)
		case let .throwStatement(expression: expression):
			return replaceThrowStatement(expression: expression)
		case let .returnStatement(expression: expression):
			return replaceReturnStatement(expression: expression)
		case .breakStatement:
			return [.breakStatement]
		case .continueStatement:
			return [.continueStatement]
		case let .assignmentStatement(leftHand: leftHand, rightHand: rightHand):
			return replaceAssignmentStatement(leftHand: leftHand, rightHand: rightHand)
		case .error:
			return [.error]
		}
	}

	func replaceExpression(expression: Expression) -> ArrayClass<Statement> {
		return [.expression(expression: replaceExpression(expression))]
	}

	func replaceExtension(type: String, members: ArrayClass<Statement>) -> ArrayClass<Statement> {
		return [.extensionDeclaration(type: type, members: replaceStatements(members))]
	}

	func replaceImportDeclaration(name: String) -> ArrayClass<Statement> {
		return [.importDeclaration(name: name)]
	}

	func replaceTypealiasDeclaration(identifier: String, type: String, isImplicit: Bool)
		-> ArrayClass<Statement>
	{
		return [.typealiasDeclaration(identifier: identifier, type: type, isImplicit: isImplicit)]
	}

	func replaceClassDeclaration(
		name: String,
		inherits: ArrayClass<String>,
		members: ArrayClass<Statement>)
		-> ArrayClass<Statement>
	{
		return [.classDeclaration(
			name: name, inherits: inherits, members: replaceStatements(members)), ]
	}

	func replaceCompanionObject(members: ArrayClass<Statement>) -> ArrayClass<Statement> {
		return [.companionObject(members: replaceStatements(members))]
	}

	func replaceEnumDeclaration(
		access: String?, name: String, inherits: ArrayClass<String>, elements: ArrayClass<EnumElement>,
		members: ArrayClass<Statement>, isImplicit: Bool) -> ArrayClass<Statement>
	{
		return [
			.enumDeclaration(
				access: access, name: name, inherits: inherits,
				elements: elements.flatMap {
						replaceEnumElementDeclaration(
							name: $0.name,
							associatedValues: $0.associatedValues,
							rawValue: $0.rawValue,
							annotations: $0.annotations)
					},
				members: replaceStatements(members), isImplicit: isImplicit), ]
	}

	func replaceEnumElementDeclaration(
		name: String,
		associatedValues: ArrayClass<LabeledType>,
		rawValue: Expression?,
		annotations: String?)
		-> ArrayClass<EnumElement>
	{
		return [EnumElement(
			name: name,
			associatedValues: associatedValues,
			rawValue: rawValue,
			annotations: annotations), ]
	}

	func replaceProtocolDeclaration(
		name: String,
		members: ArrayClass<Statement>)
		-> ArrayClass<Statement>
	{
		return [.protocolDeclaration(name: name, members: replaceStatements(members))]
	}

	func replaceStructDeclaration(
		annotations: String?,
		name: String,
		inherits: ArrayClass<String>,
		members: ArrayClass<Statement>)
		-> ArrayClass<Statement>
	{
		return [.structDeclaration(
			annotations: annotations,
			name: name,
			inherits: inherits,
			members: replaceStatements(members)), ]
	}

	func replaceFunctionDeclaration(_ functionDeclaration: FunctionDeclarationData)
		-> ArrayClass<Statement>
	{
		if let result = replaceFunctionDeclaration(functionDeclaration) {
			return [.functionDeclaration(data: result)]
		}
		else {
			return []
		}
	}

	func replaceFunctionDeclaration(_ functionDeclaration: FunctionDeclarationData)
		-> FunctionDeclarationData?
	{
		let replacedParameters = functionDeclaration.parameters
			.map {
				FunctionParameter(
					label: $0.label,
					apiLabel: $0.apiLabel,
					type: $0.type,
					value: $0.value.map(replaceExpression))
			}

		let functionDeclaration = functionDeclaration
		functionDeclaration.parameters = replacedParameters
		functionDeclaration.statements = functionDeclaration.statements.map(replaceStatements)
		return functionDeclaration
	}

	func replaceVariableDeclaration(_ variableDeclaration: VariableDeclarationData)
		-> ArrayClass<Statement>
	{
		return [.variableDeclaration(data: replaceVariableDeclaration(variableDeclaration))]
	}

	func replaceVariableDeclaration(_ variableDeclaration: VariableDeclarationData)
		-> VariableDeclarationData
	{
		let variableDeclaration = variableDeclaration
		variableDeclaration.expression = variableDeclaration.expression.map(replaceExpression)
		if let getter = variableDeclaration.getter {
			variableDeclaration.getter = replaceFunctionDeclaration(getter)
		}
		if let setter = variableDeclaration.setter {
			variableDeclaration.setter = replaceFunctionDeclaration(setter)
		}
		return variableDeclaration
	}

	func replaceForEachStatement(
		collection: Expression, variable: Expression, statements: ArrayClass<Statement>)
		-> ArrayClass<Statement>
	{
		return [.forEachStatement(
			collection: replaceExpression(collection),
			variable: replaceExpression(variable),
			statements: replaceStatements(statements)), ]
	}

	func replaceWhileStatement(
		expression: Expression,
		statements: ArrayClass<Statement>)
		-> ArrayClass<Statement>
	{
		return [.whileStatement(
			expression: replaceExpression(expression),
			statements: replaceStatements(statements)), ]
	}

	func replaceIfStatement(_ ifStatement: IfStatementData) -> ArrayClass<Statement> {
		return [Statement.ifStatement(data: replaceIfStatement(ifStatement))]
	}

	func replaceIfStatement(_ ifStatement: IfStatementData) -> IfStatementData {
		let ifStatement = ifStatement
		ifStatement.conditions = replaceIfConditions(ifStatement.conditions)
		ifStatement.declarations = ifStatement.declarations.map(replaceVariableDeclaration)
		ifStatement.statements = replaceStatements(ifStatement.statements)
		ifStatement.elseStatement = ifStatement.elseStatement.map(replaceIfStatement)
		return ifStatement
	}

	func replaceIfConditions(_ conditions: ArrayClass<IfStatementData.Condition>)
		-> ArrayClass<IfStatementData.Condition>
	{
		return conditions.map { condition -> IfStatementData.Condition in
			switch condition {
			case let .condition(expression: expression):
				return .condition(expression: replaceExpression(expression))
			case let .declaration(variableDeclaration: variableDeclaration):
				return .declaration(
					variableDeclaration: replaceVariableDeclaration(variableDeclaration))
			}
		}
	}

	func replaceSwitchStatement(
		convertsToExpression: Statement?, expression: Expression,
		cases: ArrayClass<SwitchCase>) -> ArrayClass<Statement>
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

	func replaceDeferStatement(statements: ArrayClass<Statement>) -> ArrayClass<Statement> {
		return [.deferStatement(statements: replaceStatements(statements))]
	}

	func replaceThrowStatement(expression: Expression) -> ArrayClass<Statement> {
		return [.throwStatement(expression: replaceExpression(expression))]
	}

	func replaceReturnStatement(expression: Expression?) -> ArrayClass<Statement> {
		return [.returnStatement(expression: expression.map(replaceExpression))]
	}

	func replaceAssignmentStatement(leftHand: Expression, rightHand: Expression)
		-> ArrayClass<Statement>
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
		case let .declarationReferenceExpression(data: declarationReferenceExpression):
			return replaceDeclarationReferenceExpression(declarationReferenceExpression)
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
		case let .ifExpression(
			condition: condition, trueExpression: trueExpression, falseExpression: falseExpression):

			return replaceIfExpression(
				condition: condition,
				trueExpression: trueExpression,
				falseExpression: falseExpression)
		case let .callExpression(data: callExpression):
			return replaceCallExpression(callExpression)
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

	func replaceTemplateExpression(pattern: String, matches: DictionaryClass<String, Expression>)
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
		_ declarationReferenceExpression: DeclarationReferenceData) -> Expression
	{
		return .declarationReferenceExpression(
			data: replaceDeclarationReferenceExpression(declarationReferenceExpression))
	}

	func replaceDeclarationReferenceExpression(
		_ declarationReferenceExpression: DeclarationReferenceData)
		-> DeclarationReferenceData
	{
		return declarationReferenceExpression
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

	func replaceArrayExpression(elements: ArrayClass<Expression>, type: String) -> Expression {
		return .arrayExpression(elements: elements.map(replaceExpression), type: type)
	}

	func replaceDictionaryExpression(
		keys: ArrayClass<Expression>,
		values: ArrayClass<Expression>,
		type: String)
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

	func replaceIfExpression(
		condition: Expression, trueExpression: Expression, falseExpression: Expression)
		-> Expression
	{
		return .ifExpression(
			condition: replaceExpression(condition),
			trueExpression: replaceExpression(trueExpression),
			falseExpression: replaceExpression(falseExpression))
	}

	func replaceCallExpression(_ callExpression: CallExpressionData) -> Expression {
		return .callExpression(data: replaceCallExpression(callExpression))
	}

	func replaceCallExpression(_ callExpression: CallExpressionData) -> CallExpressionData {
		return CallExpressionData(
			function: replaceExpression(callExpression.function),
			parameters: replaceExpression(callExpression.parameters),
			type: callExpression.type,
			range: callExpression.range)
	}

	func replaceClosureExpression(
		parameters: ArrayClass<LabeledType>, statements: ArrayClass<Statement>, type: String)
		-> Expression
	{
		return .closureExpression(
			parameters: parameters,
			statements: replaceStatements(statements),
			type: type)
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

	func replaceInterpolatedStringLiteralExpression(expressions: ArrayClass<Expression>)
		-> Expression
	{
		return .interpolatedStringLiteralExpression(expressions: expressions.map(replaceExpression))
	}

	func replaceTupleExpression(pairs: ArrayClass<LabeledExpression>) -> Expression {
		return .tupleExpression( pairs: pairs.map {
			LabeledExpression(label: $0.label, expression: replaceExpression($0.expression))
		})
	}

	func replaceTupleShuffleExpression(
		labels: ArrayClass<String>,
		indices: ArrayClass<TupleShuffleIndex>,
		expressions: ArrayClass<Expression>)
		-> Expression
	{
		return .tupleShuffleExpression(
			labels: labels, indices: indices, expressions: expressions.map(replaceExpression))
	}
}

public class DescriptionAsToStringTranspilationPass: TranspilationPass {
	override func replaceVariableDeclaration(_ variableDeclaration: VariableDeclarationData)
		-> ArrayClass<Statement>
	{
		if variableDeclaration.identifier == "description",
			variableDeclaration.typeName == "String",
			let getter = variableDeclaration.getter
		{
			return [.functionDeclaration(data: FunctionDeclarationData(
				prefix: "toString",
				parameters: [],
				returnType: "String",
				functionType: "() -> String",
				genericTypes: [],
				isImplicit: false,
				isStatic: false,
				isMutating: false,
				extendsType: variableDeclaration.extendsType,
				statements: getter.statements,
				access: nil,
				annotations: variableDeclaration.annotations)), ]
		}

		return super.replaceVariableDeclaration(variableDeclaration)
	}
}

public class RemoveParenthesesTranspilationPass: TranspilationPass {
	override func replaceSubscriptExpression(
		subscriptedExpression: Expression, indexExpression: Expression, type: String) -> Expression
	{
		if case let .parenthesesExpression(expression: innerExpression) = indexExpression {
			return super.replaceSubscriptExpression(
				subscriptedExpression: subscriptedExpression,
				indexExpression: innerExpression,
				type: type)
		}

		return super.replaceSubscriptExpression(
			subscriptedExpression: subscriptedExpression,
			indexExpression: indexExpression,
			type: type)
	}

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

	override func replaceIfExpression(
		condition: Expression, trueExpression: Expression, falseExpression: Expression)
		-> Expression
	{
		let replacedCondition: Expression
		if case let .parenthesesExpression(expression: innerExpression) = condition {
			replacedCondition = innerExpression
		}
		else {
			replacedCondition = condition
		}

		let replacedTrueExpression: Expression
		if case let .parenthesesExpression(expression: innerExpression) = trueExpression {
			replacedTrueExpression = innerExpression
		}
		else {
			replacedTrueExpression = trueExpression
		}

		let replacedFalseExpression: Expression
		if case let .parenthesesExpression(expression: innerExpression) = falseExpression {
			replacedFalseExpression = innerExpression
		}
		else {
			replacedFalseExpression = falseExpression
		}

		return .ifExpression(
			condition: replacedCondition,
			trueExpression: replacedTrueExpression,
			falseExpression: replacedFalseExpression)
	}
}

/// Removes implicit declarations so that they don't show up on the translation
public class RemoveImplicitDeclarationsTranspilationPass: TranspilationPass {
	override func replaceEnumDeclaration(
		access: String?, name: String, inherits: ArrayClass<String>, elements: ArrayClass<EnumElement>,
		members: ArrayClass<Statement>, isImplicit: Bool) -> ArrayClass<Statement>
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
		identifier: String, type: String, isImplicit: Bool) -> ArrayClass<Statement>
	{
		if isImplicit {
			return []
		}
		else {
			return super.replaceTypealiasDeclaration(
				identifier: identifier, type: type, isImplicit: isImplicit)
		}
	}

	override func replaceVariableDeclaration(_ variableDeclaration: VariableDeclarationData)
		-> ArrayClass<Statement>
	{
		if variableDeclaration.isImplicit {
			return []
		}
		else {
			return super.replaceVariableDeclaration(variableDeclaration)
		}
	}

	override func replaceFunctionDeclaration(_ functionDeclaration: FunctionDeclarationData)
		-> FunctionDeclarationData?
	{
		if functionDeclaration.isImplicit {
			return nil
		}
		else {
			return super.replaceFunctionDeclaration(functionDeclaration)
		}
	}
}

/// Optional initializers can be translated as `invoke` operators to have similar syntax and
/// functionality.
public class OptionalInitsTranspilationPass: TranspilationPass {
	private var isFailableInitializer: Bool = false

	override func replaceFunctionDeclaration(_ functionDeclaration: FunctionDeclarationData)
		-> FunctionDeclarationData?
	{
		if functionDeclaration.isStatic == true,
			functionDeclaration.extendsType == nil,
			functionDeclaration.prefix == "init"
		{
			if functionDeclaration.returnType.hasSuffix("?") {
				let functionDeclaration = functionDeclaration

				isFailableInitializer = true
				let newStatements = replaceStatements(functionDeclaration.statements ?? [])
				isFailableInitializer = false

				functionDeclaration.prefix = "invoke"
				functionDeclaration.statements = newStatements
				return functionDeclaration
			}
		}

		return super.replaceFunctionDeclaration(functionDeclaration)
	}

	override func replaceAssignmentStatement(leftHand: Expression, rightHand: Expression)
		-> ArrayClass<Statement>
	{
		if isFailableInitializer,
			case let .declarationReferenceExpression(data: expression) = leftHand,
			expression.identifier == "self"
		{
			return [.returnStatement(expression: rightHand)]
		}
		else {
			return super.replaceAssignmentStatement(leftHand: leftHand, rightHand: rightHand)
		}
	}
}

public class RemoveExtraReturnsInInitsTranspilationPass: TranspilationPass {
	override func replaceFunctionDeclaration(_ functionDeclaration: FunctionDeclarationData)
		-> FunctionDeclarationData?
	{
		if functionDeclaration.isStatic == true,
			functionDeclaration.extendsType == nil,
			functionDeclaration.prefix == "init",
			let lastStatement = functionDeclaration.statements?.last,
			case .returnStatement(expression: nil) = lastStatement
		{
			let functionDeclaration = functionDeclaration
			functionDeclaration.statements?.removeLast()
			return functionDeclaration
		}

		return functionDeclaration
	}
}

/// The static functions and variables in a class must all be placed inside a single companion
/// object.
public class StaticMembersTranspilationPass: TranspilationPass {
	private func sendStaticMembersToCompanionObject(_ members: ArrayClass<Statement>)
		-> ArrayClass<Statement>
	{
		let isStaticMember = { (member: Statement) -> Bool in
			if case let .functionDeclaration(data: functionDeclaration) = member,
				functionDeclaration.isStatic == true,
				functionDeclaration.extendsType == nil,
				functionDeclaration.prefix != "init"
			{
				return true
			}
			else if case let .variableDeclaration(data: variableDeclaration) = member,
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

		let newMembers = ArrayClass([.companionObject(members: staticMembers)]) + nonStaticMembers
		return newMembers
	}

	override func replaceClassDeclaration(
		name: String,
		inherits: ArrayClass<String>,
		members: ArrayClass<Statement>)
		-> ArrayClass<Statement>
	{
		let newMembers = sendStaticMembersToCompanionObject(members)
		return super.replaceClassDeclaration(name: name, inherits: inherits, members: newMembers)
	}

	override func replaceStructDeclaration(
		annotations: String?,
		name: String,
		inherits: ArrayClass<String>,
		members: ArrayClass<Statement>)
		-> ArrayClass<Statement>
	{
		let newMembers = sendStaticMembersToCompanionObject(members)
		return super.replaceStructDeclaration(
			annotations: annotations,
			name: name,
			inherits: inherits,
			members: newMembers)
	}

	override func replaceEnumDeclaration(
		access: String?, name: String, inherits: ArrayClass<String>, elements: ArrayClass<EnumElement>,
		members: ArrayClass<Statement>, isImplicit: Bool) -> ArrayClass<Statement>
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
		name: String,
		inherits: ArrayClass<String>,
		members: ArrayClass<Statement>)
		-> ArrayClass<Statement>
	{
		typeNamesStack.append(name)
		let result = super.replaceClassDeclaration(name: name, inherits: inherits, members: members)
		typeNamesStack.removeLast()
		return result
	}

	override func replaceStructDeclaration(
		annotations: String?,
		name: String,
		inherits: ArrayClass<String>,
		members: ArrayClass<Statement>)
		-> ArrayClass<Statement>
	{
		typeNamesStack.append(name)
		let result = super.replaceStructDeclaration(
			annotations: annotations, name: name, inherits: inherits, members: members)
		typeNamesStack.removeLast()
		return result
	}

	override func replaceVariableDeclaration(_ variableDeclaration: VariableDeclarationData)
		-> VariableDeclarationData
	{
		let variableDeclaration = variableDeclaration
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
			case let .declarationReferenceExpression(data: enumExpression) = rightExpression
		{
			let lastEnumType = String(enumType.split(separator: ".").last!)

			if KotlinTranslator.sealedClasses.contains(lastEnumType) {
				let enumExpression = enumExpression
				enumExpression.identifier = enumExpression.identifier.capitalizedAsCamelCase
				return .dotExpression(
					leftExpression: .typeExpression(type: enumType),
					rightExpression: .declarationReferenceExpression(data: enumExpression))
			}
			else if KotlinTranslator.enumClasses.contains(lastEnumType) {
				let enumExpression = enumExpression
				enumExpression.identifier = enumExpression.identifier.upperSnakeCase()
				return .dotExpression(
					leftExpression: .typeExpression(type: enumType),
					rightExpression: .declarationReferenceExpression(data: enumExpression))
			}
		}

		return super.replaceDotExpression(
			leftExpression: leftExpression, rightExpression: rightExpression)
	}

	override func replaceEnumDeclaration(
		access: String?,
		name: String,
		inherits: ArrayClass<String>,
		elements: ArrayClass<EnumElement>,
		members: ArrayClass<Statement>,
		isImplicit: Bool)
		-> ArrayClass<Statement>
	{
		let isSealedClass = KotlinTranslator.sealedClasses.contains(name)
		let isEnumClass = KotlinTranslator.enumClasses.contains(name)

		let newElements = elements.map { (element: EnumElement) -> EnumElement in
			if isSealedClass {
				return EnumElement(
					name: element.name.capitalizedAsCamelCase,
					associatedValues: element.associatedValues,
					rawValue: element.rawValue,
					annotations: element.annotations)
			}
			else if isEnumClass {
				return EnumElement(
					name: element.name.upperSnakeCase(),
					associatedValues: element.associatedValues,
					rawValue: element.rawValue,
					annotations: element.annotations)
			}
			else {
				return element
			}
		}

		return super.replaceEnumDeclaration(
			access: access,
			name: name,
			inherits: inherits,
			elements: newElements,
			members: members,
			isImplicit: isImplicit)
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
			case let .declarationReferenceExpression(data: enumExpression) = rightExpression,
			enumExpression.type == "(\(enumType).Type) -> \(enumType)",
			!KotlinTranslator.sealedClasses.contains(enumType)
		{
			return .declarationReferenceExpression(data: enumExpression)
		}
		else {
			return super.replaceDotExpression(
				leftExpression: leftExpression, rightExpression: rightExpression)
		}
	}

	override func replaceFunctionDeclaration(_ functionDeclaration: FunctionDeclarationData)
		-> FunctionDeclarationData?
	{
		returnTypesStack.append(functionDeclaration.returnType)
		defer { returnTypesStack.removeLast() }
		return super.replaceFunctionDeclaration(functionDeclaration)
	}

	override func replaceReturnStatement(expression: Expression?) -> ArrayClass<Statement> {
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
		if case let .declarationReferenceExpression(data: expression) = leftExpression,
			expression.identifier == "self",
			expression.isImplicit
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
		_ expression: DeclarationReferenceData) -> DeclarationReferenceData
	{
		if expression.identifier == "self" {
			let expression = expression
			expression.identifier = "this"
			return expression
		}
		return super.replaceDeclarationReferenceExpression(expression)
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

	override func replaceEnumDeclaration(
		access: String?, name: String, inherits: ArrayClass<String>, elements: ArrayClass<EnumElement>,
		members: ArrayClass<Statement>, isImplicit: Bool) -> ArrayClass<Statement>
	{
		return super.replaceEnumDeclaration(
			access: access,
			name: name,
			inherits: inherits.filter {
					isNotASwiftProtocol($0) && !TranspilationPass.isASwiftRawRepresentableType($0)
				},
			elements: elements,
			members: members,
			isImplicit: isImplicit)
	}

	override func replaceStructDeclaration(
		annotations: String?,
		name: String,
		inherits: ArrayClass<String>,
		members: ArrayClass<Statement>)
		-> ArrayClass<Statement>
	{
		return super.replaceStructDeclaration(
			annotations: annotations,
			name: name,
			inherits: inherits.filter(isNotASwiftProtocol),
			members: members)
	}

	override func replaceClassDeclaration(
		name: String,
		inherits: ArrayClass<String>,
		members: ArrayClass<Statement>)
		-> ArrayClass<Statement>
	{
		return super.replaceClassDeclaration(
			name: name,
			inherits: inherits.filter(isNotASwiftProtocol),
			members: members)
	}
}

/// The "anonymous parameter" `$0` has to be replaced by `it`
public class AnonymousParametersTranspilationPass: TranspilationPass {
	override func replaceDeclarationReferenceExpression(
		_ expression: DeclarationReferenceData) -> DeclarationReferenceData
	{
		if expression.identifier == "$0" {
			let expression = expression
			expression.identifier = "it"
			return expression
		}
		else {
			return super.replaceDeclarationReferenceExpression(expression)
		}
	}

	override func replaceClosureExpression(
		parameters: ArrayClass<LabeledType>, statements: ArrayClass<Statement>, type: String)
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

/// ArrayClass needs explicit initializers to account for the fact that it can't be implicitly
/// cast to covariant types. For instance:
///
/// ````
/// let myIntArray: ArrayClass = [1, 2, 3]
/// let myAnyArray = myIntArray as ArrayClass<Any> // error
/// let myAnyArray = ArrayClass<Any>(myIntArray) // OK
/// ````
///
/// This transformation can't be done with the current template mode because there's no way to get
/// the type for the cast. However, since this seems to be a specific case that only shows up in the
/// stdlib at the moment, this pass should serve as a workaround.
public class CovarianceInitsAsCastsTranspilationPass: TranspilationPass {
	override func replaceCallExpression(_ callExpression: CallExpressionData) -> Expression {
		if case let .typeExpression(type: type) = callExpression.function,
			type.hasPrefix("ArrayClass"),
			case let .tupleExpression(pairs: pairs) = callExpression.parameters,
			pairs.count == 1,
			let onlyPair = pairs.first
		{
			if onlyPair.label == "array" {
				// If we're initializing with an Array of a different type, we might need a cast
				if let arrayType = onlyPair.expression.type {
					let arrayElementType = arrayType.dropFirst().dropLast()
					let arrayClassElementType =
						type.dropFirst("ArrayClass<".count).dropLast()

					if arrayElementType != arrayClassElementType {
						return .binaryOperatorExpression(
							leftExpression: replaceExpression(onlyPair.expression),
							rightExpression: .typeExpression(type: type),
							operatorSymbol: "as",
							type: type)
					}
				}
				// If it's an Array of the same type, just return the array itself
				return replaceExpression(onlyPair.expression)
			}
			else {
				return .binaryOperatorExpression(
					leftExpression: replaceExpression(onlyPair.expression),
					rightExpression: .typeExpression(type: type),
					operatorSymbol: "as",
					type: type)
			}
		}
		else if case let .dotExpression(
				leftExpression: leftExpression,
				rightExpression: rightExpression) = callExpression.function,
			let leftType = leftExpression.type,
			leftType.hasPrefix("ArrayClass"),
			case let .declarationReferenceExpression(
				data: declarationReferenceExpression) = rightExpression,
			declarationReferenceExpression.identifier == "as",
			case let .tupleExpression(pairs: pairs) = callExpression.parameters,
			pairs.count == 1,
			let onlyPair = pairs.first,
			case let .typeExpression(type: type) = onlyPair.expression
		{
			return .binaryOperatorExpression(
				leftExpression: leftExpression,
				rightExpression: .typeExpression(type: type),
				operatorSymbol: "as?",
				type: type + "?")
		}
		else {
			return super.replaceCallExpression(callExpression)
		}
	}
}

/// Closures in kotlin can't have normal "return" statements. Instead, they must have return@f
/// statements (not yet implemented) or just standalone expressions (easier to implement but more
/// error-prone). This pass turns return statements in closures into standalone expressions
public class ReturnsInLambdasTranspilationPass: TranspilationPass {
	var isInClosure = false

	override func replaceClosureExpression(
		parameters: ArrayClass<LabeledType>,
		statements: ArrayClass<Statement>,
		type: String)
		-> Expression
	{
		isInClosure = true
		defer { isInClosure = false }
		return super.replaceClosureExpression(
			parameters: parameters, statements: statements, type: type)
	}

	override func replaceReturnStatement(expression: Expression?) -> ArrayClass<Statement> {
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
		cases: ArrayClass<SwitchCase>) -> ArrayClass<Statement>
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
			let newCases: ArrayClass<SwitchCase> = []
			for switchCase in cases {
				// Swift switches must have at least one statement
				let lastStatement = switchCase.statements.last!
				if case let .returnStatement(expression: maybeExpression) = lastStatement,
					let returnExpression = maybeExpression
				{
					let newStatements = ArrayClass(switchCase.statements.dropLast())
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
			let newCases: ArrayClass<SwitchCase> = []
			for switchCase in cases {
				// Swift switches must have at least one statement
				let lastStatement = switchCase.statements.last!
				if case let .assignmentStatement(leftHand: _, rightHand: rightHand) = lastStatement
				{
					let newStatements = ArrayClass(switchCase.statements.dropLast())
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
	override func replaceStatements(_ oldStatement: ArrayClass<Statement>) -> ArrayClass<Statement> {
		let statements = super.replaceStatements(oldStatement)

		let result: ArrayClass<Statement> = []

		var i = 0
		while i < (statements.count - 1) {
			let currentStatement = statements[i]
			let nextStatement = statements[i + 1]
			if case let .variableDeclaration(data: variableDeclaration) = currentStatement,
				variableDeclaration.isImplicit == false,
				variableDeclaration.extendsType == nil,
				case let .switchStatement(
					convertsToExpression: maybeConversion, expression: switchExpression,
					cases: cases) = nextStatement,
				let switchConversion = maybeConversion,
				case let .assignmentStatement(leftHand: leftHand, rightHand: _) = switchConversion,
				case let .declarationReferenceExpression(data: assignmentExpression) = leftHand,
				assignmentExpression.identifier == variableDeclaration.identifier,
				!assignmentExpression.isStandardLibrary,
				!assignmentExpression.isImplicit
			{
				variableDeclaration.expression = .nilLiteralExpression
				variableDeclaration.getter = nil
				variableDeclaration.setter = nil
				variableDeclaration.isStatic = false
				let newConversionExpression =
					Statement.variableDeclaration(data: variableDeclaration)
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

/// Breaks are not allowed in Kotlin `when` statements, but the `when` statements don't have to be
/// exhaustive. Just remove the cases that only have breaks.
public class RemoveBreaksInSwitchesTranspilationPass: TranspilationPass {
	override func replaceSwitchStatement(
		convertsToExpression: Statement?, expression: Expression, cases: ArrayClass<SwitchCase>)
		-> ArrayClass<Statement>
	{
		let newCases = cases.compactMap { (switchCase: SwitchCase) -> SwitchCase? in
			if switchCase.statements.count == 1,
				let onlyStatement = switchCase.statements.first,
				case .breakStatement = onlyStatement
			{
				return nil
			}
			else {
				return switchCase
			}
		}

		return super.replaceSwitchStatement(
			convertsToExpression: convertsToExpression,
			expression: expression,
			cases: newCases)
	}
}

/// Sealed classes should be tested for subclasses with the `is` operator. This is automatically
/// done for enum cases with associated values, but in other cases it has to be handled here.
public class IsOperatorsInSealedClassesTranspilationPass: TranspilationPass {
	override func replaceSwitchStatement(
		convertsToExpression: Statement?,
		expression: Expression,
		cases: ArrayClass<SwitchCase>)
		-> ArrayClass<Statement>
	{
		guard case let .declarationReferenceExpression(
				data: declarationReferenceExpression) = expression,
			KotlinTranslator.sealedClasses.contains(declarationReferenceExpression.type) else
		{
			return super.replaceSwitchStatement(
				convertsToExpression: convertsToExpression,
				expression: expression,
				cases: cases)
		}

		let newCases = cases.map { (switchCase: SwitchCase) -> SwitchCase in
			if let caseExpression = switchCase.expression,
				case let .dotExpression(
					leftExpression: leftExpression,
					rightExpression: rightExpression) = caseExpression,
				case let .typeExpression(type: typeName) = leftExpression,
				case let .declarationReferenceExpression(
					data: declarationReferenceExpression) = rightExpression
			{
				return SwitchCase(
					expression: Expression.binaryOperatorExpression(
						leftExpression: expression,
						rightExpression: .typeExpression(
							type: "\(typeName).\(declarationReferenceExpression.identifier)"),
						operatorSymbol: "is",
						type: "Bool"),
					statements: switchCase.statements)
			}
			else {
				return switchCase
			}
		}

		return super.replaceSwitchStatement(
			convertsToExpression: convertsToExpression,
			expression: expression,
			cases: newCases)
	}
}

public class RemoveExtensionsTranspilationPass: TranspilationPass {
	var extendingType: String?

	override func replaceExtension(
		type: String,
		members: ArrayClass<Statement>)
		-> ArrayClass<Statement>
	{
		extendingType = type
		let members = replaceStatements(members)
		extendingType = nil
		return members
	}

	override func replaceStatement(_ statement: Statement) -> ArrayClass<Statement> {
		switch statement {
		case let .extensionDeclaration(type: type, members: members):
			return replaceExtension(type: type, members: members)
		case let .functionDeclaration(data: functionDeclaration):
			return replaceFunctionDeclaration(functionDeclaration)
		case let .variableDeclaration(data: variableDeclaration):
			return replaceVariableDeclaration(variableDeclaration)
		default:
			return [statement]
		}
	}

	override func replaceFunctionDeclaration(_ functionDeclaration: FunctionDeclarationData)
		-> ArrayClass<Statement>
	{
		let functionDeclaration = functionDeclaration
		functionDeclaration.extendsType = self.extendingType
		return [Statement.functionDeclaration(data: functionDeclaration)]
	}

	override func replaceVariableDeclaration(_ variableDeclaration: VariableDeclarationData)
		-> VariableDeclarationData
	{
		let variableDeclaration = variableDeclaration
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
	override func replaceFunctionDeclaration(_ functionDeclaration: FunctionDeclarationData)
		-> FunctionDeclarationData?
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
		access: String?, name: String, inherits: ArrayClass<String>, elements: ArrayClass<EnumElement>,
		members: ArrayClass<Statement>, isImplicit: Bool) -> ArrayClass<Statement>
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
		_ expression: DeclarationReferenceData) -> DeclarationReferenceData
	{
		if expression.isStandardLibrary {
			let message = "Reference to standard library \"\(expression.identifier)\" was not " +
				"translated."
			Compiler.handleWarning(
					message: message,
					sourceFile: ast.sourceFile,
					sourceFileRange: expression.range)
		}
		return super.replaceDeclarationReferenceExpression(expression)
	}
}

/// If a value type's members are all immutable, that value type can safely be translated as a
/// class. Otherwise, the translation can cause inconsistencies, so this pass raises warnings.
/// Source: https://forums.swift.org/t/are-immutable-structs-like-classes/16270
public class RaiseMutableValueTypesWarningsTranspilationPass: TranspilationPass {
	override func replaceStructDeclaration(
		annotations: String?,
		name: String,
		inherits: ArrayClass<String>,
		members: ArrayClass<Statement>)
		-> ArrayClass<Statement>
	{
		for member in members {
			if case let .variableDeclaration(data: variableDeclaration) = member,
				!variableDeclaration.isImplicit,
				!variableDeclaration.isStatic,
				!variableDeclaration.isLet,
				variableDeclaration.getter == nil
			{
				let message = "No support for mutable variables in value types: found variable " +
					"\(variableDeclaration.identifier) inside struct \(name)"
				Compiler.handleWarning(
					message: message,
					sourceFile: ast.sourceFile,
					sourceFileRange: nil)
			}
			else if case let .functionDeclaration(data: functionDeclaration) = member,
				functionDeclaration.isMutating
			{
				let methodName = functionDeclaration.prefix + "(" +
					functionDeclaration.parameters.map { $0.label + ":" }
						.joined(separator: ", ") + ")"
				let message = "No support for mutating methods in value types: found method " +
					"\(methodName) inside struct \(name)"
				Compiler.handleWarning(
					message: message,
					sourceFile: ast.sourceFile,
					sourceFileRange: nil)
			}
		}

		return super.replaceStructDeclaration(
			annotations: annotations, name: name, inherits: inherits, members: members)
	}

	override func replaceEnumDeclaration(
		access: String?, name: String, inherits: ArrayClass<String>, elements: ArrayClass<EnumElement>,
		members: ArrayClass<Statement>, isImplicit: Bool) -> ArrayClass<Statement>
	{
		for member in members {
			if case let .functionDeclaration(data: functionDeclaration) = member,
				functionDeclaration.isMutating
			{
				let methodName = functionDeclaration.prefix + "(" +
					functionDeclaration.parameters.map { $0.label + ":" }
						.joined(separator: ", ") + ")"
				let message = "No support for mutating methods in value types: found method " +
					"\(methodName) inside enum \(name)"
				Compiler.handleWarning(
					message: message,
					sourceFile: ast.sourceFile,
					sourceFileRange: nil)
			}
		}

		return super.replaceEnumDeclaration(
			access: access, name: name, inherits: inherits, elements: elements, members: members,
			isImplicit: isImplicit)
	}
}

/// If statements with let declarations get translated to Kotlin by having their let declarations
/// rearranged to be before the if statement. This will cause any let conditions that have side
/// effects (i.e. `let x = sideEffects()`) to run eagerly on Kotlin but lazily on Swift, which can
/// lead to incorrect behavior.
public class RaiseWarningsForSideEffectsInIfLetsTranspilationPass: TranspilationPass {
	override func replaceIfStatement(_ ifStatement: IfStatementData) -> IfStatementData {
		raiseWarningsForIfStatement(ifStatement, isElse: false)

		// No recursion by calling super, otherwise we'd run on the else statements twice
		return ifStatement
	}

	private func raiseWarningsForIfStatement(_ ifStatement: IfStatementData, isElse: Bool) {
		// The first condition of an non-else if statement is the only one that can safely have side
		// effects
		let conditions = isElse ?
			ifStatement.conditions :
			ArrayClass(ifStatement.conditions.dropFirst())

		let sideEffectsRanges = conditions.flatMap(mayHaveSideEffectsOnRanges)
		for range in sideEffectsRanges {
			Compiler.handleWarning(
				message: "If condition may have side effects.",
				details: "",
				sourceFile: ast.sourceFile,
				sourceFileRange: range)
		}

		if let elseStatement = ifStatement.elseStatement {
			raiseWarningsForIfStatement(elseStatement, isElse: true)
		}
	}

	private func mayHaveSideEffectsOnRanges(
		_ condition: IfStatementData.Condition)
		-> ArrayClass<SourceFileRange>
	{
		if case let .declaration(variableDeclaration: variableDeclaration) = condition,
			let expression = variableDeclaration.expression
		{
			return mayHaveSideEffectsOnRanges(expression)
		}

		return []
	}

	private func mayHaveSideEffectsOnRanges(_ expression: Expression) -> ArrayClass<SourceFileRange> {
		switch expression {
		case let .callExpression(data: callExpression):
			if let range = callExpression.range {
				return [range]
			}
			else {
				return []
			}
		case let .parenthesesExpression(expression: expression):
			return mayHaveSideEffectsOnRanges(expression)
		case let .forceValueExpression(expression: expression):
			return mayHaveSideEffectsOnRanges(expression)
		case let .optionalExpression(expression: expression):
			return mayHaveSideEffectsOnRanges(expression)
		case let .subscriptExpression(
			subscriptedExpression: subscriptedExpression,
			indexExpression: indexExpression,
			type: _):

			return mayHaveSideEffectsOnRanges(subscriptedExpression) +
				mayHaveSideEffectsOnRanges(indexExpression)

		case let .arrayExpression(elements: elements, type: _):
			return elements.flatMap(mayHaveSideEffectsOnRanges)
		case let .dictionaryExpression(keys: keys, values: values, type: _):
			return keys.flatMap(mayHaveSideEffectsOnRanges) +
				values.flatMap(mayHaveSideEffectsOnRanges)
		case let .dotExpression(leftExpression: leftExpression, rightExpression: rightExpression):
			return mayHaveSideEffectsOnRanges(leftExpression) +
				mayHaveSideEffectsOnRanges(rightExpression)
		case let .binaryOperatorExpression(
			leftExpression: leftExpression,
			rightExpression: rightExpression,
			operatorSymbol: _,
			type: _):

			return mayHaveSideEffectsOnRanges(leftExpression) +
				mayHaveSideEffectsOnRanges(rightExpression)
		case let .prefixUnaryExpression(expression: expression, operatorSymbol: _, type: _):
			return mayHaveSideEffectsOnRanges(expression)
		case let .postfixUnaryExpression(expression: expression, operatorSymbol: _, type: _):
			return mayHaveSideEffectsOnRanges(expression)
		case let .ifExpression(
			condition: condition,
			trueExpression: trueExpression,
			falseExpression: falseExpression):

			return mayHaveSideEffectsOnRanges(condition) +
				mayHaveSideEffectsOnRanges(trueExpression) +
				mayHaveSideEffectsOnRanges(falseExpression)

		case let .interpolatedStringLiteralExpression(expressions: expressions):
			return expressions.flatMap(mayHaveSideEffectsOnRanges)
		case let .tupleExpression(pairs: pairs):
			return pairs.flatMap { mayHaveSideEffectsOnRanges($0.expression) }
		case let .tupleShuffleExpression(labels: _, indices: _, expressions: expressions):
			return expressions.flatMap(mayHaveSideEffectsOnRanges)
		default:
			return []
 		}
	}
}

/// Sends let declarations to before the if statement, and replaces them with `x != null` conditions
public class RearrangeIfLetsTranspilationPass: TranspilationPass {

	/// Send the let declarations to before the if statement
	override func replaceIfStatement(_ ifStatement: IfStatementData) -> ArrayClass<Statement> {
		let letDeclarations = gatherLetDeclarations(ifStatement)
			.map { Statement.variableDeclaration(data: $0) }

		return letDeclarations + super.replaceIfStatement(ifStatement)
	}

	/// Add conditions (`x != null`) for all let declarations
	override func replaceIfStatement(_ ifStatement: IfStatementData) -> IfStatementData {
		let newConditions = ifStatement.conditions.map { condition -> IfStatementData.Condition in
			if case let .declaration(variableDeclaration: variableDeclaration) = condition {
				return .condition(expression: .binaryOperatorExpression(
					leftExpression: .declarationReferenceExpression(data:
						DeclarationReferenceData(
							identifier: variableDeclaration.identifier,
							type: variableDeclaration.typeName,
							isStandardLibrary: false,
							isImplicit: false,
							range: variableDeclaration.expression?.range)),
					rightExpression: .nilLiteralExpression, operatorSymbol: "!=",
					type: "Boolean"))
			}
			else {
				return condition
			}
		}

		let ifStatement = ifStatement
		ifStatement.conditions = newConditions
		return super.replaceIfStatement(ifStatement)
	}

	/// Gather the let declarations from the if statement and its else( if)s into a single array
	private func gatherLetDeclarations(
		_ ifStatement: IfStatementData?)
		-> ArrayClass<VariableDeclarationData>
	{
		guard let ifStatement = ifStatement else {
			return []
		}

		let letDeclarations =
			ifStatement.conditions.compactMap { condition -> VariableDeclarationData? in
				if case let .declaration(variableDeclaration: variableDeclaration) = condition {
					return variableDeclaration
				}
				else {
					return nil
				}
			}.filter { variableDeclaration in
				// If it's a shadowing identifier there's no need to declare it in Kotlin
				// (i.e. `if let x = x { }`)
				if let declarationExpression = variableDeclaration.expression,
					case let .declarationReferenceExpression(
						data: expression) = declarationExpression,
					expression.identifier == variableDeclaration.identifier
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
}

/// Create a rawValue variable for enums that conform to rawRepresentable
public class RawValuesTranspilationPass: TranspilationPass {
	override func replaceEnumDeclaration(
		access: String?,
		name: String,
		inherits: ArrayClass<String>,
		elements: ArrayClass<EnumElement>,
		members: ArrayClass<Statement>,
		isImplicit: Bool) -> ArrayClass<Statement>
	{
		if let typeName = elements.compactMap({ $0.rawValue?.type }).first {
			let rawValueVariable = createRawValueVariable(
					rawValueType: typeName,
					access: access,
					name: name,
					elements: elements)

			guard let rawValueInitializer = createRawValueInitializer(
				rawValueType: typeName,
				access: access,
				name: name,
				elements: elements) else
			{
				Compiler.handleWarning(
					message: "Failed to create init(rawValue:)",
					details: "Unable to get all raw values in enum declaration.",
					sourceFile: ast.sourceFile,
					sourceFileRange: elements.compactMap { $0.rawValue?.range }.first)
				return super.replaceEnumDeclaration(
					access: access,
					name: name,
					inherits: inherits,
					elements: elements,
					members: members,
					isImplicit: isImplicit)
			}

			let newMembers = members
			newMembers.append(.functionDeclaration(data: rawValueInitializer))
			newMembers.append(.variableDeclaration(data: rawValueVariable))

			return super.replaceEnumDeclaration(
				access: access,
				name: name,
				inherits: inherits,
				elements: elements,
				members: newMembers,
				isImplicit: isImplicit)
		}
		else {
			return super.replaceEnumDeclaration(
				access: access,
				name: name,
				inherits: inherits,
				elements: elements,
				members: members,
				isImplicit: isImplicit)
		}
	}

	private func createRawValueInitializer(
		rawValueType: String,
		access: String?,
		name: String,
		elements: ArrayClass<EnumElement>)
		-> FunctionDeclarationData?
	{
		let maybeSwitchCases = elements.map { element -> SwitchCase? in
			guard let rawValue = element.rawValue else {
				return nil
			}

			return SwitchCase(
				expression: rawValue,
				statements: [
					.returnStatement(
						expression: .dotExpression(
							leftExpression: .typeExpression(type: name),
							rightExpression: .declarationReferenceExpression(data:
								DeclarationReferenceData(
									identifier: element.name,
									type: name,
									isStandardLibrary: false,
									isImplicit: false,
									range: nil)))),
				])
		}

		guard let switchCases = maybeSwitchCases.as(ArrayClass<SwitchCase>.self) else {
			return nil
		}

		let defaultSwitchCase = SwitchCase(
			expression: nil,
			statements: [.returnStatement(expression: .nilLiteralExpression)])

		switchCases.append(defaultSwitchCase)

		let switchStatement = Statement.switchStatement(
			convertsToExpression: nil,
			expression: .declarationReferenceExpression(data:
				DeclarationReferenceData(
					identifier: "rawValue",
					type: rawValueType,
					isStandardLibrary: false,
					isImplicit: false,
					range: nil)),
			cases: switchCases)

		return FunctionDeclarationData(
			prefix: "init",
			parameters: [FunctionParameter(
				label: "rawValue",
				apiLabel: nil,
				type: rawValueType,
				value: nil), ],
			returnType: name + "?",
			functionType: "(\(rawValueType)) -> \(name)?",
			genericTypes: [],
			isImplicit: false,
			isStatic: true,
			isMutating: false,
			extendsType: nil,
			statements: [switchStatement],
			access: access,
			annotations: nil)
	}

	private func createRawValueVariable(
		rawValueType: String,
		access: String?,
		name: String,
		elements: ArrayClass<EnumElement>)
		-> VariableDeclarationData
	{
		let switchCases = elements.map { element in
			SwitchCase(
				expression: .dotExpression(
					leftExpression: .typeExpression(type: name),
					rightExpression: .declarationReferenceExpression(data:
						DeclarationReferenceData(
							identifier: element.name,
							type: name,
							isStandardLibrary: false,
							isImplicit: false,
							range: nil))),
				statements: [
					.returnStatement(
						expression: element.rawValue),
				])
		}

		let switchStatement = Statement.switchStatement(
			convertsToExpression: nil,
			expression: .declarationReferenceExpression(data:
				DeclarationReferenceData(
					identifier: "this",
					type: name,
					isStandardLibrary: false,
					isImplicit: false,
					range: nil)),
			cases: switchCases)

		let getter = FunctionDeclarationData(
			prefix: "get",
			parameters: [],
			returnType: rawValueType,
			functionType: "() -> \(rawValueType)",
			genericTypes: [],
			isImplicit: false,
			isStatic: false,
			isMutating: false,
			extendsType: nil,
			statements: [switchStatement],
			access: access,
			annotations: nil)

		return VariableDeclarationData(
			identifier: "rawValue",
			typeName: rawValueType,
			expression: nil,
			getter: getter,
			setter: nil,
			isLet: false,
			isImplicit: false,
			isStatic: false,
			extendsType: nil,
			annotations: nil)
	}
}

/// Guards are translated as if statements with a ! at the start of the condition. Sometimes, the
/// ! combines with a != or even another !, causing a double negative in the condition that can
/// be removed (or turned into a single ==). This pass performs that transformation.
public class DoubleNegativesInGuardsTranspilationPass: TranspilationPass {
	override func replaceIfStatement(_ ifStatement: IfStatementData) -> IfStatementData {
		if ifStatement.isGuard,
			ifStatement.conditions.count == 1,
			let onlyCondition = ifStatement.conditions.first,
			case let .condition(expression: onlyConditionExpression) = onlyCondition
		{
			let shouldStillBeGuard: Bool
			let newCondition: Expression
			if case let .prefixUnaryExpression(
				expression: innerExpression, operatorSymbol: "!", type: _) = onlyConditionExpression
			{
				newCondition = innerExpression
				shouldStillBeGuard = false
			}
			else if case let .binaryOperatorExpression(
				leftExpression: leftExpression, rightExpression: rightExpression,
				operatorSymbol: "!=", type: type) = onlyConditionExpression
			{
				newCondition = .binaryOperatorExpression(
					leftExpression: leftExpression, rightExpression: rightExpression,
					operatorSymbol: "==", type: type)
				shouldStillBeGuard = false
			}
			else if case let .binaryOperatorExpression(
				leftExpression: leftExpression, rightExpression: rightExpression,
				operatorSymbol: "==", type: type) = onlyConditionExpression
			{
				newCondition = .binaryOperatorExpression(
					leftExpression: leftExpression, rightExpression: rightExpression,
					operatorSymbol: "!=", type: type)
				shouldStillBeGuard = false
			}
			else {
				newCondition = onlyConditionExpression
				shouldStillBeGuard = true
			}

			let ifStatement = ifStatement
			ifStatement.conditions = ArrayClass([newCondition]).map {
				IfStatementData.Condition.condition(expression: $0)
			}
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
	override func replaceStatement(_ statement: Statement) -> ArrayClass<Statement> {
		if case let .ifStatement(data: ifStatement) = statement,
			ifStatement.conditions.count == 1,
			let onlyCondition = ifStatement.conditions.first,
			case let .condition(expression: onlyConditionExpression) = onlyCondition,
			case let .binaryOperatorExpression(
				leftExpression: declarationReference,
				rightExpression: Expression.nilLiteralExpression,
				operatorSymbol: "==",
				type: _) = onlyConditionExpression,
			case let .declarationReferenceExpression(
				data: declarationExpression) = declarationReference,
			ifStatement.statements.count == 1,
			let onlyStatement = ifStatement.statements.first,
			case let .returnStatement(expression: returnExpression) = onlyStatement
		{
			return [.expression(expression:
				.binaryOperatorExpression(
					leftExpression: declarationReference,
					rightExpression: .returnExpression(expression: returnExpression),
					operatorSymbol: "?:",
					type: declarationExpression.type)), ]
		}
		else {
			return super.replaceStatement(statement)
		}
	}
}

public class FixProtocolContentsTranspilationPass: TranspilationPass {
	var isInProtocol = false

	override func replaceProtocolDeclaration(
		name: String, members: ArrayClass<Statement>) -> ArrayClass<Statement>
	{
		isInProtocol = true
		let result = super.replaceProtocolDeclaration(name: name, members: members)
		isInProtocol = false

		return result
	}

	override func replaceFunctionDeclaration(_ functionDeclaration: FunctionDeclarationData)
		-> FunctionDeclarationData?
	{
		if isInProtocol {
			let functionDeclaration = functionDeclaration
			functionDeclaration.statements = nil
			return super.replaceFunctionDeclaration(functionDeclaration)
		}
		else {
			return super.replaceFunctionDeclaration(functionDeclaration)
		}
	}

	override func replaceVariableDeclaration(_ variableDeclaration: VariableDeclarationData)
		-> VariableDeclarationData
	{
		if isInProtocol {
			let variableDeclaration = variableDeclaration
			variableDeclaration.getter?.isImplicit = true
			variableDeclaration.setter?.isImplicit = true
			variableDeclaration.getter?.statements = nil
			variableDeclaration.setter?.statements = nil
			return super.replaceVariableDeclaration(variableDeclaration)
		}
		else {
			return super.replaceVariableDeclaration(variableDeclaration)
		}
	}
}

public extension TranspilationPass {
	/// Runs transpilation passes that have to be run on all files before the other passes can
	/// run. For instance, we need to record all enums declared on all files before we can
	/// translate references to them correctly.
	static func runFirstRoundOfPasses(on sourceFile: GryphonAST) -> GryphonAST {
		var result = sourceFile

		// Remove declarations that shouldn't even be considered in the passes
		result = RemoveImplicitDeclarationsTranspilationPass(ast: result).run()

		// RecordEnums needs to be after CleanInheritance: it needs Swift-only inheritances removed
		// in order to know if the enum inherits from a class or not, and therefore is a sealed
		// class or an enum class.
		result = CleanInheritancesTranspilationPass(ast: result).run()

		// Record information on enum and function translations
		result = RecordTemplatesTranspilationPass(ast: result).run()
		result = RecordEnumsTranspilationPass(ast: result).run()
		result = RecordFunctionTranslationsTranspilationPass(ast: result).run()

		return result
	}

	/// Runs transpilation passes that can be run independently on any files, provided they happen
	/// after the `runFirstRoundOfPasses`.
	static func runSecondRoundOfPasses(on sourceFile: GryphonAST) -> GryphonAST {
		var result = sourceFile

		// Replace templates (must go before other passes since templates are recorded before
		// running any passes)
		result = ReplaceTemplatesTranspilationPass(ast: result).run()

		// Cleanup
		result = RemoveParenthesesTranspilationPass(ast: result).run()
		result = RemoveExtraReturnsInInitsTranspilationPass(ast: result).run()

		// Transform structures that need to be significantly different in Kotlin
		result = RawValuesTranspilationPass(ast: result).run()
		result = DescriptionAsToStringTranspilationPass(ast: result).run()
		result = OptionalInitsTranspilationPass(ast: result).run()
		result = StaticMembersTranspilationPass(ast: result).run()
		result = FixProtocolContentsTranspilationPass(ast: result).run()
		result = RemoveExtensionsTranspilationPass(ast: result).run()
		// Note: We have to know the order of the conditions to raise warnings here, so they must go
		// before the conditions are rearranged
		result = RaiseWarningsForSideEffectsInIfLetsTranspilationPass(ast: result).run()
		result = RearrangeIfLetsTranspilationPass(ast: result).run()

		// Transform structures that need to be slightly different in Kotlin
		result = SelfToThisTranspilationPass(ast: result).run()
		result = AnonymousParametersTranspilationPass(ast: result).run()
		result = CovarianceInitsAsCastsTranspilationPass(ast: result).run()
		result = RemoveBreaksInSwitchesTranspilationPass(ast: result).run()
		result = ReturnsInLambdasTranspilationPass(ast: result).run()
		result = RenameOperatorsTranspilationPass(ast: result).run()

		result = CapitalizeEnumsTranspilationPass(ast: result).run()
		result = IsOperatorsInSealedClassesTranspilationPass(ast: result).run()

		// Improve Kotlin readability
		result = OmitImplicitEnumPrefixesTranspilationPass(ast: result).run()
		result = InnerTypePrefixesTranspilationPass(ast: result).run()
		result = DoubleNegativesInGuardsTranspilationPass(ast: result).run()
		result = SwitchesToExpressionsTranspilationPass(ast: result).run()
		result = ReturnIfNilTranspilationPass(ast: result).run()

		// Raise any warnings that may be left
		result = RaiseStandardLibraryWarningsTranspilationPass(ast: result).run()
		result = RaiseMutableValueTypesWarningsTranspilationPass(ast: result).run()

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
public enum ASTNode: Equatable {
	case statement(Statement)
	case expression(Expression)
}
