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

public class GRYSourceFile: GRYPrintableAsTree, Codable {
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

	enum CodingKeys: String, CodingKey {
		case declarations
		case statements
	}

	required public init(from decoder: Decoder) throws {
		let container = try! decoder.container(keyedBy: CodingKeys.self)
		self.declarations =
			try! container.decodeNodesArray([GRYTopLevelNode].self, forKey: .declarations)
		self.statements =
			try! container.decodeNodesArray([GRYTopLevelNode].self, forKey: .statements)
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try! container.encode(declarations.withJsonWrappers, forKey: .declarations)
		try! container.encode(statements.withJsonWrappers, forKey: .statements)
	}

	//
	public var treeDescription: String { return "Source File" }

	public var printableSubtrees: [GRYPrintableAsTree] {
		return [GRYPrintableTree(description: "Declarations", subtrees: declarations),
				GRYPrintableTree(description: "Statements", subtrees: statements), ]
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: - JSON node
private class GRYAstJsonNode: Codable {
	let nodeType: String
	let node: GRYAstNode

	init(nodeType: String, node: GRYAstNode) {
		self.nodeType = nodeType
		self.node = node
	}

	enum CodingKeys: String, CodingKey {
		case nodeType
		case node
	}

	required public init(from decoder: Decoder) throws {
		let container = try! decoder.container(keyedBy: CodingKeys.self)

		let nodeType = try! container.decode(String.self, forKey: .nodeType)
		let node: GRYAstNode

		switch nodeType {
		case String(describing: GRYImportDeclaration.self):
			node = try! container.decode(GRYImportDeclaration.self, forKey: .node)
		case String(describing: GRYClassDeclaration.self):
			node = try! container.decode(GRYClassDeclaration.self, forKey: .node)
		case String(describing: GRYConstructorDeclaration.self):
			node = try! container.decode(GRYConstructorDeclaration.self, forKey: .node)
		case String(describing: GRYDestructorDeclaration.self):
			node = try! container.decode(GRYDestructorDeclaration.self, forKey: .node)
		case String(describing: GRYEnumDeclaration.self):
			node = try! container.decode(GRYEnumDeclaration.self, forKey: .node)
		case String(describing: GRYProtocolDeclaration.self):
			node = try! container.decode(GRYProtocolDeclaration.self, forKey: .node)
		case String(describing: GRYStructDeclaration.self):
			node = try! container.decode(GRYStructDeclaration.self, forKey: .node)
		case String(describing: GRYFunctionDeclaration.self):
			node = try! container.decode(GRYFunctionDeclaration.self, forKey: .node)
		case String(describing: GRYVariableDeclaration.self):
			node = try! container.decode(GRYVariableDeclaration.self, forKey: .node)

		case String(describing: GRYForEachStatement.self):
			node = try! container.decode(GRYForEachStatement.self, forKey: .node)
		case String(describing: GRYIfStatement.self):
			node = try! container.decode(GRYIfStatement.self, forKey: .node)
		case String(describing: GRYThrowStatement.self):
			node = try! container.decode(GRYThrowStatement.self, forKey: .node)
		case String(describing: GRYReturnStatement.self):
			node = try! container.decode(GRYReturnStatement.self, forKey: .node)
		case String(describing: GRYVariableDeclarationStatement.self):
			node = try! container.decode(GRYVariableDeclarationStatement.self, forKey: .node)
		case String(describing: GRYAssignmentStatement.self):
			node = try! container.decode(GRYAssignmentStatement.self, forKey: .node)

		case String(describing: GRYForceValueExpression.self):
			node = try! container.decode(GRYForceValueExpression.self, forKey: .node)
		case String(describing: GRYDeclarationReferenceExpression.self):
			node = try! container.decode(GRYDeclarationReferenceExpression.self, forKey: .node)
		case String(describing: GRYTypeExpression.self):
			node = try! container.decode(GRYTypeExpression.self, forKey: .node)
		case String(describing: GRYSubscriptExpression.self):
			node = try! container.decode(GRYSubscriptExpression.self, forKey: .node)
		case String(describing: GRYArrayExpression.self):
			node = try! container.decode(GRYArrayExpression.self, forKey: .node)
		case String(describing: GRYDotExpression.self):
			node = try! container.decode(GRYDotExpression.self, forKey: .node)
		case String(describing: GRYBinaryOperatorExpression.self):
			node = try! container.decode(GRYBinaryOperatorExpression.self, forKey: .node)
		case String(describing: GRYUnaryOperatorExpression.self):
			node = try! container.decode(GRYUnaryOperatorExpression.self, forKey: .node)
		case String(describing: GRYCallExpression.self):
			node = try! container.decode(GRYCallExpression.self, forKey: .node)
		case String(describing: GRYNilLiteralExpression.self):
			node = try! container.decode(GRYNilLiteralExpression.self, forKey: .node)
		case String(describing: GRYInterpolatedStringLiteralExpression.self):
			node = try! container.decode(GRYInterpolatedStringLiteralExpression.self, forKey: .node)
		case String(describing: GRYTupleExpression.self):
			node = try! container.decode(GRYTupleExpression.self, forKey: .node)

		case String(describing: GRYLiteralExpression<Int>.self):
			node = try! container.decode(GRYLiteralExpression<Int>.self, forKey: .node)
		case String(describing: GRYLiteralExpression<Double>.self):
			node = try! container.decode(GRYLiteralExpression<Double>.self, forKey: .node)
		case String(describing: GRYLiteralExpression<Bool>.self):
			node = try! container.decode(GRYLiteralExpression<Bool>.self, forKey: .node)
		case String(describing: GRYLiteralExpression<String>.self):
			node = try! container.decode(GRYLiteralExpression<String>.self, forKey: .node)

		default:
			node = GRYAstNode()
		}

		self.nodeType = nodeType
		self.node = node
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try! container.encode(nodeType, forKey: .nodeType)
		try! container.encode(node, forKey: .node)
	}
}

fileprivate extension Array where Element: GRYAstNode {
	var withJsonWrappers: [GRYAstJsonNode] {
		return self.map {
			GRYAstJsonNode(nodeType: String(describing: type(of: $0)), node: $0)
		}
	}
}

fileprivate extension GRYAstNode {
	var withJsonWrapper: GRYAstJsonNode {
		return GRYAstJsonNode(nodeType: String(describing: type(of: self)), node: self)
	}
}

fileprivate extension Optional where Wrapped: GRYAstNode {
	var withJsonWrapper: GRYAstJsonNode? {
		switch self {
		case .some(let wrapped):
			return GRYAstJsonNode(nodeType: String(describing: type(of: wrapped)), node: wrapped)
		case .none:
			return nil
		}
	}
}

fileprivate extension KeyedDecodingContainer {
	func decodeNodesArray<T>(_ type: [T].Type, forKey key: K) throws -> [T] {
		let jsonInstances = try! self.decode([GRYAstJsonNode].self, forKey: key)
		return jsonInstances.map { $0.node as! T }
	}

	func decodeNode<T>(_ type: T.Type, forKey key: K) throws -> T {
		let jsonInstance = try! self.decode(GRYAstJsonNode.self, forKey: key)
		return jsonInstance.node as! T
	}

	func decodeOptionalNode<T>(_ type: T.Type, forKey key: K) throws -> T? {
		let jsonInstance = try! self.decode(GRYAstJsonNode?.self, forKey: key)
		if let jsonInstance = jsonInstance {
			return (jsonInstance.node as! T)
		}
		else {
			return nil
		}
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: - Root AST nodes
public class GRYAstNode: GRYPrintableAsTree, Codable {
	fileprivate init() { }

	public var treeDescription: String { fatalError("AST nodes should provide their own names") }
	public var printableSubtrees: [GRYPrintableAsTree] { return [] }
}

public class GRYTopLevelNode: GRYAstNode {
}

public class GRYDeclaration: GRYTopLevelNode {
}

////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: - Declarations
public class GRYImportDeclaration: GRYDeclaration {
	let value: String

	init(_ value: String) {
		self.value = value
		super.init()
	}

	//
	enum CodingKeys: String, CodingKey {
		case value
	}

	override public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try! container.encode(value, forKey: .value)
	}

	required public init(from decoder: Decoder) throws {
		let container = try! decoder.container(keyedBy: CodingKeys.self)
		self.value = try! container.decode(String.self, forKey: .value)
		super.init()
	}

	//
	override public var treeDescription: String { return "Import \(value)" }
}

public class GRYClassDeclaration: GRYDeclaration {
	let name: String
	let inherits: [String]
	let members: [GRYTopLevelNode]

	init(name: String, inherits: [String], members: [GRYTopLevelNode]) {
		self.name = name
		self.inherits = inherits
		self.members = members
		super.init()
	}

	//
	enum CodingKeys: String, CodingKey {
		case name
		case inherits
		case members
	}

	override public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try! container.encode(name, forKey: .name)
		try! container.encode(inherits, forKey: .inherits)
		try! container.encode(members.withJsonWrappers, forKey: .members)
	}

	required public init(from decoder: Decoder) throws {
		let container = try! decoder.container(keyedBy: CodingKeys.self)
		self.name = try! container.decode(String.self, forKey: .name)
		self.inherits = try! container.decode([String].self, forKey: .inherits)
		self.members = try! container.decodeNodesArray([GRYTopLevelNode].self, forKey: .members)
		super.init()
	}

	//
	override public var treeDescription: String { return "Class \(name)" }

	override public var printableSubtrees: [GRYPrintableAsTree] {
		return [GRYPrintableTree(description: "Inherits", subtrees: inherits),
				GRYPrintableTree(description: "Members", subtrees: members), ]
	}
}

public class GRYConstructorDeclaration: GRYDeclaration {
	let isImplicit: Bool

	init(isImplicit: Bool) {
		self.isImplicit = isImplicit
		super.init()
	}

	//
	enum CodingKeys: String, CodingKey {
		case isImplicit
	}

	required public init(from decoder: Decoder) throws {
		let container = try! decoder.container(keyedBy: CodingKeys.self)
		self.isImplicit = try! container.decode(Bool.self, forKey: .isImplicit)
		super.init()
	}

	override public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try! container.encode(isImplicit, forKey: .isImplicit)
	}

	//
	override public var treeDescription: String {
		if isImplicit {
			return "Constructor (implicit)"
		}
		else {
			return "Constructor"
		}
	}
}

public class GRYDestructorDeclaration: GRYDeclaration {
	let isImplicit: Bool

