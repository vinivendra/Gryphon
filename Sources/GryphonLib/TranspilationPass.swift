//
// Copyright 2018 Vinicius Jorge Vendramini
//
// Licensed under the Hippocratic License, Version 2.1;
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://firstdonoharm.dev/version/2/1/license.md
//
// To the full extent allowed by law, this software comes "AS IS,"
// WITHOUT ANY WARRANTY, EXPRESS OR IMPLIED, and licensor and any other
// contributor shall not be liable to anyone for any damages or other
// liability arising from, out of, or in connection with the sotfware
// or this license, under any kind of legal claim.
// See the License for the specific language governing permissions and
// limitations under the License.
//

// gryphon output: Sources/GryphonLib/TranspilationPass.swiftAST
// gryphon output: Sources/GryphonLib/TranspilationPass.gryphonASTRaw
// gryphon output: Sources/GryphonLib/TranspilationPass.gryphonAST
// gryphon output: Bootstrap/TranspilationPass.kt

// gryphon insert: import kotlin.system.*

import SwiftSyntax

/// Implements the basic algorithm that visits nodes in the AST. Subclassing this class and
/// overriding the `replace` and `process` methods lets you alter the AST in specific places, which
/// is how most passes are implemented.
/// The `process` methods are just like the `replace` methods, except that they return the same type
/// that they receive.
/// The default implementation of `replace` methods is to simply return the same node as they
/// received - after visiting all of its subnodes and replacing them if necessary. This means
/// running the base TranspilationPass class on an AST, without overriding any methods, will simply
/// return the same AST.
/// It also means that overriding methods may call their respective super methods if they want to
/// visit all subnodes (instead of manually re-implementing this visit). For example, when
/// overriding `replaceIfStatement`, instead of just returning a new if statement a user might call
/// `return super.replaceIfStatement(myNewIfStatement)` to make sure the overridden method also runs
/// on nested if statements.
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

	/// Is the current node that's being replaced a statement on the main function or a declaration?
	internal var isReplacingStatements = false

	/// Top-level nodes are those outside the main function and with no parents.
	internal var isTopLevelNode: Bool {
		return parent == nil && !isReplacingStatements
	}

	// MARK: - Interface
	init(ast: GryphonAST, context: TranspilationContext) {
		self.ast = ast
		self.context = context
	}

	func run() -> GryphonAST { // gryphon annotation: open
		isReplacingStatements = true
		let replacedStatements = replaceStatements(ast.statements)
		isReplacingStatements = false
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

	static let swiftRawRepresentableTypes: List = [
		"String",
		"Int", "Int8", "Int16", "Int32", "Int64",
		"UInt", "UInt8", "UInt16", "UInt32", "UInt64",
		"Float", "Float32", "Float64", "Float80", "Double",
	]

	static let swiftProtocols: List = [
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
		-> List<Statement>
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
			return [BreakStatement(syntax: statement.syntax, range: statement.range)]
		}
		if statement is ContinueStatement {
			return [ContinueStatement(syntax: statement.syntax, range: statement.range)]
		}
		if let assignmentStatement = statement as? AssignmentStatement {
			return replaceAssignmentStatement(assignmentStatement)
		}
		if statement is ErrorStatement {
			return [ErrorStatement(syntax: statement.syntax, range: statement.range)]
		}

		fatalError("This should never be reached.")
	}

	func replaceComment( // gryphon annotation: open
		_ commentStatement: CommentStatement)
		-> List<Statement>
	{
		return [commentStatement]
	}

	func replaceExpressionStatement( // gryphon annotation: open
		_ expressionStatement: ExpressionStatement)
		-> List<Statement>
	{
		return [ExpressionStatement(
			syntax: expressionStatement.syntax,
			range: expressionStatement.range,
			expression: replaceExpression(expressionStatement.expression)), ]
	}

	func replaceExtension( // gryphon annotation: open
		_ extensionDeclaration: ExtensionDeclaration)
		-> List<Statement>
	{
		return [ExtensionDeclaration(
			syntax: extensionDeclaration.syntax,
			range: extensionDeclaration.range,
			typeName: extensionDeclaration.typeName,
			members: replaceStatements(extensionDeclaration.members)), ]
	}

	func replaceImportDeclaration( // gryphon annotation: open
		_ importDeclaration: ImportDeclaration)
		-> List<Statement>
	{
		return [importDeclaration]
	}

	func replaceTypealiasDeclaration( // gryphon annotation: open
		_ typealiasDeclaration: TypealiasDeclaration)
		-> List<Statement>
	{
		return [typealiasDeclaration]
	}

	func replaceClassDeclaration( // gryphon annotation: open
		_ classDeclaration: ClassDeclaration)
		-> List<Statement>
	{
		return [ClassDeclaration(
			syntax: classDeclaration.syntax,
			range: classDeclaration.range,
			className: classDeclaration.className,
			annotations: classDeclaration.annotations,
			access: classDeclaration.access,
			isOpen: classDeclaration.isOpen,
			inherits: classDeclaration.inherits,
			members: replaceStatements(classDeclaration.members)), ]
	}

	func replaceCompanionObject( // gryphon annotation: open
		_ companionObject: CompanionObject)
		-> List<Statement>
	{
		return [CompanionObject(
			syntax: companionObject.syntax,
			range: companionObject.range,
			members: replaceStatements(companionObject.members)), ]
	}

	func replaceEnumDeclaration( // gryphon annotation: open
		_ enumDeclaration: EnumDeclaration)
		-> List<Statement>
	{
		return [
			EnumDeclaration(
				syntax: enumDeclaration.syntax,
				range: enumDeclaration.range,
				access: enumDeclaration.access,
				enumName: enumDeclaration.enumName,
				annotations: enumDeclaration.annotations,
				inherits: enumDeclaration.inherits,
				elements: enumDeclaration.elements
					.flatMap { replaceEnumElementDeclaration($0) }
					.toMutableList(),
				members: replaceStatements(enumDeclaration.members),
				isImplicit: enumDeclaration.isImplicit), ]
	}

	func replaceEnumElementDeclaration( // gryphon annotation: open
		_ enumElement: EnumElement)
		-> List<EnumElement>
	{
		return [enumElement]
	}

	func replaceProtocolDeclaration( // gryphon annotation: open
		_ protocolDeclaration: ProtocolDeclaration)
		-> List<Statement>
	{
		return [ProtocolDeclaration(
			syntax: protocolDeclaration.syntax,
			range: protocolDeclaration.range,
			protocolName: protocolDeclaration.protocolName,
			access: protocolDeclaration.access,
			annotations: protocolDeclaration.annotations,
			members: replaceStatements(protocolDeclaration.members)), ]
	}

	func replaceStructDeclaration( // gryphon annotation: open
		_ structDeclaration: StructDeclaration)
		-> List<Statement>
	{
		return [StructDeclaration(
			syntax: structDeclaration.syntax,
			range: structDeclaration.range,
			annotations: structDeclaration.annotations,
			structName: structDeclaration.structName,
			access: structDeclaration.access,
			inherits: structDeclaration.inherits,
			members: replaceStatements(structDeclaration.members)), ]
	}

	func replaceInitializerDeclaration( // gryphon annotation: open
		_ initializerDeclaration: InitializerDeclaration)
		-> List<Statement>
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
					value: $0.value.map { replaceExpression($0) },
					isVariadic: $0.isVariadic)
		}

		initializerDeclaration.parameters = replacedParameters.toMutableList()
		initializerDeclaration.statements =
			initializerDeclaration.statements.map { replaceStatements($0) }
		return initializerDeclaration
	}

	func replaceFunctionDeclaration( // gryphon annotation: open
		_ functionDeclaration: FunctionDeclaration)
		-> List<Statement>
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
					value: $0.value.map { replaceExpression($0) },
					isVariadic: $0.isVariadic)
			}

		functionDeclaration.parameters = replacedParameters.toMutableList()
		functionDeclaration.statements =
			functionDeclaration.statements.map { replaceStatements($0) }
		return functionDeclaration
	}

	func replaceVariableDeclaration( // gryphon annotation: open
		_ variableDeclaration: VariableDeclaration)
		-> List<Statement>
	{
		return [processVariableDeclaration(variableDeclaration)]
	}

	func processVariableDeclaration( // gryphon annotation: open
		_ variableDeclaration: VariableDeclaration)
		-> VariableDeclaration
	{
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
		-> List<Statement>
	{
		return [DoStatement(
			syntax: doStatement.syntax,
			range: doStatement.range,
			statements: replaceStatements(doStatement.statements)), ]
	}

	func replaceCatchStatement( // gryphon annotation: open
		_ catchStatement: CatchStatement)
		-> List<Statement>
	{
		return [CatchStatement(
			syntax: catchStatement.syntax,
			range: catchStatement.range,
			variableDeclaration: catchStatement.variableDeclaration
				.map { processVariableDeclaration($0) },
			statements: replaceStatements(catchStatement.statements)),
		]
	}

	func replaceForEachStatement( // gryphon annotation: open
		_ forEachStatement: ForEachStatement)
		-> List<Statement>
	{
		return [ForEachStatement(
			syntax: forEachStatement.syntax,
			range: forEachStatement.range,
			collection: replaceExpression(forEachStatement.collection),
			variable: forEachStatement.variable.map { replaceExpression($0) },
			statements: replaceStatements(forEachStatement.statements)), ]
	}

	func replaceWhileStatement( // gryphon annotation: open
		_ whileStatement: WhileStatement)
		-> List<Statement>
	{
		return [WhileStatement(
			syntax: whileStatement.syntax,
			range: whileStatement.range,
			expression: replaceExpression(whileStatement.expression),
			statements: replaceStatements(whileStatement.statements)), ]
	}

	func replaceIfStatement( // gryphon annotation: open
		_ ifStatement: IfStatement)
		-> List<Statement>
	{
		return [processIfStatement(ifStatement)]
	}

	func processIfStatement( // gryphon annotation: open
		_ ifStatement: IfStatement)
		-> IfStatement
	{
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
		-> List<Statement>
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
			syntax: switchStatement.syntax,
			range: switchStatement.range,
			convertsToExpression: replacedConvertsToExpression,
			expression: replaceExpression(switchStatement.expression),
			cases: replacedCases.toMutableList()), ]
	}

	func replaceDeferStatement( // gryphon annotation: open
		_ deferStatement: DeferStatement)
		-> List<Statement>
	{
		return [DeferStatement(
			syntax: deferStatement.syntax,
			range: deferStatement.range,
			statements: replaceStatements(deferStatement.statements)), ]
	}

	func replaceThrowStatement( // gryphon annotation: open
		_ throwStatement: ThrowStatement)
		-> List<Statement>
	{
		return [ThrowStatement(
			syntax: throwStatement.syntax,
			range: throwStatement.range,
			expression: replaceExpression(throwStatement.expression)), ]
	}

	func replaceReturnStatement( // gryphon annotation: open
		_ returnStatement: ReturnStatement)
		-> List<Statement>
	{
		return [ReturnStatement(
			syntax: returnStatement.syntax,
			range: returnStatement.range,
			expression: returnStatement.expression.map { replaceExpression($0) },
			label: returnStatement.label), ]
	}

	func replaceAssignmentStatement( // gryphon annotation: open
		_ assignmentStatement: AssignmentStatement)
		-> List<Statement>
	{
		return [AssignmentStatement(
			syntax: assignmentStatement.syntax,
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

		if let expression = expression as? LiteralCodeExpression {
			return replaceLiteralCodeExpression(expression)
		}
		if let expression = expression as? ConcatenationExpression {
			return replaceConcatenationExpression(expression)
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
			return ErrorExpression(
				syntax: expression.syntax,
				range: expression.range)
		}

		fatalError("This should never be reached.")
	}

	func replaceLiteralCodeExpression( // gryphon annotation: open
		_ literalCodeExpression: LiteralCodeExpression)
		-> Expression
	{
		return literalCodeExpression
	}

	func replaceConcatenationExpression(
		_ concatenationExpression: ConcatenationExpression)
		-> Expression
	{
		return ConcatenationExpression(
			syntax: concatenationExpression.syntax,
			range: concatenationExpression.range,
			leftExpression: replaceExpression(concatenationExpression.leftExpression),
			rightExpression: replaceExpression(concatenationExpression.rightExpression))
	}

	func replaceParenthesesExpression( // gryphon annotation: open
		_ parenthesesExpression: ParenthesesExpression)
		-> Expression
	{
		return ParenthesesExpression(
			syntax: parenthesesExpression.syntax,
			range: parenthesesExpression.range,
			expression: replaceExpression(parenthesesExpression.expression))
	}

	func replaceForceValueExpression( // gryphon annotation: open
		_ forceValueExpression: ForceValueExpression)
		-> Expression
	{
		return ForceValueExpression(
			syntax: forceValueExpression.syntax,
			range: forceValueExpression.range,
			expression: replaceExpression(forceValueExpression.expression))
	}

	func replaceOptionalExpression( // gryphon annotation: open
		_ optionalExpression: OptionalExpression)
		-> Expression
	{
		return OptionalExpression(
			syntax: optionalExpression.syntax,
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
			syntax: subscriptExpression.syntax,
			range: subscriptExpression.range,
			subscriptedExpression: replaceExpression(subscriptExpression.subscriptedExpression),
			indexExpression: processTupleExpression(subscriptExpression.indexExpression),
			typeName: subscriptExpression.typeName)
	}

	func replaceArrayExpression( // gryphon annotation: open
		_ arrayExpression: ArrayExpression)
		-> Expression
	{
		return ArrayExpression(
			syntax: arrayExpression.syntax,
			range: arrayExpression.range,
			elements: arrayExpression.elements.map { replaceExpression($0) }.toMutableList(),
			typeName: arrayExpression.typeName)
	}

	func replaceDictionaryExpression( // gryphon annotation: open
		_ dictionaryExpression: DictionaryExpression)
		-> Expression
	{
		return DictionaryExpression(
			syntax: dictionaryExpression.syntax,
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
			syntax: returnStatement.syntax,
			range: returnStatement.range,
			expression: returnStatement.expression.map { replaceExpression($0) })
	}

	func replaceDotExpression( // gryphon annotation: open
		_ dotExpression: DotExpression)
		-> Expression
	{
		return DotExpression(
			syntax: dotExpression.syntax,
			range: dotExpression.range,
			leftExpression: replaceExpression(dotExpression.leftExpression),
			rightExpression: replaceExpression(dotExpression.rightExpression))
	}

	func replaceBinaryOperatorExpression( // gryphon annotation: open
		_ binaryOperatorExpression: BinaryOperatorExpression)
		-> Expression
	{
		return BinaryOperatorExpression(
			syntax: binaryOperatorExpression.syntax,
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
			syntax: prefixUnaryExpression.syntax,
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
			syntax: postfixUnaryExpression.syntax,
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
			syntax: ifExpression.syntax,
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
			syntax: callExpression.syntax,
			range: callExpression.range,
			function: replaceExpression(callExpression.function),
			parameters: replaceExpression(callExpression.parameters),
			typeName: callExpression.typeName,
			allowsTrailingClosure: callExpression.allowsTrailingClosure)
	}

	func replaceClosureExpression( // gryphon annotation: open
		_ closureExpression: ClosureExpression)
		-> Expression
	{
		return ClosureExpression(
			syntax: closureExpression.syntax,
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
			syntax: interpolatedStringLiteralExpression.syntax,
			range: interpolatedStringLiteralExpression.range,
			expressions: interpolatedStringLiteralExpression.expressions
				.map { replaceExpression($0) }.toMutableList())
	}

	func replaceTupleExpression( // gryphon annotation: open
		_ tupleExpression: TupleExpression)
		-> Expression
	{
		return processTupleExpression(tupleExpression)
	}

	func processTupleExpression( // gryphon annotation: open
		_ tupleExpression: TupleExpression)
		-> TupleExpression
	{
		return TupleExpression(
			syntax: tupleExpression.syntax,
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
			syntax: tupleShuffleExpression.syntax,
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
		-> List<Statement>
	{
		// Get the type that declares this property, if any
		var maybeTypeParent: String?
		for parent in parents {
			if case let .statementNode(value: parentStatement) = parent {
				if let classDeclaration = parentStatement as? ClassDeclaration {
					maybeTypeParent = classDeclaration.className
				}
				else if let structDeclaration = parentStatement as? StructDeclaration {
					maybeTypeParent = structDeclaration.structName
				}
				else if let enumDeclaration = parentStatement as? EnumDeclaration {
					maybeTypeParent = enumDeclaration.enumName
				}
			}
		}

		if let typeParent = maybeTypeParent {
			if let inheritances = context.inheritances[typeParent] {
				// If the description variable isn't satisfying a CustomStringConvertible
				// requirement, do nothing
				if !inheritances.contains("CustomStringConvertible") {
					return super.replaceVariableDeclaration(variableDeclaration)
				}
			}
			else {
				// If we found the parent type, its inheritances should have been recorded earlier.
				// Something went wrong.
				do {
					try Compiler.handleError(
						message: "Unable to check inheritances for \(typeParent)",
						sourceFile: ast.sourceFile,
						sourceFileRange: variableDeclaration.range)
				}
				catch { }
				return [ErrorStatement(
					syntax: variableDeclaration.syntax,
					range: variableDeclaration.range)]
			}
		}
		else {
			// Local variable, do nothing
			return super.replaceVariableDeclaration(variableDeclaration)
		}

		if variableDeclaration.identifier == "description",
			variableDeclaration.typeAnnotation == "String"
		{
			let statements: MutableList<Statement>
			if let getterStatements = variableDeclaration.getter?.statements {
				statements = getterStatements
			}
			else if let expression = variableDeclaration.expression {
				statements = [ExpressionStatement(
					syntax: expression.syntax,
					range: expression.range,
					expression: expression)]
			}
			else {
				return super.replaceVariableDeclaration(variableDeclaration)
			}

			let newAnnotations = variableDeclaration.annotations
			if !newAnnotations.contains("override") {
				newAnnotations.append("override")
			}

			return [FunctionDeclaration(
				syntax: variableDeclaration.syntax,
				range: variableDeclaration.range,
				prefix: "toString",
				parameters: [],
				returnType: "String",
				functionType: "() -> String",
				genericTypes: [],
				isOpen: !context.defaultsToFinal,
				isImplicit: false,
				isStatic: false,
				isMutating: false,
				isPure: false,
				isJustProtocolInterface: false,
				extendsType: variableDeclaration.extendsType,
				statements: statements,
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
		if subscriptExpression.indexExpression.pairs.count == 1,
			let onlyExpression = subscriptExpression.indexExpression.pairs.first,
			onlyExpression.label == nil,
			let parenthesesExpression = onlyExpression.expression as? ParenthesesExpression
		{
			return super.replaceSubscriptExpression(SubscriptExpression(
				syntax: subscriptExpression.syntax,
				range: subscriptExpression.range,
				subscriptedExpression: subscriptExpression.subscriptedExpression,
				indexExpression: TupleExpression(
					range: subscriptExpression.indexExpression.range,
					pairs: [LabeledExpression(
						label: nil,
						expression: parenthesesExpression.expression), ]),
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
			syntax: ifExpression.syntax,
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
		-> List<Statement>
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
		-> List<Statement>
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
		-> List<Statement>
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

/// SwiftSyntax does not include return types in initializers, but we can get them from the
/// encolsing class, struct, or enum.
public class ReturnTypesForInitsTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	let typeDeclarationStack: MutableList<String> = []

	override func processInitializerDeclaration( // gryphon annotation: override
		_ initializerDeclaration: InitializerDeclaration)
		-> InitializerDeclaration?
	{
		if context.isUsingSwiftSyntax, let enclosingType = typeDeclarationStack.last {
			initializerDeclaration.returnType = enclosingType

			let functionType = "(" +
				initializerDeclaration.parameters
					.map { $0.typeName }
					.joined(separator: ", ") +
				") -> " + enclosingType +
				(initializerDeclaration.isOptional ? "?" : "")
			if context.isUsingSwiftSyntax {
				initializerDeclaration.functionType = functionType
			}
			else {
				initializerDeclaration.functionType = "(\(enclosingType).Type) -> \(functionType)"
			}
		}

		return initializerDeclaration
	}

	override func replaceClassDeclaration( // gryphon annotation: override
		_ classDeclaration: ClassDeclaration)
		-> List<Statement>
	{
		typeDeclarationStack.append(classDeclaration.className)
		let result = super.replaceClassDeclaration(classDeclaration)
		typeDeclarationStack.removeLast()
		return result
	}

	override func replaceStructDeclaration( // gryphon annotation: override
		_ structDeclaration: StructDeclaration)
		-> List<Statement>
	{
		typeDeclarationStack.append(structDeclaration.structName)
		let result = super.replaceStructDeclaration(structDeclaration)
		typeDeclarationStack.removeLast()
		return result
	}

	override func replaceEnumDeclaration( // gryphon annotation: override
		_ enumDeclaration: EnumDeclaration)
		-> List<Statement>
	{
		typeDeclarationStack.append(enumDeclaration.enumName)
		let result = super.replaceEnumDeclaration(enumDeclaration)
		typeDeclarationStack.removeLast()
		return result
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
		-> List<Statement>
	{
		// TODO: replace this with a check for isOptional once SwiftSyntax is fully supported
		if (initializerDeclaration.isStatic == true &&
				initializerDeclaration.extendsType == nil &&
				initializerDeclaration.returnType.hasSuffix("?")) ||
			initializerDeclaration.isOptional
		{
			isFailableInitializer = true
			let newStatements = replaceStatements(initializerDeclaration.statements ?? [])
			isFailableInitializer = false

			// TODO: simplify this once SwiftSyntax is fully supported
			let newReturnType = initializerDeclaration.returnType.hasSuffix("?") ?
				initializerDeclaration.returnType :
				initializerDeclaration.returnType + "?"

			let result: MutableList<Statement> = [FunctionDeclaration(
				syntax: initializerDeclaration.syntax,
				range: initializerDeclaration.range,
				prefix: "invoke",
				parameters: initializerDeclaration.parameters,
				returnType: newReturnType,
				functionType: initializerDeclaration.functionType,
				genericTypes: initializerDeclaration.genericTypes,
				isOpen: initializerDeclaration.isOpen,
				isImplicit: initializerDeclaration.isImplicit,
				isStatic: initializerDeclaration.isStatic,
				isMutating: initializerDeclaration.isMutating,
				isPure: initializerDeclaration.isPure,
				isJustProtocolInterface: initializerDeclaration.isJustProtocolInterface,
				extendsType: initializerDeclaration.extendsType,
				statements: newStatements,
				access: initializerDeclaration.access,
				annotations: initializerDeclaration.annotations), ]

			return result
		}

		return super.replaceInitializerDeclaration(initializerDeclaration)
	}

	override func replaceAssignmentStatement( // gryphon annotation: override
		_ assignmentStatement: AssignmentStatement)
		-> List<Statement>
	{
		if isFailableInitializer,
			let expression = assignmentStatement.leftHand as? DeclarationReferenceExpression
		{
			if expression.identifier == "self" {
				return [ReturnStatement(
					syntax: assignmentStatement.syntax,
					range: assignmentStatement.range,
					expression: assignmentStatement.rightHand,
					label: nil), ]
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
			[CompanionObject(
				syntax: nil,
				range: range,
				members: staticMembers.toMutableList())]
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
		-> List<Statement>
	{
		let newMembers = sendStaticMembersToCompanionObject(
			classDeclaration.members,
			withRange: classDeclaration.range)
		return super.replaceClassDeclaration(ClassDeclaration(
			syntax: classDeclaration.syntax,
			range: classDeclaration.range,
			className: classDeclaration.className,
			annotations: classDeclaration.annotations,
			access: classDeclaration.access,
			isOpen: classDeclaration.isOpen,
			inherits: classDeclaration.inherits,
			members: newMembers))
	}

	override func replaceStructDeclaration( // gryphon annotation: override
		_ structDeclaration: StructDeclaration)
		-> List<Statement>
	{
		let newMembers = sendStaticMembersToCompanionObject(
			structDeclaration.members,
			withRange: structDeclaration.range)
		return super.replaceStructDeclaration(StructDeclaration(
			syntax: structDeclaration.syntax,
			range: structDeclaration.range,
			annotations: structDeclaration.annotations,
			structName: structDeclaration.structName,
			access: structDeclaration.access,
			inherits: structDeclaration.inherits,
			members: newMembers))
	}

	override func replaceEnumDeclaration( // gryphon annotation: override
		_ enumDeclaration: EnumDeclaration)
		-> List<Statement>
	{
		let newMembers = sendStaticMembersToCompanionObject(
			enumDeclaration.members,
			withRange: enumDeclaration.range)
		return super.replaceEnumDeclaration(EnumDeclaration(
			syntax: enumDeclaration.syntax,
			range: enumDeclaration.range,
			access: enumDeclaration.access,
			enumName: enumDeclaration.enumName,
			annotations: enumDeclaration.annotations,
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
		-> List<Statement>
	{
		typeNamesStack.append(classDeclaration.className)
		let result = super.replaceClassDeclaration(classDeclaration)
		typeNamesStack.removeLast()
		return result
	}

	override func replaceStructDeclaration( // gryphon annotation: override
		_ structDeclaration: StructDeclaration)
		-> List<Statement>
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
		if let typeAnnotation = variableDeclaration.typeAnnotation {
			variableDeclaration.typeAnnotation = removePrefixes(typeAnnotation)
		}

		return super.processVariableDeclaration(variableDeclaration)
	}

	override func replaceTypeExpression( // gryphon annotation: override
		_ typeExpression: TypeExpression)
		-> Expression
	{
		return TypeExpression(
			syntax: typeExpression.syntax,
			range: typeExpression.range,
			typeName: removePrefixes(typeExpression.typeName))
	}
}

/// Capitalizes references to enums (since enum cases in Kotlin are conventionally written in
/// capitalized forms)
public class CapitalizeEnumsTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	override func replaceTypeExpression( // gryphon annotation: override
		_ typeExpression: TypeExpression)
		-> Expression
	{
		let typeComponents = typeExpression.typeName.split(withStringSeparator: ".")

		if typeComponents.count == 2,
			self.context.sealedClasses.contains(typeComponents[0]) ||
				self.context.enumClasses.contains(typeComponents[0])
		{
			let newType = typeComponents[0] + "." + typeComponents[1].capitalizedAsCamelCase()
			return TypeExpression(
				syntax: typeExpression.syntax,
				range: typeExpression.range,
				typeName: newType)
		}

		return super.replaceTypeExpression(typeExpression)
	}

	override func replaceDotExpression( // gryphon annotation: override
		_ dotExpression: DotExpression)
		-> Expression
	{
		let enumType: String
		if !context.isUsingSwiftSyntax,
			let enumExpression = dotExpression.leftExpression as? TypeExpression
		{
			enumType = enumExpression.typeName
		}
		else if context.isUsingSwiftSyntax,
			let enumExpression = dotExpression.leftExpression as? DeclarationReferenceExpression
		{
			enumType = enumExpression.identifier
		}
		else {
			return super.replaceDotExpression(dotExpression)
		}

		if let enumExpression = dotExpression.rightExpression as? DeclarationReferenceExpression {
			// Enum types may need to be processed before they can be correctly interpreted
			// (i.e. they may be `List<MyEnum>.ArrayLiteralElement` instead of `MyEnum`
			let mappedEnumType = Utilities.getTypeMapping(for: enumType) ?? enumType
			let lastEnumType = String(mappedEnumType
				.split(withStringSeparator: ".")
				.last!)

			if self.context.sealedClasses.contains(lastEnumType) {
				enumExpression.identifier =
					enumExpression.identifier.capitalizedAsCamelCase()
				return DotExpression(
					syntax: dotExpression.syntax,
					range: dotExpression.range,
					leftExpression: TypeExpression(
						syntax: dotExpression.leftExpression.syntax,
						range: dotExpression.leftExpression.range,
						typeName: enumType),
					rightExpression: enumExpression)
			}
			else if self.context.enumClasses.contains(lastEnumType) {
				enumExpression.identifier = enumExpression.identifier.upperSnakeCase()
				return DotExpression(
					syntax: dotExpression.syntax,
					range: dotExpression.range,
					leftExpression: TypeExpression(
						syntax: dotExpression.leftExpression.syntax,
						range: dotExpression.leftExpression.range,
						typeName: enumType),
					rightExpression: enumExpression)
			}
		}

		return super.replaceDotExpression(dotExpression)
	}

	override func replaceEnumDeclaration( // gryphon annotation: override
		_ enumDeclaration: EnumDeclaration)
		-> List<Statement>
	{
		let isSealedClass =
			self.context.sealedClasses.contains(enumDeclaration.enumName)
		let isEnumClass = self.context.enumClasses.contains(enumDeclaration.enumName)

		let newElements: MutableList<EnumElement>
		if isSealedClass {
			newElements = enumDeclaration.elements.map { element in
				EnumElement(
					syntax: element.syntax,
					name: element.name.capitalizedAsCamelCase(),
					associatedValues: element.associatedValues,
					rawValue: element.rawValue,
					annotations: element.annotations)
			}.toMutableList()
		}
		else if isEnumClass {
			newElements = enumDeclaration.elements.map { element in
				EnumElement(
					syntax: element.syntax,
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
			syntax: enumDeclaration.syntax,
			range: enumDeclaration.range,
			access: enumDeclaration.access,
			enumName: enumDeclaration.enumName,
			annotations: enumDeclaration.annotations,
			inherits: enumDeclaration.inherits,
			elements: newElements,
			members: enumDeclaration.members,
			isImplicit: enumDeclaration.isImplicit))
	}
}

/// Some operators in Kotlin hae different symbols (or names) then they so in Swift, so this pass
/// renames them. Additionally, the Swift AST outputs `==` between enums as `__derived_enum_equals`,
/// so this pass is also used to rename that.
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
			"__derived_enum_equals": "==",
        ]
		if let operatorTranslation = operatorTranslations[binaryOperatorExpression.operatorSymbol] {
			return super.replaceBinaryOperatorExpression(BinaryOperatorExpression(
				syntax: binaryOperatorExpression.syntax,
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
		var firstSuperCall: CallExpression?
		let filteredStatements: MutableList<Statement> = []

		if let statements = initializerDeclaration.statements {
			for statement in statements {
				if let newSuperCall = getSuperCallFromStatement(statement) {
					if firstSuperCall != nil {
						// Swift doesn't allow more than one super call in an init's body's top
						// level, so this should technically be unreachable, but the warning is here
						// if it ever gets reached
						raiseMultipleSuperCallsWarning(forSuperCall: newSuperCall)
						return initializerDeclaration
					}
					else {
						firstSuperCall = newSuperCall
					}
				}
				else {
					// Keep all statements except super calls
					filteredStatements.append(statement)
				}
			}
		}

		let replacedStatements = replaceStatements(filteredStatements)

		if let superCall = firstSuperCall {
			return InitializerDeclaration(
				syntax: initializerDeclaration.syntax,
				range: initializerDeclaration.range,
				parameters: initializerDeclaration.parameters,
				returnType: initializerDeclaration.returnType,
				functionType: initializerDeclaration.functionType,
				genericTypes: initializerDeclaration.genericTypes,
				isOpen: initializerDeclaration.isOpen,
				isImplicit: initializerDeclaration.isImplicit,
				isStatic: initializerDeclaration.isStatic,
				isMutating: initializerDeclaration.isMutating,
				isPure: initializerDeclaration.isPure,
				extendsType: initializerDeclaration.extendsType,
				statements: replacedStatements,
				access: initializerDeclaration.access,
				annotations: initializerDeclaration.annotations,
				superCall: superCall,
				isOptional: initializerDeclaration.isOptional)
		}
		else {
			return initializerDeclaration
		}
	}

	override func replaceCallExpression( // gryphon annotation: override
		_ callExpression: CallExpression)
		-> Expression
	{
		if let superCall = getSuperCallFromCallExpression(callExpression) {
			raiseMultipleSuperCallsWarning(forSuperCall: superCall)
		}

		return super.replaceCallExpression(callExpression)
	}

	private func getSuperCallFromStatement(_ statement: Statement) -> CallExpression? {
		if let expressionStatement = statement as? ExpressionStatement {
			if let callExpression = expressionStatement.expression as? CallExpression {
				return getSuperCallFromCallExpression(callExpression)
			}
		}

		return nil
	}

	/// Check if a call expression if a super call. If it is, return it in a new format so that it
	/// can be put in the init's header.
	private func getSuperCallFromCallExpression(
		_ callExpression: CallExpression)
		-> CallExpression?
	{
		if let dotExpression = callExpression.function as? DotExpression {
			if let leftExpression = dotExpression.leftExpression as?
					DeclarationReferenceExpression,
				let rightExpression = dotExpression.rightExpression as?
					DeclarationReferenceExpression,
				leftExpression.identifier == "super",
				rightExpression.identifier == "init"
			{
				return CallExpression(
					syntax: callExpression.syntax,
					range: callExpression.range,
					function: leftExpression,
					parameters: callExpression.parameters,
					typeName: callExpression.typeName,
					allowsTrailingClosure: callExpression.allowsTrailingClosure)
			}
		}

		return nil
	}

	private func raiseMultipleSuperCallsWarning(forSuperCall superCall: CallExpression) {
		let message = "Kotlin only supports a single call to the superclass's " +
			"initializer"
		Compiler.handleWarning(
			message: message,
			syntax: superCall.syntax,
			sourceFile: ast.sourceFile,
			sourceFileRange: superCall.range)
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
			syntax: binaryOperatorExpression.syntax,
			range: binaryOperatorExpression.range,
			leftExpression: optionalExpression.expression,
			rightExpression: binaryOperatorExpression.rightExpression,
			operatorSymbol: "as?",
			typeName: binaryOperatorExpression.typeName)
	}
}

/// Declarations that can be overriden in Kotlin have to be marked as `open` to enable overriding,
/// or `final` to disable it. The default behavior is handled by SwiftTranslator, but users may
/// choose on a case-by-case basis using annotations. This pass removes `open` and `final`
/// annotations and sets the declaration's `isOpen` flag accordingly.
///
/// The precedence rules should be (more or less):
///   1. Annotations with "open" or "final"
///   2. Declarations translated as "private", which can't also be "open" in Kotlin.
///   3. Swift nodes that are always final (local variables, top-level variables, static members,
///       structs and enum members, etc)
///   4. Swift annotations (either the "final" annotation or the "open" access modifier)
///   5. If the invocation includes the `--default-final` option, what's left is final; otherwise,
///       it's open.
///
/// The SwiftTranslator handles numbers 4 and 5, and parts of 3 (i.e. static members are implicitly
/// annotated with final); this pass overwrites those results with numbers 1, 2, and 3 if needed.
///
public class OpenDeclarationsTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	var accessModifiersStack: MutableList<String?> = []

	private func topmostAccessModifierIsPrivate() -> Bool {
		for accessModifier in accessModifiersStack.reversed() {
			if let accessModifier = accessModifier {
				return (accessModifier == "private")
			}
		}

		// Kotlin defaults to "public", not "private"
		return false
	}

	override func replaceClassDeclaration( // gryphon annotation: override
		_ classDeclaration: ClassDeclaration)
		-> List<Statement>
	{
		accessModifiersStack.append(classDeclaration.access)

		let annotations = classDeclaration.annotations

		let isOpenResult: Bool
		let annotationsResult: MutableList<String>
		if annotations.contains("open") {
			isOpenResult = true
			annotationsResult = annotations.filter { $0 != "open" && $0 != "final" }.toMutableList()
		}
		else if annotations.contains("final") {
			isOpenResult = false
			annotationsResult = annotations.filter { $0 != "open" && $0 != "final" }.toMutableList()
		}
		else if topmostAccessModifierIsPrivate() {
			isOpenResult = false
			annotationsResult = annotations
		}
		else {
			isOpenResult = classDeclaration.isOpen
			annotationsResult = annotations
		}

		let result = super.replaceClassDeclaration(ClassDeclaration(
			syntax: classDeclaration.syntax,
			range: classDeclaration.range,
			className: classDeclaration.className,
			annotations: annotationsResult,
			access: classDeclaration.access,
			isOpen: isOpenResult,
			inherits: classDeclaration.inherits,
			members: classDeclaration.members))

		accessModifiersStack.removeLast()
		return result
	}

	override func replaceVariableDeclaration( // gryphon annotation: override
		_ variableDeclaration: VariableDeclaration)
		-> List<Statement>
	{
		accessModifiersStack.append(variableDeclaration.access)

		var annotationsResult = variableDeclaration.annotations

		let isOpenResult: Bool
		if annotationsResult.contains("open") {
			isOpenResult = true
			annotationsResult = annotationsResult
				.filter { $0 != "open" && $0 != "final" }
				.toMutableList()
		}
		else if annotationsResult.contains("final") {
			isOpenResult = false
			annotationsResult = annotationsResult
				.filter { $0 != "open" && $0 != "final" }
				.toMutableList()
		}
		else if topmostAccessModifierIsPrivate() {
			isOpenResult = false
		}
		else if let parent = parent,
			case let .statementNode(value: parentDeclaration) = parent
		{
			if parentDeclaration is ClassDeclaration {
				isOpenResult = variableDeclaration.isOpen
			}
			else if parentDeclaration is CompanionObject {
				// Static declarations are always final in Swift
				isOpenResult = false
			}
			else if parentDeclaration is StructDeclaration {
				// Struct members are always final in Swift
				isOpenResult = false
			}
			else if parentDeclaration is EnumDeclaration {
				// Enum members are always final in Swift
				isOpenResult = false
			}
			else {
				// Local variables have to be final
				isOpenResult = false
			}
		}
		else {
			// Top level declarations have to be final
			isOpenResult = false
		}

		variableDeclaration.isOpen = isOpenResult
		variableDeclaration.annotations = annotationsResult

		let result = super.replaceVariableDeclaration(variableDeclaration)
		accessModifiersStack.removeLast()
		return result
	}

	override func replaceFunctionDeclaration( // gryphon annotation: override
		_ functionDeclaration: FunctionDeclaration)
		-> List<Statement>
	{
		accessModifiersStack.append(functionDeclaration.access)

		var annotationsResult = functionDeclaration.annotations

		let isOpenResult: Bool
		if annotationsResult.contains("open") {
			isOpenResult = true
			annotationsResult = annotationsResult
				.filter { $0 != "open" && $0 != "final" }
				.toMutableList()
		}
		else if annotationsResult.contains("final") {
			isOpenResult = false
			annotationsResult = annotationsResult
				.filter { $0 != "open" && $0 != "final" }
				.toMutableList()
		}
		else if topmostAccessModifierIsPrivate() {
			isOpenResult = false
		}
		else if let parent = parent,
			case let .statementNode(value: parentDeclaration) = parent
		{
			if parentDeclaration is ClassDeclaration {
				isOpenResult = functionDeclaration.isOpen
			}
			else if parentDeclaration is CompanionObject {
				// Static declarations are always final in Swift
				isOpenResult = false
			}
			else if parentDeclaration is StructDeclaration {
				// Struct members are always final in Swift
				isOpenResult = false
			}
			else if parentDeclaration is EnumDeclaration {
				// Enum members are always final in Swift
				isOpenResult = false
			}
			else {
				// Any other functions will be final
				isOpenResult = false
			}
		}
		else {
			// Top level declarations have to be final
			isOpenResult = false
		}

		functionDeclaration.isOpen = isOpenResult
		functionDeclaration.annotations = annotationsResult

		let result = super.replaceFunctionDeclaration(functionDeclaration)
		accessModifiersStack.removeLast()
		return result
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
///
public class AccessModifiersTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	/// A stack containing access modifiers from parent declarations. Modifiers in this stack should
	/// already be processed.
	var accessModifiersStack: MutableList<String?> = []

	override func replaceClassDeclaration( // gryphon annotation: override
		_ classDeclaration: ClassDeclaration)
		-> List<Statement>
	{
		let translationResult = translateAccessModifierAndAnnotations(
			access: classDeclaration.access,
			annotations: classDeclaration.annotations,
			forDeclaration: classDeclaration)

		accessModifiersStack.append(translationResult.access)
		let result = super.replaceClassDeclaration(ClassDeclaration(
			syntax: classDeclaration.syntax,
			range: classDeclaration.range,
			className: classDeclaration.className,
			annotations: translationResult.annotations,
			access: translationResult.access,
			isOpen: classDeclaration.isOpen,
			inherits: classDeclaration.inherits,
			members: classDeclaration.members))
		accessModifiersStack.removeLast()
		return result
	}

	override func replaceStructDeclaration( // gryphon annotation: override
		_ structDeclaration: StructDeclaration)
		-> List<Statement>
	{
		let translationResult = translateAccessModifierAndAnnotations(
			access: structDeclaration.access,
			annotations: structDeclaration.annotations,
			forDeclaration: structDeclaration)

		accessModifiersStack.append(translationResult.access)
		let result = super.replaceStructDeclaration(StructDeclaration(
			syntax: structDeclaration.syntax,
			range: structDeclaration.range,
			annotations: translationResult.annotations,
			structName: structDeclaration.structName,
			access: translationResult.access,
			inherits: structDeclaration.inherits,
			members: structDeclaration.members))
		accessModifiersStack.removeLast()
		return result
	}

	override func replaceEnumDeclaration( // gryphon annotation: override
		_ enumDeclaration: EnumDeclaration)
		-> List<Statement>
	{
		let translationResult = translateAccessModifierAndAnnotations(
			access: enumDeclaration.access,
			annotations: enumDeclaration.annotations,
			forDeclaration: enumDeclaration)

		accessModifiersStack.append(translationResult.access)
		let result = super.replaceEnumDeclaration(EnumDeclaration(
			syntax: enumDeclaration.syntax,
			range: enumDeclaration.range,
			access: translationResult.access,
			enumName: enumDeclaration.enumName,
			annotations: translationResult.annotations,
			inherits: enumDeclaration.inherits,
			elements: enumDeclaration.elements,
			members: enumDeclaration.members,
			isImplicit: enumDeclaration.isImplicit))
		accessModifiersStack.removeLast()
		return result
	}

	override func replaceProtocolDeclaration( // gryphon annotation: override
		_ protocolDeclaration: ProtocolDeclaration)
		-> List<Statement>
	{
		let translationResult = translateAccessModifierAndAnnotations(
			access: protocolDeclaration.access,
			annotations: protocolDeclaration.annotations,
			forDeclaration: protocolDeclaration)

		// Push the non-existent "protocol" access modifier as a special marker so that inner
		// declarations will omit their own access modifiers. This is because declarations inside
		// a protocol always inherit the procotol's access modifier.
		accessModifiersStack.append("protocol")
		let result = super.replaceProtocolDeclaration(ProtocolDeclaration(
			syntax: protocolDeclaration.syntax,
			range: protocolDeclaration.range,
			protocolName: protocolDeclaration.protocolName,
			access: translationResult.access,
			annotations: translationResult.annotations,
			members: protocolDeclaration.members))
		accessModifiersStack.removeLast()
		return result
	}

	override func replaceVariableDeclaration( // gryphon annotation: override
		_ variableDeclaration: VariableDeclaration)
		-> List<Statement>
	{
		let translationResult = translateAccessModifierAndAnnotations(
			access: variableDeclaration.access,
			annotations: variableDeclaration.annotations,
			forDeclaration: variableDeclaration)

		// Use explicit access modifiers only when they were specified in the annotations, when it's
		// a top-level variable, or when it's a property.
		// Otherwise, assume it's a local variable, which can't have explicit access modifiers.
		if translationResult.didUseAnnotations || isTopLevelNode || thisVariableIsAProperty() {
			accessModifiersStack.append(translationResult.access)
			let result = super.replaceVariableDeclaration(VariableDeclaration(
				syntax: variableDeclaration.syntax,
				range: variableDeclaration.range,
				identifier: variableDeclaration.identifier,
				typeAnnotation: variableDeclaration.typeAnnotation,
				expression: variableDeclaration.expression,
				getter: variableDeclaration.getter,
				setter: variableDeclaration.setter,
				access: translationResult.access,
				isOpen: variableDeclaration.isOpen,
				isLet: variableDeclaration.isLet,
				isImplicit: variableDeclaration.isImplicit,
				isStatic: variableDeclaration.isStatic,
				extendsType: variableDeclaration.extendsType,
				annotations: translationResult.annotations))
			accessModifiersStack.removeLast()
			return result
		}
		else {
			return super.replaceVariableDeclaration(VariableDeclaration(
				syntax: variableDeclaration.syntax,
				range: variableDeclaration.range,
				identifier: variableDeclaration.identifier,
				typeAnnotation: variableDeclaration.typeAnnotation,
				expression: variableDeclaration.expression,
				getter: variableDeclaration.getter,
				setter: variableDeclaration.setter,
				access: nil,
				isOpen: variableDeclaration.isOpen,
				isLet: variableDeclaration.isLet,
				isImplicit: variableDeclaration.isImplicit,
				isStatic: variableDeclaration.isStatic,
				extendsType: variableDeclaration.extendsType,
				annotations: variableDeclaration.annotations))
		}
	}

	override func replaceFunctionDeclaration( // gryphon annotation: override
		_ functionDeclaration: FunctionDeclaration)
		-> List<Statement>
	{
		let translationResult = translateAccessModifierAndAnnotations(
			access: functionDeclaration.access,
			annotations: functionDeclaration.annotations,
			forDeclaration: functionDeclaration)

		accessModifiersStack.append(translationResult.access)
		let result = super.replaceFunctionDeclaration(FunctionDeclaration(
			syntax: functionDeclaration.syntax,
			range: functionDeclaration.range,
			prefix: functionDeclaration.prefix,
			parameters: functionDeclaration.parameters,
			returnType: functionDeclaration.returnType,
			functionType: functionDeclaration.functionType,
			genericTypes: functionDeclaration.genericTypes,
			isOpen: functionDeclaration.isOpen,
			isImplicit: functionDeclaration.isImplicit,
			isStatic: functionDeclaration.isStatic,
			isMutating: functionDeclaration.isMutating,
			isPure: functionDeclaration.isPure,
			isJustProtocolInterface: functionDeclaration.isJustProtocolInterface,
			extendsType: functionDeclaration.extendsType,
			statements: functionDeclaration.statements,
			access: translationResult.access,
			annotations: translationResult.annotations))
		accessModifiersStack.removeLast()
		return result
	}

	override func replaceTypealiasDeclaration( // gryphon annotation: override
		_ typealiasDeclaration: TypealiasDeclaration)
		-> List<Statement>
	{
		let newAccess = getAccessModifier(
			forModifier: typealiasDeclaration.access,
			declaration: typealiasDeclaration)

		accessModifiersStack.append(newAccess)
		let result = super.replaceTypealiasDeclaration(TypealiasDeclaration(
			syntax: typealiasDeclaration.syntax,
			range: typealiasDeclaration.range,
			identifier: typealiasDeclaration.identifier,
			typeName: typealiasDeclaration.typeName,
			access: newAccess,
			isImplicit: typealiasDeclaration.isImplicit))
		accessModifiersStack.removeLast()
		return result
	}

	override func replaceInitializerDeclaration( // gryphon annotation: override
		_ initializerDeclaration: InitializerDeclaration)
		-> List<Statement>
	{
		let translationResult = translateAccessModifierAndAnnotations(
			access: initializerDeclaration.access,
			annotations: initializerDeclaration.annotations,
			forDeclaration: initializerDeclaration)

		accessModifiersStack.append(translationResult.access)
		let result = super.replaceInitializerDeclaration(InitializerDeclaration(
			syntax: initializerDeclaration.syntax,
			range: initializerDeclaration.range,
			parameters: initializerDeclaration.parameters,
			returnType: initializerDeclaration.returnType,
			functionType: initializerDeclaration.functionType,
			genericTypes: initializerDeclaration.genericTypes,
			isOpen: initializerDeclaration.isOpen,
			isImplicit: initializerDeclaration.isImplicit,
			isStatic: initializerDeclaration.isStatic,
			isMutating: initializerDeclaration.isMutating,
			isPure: initializerDeclaration.isPure,
			extendsType: initializerDeclaration.extendsType,
			statements: initializerDeclaration.statements,
			access: translationResult.access,
			annotations: translationResult.annotations,
			superCall: initializerDeclaration.superCall,
			isOptional: initializerDeclaration.isOptional))
		accessModifiersStack.removeLast()
		return result
	}

	/// The result of translating an access modifier. Contains the translated access modifier, which
	/// may have reuslted from an access modifier in an annotation; the remaining annotations, or
	/// nil if there are none; and a flag indicating if an access modifier was taken from the
	/// annotations.
	struct AccessTranslationResult {
		let access: String?
		let annotations: MutableList<String>
		let didUseAnnotations: Bool
	}

	private func translateAccessModifierAndAnnotations(
		access: String?,
		annotations: MutableList<String>,
		forDeclaration declaration: Statement)
		-> AccessTranslationResult
	{
		let accessResult: String?
		let annotationsResult: MutableList<String>
		let didUseAnnotations: Bool

		let explicitAccessModifiers = annotations.filter { isKotlinAccessModifier($0) }

		if let explicitAccessModifier = explicitAccessModifiers.first {
			accessResult = explicitAccessModifier
			annotationsResult = annotations
				.filter { !isKotlinAccessModifier($0) }
				.toMutableList()
			didUseAnnotations = true
		}
		else {
			accessResult = getAccessModifier(
				forModifier: access,
				declaration: declaration)
			annotationsResult = annotations
			didUseAnnotations = false
		}

		return AccessTranslationResult(
			access: accessResult,
			annotations: annotationsResult,
			didUseAnnotations: didUseAnnotations)
	}

	private func isKotlinAccessModifier(_ modifier: String) -> Bool {
		return (modifier == "public") ||
			(modifier == "internal") ||
			(modifier == "protected") ||
			(modifier == "private")
	}

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
			let innerModifier = swiftModifier
			var outerModifier = accessModifiersStack.compactMap { $0 }.last

			// Access modifiers can be manually specified to be "protected" using annotations. Since
			// Swift modifiers can never be automatically translated as "protected", this algorithm
			// can treat "protected" as the next most restrictive option, which is "private".
			if outerModifier == "protected" {
				outerModifier = "private"
			}

			// The "protocol" string is used as a special value when we're translating members of a
			// protocol (which should never have explicit access modifiers).
			if outerModifier == "protocol" {
				return nil
			}

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

			if (outerModifier == nil) || (outerModifier! == "public") {
				// If the outer is public, we can only explicitly be internal or private
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

	/// To be used inside a replaceVariableDeclaration or processVariableDeclaration method only.
	/// Returns true if the variable is a property, false if it's a local variable or anything else.
	func thisVariableIsAProperty() -> Bool {
		if let parent = parent,
			case let .statementNode(value: parentDeclaration) = parent
		{
			if (parentDeclaration is ClassDeclaration) ||
				(parentDeclaration is CompanionObject) ||
				(parentDeclaration is StructDeclaration) ||
				(parentDeclaration is EnumDeclaration)
			{
				return true
			}
		}

		return false
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
			syntax: declaration.syntax,
			sourceFile: ast.sourceFile,
			sourceFileRange: declaration.range)
	}

	private func raiseAlgorithmErrorWarning(forDeclaration declaration: Statement) {
		let message = "Failed to calculate the correct access modifier. Defaulting to \"public\"."
		Compiler.handleWarning(
			message: message,
			syntax: declaration.syntax,
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
		_ declarationReferenceExpression: DeclarationReferenceExpression)
		-> DeclarationReferenceExpression
	{
		if declarationReferenceExpression.identifier == "self" {
			declarationReferenceExpression.identifier = "this"
			return declarationReferenceExpression
		}
		return super.processDeclarationReferenceExpression(declarationReferenceExpression)
	}
}

/// Declarations can't conform to Swift-only protocols like Codable and Equatable, and enums can't
/// inherit from types Strings and Ints.
public class CleanInheritancesTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	override func replaceEnumDeclaration( // gryphon annotation: override
		_ enumDeclaration: EnumDeclaration)
		-> List<Statement>
	{
		return super.replaceEnumDeclaration(EnumDeclaration(
			syntax: enumDeclaration.syntax,
			range: enumDeclaration.range,
			access: enumDeclaration.access,
			enumName: enumDeclaration.enumName,
			annotations: enumDeclaration.annotations,
			inherits: enumDeclaration.inherits.filter {
					!TranspilationPass.isASwiftProtocol($0) &&
						!TranspilationPass.isASwiftRawRepresentableType($0)
				}.toMutableList(),
			elements: enumDeclaration.elements,
			members: enumDeclaration.members,
			isImplicit: enumDeclaration.isImplicit))
	}

	override func replaceStructDeclaration( // gryphon annotation: override
		_ structDeclaration: StructDeclaration)
		-> List<Statement>
	{
		return super.replaceStructDeclaration(StructDeclaration(
			syntax: structDeclaration.syntax,
			range: structDeclaration.range,
			annotations: structDeclaration.annotations,
			structName: structDeclaration.structName,
			access: structDeclaration.access,
			inherits: structDeclaration.inherits
				.filter { !TranspilationPass.isASwiftProtocol($0) }
				.toMutableList(),
			members: structDeclaration.members))
	}

	override func replaceClassDeclaration( // gryphon annotation: override
		_ classDeclaration: ClassDeclaration)
		-> List<Statement>
	{
		return super.replaceClassDeclaration(ClassDeclaration(
			syntax: classDeclaration.syntax,
			range: classDeclaration.range,
			className: classDeclaration.className,
			annotations: classDeclaration.annotations,
			access: classDeclaration.access,
			isOpen: classDeclaration.isOpen,
			inherits: classDeclaration.inherits
				.filter { !TranspilationPass.isASwiftProtocol($0) }
				.toMutableList(),
			members: classDeclaration.members))
	}
}

/// Variables with an optional type don't have to be explicitly initialized with `nil` in Swift,
/// (though it happens implicitly), but they might in Kotlin.
public class ImplicitNilsInOptionalVariablesTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	override func processVariableDeclaration( // gryphon annotation: override
		_ variableDeclaration: VariableDeclaration)
		-> VariableDeclaration
	{
		if !variableDeclaration.isLet,
			variableDeclaration.expression == nil,
			let typeName = variableDeclaration.typeAnnotation,
			typeName.hasSuffix("?")
		{
			variableDeclaration.expression = NilLiteralExpression(
				syntax: variableDeclaration.syntax,
				range: nil)
		}

		return variableDeclaration
	}
}

/// The "anonymous parameter" `$0` has to be replaced by `it`
public class AnonymousParametersTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	override func processDeclarationReferenceExpression( // gryphon annotation: override
		_ declarationReferenceExpression: DeclarationReferenceExpression)
		-> DeclarationReferenceExpression
	{
		if declarationReferenceExpression.identifier == "$0" {
			declarationReferenceExpression.identifier = "it"
			return declarationReferenceExpression
		}
		else {
			return super.processDeclarationReferenceExpression(declarationReferenceExpression)
		}
	}

	// TODO: Remove this if possible after SwiftSyntax
	override func replaceClosureExpression( // gryphon annotation: override
		_ closureExpression: ClosureExpression)
		-> Expression
	{
		if closureExpression.parameters.count == 1,
			closureExpression.parameters[0].label == "$0"
		{
			return super.replaceClosureExpression(ClosureExpression(
				syntax: closureExpression.syntax,
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

/// Gryphon's collections aren't defined within the compiler, so they can't take advantage of
/// checked casts for covariant types. Because of that, casts have to be checked at runtime. This is
/// done using the `as` and `forceCast` method from the GryphonSwiftLibrary, which translate to the
/// `cast(Mutable)(OrNull)` methods from the GryphonKotlinLibrary. The type signature of the Swift
/// and Kotlin versions is different, so this pass is used to perform the translation.
/// Additionally, Gryphon uses initializers (i.e. `MutableList<Int>(array)`) to turn native Swift
/// sequences into MutableLists etc. These initializer calls are translated here to `toMutableList`
/// etc. All calls to these initializers are translated, even if the translation is redundant, since
/// we cannot always know if the call is redundant or not.
public class CovarianceInitsAsCallsTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	override func replaceCallExpression( // gryphon annotation: override
		_ callExpression: CallExpression)
		-> Expression
	{
		// Deal with cases where an initializer is used directly (i.e. `MutableList<Int>(array)`)
		if let typeExpression = callExpression.function as? TypeExpression,
			let tupleExpression = callExpression.parameters as? TupleExpression
		{
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

				return DotExpression(
					syntax: callExpression.syntax,
					range: callExpression.range,
					leftExpression: replaceExpression(onlyPair.expression),
					rightExpression: CallExpression(
						syntax: callExpression.syntax,
						range: callExpression.range,
						function: DeclarationReferenceExpression(
							syntax: callExpression.syntax,
							range: callExpression.range,
							identifier: "\(functionName)<\(mappedGenericString)>",
							typeName: typeExpression.typeName,
							isStandardLibrary: false,
							isImplicit: false),
						parameters: TupleExpression(
							syntax: callExpression.syntax,
							range: callExpression.range,
							pairs: []),
						typeName: typeExpression.typeName,
						allowsTrailingClosure: callExpression.allowsTrailingClosure))
			}
		}

		// Deal with cases where the casting method is called (i.e. `list.as(List<Int>.self)`)
		if let dotExpression = callExpression.function as? DotExpression {
			if let leftType = dotExpression.leftExpression.swiftType,
				(leftType.hasPrefix("MutableList") ||
					leftType.hasPrefix("List") ||
					leftType.hasPrefix("MutableMap") ||
					leftType.hasPrefix("Map")),
				let rightExpression =
					dotExpression.rightExpression as? DeclarationReferenceExpression,
				let tupleExpression = callExpression.parameters as? TupleExpression
			{
				if (rightExpression.identifier == "as" ||
					rightExpression.identifier.hasPrefix("forceCast")),
					tupleExpression.pairs.count == 1,
					let onlyPair = tupleExpression.pairs.first
				{
					let methodSuffix = (rightExpression.identifier.hasPrefix("forceCast")) ?
						"" :
						"OrNull"

					let maybeTypeExpression: TypeExpression?
					if context.isUsingSwiftSyntax,
						let dotTypeExpression = onlyPair.expression as? DotExpression,
						let leftTypeExpression = dotTypeExpression.leftExpression as? TypeExpression
					{
						maybeTypeExpression = leftTypeExpression
					}
					else if let typeExpression = onlyPair.expression as? TypeExpression {
						maybeTypeExpression = typeExpression
					}
					else {
						maybeTypeExpression = nil
					}

					if let typeExpression = maybeTypeExpression {
						let methodPrefix: String
						let castedGenerics: String
						if typeExpression.typeName.hasPrefix("List<") {
							methodPrefix = "cast" + methodSuffix
							castedGenerics = String(
								typeExpression.typeName.dropFirst("List<".count).dropLast())
						}
						else if typeExpression.typeName.hasPrefix("MutableList<") {
							methodPrefix = "castMutable" + methodSuffix
							castedGenerics = String(
								typeExpression.typeName.dropFirst("MutableList<".count).dropLast())
						}
						else if typeExpression.typeName.hasPrefix("Map<") {
							methodPrefix = "cast" + methodSuffix
							castedGenerics = String(
								typeExpression.typeName.dropFirst("Map<".count).dropLast())
						}
						else if typeExpression.typeName.hasPrefix("MutableMap<") {
							methodPrefix = "castMutable" + methodSuffix
							castedGenerics = String(
								typeExpression.typeName.dropFirst("MutableMap<".count).dropLast())
						}
						else {
							return super.replaceCallExpression(callExpression)
						}

						let castedGenericTypes = Utilities.splitTypeList(castedGenerics)
						let fullMethodName =
							"\(methodPrefix)<\(castedGenericTypes.joined(separator: ", "))>"

						return CallExpression(
							syntax: callExpression.syntax,
							range: callExpression.range,
							function: DotExpression(
								syntax: dotExpression.syntax,
								range: dotExpression.range,
								leftExpression: dotExpression.leftExpression,
								rightExpression: DeclarationReferenceExpression(
									syntax: rightExpression.syntax,
									range: rightExpression.range,
									identifier: fullMethodName,
									typeName: rightExpression.typeName,
									isStandardLibrary: rightExpression.isStandardLibrary,
									isImplicit: rightExpression.isImplicit)),
							parameters: TupleExpression(
								syntax: tupleExpression.syntax,
								range: tupleExpression.range,
								pairs: []),
							typeName: callExpression.typeName,
							allowsTrailingClosure: callExpression.allowsTrailingClosure)
					}
				}
			}
		}

		return super.replaceCallExpression(callExpression)
	}
}

/// Optional function calls like `foo?()` have to be translated to Kotlin as `foo?.invoke()`.
public class OptionalFunctionCallsTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	override func processCallExpression( // gryphon annotation: override
		_ callExpression: CallExpression)
		-> CallExpression
	{
		if callExpression.function is OptionalExpression {
			return CallExpression(
				syntax: callExpression.syntax,
				range: callExpression.range,
				function: DotExpression(
					syntax: callExpression.syntax,
					range: callExpression.range,
					leftExpression: callExpression.function,
					rightExpression: DeclarationReferenceExpression(
						syntax: callExpression.syntax,
						range: callExpression.range,
						identifier: "invoke",
						typeName: callExpression.function.swiftType ?? "<<Error>>",
						isStandardLibrary: false,
						isImplicit: false)),
				parameters: callExpression.parameters,
				typeName: callExpression.typeName,
				allowsTrailingClosure: callExpression.allowsTrailingClosure)
		}
		else {
			return super.processCallExpression(callExpression)
		}
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
				syntax: callExpression.syntax,
				range: callExpression.range,
				function: DeclarationReferenceExpression(
					syntax: callExpression.syntax,
					range: callExpression.range,
					identifier: "\(functionName)<\(genericElements)>",
					typeName: typeName,
					isStandardLibrary: false,
					isImplicit: false),
				parameters: parameters,
				typeName: typeName,
				allowsTrailingClosure: callExpression.allowsTrailingClosure)
		}

		return super.replaceCallExpression(callExpression)
	}
}

/// Closures in kotlin can't have normal "return" statements. Instead, they must have `return@f`
/// statements (with labels) or just standalone expressions. This pass turns return statements in
/// closures into standalone expressions where possible, and adds labels in other cases.
/// Labels can be added automatically by using the calling function's name. If there's more than one
/// function with that name on the stack (i.e. two nested `map`s), Kotlin raises a warning but
/// returns to the topmost closure, which is the same behavior as Swift.
public class ReturnsInLambdasTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	/// Stores the names of all functions that called are "currently being called".
	/// For instance, if we're inside `f( a.filter { b.map { ... } })`, this contains
	/// `["f", "filter", "map"]`.
	var labelsStack: MutableList<String> = []

	override func replaceCallExpression( // gryphon annotation: override
		_ callExpression: CallExpression)
		-> Expression
	{
		if let label = getLabelForFunction(callExpression.function) {
			labelsStack.append(label)
			let result = super.replaceCallExpression(callExpression)
			labelsStack.removeLast()
			return result
		}
		else {
			return super.replaceCallExpression(callExpression)
		}
	}

	func getLabelForFunction(_ functionExpression: Expression) -> String? {
		if let declarationReferenceExpression =
			functionExpression as? DeclarationReferenceExpression
		{
			let functionName = declarationReferenceExpression.identifier // `foo(arg:)`
			let functionPrefix = String(functionName.prefix(while: { $0 != "(" }))
			return functionPrefix
		}
		else if let dotExpression = functionExpression as? DotExpression {
			return getLabelForFunction(dotExpression.rightExpression)
		}
		else if let typeExpression = functionExpression as? TypeExpression {
			return typeExpression.typeName
		}
		else if let literalCodeExpression = functionExpression as? LiteralCodeExpression {
			return literalCodeExpression.string
		}
		else {
			Compiler.handleWarning(
				message: "Unable to get label for function.",
				syntax: functionExpression.syntax,
				sourceFile: ast.sourceFile,
				sourceFileRange: functionExpression.range)
			return nil
		}
	}

	override func replaceClosureExpression( // gryphon annotation: override
		_ closureExpression: ClosureExpression)
		-> Expression
	{
		// If it's a single-expression closure, omit the return
		if closureExpression.statements.count == 1 {
			if let returnStatement = closureExpression.statements[0] as? ReturnStatement {
				if let expression = returnStatement.expression {
					let newStatements: MutableList<Statement> = [ExpressionStatement(
						syntax: returnStatement.syntax,
						range: returnStatement.range,
						expression: expression), ]
					return super.replaceClosureExpression(ClosureExpression(
						syntax: closureExpression.syntax,
						range: closureExpression.range,
						parameters: closureExpression.parameters,
						statements: newStatements,
						typeName: closureExpression.typeName))
				}
			}
			else if let switchStatement = closureExpression.statements[0] as? SwitchStatement {
				// If it's a switch that's gonna become a return, remove the return and let the
				// resulting `when` be a standalone expression
				if let conversionExpression = switchStatement.convertsToExpression,
					conversionExpression is ReturnStatement
				{
					let newSwitchStatement = SwitchStatement(
						syntax: switchStatement.syntax,
						range: switchStatement.range,
						convertsToExpression: nil,
						expression: switchStatement.expression,
						cases: switchStatement.cases)
					return super.replaceClosureExpression(ClosureExpression(
						syntax: closureExpression.syntax,
						range: closureExpression.range,
						parameters: closureExpression.parameters,
						statements: [newSwitchStatement],
						typeName: closureExpression.typeName))
				}
			}
		}

		// Otherwise, add labels to any returns
		return super.replaceClosureExpression(closureExpression)
	}

	override func replaceReturnStatement( // gryphon annotation: override
		_ returnStatement: ReturnStatement)
		-> List<Statement>
	{
		return super.replaceReturnStatement(ReturnStatement(
			syntax: returnStatement.syntax,
			range: returnStatement.range,
			expression: returnStatement.expression.map { replaceExpression($0) },
			label: labelsStack.last))
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
			return super.replaceTupleExpression(tupleExpression)
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
		guard let types = maybeTypes.as(List<String>.self) else {
			return tupleExpression
		}
		let pairType = "Pair<\(types.joined(separator: ", "))>"

		return CallExpression(
			syntax: tupleExpression.syntax,
			range: tupleExpression.range,
			function: TypeExpression(
				syntax: tupleExpression.syntax,
				range: tupleExpression.range,
				typeName: pairType),
			parameters: TupleExpression(
				syntax: tupleExpression.syntax,
				range: tupleExpression.range,
				pairs: [
					LabeledExpression(
						label: nil,
						expression: tupleExpression.pairs[0].expression),
					LabeledExpression(
						label: nil,
						expression: tupleExpression.pairs[1].expression),
			]),
			typeName: pairType,
			allowsTrailingClosure: false)
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

		// Only Pairs are supported for now
		guard tupleComponents.count == 2 else {
			return super.replaceDotExpression(dotExpression)
		}

		// Key-value tuples are assumed to be from dictionaries (as a special case)
		guard !(tupleComponents[0].hasPrefix("key:") && tupleComponents[1].hasPrefix("value:"))
			else
		{
			return super.replaceDotExpression(dotExpression)
		}

		// Get the index of the member we're referencing
		let tupleMemberIndex: Int
		if let index = Int(memberExpression.identifier) {
			// If it's a tuple without labels (e.g. `(Int, Int)` and `tuple.0`)
			tupleMemberIndex = index
		}
		else if let index = tupleComponents.firstIndex(where:
			{ $0.split(withStringSeparator: ":").first == memberExpression.identifier })
		{
			// If the right expression refers to one of the tuple's named components
			tupleMemberIndex = index
		}
		else {
			return super.replaceDotExpression(dotExpression)
		}

		let newIdentifier = (tupleMemberIndex == 0) ? "first" : "second"

		return DotExpression(
			syntax: dotExpression.syntax,
			range: dotExpression.range,
			leftExpression: dotExpression.leftExpression,
			rightExpression: DeclarationReferenceExpression(
				syntax: memberExpression.syntax,
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

		if let tupleExpression = callExpression.parameters as? TupleExpression {
			for index in tupleExpression.pairs.indices {
				let pair = tupleExpression.pairs[index]
				let expression = pair.expression
				let parameterType = parameterTypes[index]

				if parameterType.hasPrefix("@autoclosure") {
					let newExpression = ClosureExpression(
						syntax: expression.syntax,
						range: expression.range,
						parameters: [],
						statements: [ExpressionStatement(
							syntax: expression.syntax,
							range: expression.range,
							expression: expression), ],
						typeName: parameterType)

					tupleExpression.pairs[index] = LabeledExpression(
						label: pair.label,
						expression: newExpression)
				}
			}
		}
		else if let tupleShuffleExpression = callExpression.parameters as? TupleShuffleExpression {
			for index in tupleShuffleExpression.expressions.indices {
				let expression = tupleShuffleExpression.expressions[index]
				let parameterType = parameterTypes[index]

				if parameterType.hasPrefix("@autoclosure") {
					let newExpression = ClosureExpression(
						syntax: expression.syntax,
						range: expression.range,
						parameters: [],
						statements: [ExpressionStatement(
							syntax: expression.syntax,
							range: expression.range,
							expression: expression), ],
						typeName: parameterType)

					tupleShuffleExpression.expressions[index] = newExpression
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

			let returnType: String
			if context.isUsingSwiftSyntax, subscriptExpression.typeName.hasSuffix("?") {
				returnType = String(subscriptExpression.typeName.dropLast())
			}
			else {
				returnType = subscriptExpression.typeName
			}

			return replaceDotExpression(DotExpression(
				syntax: subscriptExpression.syntax,
				range: subscriptExpression.range,
				leftExpression: subscriptExpression.subscriptedExpression,
				rightExpression: CallExpression(
					syntax: subscriptExpression.subscriptedExpression.syntax,
					range: subscriptExpression.subscriptedExpression.range,
					function: DeclarationReferenceExpression(
						syntax: subscriptExpression.subscriptedExpression.syntax,
						range: subscriptExpression.subscriptedExpression.range,
						identifier: "get",
						typeName: "\(indexExpressionType) -> \(returnType)",
						isStandardLibrary: false,
						isImplicit: false),
					parameters: subscriptExpression.indexExpression,
					typeName: subscriptExpression.typeName,
					allowsTrailingClosure: false)))
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
					syntax: dotExpression.syntax,
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
				syntax: dotExpression.syntax,
				range: dotExpression.range,
				leftExpression: processedLeftExpression,
				rightExpression: OptionalExpression(
					syntax: dotExpression.rightExpression.syntax,
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
		-> List<Statement>
	{
		var hasAllReturnCases = true
		var hasAllAssignmentCases = true
		var assignmentExpression: Expression?

		for statements in switchStatement.cases.map({ $0.statements }) {
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
						let newStatements = switchCase.statements.dropLast().toMutableList()
						newStatements.append(ExpressionStatement(
							syntax: returnExpression.syntax,
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
					syntax: switchStatement.syntax,
					range: switchStatement.range,
					expression: NilLiteralExpression(
						syntax: switchStatement.syntax,
						range: switchStatement.range),
					label: nil)
			return [SwitchStatement(
				syntax: switchStatement.syntax,
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
					let newStatements = switchCase.statements.dropLast().toMutableList()
					newStatements.append(ExpressionStatement(
						syntax: assignmentStatement.rightHand.syntax,
						range: assignmentStatement.rightHand.range,
						expression: assignmentStatement.rightHand))
					newCases.append(SwitchCase(
						expressions: switchCase.expressions,
						statements: newStatements))
				}
			}
			let conversionExpression = AssignmentStatement(
				syntax: switchStatement.syntax,
				range: switchStatement.range,
				leftHand: assignmentExpression,
				rightHand: NilLiteralExpression(
					syntax: switchStatement.syntax,
					range: switchStatement.range))
			return [SwitchStatement(
				syntax: switchStatement.syntax,
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
		_ statements: MutableList<Statement>)
		-> MutableList<Statement>
	{
		let newStatements = super.replaceStatements(statements)

		let result: MutableList<Statement> = []

		var i = 0
		while i < (newStatements.count - 1) {
			let currentStatement = newStatements[i]
			let nextStatement = newStatements[i + 1]
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
								syntax: switchStatement.syntax,
								range: switchStatement.range)
							variableDeclaration.getter = nil
							variableDeclaration.setter = nil
							variableDeclaration.isStatic = false
							let newConversionExpression = variableDeclaration
							result.append(SwitchStatement(
								syntax: switchStatement.syntax,
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

		// If the last statement was a switch that became an expression, we skipped it on purpose
		// by adding 2 to i, so i will be the statements count. Otherwise, we have to process
		// the last statement now (and i will be the count minus 1).
		if i != newStatements.count {
			if let lastStatement = newStatements.last {
				result.append(lastStatement)
			}
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
		-> List<Statement>
	{
		let newCases = switchStatement.cases.compactMap { removeBreaksInSwitchCase($0) }

		return super.replaceSwitchStatement(SwitchStatement(
			syntax: switchStatement.syntax,
			range: switchStatement.range,
			convertsToExpression: switchStatement.convertsToExpression,
			expression: switchStatement.expression,
			cases: newCases.toMutableList()))
	}

	private func removeBreaksInSwitchCase(_ switchCase: SwitchCase) -> SwitchCase {
		let statements = switchCase.statements.prefix {
			!($0 is BreakStatement)
		}
		switchCase.statements = statements.toMutableList()
		return switchCase
	}
}

/// Sealed classes should be tested for subclasses in switches with the `is` operator. This is
/// automatically done for enum cases with associated values, but in other cases it has to be
/// handled here.
public class IsOperatorsInSwitchesTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	override func replaceSwitchStatement( // gryphon annotation: override
		_ switchStatement: SwitchStatement)
		-> List<Statement>
	{
		if let declarationReferenceExpression =
				switchStatement.expression as? DeclarationReferenceExpression,
			let declarationType = declarationReferenceExpression.typeName
		{
			if self.context.sealedClasses.contains(declarationType) {
				let newCases = switchStatement.cases.map {
					replaceIsOperatorsInSwitchCase($0, usingExpression: switchStatement.expression)
				}

				return super.replaceSwitchStatement(SwitchStatement(
					syntax: switchStatement.syntax,
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
					syntax: dotExpression.syntax,
					range: dotExpression.range,
					leftExpression: expression,
					rightExpression: TypeExpression(
						syntax: typeExpression.syntax,
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

/// When translating an if-case, sealed classes should result in an `is` comparison, but enum
/// classes should result in an `==` comparison. This pass assumes all if-case comparisons arrive
/// here as an `is` comparison, meaning sealed classes are already correct but enum classes have to
/// change.
public class IsOperatorsInIfStatementsTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	override func replaceIfCondition( // gryphon annotation: override
		_ condition: IfStatement.IfCondition)
		-> IfStatement.IfCondition
	{
		if case let .condition(expression: expression) = condition {
			if let binaryExpression = expression as? BinaryOperatorExpression {
				if binaryExpression.operatorSymbol == "is",
					let typeExpression = binaryExpression.rightExpression as? TypeExpression
				{
					// Type expression is currently "MyEnum.enumCase". Separate it so we can
					// check if the enum is in the context.
					let enumName = typeExpression.typeName.split(withStringSeparator: ".")[0]

					// If it's an enum class, change it from "is" to "=="
					if self.context.enumClasses.contains(enumName) {
						return .condition(expression: BinaryOperatorExpression(
							syntax: binaryExpression.syntax,
							range: binaryExpression.range,
							leftExpression: binaryExpression.leftExpression,
							rightExpression: binaryExpression.rightExpression,
							operatorSymbol: "==",
							typeName: binaryExpression.typeName))
					}
				}
			}
		}

		return condition
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

	override func replaceFunctionDeclaration( // gryphon annotation: override
		_ functionDeclaration: FunctionDeclaration)
		-> List<Statement>
	{
		functionDeclaration.extendsType = self.extendingType
		return [functionDeclaration]
	}

	override func processVariableDeclaration( // gryphon annotation: override
		_ variableDeclaration: VariableDeclaration)
		-> VariableDeclaration
	{
		// If this variable is in a generic context, we should have detected it earlier in the Swift
		// Translator and put the information in the extendingType to preserve it. If the variable
		// is not in an extension (i.e. if it's in a generic class), we remove the extending type
		// here.
		// The variableDeclaration will contain `Box<T>`, and the extending type will contain simply
		// `Box`.
		if let extensionType = self.extendingType {
			if let typeWithGenerics = variableDeclaration.extendsType,
				typeWithGenerics.contains("<"),
				typeWithGenerics.hasPrefix(extensionType)
			{
				return variableDeclaration
			}
			else {
				variableDeclaration.extendsType = self.extendingType
				return variableDeclaration
			}
		}
		else {
			variableDeclaration.extendsType = nil
			return variableDeclaration
		}
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
										syntax: binaryOperator.syntax,
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
			syntax: ifStatement.syntax,
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
/// It also records :
/// - all functions that have been marked as pure so that they don't raise warnings
///   for possible side-effects in if-lets.
/// - memberwise initializers automatically created for structs.
/// - initializers automatically created for sealed classes.
public class RecordFunctionsTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	override func processFunctionDeclaration( // gryphon annotation: override
		_ functionDeclaration: FunctionDeclaration)
		-> FunctionDeclaration?
	{
		let swiftAPIName = functionDeclaration.prefix + "(" +
			functionDeclaration.parameters.map { ($0.apiLabel ?? "_") + ":" }.joined() + ")"

		self.context.addFunctionTranslation(TranspilationContext.FunctionTranslation(
			swiftAPIName: swiftAPIName,
			typeName: functionDeclaration.functionType,
			prefix: functionDeclaration.prefix,
			parameters: functionDeclaration.parameters))

		//
		if functionDeclaration.isPure {
			self.context.recordPureFunction(functionDeclaration)
		}

		return super.processFunctionDeclaration(functionDeclaration)
	}

	override func replaceEnumDeclaration( // gryphon annotation: override
		_ enumDeclaration: EnumDeclaration)
		-> List<Statement>
	{
		guard context.sealedClasses.contains(enumDeclaration.enumName) else {
			return super.replaceEnumDeclaration(enumDeclaration)
		}

		for element in enumDeclaration.elements {
			let parameters = element.associatedValues.compactMap
				{ (labeledType: LabeledType) -> FunctionParameter? in
					return FunctionParameter(
						label: labeledType.label,
						apiLabel: labeledType.label,
						typeName: labeledType.typeName,
						value: nil)
				}.toMutableList()

			let functionType = "(\(parameters.map { $0.typeName }.joined(separator: ","))) -> " +
				enumDeclaration.enumName

			let fakeFunctionDeclaration = FunctionDeclaration(
				range: nil,
				prefix: element.name,
				parameters: parameters,
				returnType: enumDeclaration.enumName,
				functionType: functionType,
				genericTypes: [],
				isOpen: false,
				isImplicit: false,
				isStatic: false,
				isMutating: false,
				isPure: false,
				isJustProtocolInterface: false,
				extendsType: nil,
				statements: [],
				access: nil,
				annotations: [])

			// Record the fake declaration
			_ = processFunctionDeclaration(fakeFunctionDeclaration)
		}

		return super.replaceEnumDeclaration(enumDeclaration)
	}

	override func replaceStructDeclaration( // gryphon annotation: override
		_ structDeclaration: StructDeclaration)
		-> List<Statement>
	{
		guard !structDeclaration.members.contains(where: { $0 is InitializerDeclaration }) else {
			return super.replaceStructDeclaration(structDeclaration)
		}

		// Create a fake initializer declaration to send to the function that records it
		let properties = structDeclaration.members.compactMap { statementAsStructProperty($0) }

		let parameters = properties.compactMap
			{ (variableDeclaration: VariableDeclaration) -> FunctionParameter? in
				guard let typeName = variableDeclaration.typeAnnotation ??
					variableDeclaration.expression?.swiftType else
				{
					return nil
				}
				return FunctionParameter(
					label: variableDeclaration.identifier,
					apiLabel: variableDeclaration.identifier,
					typeName: typeName,
					value: variableDeclaration.expression)
			}.toMutableList()
		let functionType = "(\(parameters.map { $0.typeName }.joined(separator: ","))) -> " +
			structDeclaration.structName

		let fakeFunctionDeclaration = FunctionDeclaration(
			range: nil,
			prefix: structDeclaration.structName,
			parameters: parameters,
			returnType: structDeclaration.structName,
			functionType: functionType,
			genericTypes: [],
			isOpen: false,
			isImplicit: false,
			isStatic: false,
			isMutating: false,
			isPure: false,
			isJustProtocolInterface: false,
			extendsType: nil,
			statements: [],
			access: nil,
			annotations: [])

		// Record the fake declaration
		_ = processFunctionDeclaration(fakeFunctionDeclaration)

		return super.replaceStructDeclaration(structDeclaration)
	}

	private func statementAsStructProperty(
		_ statement: Statement)
		-> VariableDeclaration?
	{
		if let variableDeclaration = statement as? VariableDeclaration {
			if variableDeclaration.getter == nil,
				variableDeclaration.setter == nil,
				!variableDeclaration.isStatic
			{
				return variableDeclaration
			}
		}

		return nil
	}
}

/// Equivalent to RecordFunctionsTranspilationPass, but for recording Initializers. Does not look
/// for `pure` annotations.
public class RecordInitializersTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	override func processInitializerDeclaration( // gryphon annotation: override
		_ initializerDeclaration: InitializerDeclaration)
		-> InitializerDeclaration?
	{
		let initializedType = initializerDeclaration.returnType

		let swiftAPIName = initializedType + "(" +
			initializerDeclaration.parameters.map { ($0.apiLabel ?? "_") + ":" }.joined() + ")"

		self.context.addFunctionTranslation(
			TranspilationContext.FunctionTranslation(
				swiftAPIName: swiftAPIName,
				typeName: initializerDeclaration.functionType,
				prefix: initializedType,
				parameters: initializerDeclaration.parameters))

		return super.processInitializerDeclaration(initializerDeclaration)
	}
}

/// Records the superclass and protocol inheritances of any enum, struct or class declaration.
/// Inheritances are copied to avoid them changing accidentally later.
///
/// TODO: This can cause issues when two nested classes have the same name (e.g. `A.B` and `C.B`).
public class RecordInheritancesTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	override func replaceEnumDeclaration( // gryphon annotation: override
		_ enumDeclaration: EnumDeclaration)
		-> List<Statement>
	{
		self.context.addInheritances(
			forType: enumDeclaration.enumName,
			inheritances: enumDeclaration.inherits.toList())
		return super.replaceEnumDeclaration(enumDeclaration)
	}

	override func replaceStructDeclaration( // gryphon annotation: override
		_ structDeclaration: StructDeclaration)
		-> List<Statement>
	{
		self.context.addInheritances(
			forType: structDeclaration.structName,
			inheritances: structDeclaration.inherits.toList())
		return super.replaceStructDeclaration(structDeclaration)
	}

	override func replaceClassDeclaration( // gryphon annotation: override
		_ classDeclaration: ClassDeclaration)
		-> List<Statement>
	{
		self.context.addInheritances(
			forType: classDeclaration.className,
			inheritances: classDeclaration.inherits.toList())
		return super.replaceClassDeclaration(classDeclaration)
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
		-> List<Statement>
	{
		self.context.addProtocol(protocolDeclaration.protocolName)

		return super.replaceProtocolDeclaration(protocolDeclaration)
	}
}

public class RaiseStandardLibraryWarningsTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	override func processDeclarationReferenceExpression( // gryphon annotation: override
		_ declarationReferenceExpression: DeclarationReferenceExpression)
		-> DeclarationReferenceExpression
	{
		if declarationReferenceExpression.isStandardLibrary {
			let message = "Reference to standard library " +
				"\"\(declarationReferenceExpression.identifier)\" was not translated."
			Compiler.handleWarning(
					message: message,
					syntax: declarationReferenceExpression.syntax,
					sourceFile: ast.sourceFile,
					sourceFileRange: declarationReferenceExpression.range)
		}
		return super.processDeclarationReferenceExpression(declarationReferenceExpression)
	}
}

/// Double optionals behave differently in Swift and Kotlin, so we raise a warning whenever we find
/// them.
public class RaiseDoubleOptionalWarningsTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	override func replaceExpression( // gryphon annotation: override
		_ expression: Expression)
		-> Expression
	{
		if let typeName = expression.swiftType {
			if typeName.hasSuffix("??") {
				let message = "Double optionals may behave differently in Kotlin."
				Compiler.handleWarning(
					message: message,
					syntax: expression.syntax,
					sourceFile: ast.sourceFile,
					sourceFileRange: expression.range)
			}
		}

		return super.replaceExpression(expression)
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
		-> List<Statement>
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
						syntax: variableDeclaration.syntax,
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
						syntax: functionDeclaration.syntax,
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
		-> List<Statement>
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
						syntax: functionDeclaration.syntax,
						sourceFile: ast.sourceFile,
						sourceFileRange: functionDeclaration.range)
				}
			}
		}

		return super.replaceEnumDeclaration(enumDeclaration)
	}
}

/// Struct initializers aren't yet supported; this raises warnings when they're detected.
public class RaiseStructInitializerWarningsTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	override func processInitializerDeclaration( // gryphon annotation: override
		_ initializerDeclaration: InitializerDeclaration)
		-> InitializerDeclaration?
	{
		// Get the type that declares this property, if any
		var isStructInitializer: Bool = false
		for parent in parents {
			if case let .statementNode(value: parentStatement) = parent {
				if parentStatement is ClassDeclaration || parentStatement is EnumDeclaration {
					isStructInitializer = false
				}
				else if parentStatement is StructDeclaration {
					isStructInitializer = true
				}
			}
		}

		if isStructInitializer {
			let message = "Secondary initializers in structs are not yet supported." +
				" Consider using default values for the struct's properties instead."
			Compiler.handleWarning(
				message: message,
				syntax: initializerDeclaration.syntax,
				ast: initializerDeclaration,
				sourceFile: ast.sourceFile,
				sourceFileRange: initializerDeclaration.range)
			return nil
		}
		else {
			return super.processInitializerDeclaration(initializerDeclaration)
		}
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
				syntax: expression.syntax,
				ast: expression,
				sourceFile: ast.sourceFile,
				sourceFileRange: expression.range)
		}

		return super.replaceExpression(expression)
	}

	override func replaceDotExpression( // gryphon annotation: override
		_ dotExpression: DotExpression)
		-> Expression
	{
		// If the expression is being transformed into a mutableList or a mutableMap it's probably
		// ok.
		if let leftExpressionType = dotExpression.leftExpression.swiftType,
			leftExpressionType.hasPrefix("["),
			let callExpression = dotExpression.rightExpression as? CallExpression
		{
			if let callType = callExpression.typeName {
				if (callType.hasPrefix("MutableList") ||
						callType.hasPrefix("List") ||
						callType.hasPrefix("MutableMap") ||
						callType.hasPrefix("Map")),
					let declarationReference =
						callExpression.function as? DeclarationReferenceExpression,
					let declarationType = declarationReference.typeName
				{
					if declarationReference.identifier.hasPrefix("toMutable"),
						(declarationType.hasPrefix("MutableList") ||
							declarationType.hasPrefix("MutableMap"))
					{
						return dotExpression
					}
					else if declarationReference.identifier.hasPrefix("toList"),
						declarationType.hasPrefix("List")
					{
						return dotExpression
					}
					else if declarationReference.identifier.hasPrefix("toMap"),
						declarationType.hasPrefix("Map")
					{
						return dotExpression
					}
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
		// We should still add recursion on the if's statements, though.
		return ifStatement
	}

	private func raiseWarningsForIfStatement(_ ifStatement: IfStatement, isElse: Bool) {
		// The first condition of an non-else if statement is the only one that can safely have side
		// effects
		let conditions = isElse ?
			ifStatement.conditions :
			ifStatement.conditions.dropFirst()

		let sideEffectsRanges = conditions.flatMap {
			informationOnPossibleSideEffectsInCondition($0)
		}
		for rangeAndSyntax in sideEffectsRanges {
			let syntax = rangeAndSyntax.0
			let range = rangeAndSyntax.1
			Compiler.handleWarning(
				message: "If condition may have side effects.",
				syntax: syntax,
				sourceFile: ast.sourceFile,
				sourceFileRange: range)
		}

		if let elseStatement = ifStatement.elseStatement {
			raiseWarningsForIfStatement(elseStatement, isElse: true)
		}
	}

	private func informationOnPossibleSideEffectsInCondition(
		_ condition: IfStatement.IfCondition)
		-> MutableList<(Syntax?, SourceFileRange)>
	{
		if case let .declaration(variableDeclaration: variableDeclaration) = condition {
			if let expression = variableDeclaration.expression {
				return informationOnPossibleSideEffectsIn(expression)
			}
		}

		return []
	}

	private func informationOnPossibleSideEffectsIn(
		_ expression: Expression)
		-> MutableList<(Syntax?, SourceFileRange)>
	{
		if let expression = expression as? CallExpression {
			if !self.context.isReferencingPureFunction(expression),
				let range = expression.range
			{
				return [(expression.syntax, range)]
			}
			else {
				return []
			}
		}
		if let expression = expression as? ParenthesesExpression {
			return informationOnPossibleSideEffectsIn(expression.expression)
		}
		if let expression = expression as? ForceValueExpression {
			return informationOnPossibleSideEffectsIn(expression.expression)
		}
		if let expression = expression as? OptionalExpression {
			return informationOnPossibleSideEffectsIn(expression.expression)
		}
		if let expression = expression as? SubscriptExpression {
			let result = informationOnPossibleSideEffectsIn(expression.subscriptedExpression)
			result.append(contentsOf:
				informationOnPossibleSideEffectsIn(expression.indexExpression))
			return result
		}
		if let expression = expression as? ArrayExpression {
			return expression.elements
				.flatMap { informationOnPossibleSideEffectsIn($0) }
				.toMutableList()
		}
		if let expression = expression as? DictionaryExpression {
			let result = expression.keys
				.flatMap { informationOnPossibleSideEffectsIn($0) }
				.toMutableList()
			result.append(contentsOf:
				expression.values.flatMap { informationOnPossibleSideEffectsIn($0) })
			return result
		}
		if let expression = expression as? DotExpression {
			let result = informationOnPossibleSideEffectsIn(expression.leftExpression)
			result.append(contentsOf:
				informationOnPossibleSideEffectsIn(expression.rightExpression))
			return result
		}
		if let expression = expression as? BinaryOperatorExpression {
			let result = informationOnPossibleSideEffectsIn(expression.leftExpression)
			result.append(contentsOf:
				informationOnPossibleSideEffectsIn(expression.rightExpression))
			return result
		}
		if let expression = expression as? PrefixUnaryExpression {
			return informationOnPossibleSideEffectsIn(expression.subExpression)
		}
		if let expression = expression as? PostfixUnaryExpression {
			return informationOnPossibleSideEffectsIn(expression.subExpression)
		}
		if let expression = expression as? IfExpression {
			let result = informationOnPossibleSideEffectsIn(expression.condition)
			result.append(contentsOf:
				informationOnPossibleSideEffectsIn(expression.trueExpression))
			result.append(contentsOf:
				informationOnPossibleSideEffectsIn(expression.falseExpression))
			return result
		}
		if let expression = expression as? InterpolatedStringLiteralExpression {
			return expression.expressions
				.flatMap { informationOnPossibleSideEffectsIn($0) }
				.toMutableList()
		}
		if let expression = expression as? TupleExpression {
			return expression.pairs
				.flatMap { informationOnPossibleSideEffectsIn($0.expression) }
				.toMutableList()
		}
		if let expression = expression as? TupleShuffleExpression {
			return expression.expressions
				.flatMap { informationOnPossibleSideEffectsIn($0) }
				.toMutableList()
		}

		return []
	}
}

/// Lists of conditions in Swift if statements get translated as && expressions in Kotlin. This
/// could cause problems if any of the conditions has a precedence that's lower than the &&, since
/// the conditions would be evaluated in the wrong order. This pass adds parentheses around these
/// conditions to ensure they're evaluated correctly.
/// According to https://kotlinlang.org/docs/reference/grammar.html#expressions, only the
/// disjunction (`||`), spread (`*`) and assignment (`=`, `+=`, `-=`, `*=`,` /=`, `%=`) operators
/// have lower precedence than `&&`; of those, only `||` is currently supported in if conditions.
public class AddParenthesesForOperatorsInIfsTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	override func processIfStatement( // gryphon annotation: override
		_ ifStatement: IfStatement)
		-> IfStatement
	{
		// If there's only one condition there's no need to disambiguate
		guard ifStatement.conditions.count > 1 else {
			return super.processIfStatement(ifStatement)
		}

		let newConditions: MutableList<IfStatement.IfCondition> = []

		for condition in ifStatement.conditions {
			if case let .condition(expression: expression) = condition {
				if let binaryExpression = expression as? BinaryOperatorExpression,
					binaryExpression.operatorSymbol == "||"
				{
					newConditions.append(.condition(expression: ParenthesesExpression(
						syntax: expression.syntax,
						range: expression.range,
						expression: expression)))
					continue
				}
			}

			newConditions.append(condition)
		}

		ifStatement.conditions = newConditions
		return super.processIfStatement(ifStatement)
	}
}

/// Sends let declarations to before the if statement, and replaces them with `x != null`
/// conditions. Also adds optionals to sequential declarations:
///
/// 	val a: Foo? = b
/// 	val result: Double? = a.c // This `a` should be `a?`
public class RearrangeIfLetsTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	let currentDeclarations: MutableList<String> = []

	/// Send the let declarations to before the if statement
	override func replaceIfStatement( // gryphon annotation: override
		_ ifStatement: IfStatement)
		-> List<Statement>
	{
		let gatheredDeclarations = gatherLetDeclarations(ifStatement)

		// When if-lets are rearranged, it's possible to have two equal declarations (e.g.
		// `val a = b as? String` showing up twice) coming from two different `else if`s, which
		// create conflicts in Kotlin.
		let uniqueDeclarations = gatheredDeclarations.removingDuplicates()

		// Add optionals to declarations
		let processedDeclarations: MutableList<Statement> = []
		for declaration in uniqueDeclarations {
			// Process this declaration
			processedDeclarations.append(contentsOf: replaceVariableDeclaration(declaration))
			// Add its info for future declarations
			currentDeclarations.append(declaration.identifier)
		}

		currentDeclarations.removeAll()

		let result = processedDeclarations
		result.append(contentsOf: super.replaceIfStatement(ifStatement))
		return result
	}

	override func replaceDeclarationReferenceExpression( // gryphon annotation: override
		_ declarationReferenceExpression: DeclarationReferenceExpression)
		-> Expression
	{
		if currentDeclarations.contains(declarationReferenceExpression.identifier) {
			return OptionalExpression(
				syntax: declarationReferenceExpression.syntax,
				range: declarationReferenceExpression.range,
				expression: declarationReferenceExpression)
		}
		else {
			return super.replaceDeclarationReferenceExpression(declarationReferenceExpression)
		}
	}

	/// Add conditions (`x != null`) for all let declarations
	override func processIfStatement( // gryphon annotation: override
		_ ifStatement: IfStatement)
		-> IfStatement
	{
		let newConditions = ifStatement.conditions.map {
			replaceIfLetConditionWithNullCheck($0)
		}.toMutableList()

		ifStatement.conditions = newConditions
		return super.processIfStatement(ifStatement)
	}

	private func replaceIfLetConditionWithNullCheck(
		_ condition: IfStatement.IfCondition)
		-> IfStatement.IfCondition
	{
		if case let .declaration(variableDeclaration: variableDeclaration) = condition {
			return .condition(expression: BinaryOperatorExpression(
				syntax: variableDeclaration.syntax,
				range: variableDeclaration.range,
				leftExpression: DeclarationReferenceExpression(
					syntax: variableDeclaration.expression?.syntax,
					range: variableDeclaration.expression?.range,
					identifier: variableDeclaration.identifier,
					typeName: variableDeclaration.typeAnnotation,
					isStandardLibrary: false,
					isImplicit: false),
				rightExpression: NilLiteralExpression(
					syntax: variableDeclaration.syntax,
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
		let syntax = functionDeclaration.syntax

		// Declare new variables with the same name as the Swift paramemeters, containing `this` and
		// `other`
		newStatements.append(VariableDeclaration(
			syntax: syntax,
			range: range,
			identifier: lhs.label,
			typeAnnotation: lhs.typeName,
			expression: DeclarationReferenceExpression(
				syntax: syntax,
				range: range,
				identifier: "this",
				typeName: lhs.typeName,
				isStandardLibrary: false,
				isImplicit: false),
			getter: nil,
			setter: nil,
			access: nil,
			isOpen: false,
			isLet: true,
			isImplicit: false,
			isStatic: false,
			extendsType: nil,
			annotations: []))
		newStatements.append(VariableDeclaration(
			syntax: syntax,
			range: range,
			identifier: rhs.label,
			typeAnnotation: "Any?",
			expression: DeclarationReferenceExpression(
				syntax: syntax,
				range: range,
				identifier: "other",
				typeName: "Any?",
				isStandardLibrary: false,
				isImplicit: false),
			getter: nil,
			setter: nil,
			access: nil,
			isOpen: false,
			isLet: true,
			isImplicit: false,
			isStatic: false,
			extendsType: nil,
			annotations: []))

		// Add an if statement to guarantee the comparison only happens between the right types
		newStatements.append(IfStatement(
			syntax: syntax,
			range: range,
			conditions: [ .condition(expression: BinaryOperatorExpression(
				syntax: syntax,
				range: range,
				leftExpression: DeclarationReferenceExpression(
					syntax: syntax,
					range: range,
					identifier: rhs.label,
					typeName: "Any?",
					isStandardLibrary: false,
					isImplicit: false),
				rightExpression: TypeExpression(
					syntax: syntax,
					range: range,
					typeName: rhs.typeName),
				operatorSymbol: "is",
				typeName: "Bool")),
			],
			declarations: [],
			statements: oldStatements,
			elseStatement: IfStatement(
				syntax: syntax,
				range: range,
				conditions: [],
				declarations: [],
				statements: [
					ReturnStatement(
						syntax: syntax,
						range: range,
						expression: LiteralBoolExpression(
							syntax: syntax,
							range: range,
							value: false),
						label: nil),
				],
				elseStatement: nil,
				isGuard: false),
			isGuard: false))

		return super.processFunctionDeclaration(FunctionDeclaration(
			syntax: syntax,
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
			isOpen: true,
			isImplicit: functionDeclaration.isImplicit,
			isStatic: false,
			isMutating: functionDeclaration.isMutating,
			isPure: functionDeclaration.isPure,
			isJustProtocolInterface: functionDeclaration.isJustProtocolInterface,
			extendsType: nil,
			statements: newStatements,
			access: "public",
			annotations: ["override", "open"]))
	}
}

/// Populate implicit raw values when needed. For strings, the raw value is the same as the case's
/// identifier; for integers, it's 1 more than the last case, starting at 0.
public class ImplicitRawValuesTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	override func replaceEnumDeclaration( // gryphon annotation: override
		_ enumDeclaration: EnumDeclaration)
		-> List<Statement>
	{
		if enumDeclaration.inherits.contains("String") {
			for element in enumDeclaration.elements {
				if element.rawValue == nil {
					element.rawValue = LiteralStringExpression(
						syntax: enumDeclaration.syntax,
						range: enumDeclaration.range,
						value: element.name,
						isMultiline: false)
				}
			}
		}
		else if enumDeclaration.inherits.contains("Int") {
			var lastValue: Int64 = -1 // So that the first will be 0
			for element in enumDeclaration.elements {
				if let rawValue = element.rawValue as? LiteralIntExpression {
					lastValue = rawValue.value
				}
				else {
					element.rawValue = LiteralIntExpression(
						syntax: enumDeclaration.syntax,
						range: enumDeclaration.range,
						value: lastValue + 1)
					lastValue = lastValue + 1
				}
			}
		}

		return super.replaceEnumDeclaration(enumDeclaration)
	}
}

/// Create a rawValue variable and initializer for enums that conform to rawRepresentable
public class RawValuesMembersTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	override func replaceEnumDeclaration( // gryphon annotation: override
		_ enumDeclaration: EnumDeclaration)
		-> List<Statement>
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
					message: "Failed to create init(rawValue:). " +
						"Unable to get all raw values from the enum declaration.",
					syntax: enumDeclaration.syntax,
					ast: enumDeclaration,
					sourceFile: ast.sourceFile,
					sourceFileRange: enumDeclaration.range)
				return super.replaceEnumDeclaration(enumDeclaration)
			}

			let newMembers = enumDeclaration.members
			newMembers.append(rawValueInitializer)
			newMembers.append(rawValueVariable)

			return super.replaceEnumDeclaration(EnumDeclaration(
				syntax: enumDeclaration.syntax,
				range: enumDeclaration.range,
				access: enumDeclaration.access,
				enumName: enumDeclaration.enumName,
				annotations: enumDeclaration.annotations,
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
		let syntax = enumDeclaration.syntax

		let switchCases = enumDeclaration.elements.map { element -> SwitchCase in
			SwitchCase(
				expressions: [element.rawValue!],
				statements: [
					ReturnStatement(
						syntax: syntax,
						range: range,
						expression: DotExpression(
							syntax: syntax,
							range: range,
							leftExpression: TypeExpression(
								syntax: syntax,
								range: range,
								typeName: enumDeclaration.enumName),
							rightExpression: DeclarationReferenceExpression(
								syntax: syntax,
								range: range,
								identifier: element.name,
								typeName: enumDeclaration.enumName,
								isStandardLibrary: false,
								isImplicit: false)),
						label: nil),
				])
		}.toMutableList()

		let defaultSwitchCase = SwitchCase(
			expressions: [],
			statements: [ReturnStatement(
				syntax: syntax,
				range: range,
				expression: NilLiteralExpression(syntax: syntax, range: range),
				label: nil), ])

		switchCases.append(defaultSwitchCase)

		let switchStatement = SwitchStatement(
			syntax: syntax,
			range: range,
			convertsToExpression: nil,
			expression: DeclarationReferenceExpression(
				syntax: syntax,
				range: range,
				identifier: "rawValue",
				typeName: rawValueType,
				isStandardLibrary: false,
				isImplicit: false),
			cases: switchCases)

		return InitializerDeclaration(
			syntax: syntax,
			range: range,
			parameters: [FunctionParameter(
				label: "rawValue",
				apiLabel: nil,
				typeName: rawValueType,
				value: nil), ],
			returnType: enumDeclaration.enumName + "?",
			functionType: "(\(rawValueType)) -> \(enumDeclaration.enumName)?",
			genericTypes: [],
			isOpen: false,
			isImplicit: false,
			isStatic: true,
			isMutating: false,
			isPure: true,
			extendsType: nil,
			statements: [switchStatement],
			access: enumDeclaration.access,
			annotations: [],
			superCall: nil,
			isOptional: true)
	}

	private func createRawValueVariable(
		withRawValueType rawValueType: String,
		forEnumDeclaration enumDeclaration: EnumDeclaration)
		-> VariableDeclaration
	{
		let range = enumDeclaration.range
		let syntax = enumDeclaration.syntax

		let switchCases = enumDeclaration.elements.map { element in
			SwitchCase(
				expressions: [DotExpression(
					syntax: syntax,
					range: range,
					leftExpression: TypeExpression(
						syntax: syntax,
						range: range,
						typeName: enumDeclaration.enumName),
					rightExpression: DeclarationReferenceExpression(
						syntax: syntax,
						range: range,
						identifier: element.name,
						typeName: enumDeclaration.enumName,
						isStandardLibrary: false,
						isImplicit: false)), ],
				statements: [
					ReturnStatement(
						syntax: syntax,
						range: range,
						expression: element.rawValue,
						label: nil),
				])
		}.toMutableList()

		let switchStatement = SwitchStatement(
			syntax: syntax,
			range: range,
			convertsToExpression: nil,
			expression: DeclarationReferenceExpression(
				syntax: syntax,
				range: range,
				identifier: "this",
				typeName: enumDeclaration.enumName,
				isStandardLibrary: false,
				isImplicit: false),
			cases: switchCases)

		let getter = FunctionDeclaration(
			syntax: syntax,
			range: range,
			prefix: "get",
			parameters: [],
			returnType: rawValueType,
			functionType: "() -> \(rawValueType)",
			genericTypes: [],
			isOpen: false,
			isImplicit: false,
			isStatic: false,
			isMutating: false,
			isPure: false,
			isJustProtocolInterface: false,
			extendsType: nil,
			statements: [switchStatement],
			access: enumDeclaration.access,
			annotations: [])

		return VariableDeclaration(
			syntax: syntax,
			range: range,
			identifier: "rawValue",
			typeAnnotation: rawValueType,
			expression: nil,
			getter: getter,
			setter: nil,
			access: nil,
			isOpen: false,
			isLet: false,
			isImplicit: false,
			isStatic: false,
			extendsType: nil,
			annotations: [])
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
					syntax: binaryOperatorExpression.syntax,
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
					syntax: binaryOperatorExpression.syntax,
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

			ifStatement.conditions = List<Expression>([newCondition]).map {
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
		-> List<Statement>
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
								syntax: ifStatement.syntax,
								range: ifStatement.range,
								expression: BinaryOperatorExpression(
									syntax: ifStatement.syntax,
									range: ifStatement.range,
									leftExpression: binaryOperatorExpression.leftExpression,
									rightExpression: ReturnExpression(
										syntax: ifStatement.syntax,
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

/// Removes function bodies and makes variables' getters and setters empty and implicit
public class FixProtocolContentsTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	var isInProtocol = false

	override func replaceProtocolDeclaration( // gryphon annotation: override
		_ protocolDeclaration: ProtocolDeclaration)
		-> List<Statement>
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
			functionDeclaration.statements = nil
			functionDeclaration.isJustProtocolInterface = true
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

/// Function declarations in protocols are dumped with a generic constraint of
/// `<Self where Self: MyProtocol>`. That constraint passes through `Utilities.splitTypeList`, which
/// simplifies it to `"SelfwhereSelf:MyProtocol"`. This can happen both in protocol declarations and
/// in extensions (when extending a protocol). This pass removes that constraint, since it shouldn't
/// show up in the translated code.
public class FixProtocolGenericsTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }
	override func processFunctionDeclaration( // gryphon annotation: override
		_ functionDeclaration: FunctionDeclaration)
		-> FunctionDeclaration?
	{
		let newGenerics = functionDeclaration.genericTypes.filter {
				!$0.hasPrefix("Self")
			}.toMutableList()
		functionDeclaration.genericTypes = newGenerics
		return super.processFunctionDeclaration(functionDeclaration)
	}
}

/// Extensions for generic types in Swift 5.2 are dumped without the generic information (i.e.
/// an extension for `Box<T>` is dumped as if it were just for `Box`). We can retrieve that generic
/// information by looking at a function's type, which includes the extended type (i.e.
/// `<T> (Box<T>) -> (Int) -> ()`. This pass retrieves that information and adds it to the extended
/// type if needed.
///
/// If we're in SwiftSyntax, we also have to add the extended type's generics to the function
/// declaration itself.
public class FixExtensionGenericsTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	override func processFunctionDeclaration( // gryphon annotation: override
		_ functionDeclaration: FunctionDeclaration)
		-> FunctionDeclaration?
	{
		if context.isUsingSwiftSyntax {
			if let extendedType = functionDeclaration.extendsType, extendedType.contains("<") {
				let genericString = String(extendedType
					.drop(while: { $0 != "<" })
					.dropFirst()
					.dropLast())
				let genericTypes = Utilities.splitTypeList(genericString, separators: [","])
				functionDeclaration.genericTypes.append(contentsOf: genericTypes)
			}

			return super.processFunctionDeclaration(functionDeclaration)
		}
		else {
			if let extendedType = functionDeclaration.extendsType {
				var newType = functionDeclaration.functionType
				let prefixToDiscard = functionDeclaration.functionType.prefix { $0 != "(" }
				newType = String(functionDeclaration.functionType
					.dropFirst(prefixToDiscard.count + 1))
				newType = String(newType.prefix { $0 != ")" })

				// If we're really just adding generics (i.e. `Box` to `Box<T>`)
				if newType.hasPrefix(extendedType + "<") {
					functionDeclaration.extendsType = newType
				}
			}

			return super.processFunctionDeclaration(functionDeclaration)
		}
	}
}

/// - Escapes `$`s in strings (to avoid accidental string interpolations in Kotlin).
/// - Escapes `'`s in character literals.
public class EscapeSpecialCharactersInStringsTranspilationPass: TranspilationPass {
    // gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
    // gryphon insert:     super(ast, context) { }
    
    override func replaceLiteralStringExpression( // gryphon annotation: override
        _ literalStringExpression: LiteralStringExpression) -> Expression {
        let replacedLiteralStringExpression = LiteralStringExpression(
            range: literalStringExpression.range,
            value: literalStringExpression.value.replacingOccurrences(of: "$", with: "\\$"),
            isMultiline: literalStringExpression.isMultiline)
        return super.replaceLiteralStringExpression(replacedLiteralStringExpression)
    }

	override func replaceLiteralCharacterExpression( // gryphon annotation: override
		_ literalCharacterExpression: LiteralCharacterExpression)
		-> Expression
	{
		if context.isUsingSwiftSyntax {
			let replacedLiteralCharacterExpression = LiteralCharacterExpression(
				range: literalCharacterExpression.range,
				value: literalCharacterExpression.value.replacingOccurrences(of: "'", with: "\\'"))
			return super.replaceLiteralCharacterExpression(replacedLiteralCharacterExpression)
		}
		else {
			return super.replaceLiteralCharacterExpression(literalCharacterExpression)
		}
	}
}

/// Removes `override` annotations from static members and initializers, as they're not supported in
/// Kotlin.
public class RemoveOverridesTranspilationPass: TranspilationPass {
	override func replaceCompanionObject(_ companionObject: CompanionObject) -> List<Statement> {
		for statement in companionObject.members {
			if let variableDeclaration = statement as? VariableDeclaration {
				variableDeclaration.annotations.remove("override")
			}
			if let functionDeclaration = statement as? FunctionDeclaration {
				functionDeclaration.annotations.remove("override")
			}
		}

		return super.replaceCompanionObject(companionObject)
	}

	override func replaceInitializerDeclaration(
		_ initializerDeclaration: InitializerDeclaration)
		-> List<Statement>
	{
		initializerDeclaration.annotations.remove("override")
		return super.replaceInitializerDeclaration(initializerDeclaration)
	}
}

/// Kotlin initializers cannot be marked as `open`.
public class RemoveOpenForInitializersTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	override func processInitializerDeclaration( // gryphon annotation: override
		_ initializerDeclaration: InitializerDeclaration)
		-> InitializerDeclaration?
	{
		return InitializerDeclaration(
			syntax: initializerDeclaration.syntax,
			range: initializerDeclaration.range,
			parameters: initializerDeclaration.parameters,
			returnType: initializerDeclaration.returnType,
			functionType: initializerDeclaration.functionType,
			genericTypes: initializerDeclaration.genericTypes,
			isOpen: false,
			isImplicit: initializerDeclaration.isImplicit,
			isStatic: initializerDeclaration.isStatic,
			isMutating: initializerDeclaration.isMutating,
			isPure: initializerDeclaration.isPure,
			extendsType: initializerDeclaration.extendsType,
			statements: initializerDeclaration.statements,
			access: initializerDeclaration.access,
			annotations: initializerDeclaration.annotations,
			superCall: initializerDeclaration.superCall,
			isOptional: initializerDeclaration.isOptional)
	}
}

/// Kotlin catch statements must have a variable declaration
public class AddVariablesToCatchesTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	override func replaceCatchStatement( // gryphon annotation: override
		_ catchStatement: CatchStatement)
		-> List<Statement>
	{
		if catchStatement.variableDeclaration == nil {
			return super.replaceCatchStatement(CatchStatement(
				syntax: catchStatement.syntax,
				range: catchStatement.range,
				variableDeclaration: VariableDeclaration(
					syntax: catchStatement.syntax,
					range: catchStatement.range,
					identifier: "_error",
					typeAnnotation: "Error",
					expression: nil,
					getter: nil,
					setter: nil,
					access: nil,
					isOpen: false,
					isLet: true,
					isImplicit: false,
					isStatic: false,
					extendsType: nil,
					annotations: []),
				statements: catchStatement.statements))
		}

		return super.replaceCatchStatement(catchStatement)
	}
}

/// Tries to match call expressions to known function declarations so we can use the internal
/// parameter names, e.g. turn `f(a = 0)` into `f(b = 0)` when we've seen a `f(a b: Int)`. If no
/// matches are found, remove all labels; this might cause correctness problems, but it happens too
/// often to do anything else.
public class MatchFunctionCallsToDeclarationsTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	override func processCallExpression( // gryphon annotation: override
		_ callExpression: CallExpression)
		-> CallExpression
	{
		guard context.isUsingSwiftSyntax else {
			return callExpression
		}

		let tupleExpression = callExpression.parameters as! TupleExpression

		// Go through the dot expression chain to get the final expression
		var functionExpression = callExpression.function
		while true {
			if let expression = functionExpression as? DotExpression {
				functionExpression = expression.rightExpression
			}
			else {
				break
			}
		}

		// Don't try to match templates
		if functionExpression is LiteralCodeExpression {
			return super.processCallExpression(callExpression)
		}

		// Try to find a function translation
		let maybeFunctionTranslation: TranspilationContext.FunctionTranslation?
		if let expression = functionExpression as? DeclarationReferenceExpression,
			let typeName = expression.typeName
		{
			maybeFunctionTranslation = self.context.getFunctionTranslation(
				forName: expression.identifier,
				typeName: typeName)
		}
		else if let typeExpression = functionExpression as? TypeExpression,
			let parameterTypes = callExpression.parameters.swiftType
		{
			let typeName = typeExpression.typeName
			let initializerType = "(\(typeName).Type) -> \(parameterTypes) -> \(typeName)"
			maybeFunctionTranslation = self.context.getFunctionTranslation(
				forName: typeName,
				typeName: initializerType)
		}
		else {
			maybeFunctionTranslation = nil
		}

		guard let functionTranslation = maybeFunctionTranslation else {
			removeLabels(fromTupleExpression: tupleExpression)
			return super.processCallExpression(callExpression)
		}



		// Try to match the call to the declaration using the swiftc algorithm
		let callArguments = tupleExpression.pairs

		let defaultArguments = functionTranslation.parameters.map { $0.value != nil }
		let acceptsUnlabeledTrailingClosures = functionTranslation.parameters.map { _ in true }

		let matchResult: MutableList<MutableList<Int>> = []

		// Check if there's an unlabeled closure at the end (and assume it's a trailing closure
		// if there is)
		let unlabeledTrailingClosureArgIndex: Int?
		if let lastArgument = callArguments.last,
			lastArgument.expression is ClosureExpression,
			lastArgument.label == nil
		{
			unlabeledTrailingClosureArgIndex = callArguments.count - 1
		}
		else {
			unlabeledTrailingClosureArgIndex = nil
		}

		let matchFailed = matchCallArguments(
			args: callArguments,
			params: functionTranslation.parameters,
			paramInfo: ParameterListInfo(
				defaultArguments: defaultArguments,
				acceptsUnlabeledTrailingClosures: acceptsUnlabeledTrailingClosures),
			unlabeledTrailingClosureArgIndex: unlabeledTrailingClosureArgIndex,
			trailingClosureMatching: .forward,
			parameterBindings: matchResult)

		if matchFailed {
			Compiler.handleWarning(
				message: "Unable to match these parameters to their declarations, " +
					"removing all labels",
				syntax: callExpression.parameters.syntax,
				ast: callExpression.parameters,
				sourceFile: ast.sourceFile,
				sourceFileRange: callExpression.parameters.range)

			removeLabels(fromTupleExpression: tupleExpression)
			return super.processCallExpression(callExpression)
		}

		let resultPairs: MutableList<LabeledExpression> = []

		// Variadic arguments can't be named, which means all arguments before them can't be
		// named either.
		let lastVariadicIndex =
			functionTranslation.parameters.lastIndex(where: { $0.isVariadic }) ??
			-1

		// matchResult will be something like [[0], [1], [2], [3, 4], [5], []]
		for declarationIndex in functionTranslation.parameters.indices {
			let isBeforeVariadic = (declarationIndex <= lastVariadicIndex)

			let implementationLabel = functionTranslation.parameters[declarationIndex].label

			let callIndices = matchResult[declarationIndex]
			for callIndex in callIndices {
				let argument = callArguments[callIndex]
				resultPairs.append(LabeledExpression(
					label: isBeforeVariadic ? nil : implementationLabel,
					expression: argument.expression))
			}
		}

		// Figure out if we can write a trailing closure in Kotlin
		let hasVariadic =
			functionTranslation.parameters.contains(where: { $0.isVariadic })
		let hasDefaultArgument =
			functionTranslation.parameters.contains(where: { $0.value != nil })
		let allowsTrailingClosure = (!hasDefaultArgument && !hasVariadic)

		tupleExpression.pairs = resultPairs
		callExpression.allowsTrailingClosure = allowsTrailingClosure
		return super.processCallExpression(callExpression)
	}

	private func removeLabels(fromTupleExpression tupleExpression: TupleExpression) {
		let newPairs = tupleExpression.pairs.map {
			LabeledExpression(
				label: nil,
				expression: $0.expression)
		}.toMutableList()

		tupleExpression.pairs = newPairs
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

		// We need to specify the initializers' return types before recording them
		ast = ReturnTypesForInitsTranspilationPass(ast: ast, context: context).run()

		// Record information on enum and function translations
		ast = RecordTemplatesTranspilationPass(ast: ast, context: context).run()
		ast = RecordProtocolsTranspilationPass(ast: ast, context: context).run()
		ast = RecordInitializersTranspilationPass(ast: ast, context: context).run()
		ast = RecordInheritancesTranspilationPass(ast: ast, context: context).run()

		// RecordEnums needs to be after CleanInheritance: it needs Swift-only inheritances removed
		// in order to know if the enum inherits from a class or not, and therefore is a sealed
		// class or an enum class.
		// ImplicitRawValues needs to know if the enum inherits from a String or Int in order to
		// populate the implicit raw values correctly.
		ast = ImplicitRawValuesTranspilationPass(ast: ast, context: context).run()
		ast = CleanInheritancesTranspilationPass(ast: ast, context: context).run()
		ast = RecordEnumsTranspilationPass(ast: ast, context: context).run()

		// RecordFunctions needs RecordEnums so it can know which enums are sealed classes and need
		// their sealed class initializers recorded.
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

		/// Replace templates (must go before other passes since templates are recorded before
		/// running any passes)
		ast = ReplaceTemplatesTranspilationPass(ast: ast, context: context).run()

		/// Cleanup
		ast = RemoveParenthesesTranspilationPass(ast: ast, context: context).run()
		ast = RemoveExtraReturnsInInitsTranspilationPass(ast: ast, context: context).run()

		/// Transform structures that need to be significantly different in Kotlin
		ast = EquatableOperatorsTranspilationPass(ast: ast, context: context).run()
		ast = RawValuesMembersTranspilationPass(ast: ast, context: context).run()
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
		ast = AddParenthesesForOperatorsInIfsTranspilationPass(ast: ast, context: context).run()
		ast = RearrangeIfLetsTranspilationPass(ast: ast, context: context).run()

		/// Transform structures that need to be slightly different in Kotlin
		ast = SelfToThisTranspilationPass(ast: ast, context: context).run()
		ast = ImplicitNilsInOptionalVariablesTranspilationPass(ast: ast, context: context).run()
		ast = AnonymousParametersTranspilationPass(ast: ast, context: context).run()
		ast = CovarianceInitsAsCallsTranspilationPass(ast: ast, context: context).run()
		ast = OptionalFunctionCallsTranspilationPass(ast: ast, context: context).run()
		ast = DataStructureInitializersTranspilationPass(ast: ast, context: context).run()
		ast = TuplesToPairsTranspilationPass(ast: ast, context: context).run()
		ast = TupleMembersTranspilationPass(ast: ast, context: context).run()
		ast = AutoclosuresTranspilationPass(ast: ast, context: context).run()
		ast = RefactorOptionalsInSubscriptsTranspilationPass(ast: ast, context: context).run()
		ast = AddOptionalsInDotChainsTranspilationPass(ast: ast, context: context).run()
		ast = RenameOperatorsTranspilationPass(ast: ast, context: context).run()
		ast = CallsToSuperclassInitializersTranspilationPass(ast: ast, context: context).run()
		ast = OptionalsInConditionalCastsTranspilationPass(ast: ast, context: context).run()
		ast = AccessModifiersTranspilationPass(ast: ast, context: context).run()
		ast = OpenDeclarationsTranspilationPass(ast: ast, context: context).run()
		ast = FixProtocolGenericsTranspilationPass(ast: ast, context: context).run()
		ast = FixExtensionGenericsTranspilationPass(ast: ast, context: context).run()
		ast = RemoveOpenForInitializersTranspilationPass(ast: ast, context: context).run()
		ast = AddVariablesToCatchesTranspilationPass(ast: ast, context: context).run()
		ast = MatchFunctionCallsToDeclarationsTranspilationPass(ast: ast, context: context).run()
        ast = EscapeSpecialCharactersInStringsTranspilationPass(ast: ast, context: context).run()
		ast = RemoveOverridesTranspilationPass(ast: ast, context: context).run()

		// - CapitalizeEnums has to be before IsOperatorsInSealedClasses and
		//   IsOperatorsInIfStatementsTranspilationPass
		ast = CapitalizeEnumsTranspilationPass(ast: ast, context: context).run()
		ast = IsOperatorsInSwitchesTranspilationPass(ast: ast, context: context).run()
		ast = IsOperatorsInIfStatementsTranspilationPass(ast: ast, context: context).run()

		// - SwitchesToExpressions has to be before RemoveBreaksInSwitches:
		//   RemoveBreaks might remove a case that only has a break, turning an exhaustive switch
		//   into a non-exhaustive one and making it convertible to an expression. However, only
		//   exhaustive switches can be converted to expressions, so this should be avoided.
		// - SwitchesToExpressions has to be before ReturnsInLambdas:
		//   Returns in lambdas needs to know if the switch becomes a return.
		ast = SwitchesToExpressionsTranspilationPass(ast: ast, context: context).run()
		ast = RemoveBreaksInSwitchesTranspilationPass(ast: ast, context: context).run()
		ast = ReturnsInLambdasTranspilationPass(ast: ast, context: context).run()

		/// Improve Kotlin readability
		ast = InnerTypePrefixesTranspilationPass(ast: ast, context: context).run()
		ast = DoubleNegativesInGuardsTranspilationPass(ast: ast, context: context).run()
		ast = ReturnIfNilTranspilationPass(ast: ast, context: context).run()

		/// Raise any warnings that may be left
		ast = RaiseStandardLibraryWarningsTranspilationPass(ast: ast, context: context).run()
		ast = RaiseDoubleOptionalWarningsTranspilationPass(ast: ast, context: context).run()
		ast = RaiseMutableValueTypesWarningsTranspilationPass(ast: ast, context: context).run()
		ast = RaiseStructInitializerWarningsTranspilationPass(ast: ast, context: context).run()
		ast = RaiseNativeDataStructureWarningsTranspilationPass(ast: ast, context: context).run()

		return ast
	}

	/// For debugging only
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
