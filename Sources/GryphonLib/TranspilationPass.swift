//
// Copyright 2018 Vinícius Jorge Vendramini
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

public class TranspilationPass {
	static let swiftRawRepresentableTypes: ArrayClass<String> = [
		"String",
		"Int", "Int8", "Int16", "Int32", "Int64",
		"UInt", "UInt8", "UInt16", "UInt32", "UInt64",
		"Float", "Float32", "Float64", "Float80", "Double",
		]

	static func isASwiftRawRepresentableType(_ typeName: String) -> Bool {
		return swiftRawRepresentableTypes.contains(typeName)
	}

	static let swiftProtocols: ArrayClass<String> = [
		"Equatable", "Codable", "Decodable", "Encodable", "CustomStringConvertible",
	]

	static func isASwiftProtocol(_ protocolName: String) -> Bool {
		return swiftProtocols.contains(protocolName)
	}

	//
	var ast: GryphonAST

	fileprivate var parents: ArrayClass<ASTNode> = []
	fileprivate var parent: ASTNode {
		return parents.secondToLast!
	}

	init(ast: GryphonAST) {
		self.ast = ast
	}

	func run() -> GryphonAST { // annotation: open
		let replacedStatements = replaceStatements(ast.statements)
		let replacedDeclarations = replaceStatements(ast.declarations)
		return GryphonAST(
			sourceFile: ast.sourceFile,
			declarations: replacedDeclarations,
			statements: replacedStatements)
	}

	func replaceStatements( // annotation: open
		_ statements: ArrayClass<Statement>)
		-> ArrayClass<Statement>
	{
		return statements.flatMap { replaceStatement($0) }
	}

	func replaceStatement( // annotation: open
		_ statement: Statement)
		-> ArrayClass<Statement>
	{
		parents.append(.statementNode(value: statement))
		defer { parents.removeLast() }

		if let commentStatement = statement as? CommentStatement {
			return replaceComment(range: commentStatement.range, value: commentStatement.value)
		}
		if let expressionStatement = statement as? ExpressionStatement {
			return replaceExpressionStatement(expression: expressionStatement.expression)
		}
		if let extensionDeclaration = statement as? ExtensionDeclaration {
			return replaceExtension(
				typeName: extensionDeclaration.typeName,
				members: extensionDeclaration.members)
		}
		if let importDeclaration = statement as? ImportDeclaration {
			return replaceImportDeclaration(moduleName: importDeclaration.moduleName)
		}
		if let typealiasDeclaration = statement as? TypealiasDeclaration {
			return replaceTypealiasDeclaration(
				identifier: typealiasDeclaration.identifier,
				typeName: typealiasDeclaration.typeName,
				isImplicit: typealiasDeclaration.isImplicit)
		}
		if let classDeclaration = statement as? ClassDeclaration {
			return replaceClassDeclaration(
				className: classDeclaration.className,
				inherits: classDeclaration.inherits,
				members: classDeclaration.members)
		}
		if let companionObject = statement as? CompanionObject {
			return replaceCompanionObject(members: companionObject.members)
		}
		if let enumDeclaration = statement as? EnumDeclaration {
			return replaceEnumDeclaration(
				access: enumDeclaration.access,
				enumName: enumDeclaration.enumName,
				inherits: enumDeclaration.inherits,
				elements: enumDeclaration.elements,
				members: enumDeclaration.members,
				isImplicit: enumDeclaration.isImplicit)
		}
		if let protocolDeclaration = statement as? ProtocolDeclaration {
			return replaceProtocolDeclaration(
				protocolName: protocolDeclaration.protocolName,
				members: protocolDeclaration.members)
		}
		if let structDeclaration = statement as? StructDeclaration {
			return replaceStructDeclaration(
				annotations: structDeclaration.annotations,
				structName: structDeclaration.structName,
				inherits: structDeclaration.inherits,
				members: structDeclaration.members)
		}
		if let functionDeclaration = statement as? FunctionDeclaration {
			return replaceFunctionDeclaration(functionDeclaration.data)
		}
		if let variableDeclaration = statement as? VariableDeclaration {
			return replaceVariableDeclaration(variableDeclaration.data)
		}
		if let doStatement = statement as? DoStatement {
			return replaceDoStatement(statements: doStatement.statements)
		}
		if let catchStatement = statement as? CatchStatement {
			return replaceCatchStatement(
				variableDeclaration: catchStatement.variableDeclaration,
				statements: catchStatement.statements)
		}
		if let forEachStatement = statement as? ForEachStatement {
			return replaceForEachStatement(
				collection: forEachStatement.collection,
				variable: forEachStatement.variable,
				statements: forEachStatement.statements)
		}
		if let whileStatement = statement as? WhileStatement {
			return replaceWhileStatement(
				expression: whileStatement.expression,
				statements: whileStatement.statements)
		}
		if let ifStatement = statement as? IfStatement {
			return replaceIfStatement(ifStatement.data)
		}
		if let switchStatement = statement as? SwitchStatement {
			return replaceSwitchStatement(
				convertsToExpression: switchStatement.convertsToExpression,
				expression: switchStatement.expression,
				cases: switchStatement.cases)
		}
		if let deferStatement = statement as? DeferStatement {
			return replaceDeferStatement(statements: deferStatement.statements)
		}
		if let throwStatement = statement as? ThrowStatement {
			return replaceThrowStatement(expression: throwStatement.expression)
		}
		if let returnStatement = statement as? ReturnStatement {
			return replaceReturnStatement(expression: returnStatement.expression)
		}
		if statement is BreakStatement {
			return [BreakStatement(range: nil)]
		}
		if statement is ContinueStatement {
			return [ContinueStatement(range: nil)]
		}
		if let assignmentStatement = statement as? AssignmentStatement {
			return replaceAssignmentStatement(
				leftHand: assignmentStatement.leftHand,
				rightHand: assignmentStatement.rightHand)
		}
		if statement is ErrorStatement {
			return [ErrorStatement(range: nil)]
		}

		fatalError("This should never be reached.")
	}

	func replaceComment(range: SourceFileRange?, value: String) // annotation: open
		-> ArrayClass<Statement>
	{
		return [CommentStatement(range: range, value: value)]
	}

	func replaceExpressionStatement( // annotation: open
		expression: Expression)
		-> ArrayClass<Statement>
	{
		return [ExpressionStatement(range: nil, expression: replaceExpression(expression))]
	}

	func replaceExtension( // annotation: open
		typeName: String,
		members: ArrayClass<Statement>)
		-> ArrayClass<Statement>
	{
		return [ExtensionDeclaration(
			range: nil,
			typeName: typeName,
			members: replaceStatements(members)), ]
	}

	func replaceImportDeclaration( // annotation: open
		moduleName: String)
		-> ArrayClass<Statement>
	{
		return [ImportDeclaration(range: nil, moduleName: moduleName)]
	}

	func replaceTypealiasDeclaration( // annotation: open
		identifier: String,
		typeName: String,
		isImplicit: Bool)
		-> ArrayClass<Statement>
	{
		return [TypealiasDeclaration(
			range: nil,
			identifier: identifier,
			typeName: typeName,
			isImplicit: isImplicit), ]
	}

	func replaceClassDeclaration( // annotation: open
		className: String,
		inherits: ArrayClass<String>,
		members: ArrayClass<Statement>)
		-> ArrayClass<Statement>
	{
		return [ClassDeclaration(
			range: nil,
			className: className,
			inherits: inherits,
			members: replaceStatements(members)), ]
	}

	func replaceCompanionObject( // annotation: open
		members: ArrayClass<Statement>)
		-> ArrayClass<Statement>
	{
		return [CompanionObject(range: nil, members: replaceStatements(members))]
	}

	func replaceEnumDeclaration( // annotation: open
		access: String?,
		enumName: String,
		inherits: ArrayClass<String>,
		elements: ArrayClass<EnumElement>,
		members: ArrayClass<Statement>,
		isImplicit: Bool)
		-> ArrayClass<Statement>
	{
		return [
			EnumDeclaration(
				range: nil,
				access: access,
				enumName: enumName,
				inherits: inherits,
				elements: elements.flatMap {
						replaceEnumElementDeclaration(
							enumName: $0.name,
							associatedValues: $0.associatedValues,
							rawValue: $0.rawValue,
							annotations: $0.annotations)
					},
				members: replaceStatements(members),
				isImplicit: isImplicit), ]
	}

	func replaceEnumElementDeclaration( // annotation: open
		enumName: String,
		associatedValues: ArrayClass<LabeledType>,
		rawValue: Expression?,
		annotations: String?)
		-> ArrayClass<EnumElement>
	{
		return [EnumElement(
			name: enumName,
			associatedValues: associatedValues,
			rawValue: rawValue,
			annotations: annotations), ]
	}

	func replaceProtocolDeclaration( // annotation: open
		protocolName: String,
		members: ArrayClass<Statement>)
		-> ArrayClass<Statement>
	{
		return [ProtocolDeclaration(
			range: nil,
			protocolName: protocolName,
			members: replaceStatements(members)), ]
	}

	func replaceStructDeclaration( // annotation: open
		annotations: String?,
		structName: String,
		inherits: ArrayClass<String>,
		members: ArrayClass<Statement>)
		-> ArrayClass<Statement>
	{
		return [StructDeclaration(
			range: nil,
			annotations: annotations,
			structName: structName,
			inherits: inherits,
			members: replaceStatements(members)), ]
	}

	func replaceFunctionDeclaration( // annotation: open
		_ functionDeclaration: FunctionDeclarationData)
		-> ArrayClass<Statement>
	{
		if let result = replaceFunctionDeclarationData(functionDeclaration) {
			return [FunctionDeclaration(range: nil, data: result)]
		}
		else {
			return []
		}
	}

	func replaceFunctionDeclarationData( // annotation: open
		_ functionDeclaration: FunctionDeclarationData)
		-> FunctionDeclarationData?
	{
		let replacedParameters = functionDeclaration.parameters
			.map {
				FunctionParameter(
					label: $0.label,
					apiLabel: $0.apiLabel,
					typeName: $0.typeName,
					value: $0.value.map { replaceExpression($0) })
			}

		let functionDeclaration = functionDeclaration
		functionDeclaration.parameters = replacedParameters
		functionDeclaration.statements =
			functionDeclaration.statements.map { replaceStatements($0) }
		return functionDeclaration
	}

	func replaceVariableDeclaration( // annotation: open
		_ variableDeclaration: VariableDeclarationData)
		-> ArrayClass<Statement>
	{
		return [VariableDeclaration(
			range: nil,
			data: replaceVariableDeclarationData(variableDeclaration)), ]
	}

	func replaceVariableDeclarationData( // annotation: open
		_ variableDeclaration: VariableDeclarationData)
		-> VariableDeclarationData
	{
		let variableDeclaration = variableDeclaration
		variableDeclaration.expression =
			variableDeclaration.expression.map { replaceExpression($0) }
		if let getter = variableDeclaration.getter {
			variableDeclaration.getter = replaceFunctionDeclarationData(getter)
		}
		if let setter = variableDeclaration.setter {
			variableDeclaration.setter = replaceFunctionDeclarationData(setter)
		}
		return variableDeclaration
	}

	func replaceDoStatement( // annotation: open
		statements: ArrayClass<Statement>)
		-> ArrayClass<Statement>
	{
		return [DoStatement(range: nil, statements: replaceStatements(statements))]
	}

	func replaceCatchStatement( // annotation: open
		variableDeclaration: VariableDeclarationData?,
		statements: ArrayClass<Statement>)
		-> ArrayClass<Statement>
	{
		return [CatchStatement(
			range: nil,
			variableDeclaration: variableDeclaration.map { replaceVariableDeclarationData($0) },
			statements: replaceStatements(statements)),
		]
	}

	func replaceForEachStatement( // annotation: open
		collection: Expression, variable: Expression, statements: ArrayClass<Statement>)
		-> ArrayClass<Statement>
	{
		return [ForEachStatement(
			range: nil,
			collection: replaceExpression(collection),
			variable: replaceExpression(variable),
			statements: replaceStatements(statements)), ]
	}