	init(isImplicit: Bool) {
		self.isImplicit = isImplicit
		super.init()
	}

	//
	enum CodingKeys: String, CodingKey {
		case isImplicit
	}

	required public init(from decoder: Decoder) throws {
		let container = try! decoder.container(keyedBy: CodingKeys.self)
		self.isImplicit = try! container.decode(Bool.self, forKey: .isImplicit)
		super.init()
	}

	override public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try! container.encode(isImplicit, forKey: .isImplicit)
	}

	//
	override public var treeDescription: String {
		if isImplicit {
			return "Destructor (implicit)"
		}
		else {
			return "Destructor"
		}
	}
}

public class GRYEnumDeclaration: GRYDeclaration {
	let access: String
	let name: String
	let inherits: [String]
	let elements: [String]

	init(access: String, name: String, inherits: [String], elements: [String]) {
		self.access = access
		self.name = name
		self.inherits = inherits
		self.elements = elements
		super.init()
	}

	//
	enum CodingKeys: String, CodingKey {
		case access
		case name
		case inherits
		case elements
	}

	required public init(from decoder: Decoder) throws {
		let container = try! decoder.container(keyedBy: CodingKeys.self)
		self.access = try! container.decode(String.self, forKey: .access)
		self.name = try! container.decode(String.self, forKey: .name)
		self.inherits = try! container.decode([String].self, forKey: .inherits)
		self.elements = try! container.decode([String].self, forKey: .elements)
		super.init()
	}

