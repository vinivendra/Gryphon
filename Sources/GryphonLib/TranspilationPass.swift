//
// Copyright 2018 Vinicius Jorge Vendramini
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

// gryphon output: Sources/GryphonLib/TranspilationPass.swiftAST
// gryphon output: Sources/GryphonLib/TranspilationPass.gryphonASTRaw
// gryphon output: Sources/GryphonLib/TranspilationPass.gryphonAST
// gryphon output: Bootstrap/TranspilationPass.kt

// gryphon insert: import kotlin.system.*

/// Implements the basic algorithm that visits nodes in the AST. Subclassing this class and
/// overriding the `replace` and `process` methods lets you alter the AST in specific places, which
/// is how most passes are implemented.
/// The `process` methods are just like the `replace` methods, except that they return the same type
/// that they receive. The different names serves only to make this file compile correctly in
/// Kotlin.
/// The default implementation of `replace` methods is to simply return the same node as they
/// received - after visiting all of its subnodes and replacing them if necessary. This means
/// running the base TranspilationPass class on an AST, without overriding any methods, will simply
/// return the same AST.
/// It also means that overriding methods may call their respective super methods if they want to
/// visit all subnodes (instead of manually re-implementing this visit). For example, when
/// overriding `replaceIfStatement`, instead of just returning a new if statement a user might call
/// `return super.replaceIfStatement(myNewIfStatement)` to make sure their overriding method also
/// runs on nested if statements.
/// The `process` methods are always called from their respective `replace` methods, meaning users
/// can override either one to replace a certain statement type.
public class TranspilationPass {
	// MARK: - Properties
	let ast: GryphonAST
	let context: TranspilationContext

	internal var parents: MutableList<ASTNode> = []
	internal var parent: ASTNode? {
		return parents.secondToLast
	}

	// MARK: - Interface
	init(ast: GryphonAST, context: TranspilationContext) {
		self.ast = ast
		self.context = context
	}

	func run() -> GryphonAST { // gryphon annotation: open
		let replacedStatements = replaceStatements(ast.statements)
		let replacedDeclarations = replaceStatements(ast.declarations)
		return GryphonAST(
			sourceFile: ast.sourceFile,
			declarations: replacedDeclarations,
			statements: replacedStatements,
			outputFileMap: ast.outputFileMap)
	}

	// MARK: - Helper functions
	static func isASwiftRawRepresentableType(_ typeName: String) -> Bool {
		return swiftRawRepresentableTypes.contains(typeName)
	}

	static func isASwiftProtocol(_ protocolName: String) -> Bool {
		return swiftProtocols.contains(protocolName)
	}

	static let swiftRawRepresentableTypes: MutableList<String> = [
		"String",
		"Int", "Int8", "Int16", "Int32", "Int64",
		"UInt", "UInt8", "UInt16", "UInt32", "UInt64",
		"Float", "Float32", "Float64", "Float80", "Double",
	]

	static let swiftProtocols: MutableList<String> = [
		"Equatable", "Codable", "Decodable", "Encodable", "CustomStringConvertible", "Hashable",
	]

	// MARK: - Replace Statements

	func replaceStatements( // gryphon annotation: open
		_ statements: MutableList<Statement>)
		-> MutableList<Statement>
	{
		return statements.flatMap { replaceStatement($0) }.toMutableList()
	}

	func replaceStatement( // gryphon annotation: open
		_ statement: Statement)
		-> MutableList<Statement>
	{
		parents.append(.statementNode(value: statement))
		defer { parents.removeLast() }

		if let commentStatement = statement as? CommentStatement {
			return replaceComment(commentStatement)
		}
		if let expressionStatement = statement as? ExpressionStatement {
			return replaceExpressionStatement(expressionStatement)
		}
		if let extensionDeclaration = statement as? ExtensionDeclaration {
			return replaceExtension(extensionDeclaration)
		}
		if let importDeclaration = statement as? ImportDeclaration {
			return replaceImportDeclaration(importDeclaration)
		}
		if let typealiasDeclaration = statement as? TypealiasDeclaration {
			return replaceTypealiasDeclaration(typealiasDeclaration)
		}
		if let classDeclaration = statement as? ClassDeclaration {
			return replaceClassDeclaration(classDeclaration)
		}
		if let companionObject = statement as? CompanionObject {
			return replaceCompanionObject(companionObject)
		}
		if let enumDeclaration = statement as? EnumDeclaration {
			return replaceEnumDeclaration(enumDeclaration)
		}
		if let protocolDeclaration = statement as? ProtocolDeclaration {
			return replaceProtocolDeclaration(protocolDeclaration)
		}
		if let structDeclaration = statement as? StructDeclaration {
			return replaceStructDeclaration(structDeclaration)
		}
		if let initializerDeclaration = statement as? InitializerDeclaration {
			return replaceInitializerDeclaration(initializerDeclaration)
		}
		if let functionDeclaration = statement as? FunctionDeclaration {
			return replaceFunctionDeclaration(functionDeclaration)
		}
		if let variableDeclaration = statement as? VariableDeclaration {
			return replaceVariableDeclaration(variableDeclaration)
		}
		if let doStatement = statement as? DoStatement {
			return replaceDoStatement(doStatement)
		}
		if let catchStatement = statement as? CatchStatement {
			return replaceCatchStatement(catchStatement)
		}
		if let forEachStatement = statement as? ForEachStatement {
			return replaceForEachStatement(forEachStatement)
		}
		if let whileStatement = statement as? WhileStatement {
			return replaceWhileStatement(whileStatement)
		}
		if let ifStatement = statement as? IfStatement {
			return replaceIfStatement(ifStatement)
		}
		if let switchStatement = statement as? SwitchStatement {
			return replaceSwitchStatement(switchStatement)
		}
		if let deferStatement = statement as? DeferStatement {
			return replaceDeferStatement(deferStatement)
		}
		if let throwStatement = statement as? ThrowStatement {
			return replaceThrowStatement(throwStatement)
		}
		if let returnStatement = statement as? ReturnStatement {
			return replaceReturnStatement(returnStatement)
		}
		if statement is BreakStatement {
			return [BreakStatement(range: statement.range)]
		}
		if statement is ContinueStatement {
			return [ContinueStatement(range: statement.range)]
		}
		if let assignmentStatement = statement as? AssignmentStatement {
			return replaceAssignmentStatement(assignmentStatement)
		}
		if statement is ErrorStatement {
			return [ErrorStatement(range: statement.range)]
		}

		fatalError("This should never be reached.")
	}

	func replaceComment(_ commentStatement: CommentStatement) // gryphon annotation: open
		-> MutableList<Statement>
	{
		return [commentStatement]
	}

	func replaceExpressionStatement( // gryphon annotation: open
		_ expressionStatement: ExpressionStatement)
		-> MutableList<Statement>
	{
		return [ExpressionStatement(
			range: expressionStatement.range,
			expression: replaceExpression(expressionStatement.expression)), ]
	}

	func replaceExtension( // gryphon annotation: open
		_ extensionDeclaration: ExtensionDeclaration)
		-> MutableList<Statement>
	{
		return [ExtensionDeclaration(
			range: extensionDeclaration.range,
			typeName: extensionDeclaration.typeName,
			members: replaceStatements(extensionDeclaration.members)), ]
	}

	func replaceImportDeclaration( // gryphon annotation: open
		_ importDeclaration: ImportDeclaration)
		-> MutableList<Statement>
	{
		return [importDeclaration]
	}

	func replaceTypealiasDeclaration( // gryphon annotation: open
		_ typealiasDeclaration: TypealiasDeclaration)
		-> MutableList<Statement>
	{
		return [typealiasDeclaration]
	}

	func replaceClassDeclaration( // gryphon annotation: open
		_ classDeclaration: ClassDeclaration)
		-> MutableList<Statement>
	{
		return [ClassDeclaration(
			range: classDeclaration.range,
			className: classDeclaration.className,
			access: classDeclaration.access,
			inherits: classDeclaration.inherits,
			members: replaceStatements(classDeclaration.members)), ]
	}

	func replaceCompanionObject( // gryphon annotation: open
		_ companionObject: CompanionObject)
		-> MutableList<Statement>
	{
		return [CompanionObject(
			range: companionObject.range,
			members: replaceStatements(companionObject.members)), ]
	}

	func replaceEnumDeclaration( // gryphon annotation: open
		_ enumDeclaration: EnumDeclaration)
		-> MutableList<Statement>
	{
		return [
			EnumDeclaration(
				range: enumDeclaration.range,
				access: enumDeclaration.access,
				enumName: enumDeclaration.enumName,
				inherits: enumDeclaration.inherits,
				elements: enumDeclaration.elements
					.flatMap { replaceEnumElementDeclaration($0) }
					.toMutableList(),
				members: replaceStatements(enumDeclaration.members),
				isImplicit: enumDeclaration.isImplicit), ]
	}

	func replaceEnumElementDeclaration( // gryphon annotation: open
		_ enumElement: EnumElement)
		-> MutableList<EnumElement>
	{
		return [enumElement]
	}

	func replaceProtocolDeclaration( // gryphon annotation: open
		_ protocolDeclaration: ProtocolDeclaration)
		-> MutableList<Statement>
	{
		return [ProtocolDeclaration(
			range: protocolDeclaration.range,
			protocolName: protocolDeclaration.protocolName,
			members: replaceStatements(protocolDeclaration.members)), ]
	}

	func replaceStructDeclaration( // gryphon annotation: open
		_ structDeclaration: StructDeclaration)
		-> MutableList<Statement>
	{
		return [StructDeclaration(
			range: structDeclaration.range,
			annotations: structDeclaration.annotations,
			structName: structDeclaration.structName,
			inherits: structDeclaration.inherits,
			members: replaceStatements(structDeclaration.members)), ]
	}

	func replaceInitializerDeclaration( // gryphon annotation: open
		_ initializerDeclaration: InitializerDeclaration)
		-> MutableList<Statement>
	{
		if let result = processInitializerDeclaration(initializerDeclaration) {
			return [result]
		}
		else {
			return []
		}
	}

	func processInitializerDeclaration( // gryphon annotation: open
		_ initializerDeclaration: InitializerDeclaration)
		-> InitializerDeclaration?
	{
		let replacedParameters = initializerDeclaration.parameters
			.map {
				FunctionParameter(
					label: $0.label,
					apiLabel: $0.apiLabel,
					typeName: $0.typeName,
					value: $0.value.map { replaceExpression($0) })
		}

		let initializerDeclaration = initializerDeclaration
		initializerDeclaration.parameters = replacedParameters.toMutableList()
		initializerDeclaration.statements =
			initializerDeclaration.statements.map { replaceStatements($0) }
		return initializerDeclaration
	}

	func replaceFunctionDeclaration( // gryphon annotation: open
		_ functionDeclaration: FunctionDeclaration)
		-> MutableList<Statement>
	{
		if let result = processFunctionDeclaration(functionDeclaration) {
			return [result]
		}
		else {
			return []
		}
	}