	func replaceWhileStatement( // annotation: open
		expression: Expression,
		statements: ArrayClass<Statement>)
		-> ArrayClass<Statement>
	{
		return [WhileStatement(
			range: nil,
			expression: replaceExpression(expression),
			statements: replaceStatements(statements)), ]
	}

	func replaceIfStatement( // annotation: open
		_ ifStatement: IfStatementData)
		-> ArrayClass<Statement>
	{
		return [IfStatement(range: nil, data: replaceIfStatementData(ifStatement))]
	}

	func replaceIfStatementData( // annotation: open
		_ ifStatement: IfStatementData)
		-> IfStatementData
	{
		let ifStatement = ifStatement
		ifStatement.conditions = replaceIfConditions(ifStatement.conditions)
		ifStatement.declarations =
			ifStatement.declarations.map { replaceVariableDeclarationData($0) }
		ifStatement.statements = replaceStatements(ifStatement.statements)
		ifStatement.elseStatement = ifStatement.elseStatement.map { replaceIfStatementData($0) }
		return ifStatement
	}

	func replaceIfConditions( // annotation: open
		_ conditions: ArrayClass<IfStatementData.IfCondition>)
		-> ArrayClass<IfStatementData.IfCondition>
	{
		return conditions.map { replaceIfCondition($0) }
	}

	func replaceIfCondition( // annotation: open
		_ condition: IfStatementData.IfCondition)
		-> IfStatementData.IfCondition
	{
		switch condition {
		case let .condition(expression: expression):
			return .condition(expression: replaceExpression(expression))
		case let .declaration(variableDeclaration: variableDeclaration):
			return .declaration(
				variableDeclaration: replaceVariableDeclarationData(variableDeclaration))
		}
	}

	func replaceSwitchStatement( // annotation: open
		convertsToExpression: Statement?, expression: Expression,
		cases: ArrayClass<SwitchCase>) -> ArrayClass<Statement>
	{
		let replacedConvertsToExpression: Statement?
		if let convertsToExpression = convertsToExpression {
			if let replacedExpression = replaceStatement(convertsToExpression).first {
				replacedConvertsToExpression = replacedExpression
			}
			else {
				replacedConvertsToExpression = nil
			}
		}
		else {
			replacedConvertsToExpression = nil
		}

		let replacedCases = cases.map
			{
				SwitchCase(
					expressions: $0.expressions.map { replaceExpression($0) },
					statements: replaceStatements($0.statements))
			}

		return [SwitchStatement(
			range: nil,
			convertsToExpression: replacedConvertsToExpression,
			expression: replaceExpression(expression),
			cases: replacedCases), ]
	}

	func replaceDeferStatement( // annotation: open
		statements: ArrayClass<Statement>)
		-> ArrayClass<Statement>
	{
		return [DeferStatement(range: nil, statements: replaceStatements(statements))]
	}

	func replaceThrowStatement( // annotation: open
		expression: Expression)
		-> ArrayClass<Statement>
	{
		return [ThrowStatement(range: nil, expression: replaceExpression(expression))]
	}

	func replaceReturnStatement( // annotation: open
		expression: Expression?)
		-> ArrayClass<Statement>
	{
		return [ReturnStatement(range: nil, expression: expression.map { replaceExpression($0) })]
	}

	func replaceAssignmentStatement( // annotation: open
		leftHand: Expression,
		rightHand: Expression)
		-> ArrayClass<Statement>
	{
		return [AssignmentStatement(
			range: nil,
			leftHand: replaceExpression(leftHand),
			rightHand: replaceExpression(rightHand)), ]
	}

	func replaceExpression( // annotation: open
		_ expression: Expression)
		-> Expression
	{
		parents.append(.expressionNode(value: expression))
		defer { parents.removeLast() }

		if let subExpression = expression as? TemplateExpression {
			return replaceTemplateExpression(
				pattern: subExpression.pattern,
				matches: subExpression.matches)
		}
		if let subExpression = expression as? LiteralCodeExpression {
			return replaceLiteralCodeExpression(string: subExpression.string)
		}
		if let subExpression = expression as? LiteralDeclarationExpression {
			return replaceLiteralCodeExpression(string: subExpression.string)
		}
		if let subExpression = expression as? ParenthesesExpression {
			return replaceParenthesesExpression(expression: subExpression.expression)
		}
		if let subExpression = expression as? ForceValueExpression {
			return replaceForceValueExpression(expression: subExpression.expression)
		}
		if let subExpression = expression as? OptionalExpression {
			return replaceOptionalExpression(expression: subExpression.expression)
		}
		if let subExpression = expression as? DeclarationReferenceExpression {
			return replaceDeclarationReferenceExpression(subExpression.data)
		}
		if let subExpression = expression as? TypeExpression {
			return replaceTypeExpression(typeName: subExpression.typeName)
		}
		if let subExpression = expression as? SubscriptExpression {
			return replaceSubscriptExpression(
				subscriptedExpression: subExpression.subscriptedExpression,
				indexExpression: subExpression.indexExpression,
				typeName: subExpression.typeName)
		}
		if let subExpression = expression as? ArrayExpression {
			return replaceArrayExpression(
				elements: subExpression.elements,
				typeName: subExpression.typeName)
		}
		if let subExpression = expression as? DictionaryExpression {
			return replaceDictionaryExpression(
				keys: subExpression.keys,
				values: subExpression.values,
				typeName: subExpression.typeName)
		}
		if let subExpression = expression as? ReturnExpression {
			return replaceReturnExpression(innerExpression: subExpression.expression)
		}
		if let subExpression = expression as? DotExpression {
			return replaceDotExpression(
				leftExpression: subExpression.leftExpression,
				rightExpression: subExpression.rightExpression)
		}
		if let subExpression = expression as? BinaryOperatorExpression {
			return replaceBinaryOperatorExpression(
				leftExpression: subExpression.leftExpression,
				rightExpression: subExpression.rightExpression,
				operatorSymbol: subExpression.operatorSymbol,
				typeName: subExpression.typeName)
		}
		if let subExpression = expression as? PrefixUnaryExpression {
			return replacePrefixUnaryExpression(
				subExpression: subExpression.subExpression,
				operatorSymbol: subExpression.operatorSymbol,
				typeName: subExpression.typeName)
		}
		if let subExpression = expression as? PostfixUnaryExpression {
			return replacePostfixUnaryExpression(
				subExpression: subExpression.subExpression,
				operatorSymbol: subExpression.operatorSymbol,
				typeName: subExpression.typeName)
		}
		if let subExpression = expression as? IfExpression {
			return replaceIfExpression(
				condition: subExpression.condition,
				trueExpression: subExpression.trueExpression,
				falseExpression: subExpression.falseExpression)
		}
		if let subExpression = expression as? CallExpression {
			return replaceCallExpression(subExpression.data)
		}
		if let subExpression = expression as? ClosureExpression {
			return replaceClosureExpression(
				parameters: subExpression.parameters,
				statements: subExpression.statements,
				typeName: subExpression.typeName)
		}
		if let subExpression = expression as? LiteralIntExpression {
			return replaceLiteralIntExpression(value: subExpression.value)
		}
		if let subExpression = expression as? LiteralUIntExpression {
			return replaceLiteralUIntExpression(value: subExpression.value)
		}
		if let subExpression = expression as? LiteralDoubleExpression {
			return replaceLiteralDoubleExpression(value: subExpression.value)
		}
		if let subExpression = expression as? LiteralFloatExpression {
			return replaceLiteralFloatExpression(value: subExpression.value)
		}
		if let subExpression = expression as? LiteralBoolExpression {
			return replaceLiteralBoolExpression(value: subExpression.value)
		}
		if let subExpression = expression as? LiteralStringExpression {
			return replaceLiteralStringExpression(value: subExpression.value)
		}
		if let subExpression = expression as? LiteralCharacterExpression {
			return replaceLiteralCharacterExpression(value: subExpression.value)
		}
		if expression is NilLiteralExpression {
			return replaceNilLiteralExpression()
		}
		if let subExpression = expression as? InterpolatedStringLiteralExpression {
			return replaceInterpolatedStringLiteralExpression(
				expressions: subExpression.expressions)
		}
		if let subExpression = expression as? TupleExpression {
			return replaceTupleExpression(pairs: subExpression.pairs)
		}
		if let subExpression = expression as? TupleShuffleExpression {
			return replaceTupleShuffleExpression(
				labels: subExpression.labels,
				indices: subExpression.indices,
				expressions: subExpression.expressions)
		}
		if expression is ErrorExpression {
			return ErrorExpression(range: nil)
		}

		fatalError("This should never be reached.")
	}

	func replaceTemplateExpression( // annotation: open
		pattern: String,
		matches: DictionaryClass<String, Expression>)
		-> Expression
	{
		let newMatches = matches.mapValues { replaceExpression($0) } // kotlin: ignore
		// insert: val newMatches = matches.mapValues { replaceExpression(it.value) }.toMutableMap()

		return TemplateExpression(
			range: nil,
			pattern: pattern,
			matches: newMatches)
	}

	func replaceLiteralCodeExpression( // annotation: open
		string: String)
		-> Expression
	{
		return LiteralCodeExpression(range: nil, string: string)
	}

	func replaceParenthesesExpression( // annotation: open
		expression: Expression)
		-> Expression
	{
		return ParenthesesExpression(range: nil, expression: replaceExpression(expression))
	}

	func replaceForceValueExpression( // annotation: open
		expression: Expression)
		-> Expression
	{
		return ForceValueExpression(range: nil, expression: replaceExpression(expression))
	}

	func replaceOptionalExpression( // annotation: open
		expression: Expression)
		-> Expression
	{
		return OptionalExpression(range: nil, expression: replaceExpression(expression))
	}

	func replaceDeclarationReferenceExpression( // annotation: open
		_ declarationReferenceExpressionFixme: DeclarationReferenceData)
		-> Expression
	{
		return DeclarationReferenceExpression(
			range: nil,
			data: replaceDeclarationReferenceExpressionData(declarationReferenceExpressionFixme))
	}

	func replaceDeclarationReferenceExpressionData( // annotation: open
		_ declarationReferenceExpression: DeclarationReferenceData)
		-> DeclarationReferenceData
	{
		return declarationReferenceExpression
	}

	func replaceTypeExpression( // annotation: open
		typeName: String)
		-> Expression
	{
		return TypeExpression(range: nil, typeName: typeName)
	}

	func replaceSubscriptExpression( // annotation: open
		subscriptedExpression: Expression,
		indexExpression: Expression,
		typeName: String)
		-> Expression
	{
		return SubscriptExpression(
			range: nil,
			subscriptedExpression: replaceExpression(subscriptedExpression),
			indexExpression: replaceExpression(indexExpression), typeName: typeName)
	}

	func replaceArrayExpression( // annotation: open
		elements: ArrayClass<Expression>,
		typeName: String)
		-> Expression
	{
		return ArrayExpression(
			range: nil,
			elements: elements.map { replaceExpression($0) },
			typeName: typeName)
	}

	func replaceDictionaryExpression( // annotation: open
		keys: ArrayClass<Expression>,
		values: ArrayClass<Expression>,
		typeName: String)
		-> Expression
	{
		return DictionaryExpression(range: nil, keys: keys, values: values, typeName: typeName)
	}

	func replaceReturnExpression( // annotation: open
		innerExpression: Expression?)
		-> Expression
	{
		return ReturnExpression(
			range: nil,
			expression: innerExpression.map { replaceExpression($0) })
	}

	func replaceDotExpression( // annotation: open
		leftExpression: Expression,
		rightExpression: Expression)
		-> Expression
	{
		return DotExpression(
			range: nil,
			leftExpression: replaceExpression(leftExpression),
			rightExpression: replaceExpression(rightExpression))
	}

