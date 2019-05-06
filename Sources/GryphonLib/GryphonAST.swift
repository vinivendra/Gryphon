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
	public static func == (lhs: GryphonAST, rhs: GryphonAST) -> Bool { // kotlin: ignore
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
		case let .expressionStatement(expression: expression):
			return [expression]
		case let .extensionDeclaration(typeName: typeName, members: members):
			return [PrintableTree(typeName),
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

public indirect enum Expression: PrintableAsTree, Equatable {

	case literalCodeExpression(
		string: String)
	case literalDeclarationExpression(
		string: String)
	case templateExpression(
		pattern: String,
		matches: DictionaryClass<String, Expression>)
	case parenthesesExpression(
		expression: Expression)
	case forceValueExpression(
		expression: Expression)
	case optionalExpression(
		expression: Expression)
	case declarationReferenceExpression(
		data: DeclarationReferenceData)
	case typeExpression(
		typeName: String)
	case subscriptExpression(
		subscriptedExpression: Expression,
		indexExpression: Expression,
		typeName: String)
	case arrayExpression(
		elements: ArrayClass<Expression>,
		typeName: String)
	case dictionaryExpression(
		keys: ArrayClass<Expression>,
		values: ArrayClass<Expression>,
		typeName: String)
	case returnExpression(
		expression: Expression?)
	case dotExpression(
		leftExpression: Expression,
		rightExpression: Expression)
	case binaryOperatorExpression(
		leftExpression: Expression,
		rightExpression: Expression,
		operatorSymbol: String,
		typeName: String)
	case prefixUnaryExpression(
		expression: Expression,
		operatorSymbol: String,
		typeName: String)
	case postfixUnaryExpression(
		expression: Expression,
		operatorSymbol: String,
		typeName: String)
	case ifExpression(
		condition: Expression,
		trueExpression: Expression,
		falseExpression: Expression)
	case callExpression(
		data: CallExpressionData)
	case closureExpression(
		parameters: ArrayClass<LabeledType>,
		statements: ArrayClass<Statement>,
		typeName: String)
	case literalIntExpression(
		value: Int64)
	case literalUIntExpression(
		value: UInt64)
	case literalDoubleExpression(
		value: Double)
	case literalFloatExpression(
		value: Float)
	case literalBoolExpression(
		value: Bool)
	case literalStringExpression(
		value: String)
	case literalCharacterExpression(
		value: String)
	case nilLiteralExpression
	case interpolatedStringLiteralExpression(
		expressions: ArrayClass<Expression>)
	case tupleExpression(
		pairs: ArrayClass<LabeledExpression>)
	case tupleShuffleExpression(
		labels: ArrayClass<String>,
		indices: ArrayClass<TupleShuffleIndex>,
		expressions: ArrayClass<Expression>)
	case error

	//
	public var name: String {
		switch self {
		case .templateExpression:
			return "templateExpression".capitalizedAsCamelCase()
		case .literalCodeExpression:
			return "literalCodeExpression".capitalizedAsCamelCase()
		case .literalDeclarationExpression:
			return "literalDeclarationExpression".capitalizedAsCamelCase()
		case .parenthesesExpression:
			return "parenthesesExpression".capitalizedAsCamelCase()
		case .forceValueExpression:
			return "forceValueExpression".capitalizedAsCamelCase()
		case .optionalExpression:
			return "optionalExpression".capitalizedAsCamelCase()
		case .declarationReferenceExpression:
			return "declarationReferenceExpression".capitalizedAsCamelCase()
		case .typeExpression:
			return "typeExpression".capitalizedAsCamelCase()
		case .subscriptExpression:
			return "subscriptExpression".capitalizedAsCamelCase()
		case .arrayExpression:
			return "arrayExpression".capitalizedAsCamelCase()
		case .dictionaryExpression:
			return "dictionaryExpression".capitalizedAsCamelCase()
		case .returnExpression:
			return "returnExpression".capitalizedAsCamelCase()
		case .dotExpression:
			return "dotExpression".capitalizedAsCamelCase()
		case .binaryOperatorExpression:
			return "binaryOperatorExpression".capitalizedAsCamelCase()
		case .prefixUnaryExpression:
			return "prefixUnaryExpression".capitalizedAsCamelCase()
		case .postfixUnaryExpression:
			return "postfixUnaryExpression".capitalizedAsCamelCase()
		case .ifExpression:
			return "ifExpression".capitalizedAsCamelCase()
		case .callExpression:
			return "callExpression".capitalizedAsCamelCase()
		case .closureExpression:
			return "closureExpression".capitalizedAsCamelCase()
		case .literalIntExpression:
			return "literalIntExpression".capitalizedAsCamelCase()
		case .literalUIntExpression:
			return "literalUIntExpression".capitalizedAsCamelCase()
		case .literalDoubleExpression:
			return "literalDoubleExpression".capitalizedAsCamelCase()
		case .literalFloatExpression:
			return "literalFloatExpression".capitalizedAsCamelCase()
		case .literalBoolExpression:
			return "literalBoolExpression".capitalizedAsCamelCase()
		case .literalStringExpression:
			return "literalStringExpression".capitalizedAsCamelCase()
		case .literalCharacterExpression:
			return "literalCharacterExpression".capitalizedAsCamelCase()
		case .nilLiteralExpression:
			return "nilLiteralExpression".capitalizedAsCamelCase()
		case .interpolatedStringLiteralExpression:
			return "interpolatedStringLiteralExpression".capitalizedAsCamelCase()
		case .tupleExpression:
			return "tupleExpression".capitalizedAsCamelCase()
		case .tupleShuffleExpression:
			return "tupleShuffleExpression".capitalizedAsCamelCase()
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
		case let .templateExpression(pattern: pattern, matches: matches):
			let matchesTrees = ArrayClass<PrintableAsTree?>(
				matches.map { PrintableTree($0.key, [$0.value]) })

			return [
				PrintableTree("pattern \"\(pattern)\""),
				PrintableTree("matches", matchesTrees), ]
		case .literalCodeExpression(string: let string):
			return [PrintableTree(string)]
		case .literalDeclarationExpression(string: let string):
			return [PrintableTree(string)]
		case let .parenthesesExpression(expression: expression):
			return [expression]
		case let .forceValueExpression(expression: expression):
			return [expression]
		case let .optionalExpression(expression: expression):
			return [expression]
		case let .declarationReferenceExpression(data: expression):
			return [
				PrintableTree(expression.typeName),
				PrintableTree(expression.identifier),
				expression.isStandardLibrary ? PrintableTree("isStandardLibrary") : nil,
				expression.isImplicit ? PrintableTree("implicit") : nil, ]
		case let .typeExpression(typeName: typeName):
			return [PrintableTree(typeName)]
		case let .subscriptExpression(
			subscriptedExpression: subscriptedExpression, indexExpression: indexExpression,
			typeName: typeName):

			return [
				PrintableTree("type \(typeName)"),
				PrintableTree.ofExpressions("subscriptedExpression", [subscriptedExpression]),
				PrintableTree.ofExpressions("indexExpression", [indexExpression]), ]
		case let .arrayExpression(elements: elements, typeName: typeName):
			return [
				PrintableTree("type \(typeName)"),
				PrintableTree.ofExpressions("elements", elements), ]
		case let .dictionaryExpression(keys: keys, values: values, typeName: typeName):
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
		case let .returnExpression(expression: expression):
			return [expression]
		case let .dotExpression(leftExpression: leftExpression, rightExpression: rightExpression):
			return [
				PrintableTree.ofExpressions("left", [leftExpression]),
				PrintableTree.ofExpressions("right", [rightExpression]), ]
		case let .binaryOperatorExpression(
			leftExpression: leftExpression,
			rightExpression: rightExpression,
			operatorSymbol: operatorSymbol,
			typeName: typeName):

			return [
				PrintableTree("type \(typeName)"),
				PrintableTree.ofExpressions("left", [leftExpression]),
				PrintableTree("operator \(operatorSymbol)"),
				PrintableTree.ofExpressions("right", [rightExpression]), ]
		case let .prefixUnaryExpression(
			expression: expression, operatorSymbol: operatorSymbol, typeName: typeName):

			return [
				PrintableTree("type \(typeName)"),
				PrintableTree("operator \(operatorSymbol)"),
				PrintableTree.ofExpressions("expression", [expression]), ]
		case let .ifExpression(
			condition: condition, trueExpression: trueExpression, falseExpression: falseExpression):

			return [
				PrintableTree.ofExpressions("condition", [condition]),
				PrintableTree.ofExpressions("trueExpression", [trueExpression]),
				PrintableTree.ofExpressions("falseExpression", [falseExpression]), ]
		case let .postfixUnaryExpression(
			expression: expression, operatorSymbol: operatorSymbol, typeName: typeName):

			return [
				PrintableTree("type \(typeName)"),
				PrintableTree("operator \(operatorSymbol)"),
				PrintableTree.ofExpressions("expression", [expression]), ]
		case let .callExpression(data: callExpression):
			return [
				PrintableTree("type \(callExpression.typeName)"),
				PrintableTree.ofExpressions("function", [callExpression.function]),
				PrintableTree.ofExpressions("parameters", [callExpression.parameters]), ]
		case let .closureExpression(
			parameters: parameters, statements: statements, typeName: typeName):

			let parametersString =
				"(" + parameters.map { $0.label + ":" }.joined(separator: ", ") + ")"
			return [
				PrintableTree(typeName),
				PrintableTree(parametersString),
				PrintableTree.ofStatements("statements", statements), ]
		case let .tupleExpression(pairs: pairs):
			return pairs.map {
				PrintableTree.ofExpressions(($0.label ?? "_") + ":", [$0.expression])
			}
		case let .tupleShuffleExpression(
			labels: labels, indices: indices, expressions: expressions):

			return [
				PrintableTree.ofStrings("labels", labels),
				PrintableTree.ofStrings("indices", indices.map { $0.description }),
				PrintableTree.ofExpressions("expressions", expressions), ]
		case let .literalIntExpression(value: value):
			return [PrintableTree(String(value))]
		case let .literalUIntExpression(value: value):
			return [PrintableTree(String(value))]
		case let .literalDoubleExpression(value: value):
			return [PrintableTree(String(value))]
		case let .literalFloatExpression(value: value):
			return [PrintableTree(String(value))]
		case let .literalBoolExpression(value: value):
			return [PrintableTree(String(value))]
		case let .literalStringExpression(value: value):
			return [PrintableTree("\"\(value)\"")]
		case let .literalCharacterExpression(value: value):
			return [PrintableTree("'\(value)'")]
		case .nilLiteralExpression:
			return []
		case let .interpolatedStringLiteralExpression(expressions: expressions):
			return [PrintableTree.ofExpressions("expressions", expressions)]
		case .error:
			return []
		}
	}

	// TODO: Add support for `case .a, .b:`
	public var swiftType: String? {
		switch self {
		case .templateExpression:
			return nil
		case .literalCodeExpression:
			return nil
		case .literalDeclarationExpression:
			return nil
		case let .parenthesesExpression(expression: expression):
			return expression.swiftType
		case let .forceValueExpression(expression: expression):
			let subtype = expression.swiftType
			if let subtype = subtype, subtype.hasSuffix("?") {
				return String(subtype.dropLast())
			}
			else {
				return expression.swiftType
			}

		case let .optionalExpression(expression: expression):
			if let typeName = expression.swiftType {
				return String(typeName.dropLast()) // Drop the "?"
			}
			else {
				return nil
			}
		case let .declarationReferenceExpression(data: declarationReferenceExpression):
			return declarationReferenceExpression.typeName
		case let .typeExpression(typeName: typeName):
			return typeName
		case let .subscriptExpression(
			subscriptedExpression: _, indexExpression: _, typeName: typeName):

			return typeName
		case let .arrayExpression(elements: _, typeName: typeName):
			return typeName
		case let .dictionaryExpression(keys: _, values: _, typeName: typeName):
			return typeName
		case let .returnExpression(expression: expression):
			return expression?.swiftType
		case let .dotExpression(leftExpression: leftExpression, rightExpression: rightExpression):

			// Enum references should be considered to have the left type, as the right expression's
			// is a function type (something like `(MyEnum.Type) -> MyEnum` or
			// `(A.MyEnum.Type) -> A.MyEnum`).
			if case let .typeExpression(typeName: enumType) = leftExpression,
				case let .declarationReferenceExpression(
					data: declarationReferenceExpression) = rightExpression
			{
				if declarationReferenceExpression.typeName.hasPrefix("("),
				declarationReferenceExpression.typeName.contains("\(enumType).Type) -> "),
				declarationReferenceExpression.typeName.hasSuffix(enumType)
				{
					return enumType
				}
			}

			return rightExpression.swiftType
		case let .binaryOperatorExpression(
			leftExpression: _, rightExpression: _, operatorSymbol: _, typeName: typeName):

			return typeName
		case let .prefixUnaryExpression(expression: _, operatorSymbol: _, typeName: typeName):
			return typeName
		case let .postfixUnaryExpression(expression: _, operatorSymbol: _, typeName: typeName):
			return typeName
		case let .ifExpression(condition: _, trueExpression: trueExpression, falseExpression: _):
			return trueExpression.swiftType
		case let .callExpression(data: callExpression):
			return callExpression.typeName
		case let .closureExpression(parameters: _, statements: _, typeName: typeName):
			return typeName
		case .literalIntExpression:
			return "Int"
		case .literalUIntExpression:
			return "UInt"
		case .literalDoubleExpression:
			return "Double"
		case .literalFloatExpression:
			return "Float"
		case .literalBoolExpression:
			return "Bool"
		case .literalStringExpression:
			return "String"
		case .literalCharacterExpression:
			return "Character"
		case .nilLiteralExpression:
			return nil
		case .interpolatedStringLiteralExpression:
			return "String"
		case .tupleExpression:
			return nil
		case .tupleShuffleExpression:
			return nil
		case .error:
			return "<<Error>>"
		}
	}

	var range: SourceFileRange? {
		switch self {
		case let .declarationReferenceExpression(data: declarationReferenceExpression):
			return declarationReferenceExpression.range
		case let .callExpression(data: callExpression):
			return callExpression.range
		default:
			return nil
		}
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

	public static func == ( // kotlin: ignore
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

	public static func == ( // kotlin: ignore
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
	var function: Expression
	var parameters: Expression
	var typeName: String
	var range: SourceFileRange?

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

	public static func == ( // kotlin: ignore
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

	public static func == ( // kotlin: ignore
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

	public static func == ( // kotlin: ignore
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

	public static func == (lhs: SwitchCase, rhs: SwitchCase) -> Bool { // kotlin: ignore
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

	public static func == (lhs: EnumElement, rhs: EnumElement) -> Bool { // kotlin: ignore
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
}