	func processFunctionDeclaration( // gryphon annotation: open
		_ functionDeclaration: FunctionDeclaration)
		-> FunctionDeclaration?
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
		functionDeclaration.parameters = replacedParameters.toMutableList()
		functionDeclaration.statements =
			functionDeclaration.statements.map { replaceStatements($0) }
		return functionDeclaration
	}

	func replaceVariableDeclaration( // gryphon annotation: open
		_ variableDeclaration: VariableDeclaration)
		-> MutableList<Statement>
	{
		return [processVariableDeclaration(variableDeclaration)]
	}

	func processVariableDeclaration( // gryphon annotation: open
		_ variableDeclaration: VariableDeclaration)
		-> VariableDeclaration
	{
		let variableDeclaration = variableDeclaration
		variableDeclaration.expression =
			variableDeclaration.expression.map { replaceExpression($0) }
		if let getter = variableDeclaration.getter {
			variableDeclaration.getter = processFunctionDeclaration(getter)
		}
		if let setter = variableDeclaration.setter {
			variableDeclaration.setter = processFunctionDeclaration(setter)
		}
		return variableDeclaration
	}

	func replaceDoStatement( // gryphon annotation: open
		_ doStatement: DoStatement)
		-> MutableList<Statement>
	{
		return [DoStatement(
			range: doStatement.range,
			statements: replaceStatements(doStatement.statements)), ]
	}

	func replaceCatchStatement( // gryphon annotation: open
		_ catchStatement: CatchStatement)
		-> MutableList<Statement>
	{
		return [CatchStatement(
			range: catchStatement.range,
			variableDeclaration: catchStatement.variableDeclaration
				.map { processVariableDeclaration($0) },
			statements: replaceStatements(catchStatement.statements)),
		]
	}

	func replaceForEachStatement( // gryphon annotation: open
		_ forEachStatement: ForEachStatement)
		-> MutableList<Statement>
	{
		return [ForEachStatement(
			range: forEachStatement.range,
			collection: replaceExpression(forEachStatement.collection),
			variable: replaceExpression(forEachStatement.variable),
			statements: replaceStatements(forEachStatement.statements)), ]
	}

	func replaceWhileStatement( // gryphon annotation: open
		_ whileStatement: WhileStatement)
		-> MutableList<Statement>
	{
		return [WhileStatement(
			range: whileStatement.range,
			expression: replaceExpression(whileStatement.expression),
			statements: replaceStatements(whileStatement.statements)), ]
	}

	func replaceIfStatement( // gryphon annotation: open
		_ ifStatement: IfStatement)
		-> MutableList<Statement>
	{
		return [processIfStatement(ifStatement)]
	}

	func processIfStatement( // gryphon annotation: open
		_ ifStatement: IfStatement)
		-> IfStatement
	{
		let ifStatement = ifStatement
		ifStatement.conditions = replaceIfConditions(ifStatement.conditions)
		ifStatement.declarations =
			ifStatement.declarations.map { processVariableDeclaration($0) }.toMutableList()
		ifStatement.statements = replaceStatements(ifStatement.statements)
		ifStatement.elseStatement = ifStatement.elseStatement.map { processIfStatement($0) }
		return ifStatement
	}

	func replaceIfConditions( // gryphon annotation: open
		_ conditions: MutableList<IfStatement.IfCondition>)
		-> MutableList<IfStatement.IfCondition>
	{
		return conditions.map { replaceIfCondition($0) }.toMutableList()
	}

	func replaceIfCondition( // gryphon annotation: open
		_ condition: IfStatement.IfCondition)
		-> IfStatement.IfCondition
	{
		switch condition {
		case let .condition(expression: expression):
			return .condition(expression: replaceExpression(expression))
		case let .declaration(variableDeclaration: variableDeclaration):
			return .declaration(
				variableDeclaration: processVariableDeclaration(variableDeclaration))
		}
	}

	func replaceSwitchStatement( // gryphon annotation: open
		_ switchStatement: SwitchStatement)
		-> MutableList<Statement>
	{
		let replacedConvertsToExpression: Statement?
		if let convertsToExpression = switchStatement.convertsToExpression {
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

		let replacedCases = switchStatement.cases.map
			{
				SwitchCase(
					expressions: $0.expressions.map { replaceExpression($0) }.toMutableList(),
					statements: replaceStatements($0.statements))
			}

		return [SwitchStatement(
			range: switchStatement.range,
			convertsToExpression: replacedConvertsToExpression,
			expression: replaceExpression(switchStatement.expression),
			cases: replacedCases.toMutableList()), ]
	}

	func replaceDeferStatement( // gryphon annotation: open
		_ deferStatement: DeferStatement)
		-> MutableList<Statement>
	{
		return [DeferStatement(
			range: deferStatement.range,
			statements: replaceStatements(deferStatement.statements)), ]
	}

	func replaceThrowStatement( // gryphon annotation: open
		_ throwStatement: ThrowStatement)
		-> MutableList<Statement>
	{
		return [ThrowStatement(
			range: throwStatement.range,
			expression: replaceExpression(throwStatement.expression)), ]
	}

	func replaceReturnStatement( // gryphon annotation: open
		_ returnStatement: ReturnStatement)
		-> MutableList<Statement>
	{
		return [ReturnStatement(
			range: returnStatement.range,
			expression: returnStatement.expression.map { replaceExpression($0) }), ]
	}

	func replaceAssignmentStatement( // gryphon annotation: open
		_ assignmentStatement: AssignmentStatement)
		-> MutableList<Statement>
	{
		return [AssignmentStatement(
			range: assignmentStatement.range,
			leftHand: replaceExpression(assignmentStatement.leftHand),
			rightHand: replaceExpression(assignmentStatement.rightHand)), ]
	}

	// MARK: - Replace Expressions
	func replaceExpression( // gryphon annotation: open
		_ expression: Expression)
		-> Expression
	{
		parents.append(.expressionNode(value: expression))
		defer { parents.removeLast() }

		if let expression = expression as? TemplateExpression {
			return replaceTemplateExpression(expression)
		}
		if let expression = expression as? LiteralCodeExpression {
			return replaceLiteralCodeExpression(expression)
		}
		if let expression = expression as? ParenthesesExpression {
			return replaceParenthesesExpression(expression)
		}
		if let expression = expression as? ForceValueExpression {
			return replaceForceValueExpression(expression)
		}
		if let expression = expression as? OptionalExpression {
			return replaceOptionalExpression(expression)
		}
		if let expression = expression as? DeclarationReferenceExpression {
			return replaceDeclarationReferenceExpression(expression)
		}
		if let expression = expression as? TypeExpression {
			return replaceTypeExpression(expression)
		}
		if let expression = expression as? SubscriptExpression {
			return replaceSubscriptExpression(expression)
		}
		if let expression = expression as? ArrayExpression {
			return replaceArrayExpression(expression)
		}
		if let expression = expression as? DictionaryExpression {
			return replaceDictionaryExpression(expression)
		}
		if let expression = expression as? ReturnExpression {
			return replaceReturnExpression(expression)
		}
		if let expression = expression as? DotExpression {
			return replaceDotExpression(expression)
		}
		if let expression = expression as? BinaryOperatorExpression {
			return replaceBinaryOperatorExpression(expression)
		}
		if let expression = expression as? PrefixUnaryExpression {
			return replacePrefixUnaryExpression(expression)
		}
		if let expression = expression as? PostfixUnaryExpression {
			return replacePostfixUnaryExpression(expression)
		}
		if let expression = expression as? IfExpression {
			return replaceIfExpression(expression)
		}
		if let expression = expression as? CallExpression {
			return replaceCallExpression(expression)
		}
		if let expression = expression as? ClosureExpression {
			return replaceClosureExpression(expression)
		}
		if let expression = expression as? LiteralIntExpression {
			return replaceLiteralIntExpression(expression)
		}
		if let expression = expression as? LiteralUIntExpression {
			return replaceLiteralUIntExpression(expression)
		}
		if let expression = expression as? LiteralDoubleExpression {
			return replaceLiteralDoubleExpression(expression)
		}
		if let expression = expression as? LiteralFloatExpression {
			return replaceLiteralFloatExpression(expression)
		}
		if let expression = expression as? LiteralBoolExpression {
			return replaceLiteralBoolExpression(expression)
		}
		if let expression = expression as? LiteralStringExpression {
			return replaceLiteralStringExpression(expression)
		}
		if let expression = expression as? LiteralCharacterExpression {
			return replaceLiteralCharacterExpression(expression)
		}
		if let expression = expression as? NilLiteralExpression {
			return replaceNilLiteralExpression(expression)
		}
		if let expression = expression as? InterpolatedStringLiteralExpression {
			return replaceInterpolatedStringLiteralExpression(expression)
		}
		if let expression = expression as? TupleExpression {
			return replaceTupleExpression(expression)
		}
		if let expression = expression as? TupleShuffleExpression {
			return replaceTupleShuffleExpression(expression)
		}
		if expression is ErrorExpression {
			return ErrorExpression(range: expression.range)
		}

		fatalError("This should never be reached.")
	}

	func replaceTemplateExpression( // gryphon annotation: open
		_ templateExpression: TemplateExpression)
		-> Expression
	{
		let newMatches = templateExpression.matches // gryphon ignore
			.mapValues { replaceExpression($0) }
		// gryphon insert: val newMatches = templateExpression.matches
		// gryphon insert:     .mapValues { replaceExpression(it.value) }.toMutableMap()

		return TemplateExpression(
			range: templateExpression.range,
			pattern: templateExpression.pattern,
			matches: newMatches.toMutableMap())
	}

	func replaceLiteralCodeExpression( // gryphon annotation: open
		_ literalCodeExpression: LiteralCodeExpression)
		-> Expression
	{
		return literalCodeExpression
	}

	func replaceParenthesesExpression( // gryphon annotation: open
		_ parenthesesExpression: ParenthesesExpression)
		-> Expression
	{
		return ParenthesesExpression(
			range: parenthesesExpression.range,
			expression: replaceExpression(parenthesesExpression.expression))
	}

	func replaceForceValueExpression( // gryphon annotation: open
		_ forceValueExpression: ForceValueExpression)
		-> Expression
	{
		return ForceValueExpression(
			range: forceValueExpression.range,
			expression: replaceExpression(forceValueExpression.expression))
	}

	func replaceOptionalExpression( // gryphon annotation: open
		_ optionalExpression: OptionalExpression)
		-> Expression
	{
		return OptionalExpression(
			range: optionalExpression.range,
			expression: replaceExpression(optionalExpression.expression))
	}

	func replaceDeclarationReferenceExpression( // gryphon annotation: open
		_ declarationReferenceExpression: DeclarationReferenceExpression)
		-> Expression
	{
		return processDeclarationReferenceExpression(declarationReferenceExpression)
	}

	func processDeclarationReferenceExpression( // gryphon annotation: open
		_ declarationReferenceExpression: DeclarationReferenceExpression)
		-> DeclarationReferenceExpression
	{
		return declarationReferenceExpression
	}

	func replaceTypeExpression( // gryphon annotation: open
		_ typeExpression: TypeExpression)
		-> Expression
	{
		return typeExpression
	}

	func replaceSubscriptExpression( // gryphon annotation: open
		_ subscriptExpression: SubscriptExpression)
		-> Expression
	{
		return SubscriptExpression(
			range: subscriptExpression.range,
			subscriptedExpression: replaceExpression(subscriptExpression.subscriptedExpression),
			indexExpression: replaceExpression(subscriptExpression.indexExpression),
			typeName: subscriptExpression.typeName)
	}

	func replaceArrayExpression( // gryphon annotation: open
		_ arrayExpression: ArrayExpression)
		-> Expression
	{
		return ArrayExpression(
			range: arrayExpression.range,
			elements: arrayExpression.elements.map { replaceExpression($0) }.toMutableList(),
			typeName: arrayExpression.typeName)
	}

	func replaceDictionaryExpression( // gryphon annotation: open
		_ dictionaryExpression: DictionaryExpression)
		-> Expression
	{
		return DictionaryExpression(
			range: dictionaryExpression.range,
			keys: dictionaryExpression.keys.map { replaceExpression($0) }.toMutableList(),
			values: dictionaryExpression.values.map { replaceExpression($0) }.toMutableList(),
			typeName: dictionaryExpression.typeName)
	}

	func replaceReturnExpression( // gryphon annotation: open
		_ returnStatement: ReturnExpression)
		-> Expression
	{
		return ReturnExpression(
			range: returnStatement.range,
			expression: returnStatement.expression.map { replaceExpression($0) })
	}

	func replaceDotExpression( // gryphon annotation: open
		_ dotExpression: DotExpression)
		-> Expression
	{
		return DotExpression(
			range: dotExpression.range,
			leftExpression: replaceExpression(dotExpression.leftExpression),
			rightExpression: replaceExpression(dotExpression.rightExpression))
	}

	func replaceBinaryOperatorExpression( // gryphon annotation: open
		_ binaryOperatorExpression: BinaryOperatorExpression) -> Expression
	{
		return BinaryOperatorExpression(
			range: binaryOperatorExpression.range,
			leftExpression: replaceExpression(binaryOperatorExpression.leftExpression),
			rightExpression: replaceExpression(binaryOperatorExpression.rightExpression),
			operatorSymbol: binaryOperatorExpression.operatorSymbol,
			typeName: binaryOperatorExpression.typeName)
	}

	func replacePrefixUnaryExpression( // gryphon annotation: open
		_ prefixUnaryExpression: PrefixUnaryExpression)
		-> Expression
	{
		return PrefixUnaryExpression(
			range: prefixUnaryExpression.range,
			subExpression: replaceExpression(prefixUnaryExpression.subExpression),
			operatorSymbol: prefixUnaryExpression.operatorSymbol,
			typeName: prefixUnaryExpression.typeName)
	}

	func replacePostfixUnaryExpression( // gryphon annotation: open
		_ postfixUnaryExpression: PostfixUnaryExpression)
		-> Expression
	{
		return PostfixUnaryExpression(
			range: postfixUnaryExpression.range,
			subExpression: replaceExpression(postfixUnaryExpression.subExpression),
			operatorSymbol: postfixUnaryExpression.operatorSymbol,
			typeName: postfixUnaryExpression.typeName)
	}

	func replaceIfExpression( // gryphon annotation: open
		_ ifExpression: IfExpression)
		-> Expression
	{
		return IfExpression(
			range: ifExpression.range,
			condition: replaceExpression(ifExpression.condition),
			trueExpression: replaceExpression(ifExpression.trueExpression),
			falseExpression: replaceExpression(ifExpression.falseExpression))
	}

	func replaceCallExpression( // gryphon annotation: open
		_ callExpression: CallExpression)
		-> Expression
	{
		return processCallExpression(callExpression)
	}

	func processCallExpression( // gryphon annotation: open
		_ callExpression: CallExpression)
		-> CallExpression
	{
		return CallExpression(
			range: callExpression.range,
			function: replaceExpression(callExpression.function),
			parameters: replaceExpression(callExpression.parameters),
			typeName: callExpression.typeName)
	}

	func replaceClosureExpression( // gryphon annotation: open
		_ closureExpression: ClosureExpression)
		-> Expression
	{
		return ClosureExpression(
			range: closureExpression.range,
			parameters: closureExpression.parameters,
			statements: replaceStatements(closureExpression.statements),
			typeName: closureExpression.typeName)
	}

	func replaceLiteralIntExpression( // gryphon annotation: open
		_ literalIntExpression: LiteralIntExpression)
		-> Expression
	{
		return literalIntExpression
	}

	func replaceLiteralUIntExpression( // gryphon annotation: open
		_ literalUIntExpression: LiteralUIntExpression)
		-> Expression {
		return literalUIntExpression
	}

	func replaceLiteralDoubleExpression( // gryphon annotation: open
		_ literalDoubleExpression: LiteralDoubleExpression)
		-> Expression
	{
		return literalDoubleExpression
	}

	func replaceLiteralFloatExpression( // gryphon annotation: open
		_ literalFloatExpression: LiteralFloatExpression)
		-> Expression
	{
		return literalFloatExpression
	}

	func replaceLiteralBoolExpression( // gryphon annotation: open
		_ literalBoolExpression: LiteralBoolExpression)
		-> Expression
	{
		return literalBoolExpression
	}

	func replaceLiteralStringExpression( // gryphon annotation: open
		_ literalStringExpression: LiteralStringExpression)
		-> Expression
	{
		return literalStringExpression
	}

	func replaceLiteralCharacterExpression( // gryphon annotation: open
		_ literalCharacterExpression: LiteralCharacterExpression)
		-> Expression
	{
		return literalCharacterExpression
	}

	func replaceNilLiteralExpression( // gryphon annotation: open
		_ nilLiteralExpression: NilLiteralExpression)
		-> Expression
	{
		return nilLiteralExpression
	}

	func replaceInterpolatedStringLiteralExpression( // gryphon annotation: open
		_ interpolatedStringLiteralExpression: InterpolatedStringLiteralExpression)
		-> Expression
	{
		return InterpolatedStringLiteralExpression(
			range: interpolatedStringLiteralExpression.range,
			expressions: interpolatedStringLiteralExpression.expressions
				.map { replaceExpression($0) }.toMutableList())
	}

	func replaceTupleExpression( // gryphon annotation: open
		_ tupleExpression: TupleExpression)
		-> Expression
	{
		return TupleExpression(
			range: tupleExpression.range,
			pairs: tupleExpression.pairs.map {
				LabeledExpression(label: $0.label, expression: replaceExpression($0.expression))
			}.toMutableList())
	}

	func replaceTupleShuffleExpression( // gryphon annotation: open
		_ tupleShuffleExpression: TupleShuffleExpression)
		-> Expression
	{
		return TupleShuffleExpression(
			range: tupleShuffleExpression.range,
			labels: tupleShuffleExpression.labels,
			indices: tupleShuffleExpression.indices,
			expressions: tupleShuffleExpression.expressions
				.map { replaceExpression($0) }
				.toMutableList())
	}
}