	func replaceBinaryOperatorExpression( // annotation: open
		leftExpression: Expression,
		rightExpression: Expression,
		operatorSymbol: String,
		typeName: String) -> Expression
	{
		return BinaryOperatorExpression(
			range: nil,
			leftExpression: replaceExpression(leftExpression),
			rightExpression: replaceExpression(rightExpression),
			operatorSymbol: operatorSymbol,
			typeName: typeName)
	}

	func replacePrefixUnaryExpression( // annotation: open
		subExpression: Expression,
		operatorSymbol: String,
		typeName: String)
		-> Expression
	{
		return PrefixUnaryExpression(
			range: nil,
			subExpression: replaceExpression(subExpression),
			operatorSymbol: operatorSymbol,
			typeName: typeName)
	}

	func replacePostfixUnaryExpression( // annotation: open
		subExpression: Expression,
		operatorSymbol: String,
		typeName: String)
		-> Expression
	{
		return PostfixUnaryExpression(
			range: nil,
			subExpression: replaceExpression(subExpression),
			operatorSymbol: operatorSymbol,
			typeName: typeName)
	}

	func replaceIfExpression( // annotation: open
		condition: Expression,
		trueExpression: Expression,
		falseExpression: Expression)
		-> Expression
	{
		return IfExpression(
			range: nil,
			condition: replaceExpression(condition),
			trueExpression: replaceExpression(trueExpression),
			falseExpression: replaceExpression(falseExpression))
	}

	func replaceCallExpression( // annotation: open
		_ callExpressionFixme: CallExpressionData)
		-> Expression
	{
		return CallExpression(range: nil, data: replaceCallExpressionData(callExpressionFixme))
	}

	func replaceCallExpressionData( // annotation: open
		_ callExpression: CallExpressionData)
		-> CallExpressionData
	{
		return CallExpressionData(
			function: replaceExpression(callExpression.function),
			parameters: replaceExpression(callExpression.parameters),
			typeName: callExpression.typeName,
			range: callExpression.range)
	}

	func replaceClosureExpression( // annotation: open
		parameters: ArrayClass<LabeledType>,
		statements: ArrayClass<Statement>,
		typeName: String)
		-> Expression
	{
		return ClosureExpression(
			range: nil,
			parameters: parameters,
			statements: replaceStatements(statements),
			typeName: typeName)
	}

	func replaceLiteralIntExpression(value: Int64) -> Expression { // annotation: open
		return LiteralIntExpression(range: nil, value: value)
	}

	func replaceLiteralUIntExpression(value: UInt64) -> Expression { // annotation: open
		return LiteralUIntExpression(range: nil, value: value)
	}

	func replaceLiteralDoubleExpression(value: Double) -> Expression { // annotation: open
		return LiteralDoubleExpression(range: nil, value: value)
	}

	func replaceLiteralFloatExpression(value: Float) -> Expression { // annotation: open
		return LiteralFloatExpression(range: nil, value: value)
	}

	func replaceLiteralBoolExpression(value: Bool) -> Expression { // annotation: open
		return LiteralBoolExpression(range: nil, value: value)
	}

	func replaceLiteralStringExpression(value: String) -> Expression { // annotation: open
		return LiteralStringExpression(range: nil, value: value)
	}

	func replaceLiteralCharacterExpression(value: String) -> Expression { // annotation: open
		return LiteralCharacterExpression(range: nil, value: value)
	}

	func replaceNilLiteralExpression() -> Expression { // annotation: open
		return NilLiteralExpression(range: nil)
	}

	func replaceInterpolatedStringLiteralExpression( // annotation: open
		expressions: ArrayClass<Expression>)
		-> Expression
	{
		return InterpolatedStringLiteralExpression(
			range: nil,
			expressions: expressions.map { replaceExpression($0) })
	}

	func replaceTupleExpression( // annotation: open
		pairs: ArrayClass<LabeledExpression>)
		-> Expression
	{
		return TupleExpression(
			range: nil,
			pairs: pairs.map {
				LabeledExpression(label: $0.label, expression: replaceExpression($0.expression))
			})
	}

	func replaceTupleShuffleExpression( // annotation: open
		labels: ArrayClass<String>,
		indices: ArrayClass<TupleShuffleIndex>,
		expressions: ArrayClass<Expression>)
		-> Expression
	{
		return TupleShuffleExpression(
			range: nil,
			labels: labels,
			indices: indices,
			expressions: expressions.map { replaceExpression($0) })
	}
}

public class DescriptionAsToStringTranspilationPass: TranspilationPass {
	// declaration: constructor(ast: GryphonAST): super(ast) { }

	override func replaceVariableDeclaration( // annotation: override
		_ variableDeclaration: VariableDeclarationData)
		-> ArrayClass<Statement>
	{
		if variableDeclaration.identifier == "description",
			variableDeclaration.typeName == "String",
			let getter = variableDeclaration.getter
		{
			return [FunctionDeclaration(range: nil, data: FunctionDeclarationData(
				prefix: "toString",
				parameters: [],
				returnType: "String",
				functionType: "() -> String",
				genericTypes: [],
				isImplicit: false,
				isStatic: false,
				isMutating: false,
				isPure: false,
				extendsType: variableDeclaration.extendsType,
				statements: getter.statements,
				access: nil,
				annotations: variableDeclaration.annotations)), ]
		}

		return super.replaceVariableDeclaration(variableDeclaration)
	}
}

public class RemoveParenthesesTranspilationPass: TranspilationPass {
	// declaration: constructor(ast: GryphonAST): super(ast) { }

	override func replaceSubscriptExpression( // annotation: override
		subscriptedExpression: Expression,
		indexExpression: Expression,
		typeName: String)
		-> Expression
	{
		if let parentheses = indexExpression as? ParenthesesExpression {
			return super.replaceSubscriptExpression(
				subscriptedExpression: subscriptedExpression,
				indexExpression: parentheses.expression,
				typeName: typeName)
		}

		return super.replaceSubscriptExpression(
			subscriptedExpression: subscriptedExpression,
			indexExpression: indexExpression,
			typeName: typeName)
	}

	override func replaceParenthesesExpression( // annotation: override
		expression: Expression)
		-> Expression
	{
		let myParent = self.parent
		if case let .expressionNode(parentExpression) = myParent {
			if parentExpression is TupleExpression ||
				parentExpression is InterpolatedStringLiteralExpression
			{
				return replaceExpression(expression)
			}
		}

		return ParenthesesExpression(range: nil, expression: replaceExpression(expression))
	}

	override func replaceIfExpression( // annotation: override
		condition: Expression,
		trueExpression: Expression,
		falseExpression: Expression)
		-> Expression
	{
		let replacedCondition: Expression
		if let parentheses = condition as? ParenthesesExpression {
			replacedCondition = parentheses.expression
		}
		else {
			replacedCondition = condition
		}

		let replacedTrueExpression: Expression
		if let parentheses = trueExpression as? ParenthesesExpression {
			replacedTrueExpression = parentheses.expression
		}
		else {
			replacedTrueExpression = trueExpression
		}

		let replacedFalseExpression: Expression
		if let parentheses = falseExpression as? ParenthesesExpression {
			replacedFalseExpression = parentheses.expression
		}
		else {
			replacedFalseExpression = falseExpression
		}

		return IfExpression(
			range: nil,
			condition: replacedCondition,
			trueExpression: replacedTrueExpression,
			falseExpression: replacedFalseExpression)
	}
}

/// Removes implicit declarations so that they don't show up on the translation
public class RemoveImplicitDeclarationsTranspilationPass: TranspilationPass {
	// declaration: constructor(ast: GryphonAST): super(ast) { }

	override func replaceEnumDeclaration( // annotation: override
		access: String?,
		enumName: String,
		inherits: ArrayClass<String>,
		elements: ArrayClass<EnumElement>,
		members: ArrayClass<Statement>,
		isImplicit: Bool)
		-> ArrayClass<Statement>
	{
		if isImplicit {
			return []
		}
		else {
			return super.replaceEnumDeclaration(
				access: access,
				enumName: enumName,
				inherits: inherits,
				elements: elements,
				members: members,
				isImplicit: isImplicit)
		}
	}

	override func replaceTypealiasDeclaration( // annotation: override
		identifier: String,
		typeName: String,
		isImplicit: Bool)
		-> ArrayClass<Statement>
	{
		if isImplicit {
			return []
		}
		else {
			return super.replaceTypealiasDeclaration(
				identifier: identifier, typeName: typeName, isImplicit: isImplicit)
		}
	}

	override func replaceVariableDeclaration( // annotation: override
		_ variableDeclaration: VariableDeclarationData)
		-> ArrayClass<Statement>
	{
		if variableDeclaration.isImplicit {
			return []
		}
		else {
			return super.replaceVariableDeclaration(variableDeclaration)
		}
	}

	override func replaceFunctionDeclarationData( // annotation: override
		_ functionDeclaration: FunctionDeclarationData)
		-> FunctionDeclarationData?
	{
		if functionDeclaration.isImplicit {
			return nil
		}
		else {
			return super.replaceFunctionDeclarationData(functionDeclaration)
		}
	}
}

/// Optional initializers can be translated as `invoke` operators to have similar syntax and
/// functionality.
public class OptionalInitsTranspilationPass: TranspilationPass {
	// declaration: constructor(ast: GryphonAST): super(ast) { }

	private var isFailableInitializer: Bool = false

	override func replaceFunctionDeclarationData( // annotation: override
		_ functionDeclaration: FunctionDeclarationData)
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

		return super.replaceFunctionDeclarationData(functionDeclaration)
	}

	override func replaceAssignmentStatement( // annotation: override
		leftHand: Expression,
		rightHand: Expression)
		-> ArrayClass<Statement>
	{
		if isFailableInitializer,
			let expression = leftHand as? DeclarationReferenceExpression
		{
			if expression.data.identifier == "self" {
				return [ReturnStatement(range: nil, expression: rightHand)]
			}
		}

		return super.replaceAssignmentStatement(leftHand: leftHand, rightHand: rightHand)
	}
}

public class RemoveExtraReturnsInInitsTranspilationPass: TranspilationPass {
	// declaration: constructor(ast: GryphonAST): super(ast) { }

