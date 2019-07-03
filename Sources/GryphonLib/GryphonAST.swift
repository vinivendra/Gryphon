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

public final class GryphonAST: PrintableAsTree, Equatable, CustomStringConvertible {
	let sourceFile: SourceFile?
	let declarations: ArrayClass<Statement>
	let statements: ArrayClass<Statement>

	init(
		sourceFile: SourceFile?,
		declarations: ArrayClass<Statement>,
		statements: ArrayClass<Statement>)
	{
		self.sourceFile = sourceFile
		self.declarations = declarations
		self.statements = statements
	}

	//
	public static func == (lhs: GryphonAST, rhs: GryphonAST) -> Bool {
		return lhs.declarations == rhs.declarations &&
			lhs.statements == rhs.statements
	}

	//
	public var treeDescription: String { // annotation: override
		return "Source File"
	}

	public var printableSubtrees: ArrayClass<PrintableAsTree?> { // annotation: override
		return [PrintableTree("Declarations", ArrayClass<PrintableAsTree?>(declarations)),
				PrintableTree("Statements", ArrayClass<PrintableAsTree?>(statements)), ]
	}

	//
	public var description: String { // annotation: override
		return prettyDescription()
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////

extension PrintableTree {
	static func ofStatements(_ description: String, _ subtrees: ArrayClass<Statement>)
		-> PrintableAsTree?
	{
		let newSubtrees = ArrayClass<PrintableAsTree?>(subtrees)
		return PrintableTree.initOrNil(description, newSubtrees)
	}
}

public indirect enum Statement: PrintableAsTree, Equatable {

	case comment(
		value: String,
		range: SourceFileRange)
	case expressionStatement(
		expression: Expression)
	case typealiasDeclaration(
		identifier: String,
		typeName: String,
		isImplicit: Bool)
	case extensionDeclaration(
		typeName: String,
		members: ArrayClass<Statement>)
	case importDeclaration(
		moduleName: String)
	case classDeclaration(
		className: String,
		inherits: ArrayClass<String>,
		members: ArrayClass<Statement>)
	case companionObject(
		members: ArrayClass<Statement>)
	case enumDeclaration(
		access: String?,
		enumName: String,
		inherits: ArrayClass<String>,
		elements: ArrayClass<EnumElement>,
		members: ArrayClass<Statement>,
		isImplicit: Bool)
	case protocolDeclaration(
		protocolName: String,
		members: ArrayClass<Statement>)
	case structDeclaration(
		annotations: String?,
		structName: String,
		inherits: ArrayClass<String>,
		members: ArrayClass<Statement>)
	case functionDeclaration(
		data: FunctionDeclarationData)
	case variableDeclaration(
		data: VariableDeclarationData)
	case doStatement(
		statements: ArrayClass<Statement>)
	case catchStatement(
		variableDeclaration: VariableDeclarationData?,
		statements: ArrayClass<Statement>)
	case forEachStatement(
		collection: Expression,
		variable: Expression,
		statements: ArrayClass<Statement>)
	case whileStatement(
		expression: Expression,
		statements: ArrayClass<Statement>)
	case ifStatement(
		data: IfStatementData)
	case switchStatement(
		convertsToExpression: Statement?,
		expression: Expression,
		cases: ArrayClass<SwitchCase>)
	case deferStatement(
		statements: ArrayClass<Statement>)
	case throwStatement(
		expression: Expression)
	case returnStatement(
		expression: Expression?)
	case breakStatement
	case continueStatement
	case assignmentStatement(
		leftHand: Expression,
		rightHand: Expression)
	case error

	//
	public var name: String {
		switch self {
		case .comment:
			return "comment".capitalizedAsCamelCase()
		case .expressionStatement:
			return "expressionStatement".capitalizedAsCamelCase()
		case .extensionDeclaration:
			return "extensionDeclaration".capitalizedAsCamelCase()
		case .importDeclaration:
			return "importDeclaration".capitalizedAsCamelCase()
		case .typealiasDeclaration:
			return "typealiasDeclaration".capitalizedAsCamelCase()
		case .classDeclaration:
			return "classDeclaration".capitalizedAsCamelCase()
		case .companionObject:
			return "companionObject".capitalizedAsCamelCase()
		case .enumDeclaration:
			return "enumDeclaration".capitalizedAsCamelCase()
		case .protocolDeclaration:
			return "protocolDeclaration".capitalizedAsCamelCase()
		case .structDeclaration:
			return "structDeclaration".capitalizedAsCamelCase()
		case .functionDeclaration:
			return "functionDeclaration".capitalizedAsCamelCase()
		case .variableDeclaration:
			return "variableDeclaration".capitalizedAsCamelCase()
		case .doStatement:
			return "doStatement".capitalizedAsCamelCase()
		case .catchStatement:
			return "catchStatement".capitalizedAsCamelCase()
		case .forEachStatement:
			return "forEachStatement".capitalizedAsCamelCase()
		case .whileStatement:
			return "whileStatement".capitalizedAsCamelCase()
		case .ifStatement:
			return "ifStatement".capitalizedAsCamelCase()
		case .switchStatement:
			return "switchStatement".capitalizedAsCamelCase()
		case .deferStatement:
			return "deferStatement".capitalizedAsCamelCase()
		case .throwStatement:
			return "throwStatement".capitalizedAsCamelCase()
		case .returnStatement:
			return "returnStatement".capitalizedAsCamelCase()
		case .breakStatement:
			return "breakStatement".capitalizedAsCamelCase()
		case .continueStatement:
			return "continueStatement".capitalizedAsCamelCase()
		case .assignmentStatement:
			return "assignmentStatement".capitalizedAsCamelCase()
		case .error:
			return "error".capitalizedAsCamelCase()
		}
	}

	//
	public var treeDescription: String { // annotation: override
		return name
	}

	public var printableSubtrees: ArrayClass<PrintableAsTree?> { // annotation: override
		switch self {
		case let .comment(value: value, range: _):
			return [PrintableTree("//\(value)")]
		case let .expressionStatement(expression: expression):
			return [expression]
		case let .extensionDeclaration(typeName: typeName, members: members):
			return [
				PrintableTree(typeName),
				PrintableTree.ofStatements("members", members), ]
		case let .importDeclaration(moduleName: moduleName):
			return [PrintableTree(moduleName)]
		case let .typealiasDeclaration(
			identifier: identifier, typeName: typeName, isImplicit: isImplicit):

			return [
				isImplicit ? PrintableTree("implicit") : nil,
				PrintableTree("identifier: \(identifier)"),
				PrintableTree("typeName: \(typeName)"), ]
		case let .classDeclaration(className: className, inherits: inherits, members: members):
			return  [
				PrintableTree(className),
				PrintableTree.ofStrings("inherits", inherits),
				PrintableTree.ofStatements("members", members), ]
		case let .companionObject(members: members):
			return ArrayClass<PrintableAsTree?>(members)
		case let .enumDeclaration(
			access: access,
			enumName: enumName,
			inherits: inherits,
			elements: elements,
			members: members,
			isImplicit: isImplicit):

			return [
				isImplicit ? PrintableTree("implicit") : nil,
				PrintableTree.initOrNil(access),
				PrintableTree(enumName),
				PrintableTree.ofStrings("inherits", inherits),
				PrintableTree("elements", ArrayClass<PrintableAsTree?>(elements)),
				PrintableTree.ofStatements("members", members), ]
		case let .protocolDeclaration(protocolName: protocolName, members: members):
			return [
				PrintableTree(protocolName),
				PrintableTree.ofStatements("members", members), ]
		case let .structDeclaration(
			annotations: annotations, structName: structName, inherits: inherits, members: members):

			return [
				PrintableTree.initOrNil(
					"annotations", [PrintableTree.initOrNil(annotations)]),
				PrintableTree(structName),
				PrintableTree.ofStrings("inherits", inherits),
				PrintableTree.ofStatements("members", members), ]
		case let .functionDeclaration(data: functionDeclaration):
			let parametersTrees = functionDeclaration.parameters
				.map { parameter -> PrintableAsTree? in
					PrintableTree(
						"parameter",
						[
							parameter.apiLabel.map { PrintableTree("api label: \($0)") },
							PrintableTree("label: \(parameter.label)"),
							PrintableTree("type: \(parameter.typeName)"),
							PrintableTree.initOrNil("value", [parameter.value]),
						])
			}

			return [
				functionDeclaration.extendsType.map { PrintableTree("extends type \($0)") },
				functionDeclaration.isImplicit ? PrintableTree("implicit") : nil,
				functionDeclaration.isStatic ? PrintableTree("static") : nil,
				functionDeclaration.isMutating ? PrintableTree("mutating") : nil,
				PrintableTree.initOrNil(functionDeclaration.access),
				PrintableTree("type: \(functionDeclaration.functionType)"),
				PrintableTree("prefix: \(functionDeclaration.prefix)"),
				PrintableTree("parameters", parametersTrees),
				PrintableTree("return type: \(functionDeclaration.returnType)"),
				PrintableTree.ofStatements(
					"statements", (functionDeclaration.statements ?? [])), ]
		case let .variableDeclaration(data: variableDeclaration):
			return [
				PrintableTree.initOrNil(
					"extendsType", [PrintableTree.initOrNil(variableDeclaration.extendsType)]),
				variableDeclaration.isImplicit ? PrintableTree("implicit") : nil,
				variableDeclaration.isStatic ? PrintableTree("static") : nil,
				variableDeclaration.isLet ? PrintableTree("let") : PrintableTree("var"),
				PrintableTree(variableDeclaration.identifier),
				PrintableTree(variableDeclaration.typeName),
				variableDeclaration.expression,
				PrintableTree.initOrNil(
					"getter",
					[variableDeclaration.getter.map { Statement.functionDeclaration(data: $0) }]),
				PrintableTree.initOrNil(
					"setter",
					[variableDeclaration.setter.map { Statement.functionDeclaration(data: $0) }]),
				PrintableTree.initOrNil(
					"annotations", [PrintableTree.initOrNil(variableDeclaration.annotations)]), ]
		case let .doStatement(statements: statements):
			return ArrayClass<PrintableAsTree?>(statements)

		case let .catchStatement(variableDeclaration: variableDeclaration, statements: statements):
			return [
				PrintableTree(
					"variableDeclaration", ArrayClass<PrintableAsTree?>([
							variableDeclaration.map { Statement.variableDeclaration(data: $0) },
						])),
				PrintableTree.ofStatements(
					"statements", statements),
			]

		case let .forEachStatement(
			collection: collection,
			variable: variable,
			statements: statements):

			return [
				PrintableTree("variable", [variable]),
				PrintableTree("collection", [collection]),
				PrintableTree.ofStatements("statements", statements), ]
		case let .whileStatement(expression: expression, statements: statements):
			return [
				PrintableTree.ofExpressions("expression", [expression]),
				PrintableTree.ofStatements("statements", statements), ]
		case let .ifStatement(data: ifStatement):
			let declarationTrees =
				ifStatement.declarations.map { Statement.variableDeclaration(data: $0) }
			let conditionTrees = ifStatement.conditions.map { $0.toStatement() }
			let elseStatementTrees = ifStatement.elseStatement
				.map({ Statement.ifStatement(data: $0) })?.printableSubtrees ?? []
			return [
				ifStatement.isGuard ? PrintableTree("guard") : nil,
				PrintableTree.ofStatements(
					"declarations", declarationTrees),
				PrintableTree.ofStatements(
					"conditions", conditionTrees),
				PrintableTree.ofStatements(
					"statements", ifStatement.statements),
				PrintableTree.initOrNil(
					"else", elseStatementTrees), ]
		case let .switchStatement(
			convertsToExpression: convertsToExpression,
			expression: expression,
			cases: cases):

			let caseItems = cases.map { switchCase -> PrintableAsTree? in
				PrintableTree("case item", [
					PrintableTree.ofExpressions(
						"expressions", switchCase.expressions),
					PrintableTree.ofStatements(
						"statements", switchCase.statements),
					])
			}

			return [
				PrintableTree.ofStatements(
					"converts to expression",
					convertsToExpression.map { [$0] } ?? []),
				PrintableTree.ofExpressions("expression", [expression]),
				PrintableTree("case items", caseItems), ]
		case let .deferStatement(statements: statements):
			return ArrayClass<PrintableAsTree?>(statements)
		case let .throwStatement(expression: expression):
			return [expression]
		case let .returnStatement(expression: expression):
			return [expression]
		case .breakStatement:
			return []
		case .continueStatement:
			return []
		case let .assignmentStatement(leftHand: leftHand, rightHand: rightHand):
			return [leftHand, rightHand]
		case .error:
			return []
		}
	}

	public static func == (lhs: Statement, rhs: Statement) -> Bool {
		if case let expressionStatement(expression: leftExpression) = lhs,
			case let expressionStatement(expression: rightExpression) = rhs
		{
			return leftExpression == rightExpression
		}
		if case let typealiasDeclaration(
				identifier: leftIdentifier,
				typeName: leftTypeName,
				isImplicit: leftIsImplicit) = lhs,
			case let typealiasDeclaration(
				identifier: rightIdentifier,
				typeName: rightTypeName,
				isImplicit: rightIsImplicit) = rhs
		{
			return leftIdentifier == rightIdentifier &&
				leftTypeName == rightTypeName &&
				leftIsImplicit == rightIsImplicit
		}
		if case let extensionDeclaration(
			typeName: leftTypeName,
			members: leftMembers) = lhs,
		case let extensionDeclaration(
			typeName: rightTypeName,
			members: rightMembers) = rhs
		{
			return leftTypeName == rightTypeName &&
				leftMembers == rightMembers
		}
		if case let importDeclaration(moduleName: leftModuleName) = lhs,
		case let importDeclaration(moduleName: rightModuleName) = rhs
		{
			return leftModuleName == rightModuleName
		}
		if case let classDeclaration(
			className: leftClassName,
			inherits: leftInherits,
			members: leftMembers) = lhs,
		case let classDeclaration(
			className: rightClassName,
			inherits: rightInherits,
			members: rightMembers) = rhs
		{
			return leftClassName == rightClassName &&
				leftInherits == rightInherits &&
				leftMembers == rightMembers
		}
		if case let companionObject(members: leftMembers) = lhs,
		case let companionObject(members: rightMembers) = rhs
		{
			return leftMembers == rightMembers
		}
		if case let enumDeclaration(
			access: leftAccess,
			enumName: leftEnumName,
			inherits: leftInherits,
			elements: leftElements,
			members: leftMembers,
			isImplicit: leftIsImplicit) = lhs,
		case let enumDeclaration(
			access: rightAccess,
			enumName: rightEnumName,
			inherits: rightInherits,
			elements: rightElements,
			members: rightMembers,
			isImplicit: rightIsImplicit) = rhs
		{
			return leftAccess == rightAccess &&
				leftEnumName == rightEnumName &&
				leftInherits == rightInherits &&
				leftElements == rightElements &&
				leftMembers == rightMembers &&
				leftIsImplicit == rightIsImplicit
		}
		if case let protocolDeclaration(
			protocolName: leftProtocolName,
			members: leftMembers) = lhs,
		case let protocolDeclaration(
			protocolName: rightProtocolName,
			members: rightMembers) = rhs
		{
			return leftProtocolName == rightProtocolName &&
				leftMembers == rightMembers
		}
		if case let structDeclaration(
			annotations: leftAnnotations,
			structName: leftStructName,
			inherits: leftInherits,
			members: leftMembers) = lhs,
		case let structDeclaration(
			annotations: rightAnnotations,
			structName: rightStructName,
			inherits: rightInherits,
			members: rightMembers) = rhs
		{
			return leftAnnotations == rightAnnotations &&
				leftStructName == rightStructName &&
				leftInherits == rightInherits &&
				leftMembers == rightMembers
		}
		if case let functionDeclaration(data: leftData) = lhs,
		case let functionDeclaration(data: rightData) = rhs
		{
			return leftData == rightData
		}
		if case let variableDeclaration(data: leftData) = lhs,
		case let variableDeclaration(data: rightData) = rhs
		{
			return leftData == rightData
		}
		if case let doStatement(statements: leftStatements) = lhs,
		case let doStatement(statements: rightStatements) = rhs
		{
			return leftStatements == rightStatements
		}
		if case let catchStatement(
			variableDeclaration: leftVariableDeclaration,
			statements: leftStatements) = lhs,
		case let catchStatement(
			variableDeclaration: rightVariableDeclaration,
			statements: rightStatements) = rhs
		{
			return leftVariableDeclaration == rightVariableDeclaration &&
				leftStatements == rightStatements
		}
		if case let forEachStatement(
			collection: leftCollection,
			variable: leftVariable,
			statements: leftStatements) = lhs,
		case let forEachStatement(
			collection: rightCollection,
			variable: rightVariable,
			statements: rightStatements) = rhs
		{
			return leftCollection == rightCollection &&
				leftVariable == rightVariable &&
				leftStatements == rightStatements
		}
		if case let whileStatement(
			expression: leftExpression,
			statements: leftStatements) = lhs,
		case let whileStatement(
			expression: rightExpression,
			statements: rightStatements) = rhs
		{
			return leftExpression == rightExpression &&
				leftStatements == rightStatements
		}
		if case let ifStatement(data: leftData) = lhs,
		case let ifStatement(data: rightData) = rhs
		{
			return leftData == rightData
		}
		if case let switchStatement(
			convertsToExpression: leftConvertsToExpression,
			expression: leftExpression,
			cases: leftCases) = lhs,
		case let switchStatement(
			convertsToExpression: rightConvertsToExpression,
			expression: rightExpression,
			cases: rightCases) = rhs
		{
			return leftConvertsToExpression == rightConvertsToExpression &&
			leftExpression == rightExpression &&
			leftCases == rightCases
		}
		if case let deferStatement(statements: leftStatements) = lhs,
		case let deferStatement(statements: rightStatements) = rhs
		{
			return leftStatements == rightStatements
		}
		if case let throwStatement(expression: leftExpression) = lhs,
		case let throwStatement(expression: rightExpression) = rhs
		{
			return leftExpression == rightExpression
		}
		if case let returnStatement(expression: leftExpression) = lhs,
		case let returnStatement(expression: rightExpression) = rhs
		{
			return leftExpression == rightExpression
		}
		if case .breakStatement = lhs,
			case .breakStatement = rhs
		{
			return true
		}
		if case .continueStatement = lhs,
			case .continueStatement = rhs
		{
			return true
		}
		if case let .assignmentStatement(
				leftHand: leftLeftHand,
				rightHand: leftRightHand) = lhs,
			case let .assignmentStatement(
				leftHand: rightLeftHand,
				rightHand: rightRightHand) = rhs
		{
			return leftLeftHand == rightLeftHand &&
				leftRightHand == rightRightHand
		}
		if case .error = lhs,
			case .error = rhs
		{
			return true
		}
		else {
			return false
		}
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////
// TODO: dictionaryExpression should have key-value pairs

extension PrintableTree {
	static func ofExpressions(_ description: String, _ subtrees: ArrayClass<Expression>)
		-> PrintableAsTree?
	{
		let newSubtrees = ArrayClass<PrintableAsTree?>(subtrees)
		return PrintableTree.initOrNil(description, newSubtrees)
	}
}

/// Necessary changes when adding a new expression:
/// - Add equatable support in Expression.==
/// - Add support for matching it in Library TranspilationPass
public class Expression: PrintableAsTree, Equatable {
	let name: String
	let range: SourceFileRange?

	init(range: SourceFileRange?, name: String) {
		self.range = range
		self.name = name
	}

	var swiftType: String? {
		fatalError("Accessing field in abstract class Expression")
	}

	// PrintableAsTree
	public var treeDescription: String {
		return name
	}

	public var printableSubtrees: ArrayClass<PrintableAsTree?> {
		fatalError("Accessing field in abstract class Expression")
	}

	public static func == (lhs: Expression, rhs: Expression) -> Bool {
		if let lhs = lhs as? LiteralCodeExpression,
			let rhs = rhs as? LiteralCodeExpression
		{
			return lhs.string == rhs.string
		}
		if let lhs = lhs as? LiteralDeclarationExpression,
			let rhs = rhs as? LiteralDeclarationExpression
		{
			return lhs.string == rhs.string
		}
		if let lhs = lhs as? TemplateExpression,
			let rhs = rhs as? TemplateExpression
		{
			return lhs.pattern == rhs.pattern &&
				lhs.matches == rhs.matches
		}
		if let lhs = lhs as? ParenthesesExpression,
			let rhs = rhs as? ParenthesesExpression
		{
			return lhs.expression == rhs.expression
		}
		if let lhs = lhs as? ForceValueExpression,
			let rhs = rhs as? ForceValueExpression
		{
			return lhs.expression == rhs.expression
		}
		if let lhs = lhs as? OptionalExpression,
			let rhs = rhs as? OptionalExpression
		{
			return lhs.expression == rhs.expression
		}
		if let lhs = lhs as? DeclarationReferenceExpression,
			let rhs = rhs as? DeclarationReferenceExpression
		{
			return lhs.data == rhs.data
		}
		if let lhs = lhs as? TypeExpression,
			let rhs = rhs as? TypeExpression
		{
			return lhs.typeName == rhs.typeName
		}
		if let lhs = lhs as? SubscriptExpression,
			let rhs = rhs as? SubscriptExpression
		{
			return lhs.subscriptedExpression == rhs.subscriptedExpression &&
				lhs.indexExpression == rhs.indexExpression &&
				lhs.typeName == rhs.typeName
		}
		if let lhs = lhs as? ArrayExpression,
			let rhs = rhs as? ArrayExpression
		{
			return lhs.elements == rhs.elements &&
				lhs.typeName == rhs.typeName
		}
		if let lhs = lhs as? DictionaryExpression,
			let rhs = rhs as? DictionaryExpression
		{
			return lhs.keys == rhs.keys &&
				lhs.values == rhs.values &&
				lhs.typeName == rhs.typeName
		}
		if let lhs = lhs as? ReturnExpression,
			let rhs = rhs as? ReturnExpression
		{
			return lhs.expression == rhs.expression
		}
		if let lhs = lhs as? DotExpression,
			let rhs = rhs as? DotExpression
		{
			return lhs.leftExpression == rhs.leftExpression &&
				lhs.rightExpression == rhs.rightExpression
		}
		if let lhs = lhs as? BinaryOperatorExpression,
			let rhs = rhs as? BinaryOperatorExpression
		{
			return lhs.leftExpression == rhs.leftExpression &&
				lhs.rightExpression == rhs.rightExpression &&
				lhs.operatorSymbol == rhs.operatorSymbol &&
				lhs.typeName == rhs.typeName
		}
		if let lhs = lhs as? PrefixUnaryExpression,
			let rhs = rhs as? PrefixUnaryExpression
		{
			return lhs.subExpression == rhs.subExpression &&
				lhs.operatorSymbol == rhs.operatorSymbol &&
				lhs.typeName == rhs.typeName
		}
		if let lhs = lhs as? PostfixUnaryExpression,
			let rhs = rhs as? PostfixUnaryExpression
		{
			return lhs.subExpression == rhs.subExpression &&
				lhs.operatorSymbol == rhs.operatorSymbol &&
				lhs.typeName == rhs.typeName
		}
		if let lhs = lhs as? IfExpression,
			let rhs = rhs as? IfExpression
		{
			return lhs.condition == rhs.condition &&
				lhs.trueExpression == rhs.trueExpression &&
				lhs.falseExpression == rhs.falseExpression
		}
		if let lhs = lhs as? CallExpression,
			let rhs = rhs as? CallExpression
		{
			return lhs.data == rhs.data
		}
		if let lhs = lhs as? ClosureExpression,
			let rhs = rhs as? ClosureExpression
		{
			return lhs.parameters == rhs.parameters &&
				lhs.statements == rhs.statements &&
				lhs.typeName == rhs.typeName
		}
		if let lhs = lhs as? LiteralIntExpression,
			let rhs = rhs as? LiteralIntExpression
		{
			return lhs.value == rhs.value
		}
		if let lhs = lhs as? LiteralUIntExpression,
			let rhs = rhs as? LiteralUIntExpression
		{
			return lhs.value == rhs.value
		}
		if let lhs = lhs as? LiteralDoubleExpression,
			let rhs = rhs as? LiteralDoubleExpression
		{
			return lhs.value == rhs.value
		}
		if let lhs = lhs as? LiteralFloatExpression,
			let rhs = rhs as? LiteralFloatExpression
		{
			return lhs.value == rhs.value
		}
		if let lhs = lhs as? LiteralBoolExpression,
			let rhs = rhs as? LiteralBoolExpression
		{
			return lhs.value == rhs.value
		}
		if let lhs = lhs as? LiteralStringExpression,
			let rhs = rhs as? LiteralStringExpression
		{
			return lhs.value == rhs.value
		}
		if let lhs = lhs as? LiteralCharacterExpression,
			let rhs = rhs as? LiteralCharacterExpression
		{
			return lhs.value == rhs.value
		}
		if lhs is NilLiteralExpression, rhs is NilLiteralExpression {
			return true
		}
		if let lhs = lhs as? InterpolatedStringLiteralExpression,
			let rhs = rhs as? InterpolatedStringLiteralExpression
		{
			return lhs.expressions == rhs.expressions
		}
		if let lhs = lhs as? TupleExpression,
			let rhs = rhs as? TupleExpression
		{
			return lhs.pairs == rhs.pairs
		}
		if let lhs = lhs as? TupleShuffleExpression,
			let rhs = rhs as? TupleShuffleExpression
		{
			return lhs.labels == rhs.labels &&
				lhs.indices == rhs.indices &&
				lhs.expressions == rhs.expressions
		}
		if lhs is ErrorExpression, rhs is ErrorExpression {
			return true
		}

		return false
	}
}

public class LiteralCodeExpression: Expression {
	let string: String

	init(range: SourceFileRange?, string: String) {
		self.string = string
		super.init(range: range, name: "LiteralCodeExpression".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: ArrayClass<PrintableAsTree?> {
		return [PrintableTree(string)]
	}

	override var swiftType: String? {
		return nil
	}

	public static func == (lhs: LiteralCodeExpression, rhs: LiteralCodeExpression) -> Bool {
		return lhs.swiftType == rhs.string
	}
}

public class LiteralDeclarationExpression: Expression {
	let string: String

	init(range: SourceFileRange?, string: String) {
		self.string = string
		super.init(range: range, name: "LiteralDeclarationExpression".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: ArrayClass<PrintableAsTree?> {
		return [PrintableTree(string)]
	}

	override var swiftType: String? {
		return nil
	}

	public static func == (
		lhs: LiteralDeclarationExpression,
		rhs: LiteralDeclarationExpression)
		-> Bool
	{
		return false
	}
}

public class TemplateExpression: Expression {
	let pattern: String
	let matches: DictionaryClass<String, Expression>

	init(range: SourceFileRange?, pattern: String, matches: DictionaryClass<String, Expression>) {
		self.pattern = pattern
		self.matches = matches
		super.init(range: range, name: "TemplateExpression".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: ArrayClass<PrintableAsTree?> {
		let matchesTrees = matches.map { PrintableTree($0.key, [$0.value]) }

		let sortedMatchesTrees = matchesTrees.sorted { a, b in
			a.treeDescription < b.treeDescription
		}

		return [
			PrintableTree("pattern \"\(pattern)\""),
			PrintableTree("matches", ArrayClass<PrintableAsTree?>(sortedMatchesTrees)), ]
	}

	override var swiftType: String? {
		return nil
	}

	public static func == (lhs: TemplateExpression, rhs: TemplateExpression) -> Bool {
		return false
	}
}

public class ParenthesesExpression: Expression {
	let expression: Expression

	init(range: SourceFileRange?, expression: Expression) {
		self.expression = expression
		super.init(range: range, name: "ParenthesesExpression".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: ArrayClass<PrintableAsTree?> {
		return [expression]
	}

	override var swiftType: String? {
		return expression.swiftType
	}

	public static func == (lhs: ParenthesesExpression, rhs: ParenthesesExpression) -> Bool {
		return lhs.expression == rhs.expression
	}
}

public class ForceValueExpression: Expression {
	let expression: Expression

	init(range: SourceFileRange?, expression: Expression) {
		self.expression = expression
		super.init(range: range, name: "ForceValueExpression".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: ArrayClass<PrintableAsTree?> {
		return [expression]
	}

	override var swiftType: String? {
		let subtype = expression.swiftType
		if let subtype = subtype, subtype.hasSuffix("?") {
			return String(subtype.dropLast())
		}
		else {
			return expression.swiftType
		}
	}

	public static func == (lhs: ForceValueExpression, rhs: ForceValueExpression) -> Bool {
		return lhs.expression == rhs.expression
	}
}

public class OptionalExpression: Expression {
	let expression: Expression

	init(range: SourceFileRange?, expression: Expression) {
		self.expression = expression
		super.init(range: range, name: "OptionalExpression".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: ArrayClass<PrintableAsTree?> {
		return [expression]
	}

	override var swiftType: String? {
		if let typeName = expression.swiftType {
			return String(typeName.dropLast()) // Drop the "?"
		}
		else {
			return nil
		}
	}

	public static func == (lhs: OptionalExpression, rhs: OptionalExpression) -> Bool {
		return lhs.expression == rhs.expression
	}
}

public class DeclarationReferenceExpression: Expression {
	let data: DeclarationReferenceData

	init(range: SourceFileRange?, data: DeclarationReferenceData) {
		self.data = data
		super.init(range: range, name: "DeclarationReferenceExpression".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: ArrayClass<PrintableAsTree?> {
		return [
			PrintableTree(data.typeName),
			PrintableTree(data.identifier),
			data.isStandardLibrary ? PrintableTree("isStandardLibrary") : nil,
			data.isImplicit ? PrintableTree("implicit") : nil, ]
	}

	override var swiftType: String? {
		return data.typeName
	}

	public static func == (
		lhs: DeclarationReferenceExpression,
		rhs: DeclarationReferenceExpression)
		-> Bool
	{
		return lhs.data == rhs.data
	}
}

public class TypeExpression: Expression {
	let typeName: String

	init(range: SourceFileRange?, typeName: String) {
		self.typeName = typeName
		super.init(range: range, name: "TypeExpression".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: ArrayClass<PrintableAsTree?> {
		return [PrintableTree(typeName)]
	}

	override var swiftType: String? {
		return typeName
	}

	public static func == (lhs: TypeExpression, rhs: TypeExpression) -> Bool {
		return lhs.typeName == rhs.typeName
	}
}

public class SubscriptExpression: Expression {
	let subscriptedExpression: Expression
	let indexExpression: Expression
	let typeName: String

	init(
		range: SourceFileRange?,
		subscriptedExpression: Expression,
		indexExpression: Expression,
		typeName: String)
	{
		self.subscriptedExpression = subscriptedExpression
		self.indexExpression = indexExpression
		self.typeName = typeName
		super.init(range: range, name: "SubscriptExpression".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: ArrayClass<PrintableAsTree?> {
		return [
			PrintableTree("type \(typeName)"),
			PrintableTree.ofExpressions("subscriptedExpression", [subscriptedExpression]),
			PrintableTree.ofExpressions("indexExpression", [indexExpression]), ]
	}

	override var swiftType: String? {
		return typeName
	}

	public static func == (lhs: SubscriptExpression, rhs: SubscriptExpression) -> Bool {
		return lhs.subscriptedExpression == rhs.subscriptedExpression &&
			lhs.indexExpression == rhs.indexExpression &&
			lhs.typeName == rhs.typeName
	}
}

public class ArrayExpression: Expression {
	let elements: ArrayClass<Expression>
	let typeName: String

	init(range: SourceFileRange?, elements: ArrayClass<Expression>, typeName: String) {
		self.elements = elements
		self.typeName = typeName
		super.init(range: range, name: "ArrayExpression".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: ArrayClass<PrintableAsTree?> {
		return [
			PrintableTree("type \(typeName)"),
			PrintableTree.ofExpressions("elements", elements), ]
	}

	override var swiftType: String? {
		return typeName
	}

	public static func == (lhs: ArrayExpression, rhs: ArrayExpression) -> Bool {
		return lhs.elements == rhs.elements &&
			lhs.typeName == rhs.typeName
	}
}

public class DictionaryExpression: Expression {
	let keys: ArrayClass<Expression>
	let values: ArrayClass<Expression>
	let typeName: String

	init(
		range: SourceFileRange?,
		keys: ArrayClass<Expression>,
		values: ArrayClass<Expression>,
		typeName: String)
	{
		self.keys = keys
		self.values = values
		self.typeName = typeName
		super.init(range: range, name: "DictionaryExpression".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: ArrayClass<PrintableAsTree?> {
		let keyValueTrees = zipToClass(keys, values).map
		{ (pair: (first: Expression, second: Expression)) -> PrintableAsTree? in
			PrintableTree("pair", [
				PrintableTree.ofExpressions("key", [pair.first]),
				PrintableTree.ofExpressions("value", [pair.second]),
				])
		}
		return [
			PrintableTree("type \(typeName)"),
			PrintableTree("key value pairs", keyValueTrees), ]
	}

	override var swiftType: String? {
		return typeName
	}

	public static func == (lhs: DictionaryExpression, rhs: DictionaryExpression) -> Bool {
		return lhs.keys == rhs.keys &&
			lhs.values == rhs.values &&
			lhs.typeName == rhs.typeName
	}
}

public class ReturnExpression: Expression {
	let expression: Expression?

	init(range: SourceFileRange?, expression: Expression?) {
		self.expression = expression
		super.init(range: range, name: "ReturnExpression".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: ArrayClass<PrintableAsTree?> {
		return [expression]
	}

	override var swiftType: String? {
		return expression?.swiftType
	}

	public static func == (lhs: ReturnExpression, rhs: ReturnExpression) -> Bool {
		return lhs.expression == rhs.expression
	}
}

public class DotExpression: Expression {
	let leftExpression: Expression
	let rightExpression: Expression

	init(range: SourceFileRange?, leftExpression: Expression, rightExpression: Expression) {
		self.leftExpression = leftExpression
		self.rightExpression = rightExpression
		super.init(range: range, name: "DotExpression".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: ArrayClass<PrintableAsTree?> {
		return [
			PrintableTree.ofExpressions("left", [leftExpression]),
			PrintableTree.ofExpressions("right", [rightExpression]), ]
	}

	override var swiftType: String? {
		// Enum references should be considered to have the left type, as the right expression's
		// is a function type (something like `(MyEnum.Type) -> MyEnum` or
		// `(A.MyEnum.Type) -> A.MyEnum`).
		if let leftType = leftExpression as? TypeExpression,
			let rightDeclarationReference = rightExpression as? DeclarationReferenceExpression
		{
			let enumType = leftType.typeName

			if rightDeclarationReference.data.typeName.hasPrefix("("),
				rightDeclarationReference.data.typeName.contains("\(enumType).Type) -> "),
				rightDeclarationReference.data.typeName.hasSuffix(enumType)
			{
				return enumType
			}
		}

		return rightExpression.swiftType
	}

	public static func == (lhs: DotExpression, rhs: DotExpression) -> Bool {
		return lhs.leftExpression == rhs.leftExpression &&
			lhs.rightExpression == rhs.rightExpression
	}
}

public class BinaryOperatorExpression: Expression {
	let leftExpression: Expression
	let rightExpression: Expression
	let operatorSymbol: String
	let typeName: String

	init(
		range: SourceFileRange?,
		leftExpression: Expression,
		rightExpression: Expression,
		operatorSymbol: String,
		typeName: String)
	{
		self.leftExpression = leftExpression
		self.rightExpression = rightExpression
		self.operatorSymbol = operatorSymbol
		self.typeName = typeName
		super.init(range: range, name: "BinaryOperatorExpression".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: ArrayClass<PrintableAsTree?> {
		return [
			PrintableTree("type \(typeName)"),
			PrintableTree.ofExpressions("left", [leftExpression]),
			PrintableTree("operator \(operatorSymbol)"),
			PrintableTree.ofExpressions("right", [rightExpression]), ]
	}

	override var swiftType: String? {
		return typeName
	}

	public static func == (lhs: BinaryOperatorExpression, rhs: BinaryOperatorExpression) -> Bool {
		return lhs.leftExpression == rhs.leftExpression &&
			lhs.rightExpression == rhs.rightExpression &&
			lhs.operatorSymbol == rhs.operatorSymbol &&
			lhs.typeName == rhs.typeName
	}
}

public class PrefixUnaryExpression: Expression {
	let subExpression: Expression
	let operatorSymbol: String
	let typeName: String

	init(
		range: SourceFileRange?,
		subExpression: Expression,
		operatorSymbol: String,
		typeName: String)
	{
		self.subExpression = subExpression
		self.operatorSymbol = operatorSymbol
		self.typeName = typeName
		super.init(range: range, name: "PrefixUnaryExpression".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: ArrayClass<PrintableAsTree?> {
		return [
			PrintableTree("type \(typeName)"),
			PrintableTree("operator \(operatorSymbol)"),
			PrintableTree.ofExpressions("expression", [subExpression]), ]
	}

	override var swiftType: String? {
		return typeName
	}

	public static func == (lhs: PrefixUnaryExpression, rhs: PrefixUnaryExpression) -> Bool {
		return lhs.subExpression == rhs.subExpression &&
			lhs.operatorSymbol == rhs.operatorSymbol &&
			lhs.typeName == rhs.typeName
	}
}

public class PostfixUnaryExpression: Expression {
	let subExpression: Expression
	let operatorSymbol: String
	let typeName: String

	init(
		range: SourceFileRange?,
		subExpression: Expression,
		operatorSymbol: String,
		typeName: String)
	{
		self.subExpression = subExpression
		self.operatorSymbol = operatorSymbol
		self.typeName = typeName
		super.init(range: range, name: "PrefixUnaryExpression".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: ArrayClass<PrintableAsTree?> {
		return [
			PrintableTree("type \(typeName)"),
			PrintableTree("operator \(operatorSymbol)"),
			PrintableTree.ofExpressions("expression", [subExpression]), ]
	}

	override var swiftType: String? {
		return typeName
	}

	public static func == (lhs: PostfixUnaryExpression, rhs: PostfixUnaryExpression) -> Bool {
		return lhs.subExpression == rhs.subExpression &&
			lhs.operatorSymbol == rhs.operatorSymbol &&
			lhs.typeName == rhs.typeName
	}
}

public class IfExpression: Expression {
	let condition: Expression
	let trueExpression: Expression
	let falseExpression: Expression

	init(
		range: SourceFileRange?,
		condition: Expression,
		trueExpression: Expression,
		falseExpression: Expression)
	{
		self.condition = condition
		self.trueExpression = trueExpression
		self.falseExpression = falseExpression
		super.init(range: range, name: "IfExpression".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: ArrayClass<PrintableAsTree?> {
		return [
			PrintableTree.ofExpressions("condition", [condition]),
			PrintableTree.ofExpressions("trueExpression", [trueExpression]),
			PrintableTree.ofExpressions("falseExpression", [falseExpression]), ]
	}

	override var swiftType: String? {
		return trueExpression.swiftType
	}

	public static func == (lhs: IfExpression, rhs: IfExpression) -> Bool {
		return lhs.condition == rhs.condition &&
			lhs.trueExpression == rhs.trueExpression &&
			lhs.falseExpression == rhs.falseExpression
	}
}

public class CallExpression: Expression {
	let data: CallExpressionData

	init(range: SourceFileRange?, data: CallExpressionData) {
		self.data = data
		super.init(range: range, name: "CallExpression".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: ArrayClass<PrintableAsTree?> {
		return [
			PrintableTree("type \(data.typeName)"),
			PrintableTree.ofExpressions("function", [data.function]),
			PrintableTree.ofExpressions("parameters", [data.parameters]), ]
	}

	override var swiftType: String? {
		return data.typeName
	}

	public static func == (lhs: CallExpression, rhs: CallExpression) -> Bool {
		return lhs.data == rhs.data
	}
}

public class ClosureExpression: Expression {
	let parameters: ArrayClass<LabeledType>
	let statements: ArrayClass<Statement>
	let typeName: String

	init(
		range: SourceFileRange?,
		parameters: ArrayClass<LabeledType>,
		statements: ArrayClass<Statement>,
		typeName: String)
	{
		self.parameters = parameters
		self.statements = statements
		self.typeName = typeName
		super.init(range: range, name: "ClosureExpression".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: ArrayClass<PrintableAsTree?> {
		let parametersString =
			"(" + parameters.map { $0.label + ":" }.joined(separator: ", ") + ")"
		return [
			PrintableTree(typeName),
			PrintableTree(parametersString),
			PrintableTree.ofStatements("statements", statements), ]
	}

	override var swiftType: String? {
		return typeName
	}

	public static func == (lhs: ClosureExpression, rhs: ClosureExpression) -> Bool {
		return lhs.parameters == rhs.parameters &&
			lhs.parameters == rhs.parameters &&
			lhs.typeName == rhs.typeName
	}
}

public class LiteralIntExpression: Expression {
	let value: Int64

	init(range: SourceFileRange?, value: Int64) {
		self.value = value
		super.init(range: range, name: "LiteralIntExpression".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: ArrayClass<PrintableAsTree?> {
		return [PrintableTree(String(value))]
	}

	override var swiftType: String? {
		return "Int"
	}

	public static func == (lhs: LiteralIntExpression, rhs: LiteralIntExpression) -> Bool {
		return lhs.value == rhs.value
	}
}

public class LiteralUIntExpression: Expression {
	let value: UInt64

	init(range: SourceFileRange?, value: UInt64) {
		self.value = value
		super.init(range: range, name: "LiteralUIntExpression".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: ArrayClass<PrintableAsTree?> {
		return [PrintableTree(String(value))]
	}

	override var swiftType: String? {
		return "UInt"
	}

	public static func == (lhs: LiteralUIntExpression, rhs: LiteralUIntExpression) -> Bool {
		return lhs.value == rhs.value
	}
}

public class LiteralDoubleExpression: Expression {
	let value: Double

	init(range: SourceFileRange?, value: Double) {
		self.value = value
		super.init(range: range, name: "LiteralDoubleExpression".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: ArrayClass<PrintableAsTree?> {
		return [PrintableTree(String(value))]
	}

	override var swiftType: String? {
		return "Double"
	}

	public static func == (lhs: LiteralDoubleExpression, rhs: LiteralDoubleExpression) -> Bool {
		return lhs.value == rhs.value
	}
}

public class LiteralFloatExpression: Expression {
	let value: Float

	init(range: SourceFileRange?, value: Float) {
		self.value = value
		super.init(range: range, name: "LiteralFloatExpression".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: ArrayClass<PrintableAsTree?> {
		return [PrintableTree(String(value))]
	}

	override var swiftType: String? {
		return "Float"
	}

	public static func == (lhs: LiteralFloatExpression, rhs: LiteralFloatExpression) -> Bool {
		return lhs.value == rhs.value
	}
}

public class LiteralBoolExpression: Expression {
	let value: Bool

	init(range: SourceFileRange?, value: Bool) {
		self.value = value
		super.init(range: range, name: "LiteralBoolExpression".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: ArrayClass<PrintableAsTree?> {
		return [PrintableTree(String(value))]
	}

	override var swiftType: String? {
		return "Bool"
	}

	public static func == (lhs: LiteralBoolExpression, rhs: LiteralBoolExpression) -> Bool {
		return lhs.value == rhs.value
	}
}

public class LiteralStringExpression: Expression {
	let value: String

	init(range: SourceFileRange?, value: String) {
		self.value = value
		super.init(range: range, name: "LiteralStringExpression".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: ArrayClass<PrintableAsTree?> {
		return [PrintableTree(String(value))]
	}

	override var swiftType: String? {
		return "String"
	}

	public static func == (lhs: LiteralStringExpression, rhs: LiteralStringExpression) -> Bool {
		return lhs.value == rhs.value
	}
}

public class LiteralCharacterExpression: Expression {
	let value: String

	init(range: SourceFileRange?, value: String) {
		self.value = value
		super.init(range: range, name: "LiteralCharacterExpression".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: ArrayClass<PrintableAsTree?> {
		return [PrintableTree(String(value))]
	}

	override var swiftType: String? {
		return "Character"
	}

	public static func == (lhs: LiteralCharacterExpression, rhs: LiteralCharacterExpression) -> Bool
	{
		return lhs.value == rhs.value
	}
}

public class NilLiteralExpression: Expression {
	init(range: SourceFileRange?) {
		super.init(range: range, name: "NilLiteralExpression".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: ArrayClass<PrintableAsTree?> {
		return []
	}

	override var swiftType: String? {
		return nil
	}

	public static func == (lhs: NilLiteralExpression, rhs: NilLiteralExpression) -> Bool {
		return true
	}
}

public class InterpolatedStringLiteralExpression: Expression {
	let expressions: ArrayClass<Expression>

	init(range: SourceFileRange?, expressions: ArrayClass<Expression>) {
		self.expressions = expressions
		super.init(
			range: range,
			name: "InterpolatedStringLiteralExpression".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: ArrayClass<PrintableAsTree?> {
		return [PrintableTree.ofExpressions("expressions", expressions)]
	}

	override var swiftType: String? {
		return "String"
	}

	public static func == (
		lhs: InterpolatedStringLiteralExpression,
		rhs: InterpolatedStringLiteralExpression)
		-> Bool
	{
		return lhs.expressions == rhs.expressions
	}
}

public class TupleExpression: Expression {
	let pairs: ArrayClass<LabeledExpression>

	init(range: SourceFileRange?, pairs: ArrayClass<LabeledExpression>) {
		self.pairs = pairs
		super.init(range: range, name: "TupleExpression".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: ArrayClass<PrintableAsTree?> {
		return pairs.map {
			PrintableTree.ofExpressions(($0.label ?? "_") + ":", [$0.expression])
		}
	}

	override var swiftType: String? {
		return nil
	}

	public static func == (lhs: TupleExpression, rhs: TupleExpression) -> Bool {
		return lhs.pairs == rhs.pairs
	}
}

public class TupleShuffleExpression: Expression {
	let labels: ArrayClass<String>
	let indices: ArrayClass<TupleShuffleIndex>
	let expressions: ArrayClass<Expression>

	init(
		range: SourceFileRange?,
		labels: ArrayClass<String>,
		indices: ArrayClass<TupleShuffleIndex>,
		expressions: ArrayClass<Expression>)
	{
		self.labels = labels
		self.indices = indices
		self.expressions = expressions
		super.init(range: range, name: "TupleShuffleExpression".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: ArrayClass<PrintableAsTree?> {
		return [
			PrintableTree.ofStrings("labels", labels),
			PrintableTree.ofStrings("indices", indices.map { $0.description }),
			PrintableTree.ofExpressions("expressions", expressions), ]
	}

	override var swiftType: String? {
		return nil
	}

	public static func == (lhs: TupleShuffleExpression, rhs: TupleShuffleExpression) -> Bool {
		return lhs.labels == rhs.labels &&
			lhs.indices == rhs.indices &&
			lhs.expressions == rhs.expressions
	}
}

public class ErrorExpression: Expression {
	init(range: SourceFileRange?) {
		super.init(range: range, name: "ErrorExpression".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: ArrayClass<PrintableAsTree?> {
		return []
	}

	override var swiftType: String? {
		return "<<Error>>"
	}

	public static func == (lhs: ErrorExpression, rhs: ErrorExpression) -> Bool {
		return true
	}
}

public struct LabeledExpression: Equatable {
	let label: String?
	let expression: Expression
}

public struct LabeledType: Equatable {
	let label: String
	let typeName: String
}

public struct FunctionParameter: Equatable {
	let label: String
	let apiLabel: String?
	let typeName: String
	let value: Expression?
}

public class VariableDeclarationData: Equatable {
	var identifier: String
	var typeName: String
	var expression: Expression?
	var getter: FunctionDeclarationData?
	var setter: FunctionDeclarationData?
	var isLet: Bool
	var isImplicit: Bool
	var isStatic: Bool
	var extendsType: String?
	var annotations: String?

	init(
		identifier: String,
		typeName: String,
		expression: Expression?,
		getter: FunctionDeclarationData?,
		setter: FunctionDeclarationData?,
		isLet: Bool,
		isImplicit: Bool,
		isStatic: Bool,
		extendsType: String?,
		annotations: String?)
	{
		self.identifier = identifier
		self.typeName = typeName
		self.expression = expression
		self.getter = getter
		self.setter = setter
		self.isLet = isLet
		self.isImplicit = isImplicit
		self.isStatic = isStatic
		self.extendsType = extendsType
		self.annotations = annotations
	}

	public static func == (
		lhs: VariableDeclarationData,
		rhs: VariableDeclarationData)
		-> Bool
	{
		return lhs.identifier == rhs.identifier &&
			lhs.typeName == rhs.typeName &&
			lhs.expression == rhs.expression &&
			lhs.getter == rhs.getter &&
			lhs.setter == rhs.setter &&
			lhs.isLet == rhs.isLet &&
			lhs.isImplicit == rhs.isImplicit &&
			lhs.isStatic == rhs.isStatic &&
			lhs.extendsType == rhs.extendsType &&
			lhs.annotations == rhs.annotations
	}
}

public class DeclarationReferenceData: Equatable {
	var identifier: String
	var typeName: String
	var isStandardLibrary: Bool
	var isImplicit: Bool
	var range: SourceFileRange?

	init(
		identifier: String,
		typeName: String,
		isStandardLibrary: Bool,
		isImplicit: Bool,
		range: SourceFileRange?)
	{
		self.identifier = identifier
		self.typeName = typeName
		self.isStandardLibrary = isStandardLibrary
		self.isImplicit = isImplicit
		self.range = range
	}

	public static func == (
		lhs: DeclarationReferenceData,
		rhs: DeclarationReferenceData)
		-> Bool
	{
		return lhs.identifier == rhs.identifier &&
			lhs.typeName == rhs.typeName &&
			lhs.isStandardLibrary == rhs.isStandardLibrary &&
			lhs.isImplicit == rhs.isImplicit &&
			lhs.range == rhs.range
	}
}

public class CallExpressionData: Equatable {
	let function: Expression
	let parameters: Expression
	let typeName: String
	let range: SourceFileRange?

	init(
		function: Expression,
		parameters: Expression,
		typeName: String,
		range: SourceFileRange?)
	{
		self.function = function
		self.parameters = parameters
		self.typeName = typeName
		self.range = range
	}

	public static func == (
		lhs: CallExpressionData,
		rhs: CallExpressionData)
		-> Bool
	{
		return lhs.function == rhs.function &&
			lhs.parameters == rhs.parameters &&
			lhs.typeName == rhs.typeName &&
			lhs.range == rhs.range
	}
}

public class FunctionDeclarationData: Equatable {
	var prefix: String
	var parameters: ArrayClass<FunctionParameter>
	var returnType: String
	var functionType: String
	var genericTypes: ArrayClass<String>
	var isImplicit: Bool
	var isStatic: Bool
	var isMutating: Bool
	var isPure: Bool
	var extendsType: String?
	var statements: ArrayClass<Statement>?
	var access: String?
	var annotations: String?

	init(
		prefix: String,
		parameters: ArrayClass<FunctionParameter>,
		returnType: String,
		functionType: String,
		genericTypes: ArrayClass<String>,
		isImplicit: Bool,
		isStatic: Bool,
		isMutating: Bool,
		isPure: Bool,
		extendsType: String?,
		statements: ArrayClass<Statement>?,
		access: String?,
		annotations: String?)
	{
		self.prefix = prefix
		self.parameters = parameters
		self.returnType = returnType
		self.functionType = functionType
		self.genericTypes = genericTypes
		self.isImplicit = isImplicit
		self.isStatic = isStatic
		self.isMutating = isMutating
		self.isPure = isPure
		self.extendsType = extendsType
		self.statements = statements
		self.access = access
		self.annotations = annotations
	}

	public static func == (
		lhs: FunctionDeclarationData,
		rhs: FunctionDeclarationData)
		-> Bool
	{
		return lhs.prefix == rhs.prefix &&
			lhs.parameters == rhs.parameters &&
			lhs.returnType == rhs.returnType &&
			lhs.functionType == rhs.functionType &&
			lhs.genericTypes == rhs.genericTypes &&
			lhs.isImplicit == rhs.isImplicit &&
			lhs.isStatic == rhs.isStatic &&
			lhs.isMutating == rhs.isMutating &&
			lhs.isPure == rhs.isPure &&
			lhs.extendsType == rhs.extendsType &&
			lhs.statements == rhs.statements &&
			lhs.access == rhs.access &&
			lhs.annotations == rhs.annotations
	}
}

public class IfStatementData: Equatable {
	var conditions: ArrayClass<IfCondition>
	var declarations: ArrayClass<VariableDeclarationData>
	var statements: ArrayClass<Statement>
	var elseStatement: IfStatementData?
	var isGuard: Bool

	public enum IfCondition: Equatable {
		case condition(expression: Expression)
		case declaration(variableDeclaration: VariableDeclarationData)

		func toStatement() -> Statement {
			switch self {
			case let .condition(expression: expression):
				return .expressionStatement(expression: expression)
			case let .declaration(variableDeclaration: variableDeclaration):
				return .variableDeclaration(data: variableDeclaration)
			}
		}
	}

	public init(
		conditions: ArrayClass<IfCondition>,
		declarations: ArrayClass<VariableDeclarationData>,
		statements: ArrayClass<Statement>,
		elseStatement: IfStatementData?,
		isGuard: Bool)
	{
		self.conditions = conditions
		self.declarations = declarations
		self.statements = statements
		self.elseStatement = elseStatement
		self.isGuard = isGuard
	}

	public static func == (
		lhs: IfStatementData,
		rhs: IfStatementData)
		-> Bool
	{
		return lhs.conditions == rhs.conditions &&
			lhs.declarations == rhs.declarations &&
			lhs.statements == rhs.statements &&
			lhs.elseStatement == rhs.elseStatement &&
			lhs.isGuard == rhs.isGuard
	}
}

public class SwitchCase: Equatable {
	var expressions: ArrayClass<Expression>
	var statements: ArrayClass<Statement>

	init(
		expressions: ArrayClass<Expression>,
		statements: ArrayClass<Statement>)
	{
		self.expressions = expressions
		self.statements = statements
	}

	public static func == (lhs: SwitchCase, rhs: SwitchCase) -> Bool {
		return lhs.expressions == rhs.expressions &&
			lhs.statements == rhs.statements
	}
}

public class EnumElement: PrintableAsTree, Equatable {
	var name: String
	var associatedValues: ArrayClass<LabeledType>
	var rawValue: Expression?
	var annotations: String?

	init(
		name: String,
		associatedValues: ArrayClass<LabeledType>,
		rawValue: Expression?,
		annotations: String?)
	{
		self.name = name
		self.associatedValues = associatedValues
		self.rawValue = rawValue
		self.annotations = annotations
	}

	public static func == (lhs: EnumElement, rhs: EnumElement) -> Bool {
		return lhs.name == rhs.name &&
		lhs.associatedValues == rhs.associatedValues &&
		lhs.rawValue == rhs.rawValue &&
		lhs.annotations == rhs.annotations
	}

	public var treeDescription: String { // annotation: override
		return ".\(self.name)"
	}

	public var printableSubtrees: ArrayClass<PrintableAsTree?> { // annotation: override
		let associatedValues = self.associatedValues
			.map { "\($0.label): \($0.typeName)" }
			.joined(separator: ", ")
		let associatedValuesString = (associatedValues.isEmpty) ?
			nil :
			"values: \(associatedValues)"
		return [
			PrintableTree.initOrNil(associatedValuesString),
			PrintableTree.initOrNil(self.annotations), ]
	}
}

public enum TupleShuffleIndex: Equatable, CustomStringConvertible {
	case variadic(count: Int)
	case absent
	case present

	public var description: String { // annotation: override
		switch self {
		case let .variadic(count: count):
			return "variadics: \(count)"
		case .absent:
			return "absent"
		case .present:
			return "present"
		}
	}

	public static func == (lhs: TupleShuffleIndex, rhs: TupleShuffleIndex) -> Bool {
		if case let .variadic(count: lhsCount) = lhs,
			case let .variadic(count: rhsCount) = rhs
		{
			return (lhsCount == rhsCount)
		}
		else if case .absent = lhs,
			case .absent = rhs
		{
			return true
		}
		else if case .present = lhs,
			case .present = rhs
		{
			return true
		}
		else {
			return false
		}
	}
}