	override public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try! container.encode(access, forKey: .access)
		try! container.encode(name, forKey: .name)
		try! container.encode(inherits, forKey: .inherits)
		try! container.encode(elements, forKey: .elements)
	}

	//
	override public var treeDescription: String { return "Enum \(name)" }

	override public var printableSubtrees: [GRYPrintableAsTree] {
		return [access,
				GRYPrintableTree(description: "Inherits",
								 subtrees: inherits),
				GRYPrintableTree(description: "Elements",
								 subtrees: elements), ]
	}
}

public class GRYProtocolDeclaration: GRYDeclaration {
	let name: String

	init(name: String) {
		self.name = name
		super.init()
	}

	//
	enum CodingKeys: String, CodingKey {
		case name
	}

	required public init(from decoder: Decoder) throws {
		let container = try! decoder.container(keyedBy: CodingKeys.self)
		self.name = try! container.decode(String.self, forKey: .name)
		super.init()
	}

	override public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try! container.encode(name, forKey: .name)
	}

	//
	override public var treeDescription: String { return "Protocol \(name)" }
}

public class GRYStructDeclaration: GRYDeclaration {
	let name: String

	init(name: String) {
		self.name = name
		super.init()
	}

	//
	enum CodingKeys: String, CodingKey {
		case name
	}

	required public init(from decoder: Decoder) throws {
		let container = try! decoder.container(keyedBy: CodingKeys.self)
		self.name = try! container.decode(String.self, forKey: .name)
		super.init()
	}

	override public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try! container.encode(name, forKey: .name)
	}

	//
	override public var treeDescription: String { return "Struct \(name)" }
}

public class GRYFunctionDeclaration: GRYDeclaration {
	let prefix: String
	let parameterNames: [String]
	let parameterTypes: [String]
	let returnType: String
	let isImplicit: Bool
	let statements: [GRYTopLevelNode]
	let access: String

	init(
		prefix: String,
		parameterNames: [String],
		parameterTypes: [String],
		returnType: String,
		isImplicit: Bool,
		statements: [GRYTopLevelNode],
		access: String)
	{
		self.prefix = prefix
		self.parameterNames = parameterNames
		self.parameterTypes = parameterTypes
		self.returnType = returnType
		self.isImplicit = isImplicit
		self.statements = statements
		self.access = access
		super.init()
	}

	//
	enum CodingKeys: String, CodingKey {
		case prefix
		case parameterNames
		case parameterTypes
		case returnType
		case isImplicit
		case statements
		case access
	}

