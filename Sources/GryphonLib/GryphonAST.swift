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

public final class GryphonAST: PrintableAsTree, GRYCodable, Equatable, CustomStringConvertible {
	let declarations: [Statement]
	let statements: [Statement]

	init(declarations: [Statement], statements: [Statement]) {
		self.declarations = declarations
		self.statements = statements
	}

	//
	internal static func decode(from decoder: GRYDecoder) throws -> GryphonAST {
		try decoder.readOpeningParenthesis()
		_ = decoder.readIdentifier()
		let declarations = try [Statement].decode(from: decoder)
		let statements = try [Statement].decode(from: decoder)
		try decoder.readClosingParenthesis()
		return GryphonAST(declarations: declarations, statements: statements)
	}

	func encode(into encoder: GRYEncoder) throws {
		encoder.startNewObject(named: "GryphonAST")
		try declarations.encode(into: encoder)
		try statements.encode(into: encoder)
		encoder.endObject()
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
		case let .structDeclaration(name: name, inherits: inherits, members: members):
			return [
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
		case let .declarationReferenceExpression(
			identifier: identifier, type: type, isStandardLibrary: isStandardLibrary,
			isImplicit: isImplicit):

			return [
				PrintableTree(type),
				PrintableTree(identifier),
				isStandardLibrary ? PrintableTree("isStandardLibrary") : nil,
				isImplicit ? PrintableTree("implicit") : nil, ]
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

	func encode(into encoder: GRYEncoder) throws {
		switch self {
		case let .variadic(count: count):
			try "variadic".encode(into: encoder)
			try count.encode(into: encoder)
		case .absent:
			try "absent".encode(into: encoder)
		case .present:
			try "present".encode(into: encoder)
		}
	}

	static func decode(from decoder: GRYDecoder) throws -> TupleShuffleIndex {
		let caseName = try String.decode(from: decoder)
		switch caseName {
		case "variadic":
			let count = try Int.decode(from: decoder)
			return .variadic(count: count)
		case "absent":
			return .absent
		case "present":
			return .present
		default:
			throw GRYDecodingError.unexpectedContent(
				decoder: decoder, errorMessage: "Expected a ParameterIndex")
		}
	}
}

//
extension FunctionParameter: PrintableAsTree {
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