	override func replaceFunctionDeclarationData( // annotation: override
		_ functionDeclaration: FunctionDeclarationData)
		-> FunctionDeclarationData?
	{
		if functionDeclaration.isStatic == true,
			functionDeclaration.extendsType == nil,
			functionDeclaration.prefix == "init",
			let lastStatement = functionDeclaration.statements?.last,
			lastStatement is ReturnStatement
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
	// declaration: constructor(ast: GryphonAST): super(ast) { }

	private func sendStaticMembersToCompanionObject(
		_ members: ArrayClass<Statement>)
		-> ArrayClass<Statement>
	{
		let staticMembers = members.filter { isStaticMember($0) }

		guard !staticMembers.isEmpty else {
			return members
		}

		let nonStaticMembers = members.filter { !isStaticMember($0) }

		let newMembers: ArrayClass<Statement> =
			[CompanionObject(range: nil, members: staticMembers)]
		newMembers.append(contentsOf: nonStaticMembers)

		return newMembers
	}

	private func isStaticMember(_ member: Statement) -> Bool {
		if let functionDeclaration = member as? FunctionDeclaration {
			if functionDeclaration.data.isStatic == true,
				functionDeclaration.data.extendsType == nil,
				functionDeclaration.data.prefix != "init"
			{
				return true
			}
		}

		if let variableDeclaration = member as? VariableDeclaration {
			if variableDeclaration.data.isStatic {
				return true
			}
		}

		return false
	}

	override func replaceClassDeclaration( // annotation: override
		className: String,
		inherits: ArrayClass<String>,
		members: ArrayClass<Statement>)
		-> ArrayClass<Statement>
	{
		let newMembers = sendStaticMembersToCompanionObject(members)
		return super.replaceClassDeclaration(
			className: className,
			inherits: inherits,
			members: newMembers)
	}

	override func replaceStructDeclaration( // annotation: override
		annotations: String?,
		structName: String,
		inherits: ArrayClass<String>,
		members: ArrayClass<Statement>)
		-> ArrayClass<Statement>
	{
		let newMembers = sendStaticMembersToCompanionObject(members)
		return super.replaceStructDeclaration(
			annotations: annotations,
			structName: structName,
			inherits: inherits,
			members: newMembers)
	}

	override func replaceEnumDeclaration( // annotation: override
		access: String?,
		enumName: String,
		inherits: ArrayClass<String>,
		elements: ArrayClass<EnumElement>,
		members: ArrayClass<Statement>,
		isImplicit: Bool)
		-> ArrayClass<Statement>
	{
		let newMembers = sendStaticMembersToCompanionObject(members)
		return super.replaceEnumDeclaration(
			access: access,
			enumName: enumName,
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
	// declaration: constructor(ast: GryphonAST): super(ast) { }

	var typeNamesStack: ArrayClass<String> = []

	func removePrefixes(_ typeName: String) -> String {
		var result = typeName
		for typeName in typeNamesStack {
			let prefix = typeName + "."
			if result.hasPrefix(prefix) {
				result = String(result.dropFirst(prefix.count))
			}
			else {
				return result
			}
		}

		return result
	}

	override func replaceClassDeclaration( // annotation: override
		className: String,
		inherits: ArrayClass<String>,
		members: ArrayClass<Statement>)
		-> ArrayClass<Statement>
	{
		typeNamesStack.append(className)
		let result = super.replaceClassDeclaration(
			className: className,
			inherits: inherits,
			members: members)
		typeNamesStack.removeLast()
		return result
	}

	override func replaceStructDeclaration( // annotation: override
		annotations: String?,
		structName: String,
		inherits: ArrayClass<String>,
		members: ArrayClass<Statement>)
		-> ArrayClass<Statement>
	{
		typeNamesStack.append(structName)
		let result = super.replaceStructDeclaration(
			annotations: annotations,
			structName: structName,
			inherits: inherits,
			members: members)
		typeNamesStack.removeLast()
		return result
	}

	override func replaceVariableDeclarationData( // annotation: override
		_ variableDeclaration: VariableDeclarationData)
		-> VariableDeclarationData
	{
		let variableDeclaration = variableDeclaration
		variableDeclaration.typeName = removePrefixes(variableDeclaration.typeName)
		return super.replaceVariableDeclarationData(variableDeclaration)
	}

	override func replaceTypeExpression( // annotation: override
		typeName: String)
		-> Expression
	{
		return TypeExpression(range: nil, typeName: removePrefixes(typeName))
	}
}

// TODO: test
/// Capitalizes references to enums (since enum cases in Kotlin are conventionally written in
/// capitalized forms)
public class CapitalizeEnumsTranspilationPass: TranspilationPass {
	// declaration: constructor(ast: GryphonAST): super(ast) { }

	override func replaceDotExpression( // annotation: override
		leftExpression: Expression,
		rightExpression: Expression)
		-> Expression
	{
		if let enumTypeExpression = leftExpression as? TypeExpression,
			let enumExpression = rightExpression as? DeclarationReferenceExpression
		{
			let lastEnumType = String(enumTypeExpression.typeName.split(separator: ".").last!)

			if KotlinTranslator.sealedClasses.contains(lastEnumType) {
				let enumExpression = enumExpression
				enumExpression.data.identifier =
					enumExpression.data.identifier.capitalizedAsCamelCase()
				return DotExpression(
					range: nil,
					leftExpression: TypeExpression(
						range: nil,
						typeName: enumTypeExpression.typeName),
					rightExpression: enumExpression)
			}
			else if KotlinTranslator.enumClasses.contains(lastEnumType) {
				let enumExpression = enumExpression
				enumExpression.data.identifier = enumExpression.data.identifier.upperSnakeCase()
				return DotExpression(
					range: nil,
					leftExpression: TypeExpression(
						range: nil,
						typeName: enumTypeExpression.typeName),
					rightExpression: enumExpression)
			}
		}

		return super.replaceDotExpression(
			leftExpression: leftExpression, rightExpression: rightExpression)
	}

	override func replaceEnumDeclaration( // annotation: override
		access: String?,
		enumName: String,
		inherits: ArrayClass<String>,
		elements: ArrayClass<EnumElement>,
		members: ArrayClass<Statement>,
		isImplicit: Bool)
		-> ArrayClass<Statement>
	{
		let isSealedClass = KotlinTranslator.sealedClasses.contains(enumName)
		let isEnumClass = KotlinTranslator.enumClasses.contains(enumName)

		let newElements: ArrayClass<EnumElement>
		if isSealedClass {
			newElements = elements.map { element in
				EnumElement(
					name: element.name.capitalizedAsCamelCase(),
					associatedValues: element.associatedValues,
					rawValue: element.rawValue,
					annotations: element.annotations)
			}
		}
		else if isEnumClass {
			newElements = elements.map { element in
				EnumElement(
					name: element.name.upperSnakeCase(),
					associatedValues: element.associatedValues,
					rawValue: element.rawValue,
					annotations: element.annotations)
			}
		}
		else {
			newElements = elements
		}

		return super.replaceEnumDeclaration(
			access: access,
			enumName: enumName,
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
	// declaration: constructor(ast: GryphonAST): super(ast) { }

	private var returnTypesStack: ArrayClass<String> = []

	private func removePrefixFromPossibleEnumReference(
		leftExpression: Expression,
		rightExpression: Expression)
		-> Expression
	{
		if let enumTypeExpression = leftExpression as? TypeExpression,
			let enumExpression = rightExpression as? DeclarationReferenceExpression
		{
			if enumExpression.data.typeName ==
					"(\(enumTypeExpression.typeName).Type) -> \(enumTypeExpression.typeName)",
				!KotlinTranslator.sealedClasses.contains(enumTypeExpression.typeName)
			{
				return enumExpression
			}
		}

		return super.replaceDotExpression(
			leftExpression: leftExpression,
			rightExpression: rightExpression)
	}

	override func replaceFunctionDeclarationData( // annotation: override
		_ functionDeclaration: FunctionDeclarationData)
		-> FunctionDeclarationData?
	{
		returnTypesStack.append(functionDeclaration.returnType)
		defer { returnTypesStack.removeLast() }
		return super.replaceFunctionDeclarationData(functionDeclaration)
	}

	override func replaceReturnStatement( // annotation: override
		expression: Expression?)
		-> ArrayClass<Statement>
	{
		if let returnType = returnTypesStack.last,
			let expression = expression,
			let dotExpression = expression as? DotExpression
		{
			if let typeExpression = dotExpression.leftExpression as? TypeExpression {
				// It's ok to omit if the return type is an optional enum too
				var returnType = returnType
				if returnType.hasSuffix("?") {
					returnType = String(returnType.dropLast("?".count))
				}

				if typeExpression.typeName == returnType {
					let newExpression = removePrefixFromPossibleEnumReference(
						leftExpression: dotExpression.leftExpression,
						rightExpression: dotExpression.rightExpression)
					return [ReturnStatement(range: nil, expression: newExpression)]
				}
			}
		}

		return [ReturnStatement(range: nil, expression: expression)]
	}
}

public class RenameOperatorsTranspilationPass: TranspilationPass {
	// declaration: constructor(ast: GryphonAST): super(ast) { }

	override func replaceBinaryOperatorExpression( // annotation: override
		leftExpression: Expression,
		rightExpression: Expression,
		operatorSymbol: String,
		typeName: String)
		-> Expression
	{
        let operatorTranslations: DictionaryClass = [
            "??": "?:",
            "<<": "shl",
            ">>": "shr",
            "&": "and",
            "|": "or",
            "^": "xor",
        ]
		if let operatorTranslation = operatorTranslations[operatorSymbol] {
			return super.replaceBinaryOperatorExpression(
				leftExpression: leftExpression,
				rightExpression: rightExpression,
				operatorSymbol: operatorTranslation,
				typeName: typeName)
		}
		else {
			return super.replaceBinaryOperatorExpression(
				leftExpression: leftExpression,
				rightExpression: rightExpression,
				operatorSymbol: operatorSymbol,
				typeName: typeName)
		}
	}
}

public class SelfToThisTranspilationPass: TranspilationPass {
	// declaration: constructor(ast: GryphonAST): super(ast) { }

	override func replaceDotExpression( // annotation: override
		leftExpression: Expression,
		rightExpression: Expression)
		-> Expression
	{
		if let declarationReferenceExpression = leftExpression as? DeclarationReferenceExpression {
			if declarationReferenceExpression.data.identifier == "self",
				declarationReferenceExpression.data.isImplicit
			{
				return replaceExpression(rightExpression)
			}
		}

		return DotExpression(
			range: nil,
			leftExpression: replaceExpression(leftExpression),
			rightExpression: replaceExpression(rightExpression))
	}

	override func replaceDeclarationReferenceExpressionData( // annotation: override
		_ expression: DeclarationReferenceData)
		-> DeclarationReferenceData
	{
		if expression.identifier == "self" {
			let expression = expression
			expression.identifier = "this"
			return expression
		}
		return super.replaceDeclarationReferenceExpressionData(expression)
	}
}

/// Declarations can't conform to Swift-only protocols like Codable and Equatable, and enums can't
/// inherit from types Strings and Ints.
public class CleanInheritancesTranspilationPass: TranspilationPass {
	// declaration: constructor(ast: GryphonAST): super(ast) { }

	override func replaceEnumDeclaration( // annotation: override
		access: String?,
		enumName: String,
		inherits: ArrayClass<String>,
		elements: ArrayClass<EnumElement>,
		members: ArrayClass<Statement>,
		isImplicit: Bool)
		-> ArrayClass<Statement>
	{
		return super.replaceEnumDeclaration(
			access: access,
			enumName: enumName,
			inherits: inherits.filter {
					!TranspilationPass.isASwiftProtocol($0) &&
						!TranspilationPass.isASwiftRawRepresentableType($0)
				},
			elements: elements,
			members: members,
			isImplicit: isImplicit)
	}

	override func replaceStructDeclaration( // annotation: override
		annotations: String?,
		structName: String,
		inherits: ArrayClass<String>,
		members: ArrayClass<Statement>)
		-> ArrayClass<Statement>
	{
		return super.replaceStructDeclaration(
			annotations: annotations,
			structName: structName,
			inherits: inherits.filter { !TranspilationPass.isASwiftProtocol($0) },
			members: members)
	}

	override func replaceClassDeclaration( // annotation: override
		className: String,
		inherits: ArrayClass<String>,
		members: ArrayClass<Statement>)
		-> ArrayClass<Statement>
	{
		return super.replaceClassDeclaration(
			className: className,
			inherits: inherits.filter { !TranspilationPass.isASwiftProtocol($0) },
			members: members)
	}
}

/// The "anonymous parameter" `$0` has to be replaced by `it`
public class AnonymousParametersTranspilationPass: TranspilationPass {
	// declaration: constructor(ast: GryphonAST): super(ast) { }

	override func replaceDeclarationReferenceExpressionData( // annotation: override
		_ expression: DeclarationReferenceData)
		-> DeclarationReferenceData
	{
		if expression.identifier == "$0" {
			let expression = expression
			expression.identifier = "it"
			return expression
		}
		else {
			return super.replaceDeclarationReferenceExpressionData(expression)
		}
	}

	override func replaceClosureExpression( // annotation: override
		parameters: ArrayClass<LabeledType>,
		statements: ArrayClass<Statement>,
		typeName: String)
		-> Expression
	{
		if parameters.count == 1,
			parameters[0].label == "$0"
		{
			return super.replaceClosureExpression(
				parameters: [], statements: statements, typeName: typeName)
		}
		else {
			return super.replaceClosureExpression(
				parameters: parameters, statements: statements, typeName: typeName)
		}
	}
}

///
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
///
/// The conversion is done by calling `array.toMutableList<Element>()` rather than a normal class.
/// This allows translations to cover a few (not fully understood) corner cases where the array
/// isn't a `MutableList` (it happened once with an `EmptyList`), meaning a normal cast would fail.
///
public class CovarianceInitsAsCallsTranspilationPass: TranspilationPass {
	// declaration: constructor(ast: GryphonAST): super(ast) { }

	override func replaceCallExpression( // annotation: override
		_ callExpression: CallExpressionData)
		-> Expression
	{
		if let typeExpression = callExpression.function as? TypeExpression,
			let tupleExpression = callExpression.parameters as? TupleExpression
		{
			if typeExpression.typeName.hasPrefix("ArrayClass<"),
				tupleExpression.pairs.count == 1,
				let onlyPair = tupleExpression.pairs.first
			{
				let arrayClassElementType =
					String(typeExpression.typeName.dropFirst("ArrayClass<".count).dropLast())
				let mappedElementType = Utilities.getTypeMapping(for: arrayClassElementType) ??
					arrayClassElementType

				if onlyPair.label == "array" {
					// If we're initializing with an Array of a different type, we might need to call
					// `toMutableList`
					if let arrayType = onlyPair.expression.swiftType {
						let arrayElementType = arrayType.dropFirst().dropLast()

						if arrayElementType != arrayClassElementType {
							return DotExpression(
								range: nil,
								leftExpression: replaceExpression(onlyPair.expression),
								rightExpression: CallExpression(
									range: nil,
									data: CallExpressionData(
									function: DeclarationReferenceExpression(range: nil, data:
										DeclarationReferenceData(
											identifier: "toMutableList<\(mappedElementType)>",
											typeName: typeExpression.typeName,
											isStandardLibrary: false,
											isImplicit: false,
											range: nil)),
									parameters: TupleExpression(range: nil, pairs: []),
									typeName: typeExpression.typeName,
									range: nil)))
						}
					}
					// If it's an Array of the same type, just return the array itself
					return replaceExpression(onlyPair.expression)
				}
				else {
					return DotExpression(
						range: nil,
						leftExpression: replaceExpression(onlyPair.expression),
						rightExpression: CallExpression(range: nil, data: CallExpressionData(
							function: DeclarationReferenceExpression(range: nil, data:
								DeclarationReferenceData(
									identifier: "toMutableList<\(mappedElementType)>",
									typeName: typeExpression.typeName,
									isStandardLibrary: false,
									isImplicit: false,
									range: nil)),
							parameters: TupleExpression(range: nil, pairs: []),
							typeName: typeExpression.typeName,
							range: nil)))
				}
			}
		}

		if let dotExpression = callExpression.function as? DotExpression {
			if let leftType = dotExpression.leftExpression.swiftType,
				leftType.hasPrefix("ArrayClass"),
				let declarationReferenceExpression =
					dotExpression.rightExpression as? DeclarationReferenceExpression,
				let tupleExpression = callExpression.parameters as? TupleExpression
			{
				if declarationReferenceExpression.data.identifier == "as",
					tupleExpression.pairs.count == 1,
					let onlyPair = tupleExpression.pairs.first,
					let typeExpression = onlyPair.expression as? TypeExpression
				{
					return BinaryOperatorExpression(
						range: nil,
						leftExpression: dotExpression.leftExpression,
						rightExpression: TypeExpression(
							range: nil,
							typeName: typeExpression.typeName),
						operatorSymbol: "as?",
						typeName: typeExpression.typeName + "?")
				}
			}
		}

		return super.replaceCallExpression(callExpression)
	}
}

/// Closures in kotlin can't have normal "return" statements. Instead, they must have return@f
/// statements (not yet implemented) or just standalone expressions (easier to implement but more
/// error-prone). This pass turns return statements in closures into standalone expressions
public class ReturnsInLambdasTranspilationPass: TranspilationPass {
	// declaration: constructor(ast: GryphonAST): super(ast) { }

	var isInClosure = false

	override func replaceClosureExpression( // annotation: override
		parameters: ArrayClass<LabeledType>,
		statements: ArrayClass<Statement>,
		typeName: String)
		-> Expression
	{
		isInClosure = true
		defer { isInClosure = false }
		return super.replaceClosureExpression(
			parameters: parameters, statements: statements, typeName: typeName)
	}

	override func replaceReturnStatement( // annotation: override
		expression: Expression?)
		-> ArrayClass<Statement>
	{
		if isInClosure, let expression = expression {
			return [ExpressionStatement(range: nil, expression: expression)]
		}
		else {
			return [ReturnStatement(range: nil, expression: expression)]
		}
	}
}

/// Optional subscripts in kotlin have to be refactored as function calls:
///
/// ````
/// let array: [Int]? = [1, 2, 3]
/// array?[0] // Becomes `array?.get(0)` in Kotlin
/// ````
public class RefactorOptionalsInSubscriptsTranspilationPass: TranspilationPass {
	// declaration: constructor(ast: GryphonAST): super(ast) { }

	override func replaceSubscriptExpression( // annotation: override
		subscriptedExpression: Expression,
		indexExpression: Expression,
		typeName: String)
		-> Expression
	{
		if subscriptedExpression is OptionalExpression {
			return replaceDotExpression(
				leftExpression: subscriptedExpression,
				rightExpression: CallExpression(range: nil, data: CallExpressionData(
					function: DeclarationReferenceExpression(
						range: nil,
						data: DeclarationReferenceData(
							identifier: "get",
							typeName: "(\(indexExpression.swiftType ?? "<<Error>>")) -> \(typeName)",
							isStandardLibrary: false,
							isImplicit: false,
							range: subscriptedExpression.range)),
					parameters: TupleExpression(range: nil, pairs:
						[LabeledExpression(label: nil, expression: indexExpression)]),
					typeName: typeName,
					range: subscriptedExpression.range)))
		}
		else {
			return super.replaceSubscriptExpression(
				subscriptedExpression: subscriptedExpression,
				indexExpression: indexExpression,
				typeName: typeName)
		}
	}
}

/// Optional chaining in Kotlin must continue down the dot syntax chain.
///
/// ````
/// foo?.bar.baz
/// // Becomes
/// foo?.bar?.baz
/// ````
public class AddOptionalsInDotChainsTranspilationPass: TranspilationPass {
	// declaration: constructor(ast: GryphonAST): super(ast) { }

	override func replaceDotExpression( // annotation: override
		leftExpression: Expression,
		rightExpression: Expression)
		-> Expression
	{
		// FIXME:
		if rightExpression is OptionalExpression {
		}
		else if let dotExpression = leftExpression as? DotExpression {
			if dotExpressionChainHasOptionals(dotExpression.leftExpression) {
				return DotExpression(
					range: nil,
					leftExpression: addOptionalsToDotExpressionChain(
						leftExpression: dotExpression.leftExpression,
						rightExpression: dotExpression.rightExpression),
					rightExpression: rightExpression)
			}
		}

		return super.replaceDotExpression(
			leftExpression: leftExpression,
			rightExpression: rightExpression)
	}

	func addOptionalsToDotExpressionChain(
		leftExpression: Expression,
		rightExpression: Expression)
		-> Expression
	{
		// FIXME:
		if rightExpression is OptionalExpression {
		}
		else if dotExpressionChainHasOptionals(leftExpression) {

			let processedLeftExpression: Expression
			if let dotExpression = leftExpression as? DotExpression {
				processedLeftExpression = addOptionalsToDotExpressionChain(
					leftExpression: dotExpression.leftExpression,
					rightExpression: dotExpression.rightExpression)
			}
			else {
				processedLeftExpression = leftExpression
			}

			return addOptionalsToDotExpressionChain(
				leftExpression: processedLeftExpression,
				rightExpression: OptionalExpression(range: nil, expression: rightExpression))
		}

		return super.replaceDotExpression(
			leftExpression: leftExpression,
			rightExpression: rightExpression)
	}

	private func dotExpressionChainHasOptionals(_ expression: Expression) -> Bool {
		if expression is OptionalExpression {
			return true
		}
		else if let dotExpression = expression as? DotExpression {
			return dotExpressionChainHasOptionals(dotExpression.leftExpression)
		}
		else {
			return false
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
	// declaration: constructor(ast: GryphonAST): super(ast) { }

	/// Detect switches whose bodies all end in the same returns or assignments
	override func replaceSwitchStatement( // annotation: override
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

			if let returnStatement = lastStatement as? ReturnStatement {
				if returnStatement.expression != nil {
					hasAllAssignmentCases = false
					continue
				}
			}

			if let assignmentStatement = lastStatement as? AssignmentStatement {
				if assignmentExpression == nil ||
					assignmentExpression == assignmentStatement.leftHand
				{
					hasAllReturnCases = false
					assignmentExpression = assignmentStatement.leftHand
					continue
				}
			}

			hasAllReturnCases = false
			hasAllAssignmentCases = false
			break
		}

		if hasAllReturnCases {
			let newCases: ArrayClass<SwitchCase> = []
			for switchCase in cases {
				// Swift switches must have at least one statement
				let lastStatement = switchCase.statements.last!
				if let returnStatement = lastStatement as? ReturnStatement {
					if let returnExpression = returnStatement.expression {
						let newStatements = ArrayClass<Statement>(switchCase.statements.dropLast())
						newStatements.append(ExpressionStatement(
							range: nil,
							expression: returnExpression))
						newCases.append(SwitchCase(
							expressions: switchCase.expressions,
							statements: newStatements))
					}
				}
			}
			let conversionExpression =
				ReturnStatement(range: nil, expression: NilLiteralExpression(range: nil))
			return [SwitchStatement(
				range: nil,
				convertsToExpression: conversionExpression,
				expression: expression,
				cases: newCases), ]
		}
		else if hasAllAssignmentCases, let assignmentExpression = assignmentExpression {
			let newCases: ArrayClass<SwitchCase> = []
			for switchCase in cases {
				// Swift switches must have at least one statement
				let lastStatement = switchCase.statements.last!
				if let assignmentStatement = lastStatement as? AssignmentStatement {
					let newStatements = ArrayClass<Statement>(switchCase.statements.dropLast())
					newStatements.append(ExpressionStatement(
						range: nil,
						expression: assignmentStatement.rightHand))
					newCases.append(SwitchCase(
						expressions: switchCase.expressions,
						statements: newStatements))
				}
			}
			let conversionExpression = AssignmentStatement(
				range: nil,
				leftHand: assignmentExpression,
				rightHand: NilLiteralExpression(range: nil))
			return [SwitchStatement(
				range: nil,
				convertsToExpression: conversionExpression,
				expression: expression,
				cases: newCases), ]
		}
		else {
			return super.replaceSwitchStatement(
				convertsToExpression: nil, expression: expression, cases: cases)
		}
	}

	/// Replace variable declarations followed by switch statements assignments
	override func replaceStatements( // annotation: override
		_ oldStatements: ArrayClass<Statement>)
		-> ArrayClass<Statement>
	{
		let statements = super.replaceStatements(oldStatements)

		let result: ArrayClass<Statement> = []

		var i = 0
		while i < (statements.count - 1) {
			let currentStatement = statements[i]
			let nextStatement = statements[i + 1]
			if let variableDeclaration = currentStatement as? VariableDeclaration,
				let switchStatement = nextStatement as? SwitchStatement
			{
				if variableDeclaration.data.isImplicit == false,
					variableDeclaration.data.extendsType == nil,
					let switchConversion = switchStatement.convertsToExpression,
					let assignmentStatement = switchConversion as? AssignmentStatement
				{
					if let assignmentExpression =
						assignmentStatement.leftHand as? DeclarationReferenceExpression
					{

						if assignmentExpression.data.identifier ==
								variableDeclaration.data.identifier,
							!assignmentExpression.data.isStandardLibrary,
							!assignmentExpression.data.isImplicit
						{
							variableDeclaration.data.expression = NilLiteralExpression(range: nil)
							variableDeclaration.data.getter = nil
							variableDeclaration.data.setter = nil
							variableDeclaration.data.isStatic = false
							let newConversionExpression = variableDeclaration
							result.append(SwitchStatement(
								range: nil,
								convertsToExpression: newConversionExpression,
								expression: switchStatement.expression,
								cases: switchStatement.cases))

							// Skip appending variable declaration and the switch declaration, thus
							// replacing both with the new switch declaration
							i += 2

							continue
						}
					}
				}
			}

			result.append(currentStatement)
			i += 1
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
	// declaration: constructor(ast: GryphonAST): super(ast) { }

	override func replaceSwitchStatement( // annotation: override
		convertsToExpression: Statement?,
		expression: Expression,
		cases: ArrayClass<SwitchCase>)
		-> ArrayClass<Statement>
	{
		let newCases = cases.compactMap { removeBreaksInSwitchCase($0) }

		return super.replaceSwitchStatement(
			convertsToExpression: convertsToExpression,
			expression: expression,
			cases: newCases)
	}

	private func removeBreaksInSwitchCase(_ switchCase: SwitchCase) -> SwitchCase? {
		if switchCase.statements.count == 1,
			let onlyStatement = switchCase.statements.first,
			onlyStatement is BreakStatement
		{
			return nil
		}
		else {
			return switchCase
		}
	}
}

/// Sealed classes should be tested for subclasses with the `is` operator. This is automatically
/// done for enum cases with associated values, but in other cases it has to be handled here.
public class IsOperatorsInSealedClassesTranspilationPass: TranspilationPass {
	// declaration: constructor(ast: GryphonAST): super(ast) { }

	override func replaceSwitchStatement( // annotation: override
		convertsToExpression: Statement?,
		expression: Expression,
		cases: ArrayClass<SwitchCase>)
		-> ArrayClass<Statement>
	{
		if let declarationReferenceExpression = expression as? DeclarationReferenceExpression {
			if KotlinTranslator.sealedClasses.contains(
				declarationReferenceExpression.data.typeName)
			{
				let newCases = cases.map {
					replaceIsOperatorsInSwitchCase($0, usingExpression: expression)
				}

				return super.replaceSwitchStatement(
					convertsToExpression: convertsToExpression,
					expression: expression,
					cases: newCases)
			}
		}

		return super.replaceSwitchStatement(
			convertsToExpression: convertsToExpression,
			expression: expression,
			cases: cases)
	}

	private func replaceIsOperatorsInSwitchCase(
		_ switchCase: SwitchCase,
		usingExpression expression: Expression)
		-> SwitchCase
	{
		let newExpressions = switchCase.expressions.map {
			replaceIsOperatorsInExpression($0, usingExpression: expression)
		}

		return SwitchCase(
			expressions: newExpressions,
			statements: switchCase.statements)
	}

	private func replaceIsOperatorsInExpression(
		_ caseExpression: Expression,
		usingExpression expression: Expression)
		-> Expression
	{
		if let dotExpression = caseExpression as? DotExpression {
			if let typeExpression = dotExpression.leftExpression as? TypeExpression,
				let declarationReferenceExpression =
					dotExpression.rightExpression as? DeclarationReferenceExpression
			{
				return BinaryOperatorExpression(
					range: nil,
					leftExpression: expression,
					rightExpression: TypeExpression(
						range: nil,
						typeName: "\(typeExpression.typeName)." +
							"\(declarationReferenceExpression.data.identifier)"),
					operatorSymbol: "is",
					typeName: "Bool")
			}
		}

		return caseExpression
	}
}

public class RemoveExtensionsTranspilationPass: TranspilationPass {
	// declaration: constructor(ast: GryphonAST): super(ast) { }

	var extendingType: String?

	override func replaceExtension( // annotation: override
		typeName: String,
		members: ArrayClass<Statement>)
		-> ArrayClass<Statement>
	{
		extendingType = typeName
		let members = replaceStatements(members)
		extendingType = nil
		return members
	}

	override func replaceStatement( // annotation: override
		_ statement: Statement)
		-> ArrayClass<Statement>
	{
		if let extensionDeclaration = statement as? ExtensionDeclaration {
			return replaceExtension(
				typeName: extensionDeclaration.typeName,
				members: extensionDeclaration.members)
		}
		if let functionDeclaration = statement as? FunctionDeclaration {
			return replaceFunctionDeclaration(functionDeclaration.data)
		}
		if let variableDeclaration = statement as? VariableDeclaration {
			return replaceVariableDeclaration(variableDeclaration.data)
		}

		return [statement]
	}

	override func replaceFunctionDeclaration( // annotation: override
		_ functionDeclaration: FunctionDeclarationData)
		-> ArrayClass<Statement>
	{
		functionDeclaration.extendsType = self.extendingType
		return [FunctionDeclaration(range: nil, data: functionDeclaration)]
	}

	override func replaceVariableDeclarationData( // annotation: override
		_ variableDeclaration: VariableDeclarationData)
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
///
/// It also records all functions that have been marked as pure so that they don't raise warnings
/// for possible side-effects in if-lets.
public class RecordFunctionsTranspilationPass: TranspilationPass {
	// declaration: constructor(ast: GryphonAST): super(ast) { }

	override func replaceFunctionDeclarationData( // annotation: override
		_ functionDeclaration: FunctionDeclarationData)
		-> FunctionDeclarationData?
	{
		let swiftAPIName = functionDeclaration.prefix + "(" +
			functionDeclaration.parameters.map { ($0.apiLabel ?? "_") + ":" }.joined() + ")"

		KotlinTranslator.addFunctionTranslation(KotlinTranslator.FunctionTranslation(
			swiftAPIName: swiftAPIName,
			typeName: functionDeclaration.functionType,
			prefix: functionDeclaration.prefix,
			parameters: functionDeclaration.parameters.map { $0.label }))

		//
		if functionDeclaration.isPure {
			KotlinTranslator.recordPureFunction(functionDeclaration)
		}

		return super.replaceFunctionDeclarationData(functionDeclaration)
	}
}

public class RecordEnumsTranspilationPass: TranspilationPass {
	// declaration: constructor(ast: GryphonAST): super(ast) { }

	override func replaceEnumDeclaration( // annotation: override
		access: String?,
		enumName: String,
		inherits: ArrayClass<String>,
		elements: ArrayClass<EnumElement>,
		members: ArrayClass<Statement>,
		isImplicit: Bool)
		-> ArrayClass<Statement>
	{
		let isEnumClass = inherits.isEmpty && elements.reduce(true) { result, element in
			result && element.associatedValues.isEmpty
		}

		if isEnumClass {
			KotlinTranslator.addEnumClass(enumName)
		}
		else {
			KotlinTranslator.addSealedClass(enumName)
		}

		return [EnumDeclaration(
			range: nil,
			access: access,
			enumName: enumName,
			inherits: inherits,
			elements: elements,
			members: members,
			isImplicit: isImplicit), ]
	}
}

/// Records all protocol declarations in the Kotlin Translator
public class RecordProtocolsTranspilationPass: TranspilationPass {
	// declaration: constructor(ast: GryphonAST): super(ast) { }

	override func replaceProtocolDeclaration( // annotation: override
		protocolName: String,
		members: ArrayClass<Statement>)
		-> ArrayClass<Statement>
	{
		KotlinTranslator.addProtocol(protocolName)

		return super.replaceProtocolDeclaration(protocolName: protocolName, members: members)
	}
}

public class RaiseStandardLibraryWarningsTranspilationPass: TranspilationPass {
	// declaration: constructor(ast: GryphonAST): super(ast) { }

	override func replaceDeclarationReferenceExpressionData( // annotation: override
		_ expression: DeclarationReferenceData)
		-> DeclarationReferenceData
	{
		if expression.isStandardLibrary {
			let message = "Reference to standard library \"\(expression.identifier)\" was not " +
				"translated."
			Compiler.handleWarning(
					message: message,
					sourceFile: ast.sourceFile,
					sourceFileRange: expression.range)
		}
		return super.replaceDeclarationReferenceExpressionData(expression)
	}
}

/// If a value type's members are all immutable, that value type can safely be translated as a
/// class. Otherwise, the translation can cause inconsistencies, so this pass raises warnings.
/// Source: https://forums.swift.org/t/are-immutable-structs-like-classes/16270
public class RaiseMutableValueTypesWarningsTranspilationPass: TranspilationPass {
	// declaration: constructor(ast: GryphonAST): super(ast) { }

	override func replaceStructDeclaration( // annotation: override
		annotations: String?,
		structName: String,
		inherits: ArrayClass<String>,
		members: ArrayClass<Statement>)
		-> ArrayClass<Statement>
	{
		for member in members {
			if let variableDeclaration = member as? VariableDeclaration {
				if !variableDeclaration.data.isImplicit,
					!variableDeclaration.data.isStatic,
					!variableDeclaration.data.isLet,
					variableDeclaration.data.getter == nil
				{
					let message = "No support for mutable variables in value types: found" +
						" variable \(variableDeclaration.data.identifier) inside struct " +
						structName
					Compiler.handleWarning(
						message: message,
						sourceFile: ast.sourceFile,
						sourceFileRange: nil)
					continue
				}
			}

			if let functionDeclaration = member as? FunctionDeclaration {
				if functionDeclaration.data.isMutating {
					let methodName = functionDeclaration.data.prefix + "(" +
						functionDeclaration.data.parameters.map { $0.label + ":" }
							.joined(separator: ", ") + ")"
					let message = "No support for mutating methods in value types: found method " +
						"\(methodName) inside struct \(structName)"
					Compiler.handleWarning(
						message: message,
						sourceFile: ast.sourceFile,
						sourceFileRange: nil)
					continue
				}
			}
		}

		return super.replaceStructDeclaration(
			annotations: annotations, structName: structName, inherits: inherits, members: members)
	}

	override func replaceEnumDeclaration( // annotation: override
		access: String?,
		enumName: String,
		inherits: ArrayClass<String>,
		elements: ArrayClass<EnumElement>,
		members: ArrayClass<Statement>,
		isImplicit: Bool)
		-> ArrayClass<Statement>
	{
		for member in members {
			if let functionDeclaration = member as? FunctionDeclaration {
				if functionDeclaration.data.isMutating {
					let methodName = functionDeclaration.data.prefix + "(" +
						functionDeclaration.data.parameters.map { $0.label + ":" }
							.joined(separator: ", ") + ")"
					let message = "No support for mutating methods in value types: found method " +
						"\(methodName) inside enum \(enumName)"
					Compiler.handleWarning(
						message: message,
						sourceFile: ast.sourceFile,
						sourceFileRange: nil)
				}
			}
		}

		return super.replaceEnumDeclaration(
			access: access,
			enumName: enumName,
			inherits: inherits,
			elements: elements,
			members: members,
			isImplicit: isImplicit)
	}
}

/// `ArrayClass`es and `DictionaryClass`es are prefered to using `Arrays` and `Dictionaries` for
/// guaranteeing correctness. This pass raises warnings when it finds uses of the native data
/// structures, which should help avoid these bugs.
public class RaiseNativeDataStructureWarningsTranspilationPass: TranspilationPass {
	// declaration: constructor(ast: GryphonAST): super(ast) { }

	override func replaceExpression(_ expression: Expression) -> Expression // annotation: override
	{
		if let type = expression.swiftType, type.hasPrefix("[") {
			let message = "Native type \(type) can lead to different behavior in Kotlin. Prefer " +
			"ArrayClass or DictionaryClass instead."
			Compiler.handleWarning(
				message: message,
				details: expression.prettyDescription(),
				sourceFile: ast.sourceFile,
				sourceFileRange: nil)
		}

		return super.replaceExpression(expression)
	}

	override func replaceDotExpression( // annotation: override
		leftExpression: Expression,
		rightExpression: Expression)
		-> Expression
	{
		// TODO: automatically add parentheses around or's in if conditions otherwise they can
		// associate incorrectly.

		// If the expression is being transformed into a mutableList or a mutableMap it's probably
		// ok.
		if let leftExpressionType = leftExpression.swiftType,
			leftExpressionType.hasPrefix("["),
			let callExpression = rightExpression as? CallExpression {
			if (callExpression.data.typeName.hasPrefix("ArrayClass") ||
					callExpression.data.typeName.hasPrefix("DictionaryClass")),
				let declarationReference =
					callExpression.data.function as? DeclarationReferenceExpression
			{
				if declarationReference.data.identifier.hasPrefix("toMutable"),
					(declarationReference.data.typeName.hasPrefix("ArrayClass") ||
						declarationReference.data.typeName.hasPrefix("DictionaryClass"))
				{
					return DotExpression(
						range: nil,
						leftExpression: leftExpression,
						rightExpression: rightExpression)
				}
			}
		}

		return super.replaceDotExpression(
			leftExpression: leftExpression,
			rightExpression: rightExpression)
	}
}

/// If statements with let declarations get translated to Kotlin by having their let declarations
/// rearranged to be before the if statement. This will cause any let conditions that have side
/// effects (i.e. `let x = sideEffects()`) to run eagerly on Kotlin but lazily on Swift, which can
/// lead to incorrect behavior.
public class RaiseWarningsForSideEffectsInIfLetsTranspilationPass: TranspilationPass {
	// declaration: constructor(ast: GryphonAST): super(ast) { }

	override func replaceIfStatementData( // annotation: override
		_ ifStatement: IfStatementData)
		-> IfStatementData
	{
		raiseWarningsForIfStatement(ifStatement, isElse: false)

		// No recursion by calling super, otherwise we'd run on the else statements twice
		// TODO: Add recursion on the if's statements
		return ifStatement
	}

	private func raiseWarningsForIfStatement(_ ifStatement: IfStatementData, isElse: Bool) {
		// The first condition of an non-else if statement is the only one that can safely have side
		// effects
		let conditions = isElse ?
			ifStatement.conditions :
			ArrayClass<IfStatementData.IfCondition>(ifStatement.conditions.dropFirst())

		let sideEffectsRanges = conditions.flatMap { rangesWithPossibleSideEffectsInCondition($0) }
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

	private func rangesWithPossibleSideEffectsInCondition(
		_ condition: IfStatementData.IfCondition)
		-> ArrayClass<SourceFileRange>
	{
		if case let .declaration(variableDeclaration: variableDeclaration) = condition {
			if let expression = variableDeclaration.expression {
				return rangesWithPossibleSideEffectsIn(expression)
			}
		}

		return []
	}

	private func rangesWithPossibleSideEffectsIn(
		_ expression: Expression)
		-> ArrayClass<SourceFileRange>
	{
		if let subExpression = expression as? CallExpression {
			if !KotlinTranslator.isReferencingPureFunction(subExpression.data),
				let range = subExpression.data.range
			{
				return [range]
			}
			else {
				return []
			}
		}
		if let subExpression = expression as? ParenthesesExpression {
			return rangesWithPossibleSideEffectsIn(subExpression.expression)
		}
		if let subExpression = expression as? ForceValueExpression {
			return rangesWithPossibleSideEffectsIn(subExpression.expression)
		}
		if let subExpression = expression as? OptionalExpression {
			return rangesWithPossibleSideEffectsIn(subExpression.expression)
		}
		if let subExpression = expression as? SubscriptExpression {
			let result = rangesWithPossibleSideEffectsIn(subExpression.subscriptedExpression)
			result.append(contentsOf:
				rangesWithPossibleSideEffectsIn(subExpression.indexExpression))
			return result
		}
		if let subExpression = expression as? ArrayExpression {
			return subExpression.elements.flatMap { rangesWithPossibleSideEffectsIn($0) }
		}
		if let subExpression = expression as? DictionaryExpression {
			let result = subExpression.keys.flatMap { rangesWithPossibleSideEffectsIn($0) }
			result.append(contentsOf:
				subExpression.values.flatMap { rangesWithPossibleSideEffectsIn($0) })
			return result
		}
		if let subExpression = expression as? DotExpression {
			let result = rangesWithPossibleSideEffectsIn(subExpression.leftExpression)
			result.append(contentsOf:
				rangesWithPossibleSideEffectsIn(subExpression.rightExpression))
			return result
		}
		if let subExpression = expression as? BinaryOperatorExpression {
			let result = rangesWithPossibleSideEffectsIn(subExpression.leftExpression)
			result.append(contentsOf:
				rangesWithPossibleSideEffectsIn(subExpression.rightExpression))
			return result
		}
		if let subExpression = expression as? PrefixUnaryExpression {
			return rangesWithPossibleSideEffectsIn(subExpression.subExpression)
		}
		if let subExpression = expression as? PostfixUnaryExpression {
			return rangesWithPossibleSideEffectsIn(subExpression.subExpression)
		}
		if let subExpression = expression as? IfExpression {
			let result = rangesWithPossibleSideEffectsIn(subExpression.condition)
			result.append(contentsOf:
				rangesWithPossibleSideEffectsIn(subExpression.trueExpression))
			result.append(contentsOf:
				rangesWithPossibleSideEffectsIn(subExpression.falseExpression))
			return result
		}
		if let subExpression = expression as? InterpolatedStringLiteralExpression {
			return subExpression.expressions.flatMap { rangesWithPossibleSideEffectsIn($0) }
		}
		if let subExpression = expression as? TupleExpression {
			return subExpression.pairs.flatMap { rangesWithPossibleSideEffectsIn($0.expression) }
		}
		if let subExpression = expression as? TupleShuffleExpression {
			return subExpression.expressions.flatMap { rangesWithPossibleSideEffectsIn($0) }
		}

		return []
	}
}

/// Sends let declarations to before the if statement, and replaces them with `x != null` conditions
public class RearrangeIfLetsTranspilationPass: TranspilationPass {
	// declaration: constructor(ast: GryphonAST): super(ast) { }

	/// Send the let declarations to before the if statement
	override func replaceIfStatement( // annotation: override
		_ ifStatement: IfStatementData)
		-> ArrayClass<Statement>
	{
		let result: ArrayClass<Statement> = gatherLetDeclarations(ifStatement)
			.map { VariableDeclaration(range: nil, data: $0) }

		result.append(contentsOf: super.replaceIfStatement(ifStatement))

		return result
	}

	/// Add conditions (`x != null`) for all let declarations
	override func replaceIfStatementData( // annotation: override
		_ ifStatement: IfStatementData)
		-> IfStatementData
	{
		let newConditions = ifStatement.conditions.map {
			replaceIfLetConditionWithNullCheck($0)
		}

		let ifStatement = ifStatement
		ifStatement.conditions = newConditions
		return super.replaceIfStatementData(ifStatement)
	}

	private func replaceIfLetConditionWithNullCheck(
		_ condition: IfStatementData.IfCondition)
		-> IfStatementData.IfCondition
	{
		if case let .declaration(variableDeclaration: variableDeclaration) = condition {
			return .condition(expression: BinaryOperatorExpression(
				range: nil,
				leftExpression: DeclarationReferenceExpression(range: nil, data:
					DeclarationReferenceData(
						identifier: variableDeclaration.identifier,
						typeName: variableDeclaration.typeName,
						isStandardLibrary: false,
						isImplicit: false,
						range: variableDeclaration.expression?.range)),
				rightExpression: NilLiteralExpression(range: nil),
				operatorSymbol: "!=",
				typeName: "Boolean"))
		}
		else {
			return condition
		}
	}

	/// Gather the let declarations from the if statement and its else( if)s into a single array
	private func gatherLetDeclarations(
		_ ifStatement: IfStatementData?)
		-> ArrayClass<VariableDeclarationData>
	{
		guard let ifStatement = ifStatement else {
			return []
		}

		let letDeclarations = ifStatement.conditions.compactMap {
				filterVariableDeclaration($0)
			}.filter {
				!isShadowingVariableDeclaration($0)
			}

		let elseLetDeclarations = gatherLetDeclarations(ifStatement.elseStatement)

		let result = letDeclarations
		result.append(contentsOf: elseLetDeclarations)
		return result
	}

	private func filterVariableDeclaration(
		_ condition: IfStatementData.IfCondition)
		-> VariableDeclarationData?
	{
		if case let .declaration(variableDeclaration: variableDeclaration) = condition {
			return variableDeclaration
		}
		else {
			return nil
		}
	}

	private func isShadowingVariableDeclaration(
		_ variableDeclaration: VariableDeclarationData)
		-> Bool
	{
		// If it's a shadowing identifier there's no need to declare it in Kotlin
		// (i.e. `if let x = x { }`)
		if let declarationExpression = variableDeclaration.expression,
			let expression = declarationExpression as? DeclarationReferenceExpression
		{
			if expression.data.identifier == variableDeclaration.identifier {
				return true
			}
		}

		return false
	}
}

/// Change the implementation of a `==` operator to be usable in Kotlin
public class EquatableOperatorsTranspilationPass: TranspilationPass {
	// declaration: constructor(ast: GryphonAST): super(ast) { }

	override func replaceFunctionDeclarationData( // annotation: override
		_ functionDeclaration: FunctionDeclarationData)
		-> FunctionDeclarationData?
	{
		guard functionDeclaration.prefix == "==",
			functionDeclaration.parameters.count == 2,
			let oldStatements = functionDeclaration.statements else
		{
			return functionDeclaration
		}

		let lhs = functionDeclaration.parameters[0]
		let rhs = functionDeclaration.parameters[1]

		let newStatements: ArrayClass<Statement> = []

		// Declare new variables with the same name as the Swift paramemeters, containing `this` and
		// `other`
		newStatements.append(VariableDeclaration(range: nil, data: VariableDeclarationData(
			identifier: lhs.label,
			typeName: lhs.typeName,
			expression: DeclarationReferenceExpression(range: nil, data: DeclarationReferenceData(
				identifier: "this",
				typeName: lhs.typeName,
				isStandardLibrary: false,
				isImplicit: false,
				range: nil)),
			getter: nil,
			setter: nil,
			isLet: true,
			isImplicit: false,
			isStatic: false,
			extendsType: nil,
			annotations: nil)))
		newStatements.append(VariableDeclaration(range: nil, data: VariableDeclarationData(
			identifier: rhs.label,
			typeName: "Any?",
			expression: DeclarationReferenceExpression(range: nil, data: DeclarationReferenceData(
				identifier: "other",
				typeName: "Any?",
				isStandardLibrary: false,
				isImplicit: false,
				range: nil)),
			getter: nil,
			setter: nil,
			isLet: true,
			isImplicit: false,
			isStatic: false,
			extendsType: nil,
			annotations: nil)))

		// Add an if statement to guarantee the comparison only happens between the right types
		newStatements.append(IfStatement(range: nil, data: IfStatementData(
			conditions: [ .condition(expression: BinaryOperatorExpression(
				range: nil,
				leftExpression: DeclarationReferenceExpression(
					range: nil,
					data: DeclarationReferenceData(
						identifier: rhs.label,
						typeName: "Any?",
						isStandardLibrary: false,
						isImplicit: false,
						range: nil)),
				rightExpression: TypeExpression(range: nil, typeName: rhs.typeName),
				operatorSymbol: "is",
				typeName: "Bool")),
			],
			declarations: [],
			statements: oldStatements,
			elseStatement: IfStatementData(
				conditions: [],
				declarations: [],
				statements: [
					ReturnStatement(range: nil, expression:
						LiteralBoolExpression(range: nil, value: false)),
				],
				elseStatement: nil,
				isGuard: false),
			isGuard: false)))

		return super.replaceFunctionDeclarationData(FunctionDeclarationData(
			prefix: "equals",
			parameters: [
				FunctionParameter(
					label: "other",
					apiLabel: nil,
					typeName: "Any?",
					value: nil), ],
			returnType: "Bool",
			functionType: "(Any?) -> Bool",
			genericTypes: [],
			isImplicit: functionDeclaration.isImplicit,
			isStatic: false,
			isMutating: functionDeclaration.isMutating,
			isPure: functionDeclaration.isPure,
			extendsType: nil,
			statements: newStatements,
			access: nil,
			annotations: "override open"))
	}
}

/// Create a rawValue variable for enums that conform to rawRepresentable
public class RawValuesTranspilationPass: TranspilationPass {
	// declaration: constructor(ast: GryphonAST): super(ast) { }

	override func replaceEnumDeclaration( // annotation: override
		access: String?,
		enumName: String,
		inherits: ArrayClass<String>,
		elements: ArrayClass<EnumElement>,
		members: ArrayClass<Statement>,
		isImplicit: Bool) -> ArrayClass<Statement>
	{
		if let typeName = elements.compactMap({ $0.rawValue?.swiftType }).first {
			let rawValueVariable = createRawValueVariable(
				rawValueType: typeName,
				access: access,
				enumName: enumName,
				elements: elements)

			guard let rawValueInitializer = createRawValueInitializer(
				rawValueType: typeName,
				access: access,
				enumName: enumName,
				elements: elements) else
			{
				Compiler.handleWarning(
					message: "Failed to create init(rawValue:)",
					details: "Unable to get all raw values in enum declaration.",
					sourceFile: ast.sourceFile,
					sourceFileRange: elements.compactMap { $0.rawValue?.range }.first)
				return super.replaceEnumDeclaration(
					access: access,
					enumName: enumName,
					inherits: inherits,
					elements: elements,
					members: members,
					isImplicit: isImplicit)
			}

			let newMembers = members
			newMembers.append(FunctionDeclaration(range: nil, data: rawValueInitializer))
			newMembers.append(VariableDeclaration(range: nil, data: rawValueVariable))

			return super.replaceEnumDeclaration(
				access: access,
				enumName: enumName,
				inherits: inherits,
				elements: elements,
				members: newMembers,
				isImplicit: isImplicit)
		}
		else {
			return super.replaceEnumDeclaration(
				access: access,
				enumName: enumName,
				inherits: inherits,
				elements: elements,
				members: members,
				isImplicit: isImplicit)
		}
	}

	private func createRawValueInitializer(
		rawValueType: String,
		access: String?,
		enumName: String,
		elements: ArrayClass<EnumElement>)
		-> FunctionDeclarationData?
	{
		for element in elements {
			if element.rawValue == nil {
				return nil
			}
		}

		let switchCases = elements.map { element -> SwitchCase in
			SwitchCase(
				expressions: [element.rawValue!],
				statements: [
					ReturnStatement(
						range: nil,
						expression: DotExpression(
							range: nil,
							leftExpression: TypeExpression(range: nil, typeName: enumName),
							rightExpression: DeclarationReferenceExpression(
								range: nil,
								data: DeclarationReferenceData(
									identifier: element.name,
									typeName: enumName,
									isStandardLibrary: false,
									isImplicit: false,
									range: nil)))),
				])
		}

		let defaultSwitchCase = SwitchCase(
			expressions: [],
			statements: [ReturnStatement(range: nil, expression: NilLiteralExpression(range: nil))])

		switchCases.append(defaultSwitchCase)

		let switchStatement = SwitchStatement(
			range: nil,
			convertsToExpression: nil,
			expression: DeclarationReferenceExpression(range: nil, data:
				DeclarationReferenceData(
					identifier: "rawValue",
					typeName: rawValueType,
					isStandardLibrary: false,
					isImplicit: false,
					range: nil)),
			cases: switchCases)

		return FunctionDeclarationData(
			prefix: "init",
			parameters: [FunctionParameter(
				label: "rawValue",
				apiLabel: nil,
				typeName: rawValueType,
				value: nil), ],
			returnType: enumName + "?",
			functionType: "(\(rawValueType)) -> \(enumName)?",
			genericTypes: [],
			isImplicit: false,
			isStatic: true,
			isMutating: false,
			isPure: true,
			extendsType: nil,
			statements: [switchStatement],
			access: access,
			annotations: nil)
	}

	private func createRawValueVariable(
		rawValueType: String,
		access: String?,
		enumName: String,
		elements: ArrayClass<EnumElement>)
		-> VariableDeclarationData
	{
		let switchCases = elements.map { element in
			SwitchCase(
				expressions: [DotExpression(
					range: nil,
					leftExpression: TypeExpression(range: nil, typeName: enumName),
					rightExpression: DeclarationReferenceExpression(
						range: nil,
						data: DeclarationReferenceData(
							identifier: element.name,
							typeName: enumName,
							isStandardLibrary: false,
							isImplicit: false,
							range: nil))), ],
				statements: [
					ReturnStatement(
						range: nil,
						expression: element.rawValue),
				])
		}

		let switchStatement = SwitchStatement(
			range: nil,
			convertsToExpression: nil,
			expression: DeclarationReferenceExpression(range: nil, data:
				DeclarationReferenceData(
					identifier: "this",
					typeName: enumName,
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
			isPure: false,
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
	// declaration: constructor(ast: GryphonAST): super(ast) { }

	override func replaceIfStatementData( // annotation: override
		_ ifStatement: IfStatementData)
		-> IfStatementData
	{
		if ifStatement.isGuard,
			ifStatement.conditions.count == 1,
			let onlyCondition = ifStatement.conditions.first,
			case let .condition(expression: onlyConditionExpression) = onlyCondition
		{
			let shouldStillBeGuard: Bool
			let newCondition: Expression
			if let prefixUnaryExpression = onlyConditionExpression as? PrefixUnaryExpression,
				prefixUnaryExpression.operatorSymbol == "!"
			{
				newCondition = prefixUnaryExpression.subExpression
				shouldStillBeGuard = false
			}
			else if let binaryOperatorExpression =
					onlyConditionExpression as? BinaryOperatorExpression,
				binaryOperatorExpression.operatorSymbol == "!="
			{
				newCondition = BinaryOperatorExpression(
					range: nil,
					leftExpression: binaryOperatorExpression.leftExpression,
					rightExpression: binaryOperatorExpression.rightExpression,
					operatorSymbol: "==",
					typeName: binaryOperatorExpression.typeName)
				shouldStillBeGuard = false
			}
			else if let binaryOperatorExpression =
					onlyConditionExpression as? BinaryOperatorExpression,
				binaryOperatorExpression.operatorSymbol == "=="
			{
				newCondition = BinaryOperatorExpression(
					range: nil,
					leftExpression: binaryOperatorExpression.leftExpression,
					rightExpression: binaryOperatorExpression.rightExpression,
					operatorSymbol: "!=",
					typeName: binaryOperatorExpression.typeName)
				shouldStillBeGuard = false
			}
			else {
				newCondition = onlyConditionExpression
				shouldStillBeGuard = true
			}

			let ifStatement = ifStatement
			ifStatement.conditions = ArrayClass<Expression>([newCondition]).map {
				IfStatementData.IfCondition.condition(expression: $0)
			}
			ifStatement.isGuard = shouldStillBeGuard
			return super.replaceIfStatementData(ifStatement)
		}
		else {
			return super.replaceIfStatementData(ifStatement)
		}
	}
}

/// Statements of the type `if (a == null) { return }` in Swift can be translated as `a ?: return`
/// in Kotlin.
public class ReturnIfNilTranspilationPass: TranspilationPass {
	// declaration: constructor(ast: GryphonAST): super(ast) { }

	override func replaceStatement( // annotation: override
		_ statement: Statement)
		-> ArrayClass<Statement>
	{
		if let ifStatement = statement as? IfStatement {
			if ifStatement.data.conditions.count == 1,
				ifStatement.data.statements.count == 1
			{
				let onlyStatement = ifStatement.data.statements[0]
				let onlyCondition = ifStatement.data.conditions[0]

				if case let .condition(expression: onlyConditionExpression) = onlyCondition,
					let returnStatement = onlyStatement as? ReturnStatement
				{
					if let binaryOperatorExpression =
							onlyConditionExpression as? BinaryOperatorExpression,
						binaryOperatorExpression.operatorSymbol == "=="
					{
						if let declarationExpression =
								binaryOperatorExpression.leftExpression as?
									DeclarationReferenceExpression,
							binaryOperatorExpression.rightExpression is NilLiteralExpression
						{
							return [ExpressionStatement(range: nil, expression:
								BinaryOperatorExpression(
									range: nil,
									leftExpression: binaryOperatorExpression.leftExpression,
									rightExpression: ReturnExpression(range: nil, expression:
										returnStatement.expression),
									operatorSymbol: "?:",
									typeName: declarationExpression.data.typeName)), ]
						}
					}
				}
			}
		}

		return super.replaceStatement(statement)
	}
}

public class FixProtocolContentsTranspilationPass: TranspilationPass {
	// declaration: constructor(ast: GryphonAST): super(ast) { }

	var isInProtocol = false

	override func replaceProtocolDeclaration( // annotation: override
		protocolName: String,
		members: ArrayClass<Statement>)
		-> ArrayClass<Statement>
	{
		isInProtocol = true
		let result = super.replaceProtocolDeclaration(protocolName: protocolName, members: members)
		isInProtocol = false

		return result
	}

	override func replaceFunctionDeclarationData( // annotation: override
		_ functionDeclaration: FunctionDeclarationData)
		-> FunctionDeclarationData?
	{
		if isInProtocol {
			let functionDeclaration = functionDeclaration
			functionDeclaration.statements = nil
			return super.replaceFunctionDeclarationData(functionDeclaration)
		}
		else {
			return super.replaceFunctionDeclarationData(functionDeclaration)
		}
	}

	override func replaceVariableDeclarationData( // annotation: override
		_ variableDeclaration: VariableDeclarationData)
		-> VariableDeclarationData
	{
		if isInProtocol {
			let variableDeclaration = variableDeclaration
			variableDeclaration.getter?.isImplicit = true
			variableDeclaration.setter?.isImplicit = true
			variableDeclaration.getter?.statements = nil
			variableDeclaration.setter?.statements = nil
			return super.replaceVariableDeclarationData(variableDeclaration)
		}
		else {
			return super.replaceVariableDeclarationData(variableDeclaration)
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
		result = RecordProtocolsTranspilationPass(ast: result).run()
		result = RecordFunctionsTranspilationPass(ast: result).run()

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
		result = EquatableOperatorsTranspilationPass(ast: result).run()
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
		result = CovarianceInitsAsCallsTranspilationPass(ast: result).run()
		result = ReturnsInLambdasTranspilationPass(ast: result).run()
		result = RefactorOptionalsInSubscriptsTranspilationPass(ast: result).run()
		result = AddOptionalsInDotChainsTranspilationPass(ast: result).run()
		result = RenameOperatorsTranspilationPass(ast: result).run()

		// - CapitalizeEnums has to be before IsOperatorsInSealedClasses
		result = CapitalizeEnumsTranspilationPass(ast: result).run()
		result = IsOperatorsInSealedClassesTranspilationPass(ast: result).run()

		// - SwitchesToExpressions has to be before RemoveBreaksInSwitches:
		//   RemoveBreaks might remove a case that only has a break, turning an exhaustive switch
		//   into a non-exhaustive one and making it convertible to an expression. However, only
		//   exhaustive switches can be converted to expressions, so this should be avoided.
		result = SwitchesToExpressionsTranspilationPass(ast: result).run()
		result = RemoveBreaksInSwitchesTranspilationPass(ast: result).run()

		// Improve Kotlin readability
		result = OmitImplicitEnumPrefixesTranspilationPass(ast: result).run()
		result = InnerTypePrefixesTranspilationPass(ast: result).run()
		result = DoubleNegativesInGuardsTranspilationPass(ast: result).run()
		result = ReturnIfNilTranspilationPass(ast: result).run()

		// Raise any warnings that may be left
		result = RaiseStandardLibraryWarningsTranspilationPass(ast: result).run()
		result = RaiseMutableValueTypesWarningsTranspilationPass(ast: result).run()
		result = RaiseNativeDataStructureWarningsTranspilationPass(ast: result).run()

		return result
	}

	func printParents() {
		print("[")
		for parent in parents {
			switch parent {
			case let .statementNode(statement):
				print("\t\(statement.name),")
			case let .expressionNode(expression):
				print("\t\(expression.name),")
			}
		}
		print("]")
	}
}

//
public enum ASTNode: Equatable {
	case statementNode(value: Statement)
	case expressionNode(value: Expression)
}