// MARK: - Transpilation passes

public class DescriptionAsToStringTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	override func replaceVariableDeclaration( // gryphon annotation: override
		_ variableDeclaration: VariableDeclaration)
		-> MutableList<Statement>
	{
		if variableDeclaration.identifier == "description",
			variableDeclaration.typeName == "String",
			let getter = variableDeclaration.getter
		{
			let annotations = (variableDeclaration.annotations ?? "")
				.split(withStringSeparator: " ")
			if !annotations.contains("override") {
				annotations.append("override")
			}
			let newAnnotations = annotations.joined(separator: " ")

			return [FunctionDeclaration(
				range: variableDeclaration.range,
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
				access: "public",
				annotations: newAnnotations), ]
		}

		return super.replaceVariableDeclaration(variableDeclaration)
	}
}

public class RemoveParenthesesTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	override func replaceSubscriptExpression( // gryphon annotation: override
		_ subscriptExpression: SubscriptExpression)
		-> Expression
	{
		if let parentheses = subscriptExpression.indexExpression as? ParenthesesExpression {
			return super.replaceSubscriptExpression(SubscriptExpression(
				range: subscriptExpression.range,
				subscriptedExpression: subscriptExpression.subscriptedExpression,
				indexExpression: parentheses.expression,
				typeName: subscriptExpression.typeName))
		}

		return super.replaceSubscriptExpression(subscriptExpression)
	}

	override func replaceParenthesesExpression( // gryphon annotation: override
		_ parenthesesExpression: ParenthesesExpression)
		-> Expression
	{
		if let parent = parent,
			case let .expressionNode(parentExpression) = parent
		{
			if parentExpression is TupleExpression ||
				parentExpression is InterpolatedStringLiteralExpression
			{
				return replaceExpression(parenthesesExpression.expression)
			}
		}

		return super.replaceParenthesesExpression(parenthesesExpression)
	}

	override func replaceIfExpression( // gryphon annotation: override
		_ ifExpression: IfExpression)
		-> Expression
	{
		let replacedCondition: Expression
		if let condition = ifExpression.condition as? ParenthesesExpression {
			replacedCondition = condition.expression
		}
		else {
			replacedCondition = ifExpression.condition
		}

		let replacedTrueExpression: Expression
		if let trueExpression = ifExpression.trueExpression as? ParenthesesExpression {
			replacedTrueExpression = trueExpression.expression
		}
		else {
			replacedTrueExpression = ifExpression.trueExpression
		}

		let replacedFalseExpression: Expression
		if let falseExpression = ifExpression.falseExpression as? ParenthesesExpression {
			replacedFalseExpression = falseExpression.expression
		}
		else {
			replacedFalseExpression = ifExpression.falseExpression
		}

		return IfExpression(
			range: ifExpression.range,
			condition: replacedCondition,
			trueExpression: replacedTrueExpression,
			falseExpression: replacedFalseExpression)
	}
}

/// Removes implicit declarations so that they don't show up on the translation
public class RemoveImplicitDeclarationsTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	override func replaceEnumDeclaration( // gryphon annotation: override
		_ enumDeclaration: EnumDeclaration)
		-> MutableList<Statement>
	{
		if enumDeclaration.isImplicit {
			return []
		}
		else {
			return super.replaceEnumDeclaration(enumDeclaration)
		}
	}

	override func replaceTypealiasDeclaration( // gryphon annotation: override
		_ typealiasDeclaration: TypealiasDeclaration)
		-> MutableList<Statement>
	{
		if typealiasDeclaration.isImplicit {
			return []
		}
		else {
			return super.replaceTypealiasDeclaration(typealiasDeclaration)
		}
	}

	override func replaceVariableDeclaration( // gryphon annotation: override
		_ variableDeclaration: VariableDeclaration)
		-> MutableList<Statement>
	{
		if variableDeclaration.isImplicit {
			return []
		}
		else {
			return super.replaceVariableDeclaration(variableDeclaration)
		}
	}

	override func processFunctionDeclaration( // gryphon annotation: override
		_ functionDeclaration: FunctionDeclaration)
		-> FunctionDeclaration?
	{
		if functionDeclaration.isImplicit {
			return nil
		}
		else {
			return super.processFunctionDeclaration(functionDeclaration)
		}
	}
}

/// Optional initializers can be translated as `invoke` operators to have similar syntax and
/// functionality.
public class OptionalInitsTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	private var isFailableInitializer: Bool = false

	override func replaceInitializerDeclaration( // gryphon annotation: override
		_ initializerDeclaration: InitializerDeclaration)
		-> MutableList<Statement>
	{
		if initializerDeclaration.isStatic == true,
			initializerDeclaration.extendsType == nil
		{
			if initializerDeclaration.returnType.hasSuffix("?") {
				isFailableInitializer = true
				let newStatements = replaceStatements(initializerDeclaration.statements ?? [])
				isFailableInitializer = false

				let result: MutableList<Statement> = [FunctionDeclaration(
					range: initializerDeclaration.range,
					prefix: "invoke",
					parameters: initializerDeclaration.parameters,
					returnType: initializerDeclaration.returnType,
					functionType: initializerDeclaration.functionType,
					genericTypes: initializerDeclaration.genericTypes,
					isImplicit: initializerDeclaration.isImplicit,
					isStatic: initializerDeclaration.isStatic,
					isMutating: initializerDeclaration.isMutating,
					isPure: initializerDeclaration.isPure,
					extendsType: initializerDeclaration.extendsType,
					statements: newStatements,
					access: initializerDeclaration.access,
					annotations: initializerDeclaration.annotations), ]

				return result
			}
		}

		return super.replaceInitializerDeclaration(initializerDeclaration)
	}

	override func replaceAssignmentStatement( // gryphon annotation: override
		_ assignmentStatement: AssignmentStatement)
		-> MutableList<Statement>
	{
		if isFailableInitializer,
			let expression = assignmentStatement.leftHand as? DeclarationReferenceExpression
		{
			if expression.identifier == "self" {
				return [ReturnStatement(
					range: assignmentStatement.range,
					expression: assignmentStatement.rightHand), ]
			}
		}

		return super.replaceAssignmentStatement(assignmentStatement)
	}
}

public class RemoveExtraReturnsInInitsTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	override func processInitializerDeclaration( // gryphon annotation: override
		_ initializerDeclaration: InitializerDeclaration)
		-> InitializerDeclaration?
	{
		if initializerDeclaration.isStatic == true,
			initializerDeclaration.extendsType == nil,
			let lastStatement = initializerDeclaration.statements?.last,
			lastStatement is ReturnStatement
		{
			// TODO: Try removing these assignments now that these are reference types
			let initializerDeclaration = initializerDeclaration
			initializerDeclaration.statements?.removeLast()
			return initializerDeclaration
		}

		return initializerDeclaration
	}
}

/// The static functions and variables in a class must all be placed inside a single companion
/// object.
public class StaticMembersTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	private func sendStaticMembersToCompanionObject(
		_ members: MutableList<Statement>,
		withRange range: SourceFileRange?)
		-> MutableList<Statement>
	{
		let staticMembers = members.filter { isStaticMember($0) }

		guard !staticMembers.isEmpty else {
			return members
		}

		let nonStaticMembers = members.filter { !isStaticMember($0) }

		let newMembers: MutableList<Statement> =
			[CompanionObject(range: range, members: staticMembers.toMutableList())]
		newMembers.append(contentsOf: nonStaticMembers)

		return newMembers
	}

	private func isStaticMember(_ member: Statement) -> Bool {
		if let functionDeclaration = member as? FunctionDeclaration {
			if functionDeclaration.isStatic == true,
				functionDeclaration.extendsType == nil,
				!(functionDeclaration is InitializerDeclaration)
			{
				return true
			}
		}

		if let variableDeclaration = member as? VariableDeclaration {
			if variableDeclaration.isStatic {
				return true
			}
		}

		return false
	}

	override func replaceClassDeclaration( // gryphon annotation: override
		_ classDeclaration: ClassDeclaration)
		-> MutableList<Statement>
	{
		let newMembers = sendStaticMembersToCompanionObject(
			classDeclaration.members,
			withRange: classDeclaration.range)
		return super.replaceClassDeclaration(ClassDeclaration(
			range: classDeclaration.range,
			className: classDeclaration.className,
			access: classDeclaration.access,
			inherits: classDeclaration.inherits,
			members: newMembers))
	}

	override func replaceStructDeclaration( // gryphon annotation: override
		_ structDeclaration: StructDeclaration)
		-> MutableList<Statement>
	{
		let newMembers = sendStaticMembersToCompanionObject(
			structDeclaration.members,
			withRange: structDeclaration.range)
		return super.replaceStructDeclaration(StructDeclaration(
			range: structDeclaration.range,
			annotations: structDeclaration.annotations,
			structName: structDeclaration.structName,
			inherits: structDeclaration.inherits,
			members: newMembers))
	}

	override func replaceEnumDeclaration( // gryphon annotation: override
		_ enumDeclaration: EnumDeclaration)
		-> MutableList<Statement>
	{
		let newMembers = sendStaticMembersToCompanionObject(
			enumDeclaration.members,
			withRange: enumDeclaration.range)
		return super.replaceEnumDeclaration(EnumDeclaration(
			range: enumDeclaration.range,
			access: enumDeclaration.access,
			enumName: enumDeclaration.enumName,
			inherits: enumDeclaration.inherits,
			elements: enumDeclaration.elements,
			members: newMembers,
			isImplicit: enumDeclaration.isImplicit))
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
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	var typeNamesStack: MutableList<String> = []

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

	override func replaceClassDeclaration( // gryphon annotation: override
		_ classDeclaration: ClassDeclaration)
		-> MutableList<Statement>
	{
		typeNamesStack.append(classDeclaration.className)
		let result = super.replaceClassDeclaration(classDeclaration)
		typeNamesStack.removeLast()
		return result
	}

	override func replaceStructDeclaration( // gryphon annotation: override
		_ structDeclaration: StructDeclaration)
		-> MutableList<Statement>
	{
		typeNamesStack.append(structDeclaration.structName)
		let result = super.replaceStructDeclaration(structDeclaration)
		typeNamesStack.removeLast()
		return result
	}

	override func processVariableDeclaration( // gryphon annotation: override
		_ variableDeclaration: VariableDeclaration)
		-> VariableDeclaration
	{
		let variableDeclaration = variableDeclaration
		variableDeclaration.typeName = removePrefixes(variableDeclaration.typeName)
		return super.processVariableDeclaration(variableDeclaration)
	}

	override func replaceTypeExpression( // gryphon annotation: override
		_ typeExpression: TypeExpression)
		-> Expression
	{
		return TypeExpression(
			range: typeExpression.range,
			typeName: removePrefixes(typeExpression.typeName))
	}
}

// TODO: test
/// Capitalizes references to enums (since enum cases in Kotlin are conventionally written in
/// capitalized forms)
public class CapitalizeEnumsTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	override func replaceDotExpression( // gryphon annotation: override
		_ dotExpression: DotExpression)
		-> Expression
	{
		if let enumTypeExpression = dotExpression.leftExpression as? TypeExpression,
			let enumExpression = dotExpression.rightExpression as? DeclarationReferenceExpression
		{
			let lastEnumType = String(enumTypeExpression.typeName.split(separator: ".").last!)

			if self.context.sealedClasses.contains(lastEnumType) {
				let enumExpression = enumExpression
				enumExpression.identifier =
					enumExpression.identifier.capitalizedAsCamelCase()
				return DotExpression(
					range: dotExpression.range,
					leftExpression: TypeExpression(
						range: dotExpression.leftExpression.range,
						typeName: enumTypeExpression.typeName),
					rightExpression: enumExpression)
			}
			else if self.context.enumClasses.contains(lastEnumType) {
				let enumExpression = enumExpression
				enumExpression.identifier = enumExpression.identifier.upperSnakeCase()
				return DotExpression(
					range: dotExpression.range,
					leftExpression: TypeExpression(
						range: dotExpression.leftExpression.range,
						typeName: enumTypeExpression.typeName),
					rightExpression: enumExpression)
			}
		}

		return super.replaceDotExpression(dotExpression)
	}

	override func replaceEnumDeclaration( // gryphon annotation: override
		_ enumDeclaration: EnumDeclaration)
		-> MutableList<Statement>
	{
		let isSealedClass =
			self.context.sealedClasses.contains(enumDeclaration.enumName)
		let isEnumClass = self.context.enumClasses.contains(enumDeclaration.enumName)

		let newElements: MutableList<EnumElement>
		if isSealedClass {
			newElements = enumDeclaration.elements.map { element in
				EnumElement(
					name: element.name.capitalizedAsCamelCase(),
					associatedValues: element.associatedValues,
					rawValue: element.rawValue,
					annotations: element.annotations)
			}.toMutableList()
		}
		else if isEnumClass {
			newElements = enumDeclaration.elements.map { element in
				EnumElement(
					name: element.name.upperSnakeCase(),
					associatedValues: element.associatedValues,
					rawValue: element.rawValue,
					annotations: element.annotations)
			}.toMutableList()
		}
		else {
			newElements = enumDeclaration.elements
		}

		return super.replaceEnumDeclaration(EnumDeclaration(
			range: enumDeclaration.range,
			access: enumDeclaration.access,
			enumName: enumDeclaration.enumName,
			inherits: enumDeclaration.inherits,
			elements: newElements,
			members: enumDeclaration.members,
			isImplicit: enumDeclaration.isImplicit))
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
///     ...
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
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	private var returnTypesStack: MutableList<String> = []

	private func removePrefixFromPossibleEnumReference(
		_ dotExpression: DotExpression)
		-> Expression
	{
		if let enumTypeExpression = dotExpression.leftExpression as? TypeExpression,
			let enumExpression = dotExpression.rightExpression as? DeclarationReferenceExpression
		{
			if enumExpression.typeName ==
					"(\(enumTypeExpression.typeName).Type) -> \(enumTypeExpression.typeName)",
				!self.context.sealedClasses.contains(enumTypeExpression.typeName)
			{
				return enumExpression
			}
		}

		return super.replaceDotExpression(dotExpression)
	}

	override func processFunctionDeclaration( // gryphon annotation: override
		_ functionDeclaration: FunctionDeclaration)
		-> FunctionDeclaration?
	{
		returnTypesStack.append(functionDeclaration.returnType)
		defer { returnTypesStack.removeLast() }
		return super.processFunctionDeclaration(functionDeclaration)
	}

	override func replaceReturnStatement( // gryphon annotation: override
		_ returnStatement: ReturnStatement)
		-> MutableList<Statement>
	{
		if let returnType = returnTypesStack.last,
			let expression = returnStatement.expression,
			let dotExpression = expression as? DotExpression
		{
			if let typeExpression = dotExpression.leftExpression as? TypeExpression {
				// It's ok to omit if the return type is an optional enum too
				var returnType = returnType
				if returnType.hasSuffix("?") {
					returnType = String(returnType.dropLast("?".count))
				}

				if typeExpression.typeName == returnType {
					let newExpression = removePrefixFromPossibleEnumReference(dotExpression)
					return [ReturnStatement(
						range: returnStatement.range,
						expression: newExpression), ]
				}
			}
		}

		return super.replaceReturnStatement(returnStatement)
	}
}