	required public init(from decoder: Decoder) throws {
		let container = try! decoder.container(keyedBy: CodingKeys.self)
		self.prefix = try! container.decode(String.self, forKey: .prefix)
		self.parameterNames = try! container.decode([String].self, forKey: .parameterNames)
		self.parameterTypes = try! container.decode([String].self, forKey: .parameterTypes)
		self.returnType = try! container.decode(String.self, forKey: .returnType)
		self.isImplicit = try! container.decode(Bool.self, forKey: .isImplicit)
		self.access = try! container.decode(String.self, forKey: .access)
		self.statements =
			try! container.decodeNodesArray([GRYTopLevelNode].self, forKey: .statements)
		super.init()
	}

	override public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try! container.encode(prefix, forKey: .prefix)
		try! container.encode(parameterNames, forKey: .parameterNames)
		try! container.encode(parameterTypes, forKey: .parameterTypes)
		try! container.encode(returnType, forKey: .returnType)
		try! container.encode(isImplicit, forKey: .isImplicit)
		try! container.encode(access, forKey: .access)
		try! container.encode(statements.withJsonWrappers, forKey: .statements)
	}

	//
	override public var treeDescription: String {
		let parametersString = parameterNames.map { "\($0):" }.joined(separator: ", ")
		return "Function \(prefix)(\(parametersString))"
	}

	override public var printableSubtrees: [GRYPrintableAsTree] {
		let result: [GRYPrintableAsTree?] =
			[access,
			 isImplicit ? "Implicit" : nil,
			 "(\(parameterTypes.joined(separator: ", "))) -> \(returnType)",
			 GRYPrintableTree(description: "Statements", subtrees: statements), ]

		return result.compactMap { $0 }
	}
}

public class GRYVariableDeclaration: GRYDeclaration {
	let identifier: String
	let typeName: String
	let expression: GRYExpression?
	let getter: GRYFunctionDeclaration?
	let setter: GRYFunctionDeclaration?
	let isLet: Bool
	let extendsType: String?

	init(expression: GRYExpression?,
		 identifier: String,
		 type typeName: String,
		 getter: GRYFunctionDeclaration?,
		 setter: GRYFunctionDeclaration?,
		 isLet: Bool,
		 extendsType: String?)
	{
		self.expression = expression
		self.identifier = identifier
		self.typeName = typeName
		self.getter = getter
		self.setter = setter
		self.isLet = isLet
		self.extendsType = extendsType
		super.init()
	}

	//
	enum CodingKeys: String, CodingKey {
		case identifier
		case typeName
		case expression
		case getter
		case setter
		case isLet
		case extendsType
	}

	required public init(from decoder: Decoder) throws {
		let container = try! decoder.container(keyedBy: CodingKeys.self)
		self.identifier = try! container.decode(String.self, forKey: .identifier)
		self.typeName = try! container.decode(String.self, forKey: .typeName)
		self.isLet = try! container.decode(Bool.self, forKey: .isLet)
		self.extendsType = try! container.decode(String?.self, forKey: .extendsType)
		self.expression = try! container.decodeOptionalNode(GRYExpression.self, forKey: .expression)
		self.getter =
			try! container.decodeOptionalNode(GRYFunctionDeclaration.self, forKey: .getter)
		self.setter =
			try! container.decodeOptionalNode(GRYFunctionDeclaration.self, forKey: .setter)
		super.init()
	}

	override public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try! container.encode(identifier, forKey: .identifier)
		try! container.encode(typeName, forKey: .typeName)
		try! container.encode(isLet, forKey: .isLet)
		try! container.encode(extendsType, forKey: .extendsType)
		try! container.encode(expression.withJsonWrapper, forKey: .expression)
		try! container.encode(getter.withJsonWrapper, forKey: .getter)
		try! container.encode(setter.withJsonWrapper, forKey: .setter)
	}

	//
	override public var treeDescription: String { return "Variable Declaration" }

	override public var printableSubtrees: [GRYPrintableAsTree] {
		let expressionTree = expression.map {
			GRYPrintableTree(description: "Expression", subtrees: [$0])
		}
		let getterTree = getter.map {
			GRYPrintableTree(description: "Getter", subtrees: [$0])
		}
		let setterTree = setter.map {
			GRYPrintableTree(description: "Setter", subtrees: [$0])
		}
		let result: [GRYPrintableAsTree?] =
			[extendsType.map { "Extends \($0)" },
			 isLet ? "let" : "var",
			 identifier,
			 typeName,
			 expressionTree,
			 getterTree,
			 setterTree, ]

		return result.compactMap { $0 }
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: - Statements
public class GRYStatement: GRYTopLevelNode {
}

public class GRYForEachStatement: GRYStatement {
	let collection: GRYExpression
	let variable: GRYExpression
	let statements: [GRYStatement]

	init(collection: GRYExpression, variable: GRYExpression, statements: [GRYStatement]) {
		self.collection = collection
		self.variable = variable
		self.statements = statements
		super.init()
	}

	//
	enum CodingKeys: String, CodingKey {
		case collection
		case variable
		case statements
	}

	required public init(from decoder: Decoder) throws {
		let container = try! decoder.container(keyedBy: CodingKeys.self)
		self.collection = try! container.decodeNode(GRYExpression.self, forKey: .collection)
		self.variable = try! container.decodeNode(GRYExpression.self, forKey: .variable)
		self.statements = try! container.decodeNodesArray([GRYStatement].self, forKey: .statements)
		super.init()
	}

	override public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try! container.encode(collection.withJsonWrapper, forKey: .collection)
		try! container.encode(variable.withJsonWrapper, forKey: .variable)
		try! container.encode(statements.withJsonWrappers, forKey: .statements)
	}

	//
	override public var treeDescription: String { return "For Each" }

	override public var printableSubtrees: [GRYPrintableAsTree] {
		return [GRYPrintableTree(description: "Collection", subtrees: [collection]),
				GRYPrintableTree(description: "Variable", subtrees: [variable]),
				GRYPrintableTree(description: "Statements", subtrees: statements), ]
	}
}

