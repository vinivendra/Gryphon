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

import Foundation

// TODO: Try to change this into an enum in the future, i.e. if immutable values really are like
// references
public class GRYSourceFile: GRYPrintableAsTree, Codable, Equatable, CustomStringConvertible {
	let declarations: [GRYTopLevelNode]
	let statements: [GRYTopLevelNode]

	init(declarations: [GRYTopLevelNode], statements: [GRYTopLevelNode]) {
		self.declarations = declarations
		self.statements = statements
	}

	//
	public func writeAsJSON(toFile filePath: String) {
		print("Building AST JSON...")
		let jsonData = try! JSONEncoder().encode(self)
		let rawJsonString = String(data: jsonData, encoding: .utf8)!

		// Absolute file paths must be replaced with placeholders before writing to file.
		let swiftFilePath = GRYUtils.changeExtension(of: filePath, to: .swift)
		let escapedFilePath = swiftFilePath.replacingOccurrences(of: "/", with: "\\/")
		let processedJsonString =
			rawJsonString.replacingOccurrences(of: escapedFilePath, with: "<<testFilePath>>")

		try! processedJsonString.write(toFile: filePath, atomically: true, encoding: .utf8)
	}

	enum SourceFileCodingKeys: String, CodingKey {
		case declarations
		case statements
	}

