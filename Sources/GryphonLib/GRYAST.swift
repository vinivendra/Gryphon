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

public final class GRYAST: GRYPrintableAsTree, GRYCodable, Equatable, CustomStringConvertible {
	let declarations: [GRYTopLevelNode]
	let statements: [GRYTopLevelNode]

	init(declarations: [GRYTopLevelNode], statements: [GRYTopLevelNode]) {
		self.declarations = declarations
		self.statements = statements
	}

	//
	internal static func decode(from decoder: GRYDecoder) throws -> GRYAST {
		try decoder.readOpeningParenthesis()
		_ = decoder.readIdentifier()
		let declarations = try [GRYTopLevelNode].decode(from: decoder)
		let statements = try [GRYTopLevelNode].decode(from: decoder)
		try decoder.readClosingParenthesis()
		return GRYAST(declarations: declarations, statements: statements)
	}

	func encode(into encoder: GRYEncoder) throws {
		encoder.startNewObject(named: "GRYAST")
		try declarations.encode(into: encoder)
		try statements.encode(into: encoder)
		encoder.endObject()
	}

	//
	public static func == (lhs: GRYAST, rhs: GRYAST) -> Bool {
		return lhs.declarations == rhs.declarations &&
			lhs.statements == rhs.statements
	}

	//
	public var treeDescription: String { return "Source File" }

	public var printableSubtrees: ArrayReference<GRYPrintableAsTree?> {
		return [GRYPrintableTree("Declarations", declarations),
				GRYPrintableTree("Statements", statements), ]
	}