public class GRYIfStatement: GRYStatement {
	let conditions: [GRYExpression]
	let declarations: [GRYDeclaration]
	let statements: [GRYTopLevelNode]
	let elseStatement: GRYIfStatement?
	let isGuard: Bool

	init(conditions: [GRYExpression],
		 declarations: [GRYDeclaration],
		 statements: [GRYTopLevelNode],
		 elseStatement: GRYIfStatement?,
		 isGuard: Bool)
	{
		self.conditions = conditions
		self.declarations = declarations
		self.statements = statements
		self.elseStatement = elseStatement
		self.isGuard = isGuard
		super.init()
	}

	//
	enum CodingKeys: String, CodingKey {
		case conditions
		case declarations
		case statements
		case elseStatement
		case isGuard
	}

	required public init(from decoder: Decoder) throws {
		let container = try! decoder.container(keyedBy: CodingKeys.self)
		self.conditions = try! container.decodeNodesArray([GRYExpression].self, forKey: .conditions)
		self.declarations =
			try! container.decodeNodesArray([GRYDeclaration].self, forKey: .declarations)
		self.statements =
			try! container.decodeNodesArray([GRYTopLevelNode].self, forKey: .statements)
		self.elseStatement =
			try! container.decodeOptionalNode(GRYIfStatement.self, forKey: .elseStatement)
		self.isGuard = try! container.decode(Bool.self, forKey: .isGuard)
		super.init()
	}

	override public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try! container.encode(conditions.withJsonWrappers, forKey: .conditions)
		try! container.encode(declarations.withJsonWrappers, forKey: .declarations)
		try! container.encode(statements.withJsonWrappers, forKey: .statements)
		try! container.encode(elseStatement.withJsonWrapper, forKey: .elseStatement)
		try! container.encode(isGuard, forKey: .isGuard)
	}

	//
	override public var treeDescription: String { return "If" }

	override public var printableSubtrees: [GRYPrintableAsTree] {
		let elseTree = elseStatement.map {
			GRYPrintableTree(description: "Else", subtrees: [$0])
		}
		let result: [GRYPrintableAsTree?] = [
			"Is guard: \(isGuard)",
			GRYPrintableTree(description: "Conditions", subtrees: conditions),
			GRYPrintableTree(description: "Declarations", subtrees: declarations),
			GRYPrintableTree(description: "Statements", subtrees: statements),
			elseTree, ]

		return result.compactMap { $0 }
	}
}

public class GRYThrowStatement: GRYStatement {
	let expression: GRYExpression

	init(expression: GRYExpression) {
		self.expression = expression
		super.init()
	}

	//
	enum CodingKeys: String, CodingKey {
		case expression
	}

	required public init(from decoder: Decoder) throws {
		let container = try! decoder.container(keyedBy: CodingKeys.self)
		self.expression = try! container.decodeNode(GRYExpression.self, forKey: .expression)
		super.init()
	}

	override public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try! container.encode(expression.withJsonWrapper, forKey: .expression)
	}

	//
	override public var treeDescription: String { return "Throw" }

	override public var printableSubtrees: [GRYPrintableAsTree] {
		return [expression]
	}
}

public class GRYReturnStatement: GRYStatement {
	let expression: GRYExpression?

	init(expression: GRYExpression?) {
		self.expression = expression
		super.init()
	}

	//
	enum CodingKeys: String, CodingKey {
		case expression
	}

	required public init(from decoder: Decoder) throws {
		let container = try! decoder.container(keyedBy: CodingKeys.self)
		self.expression = try! container.decodeOptionalNode(GRYExpression.self, forKey: .expression)
		super.init()
	}

	override public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try! container.encode(expression.withJsonWrapper, forKey: .expression)
	}

	//
	override public var treeDescription: String { return "Return" }

	override public var printableSubtrees: [GRYPrintableAsTree] {
		if let expression = expression {
			return [expression]
		}
		else {
			return []
		}
	}
}

