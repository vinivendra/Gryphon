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
	let declarations: [Statement]
	let statements: [Statement]

	init(sourceFile: SourceFile?, declarations: [Statement], statements: [Statement]) {
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
	public var treeDescription: String { return "Source File" }

	public var printableSubtrees: ArrayReference<PrintableAsTree?> {
		return [PrintableTree("Declarations", declarations),
				PrintableTree("Statements", statements), ]
	}

	//
	public var description: String {
		var result = ""
		prettyPrint { result += $0 }
		return result
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////

public indirect enum Statement: Equatable, PrintableAsTree {

	case expression(
		expression: Expression)
	case typealiasDeclaration(
		identifier: String,
		type: String,
		isImplicit: Bool)
	case extensionDeclaration(
		type: String,
		members: [Statement])
	case importDeclaration(
		name: String)
	case classDeclaration(
		name: String,
		inherits: [String],
		members: [Statement])
	case companionObject(
		members: [Statement])
	case enumDeclaration(
		access: String?,
		name: String,
		inherits: [String],
		elements: [EnumElement],
		members: [Statement],
		isImplicit: Bool)
	case protocolDeclaration(
		name: String,
		members: [Statement])
	case structDeclaration(
		annotations: String?,
		name: String,
		inherits: [String],
		members: [Statement])
	case functionDeclaration(
		value: FunctionDeclaration)
	case variableDeclaration(
		value: VariableDeclaration)
	case forEachStatement(
		collection: Expression,
		variable: Expression,
		statements: [Statement])
	case whileStatement(
		expression: Expression,
		statements: [Statement])
	case ifStatement(
		value: IfStatement)
	case switchStatement(
		convertsToExpression: Statement?,
		expression: Expression,
		cases: [SwitchCase])
	case deferStatement(
		statements: [Statement])
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
}

////////////////////////////////////////////////////////////////////////////////////////////////////
// TODO: dictionaryExpression should have key-value pairs

public indirect enum Expression: Equatable, PrintableAsTree {
	case literalCodeExpression(
		string: String)
	case literalDeclarationExpression(
		string: String)
	case templateExpression(
		pattern: String,
		matches: [String: Expression])
	case parenthesesExpression(
		expression: Expression)
	case forceValueExpression(
		expression: Expression)
	case optionalExpression(
		expression: Expression)
	case declarationReferenceExpression(
		value: DeclarationReferenceExpression)
	case typeExpression(
		type: String)
	case subscriptExpression(
		subscriptedExpression: Expression,
		indexExpression: Expression,
		type: String)
	case arrayExpression(
		elements: [Expression],
		type: String)
	case dictionaryExpression(
		keys: [Expression],
		values: [Expression],
		type: String)
	case returnExpression(
		expression: Expression?)
	case dotExpression(
		leftExpression: Expression,
		rightExpression: Expression)
	case binaryOperatorExpression(
		leftExpression: Expression,
		rightExpression: Expression,
		operatorSymbol: String,
		type: String)
	case prefixUnaryExpression(
		expression: Expression,
		operatorSymbol: String,
		type: String)
	case postfixUnaryExpression(
		expression: Expression,
		operatorSymbol: String,
		type: String)
	case callExpression(
		function: Expression,
		parameters: Expression,
		type: String)
	case closureExpression(
		parameters: [LabeledType],
		statements: [Statement],
		type: String)
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
		expressions: [Expression])
	case tupleExpression(
		pairs: [LabeledExpression])
	case tupleShuffleExpression(
		labels: [String],
		indices: [TupleShuffleIndex],
		expressions: [Expression])
	case error
}

public struct LabeledExpression: Equatable {
	var label: String?
	var expression: Expression
}

public struct LabeledType: Equatable {
	var label: String
	var type: String
}

public struct FunctionParameter: Equatable, PrintableAsTree {
	var label: String
	var apiLabel: String?
	var type: String
	var value: Expression?

	public var treeDescription: String {
		return "parameter"
	}

	public var printableSubtrees: ArrayReference<PrintableAsTree?> {
		return [
			self.apiLabel.map { PrintableTree("api label: \($0)") },
			PrintableTree("label: \(self.label)"),
			PrintableTree("type: \(self.type)"),
			PrintableTree.initOrNil("value", [self.value]),
		]
	}
}

public struct VariableDeclaration: Equatable {
	var identifier: String
	var typeName: String
	var expression: Expression?
	var getter: Statement?
	var setter: Statement?
	var isLet: Bool
	var isImplicit: Bool
	var isStatic: Bool
	var extendsType: String?
	var annotations: String?
}

public struct DeclarationReferenceExpression: Equatable {
	var identifier: String
	var type: String
	var isStandardLibrary: Bool
	var isImplicit: Bool
	var range: SourceFileRange?
}

public struct FunctionDeclaration: Equatable {
	var prefix: String
	var parameters: [FunctionParameter]
	var returnType: String
	var functionType: String
	var genericTypes: [String]
	var isImplicit: Bool
	var isStatic: Bool
	var isMutating: Bool
	var extendsType: String?
	var statements: [Statement]?
	var access: String?
	var annotations: String?
}

public class IfStatement: Equatable {
	var conditions: [Expression]
	var declarations: [VariableDeclaration]
	var statements: [Statement]
	var elseStatement: IfStatement?
	var isGuard: Bool

	public init(
		conditions: [Expression],
		declarations: [VariableDeclaration],
		statements: [Statement],
		elseStatement: IfStatement?,
		isGuard: Bool)
	{
		self.conditions = conditions
		self.declarations = declarations
		self.statements = statements
		self.elseStatement = elseStatement
		self.isGuard = isGuard
	}

	public static func == (lhs: IfStatement, rhs: IfStatement) -> Bool {
		return lhs.conditions == rhs.conditions &&
			lhs.declarations == rhs.declarations &&
			lhs.statements == rhs.statements &&
			lhs.elseStatement == rhs.elseStatement &&
			lhs.isGuard == rhs.isGuard
	}

	public func copy() -> IfStatement {
		return IfStatement(
			conditions: conditions,
			declarations: declarations,
			statements: statements,
			elseStatement: elseStatement,
			isGuard: isGuard)
	}
}

public struct SwitchCase: Equatable {
	var expression: Expression?
	var statements: [Statement]
}

public struct EnumElement: Equatable {
	var name: String
	var associatedValues: [LabeledType]
	var annotations: String?
}

////////////////////////////////////////////////////////////////////////////////////////////////////

extension Statement {
	public var name: String {
		if let name = Mirror(reflecting: self).children.first?.label {
			return name
		}
		else {
			return String(describing: self)
		}
	}

	//
	public var treeDescription: String {
		return name.capitalizedAsCamelCase
	}

	public var printableSubtrees: ArrayReference<PrintableAsTree?> {
		switch self {
		case let .expression(expression: expression):
			return [expression]
		case let .extensionDeclaration(type: type, members: members):
			return [PrintableTree(type), PrintableTree.initOrNil("members", members), ]
		case let .importDeclaration(name: name):
			return [PrintableTree(name)]
		case let .typealiasDeclaration(identifier: identifier, type: type, isImplicit: isImplicit):
			return [
				isImplicit ? PrintableTree("implicit") : nil,
				PrintableTree("identifier: \(identifier)"),
				PrintableTree("type: \(type)"), ]
		case let .classDeclaration(name: name, inherits: inherits, members: members):
			return  [
				PrintableTree(name),
				PrintableTree("inherits", inherits),
				PrintableTree("members", members), ]
		case let .companionObject(members: members):
			return ArrayReference<PrintableAsTree?>(array: members)
		case let .enumDeclaration(
			access: access,
			name: name,
			inherits: inherits,
			elements: elements,
			members: members,
			isImplicit: isImplicit):

			let elementTrees = elements.map { (element: EnumElement) -> PrintableTree in
				let associatedValues = element.associatedValues
					.map { "\($0.label): \($0.type)" }
					.joined(separator: ", ")
				let associatedValuesString = (associatedValues.isEmpty) ? nil :
					"values: \(associatedValues)"
				return PrintableTree(".\(element.name)", [
					PrintableTree.initOrNil(associatedValuesString),
					PrintableTree.initOrNil(element.annotations), ])
			}

			return [
				isImplicit ? PrintableTree("implicit") : nil,
				PrintableTree.initOrNil(access),
				PrintableTree(name),
				PrintableTree("inherits", inherits),
				PrintableTree("elements", elementTrees),
				PrintableTree("members", members), ]
		case let .protocolDeclaration(name: name, members: members):
			return [
				PrintableTree(name),
				PrintableTree.initOrNil("members", members), ]
		case let .structDeclaration(
			annotations: annotations, name: name, inherits: inherits, members: members):

			return [
				PrintableTree.initOrNil(
					"annotations", [PrintableTree.initOrNil(annotations)]),
				PrintableTree(name),
				PrintableTree("inherits", inherits),
				PrintableTree("members", members), ]
		case let .functionDeclaration(value: functionDeclaration):
			return [
				functionDeclaration.extendsType.map { PrintableTree("extends type \($0)") },
				functionDeclaration.isImplicit ? PrintableTree("implicit") : nil,
				functionDeclaration.isStatic ? PrintableTree("static") : nil,
				functionDeclaration.isMutating ? PrintableTree("mutating") : nil,
				PrintableTree.initOrNil(functionDeclaration.access),
				PrintableTree("type: \(functionDeclaration.functionType)"),
				PrintableTree("prefix: \(functionDeclaration.prefix)"),
				PrintableTree("parameters", functionDeclaration.parameters),
				PrintableTree("return type: \(functionDeclaration.returnType)"),
				PrintableTree("statements", functionDeclaration.statements ?? []), ]
		case let .variableDeclaration(value: variableDeclaration):
			return [
				PrintableTree.initOrNil(
					"extendsType", [PrintableTree.initOrNil(variableDeclaration.extendsType)]),
				variableDeclaration.isImplicit ? PrintableTree("implicit") : nil,
				variableDeclaration.isStatic ? PrintableTree("static") : nil,
				variableDeclaration.isLet ? PrintableTree("let") : PrintableTree("var"),
				PrintableTree(variableDeclaration.identifier),
				PrintableTree(variableDeclaration.typeName),
				variableDeclaration.expression,
				PrintableTree.initOrNil("getter", [variableDeclaration.getter]),
				PrintableTree.initOrNil("setter", [variableDeclaration.setter]),
				PrintableTree.initOrNil(
					"annotations", [PrintableTree.initOrNil(variableDeclaration.annotations)]), ]
		case let .forEachStatement(
			collection: collection,
			variable: variable,
			statements: statements):
			return [
				PrintableTree("variable", [variable]),
				PrintableTree("collection", [collection]),
				PrintableTree.initOrNil("statements", statements), ]
		case let .whileStatement(expression: expression, statements: statements):
			return [
				PrintableTree("expression", [expression]),
				PrintableTree.initOrNil("statements", statements), ]
		case let .ifStatement(value: ifStatement):
			let declarationTrees =
				ifStatement.declarations.map { Statement.variableDeclaration(value: $0) }
			let elseStatementTrees = ifStatement.elseStatement
				.map({ Statement.ifStatement(value: $0) })?.printableSubtrees ?? []
			return [
				ifStatement.isGuard ? PrintableTree("guard") : nil,
				PrintableTree.initOrNil("declarations", declarationTrees),
				PrintableTree.initOrNil("conditions", ifStatement.conditions),
				PrintableTree.initOrNil("statements", ifStatement.statements),
				PrintableTree.initOrNil("else", elseStatementTrees), ]
		case let .switchStatement(
			convertsToExpression: convertsToExpression, expression: expression,
			cases: cases):

			let caseItems = cases.map {
				PrintableTree("case item", [
					PrintableTree("expression", [$0.expression]),
					PrintableTree("statements", $0.statements),
					])
			}

			return [
				PrintableTree.initOrNil("converts to expression", [convertsToExpression]),
				PrintableTree("expression", [expression]),
				PrintableTree("case items", caseItems), ]
		case let .deferStatement(statements: statements):
			return ArrayReference(array: statements)
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

extension Expression {
	public var type: String? {
		switch self {
		case .templateExpression:
			return nil
		case .literalCodeExpression, .literalDeclarationExpression:
			return nil
		case let .parenthesesExpression(expression: expression):
			return expression.type
		case let .forceValueExpression(expression: expression):
			let subtype = expression.type
			if let subtype = subtype, subtype.hasSuffix("?") {
				return String(subtype.dropLast())
			}
			else {
				return expression.type
			}
		case let .optionalExpression(expression: expression):
			return expression.type
		case let .declarationReferenceExpression(value: declarationReferenceExpression):
			return declarationReferenceExpression.type
		case .typeExpression:
			return nil
		case let .subscriptExpression(subscriptedExpression: _, indexExpression: _, type: type):
			return type
		case let .arrayExpression(elements: _, type: type):
			return type
		case let .dictionaryExpression(keys: _, values: _, type: type):
			return type
		case let .returnExpression(expression: expression):
			return expression?.type
		case let .dotExpression(leftExpression: _, rightExpression: rightExpression):
			return rightExpression.type
		case let .binaryOperatorExpression(
			leftExpression: _, rightExpression: _, operatorSymbol: _, type: type):

			return type
		case let .prefixUnaryExpression(expression: _, operatorSymbol: _, type: type):
			return type
		case let .postfixUnaryExpression(expression: _, operatorSymbol: _, type: type):
			return type
		case let .callExpression(function: _, parameters: _, type: type):
			return type
		case let .closureExpression(parameters: _, statements: _, type: type):
			return type
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
		case let .declarationReferenceExpression(value: declarationReferenceExpression):
			return declarationReferenceExpression.range
		default:
			return nil
		}
	}

	public var name: String {
		if let name = Mirror(reflecting: self).children.first?.label {
			return name
		}
		else {
			return String(describing: self)
		}
	}

	//
	public var treeDescription: String {
		return name
	}

	public var printableSubtrees: ArrayReference<PrintableAsTree?> {
		switch self {
		case let .templateExpression(pattern: pattern, matches: matches):
			return [
				PrintableTree("pattern \"\(pattern)\""),
				PrintableTree("matches", [matches]), ]
		case .literalCodeExpression(string: let string),
			.literalDeclarationExpression(string: let string):

			return [PrintableTree(string)]
		case let .parenthesesExpression(expression: expression):
			return [expression]
		case let .forceValueExpression(expression: expression):
			return [expression]
		case let .optionalExpression(expression: expression):
			return [expression]
		case let .declarationReferenceExpression(value: expression):
			return [
				PrintableTree(expression.type),
				PrintableTree(expression.identifier),
				expression.isStandardLibrary ? PrintableTree("isStandardLibrary") : nil,
				expression.isImplicit ? PrintableTree("implicit") : nil, ]
		case let .typeExpression(type: type):
			return [PrintableTree(type)]
		case let .subscriptExpression(
			subscriptedExpression: subscriptedExpression, indexExpression: indexExpression,
			type: type):

			return [
				PrintableTree("type \(type)"),
				PrintableTree("subscriptedExpression", [subscriptedExpression]),
				PrintableTree("indexExpression", [indexExpression]), ]
		case let .arrayExpression(elements: elements, type: type):
			return [PrintableTree("type \(type)"), PrintableTree(elements)]
		case let .dictionaryExpression(keys: keys, values: values, type: type):
			let keyValueStrings = zip(keys, values).map { "\($0): \($1)" }
			return [
				PrintableTree("type \(type)"),
				PrintableTree("key value pairs", keyValueStrings), ]
		case let .returnExpression(expression: expression):
			return [expression]
		case let .dotExpression(leftExpression: leftExpression, rightExpression: rightExpression):
			return [
				PrintableTree("left", [leftExpression]),
				PrintableTree("right", [rightExpression]), ]
		case let .binaryOperatorExpression(
			leftExpression: leftExpression,
			rightExpression: rightExpression,
			operatorSymbol: operatorSymbol,
			type: type):

			return [
				PrintableTree("type \(type)"),
				PrintableTree("left", [leftExpression]),
				PrintableTree("operator \(operatorSymbol)"),
				PrintableTree("right", [rightExpression]), ]
		case let .prefixUnaryExpression(
			expression: expression, operatorSymbol: operatorSymbol, type: type):

			return [
				PrintableTree("type \(type)"),
				PrintableTree("operator \(operatorSymbol)"),
				PrintableTree("expression", [expression]), ]
		case let .postfixUnaryExpression(
			expression: expression, operatorSymbol: operatorSymbol, type: type):

			return [
				PrintableTree("type \(type)"),
				PrintableTree("operator \(operatorSymbol)"),
				PrintableTree("expression", [expression]), ]
		case let .callExpression(function: function, parameters: parameters, type: type):
			return [
				PrintableTree("type \(type)"),
				PrintableTree("function", [function]),
				PrintableTree("parameters", [parameters]), ]
		case let .closureExpression(parameters: parameters, statements: statements, type: type):
			let parameters = "(" + parameters.map { $0.label + ":" }.joined(separator: ", ") + ")"
			return [
				PrintableTree(type),
				PrintableTree(parameters),
				PrintableTree("statements", statements), ]
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
			return [PrintableTree(expressions)]
		case let .tupleExpression(pairs: pairs):
			return ArrayReference<PrintableAsTree?>(array: pairs.map {
				PrintableTree(($0.label ?? "_") + ":", [$0.expression])
			})
		case let .tupleShuffleExpression(
			labels: labels, indices: indices, expressions: expressions):

			return [
				PrintableTree("labels", labels),
				PrintableTree("indices", indices.map { $0.description }),
				PrintableTree("expressions", expressions), ]
		case .error:
			return []
		}
	}
}

//
public enum TupleShuffleIndex: Equatable, CustomStringConvertible {
	case variadic(count: Int)
	case absent
	case present

	public var description: String {
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