	required public init(from decoder: Decoder) throws {
		let container = try! decoder.container(keyedBy: SourceFileCodingKeys.self)
		self.declarations = try! container.decode([GRYTopLevelNode].self, forKey: .declarations)
		self.statements = try! container.decode([GRYTopLevelNode].self, forKey: .statements)
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: SourceFileCodingKeys.self)
		try! container.encode(declarations, forKey: .declarations)
		try! container.encode(statements, forKey: .statements)
	}

	//
	public static func == (lhs: GRYSourceFile, rhs: GRYSourceFile) -> Bool {
		return lhs.declarations == rhs.declarations &&
			lhs.statements == rhs.statements
	}

	//
	public var treeDescription: String { return "Source File" }

	public var printableSubtrees: [GRYPrintableAsTree?] {
		return [GRYPrintableTree(description: "Declarations", subtrees: declarations),
				GRYPrintableTree(description: "Statements", subtrees: statements), ]
	}

	//
	public var description: String {
		var result = ""
		prettyPrint { result += $0 }
		return result
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////

// TODO: Separate into declarations and statements?
indirect enum GRYTopLevelNode: Equatable, Codable, GRYPrintableAsTree {

	case expression(expression: GRYExpression)
	case importDeclaration(name: String)
	case classDeclaration(name: String, inherits: [String], members: [GRYTopLevelNode])
	case constructorDeclaration(implicit: Bool)
	case destructorDeclaration(implicit: Bool)
	case enumDeclaration(access: String?, name: String, inherits: [String], elements: [String])
	case protocolDeclaration(name: String)
	case structDeclaration(name: String)
	case functionDeclaration(prefix: String, parameterNames: [String], parameterTypes: [String], returnType: String, isImplicit: Bool, statements: [GRYTopLevelNode], access: String?)
	case variableDeclaration(identifier: String, typeName: String, expression: GRYExpression?, getter: GRYTopLevelNode?, setter: GRYTopLevelNode?, isLet: Bool, extendsType: String?)
	case forEachStatement(collection: GRYExpression, variable: GRYExpression, statements: [GRYTopLevelNode])
	case ifStatement(conditions: [GRYExpression], declarations: [GRYTopLevelNode], statements: [GRYTopLevelNode], elseStatement: GRYTopLevelNode?, isGuard: Bool)
	case throwStatement(expression: GRYExpression)
	case returnStatement(expression: GRYExpression?)
	case assignmentStatement(leftHand: GRYExpression, rightHand: GRYExpression)

	//
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: StringCodingKey.self)

		try! container.encode(enumName, forKey: "astName")

		switch self {
		case let .expression(expression: expression):
			try! container.encode(expression, forKey: "expression")
		case let .importDeclaration(name: name):
			try! container.encode(name, forKey: "name")
		case let .classDeclaration(name: name, inherits: inherits, members: members):
			try! container.encode(name, forKey: "name")
			try! container.encode(inherits, forKey: "inherits")
			try! container.encode(members, forKey: "members")
		case let .constructorDeclaration(implicit: implicit):
			try! container.encode(implicit, forKey: "implicit")
		case let .destructorDeclaration(implicit: implicit):
			try! container.encode(implicit, forKey: "implicit")
		case let .enumDeclaration(access: access, name: name, inherits: inherits, elements: elements):
			try! container.encode(access, forKey: "access")
			try! container.encode(name, forKey: "name")
			try! container.encode(inherits, forKey: "inherits")
			try! container.encode(elements, forKey: "elements")
		case let .protocolDeclaration(name: name):
			try! container.encode(name, forKey: "name")
		case let .structDeclaration(name: name):
			try! container.encode(name, forKey: "name")
		case let .functionDeclaration(prefix: prefix, parameterNames: parameterNames, parameterTypes: parameterTypes, returnType: returnType, isImplicit: isImplicit, statements: statements, access: access):
			try! container.encode(prefix, forKey: "prefix")
			try! container.encode(parameterNames, forKey: "parameterNames")
			try! container.encode(parameterTypes, forKey: "parameterTypes")
			try! container.encode(returnType, forKey: "returnType")
			try! container.encode(isImplicit, forKey: "isImplicit")
			try! container.encode(statements, forKey: "statements")
			try! container.encode(access, forKey: "access")
		case let .variableDeclaration(identifier: identifier, typeName: typeName, expression: expression, getter: getter, setter: setter, isLet: isLet, extendsType: extendsType):
			try! container.encode(identifier, forKey: "identifier")
			try! container.encode(typeName, forKey: "typeName")
			try! container.encode(expression, forKey: "expression")
			try! container.encode(getter, forKey: "getter")
			try! container.encode(setter, forKey: "setter")
			try! container.encode(isLet, forKey: "isLet")
			try! container.encode(extendsType, forKey: "extendsType")
		case let .forEachStatement(collection: collection, variable: variable, statements: statements):
			try! container.encode(collection, forKey: "collection")
			try! container.encode(variable, forKey: "variable")
			try! container.encode(statements, forKey: "statements")
		case let .ifStatement(conditions: conditions, declarations: declarations, statements: statements, elseStatement: elseStatement, isGuard: isGuard):
			try! container.encode(conditions, forKey: "conditions")
			try! container.encode(declarations, forKey: "declarations")
			try! container.encode(statements, forKey: "statements")
			try! container.encode(elseStatement, forKey: "elseStatement")
			try! container.encode(isGuard, forKey: "isGuard")
		case let .throwStatement(expression: expression):
			try! container.encode(expression, forKey: "expression")
		case let .returnStatement(expression: expression):
			try! container.encode(expression, forKey: "expression")
		case let .assignmentStatement(leftHand: leftHand, rightHand: rightHand):
			try! container.encode(leftHand, forKey: "leftHand")
			try! container.encode(rightHand, forKey: "rightHand")
		}
	}

	// TODO: Can this be done with gyb?
	public init(from decoder: Decoder) throws {
		let container = try! decoder.container(keyedBy: StringCodingKey.self)

		let astName = try! container.decode(String.self, forKey: "astName")

		switch astName {
		case "expression":
			let expression = try! container.decode(GRYExpression.self, forKey: "expression")
			self = .expression(expression: expression)
		case "importDeclaration":
			let name = try! container.decode(String.self, forKey: "name")
			self = .importDeclaration(name: name)
		case "classDeclaration":
			let name = try! container.decode(String.self, forKey: "name")
			let inherits = try! container.decode([String].self, forKey: "inherits")
			let members = try! container.decode([GRYTopLevelNode].self, forKey: "members")
			self = .classDeclaration(name: name, inherits: inherits, members: members)
		case "constructorDeclaration":
			let implicit = try! container.decode(Bool.self, forKey: "implicit")
			self = .constructorDeclaration(implicit: implicit)
		case "destructorDeclaration":
			let implicit = try! container.decode(Bool.self, forKey: "implicit")
			self = .destructorDeclaration(implicit: implicit)
		case "enumDeclaration":
			let access = try! container.decode(String?.self, forKey: "access")
			let name = try! container.decode(String.self, forKey: "name")
			let inherits = try! container.decode([String].self, forKey: "inherits")
			let elements = try! container.decode([String].self, forKey: "elements")
			self = .enumDeclaration(access: access, name: name, inherits: inherits, elements: elements)
		case "protocolDeclaration":
			let name = try! container.decode(String.self, forKey: "name")
			self = .protocolDeclaration(name: name)
		case "structDeclaration":
			let name = try! container.decode(String.self, forKey: "name")
			self = .structDeclaration(name: name)
		case "functionDeclaration":
			let prefix = try! container.decode(String.self, forKey: "prefix")
			let parameterNames = try! container.decode([String].self, forKey: "parameterNames")
			let parameterTypes = try! container.decode([String].self, forKey: "parameterTypes")
			let returnType = try! container.decode(String.self, forKey: "returnType")
			let isImplicit = try! container.decode(Bool.self, forKey: "isImplicit")
			let statements = try! container.decode([GRYTopLevelNode].self, forKey: "statements")
			let access = try! container.decode(String?.self, forKey: "access")
			self = .functionDeclaration(prefix: prefix, parameterNames: parameterNames, parameterTypes: parameterTypes, returnType: returnType, isImplicit: isImplicit, statements: statements, access: access)
		case "variableDeclaration":
			let identifier = try! container.decode(String.self, forKey: "identifier")
			let typeName = try! container.decode(String.self, forKey: "typeName")
			let expression = try! container.decode(GRYExpression?.self, forKey: "expression")
			let getter = try! container.decode(GRYTopLevelNode?.self, forKey: "getter")
			let setter = try! container.decode(GRYTopLevelNode?.self, forKey: "setter")
			let isLet = try! container.decode(Bool.self, forKey: "isLet")
			let extendsType = try! container.decode(String?.self, forKey: "extendsType")
			self = .variableDeclaration(identifier: identifier, typeName: typeName, expression: expression, getter: getter, setter: setter, isLet: isLet, extendsType: extendsType)
		case "forEachStatement":
			let collection = try! container.decode(GRYExpression.self, forKey: "collection")
			let variable = try! container.decode(GRYExpression.self, forKey: "variable")
			let statements = try! container.decode([GRYTopLevelNode].self, forKey: "statements")
			self = .forEachStatement(collection: collection, variable: variable, statements: statements)
		case "ifStatement":
			let conditions = try! container.decode([GRYExpression].self, forKey: "conditions")
			let declarations = try! container.decode([GRYTopLevelNode].self, forKey: "declarations")
			let statements = try! container.decode([GRYTopLevelNode].self, forKey: "statements")
			let elseStatement = try! container.decode(GRYTopLevelNode?.self, forKey: "elseStatement")
			let isGuard = try! container.decode(Bool.self, forKey: "isGuard")
			self = .ifStatement(conditions: conditions, declarations: declarations, statements: statements, elseStatement: elseStatement, isGuard: isGuard)
		case "throwStatement":
			let expression = try! container.decode(GRYExpression.self, forKey: "expression")
			self = .throwStatement(expression: expression)
		case "returnStatement":
			let expression = try! container.decode(GRYExpression?.self, forKey: "expression")
			self = .returnStatement(expression: expression)
		case "assignmentStatement":
			let leftHand = try! container.decode(GRYExpression.self, forKey: "leftHand")
			let rightHand = try! container.decode(GRYExpression.self, forKey: "rightHand")
			self = .assignmentStatement(leftHand: leftHand, rightHand: rightHand)
		default:
			throw AstDecodingError(message: "Unknown ast node \(astName).")
		}
	}

	private var enumName: String {
		if let name = Mirror(reflecting: self).children.first?.label {
			return name
		}
		else {
			return String(describing: self)
		}
	}

	//
	public var treeDescription: String {
		return enumName.capitalizedAsCamelCase
	}

	public var printableSubtrees: [GRYPrintableAsTree?] {
		switch self {
		case let .expression(expression: expression):
			return [expression]
		case let .importDeclaration(name: name):
			return [name]
		case let .classDeclaration(name: name, inherits: inherits, members: members):
			return [
				name,
				GRYPrintableTree(description: "inherits", subtreesOrNil: inherits),
				GRYPrintableTree(description: "members", subtreesOrNil: members), ]
		case let .constructorDeclaration(implicit: implicit):
			return implicit ? ["implicit"] : []
		case let .destructorDeclaration(implicit: implicit):
			return implicit ? ["implicit"] : []
		case let .enumDeclaration(
			access: access,
			name: name,
			inherits: inherits,
			elements: elements):

			return [
				access, name,
				GRYPrintableTree(description: "inherits", subtreesOrNil: inherits),
				GRYPrintableTree(description: "elements", subtreesOrNil: elements), ]
		case let .protocolDeclaration(name: name):
			return [name]
		case let .structDeclaration(name: name):
			return [name]
		case let .functionDeclaration(
			prefix: prefix,
			parameterNames: parameterNames,
			parameterTypes: parameterTypes,
			returnType: returnType,
			isImplicit: isImplicit,
			statements: statements,
			access: access):

			let name = prefix + "(" + parameterNames.map { $0 + ":" }.joined(separator: ", ") + ")"
			let type = "(" + parameterTypes.joined(separator: ", ") + ") -> " + returnType
			return [
				isImplicit ? "implicit" : nil,
				access,
				name,
				type,
				GRYPrintableTree(description: "statements", subtreesOrNil: statements), ]
		case let .variableDeclaration(
			identifier: identifier,
			typeName: typeName,
			expression: expression,
			getter: getter,
			setter: setter,
			isLet: isLet,
			extendsType: extendsType):

			return [
				GRYPrintableTree(description: "extendsType", subtreesOrNil: [extendsType]),
				isLet ? "let" : "var",
				identifier,
				typeName,
				expression,
				GRYPrintableTree(description: "getter", subtreesOrNil: [getter]),
				GRYPrintableTree(description: "setter", subtreesOrNil: [setter]), ]
		case let .forEachStatement(
			collection: collection,
			variable: variable,
			statements: statements):
			return [
				GRYPrintableTree(description: "variable", subtrees: [variable]),
				GRYPrintableTree(description: "collection", subtrees: [collection]),
				GRYPrintableTree(description: "statements", subtreesOrNil: [statements]), ]
		case let .ifStatement(
			conditions: conditions,
			declarations: declarations,
			statements: statements,
			elseStatement: elseStatement,
			isGuard: isGuard):

			return [
				isGuard ? "guard" : nil,
				GRYPrintableTree(description: "declarations", subtreesOrNil: [declarations]),
				GRYPrintableTree(description: "conditions", subtreesOrNil: [conditions]),
				GRYPrintableTree(description: "statements", subtreesOrNil: [statements]),
				GRYPrintableTree(description: "else", subtreesOrNil: [elseStatement]), ]
		case let .throwStatement(expression: expression):
			return [expression]
		case let .returnStatement(expression: expression):
			return [expression]
		case let .assignmentStatement(leftHand: leftHand, rightHand: rightHand):
			return [leftHand, rightHand]
		}
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////

indirect enum GRYExpression: Equatable, Codable, GRYPrintableAsTree {
	case forceValueExpression(expression: GRYExpression)
	case declarationReferenceExpression(identifier: String)
	case typeExpression(type: String)
	case subscriptExpression(subscriptedExpression: GRYExpression, indexExpression: GRYExpression)
	case arrayExpression(elements: [GRYExpression])
	case dotExpression(leftExpression: GRYExpression, rightExpression: GRYExpression)
	case binaryOperatorExpression(leftExpression: GRYExpression, rightExpression: GRYExpression, operatorSymbol: String)
	case unaryOperatorExpression(expression: GRYExpression, operatorSymbol: String)
	case callExpression(function: GRYExpression, parameters: GRYExpression)
	case literalIntExpression(value: Int)
	case literalDoubleExpression(value: Double)
	case literalBoolExpression(value: Bool)
	case literalStringExpression(value: String)
	case nilLiteralExpression
	case interpolatedStringLiteralExpression(expressions: [GRYExpression])
	case tupleExpression(pairs: [TuplePair])

	//
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: StringCodingKey.self)

		try! container.encode(enumName, forKey: "astName")

		switch self {
		case let .forceValueExpression(expression: expression):
			try! container.encode(expression, forKey: "expression")
		case let .declarationReferenceExpression(identifier: identifier):
			try! container.encode(identifier, forKey: "identifier")
		case let .typeExpression(type: type):
			try! container.encode(type, forKey: "type")
		case let .subscriptExpression(subscriptedExpression: subscriptedExpression, indexExpression: indexExpression):
			try! container.encode(subscriptedExpression, forKey: "subscriptedExpression")
			try! container.encode(indexExpression, forKey: "indexExpression")
		case let .arrayExpression(elements: elements):
			try! container.encode(elements, forKey: "elements")
		case let .dotExpression(leftExpression: leftExpression, rightExpression: rightExpression):
			try! container.encode(leftExpression, forKey: "leftExpression")
			try! container.encode(rightExpression, forKey: "rightExpression")
		case let .binaryOperatorExpression(leftExpression: leftExpression, rightExpression: rightExpression, operatorSymbol: operatorSymbol):
			try! container.encode(leftExpression, forKey: "leftExpression")
			try! container.encode(rightExpression, forKey: "rightExpression")
			try! container.encode(operatorSymbol, forKey: "operatorSymbol")
		case let .unaryOperatorExpression(expression: expression, operatorSymbol: operatorSymbol):
			try! container.encode(expression, forKey: "expression")
			try! container.encode(operatorSymbol, forKey: "operatorSymbol")
		case let .callExpression(function: function, parameters: parameters):
			try! container.encode(function, forKey: "function")
			try! container.encode(parameters, forKey: "parameters")
		case let .literalIntExpression(value: value):
			try! container.encode(value, forKey: "value")
		case let .literalDoubleExpression(value: value):
			try! container.encode(value, forKey: "value")
		case let .literalBoolExpression(value: value):
			try! container.encode(value, forKey: "value")
		case let .literalStringExpression(value: value):
			try! container.encode(value, forKey: "value")
		case .nilLiteralExpression:
			break
		case let .interpolatedStringLiteralExpression(expressions: expressions):
			try! container.encode(expressions, forKey: "expressions")
		case let .tupleExpression(pairs: pairs):
			try! container.encode(pairs, forKey: "pairs")
		}
	}

	public init(from decoder: Decoder) throws {
		let container = try! decoder.container(keyedBy: StringCodingKey.self)

		let astName = try! container.decode(String.self, forKey: "astName")

		switch astName {
		case "forceValueExpression":
			let expression = try! container.decode(GRYExpression.self, forKey: "expression")
			self = .forceValueExpression(expression: expression)
		case "declarationReferenceExpression":
			let identifier = try! container.decode(String.self, forKey: "identifier")
			self = .declarationReferenceExpression(identifier: identifier)
		case "typeExpression":
			let type = try! container.decode(String.self, forKey: "type")
			self = .typeExpression(type: type)
		case "subscriptExpression":
			let subscriptedExpression = try! container.decode(GRYExpression.self, forKey: "subscriptedExpression")
			let indexExpression = try! container.decode(GRYExpression.self, forKey: "indexExpression")
			self = .subscriptExpression(subscriptedExpression: subscriptedExpression, indexExpression: indexExpression)
		case "arrayExpression":
			let elements = try! container.decode([GRYExpression].self, forKey: "elements")
			self = .arrayExpression(elements: elements)
		case "dotExpression":
			let leftExpression = try! container.decode(GRYExpression.self, forKey: "leftExpression")
			let rightExpression = try! container.decode(GRYExpression.self, forKey: "rightExpression")
			self = .dotExpression(leftExpression: leftExpression, rightExpression: rightExpression)
		case "binaryOperatorExpression":
			let leftExpression = try! container.decode(GRYExpression.self, forKey: "leftExpression")
			let rightExpression = try! container.decode(GRYExpression.self, forKey: "rightExpression")
			let operatorSymbol = try! container.decode(String.self, forKey: "operatorSymbol")
			self = .binaryOperatorExpression(leftExpression: leftExpression, rightExpression: rightExpression, operatorSymbol: operatorSymbol)
		case "unaryOperatorExpression":
			let expression = try! container.decode(GRYExpression.self, forKey: "expression")
			let operatorSymbol = try! container.decode(String.self, forKey: "operatorSymbol")
			self = .unaryOperatorExpression(expression: expression, operatorSymbol: operatorSymbol)
		case "callExpression":
			let function = try! container.decode(GRYExpression.self, forKey: "function")
			let parameters = try! container.decode(GRYExpression.self, forKey: "parameters")
			self = .callExpression(function: function, parameters: parameters)
		case "literalIntExpression":
			let value = try! container.decode(Int.self, forKey: "value")
			self = .literalIntExpression(value: value)
		case "literalDoubleExpression":
			let value = try! container.decode(Double.self, forKey: "value")
			self = .literalDoubleExpression(value: value)
		case "literalBoolExpression":
			let value = try! container.decode(Bool.self, forKey: "value")
			self = .literalBoolExpression(value: value)
		case "literalStringExpression":
			let value = try! container.decode(String.self, forKey: "value")
			self = .literalStringExpression(value: value)
		case "nilLiteralExpression":
			self = .nilLiteralExpression
		case "interpolatedStringLiteralExpression":
			let expressions = try! container.decode([GRYExpression].self, forKey: "expressions")
			self = .interpolatedStringLiteralExpression(expressions: expressions)
		case "tupleExpression":
			let pairs = try! container.decode([TuplePair].self, forKey: "pairs")
			self = .tupleExpression(pairs: pairs)
		default:
			throw AstDecodingError(message: "Unknown ast node \(astName).")
		}
	}

	private var enumName: String {
		if let name = Mirror(reflecting: self).children.first?.label {
			return name
		}
		else {
			return String(describing: self)
		}
	}

	//
	public var treeDescription: String {
		return enumName
	}

	public var printableSubtrees: [GRYPrintableAsTree?] {
		switch self {
		case let .forceValueExpression(expression: expression):
			return [expression]
		case let .declarationReferenceExpression(identifier: identifier):
			return [identifier]
		case let .typeExpression(type: type):
			return [type]
		case let .subscriptExpression(
			subscriptedExpression: subscriptedExpression,
			indexExpression: indexExpression):

			return [
				GRYPrintableTree(
					description: "subscriptedExpression", subtrees: [subscriptedExpression]),
				GRYPrintableTree(description: "indexExpression", subtrees: [indexExpression]), ]
		case let .arrayExpression(elements: elements):
			return [elements]
		case let .dotExpression(leftExpression: leftExpression, rightExpression: rightExpression):
			return [
				GRYPrintableTree(description: "left", subtrees: [leftExpression]),
				GRYPrintableTree(description: "right", subtrees: [rightExpression]), ]

		case let .binaryOperatorExpression(
			leftExpression: leftExpression,
			rightExpression: rightExpression,
			operatorSymbol: operatorSymbol):

			return [
				GRYPrintableTree(description: "left", subtrees: [leftExpression]),
				GRYPrintableTree(description: "operator \(operatorSymbol)"),
				GRYPrintableTree(description: "right", subtrees: [rightExpression]), ]
		case let .unaryOperatorExpression(expression: expression, operatorSymbol: operatorSymbol):
			return [
				GRYPrintableTree(description: "operator \(operatorSymbol)"),
				GRYPrintableTree(description: "expression", subtrees: [expression]), ]
		case let .callExpression(function: function, parameters: parameters):
			return [
				GRYPrintableTree(description: "function", subtrees: [function]),
				GRYPrintableTree(description: "parameters", subtrees: [parameters]), ]
		case let .literalIntExpression(value: value):
			return [String(value)]
		case let .literalDoubleExpression(value: value):
			return [String(value)]
		case let .literalBoolExpression(value: value):
			return [String(value)]
		case let .literalStringExpression(value: value):
			return ["\"\(value)\""]
		case .nilLiteralExpression:
			return []
		case let .interpolatedStringLiteralExpression(expressions: expressions):
			return [expressions]
		case let .tupleExpression(pairs: pairs):
			return pairs.map {
				GRYPrintableTree(description: ($0.name ?? "_") + ":", subtrees: [$0.expression])
			}
		}
	}

	//
	struct TuplePair: Equatable, Codable {
		let name: String?
		let expression: GRYExpression
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////

private struct AstDecodingError: Error {
	let message: String
}

private struct StringCodingKey: CodingKey, ExpressibleByStringLiteral {
	public var stringValue: String

	public init(stringLiteral value: String) {
		self.stringValue = value
	}

	public init(stringValue: String) {
		self.stringValue = stringValue
	}
	public var intValue: Int?
	public init?(intValue: Int) { return nil }
}