public class GRYVariableDeclarationStatement: GRYStatement {
	let variableDeclaration: GRYVariableDeclaration

	init(expression: GRYExpression?,
		 identifier: String,
		 type: String,
		 getter: GRYFunctionDeclaration?,
		 setter: GRYFunctionDeclaration?,
		 isLet: Bool,
		 extendsType: String?)
	{
		self.variableDeclaration = GRYVariableDeclaration(
			expression: expression,
			identifier: identifier,
			type: type,
			getter: getter,
			setter: setter,
			isLet: isLet,
			extendsType: extendsType)
		super.init()
	}

	//
	enum CodingKeys: String, CodingKey {
		case variableDeclaration
	}

	required public init(from decoder: Decoder) throws {
		let container = try! decoder.container(keyedBy: CodingKeys.self)
		self.variableDeclaration =
			try! container.decodeNode(GRYVariableDeclaration.self, forKey: .variableDeclaration)
		super.init()
	}

	override public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try! container.encode(variableDeclaration.withJsonWrapper, forKey: .variableDeclaration)
	}

	//
	override public var treeDescription: String { return "Variable Declaration Statement" }

	override public var printableSubtrees: [GRYPrintableAsTree] {
		return variableDeclaration.printableSubtrees
	}
}

public class GRYAssignmentStatement: GRYStatement {
	let leftHand: GRYExpression
	let rightHand: GRYExpression

	init(leftHand: GRYExpression, rightHand: GRYExpression) {
		self.leftHand = leftHand
		self.rightHand = rightHand
		super.init()
	}

	//
	enum CodingKeys: String, CodingKey {
		case leftHand
		case rightHand
	}

	required public init(from decoder: Decoder) throws {
		let container = try! decoder.container(keyedBy: CodingKeys.self)
		self.leftHand = try! container.decodeNode(GRYExpression.self, forKey: .leftHand)
		self.rightHand = try! container.decodeNode(GRYExpression.self, forKey: .rightHand)
		super.init()
	}

	override public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try! container.encode(leftHand.withJsonWrapper, forKey: .leftHand)
		try! container.encode(rightHand.withJsonWrapper, forKey: .rightHand)
	}

	//
	override public var treeDescription: String { return "Assignment" }

	override public var printableSubtrees: [GRYPrintableAsTree] {
		return [
			GRYPrintableTree(description: "Left hand", subtrees: [leftHand]),
			GRYPrintableTree(description: "Right hand", subtrees: [rightHand]), ]
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: - Expressions
public class GRYExpression: GRYTopLevelNode {
}

public class GRYForceValueExpression: GRYExpression {
	let expression: GRYExpression

	init(expression: GRYExpression) {
		self.expression = expression
		super.init()
	}

	//
	enum CodingKeys: String, CodingKey {
		case expression
	}

	required public init(from decoder: Decoder) throws {
		let container = try! decoder.container(keyedBy: CodingKeys.self)
		self.expression = try! container.decodeNode(GRYExpression.self, forKey: .expression)
		super.init()
	}

	override public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try! container.encode(expression.withJsonWrapper, forKey: .expression)
	}

	//
	override public var treeDescription: String { return "Force Value" }

	override public var printableSubtrees: [GRYPrintableAsTree] {
		return [GRYPrintableTree(description: "Expression", subtrees: [expression]), ]
	}
}

public class GRYDeclarationReferenceExpression: GRYExpression {
	let identifier: String

	init(identifier: String) {
		self.identifier = identifier
		super.init()
	}

	//
	enum CodingKeys: String, CodingKey {
		case identifier
	}

	required public init(from decoder: Decoder) throws {
		let container = try! decoder.container(keyedBy: CodingKeys.self)
		self.identifier = try! container.decode(String.self, forKey: .identifier)
		super.init()
	}

	override public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try! container.encode(identifier, forKey: .identifier)
	}

	//
	override public var treeDescription: String { return "Declaration Reference \(identifier)" }
}

public class GRYTypeExpression: GRYExpression {
	let type: String

	init(type: String) {
		self.type = type
		super.init()
	}

	//
	enum CodingKeys: String, CodingKey {
		case type
	}

	required public init(from decoder: Decoder) throws {
		let container = try! decoder.container(keyedBy: CodingKeys.self)
		self.type = try! container.decode(String.self, forKey: .type)
		super.init()
	}

	override public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try! container.encode(type, forKey: .type)
	}

	//
	override public var treeDescription: String { return "Type \(type)" }
}

public class GRYSubscriptExpression: GRYExpression {
	let subscriptedExpression: GRYExpression
	let indexExpression: GRYExpression

	init(subscriptedExpression: GRYExpression, indexExpression: GRYExpression) {
		self.subscriptedExpression = subscriptedExpression
		self.indexExpression = indexExpression
		super.init()
	}