public class RenameOperatorsTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	override func replaceBinaryOperatorExpression( // gryphon annotation: override
		_ binaryOperatorExpression: BinaryOperatorExpression)
		-> Expression
	{
        let operatorTranslations: MutableMap = [
            "??": "?:",
            "<<": "shl",
            ">>": "shr",
            "&": "and",
            "|": "or",
            "^": "xor",
        ]
		if let operatorTranslation = operatorTranslations[binaryOperatorExpression.operatorSymbol] {
			return super.replaceBinaryOperatorExpression(BinaryOperatorExpression(
				range: binaryOperatorExpression.range,
				leftExpression: binaryOperatorExpression.leftExpression,
				rightExpression: binaryOperatorExpression.rightExpression,
				operatorSymbol: operatorTranslation,
				typeName: binaryOperatorExpression.typeName))
		}
		else {
			return super.replaceBinaryOperatorExpression(binaryOperatorExpression)
		}
	}
}

/// Calls to the superclass's initializers are made in the function block in Swift but have to be
/// in the function header in Kotlin. This should remove the calls from the initializer bodies and
/// send them to the appropriate property.
public class CallsToSuperclassInitializersTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	override func processInitializerDeclaration( // gryphon annotation: override
		_ initializerDeclaration: InitializerDeclaration)
		-> InitializerDeclaration?
	{
		var superCall: CallExpression?
		let newStatements: MutableList<Statement> = []

		if let statements = initializerDeclaration.statements {
			for statement in statements {
				if let maybeSuperCall = getSuperCall(from: statement) {
					if let superCall = superCall {
						// TODO: This probably can't happen, but super calls inside ifs and such
						// _can_ happen and should be warned about
						let message = "Kotlin only supports a single call to the superclass's " +
						"initializer"
						Compiler.handleWarning(
							message: message,
							sourceFile: ast.sourceFile,
							sourceFileRange: superCall.range)
						Compiler.handleWarning(
							message: message,
							sourceFile: ast.sourceFile,
							sourceFileRange: maybeSuperCall.range)

						return initializerDeclaration
					}
					else {
						superCall = maybeSuperCall
					}
				}
				else {
					// Keep all statements except super calls
					newStatements.append(statement)
				}
			}
		}

		if let superCall = superCall {
			return InitializerDeclaration(
				range: initializerDeclaration.range,
				parameters: initializerDeclaration.parameters,
				returnType: initializerDeclaration.returnType,
				functionType: initializerDeclaration.functionType,
				genericTypes: initializerDeclaration.genericTypes,
				isImplicit: initializerDeclaration.isImplicit,
				isStatic: initializerDeclaration.isStatic,
				isMutating: initializerDeclaration.isMutating,
				isPure: initializerDeclaration.isPure,
				extendsType: initializerDeclaration.extendsType,
				statements: newStatements,
				access: initializerDeclaration.access,
				annotations: initializerDeclaration.annotations,
				superCall: superCall)
		}
		else {
			return initializerDeclaration
		}
	}

	private func getSuperCall(from statement: Statement) -> CallExpression? {
		if let expressionStatement = statement as? ExpressionStatement {
			if let callExpression = expressionStatement.expression as? CallExpression {
				if let dotExpression = callExpression.function as? DotExpression {
					if let leftExpression = dotExpression.leftExpression as?
						DeclarationReferenceExpression,
						let rightExpression = dotExpression.rightExpression as?
						DeclarationReferenceExpression,
						leftExpression.identifier == "super",
						rightExpression.identifier == "init"
					{
						return CallExpression(
							range: callExpression.range,
							function: leftExpression,
							parameters: callExpression.parameters,
							typeName: callExpression.typeName)
					}
				}
			}
		}

		return nil
	}
}

/// If we're casting an expression that has an optional type -- for instance `foo as? Int` when
/// `foo` has an optional type like `Any?` -- then `foo` comes wrapped in an optional that needs to
/// be unwrapped.
public class OptionalsInConditionalCastsTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	override func replaceBinaryOperatorExpression( // gryphon annotation: override
		_ binaryOperatorExpression: BinaryOperatorExpression)
		-> Expression
	{
		guard binaryOperatorExpression.operatorSymbol == "as?",
			let optionalExpression = binaryOperatorExpression.leftExpression as? OptionalExpression
			else
		{
			return binaryOperatorExpression
		}

		return BinaryOperatorExpression(
			range: binaryOperatorExpression.range,
			leftExpression: optionalExpression.expression,
			rightExpression: binaryOperatorExpression.rightExpression,
			operatorSymbol: "as?",
			typeName: binaryOperatorExpression.typeName)
	}
}

/// This pass is responsible for determining what access modifiers are going to be printed in the
/// output code. This mainly includes two tasks: determining how to translate Swift's access
/// modifiers into Kotlin, and determining which modifiers should be printed and which should be
/// implicit.
///
/// Some Kotlin rules:
///   - top-level declarations are `public` by default
///   - top-level `private` declarations are visible to anything in that file
///   - inner declarations can't be more visible than their parents (i.e. a `public` property in an
///       `internal` class is treated as an `internal` property).
///   - inner declarations default to `public`, but because they can't be more visible than their
///       parents, in practice they default to the modifier of their parents.
public class AccessModifiersTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	/// A stack containing access modifiers from parent declarations. Modifiers in this stack should
	/// already be processed.
	var accessModifiersStack: MutableList<String?> = []

	override func replaceClassDeclaration( // gryphon annotation: override
		_ classDeclaration: ClassDeclaration)
		-> MutableList<Statement>
	{
		let newAccess = getAccessModifier(
			forModifier: classDeclaration.access,
			declaration: classDeclaration)

		accessModifiersStack.append(newAccess)
		let result = super.replaceClassDeclaration(ClassDeclaration(
			range: classDeclaration.range,
			className: classDeclaration.className,
			access: newAccess,
			inherits: classDeclaration.inherits,
			members: classDeclaration.members))
		accessModifiersStack.removeLast()
		return result
	}

	override func replaceEnumDeclaration( // gryphon annotation: override
		_ enumDeclaration: EnumDeclaration)
		-> MutableList<Statement>
	{
		let newAccess = getAccessModifier(
			forModifier: enumDeclaration.access,
			declaration: enumDeclaration)

		accessModifiersStack.append(newAccess)
		let result = super.replaceEnumDeclaration(EnumDeclaration(
			range: enumDeclaration.range,
			access: newAccess,
			enumName: enumDeclaration.enumName,
			inherits: enumDeclaration.inherits,
			elements: enumDeclaration.elements,
			members: enumDeclaration.members,
			isImplicit: enumDeclaration.isImplicit))
		accessModifiersStack.removeLast()
		return result
	}

	override func replaceVariableDeclaration( // gryphon annotation: override
		_ variableDeclaration: VariableDeclaration)
		-> MutableList<Statement>
	{
		// Only translate the access modifiers if it's a property.
		// If it's a local variable, remove access modifiers.
		var newAccess: String?
		if let parent = parent,
			case let .statementNode(value: parentDeclaration) = parent
		{
			if (parentDeclaration is ClassDeclaration) ||
				(parentDeclaration is EnumDeclaration)
			{
				newAccess = getAccessModifier(
					forModifier: variableDeclaration.access,
					declaration: variableDeclaration)
			}
		}

		accessModifiersStack.append(newAccess)
		let result = super.replaceVariableDeclaration(VariableDeclaration(
			range: variableDeclaration.range,
			identifier: variableDeclaration.identifier,
			typeName: variableDeclaration.typeName,
			expression: variableDeclaration.expression,
			getter: variableDeclaration.getter,
			setter: variableDeclaration.setter,
			access: newAccess,
			isLet: variableDeclaration.isLet,
			isImplicit: variableDeclaration.isImplicit,
			isStatic: variableDeclaration.isStatic,
			extendsType: variableDeclaration.extendsType,
			annotations: variableDeclaration.annotations))
		accessModifiersStack.removeLast()
		return result
	}

	override func replaceFunctionDeclaration( // gryphon annotation: override
		_ functionDeclaration: FunctionDeclaration)
		-> MutableList<Statement>
	{
		let newAccess = getAccessModifier(
			forModifier: functionDeclaration.access,
			declaration: functionDeclaration)

		accessModifiersStack.append(newAccess)
		let result = super.replaceFunctionDeclaration(FunctionDeclaration(
			range: functionDeclaration.range,
			prefix: functionDeclaration.prefix,
			parameters: functionDeclaration.parameters,
			returnType: functionDeclaration.returnType,
			functionType: functionDeclaration.functionType,
			genericTypes: functionDeclaration.genericTypes,
			isImplicit: functionDeclaration.isImplicit,
			isStatic: functionDeclaration.isStatic,
			isMutating: functionDeclaration.isMutating,
			isPure: functionDeclaration.isPure,
			extendsType: functionDeclaration.extendsType,
			statements: functionDeclaration.statements,
			access: newAccess,
			annotations: functionDeclaration.annotations))
		accessModifiersStack.removeLast()
		return result
	}

	// TODO: Add access to structs
	// TODO: Process extensions, companions, and protocols
//	override func replaceStructDeclaration(
//		_ structDeclaration: StructDeclaration)
//		-> MutableList<Statement>
//	{
//		let newAccess = getAccessModifier(
//			forModifier: structDeclaration.access,
//			declaration: structDeclaration)
//
//		accessModifiersStack.append(newAccess)
//		let result = super.replaceStructDeclaration(StructDeclaration(
//			range: structDeclaration.range,
//			annotations: structDeclaration.annotations,
//			structName: structDeclaration.structName,
//			inherits: structDeclaration.inherits,
//			members: structDeclaration).members)
//		accessModifiersStack.removeLast()
//		return result
//	}

	/// Receives an access modifier from a Swift declaration and returns the modifier that should be
	/// on the Kotlin translation.
	private func getAccessModifier(
		forModifier modifier: String?,
		declaration: Statement)
		-> String?
	{
		// Swift declarations default to internal
		let swiftModifier = modifier ?? "internal"

		if accessModifiersStack.isEmpty {
			// If it's a top-level declaration

			if swiftModifier == "public" || swiftModifier == "open" {
				// Top-level Kotlin declarations default to public
				return nil
			}
			else if swiftModifier == "private" || swiftModifier == "fileprivate" {
				// Top-level Kotlin declarations that are private behave like Swift's fileprivate.
				// Top-level private and fileprivate in Swift seem to be pretty much the same.
				return "private"
			}
			else {
				return "internal"
			}
		}
		else {
			// If it's an inner declaration

			// Note that the outer modifier (in the stack) has already been translated, but the
			// inner one hasn't
			let outerModifier = accessModifiersStack.compactMap { $0 }.last
			let innerModifier = swiftModifier

			// Inner declarations can't be accurately translated as fileprivate. Default to the next
			// most open modifier (internal) so the Kotlin code will compile, but raise a warning.
			if innerModifier == "fileprivate" {
				raiseFilePrivateWarning(forDeclaration: declaration)
				return getAccessModifier(forModifier: "internal", declaration: declaration)
			}

			if let outerModifier = outerModifier {
				if outerModifier == "private" {
					// If the outer modifier is private, we can only be private
					return nil
				}
				else if outerModifier == "internal" {
					// If the outer modifier is internal, we can only explicitly be private,
					// otherwise we default to internal
					if innerModifier == "private" {
						return "private"
					}

					return nil
				}
			}
			else {
				// If the outer defaults to public, we can only explicitly be internal or private
				if innerModifier == "internal" {
					return "internal"
				}
				else if innerModifier == "private" {
					return "private"
				}

				return nil
			}
		}

		raiseAlgorithmErrorWarning(forDeclaration: declaration)
		return nil
	}

	/// If there's a filePrivate declaration inside a more open declaration, it can be seen by other
	/// declarations in the same file for Swift, but there's no similar behavior in Kotlin. Default
	/// to internal (the next most open modifier) so that the Kotlin code compiles, but raise a
	/// warning.
	private func raiseFilePrivateWarning(forDeclaration declaration: Statement) {
		let message = "Kotlin does not support fileprivate declarations. " +
			"Defaulting to \"internal\"."
		Compiler.handleWarning(
			message: message,
			sourceFile: ast.sourceFile,
			sourceFileRange: declaration.range)
	}

	private func raiseAlgorithmErrorWarning(forDeclaration declaration: Statement) {
		let message = "Failed to calculate the correct access modifier. Defaulting to \"public\"."
		Compiler.handleWarning(
			message: message,
			sourceFile: ast.sourceFile,
			sourceFileRange: declaration.range)
	}
}

