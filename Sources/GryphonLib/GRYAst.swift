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

public class GRYSourceFile: GRYPrintableAsTree {
	let declarations: [GRYTopLevelNode]?
	let statements: [GRYTopLevelNode]?

	init(declarations: [GRYTopLevelNode]?, statements: [GRYTopLevelNode]?) {
		self.declarations = declarations
		self.statements = statements
	}

	//
	public var treeDescription: String { return "Source File" }

	public var printableSubtrees: [GRYPrintableAsTree] {
		return [GRYPrintableTree(description: "Declarations", subtrees: declarations ?? []),
				GRYPrintableTree(description: "Statements", subtrees: statements  ?? []), ]
	}
}

public class GRYTopLevelNode: GRYPrintableAsTree {
	fileprivate init() {
	}

	public var treeDescription: String { fatalError("AST nodes should provide their own names") }
	public var printableSubtrees: [GRYPrintableAsTree] { return [] }
}

public class GRYDeclaration: GRYTopLevelNode {
}

public class GRYImportDeclaration: GRYDeclaration {
	let value: String

	init(_ value: String) {
		self.value = value
		super.init()
	}

	//
	override public var treeDescription: String { return "Import \(value)" }
}

public class GRYClassDeclaration: GRYDeclaration {
	let name: String
	let inherits: [String]
	let members: [GRYDeclaration]

	init(name: String, inherits: [String], members: [GRYDeclaration]) {
		self.name = name
		self.inherits = inherits
		self.members = members
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
	override public var treeDescription: String { return "Protocol \(name)" }
}

public class GRYStructDeclaration: GRYDeclaration {
	let name: String

	init(name: String) {
		self.name = name
		super.init()
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
	let type: String
	let expression: GRYExpression?
	let getter: GRYFunctionDeclaration?
	let setter: GRYFunctionDeclaration?
	let isLet: Bool
	let extendsType: String?

	init(expression: GRYExpression?,
		 identifier: String,
		 type: String,
		 getter: GRYFunctionDeclaration?,
		 setter: GRYFunctionDeclaration?,
		 isLet: Bool,
		 extendsType: String?)
	{
		self.expression = expression
		self.identifier = identifier
		self.type = type
		self.getter = getter
		self.setter = setter
		self.isLet = isLet
		self.extendsType = extendsType
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
			 type,
			 expressionTree,
			 getterTree,
			 setterTree, ]

		return result.compactMap { $0 }
	}
}

//
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
	}

	//
	override public var treeDescription: String { return "Variable Declaration Statement" }

	override public var printableSubtrees: [GRYPrintableAsTree] {
		return variableDeclaration.printableSubtrees
	}
}

public class GRYAssignmentStatement: GRYStatement {
	let identifier: String
	let expression: GRYExpression?

	init(expression: GRYExpression?, identifier: String) {
		self.expression = expression
		self.identifier = identifier
	}

	//
	override public var treeDescription: String { return "Assignment" }

	override public var printableSubtrees: [GRYPrintableAsTree] {
		let expressionTree = expression.map {
			GRYPrintableTree(description: "Expression", subtrees: [$0])
		}
		let result: [GRYPrintableAsTree?] =
			[identifier,
			 expressionTree, ]

		return result.compactMap { $0 }
	}
}

//
public class GRYExpression: GRYTopLevelNode {
}

public class GRYForceValueExpression: GRYExpression {
	let expression: GRYExpression

	init(expression: GRYExpression) {
		self.expression = expression
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
	}

	//
	override public var treeDescription: String { return "Declaration Reference \(identifier)" }
}

public class GRYTypeExpression: GRYExpression {
	let type: String

	init(type: String) {
		self.type = type
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
	}

	//
	override public var treeDescription: String { return "Call" }

	override public var printableSubtrees: [GRYPrintableAsTree] {
		return [GRYPrintableTree(description: "Function", subtrees: [function]),
				GRYPrintableTree(description: "Parameters", subtrees: [parameters]), ]
	}
}

public class GRYLiteralExpression<T>: GRYExpression {
	let value: T

	init(value: T) {
		self.value = value
	}

	//
	override public var treeDescription: String { return "Literal \(T.self) \"\(value)\"" }
}

public class GRYNilLiteralExpression: GRYExpression {
	override init() {
	}

	//
	override public var treeDescription: String { return "Nil Literal" }
}

public class GRYInterpolatedStringLiteralExpression: GRYExpression {
	let expressions: [GRYExpression]

	init(expressions: [GRYExpression]) {
		self.expressions = expressions
	}

	//
	override public var treeDescription: String { return "Interpolated String" }

	override public var printableSubtrees: [GRYPrintableAsTree] {
		return expressions
	}
}

public class GRYTupleExpression: GRYExpression, ExpressibleByArrayLiteral {
	public typealias Pair = (name: String?, expression: GRYExpression)

	let pairs: [Pair]

	init(pairs: [Pair]) {
		self.pairs = pairs
	}

	public required init(arrayLiteral elements: Pair...) {
		self.pairs = elements
	}

	//
	override public var treeDescription: String { return "Tuple Expression" }

	override public var printableSubtrees: [GRYPrintableAsTree] {
		return pairs.map { GRYPrintableTree(description: $0.0 ?? " _:", subtrees: [$0.1]) }
	}
}