	//
	public var description: String {
		var result = ""
		prettyPrint { result += $0 }
		return result
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////

extension GRYTopLevelNode {
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

	public var printableSubtrees: ArrayReference<GRYPrintableAsTree?> {
		switch self {
		case let .expression(expression: expression):
			return [expression]
		case let .extensionDeclaration(type: type, members: members):
			return [GRYPrintableTree(type), GRYPrintableTree.initOrNil("members", members), ]
		case let .importDeclaration(name: name):
			return [GRYPrintableTree(name)]
		case let .typealiasDeclaration(identifier: identifier, type: type, isImplicit: isImplicit):
			return [
				isImplicit ? GRYPrintableTree("implicit") : nil,
				GRYPrintableTree("identifier: \(identifier)"),
				GRYPrintableTree("type: \(type)"), ]
		case let .classDeclaration(name: name, inherits: inherits, members: members):
			return  [
				GRYPrintableTree(name),
				GRYPrintableTree("inherits", inherits),
				GRYPrintableTree("members", members), ]
		case let .companionObject(members: members):
			return ArrayReference<GRYPrintableAsTree?>(array: members)
		case let .enumDeclaration(
			access: access,
			name: name,
			inherits: inherits,
			elements: elements,
			members: members,
			isImplicit: isImplicit):

			return [
				isImplicit ? GRYPrintableTree("implicit") : nil,
				GRYPrintableTree.initOrNil(access),
				GRYPrintableTree(name),
				GRYPrintableTree("inherits", inherits),
				GRYPrintableTree("elements", elements),
				GRYPrintableTree("members", members), ]
		case let .enumElementDeclaration(
			name: name,
			associatedValueLabels: associatedValueLabels,
			associatedValueTypes: associatedValueTypes):

			return [
				GRYPrintableTree(name),
				GRYPrintableTree("values", associatedValueLabels),
				GRYPrintableTree("types", associatedValueTypes), ]
		case let .protocolDeclaration(name: name, members: members):
			return [
				GRYPrintableTree(name),
				GRYPrintableTree.initOrNil("members", members), ]
		case let .structDeclaration(name: name, inherits: inherits, members: members):
			return [
				GRYPrintableTree(name),
				GRYPrintableTree("inherits", inherits),
				GRYPrintableTree("members", members), ]
		case let .functionDeclaration(value: functionDeclaration):

			let name = functionDeclaration.prefix + "(" +
				functionDeclaration.parameterNames.map { $0 + ":" }.joined(separator: ", ") + ")"
			let type = "(" + functionDeclaration.parameterTypes.joined(separator: ", ") + ") -> " +
				functionDeclaration.returnType

			let defaultValueStrings: [GRYPrintableAsTree]
			if functionDeclaration.defaultValues.contains(where: { $0 != nil }) {
				defaultValueStrings = functionDeclaration.defaultValues.map
					{ (expression: GRYExpression?) -> GRYPrintableAsTree in
						expression ?? GRYPrintableTree("_")
				}
			}
			else {
				defaultValueStrings = []
			}

			return [
				functionDeclaration.extendsType.map { GRYPrintableTree("Extends type \($0)") },
				functionDeclaration.isImplicit ? GRYPrintableTree("implicit") : nil,
				functionDeclaration.isStatic ? GRYPrintableTree("static") : nil,
				functionDeclaration.isMutating ? GRYPrintableTree("mutating") : nil,
				GRYPrintableTree.initOrNil(functionDeclaration.access),
				GRYPrintableTree(name),
				GRYPrintableTree("Default Values", defaultValueStrings),
				GRYPrintableTree("type: \(type)"),
				GRYPrintableTree("statements", functionDeclaration.statements ?? []), ]
		case let .variableDeclaration(value: variableDeclaration):
			return [
				GRYPrintableTree.initOrNil(
					"extendsType", [GRYPrintableTree.initOrNil(variableDeclaration.extendsType)]),
				variableDeclaration.isImplicit ? GRYPrintableTree("implicit") : nil,
				variableDeclaration.isStatic ? GRYPrintableTree("static") : nil,
				variableDeclaration.isLet ? GRYPrintableTree("let") : GRYPrintableTree("var"),
				GRYPrintableTree(variableDeclaration.identifier),
				GRYPrintableTree(variableDeclaration.typeName),
				variableDeclaration.expression,
				GRYPrintableTree.initOrNil("getter", [variableDeclaration.getter]),
				GRYPrintableTree.initOrNil("setter", [variableDeclaration.setter]),
				GRYPrintableTree.initOrNil(
					"annotations", [GRYPrintableTree.initOrNil(variableDeclaration.annotations)]), ]
		case let .forEachStatement(
			collection: collection,
			variable: variable,
			statements: statements):
			return [
				GRYPrintableTree("variable", [variable]),
				GRYPrintableTree("collection", [collection]),
				GRYPrintableTree.initOrNil("statements", statements), ]
		case let .ifStatement(
			conditions: conditions,
			declarations: declarations,
			statements: statements,
			elseStatement: elseStatement,
			isGuard: isGuard):

			return [
				isGuard ? GRYPrintableTree("guard") : nil,
				GRYPrintableTree.initOrNil("declarations", declarations),
				GRYPrintableTree.initOrNil("conditions", conditions),
				GRYPrintableTree.initOrNil("statements", statements),
				GRYPrintableTree.initOrNil("else", [elseStatement]), ]
		case let .switchStatement(
			convertsToExpression: convertsToExpression, expression: expression,
			caseExpressions: caseExpressions, caseStatements: caseStatements):

			let caseItems = zip(caseExpressions, caseStatements).map {
				GRYPrintableTree("case item", [
					GRYPrintableTree("expression", [$0]),
					GRYPrintableTree("statements", $1),
					])
			}

			return [
				GRYPrintableTree.initOrNil("converts to expression", [convertsToExpression]),
				GRYPrintableTree("expression", [expression]),
				GRYPrintableTree("case items", caseItems), ]
		case let .throwStatement(expression: expression):
			return [expression]
		case let .returnStatement(expression: expression):
			return [expression]
		case let .assignmentStatement(leftHand: leftHand, rightHand: rightHand):
			return [leftHand, rightHand]
		case .error:
			return []
		}
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////

extension GRYExpression {
	public var type: String? {
		switch self {
		case .templateExpression(pattern: _, matches: _):
			return nil
		case .literalCodeExpression(string: _):
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
		case let .declarationReferenceExpression(
			identifier: _, type: type, isStandardLibrary: _, isImplicit: _):

			return type
		case .typeExpression:
			return nil
		case let .subscriptExpression(subscriptedExpression: _, indexExpression: _, type: type):
			return type
		case let .arrayExpression(elements: _, type: type):
			return type
		case let .dictionaryExpression(keys: _, values: _, type: type):
			return type
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
		case let .closureExpression(parameterNames:
			_, parameterTypes: _, statements: _, type: type):

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
		case .nilLiteralExpression:
			return nil
		case .interpolatedStringLiteralExpression:
			return "String"
		case .tupleExpression:
			return nil
		case .error:
			return "<<Error>>"
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

	public var printableSubtrees: ArrayReference<GRYPrintableAsTree?> {
		switch self {
		case let .templateExpression(pattern: pattern, matches: matches):
			return [
				GRYPrintableTree("pattern \"\(pattern)\""),
				GRYPrintableTree("matches", [matches]), ]
		case let .literalCodeExpression(string: string):
			return [GRYPrintableTree(string)]
		case let .parenthesesExpression(expression: expression):
			return [expression]
		case let .forceValueExpression(expression: expression):
			return [expression]
		case let .optionalExpression(expression: expression):
			return [expression]
		case let .declarationReferenceExpression(
			identifier: identifier, type: type, isStandardLibrary: isStandardLibrary,
			isImplicit: isImplicit):

			return [
				GRYPrintableTree(type),
				GRYPrintableTree(identifier),
				isStandardLibrary ? GRYPrintableTree("isStandardLibrary") : nil,
				isImplicit ? GRYPrintableTree("implicit") : nil, ]
		case let .typeExpression(type: type):
			return [GRYPrintableTree(type)]
		case let .subscriptExpression(
			subscriptedExpression: subscriptedExpression, indexExpression: indexExpression,
			type: type):

			return [
				GRYPrintableTree("type \(type)"),
				GRYPrintableTree("subscriptedExpression", [subscriptedExpression]),
				GRYPrintableTree("indexExpression", [indexExpression]), ]
		case let .arrayExpression(elements: elements, type: type):
			return [GRYPrintableTree("type \(type)"), GRYPrintableTree(elements)]
		case let .dictionaryExpression(keys: keys, values: values, type: type):
			let keyValueStrings = zip(keys, values).map { "\($0): \($1)" }
			return [
				GRYPrintableTree("type \(type)"),
				GRYPrintableTree("key value pairs", keyValueStrings), ]
		case let .dotExpression(leftExpression: leftExpression, rightExpression: rightExpression):
			return [
				GRYPrintableTree("left", [leftExpression]),
				GRYPrintableTree("right", [rightExpression]), ]
		case let .binaryOperatorExpression(
			leftExpression: leftExpression,
			rightExpression: rightExpression,
			operatorSymbol: operatorSymbol,
			type: type):

			return [
				GRYPrintableTree("type \(type)"),
				GRYPrintableTree("left", [leftExpression]),
				GRYPrintableTree("operator \(operatorSymbol)"),
				GRYPrintableTree("right", [rightExpression]), ]
		case let .prefixUnaryExpression(
			expression: expression, operatorSymbol: operatorSymbol, type: type):

			return [
				GRYPrintableTree("type \(type)"),
				GRYPrintableTree("operator \(operatorSymbol)"),
				GRYPrintableTree("expression", [expression]), ]
		case let .postfixUnaryExpression(
			expression: expression, operatorSymbol: operatorSymbol, type: type):

			return [
				GRYPrintableTree("type \(type)"),
				GRYPrintableTree("operator \(operatorSymbol)"),
				GRYPrintableTree("expression", [expression]), ]
		case let .callExpression(function: function, parameters: parameters, type: type):
			return [
				GRYPrintableTree("type \(type)"),
				GRYPrintableTree("function", [function]),
				GRYPrintableTree("parameters", [parameters]), ]
		case let .closureExpression(
			parameterNames: parameterNames, parameterTypes: _, statements: statements, type: type):

			let parameters = "(" + parameterNames.map { $0 + ":" }.joined(separator: ", ") + ")"

			return [
				GRYPrintableTree(type),
				GRYPrintableTree(parameters),
				GRYPrintableTree("statements", statements), ]
		case let .literalIntExpression(value: value):
			return [GRYPrintableTree(String(value))]
		case let .literalUIntExpression(value: value):
			return [GRYPrintableTree(String(value))]
		case let .literalDoubleExpression(value: value):
			return [GRYPrintableTree(String(value))]
		case let .literalFloatExpression(value: value):
			return [GRYPrintableTree(String(value))]
		case let .literalBoolExpression(value: value):
			return [GRYPrintableTree(String(value))]
		case let .literalStringExpression(value: value):
			return [GRYPrintableTree("\"\(value)\"")]
		case .nilLiteralExpression:
			return []
		case let .interpolatedStringLiteralExpression(expressions: expressions):
			return [GRYPrintableTree(expressions)]
		case let .tupleExpression(pairs: pairs):
			return ArrayReference<GRYPrintableAsTree?>(array: pairs.map {
				GRYPrintableTree(($0.name ?? "_") + ":", [$0.expression])
			})
		case .error:
			return []
		}
	}

	//
	public struct TuplePair: Equatable {
		let name: String?
		let expression: GRYExpression

		func encode(into encoder: GRYEncoder) throws {
			try name.encode(into: encoder)
			try expression.encode(into: encoder)
		}

		static func decode(from decoder: GRYDecoder) throws -> TuplePair {
			let name = try String?.decode(from: decoder)
			let expression = try GRYExpression.decode(from: decoder)
			return TuplePair(name: name, expression: expression)
		}
	}
}