public class SelfToThisTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	override func replaceDotExpression( // gryphon annotation: override
		_ dotExpression: DotExpression)
		-> Expression
	{
		if let declarationReferenceExpression =
			dotExpression.leftExpression as? DeclarationReferenceExpression
		{
			if declarationReferenceExpression.identifier == "self",
				declarationReferenceExpression.isImplicit
			{
				return replaceExpression(dotExpression.rightExpression)
			}
		}

		return super.replaceDotExpression(dotExpression)
	}

	override func processDeclarationReferenceExpression( // gryphon annotation: override
		_ expression: DeclarationReferenceExpression)
		-> DeclarationReferenceExpression
	{
		if expression.identifier == "self" {
			let expression = expression
			expression.identifier = "this"
			return expression
		}
		return super.processDeclarationReferenceExpression(expression)
	}
}

/// Declarations can't conform to Swift-only protocols like Codable and Equatable, and enums can't
/// inherit from types Strings and Ints.
public class CleanInheritancesTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	override func replaceEnumDeclaration( // gryphon annotation: override
		_ enumDeclaration: EnumDeclaration)
		-> MutableList<Statement>
	{
		return super.replaceEnumDeclaration(EnumDeclaration(
			range: enumDeclaration.range,
			access: enumDeclaration.access,
			enumName: enumDeclaration.enumName,
			inherits: enumDeclaration.inherits.filter {
					!TranspilationPass.isASwiftProtocol($0) &&
						!TranspilationPass.isASwiftRawRepresentableType($0)
				},
			elements: enumDeclaration.elements,
			members: enumDeclaration.members,
			isImplicit: enumDeclaration.isImplicit))
	}

	override func replaceStructDeclaration( // gryphon annotation: override
		_ structDeclaration: StructDeclaration)
		-> MutableList<Statement>
	{
		return super.replaceStructDeclaration(StructDeclaration(
			range: structDeclaration.range,
			annotations: structDeclaration.annotations,
			structName: structDeclaration.structName,
			inherits: structDeclaration.inherits.filter { !TranspilationPass.isASwiftProtocol($0) },
			members: structDeclaration.members))
	}

	override func replaceClassDeclaration( // gryphon annotation: override
		_ classDeclaration: ClassDeclaration)
		-> MutableList<Statement>
	{
		return super.replaceClassDeclaration(ClassDeclaration(
			range: classDeclaration.range,
			className: classDeclaration.className,
			access: classDeclaration.access,
			inherits: classDeclaration.inherits.filter { !TranspilationPass.isASwiftProtocol($0) },
			members: classDeclaration.members))
	}
}

/// The "anonymous parameter" `$0` has to be replaced by `it`
public class AnonymousParametersTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	override func processDeclarationReferenceExpression( // gryphon annotation: override
		_ expression: DeclarationReferenceExpression)
		-> DeclarationReferenceExpression
	{
		if expression.identifier == "$0" {
			let expression = expression
			expression.identifier = "it"
			return expression
		}
		else {
			return super.processDeclarationReferenceExpression(expression)
		}
	}

	override func replaceClosureExpression( // gryphon annotation: override
		_ closureExpression: ClosureExpression)
		-> Expression
	{
		if closureExpression.parameters.count == 1,
			closureExpression.parameters[0].label == "$0"
		{
			return super.replaceClosureExpression(ClosureExpression(
				range: closureExpression.range,
				parameters: [],
				statements: closureExpression.statements,
				typeName: closureExpression.typeName))
		}
		else {
			return super.replaceClosureExpression(closureExpression)
		}
	}
}

///
/// Gryphon's collections need explicit initializers to account for the fact that they can't be
/// implicitly cast to covariant types. For instance:
///
/// ````
/// let myIntArray: MutableList = [1, 2, 3]
/// let myAnyArray = myIntArray as MutableList<Any> // error
/// let myAnyArray = MutableList<Any>(myIntArray) // OK
/// ````
///
/// This transformation can't be done with the current template mode because there's no way to get
/// the type for the cast. However, since this seems to be a specific case that only shows up in the
/// stdlib at the moment, this pass should serve as a workaround.
///
/// The conversion is done by calling `array.toMutableList<Element>()`.
/// This allows translations to cover a few (not fully understood) corner cases where the array
/// isn't a `MutableList` (it happened once with an `EmptyList`), meaning a normal cast would fail.
///
public class CovarianceInitsAsCallsTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	override func replaceCallExpression( // gryphon annotation: override
		_ callExpression: CallExpression)
		-> Expression
	{
		// Deal with cases where an initializer is used directly (i.e. `MutableList<Int>(list)`)
		if let typeExpression = callExpression.function as? TypeExpression,
			let tupleExpression = callExpression.parameters as? TupleExpression
		{
			// TODO: Fix references to toMutableList in the stdlib templates (i.e. include toList)
			let isMutableList = typeExpression.typeName.hasPrefix("MutableList<")
			let isList = typeExpression.typeName.hasPrefix("List<")
			let isMutableMap = typeExpression.typeName.hasPrefix("MutableMap<")
			let isMap = typeExpression.typeName.hasPrefix("Map<")

			let functionName: String
			let genericElementsString: String
			if isMutableList {
				functionName = "toMutableList"
				genericElementsString =
					String(typeExpression.typeName.dropFirst("MutableList<".count).dropLast())
			}
			else if isList {
				functionName = "toList"
				genericElementsString =
					String(typeExpression.typeName.dropFirst("List<".count).dropLast())
			}
			else if isMutableMap {
				functionName = "toMutableMap"
				genericElementsString =
					String(typeExpression.typeName.dropFirst("MutableMap<".count).dropLast())
			}
			else if isMap {
				functionName = "toMap"
				genericElementsString =
					String(typeExpression.typeName.dropFirst("Map<".count).dropLast())
			}
			else {
				return super.replaceCallExpression(callExpression)
			}

			if tupleExpression.pairs.count == 1,
				let onlyPair = tupleExpression.pairs.first
			{
				let genericElements =
					Utilities.splitTypeList(genericElementsString, separators: [","])
				let mappedGenericElements = genericElements.map {
						Utilities.getTypeMapping(for: $0) ?? $0
					}
				let mappedGenericString = mappedGenericElements.joined(separator: ", ")

				// TODO: If the generic type is the same, we might be able to optimize here. Try
				// this once the type system has been refactored
				return DotExpression(
					range: callExpression.range,
					leftExpression: replaceExpression(onlyPair.expression),
					rightExpression: CallExpression(
						range: callExpression.range,
						function: DeclarationReferenceExpression(
							range: callExpression.range,
							identifier: "\(functionName)<\(mappedGenericString)>",
							typeName: typeExpression.typeName,
							isStandardLibrary: false,
							isImplicit: false),
						parameters: TupleExpression(
							range: callExpression.range,
							pairs: []),
						typeName: typeExpression.typeName))
			}
		}

		// Deal with cases where the casting method is called (i.e. `list.as(List<Int>.self)`)
		if let dotExpression = callExpression.function as? DotExpression {
			if let leftType = dotExpression.leftExpression.swiftType,
				(leftType.hasPrefix("MutableList") ||
					leftType.hasPrefix("List") ||
					leftType.hasPrefix("MutableMap") ||
					leftType.hasPrefix("Map")),
				let declarationReferenceExpression =
					dotExpression.rightExpression as? DeclarationReferenceExpression,
				let tupleExpression = callExpression.parameters as? TupleExpression
			{
				if declarationReferenceExpression.identifier == "as",
					tupleExpression.pairs.count == 1,
					let onlyPair = tupleExpression.pairs.first
				{
					if let typeExpression = onlyPair.expression as? TypeExpression {
						return BinaryOperatorExpression(
							range: callExpression.range,
							leftExpression: dotExpression.leftExpression,
							rightExpression: TypeExpression(
								range: callExpression.range,
								typeName: typeExpression.typeName),
							operatorSymbol: "as?",
							typeName: typeExpression.typeName + "?")
					}
				}
			}
		}

		return super.replaceCallExpression(callExpression)
	}
}

/// Gryphon's custom data structures use different initializers that need to be turned into the
/// corresponding Kotlin function calls (i.e. `MutableList<Int>()` to `mutableListOf<Int>()`).
public class DataStructureInitializersTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	override func replaceCallExpression( // gryphon annotation: override
		_ callExpression: CallExpression)
		-> Expression
	{
		let tupleExpression = callExpression.parameters as? TupleExpression
		let tupleShuffleExpression = callExpression.parameters as? TupleShuffleExpression

		if let typeExpression = callExpression.function as? TypeExpression {

			// Make sure there are no parameters
			// TODO: This could be simpler and safer if tupleExpression and tupleShuffleExpression
			// shared a common "Tuple" superclass
			if let tupleExpression = tupleExpression {
				guard tupleExpression.pairs.isEmpty else {
					return super.replaceCallExpression(callExpression)
				}
			}
			else if let tupleShuffleExpression = tupleShuffleExpression {
				guard tupleShuffleExpression.expressions.isEmpty else {
					return super.replaceCallExpression(callExpression)
				}
			}

			// Get the function's name and the generic elements
			let typeName = typeExpression.typeName

			let functionName: String
			let genericElements: String
			if typeName.hasPrefix("MutableList<") {
				functionName = "mutableListOf"
				genericElements = String(typeName.dropFirst("MutableList<".count).dropLast())
			}
			else if typeName.hasPrefix("List<") {
				functionName = "listOf"
				genericElements = String(typeName.dropFirst("List<".count).dropLast())
			}
			else if typeName.hasPrefix("MutableMap<") {
				functionName = "mutableMapOf"
				genericElements = String(typeName.dropFirst("MutableMap<".count).dropLast())
			}
			else if typeName.hasPrefix("Map<") {
				functionName = "mapOf"
				genericElements = String(typeName.dropFirst("Map<".count).dropLast())
			}
			else {
				return super.replaceCallExpression(callExpression)
			}

			let parameters: Expression
			if let tupleExpression = tupleExpression {
				parameters = tupleExpression
			}
			else {
				parameters = tupleShuffleExpression!
			}

			return CallExpression(
				range: callExpression.range,
				function: DeclarationReferenceExpression(
					range: callExpression.range,
					identifier: "\(functionName)<\(genericElements)>",
					typeName: typeName,
					isStandardLibrary: false,
					isImplicit: false),
				parameters: parameters,
				typeName: typeName)
		}

		return super.replaceCallExpression(callExpression)
	}
}

/// Closures in kotlin can't have normal "return" statements. Instead, they must have return@f
/// statements (not yet implemented) or just standalone expressions (easier to implement but more
/// error-prone). This pass turns return statements in closures into standalone expressions
public class ReturnsInLambdasTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	var isInClosure = false

	override func replaceClosureExpression( // gryphon annotation: override
		_ closureExpression: ClosureExpression)
		-> Expression
	{
		isInClosure = true
		defer { isInClosure = false }
		return super.replaceClosureExpression(closureExpression)
	}

	override func replaceReturnStatement( // gryphon annotation: override
		_ returnStatement: ReturnStatement)
		-> MutableList<Statement>
	{
		if isInClosure, let expression = returnStatement.expression {
			return [ExpressionStatement(
				range: returnStatement.range,
				expression: expression), ]
		}
		else {
			return super.replaceReturnStatement(returnStatement)
		}
	}
}

/// Tuples with two elements can be translated to Kotlin automatically as `Pair`s. This doesn't
/// apply to tuples in call expressions (where they just represent the call's parameters) or for
/// statements iterating over `zip`s (i.e. the `(a, b)` in `for (a, b) in zip(c, d) { ... }`).
public class TuplesToPairsTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	override func replaceTupleExpression( // gryphon annotation: override
		_ tupleExpression: TupleExpression)
		-> Expression
	{
		// Ensure it's a pair
		guard tupleExpression.pairs.count == 2 else {
			return tupleExpression
		}

		// Ignore tuples in call expressions and for statements
		if let parent = parent {
			if case let .expressionNode(value: parentExpression) = parent {
				guard !(parentExpression is CallExpression) else {
					return tupleExpression
				}
			}
			else if case let .statementNode(value: parentStatement) = parent {
				guard !(parentStatement is ForEachStatement) else {
					return tupleExpression
				}
			}
		}

		// Try to find out the types of the expressions so we can form the correct result type
		let maybeTypes = tupleExpression.pairs.map { $0.expression.swiftType }
		guard let types = maybeTypes.as(MutableList<String>.self) else {
			return tupleExpression
		}
		let pairType = "Pair<\(types.joined(separator: ", "))>"

		return CallExpression(
			range: tupleExpression.range,
			function: TypeExpression(
				range: tupleExpression.range,
				typeName: pairType),
			parameters: TupleExpression(
				range: tupleExpression.range,
				pairs: [
					LabeledExpression(
						label: nil,
						expression: tupleExpression.pairs[0].expression),
					LabeledExpression(
						label: nil,
						expression: tupleExpression.pairs[1].expression),
			]),
			typeName: pairType)
	}
}

/// When tuples are translated as pairs, their members need to be translated as the pair's `first`
/// and `second` members.
public class TupleMembersTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	override func replaceDotExpression( // gryphon annotation: override
		_ dotExpression: DotExpression)
		-> Expression
	{
		// Supported tuple types here will be a string like "(foo: Int, bar: Int)"

		// If the left expression is of a tuple type and the right expression refers to its member
		guard let swiftType = dotExpression.leftExpression.swiftType,
			Utilities.isInEnvelopingParentheses(swiftType),
			let memberExpression = dotExpression.rightExpression as? DeclarationReferenceExpression
			else
		{
			return dotExpression
		}

		let innerString = String(swiftType.dropFirst().dropLast())
		let tupleComponents = Utilities.splitTypeList(innerString, separators: [","])

		// If the tuple will be translated as a pair and the right expression refers to one of the
		// tuple's components
		guard let tupleMemberIndex = tupleComponents.firstIndex(where: {
					$0.split(withStringSeparator: ":").first == memberExpression.identifier
				}),
			tupleComponents.count == 2
			else
		{
			return dotExpression
		}

		// One exception to this rule: key-value tuples (assumed to be from dictionaries)
		guard !(tupleComponents[0].hasPrefix("key:") && tupleComponents[1].hasPrefix("value:"))
			else
		{
			return dotExpression
		}

		let newIdentifier = (tupleMemberIndex == 0) ? "first" : "second"

		return DotExpression(
			range: dotExpression.range,
			leftExpression: dotExpression.leftExpression,
			rightExpression: DeclarationReferenceExpression(
				range: memberExpression.range,
				identifier: newIdentifier,
				typeName: memberExpression.typeName,
				isStandardLibrary: memberExpression.isStandardLibrary,
				isImplicit: memberExpression.isImplicit))
	}
}