	//
	enum CodingKeys: String, CodingKey {
		case subscriptedExpression
		case indexExpression
	}

	required public init(from decoder: Decoder) throws {
		let container = try! decoder.container(keyedBy: CodingKeys.self)
		self.subscriptedExpression =
			try! container.decodeNode(GRYExpression.self, forKey: .subscriptedExpression)
		self.indexExpression =
			try! container.decodeNode(GRYExpression.self, forKey: .indexExpression)
		super.init()
	}

	override public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try! container.encode(subscriptedExpression.withJsonWrapper, forKey: .subscriptedExpression)
		try! container.encode(indexExpression.withJsonWrapper, forKey: .indexExpression)
	}

	//
	override public var treeDescription: String { return "Subscript" }

	override public var printableSubtrees: [GRYPrintableAsTree] {
		return [
			GRYPrintableTree(description: "Subscripted", subtrees: [subscriptedExpression]),
			GRYPrintableTree(description: "Index", subtrees: [indexExpression]), ]
	}
}

public class GRYArrayExpression: GRYExpression {
	let elements: [GRYExpression]

	init(elements: [GRYExpression]) {
		self.elements = elements
		super.init()
	}

	//
	enum CodingKeys: String, CodingKey {
		case elements
	}

	required public init(from decoder: Decoder) throws {
		let container = try! decoder.container(keyedBy: CodingKeys.self)
		self.elements = try! container.decodeNodesArray([GRYExpression].self, forKey: .elements)
		super.init()
	}

	override public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try! container.encode(elements.withJsonWrappers, forKey: .elements)
	}

	//
	override public var treeDescription: String { return "Array" }

	override public var printableSubtrees: [GRYPrintableAsTree] {
		return elements
	}
}

public class GRYDotExpression: GRYExpression {
	let leftExpression: GRYExpression
	let rightExpression: GRYExpression

	init(leftExpression: GRYExpression, rightExpression: GRYExpression) {
		self.leftExpression = leftExpression
		self.rightExpression = rightExpression
		super.init()
	}

	//
	enum CodingKeys: String, CodingKey {
		case leftExpression
		case rightExpression
	}

	required public init(from decoder: Decoder) throws {
		let container = try! decoder.container(keyedBy: CodingKeys.self)
		self.leftExpression = try! container.decodeNode(GRYExpression.self, forKey: .leftExpression)
		self.rightExpression =
			try! container.decodeNode(GRYExpression.self, forKey: .rightExpression)
		super.init()
	}

	override public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try! container.encode(leftExpression.withJsonWrapper, forKey: .leftExpression)
		try! container.encode(rightExpression.withJsonWrapper, forKey: .rightExpression)
	}

	//
	override public var treeDescription: String { return "Dot Expression" }

	override public var printableSubtrees: [GRYPrintableAsTree] {
		return [
			GRYPrintableTree(description: "Left", subtrees: [leftExpression]),
			GRYPrintableTree(description: "Right", subtrees: [rightExpression]), ]
	}
}

public class GRYBinaryOperatorExpression: GRYExpression {
	let leftExpression: GRYExpression
	let rightExpression: GRYExpression
	let operatorSymbol: String

	init(leftExpression: GRYExpression, rightExpression: GRYExpression, operatorSymbol: String) {
		self.leftExpression = leftExpression
		self.rightExpression = rightExpression
		self.operatorSymbol = operatorSymbol
		super.init()
	}

	//
	enum CodingKeys: String, CodingKey {
		case leftExpression
		case rightExpression
		case operatorSymbol
	}

	required public init(from decoder: Decoder) throws {
		let container = try! decoder.container(keyedBy: CodingKeys.self)
		self.leftExpression = try! container.decodeNode(GRYExpression.self, forKey: .leftExpression)
		self.rightExpression =
			try! container.decodeNode(GRYExpression.self, forKey: .rightExpression)
		self.operatorSymbol = try! container.decode(String.self, forKey: .operatorSymbol)
		super.init()
	}

	override public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try! container.encode(leftExpression.withJsonWrapper, forKey: .leftExpression)
		try! container.encode(rightExpression.withJsonWrapper, forKey: .rightExpression)
		try! container.encode(operatorSymbol, forKey: .operatorSymbol)
	}

	//
	override public var treeDescription: String { return "Binary Operator" }

	override public var printableSubtrees: [GRYPrintableAsTree] {
		return [
			GRYPrintableTree(description: "Left", subtrees: [leftExpression]),
			"Operator \(operatorSymbol)",
			GRYPrintableTree(description: "Right", subtrees: [rightExpression]), ]
	}
}

public class GRYUnaryOperatorExpression: GRYExpression {
	let expression: GRYExpression
	let operatorSymbol: String

	init(expression: GRYExpression, operatorSymbol: String) {
		self.expression = expression
		self.operatorSymbol = operatorSymbol
		super.init()
	}

