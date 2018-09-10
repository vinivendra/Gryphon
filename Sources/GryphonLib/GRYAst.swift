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
	let declarations: [GRYAst]?
	let statements: [GRYAst]?

	init(declarations: [GRYAst]?, statements: [GRYAst]?) {
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

public class GRYAst: GRYPrintableAsTree {
	fileprivate init() {
	}

	public var treeDescription: String { fatalError("AST nodes should provide their own names") }
	public var printableSubtrees: [GRYPrintableAsTree] { return [] }
}

public class GRYDeclaration: GRYAst {
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
	let statements: [GRYStatement]
	let access: String

	init(
		prefix: String,
		parameterNames: [String],
		parameterTypes: [String],
		returnType: String,
		isImplicit: Bool,
		statements: [GRYStatement],
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
		return "Function \(prefix)(\(parameterNames.joined(separator: ": "))"
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
public class GRYStatement: GRYAst {
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
	let condition: GRYExpression?
	let declarations: [GRYDeclaration]
	let statements: [GRYStatement]
	let elseStatement: GRYIfStatement?

	init(condition: GRYExpression?,
		 declarations: [GRYDeclaration],
		 statements: [GRYStatement],
		 elseStatement: GRYIfStatement?)
	{
		self.condition = condition
		self.declarations = declarations
		self.statements = statements
		self.elseStatement = elseStatement
	}

	//
	override public var treeDescription: String { return "If" }

	override public var printableSubtrees: [GRYPrintableAsTree] {
		let conditionTree = condition.map {
			GRYPrintableTree(description: "Condition", subtrees: [$0])
		}
		let elseTree = condition.map {
			GRYPrintableTree(description: "Else", subtrees: [$0])
		}
		let result = [conditionTree,
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
public class GRYExpression: GRYPrintableAsTree {
	public var treeDescription: String { fatalError("Expressions should provide their own names") }
	public var printableSubtrees: [GRYPrintableAsTree] { return [] }
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
	let functionPrefix: String
	let parameters: [GRYExpression]
	let parameterNames: [String]

	init(functionPrefix: String, parameters: [GRYExpression], parameterNames: [String]) {
		self.functionPrefix = functionPrefix
		self.parameters = parameters
		self.parameterNames = parameterNames
	}

	//
	override public var treeDescription: String { return "Call \(functionPrefix)" }

	override public var printableSubtrees: [GRYPrintableAsTree] {
		return zip(parameterNames, parameters).map {
			GRYPrintableTree(description: $0.0 + ":", subtrees: [$0.1])
		}
	}
}

public class GRYLiteralExpression<T>: GRYExpression {
	let value: T

	init(value: T) {
		self.value = value
	}

	//
	override public var treeDescription: String { return "Literal <\(T.self)> \(value)" }
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