/// Kotlin doesn't support autoclosures, but we can turn them into normal closures so they work
/// correctly.
public class AutoclosuresTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	override func replaceCallExpression( // gryphon annotation: override
		_ callExpression: CallExpression)
		-> Expression
	{
		guard let type = callExpression.function.swiftType,
			type.contains("@autoclosure") else
		{
			return callExpression
		}

		let parametersString = Utilities.splitTypeList(type, separators: [" -> "]).secondToLast!
		let parametersWithoutParentheses = String(parametersString.dropFirst().dropLast())
		let parameterTypes = Utilities.splitTypeList(parametersWithoutParentheses)

		// TODO: Add support for tupe shuffle expressions
		if let tupleExpression = callExpression.parameters as? TupleExpression {
			for index in tupleExpression.pairs.indices {
				let pair = tupleExpression.pairs[index]
				let expression = pair.expression
				let parameterType = parameterTypes[index]

				if parameterType.hasPrefix("@autoclosure") {
					let newExpression = ClosureExpression(
						range: expression.range,
						parameters: [],
						statements: [ExpressionStatement(
							range: expression.range,
							expression: expression), ],
						typeName: parameterType)

					tupleExpression.pairs[index] = LabeledExpression(
						label: pair.label,
						expression: newExpression)
				}
			}
		}

		return callExpression

	}
}

/// Optional subscripts in kotlin have to be refactored as function calls:
///
/// ````
/// let array: [Int]? = [1, 2, 3]
/// array?[0] // Becomes `array?.get(0)` in Kotlin
/// ````
public class RefactorOptionalsInSubscriptsTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	override func replaceSubscriptExpression( // gryphon annotation: override
		_ subscriptExpression: SubscriptExpression)
		-> Expression
	{
		if subscriptExpression.subscriptedExpression is OptionalExpression {
			let indexExpressionType = subscriptExpression.indexExpression.swiftType ?? "<<Error>>"
			return replaceDotExpression(DotExpression(
				range: subscriptExpression.range,
				leftExpression: subscriptExpression.subscriptedExpression,
				rightExpression: CallExpression(
					range: subscriptExpression.subscriptedExpression.range,
					function: DeclarationReferenceExpression(
						range: subscriptExpression.subscriptedExpression.range,
						identifier: "get",
						typeName: "(\(indexExpressionType)) -> \(subscriptExpression.typeName)",
						isStandardLibrary: false,
						isImplicit: false),
					parameters: TupleExpression(
						range: subscriptExpression.indexExpression.range,
						pairs: [LabeledExpression(
							label: nil,
							expression: subscriptExpression.indexExpression), ]),
					typeName: subscriptExpression.typeName)))
		}
		else {
			return super.replaceSubscriptExpression(subscriptExpression)
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
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	override func replaceDotExpression( // gryphon annotation: override
		_ dotExpression: DotExpression)
		-> Expression
	{
		if !(dotExpression.rightExpression is OptionalExpression),
			let leftDotExpression = dotExpression.leftExpression as? DotExpression
		{
			if dotExpressionChainHasOptionals(leftDotExpression.leftExpression) {
				return DotExpression(
					range: dotExpression.range,
					leftExpression: addOptionalsToDotExpressionChain(leftDotExpression),
					rightExpression: dotExpression.rightExpression)
			}
		}

		return super.replaceDotExpression(dotExpression)
	}

	func addOptionalsToDotExpressionChain(
		_ dotExpression: DotExpression)
		-> Expression
	{
		if !(dotExpression.rightExpression is OptionalExpression),
			dotExpressionChainHasOptionals(dotExpression.leftExpression)
		{

			let processedLeftExpression: Expression
			if let leftDotExpression = dotExpression.leftExpression as? DotExpression {
				processedLeftExpression = addOptionalsToDotExpressionChain(leftDotExpression)
			}
			else {
				processedLeftExpression = dotExpression.leftExpression
			}

			return addOptionalsToDotExpressionChain(DotExpression(
				range: dotExpression.range,
				leftExpression: processedLeftExpression,
				rightExpression: OptionalExpression(
					range: dotExpression.rightExpression.range,
					expression: dotExpression.rightExpression)))
		}

		return super.replaceDotExpression(dotExpression)
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
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	/// Detect switches whose bodies all end in the same returns or assignments
	override func replaceSwitchStatement( // gryphon annotation: override
		_ switchStatement: SwitchStatement)
		-> MutableList<Statement>
	{
		var hasAllReturnCases = true
		var hasAllAssignmentCases = true
		var assignmentExpression: Expression?

		for statements in switchStatement.cases.map({ $0.statements }) {
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
			let newCases: MutableList<SwitchCase> = []
			for switchCase in switchStatement.cases {
				// Swift switches must have at least one statement
				let lastStatement = switchCase.statements.last!
				if let returnStatement = lastStatement as? ReturnStatement {
					if let returnExpression = returnStatement.expression {
						let newStatements = MutableList<Statement>(
							switchCase.statements.dropLast())
						newStatements.append(ExpressionStatement(
							range: returnExpression.range,
							expression: returnExpression))
						newCases.append(SwitchCase(
							expressions: switchCase.expressions,
							statements: newStatements))
					}
				}
			}
			let conversionExpression =
				ReturnStatement(
					range: switchStatement.range,
					expression: NilLiteralExpression(range: switchStatement.range))
			return [SwitchStatement(
				range: switchStatement.range,
				convertsToExpression: conversionExpression,
				expression: switchStatement.expression,
				cases: newCases), ]
		}
		else if hasAllAssignmentCases, let assignmentExpression = assignmentExpression {
			let newCases: MutableList<SwitchCase> = []
			for switchCase in switchStatement.cases {
				// Swift switches must have at least one statement
				let lastStatement = switchCase.statements.last!
				if let assignmentStatement = lastStatement as? AssignmentStatement {
					let newStatements = MutableList<Statement>(switchCase.statements.dropLast())
					newStatements.append(ExpressionStatement(
						range: assignmentStatement.rightHand.range,
						expression: assignmentStatement.rightHand))
					newCases.append(SwitchCase(
						expressions: switchCase.expressions,
						statements: newStatements))
				}
			}
			let conversionExpression = AssignmentStatement(
				range: switchStatement.range,
				leftHand: assignmentExpression,
				rightHand: NilLiteralExpression(range: switchStatement.range))
			return [SwitchStatement(
				range: switchStatement.range,
				convertsToExpression: conversionExpression,
				expression: switchStatement.expression,
				cases: newCases), ]
		}
		else {
			return super.replaceSwitchStatement(switchStatement)
		}
	}

	/// Replace variable declarations followed by switch statements assignments
	override func replaceStatements( // gryphon annotation: override
		_ oldStatements: MutableList<Statement>)
		-> MutableList<Statement>
	{
		let statements = super.replaceStatements(oldStatements)

		let result: MutableList<Statement> = []

		var i = 0
		while i < (statements.count - 1) {
			let currentStatement = statements[i]
			let nextStatement = statements[i + 1]
			if let variableDeclaration = currentStatement as? VariableDeclaration,
				let switchStatement = nextStatement as? SwitchStatement
			{
				if variableDeclaration.isImplicit == false,
					variableDeclaration.extendsType == nil,
					let switchConversion = switchStatement.convertsToExpression,
					let assignmentStatement = switchConversion as? AssignmentStatement
				{
					if let assignmentExpression =
						assignmentStatement.leftHand as? DeclarationReferenceExpression
					{

						if assignmentExpression.identifier == variableDeclaration.identifier,
							!assignmentExpression.isStandardLibrary,
							!assignmentExpression.isImplicit
						{
							variableDeclaration.expression = NilLiteralExpression(
								range: switchStatement.range)
							variableDeclaration.getter = nil
							variableDeclaration.setter = nil
							variableDeclaration.isStatic = false
							let newConversionExpression = variableDeclaration
							result.append(SwitchStatement(
								range: switchStatement.range,
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
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	override func replaceSwitchStatement( // gryphon annotation: override
		_ switchStatement: SwitchStatement)
		-> MutableList<Statement>
	{
		let newCases = switchStatement.cases.compactMap { removeBreaksInSwitchCase($0) }

		return super.replaceSwitchStatement(SwitchStatement(
			range: switchStatement.range,
			convertsToExpression: switchStatement.convertsToExpression,
			expression: switchStatement.expression,
			cases: newCases.toMutableList()))
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
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	override func replaceSwitchStatement( // gryphon annotation: override
		_ switchStatement: SwitchStatement)
		-> MutableList<Statement>
	{
		if let declarationReferenceExpression =
			switchStatement.expression as? DeclarationReferenceExpression
		{
			if self.context.sealedClasses.contains(
				declarationReferenceExpression.typeName)
			{
				let newCases = switchStatement.cases.map {
					replaceIsOperatorsInSwitchCase($0, usingExpression: switchStatement.expression)
				}

				return super.replaceSwitchStatement(SwitchStatement(
					range: switchStatement.range,
					convertsToExpression: switchStatement.convertsToExpression,
					expression: switchStatement.expression,
					cases: newCases.toMutableList()))
			}
		}

		return super.replaceSwitchStatement(switchStatement)
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
			expressions: newExpressions.toMutableList(),
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
					range: dotExpression.range,
					leftExpression: expression,
					rightExpression: TypeExpression(
						range: typeExpression.range,
						typeName: "\(typeExpression.typeName)." +
							"\(declarationReferenceExpression.identifier)"),
					operatorSymbol: "is",
					typeName: "Bool")
			}
		}

		return caseExpression
	}
}

public class RemoveExtensionsTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	var extendingType: String?

	override func replaceExtension( // gryphon annotation: override
		_ extensionDeclaration: ExtensionDeclaration)
		-> MutableList<Statement>
	{
		extendingType = extensionDeclaration.typeName
		let members = replaceStatements(extensionDeclaration.members)
		extendingType = nil
		return members
	}

	override func replaceStatement( // gryphon annotation: override
		_ statement: Statement)
		-> MutableList<Statement>
	{
		if let extensionDeclaration = statement as? ExtensionDeclaration {
			return replaceExtension(extensionDeclaration)
		}
		if let functionDeclaration = statement as? FunctionDeclaration {
			return replaceFunctionDeclaration(functionDeclaration)
		}
		if let variableDeclaration = statement as? VariableDeclaration {
			return replaceVariableDeclaration(variableDeclaration)
		}

		return [statement]
	}

	override func replaceFunctionDeclaration( // gryphon annotation: override
		_ functionDeclaration: FunctionDeclaration)
		-> MutableList<Statement>
	{
		functionDeclaration.extendsType = self.extendingType
		return [functionDeclaration]
	}

	override func processVariableDeclaration( // gryphon annotation: override
		_ variableDeclaration: VariableDeclaration)
		-> VariableDeclaration
	{
		let variableDeclaration = variableDeclaration
		variableDeclaration.extendsType = self.extendingType
		return variableDeclaration
	}
}

/// If let conditions of the type `if let foo = foo as? Type` can be more simply translated as
/// `if (foo is Type)`. This pass makes that transformation.
public class ShadowedIfLetAsToIsTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	override func processIfStatement( // gryphon annotation: override
		_ ifStatement: IfStatement)
		-> IfStatement
	{
		let newConditions: MutableList<IfStatement.IfCondition> = []

		for condition in ifStatement.conditions {
			var conditionWasReplaced = false

			if case let .declaration(variableDeclaration: variableDeclaration) = condition {
				if let expression = variableDeclaration.expression {
					if let binaryOperator = expression as? BinaryOperatorExpression {
						if let leftExpression =
								binaryOperator.leftExpression as? DeclarationReferenceExpression,
							let rightExpression =
								binaryOperator.rightExpression as? TypeExpression,
							binaryOperator.operatorSymbol == "as?"
						{
							if variableDeclaration.identifier == leftExpression.identifier {
								conditionWasReplaced = true
								newConditions.append(IfStatement.IfCondition.condition(
									expression: BinaryOperatorExpression(
										range: binaryOperator.range,
										leftExpression: leftExpression,
										rightExpression: rightExpression,
										operatorSymbol: "is",
										typeName: "Bool")))
							}
						}
					}
				}
			}

			if !conditionWasReplaced {
				newConditions.append(condition)
			}
		}

		return super.processIfStatement(IfStatement(
			range: ifStatement.range,
			conditions: newConditions,
			declarations: ifStatement.declarations,
			statements: ifStatement.statements,
			elseStatement: ifStatement.elseStatement,
			isGuard: ifStatement.isGuard))
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
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	override func processFunctionDeclaration( // gryphon annotation: override
		_ functionDeclaration: FunctionDeclaration)
		-> FunctionDeclaration?
	{
		let swiftAPIName = functionDeclaration.prefix + "(" +
			functionDeclaration.parameters.map { ($0.apiLabel ?? "_") + ":" }.joined() + ")"

		self.context.addFunctionTranslation(
			TranspilationContext.FunctionTranslation(
				swiftAPIName: swiftAPIName,
				typeName: functionDeclaration.functionType,
				prefix: functionDeclaration.prefix,
				parameters: functionDeclaration.parameters.map { $0.label }.toMutableList()))

		//
		if functionDeclaration.isPure {
			self.context.recordPureFunction(functionDeclaration)
		}

		return super.processFunctionDeclaration(functionDeclaration)
	}
}

public class RecordEnumsTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	override func replaceEnumDeclaration( // gryphon annotation: override
		_ enumDeclaration: EnumDeclaration)
		-> MutableList<Statement>
	{
		let isEnumClass = enumDeclaration.inherits.isEmpty &&
			enumDeclaration.elements.reduce(true) { result, element in
				result && element.associatedValues.isEmpty
			}

		if isEnumClass {
			self.context.addEnumClass(enumDeclaration.enumName)
		}
		else {
			self.context.addSealedClass(enumDeclaration.enumName)
		}

		return [enumDeclaration]
	}
}

/// Records all protocol declarations in the Kotlin Translator
public class RecordProtocolsTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	override func replaceProtocolDeclaration( // gryphon annotation: override
		_ protocolDeclaration: ProtocolDeclaration)
		-> MutableList<Statement>
	{
		self.context.addProtocol(protocolDeclaration.protocolName)

		return super.replaceProtocolDeclaration(protocolDeclaration)
	}
}

public class RaiseStandardLibraryWarningsTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	override func processDeclarationReferenceExpression( // gryphon annotation: override
		_ expression: DeclarationReferenceExpression)
		-> DeclarationReferenceExpression
	{
		if expression.isStandardLibrary {
			let message = "Reference to standard library \"\(expression.identifier)\" was not " +
				"translated."
			Compiler.handleWarning(
					message: message,
					sourceFile: ast.sourceFile,
					sourceFileRange: expression.range)
		}
		return super.processDeclarationReferenceExpression(expression)
	}
}

/// If a value type's members are all immutable, that value type can safely be translated as a
/// class. Otherwise, the translation can cause inconsistencies, so this pass raises warnings.
/// Source: https://forums.swift.org/t/are-immutable-structs-like-classes/16270
public class RaiseMutableValueTypesWarningsTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	override func replaceStructDeclaration( // gryphon annotation: override
		_ structDeclaration: StructDeclaration)
		-> MutableList<Statement>
	{
		for member in structDeclaration.members {
			if let variableDeclaration = member as? VariableDeclaration {
				if !variableDeclaration.isImplicit,
					!variableDeclaration.isStatic,
					!variableDeclaration.isLet,
					variableDeclaration.getter == nil
				{
					let message = "No support for mutable variables in value types: found" +
						" variable \(variableDeclaration.identifier) inside struct " +
						structDeclaration.structName
					Compiler.handleWarning(
						message: message,
						sourceFile: ast.sourceFile,
						sourceFileRange: variableDeclaration.range)
					continue
				}
			}

			if let functionDeclaration = member as? FunctionDeclaration {
				if functionDeclaration.isMutating {
					let methodName = functionDeclaration.prefix + "(" +
						functionDeclaration.parameters.map { $0.label + ":" }
							.joined(separator: ", ") + ")"
					let message = "No support for mutating methods in value types: found method " +
						"\(methodName) inside struct \(structDeclaration.structName)"
					Compiler.handleWarning(
						message: message,
						sourceFile: ast.sourceFile,
						sourceFileRange: functionDeclaration.range)
					continue
				}
			}
		}

		return super.replaceStructDeclaration(structDeclaration)
	}

	override func replaceEnumDeclaration( // gryphon annotation: override
		_ enumDeclaration: EnumDeclaration)
		-> MutableList<Statement>
	{
		for member in enumDeclaration.members {
			if let functionDeclaration = member as? FunctionDeclaration {
				if functionDeclaration.isMutating {
					let methodName = functionDeclaration.prefix + "(" +
						functionDeclaration.parameters.map { $0.label + ":" }
							.joined(separator: ", ") + ")"
					let message = "No support for mutating methods in value types: found method " +
						"\(methodName) inside enum \(enumDeclaration.enumName)"
					Compiler.handleWarning(
						message: message,
						sourceFile: ast.sourceFile,
						sourceFileRange: functionDeclaration.range)
				}
			}
		}

		return super.replaceEnumDeclaration(enumDeclaration)
	}
}

/// `MutableList`s, `List`s, `MutableMap`s, and `Map`s are prefered to
/// using `Arrays` and `Dictionaries` for guaranteeing correctness. This pass raises warnings when
/// it finds uses of the native data structures, which should help avoid these bugs.
public class RaiseNativeDataStructureWarningsTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	override func replaceExpression( // gryphon annotation: override
		_ expression: Expression)
		-> Expression
	{
		if let type = expression.swiftType, type.hasPrefix("[") {
			let message = "Native type \(type) can lead to different behavior in Kotlin. Prefer " +
			"MutableList, List, MutableMap or Map instead."
			Compiler.handleWarning(
				message: message,
				details: expression.prettyDescription(),
				sourceFile: ast.sourceFile,
				sourceFileRange: expression.range)
		}

		return super.replaceExpression(expression)
	}

	override func replaceDotExpression( // gryphon annotation: override
		_ dotExpression: DotExpression)
		-> Expression
	{
		// TODO: automatically add parentheses around or's in if conditions otherwise they can
		// associate incorrectly.

		// If the expression is being transformed into a mutableList or a mutableMap it's probably
		// ok.
		if let leftExpressionType = dotExpression.leftExpression.swiftType,
			leftExpressionType.hasPrefix("["),
			let callExpression = dotExpression.rightExpression as? CallExpression {
			if (callExpression.typeName.hasPrefix("MutableList") ||
					callExpression.typeName.hasPrefix("List") ||
					callExpression.typeName.hasPrefix("MutableMap") ||
					callExpression.typeName.hasPrefix("Map")),
				let declarationReference =
					callExpression.function as? DeclarationReferenceExpression
			{
				if declarationReference.identifier.hasPrefix("toMutable"),
					(declarationReference.typeName.hasPrefix("MutableList") ||
						declarationReference.typeName.hasPrefix("MutableMap"))
				{
					return dotExpression
				}
				else if declarationReference.identifier.hasPrefix("toList"),
					declarationReference.typeName.hasPrefix("List")
				{
					return dotExpression
				}
				else if declarationReference.identifier.hasPrefix("toMap"),
					declarationReference.typeName.hasPrefix("Map")
				{
					return dotExpression
				}
			}
		}

		return super.replaceDotExpression(dotExpression)
	}
}

/// If statements with let declarations get translated to Kotlin by having their let declarations
/// rearranged to be before the if statement. This will cause any let conditions that have side
/// effects (i.e. `let x = sideEffects()`) to run eagerly on Kotlin but lazily on Swift, which can
/// lead to incorrect behavior.
public class RaiseWarningsForSideEffectsInIfLetsTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	override func processIfStatement( // gryphon annotation: override
		_ ifStatement: IfStatement)
		-> IfStatement
	{
		raiseWarningsForIfStatement(ifStatement, isElse: false)

		// No recursion by calling super, otherwise we'd run on the else statements twice
		// TODO: Add recursion on the if's statements
		return ifStatement
	}

	private func raiseWarningsForIfStatement(_ ifStatement: IfStatement, isElse: Bool) {
		// The first condition of an non-else if statement is the only one that can safely have side
		// effects
		let conditions = isElse ?
			ifStatement.conditions :
			MutableList<IfStatement.IfCondition>(ifStatement.conditions.dropFirst())

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
		_ condition: IfStatement.IfCondition)
		-> MutableList<SourceFileRange>
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
		-> MutableList<SourceFileRange>
	{
		if let expression = expression as? CallExpression {
			if !self.context.isReferencingPureFunction(expression),
				let range = expression.range
			{
				return [range]
			}
			else {
				return []
			}
		}
		if let expression = expression as? ParenthesesExpression {
			return rangesWithPossibleSideEffectsIn(expression.expression)
		}
		if let expression = expression as? ForceValueExpression {
			return rangesWithPossibleSideEffectsIn(expression.expression)
		}
		if let expression = expression as? OptionalExpression {
			return rangesWithPossibleSideEffectsIn(expression.expression)
		}
		if let expression = expression as? SubscriptExpression {
			let result = rangesWithPossibleSideEffectsIn(expression.subscriptedExpression)
			result.append(contentsOf:
				rangesWithPossibleSideEffectsIn(expression.indexExpression))
			return result
		}
		if let expression = expression as? ArrayExpression {
			return expression.elements
				.flatMap { rangesWithPossibleSideEffectsIn($0) }
				.toMutableList()
		}
		if let expression = expression as? DictionaryExpression {
			let result = expression.keys
				.flatMap { rangesWithPossibleSideEffectsIn($0) }
				.toMutableList()
			result.append(contentsOf:
				expression.values.flatMap { rangesWithPossibleSideEffectsIn($0) })
			return result
		}
		if let expression = expression as? DotExpression {
			let result = rangesWithPossibleSideEffectsIn(expression.leftExpression)
			result.append(contentsOf:
				rangesWithPossibleSideEffectsIn(expression.rightExpression))
			return result
		}
		if let expression = expression as? BinaryOperatorExpression {
			let result = rangesWithPossibleSideEffectsIn(expression.leftExpression)
			result.append(contentsOf:
				rangesWithPossibleSideEffectsIn(expression.rightExpression))
			return result
		}
		if let expression = expression as? PrefixUnaryExpression {
			return rangesWithPossibleSideEffectsIn(expression.subExpression)
		}
		if let expression = expression as? PostfixUnaryExpression {
			return rangesWithPossibleSideEffectsIn(expression.subExpression)
		}
		if let expression = expression as? IfExpression {
			let result = rangesWithPossibleSideEffectsIn(expression.condition)
			result.append(contentsOf:
				rangesWithPossibleSideEffectsIn(expression.trueExpression))
			result.append(contentsOf:
				rangesWithPossibleSideEffectsIn(expression.falseExpression))
			return result
		}
		if let expression = expression as? InterpolatedStringLiteralExpression {
			return expression.expressions
				.flatMap { rangesWithPossibleSideEffectsIn($0) }
				.toMutableList()
		}
		if let expression = expression as? TupleExpression {
			return expression.pairs
				.flatMap { rangesWithPossibleSideEffectsIn($0.expression) }
				.toMutableList()
		}
		if let expression = expression as? TupleShuffleExpression {
			return expression.expressions
				.flatMap { rangesWithPossibleSideEffectsIn($0) }
				.toMutableList()
		}

		return []
	}
}

/// Sends let declarations to before the if statement, and replaces them with `x != null` conditions
public class RearrangeIfLetsTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	/// Send the let declarations to before the if statement
	override func replaceIfStatement( // gryphon annotation: override
		_ ifStatement: IfStatement)
		-> MutableList<Statement>
	{
		let gatheredDeclarations = gatherLetDeclarations(ifStatement)

		// When if-lets are rearranged, it's possible to have two equal declarations (i.e.
		// `val a = b as? String` showing up twice) coming from two different `else if`s, which
		// create conflicts in Kotlin.
		let uniqueDeclarations = gatheredDeclarations.removingDuplicates()

		let result = MutableList<Statement>(uniqueDeclarations)

		result.append(contentsOf: super.replaceIfStatement(ifStatement))

		return result
	}

	/// Add conditions (`x != null`) for all let declarations
	override func processIfStatement( // gryphon annotation: override
		_ ifStatement: IfStatement)
		-> IfStatement
	{
		let newConditions = ifStatement.conditions.map {
			replaceIfLetConditionWithNullCheck($0)
		}.toMutableList()

		let ifStatement = ifStatement
		ifStatement.conditions = newConditions
		return super.processIfStatement(ifStatement)
	}

	private func replaceIfLetConditionWithNullCheck(
		_ condition: IfStatement.IfCondition)
		-> IfStatement.IfCondition
	{
		if case let .declaration(variableDeclaration: variableDeclaration) = condition {
			return .condition(expression: BinaryOperatorExpression(
				range: variableDeclaration.range,
				leftExpression: DeclarationReferenceExpression(
					range: variableDeclaration.expression?.range,
					identifier: variableDeclaration.identifier,
					typeName: variableDeclaration.typeName,
					isStandardLibrary: false,
					isImplicit: false),
				rightExpression: NilLiteralExpression(
					range: variableDeclaration.range),
				operatorSymbol: "!=",
				typeName: "Boolean"))
		}
		else {
			return condition
		}
	}

	/// Gather the let declarations from the if statement and its else( if)s into a single array
	private func gatherLetDeclarations(
		_ ifStatement: IfStatement?)
		-> MutableList<VariableDeclaration>
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

		let result = letDeclarations.toMutableList()
		result.append(contentsOf: elseLetDeclarations)
		return result
	}

	private func filterVariableDeclaration(
		_ condition: IfStatement.IfCondition)
		-> VariableDeclaration?
	{
		if case let .declaration(variableDeclaration: variableDeclaration) = condition {
			return variableDeclaration
		}
		else {
			return nil
		}
	}

	private func isShadowingVariableDeclaration(
		_ variableDeclaration: VariableDeclaration)
		-> Bool
	{
		// If it's a shadowing identifier there's no need to declare it in Kotlin
		// (i.e. `if let x = x { }`)
		if let declarationExpression = variableDeclaration.expression,
			let expression = declarationExpression as? DeclarationReferenceExpression
		{
			if expression.identifier == variableDeclaration.identifier {
				return true
			}
		}

		return false
	}
}