	//
	enum CodingKeys: String, CodingKey {
		case expression
		case operatorSymbol
	}

	required public init(from decoder: Decoder) throws {
		let container = try! decoder.container(keyedBy: CodingKeys.self)
		self.expression = try! container.decodeNode(GRYExpression.self, forKey: .expression)
		self.operatorSymbol = try! container.decode(String.self, forKey: .operatorSymbol)
		super.init()
	}

	override public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try! container.encode(expression.withJsonWrapper, forKey: .expression)
		try! container.encode(operatorSymbol, forKey: .operatorSymbol)
	}

	//
	override public var treeDescription: String { return "Unary Operator" }

	override public var printableSubtrees: [GRYPrintableAsTree] {
		return [
			"Operator \(operatorSymbol)",
			GRYPrintableTree(description: "Expression", subtrees: [expression]), ]
	}
}

public class GRYCallExpression: GRYExpression {
	let function: GRYExpression
	let parameters: GRYTupleExpression

	init(function: GRYExpression, parameters: GRYTupleExpression) {
		self.function = function
		self.parameters = parameters
		super.init()
	}

	//
	enum CodingKeys: String, CodingKey {
		case function
		case parameters
	}

	required public init(from decoder: Decoder) throws {
		let container = try! decoder.container(keyedBy: CodingKeys.self)
		self.function = try! container.decodeNode(GRYExpression.self, forKey: .function)
		self.parameters = try! container.decodeNode(GRYTupleExpression.self, forKey: .parameters)
		super.init()
	}

	override public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try! container.encode(function.withJsonWrapper, forKey: .function)
		try! container.encode(parameters.withJsonWrapper, forKey: .parameters)
	}

	//
	override public var treeDescription: String { return "Call" }

	override public var printableSubtrees: [GRYPrintableAsTree] {
		return [GRYPrintableTree(description: "Function", subtrees: [function]),
				GRYPrintableTree(description: "Parameters", subtrees: [parameters]), ]
	}
}

public class GRYLiteralExpression<T: Codable>: GRYExpression {
	let value: T

	init(value: T) {
		self.value = value
		super.init()
	}

	//
	enum CodingKeys: String, CodingKey {
		case value
	}

	required public init(from decoder: Decoder) throws {
		let container = try! decoder.container(keyedBy: CodingKeys.self)
		self.value = try! container.decode(T.self, forKey: .value)
		super.init()
	}

	override public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try! container.encode(value, forKey: .value)
	}

	//
	override public var treeDescription: String { return "Literal \(T.self) \"\(value)\"" }
}

public class GRYNilLiteralExpression: GRYExpression {
	override init() {
		super.init()
	}

	//
	required public init(from decoder: Decoder) throws {
		super.init()
	}

	//
	override public var treeDescription: String { return "Nil Literal" }
}

public class GRYInterpolatedStringLiteralExpression: GRYExpression {
	let expressions: [GRYExpression]

	init(expressions: [GRYExpression]) {
		self.expressions = expressions
		super.init()
	}

	//
	enum CodingKeys: String, CodingKey {
		case expressions
	}

	required public init(from decoder: Decoder) throws {
		let container = try! decoder.container(keyedBy: CodingKeys.self)
		self.expressions =
			try! container.decodeNodesArray([GRYExpression].self, forKey: .expressions)
		super.init()
	}

	override public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try! container.encode(expressions.withJsonWrappers, forKey: .expressions)
	}

	//
	override public var treeDescription: String { return "Interpolated String" }

	override public var printableSubtrees: [GRYPrintableAsTree] {
		return expressions
	}
}

public class GRYTupleExpression: GRYExpression, ExpressibleByArrayLiteral {
	public struct Pair: Codable {
		let name: String?
		let expression: GRYExpression
	}

	let pairs: [Pair]

	init(pairs: [Pair]) {
		self.pairs = pairs
		super.init()
	}

	public required init(arrayLiteral elements: Pair...) {
		self.pairs = elements
		super.init()
	}

	//
	enum CodingKeys: String, CodingKey {
		case names
		case expressions
	}

	required public init(from decoder: Decoder) throws {
		let container = try! decoder.container(keyedBy: CodingKeys.self)
		let names = try! container.decode([String?].self, forKey: .names)
		let expressions = try! container.decodeNodesArray([GRYExpression].self, forKey: .expressions)
		self.pairs = zip(names, expressions).map { Pair(name: $0, expression: $1) }
		super.init()
	}

	override public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		let names = pairs.map { $0.name }
		let expressions = pairs.map { $0.expression }
		try! container.encode(names, forKey: .names)
		try! container.encode(expressions.withJsonWrappers, forKey: .expressions)
	}

	//
	override public var treeDescription: String { return "Tuple Expression" }

	override public var printableSubtrees: [GRYPrintableAsTree] {
		return pairs.map {
			GRYPrintableTree(description: $0.name ?? " _:", subtrees: [$0.expression])
		}
	}
}