/// Change the implementation of a `==` operator to be usable in Kotlin
public class EquatableOperatorsTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	override func processFunctionDeclaration( // gryphon annotation: override
		_ functionDeclaration: FunctionDeclaration)
		-> FunctionDeclaration?
	{
		guard functionDeclaration.prefix == "==",
			functionDeclaration.parameters.count == 2,
			let oldStatements = functionDeclaration.statements else
		{
			return functionDeclaration
		}

		let lhs = functionDeclaration.parameters[0]
		let rhs = functionDeclaration.parameters[1]

		let newStatements: MutableList<Statement> = []

		let range = functionDeclaration.range

		// Declare new variables with the same name as the Swift paramemeters, containing `this` and
		// `other`
		newStatements.append(VariableDeclaration(
			range: range,
			identifier: lhs.label,
			typeName: lhs.typeName,
			expression: DeclarationReferenceExpression(
				range: range,
				identifier: "this",
				typeName: lhs.typeName,
				isStandardLibrary: false,
				isImplicit: false),
			getter: nil,
			setter: nil,
			access: nil,
			isLet: true,
			isImplicit: false,
			isStatic: false,
			extendsType: nil,
			annotations: nil))
		newStatements.append(VariableDeclaration(
			range: range,
			identifier: rhs.label,
			typeName: "Any?",
			expression: DeclarationReferenceExpression(
				range: range,
				identifier: "other",
				typeName: "Any?",
				isStandardLibrary: false,
				isImplicit: false),
			getter: nil,
			setter: nil,
			access: nil,
			isLet: true,
			isImplicit: false,
			isStatic: false,
			extendsType: nil,
			annotations: nil))

		// Add an if statement to guarantee the comparison only happens between the right types
		newStatements.append(IfStatement(
			range: range,
			conditions: [ .condition(expression: BinaryOperatorExpression(
				range: range,
				leftExpression: DeclarationReferenceExpression(
					range: range,
					identifier: rhs.label,
					typeName: "Any?",
					isStandardLibrary: false,
					isImplicit: false),
				rightExpression: TypeExpression(range: range, typeName: rhs.typeName),
				operatorSymbol: "is",
				typeName: "Bool")),
			],
			declarations: [],
			statements: oldStatements,
			elseStatement: IfStatement(
				range: range,
				conditions: [],
				declarations: [],
				statements: [
					ReturnStatement(range: range, expression:
						LiteralBoolExpression(range: range, value: false)),
				],
				elseStatement: nil,
				isGuard: false),
			isGuard: false))

		return super.processFunctionDeclaration(FunctionDeclaration(
			range: range,
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
			access: "public",
			annotations: "override open"))
	}
}

/// Create a rawValue variable for enums that conform to rawRepresentable
public class RawValuesTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	override func replaceEnumDeclaration( // gryphon annotation: override
		_ enumDeclaration: EnumDeclaration) -> MutableList<Statement>
	{
		if let typeName = enumDeclaration.elements.compactMap({ $0.rawValue?.swiftType }).first {
			let rawValueVariable = createRawValueVariable(
				withRawValueType: typeName,
				forEnumDeclaration: enumDeclaration)

			guard let rawValueInitializer = createRawValueInitializer(
				withRawValueType: typeName,
				forEnumDeclaration: enumDeclaration) else
			{
				Compiler.handleWarning(
					message: "Failed to create init(rawValue:)",
					details: "Unable to get all raw values in enum declaration.",
					sourceFile: ast.sourceFile,
					sourceFileRange: enumDeclaration.range)
				return super.replaceEnumDeclaration(enumDeclaration)
			}

			let newMembers = enumDeclaration.members
			newMembers.append(rawValueInitializer)
			newMembers.append(rawValueVariable)

			return super.replaceEnumDeclaration(EnumDeclaration(
				range: enumDeclaration.range,
				access: enumDeclaration.access,
				enumName: enumDeclaration.enumName,
				inherits: enumDeclaration.inherits,
				elements: enumDeclaration.elements,
				members: newMembers,
				isImplicit: enumDeclaration.isImplicit))
		}
		else {
			return super.replaceEnumDeclaration(enumDeclaration)
		}
	}

	private func createRawValueInitializer(
		withRawValueType rawValueType: String,
		forEnumDeclaration enumDeclaration: EnumDeclaration)
		-> FunctionDeclaration?
	{
		for element in enumDeclaration.elements {
			if element.rawValue == nil {
				return nil
			}
		}

		let range = enumDeclaration.range

		let switchCases = enumDeclaration.elements.map { element -> SwitchCase in
			SwitchCase(
				expressions: [element.rawValue!],
				statements: [
					ReturnStatement(
						range: range,
						expression: DotExpression(
							range: range,
							leftExpression: TypeExpression(
								range: range,
								typeName: enumDeclaration.enumName),
							rightExpression: DeclarationReferenceExpression(
								range: range,
								identifier: element.name,
								typeName: enumDeclaration.enumName,
								isStandardLibrary: false,
								isImplicit: false))),
				])
		}.toMutableList()

		let defaultSwitchCase = SwitchCase(
			expressions: [],
			statements: [ReturnStatement(
				range: range,
				expression: NilLiteralExpression(range: range)), ])

		switchCases.append(defaultSwitchCase)

		let switchStatement = SwitchStatement(
			range: range,
			convertsToExpression: nil,
			expression: DeclarationReferenceExpression(
				range: range,
				identifier: "rawValue",
				typeName: rawValueType,
				isStandardLibrary: false,
				isImplicit: false),
			cases: switchCases)

		return InitializerDeclaration(
			range: range,
			parameters: [FunctionParameter(
				label: "rawValue",
				apiLabel: nil,
				typeName: rawValueType,
				value: nil), ],
			returnType: enumDeclaration.enumName + "?",
			functionType: "(\(rawValueType)) -> \(enumDeclaration.enumName)?",
			genericTypes: [],
			isImplicit: false,
			isStatic: true,
			isMutating: false,
			isPure: true,
			extendsType: nil,
			statements: [switchStatement],
			access: enumDeclaration.access,
			annotations: nil,
			superCall: nil)
	}

	private func createRawValueVariable(
		withRawValueType rawValueType: String,
		forEnumDeclaration enumDeclaration: EnumDeclaration)
		-> VariableDeclaration
	{
		let range = enumDeclaration.range

		let switchCases = enumDeclaration.elements.map { element in
			SwitchCase(
				expressions: [DotExpression(
					range: range,
					leftExpression: TypeExpression(
						range: range,
						typeName: enumDeclaration.enumName),
					rightExpression: DeclarationReferenceExpression(
						range: range,
						identifier: element.name,
						typeName: enumDeclaration.enumName,
						isStandardLibrary: false,
						isImplicit: false)), ],
				statements: [
					ReturnStatement(
						range: range,
						expression: element.rawValue),
				])
		}.toMutableList()

		let switchStatement = SwitchStatement(
			range: range,
			convertsToExpression: nil,
			expression: DeclarationReferenceExpression(
				range: range,
				identifier: "this",
				typeName: enumDeclaration.enumName,
				isStandardLibrary: false,
				isImplicit: false),
			cases: switchCases)

		let getter = FunctionDeclaration(
			range: range,
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
			access: enumDeclaration.access,
			annotations: nil)

		return VariableDeclaration(
			range: range,
			identifier: "rawValue",
			typeName: rawValueType,
			expression: nil,
			getter: getter,
			setter: nil,
			access: nil,
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
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	override func processIfStatement( // gryphon annotation: override
		_ ifStatement: IfStatement)
		-> IfStatement
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
					range: binaryOperatorExpression.range,
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
					range: binaryOperatorExpression.range,
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
			ifStatement.conditions = MutableList<Expression>([newCondition]).map {
					IfStatement.IfCondition.condition(expression: $0)
				}.toMutableList()
			ifStatement.isGuard = shouldStillBeGuard
			return super.processIfStatement(ifStatement)
		}
		else {
			return super.processIfStatement(ifStatement)
		}
	}
}

/// Statements of the type `if (a == null) { return }` in Swift can be translated as `a ?: return`
/// in Kotlin.
public class ReturnIfNilTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	override func replaceStatement( // gryphon annotation: override
		_ statement: Statement)
		-> MutableList<Statement>
	{
		if let ifStatement = statement as? IfStatement {
			if ifStatement.conditions.count == 1,
				ifStatement.statements.count == 1
			{
				let onlyStatement = ifStatement.statements[0]
				let onlyCondition = ifStatement.conditions[0]

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
							return [ExpressionStatement(
								range: ifStatement.range,
								expression: BinaryOperatorExpression(
									range: ifStatement.range,
									leftExpression: binaryOperatorExpression.leftExpression,
									rightExpression: ReturnExpression(
										range: ifStatement.range,
										expression: returnStatement.expression),
									operatorSymbol: "?:",
									typeName: declarationExpression.typeName)), ]
						}
					}
				}
			}
		}

		return super.replaceStatement(statement)
	}
}

public class FixProtocolContentsTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	var isInProtocol = false

	override func replaceProtocolDeclaration( // gryphon annotation: override
		_ protocolDeclaration: ProtocolDeclaration)
		-> MutableList<Statement>
	{
		isInProtocol = true
		let result = super.replaceProtocolDeclaration(protocolDeclaration)
		isInProtocol = false

		return result
	}

	override func processFunctionDeclaration( // gryphon annotation: override
		_ functionDeclaration: FunctionDeclaration)
		-> FunctionDeclaration?
	{
		if isInProtocol {
			let functionDeclaration = functionDeclaration
			functionDeclaration.statements = nil
			return super.processFunctionDeclaration(functionDeclaration)
		}
		else {
			return super.processFunctionDeclaration(functionDeclaration)
		}
	}

	override func processVariableDeclaration( // gryphon annotation: override
		_ variableDeclaration: VariableDeclaration)
		-> VariableDeclaration
	{
		if isInProtocol {
			let variableDeclaration = variableDeclaration
			variableDeclaration.getter?.isImplicit = true
			variableDeclaration.setter?.isImplicit = true
			variableDeclaration.getter?.statements = nil
			variableDeclaration.setter?.statements = nil
			return super.processVariableDeclaration(variableDeclaration)
		}
		else {
			return super.processVariableDeclaration(variableDeclaration)
		}
	}
}

public extension TranspilationPass {
	/// Runs transpilation passes that have to be run on all files before the other passes can
	/// run. For instance, we need to record all enums declared on all files before we can
	/// translate references to them correctly.
	static func runFirstRoundOfPasses(
		on sourceFile: GryphonAST,
		withContext context: TranspilationContext)
		-> GryphonAST
	{
		var ast = sourceFile

		// Remove declarations that shouldn't even be considered in the passes
		ast = RemoveImplicitDeclarationsTranspilationPass(ast: ast, context: context).run()

		// RecordEnums needs to be after CleanInheritance: it needs Swift-only inheritances removed
		// in order to know if the enum inherits from a class or not, and therefore is a sealed
		// class or an enum class.
		ast = CleanInheritancesTranspilationPass(ast: ast, context: context).run()

		// Record information on enum and function translations
		ast = RecordTemplatesTranspilationPass(ast: ast, context: context).run()
		ast = RecordEnumsTranspilationPass(ast: ast, context: context).run()
		ast = RecordProtocolsTranspilationPass(ast: ast, context: context).run()
		ast = RecordFunctionsTranspilationPass(ast: ast, context: context).run()

		return ast
	}

	/// Runs transpilation passes that can be run independently on any files, provided they happen
	/// after the `runFirstRoundOfPasses`.
	static func runSecondRoundOfPasses(
		on sourceFile: GryphonAST,
		withContext context: TranspilationContext)
		-> GryphonAST
	{
		var ast = sourceFile

		// Replace templates (must go before other passes since templates are recorded before
		// running any passes)
		ast = ReplaceTemplatesTranspilationPass(ast: ast, context: context).run()

		// Cleanup
		ast = RemoveParenthesesTranspilationPass(ast: ast, context: context).run()
		ast = RemoveExtraReturnsInInitsTranspilationPass(ast: ast, context: context).run()

		// Transform structures that need to be significantly different in Kotlin
		ast = EquatableOperatorsTranspilationPass(ast: ast, context: context).run()
		ast = RawValuesTranspilationPass(ast: ast, context: context).run()
		ast = DescriptionAsToStringTranspilationPass(ast: ast, context: context).run()
		ast = OptionalInitsTranspilationPass(ast: ast, context: context).run()
		ast = StaticMembersTranspilationPass(ast: ast, context: context).run()
		ast = FixProtocolContentsTranspilationPass(ast: ast, context: context).run()
		ast = RemoveExtensionsTranspilationPass(ast: ast, context: context).run()

		// Deal with if lets:
		// - We can refactor shadowed if-let-as conditions before raising warnings to avoid false
		//   alarms
		// - We have to know the order of the conditions to raise warnings here, so warnings must go
		//   before the conditions are rearranged
		ast = ShadowedIfLetAsToIsTranspilationPass(ast: ast, context: context).run()
		ast = RaiseWarningsForSideEffectsInIfLetsTranspilationPass(ast: ast, context: context).run()
		ast = RearrangeIfLetsTranspilationPass(ast: ast, context: context).run()

		// Transform structures that need to be slightly different in Kotlin
		ast = SelfToThisTranspilationPass(ast: ast, context: context).run()
		ast = AnonymousParametersTranspilationPass(ast: ast, context: context).run()
		ast = CovarianceInitsAsCallsTranspilationPass(ast: ast, context: context).run()
		ast = DataStructureInitializersTranspilationPass(ast: ast, context: context).run()
		ast = ReturnsInLambdasTranspilationPass(ast: ast, context: context).run()
		ast = TuplesToPairsTranspilationPass(ast: ast, context: context).run()
		ast = TupleMembersTranspilationPass(ast: ast, context: context).run()
		ast = AutoclosuresTranspilationPass(ast: ast, context: context).run()
		ast = RefactorOptionalsInSubscriptsTranspilationPass(ast: ast, context: context).run()
		ast = AddOptionalsInDotChainsTranspilationPass(ast: ast, context: context).run()
		ast = RenameOperatorsTranspilationPass(ast: ast, context: context).run()
		ast = CallsToSuperclassInitializersTranspilationPass(ast: ast, context: context).run()
		ast = OptionalsInConditionalCastsTranspilationPass(ast: ast, context: context).run()
		ast = AccessModifiersTranspilationPass(ast: ast, context: context).run()

		// - CapitalizeEnums has to be before IsOperatorsInSealedClasses
		ast = CapitalizeEnumsTranspilationPass(ast: ast, context: context).run()
		ast = IsOperatorsInSealedClassesTranspilationPass(ast: ast, context: context).run()

		// - SwitchesToExpressions has to be before RemoveBreaksInSwitches:
		//   RemoveBreaks might remove a case that only has a break, turning an exhaustive switch
		//   into a non-exhaustive one and making it convertible to an expression. However, only
		//   exhaustive switches can be converted to expressions, so this should be avoided.
		ast = SwitchesToExpressionsTranspilationPass(ast: ast, context: context).run()
		ast = RemoveBreaksInSwitchesTranspilationPass(ast: ast, context: context).run()

		// Improve Kotlin readability
		ast = OmitImplicitEnumPrefixesTranspilationPass(ast: ast, context: context).run()
		ast = InnerTypePrefixesTranspilationPass(ast: ast, context: context).run()
		ast = DoubleNegativesInGuardsTranspilationPass(ast: ast, context: context).run()
		ast = ReturnIfNilTranspilationPass(ast: ast, context: context).run()

		// Raise any warnings that may be left
		ast = RaiseStandardLibraryWarningsTranspilationPass(ast: ast, context: context).run()
		ast = RaiseMutableValueTypesWarningsTranspilationPass(ast: ast, context: context).run()
		ast = RaiseNativeDataStructureWarningsTranspilationPass(ast: ast, context: context).run()

		return ast
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
