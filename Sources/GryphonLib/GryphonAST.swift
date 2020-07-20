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

// gryphon output: Sources/GryphonLib/GryphonAST.swiftAST
// gryphon output: Sources/GryphonLib/GryphonAST.gryphonASTRaw
// gryphon output: Sources/GryphonLib/GryphonAST.gryphonAST
// gryphon output: Bootstrap/GryphonAST.kt

// gryphon insert: import kotlin.system.*

public final class GryphonAST: PrintableAsTree, Equatable, CustomStringConvertible {
	let sourceFile: SourceFile?
	let declarations: MutableList<Statement>
	let statements: MutableList<Statement>
	let outputFileMap: MutableMap<FileExtension, String>

	init(
		sourceFile: SourceFile?,
		declarations: MutableList<Statement>,
		statements: MutableList<Statement>,
		outputFileMap: MutableMap<FileExtension, String>)
	{
		self.sourceFile = sourceFile
		self.declarations = declarations
		self.statements = statements
		self.outputFileMap = outputFileMap
	}

	//
	public static func == (lhs: GryphonAST, rhs: GryphonAST) -> Bool {
		return lhs.declarations == rhs.declarations &&
			lhs.statements == rhs.statements
	}

	//
	public var treeDescription: String { // gryphon annotation: override
		return "Source File"
	}

	public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		return
			[PrintableTree(
				"Declarations",
				declarations.forceCast(to: List<PrintableAsTree?>.self)),
			 PrintableTree(
				"Statements",
				statements.forceCast(to: List<PrintableAsTree?>.self)), ]
	}

	//
	public var description: String {
		return prettyDescription()
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////

extension PrintableTree {
	static func ofStatements(
		_ description: String,
		_ subtrees: List<Statement>)
		-> PrintableAsTree?
	{
		let newSubtrees = subtrees.forceCast(to: List<PrintableAsTree?>.self)
		return PrintableTree.initOrNil(description, newSubtrees)
	}
}

/// Necessary changes when adding a new statement:
/// - GryphonAST's `Statement.==`
/// - `TranspilationPass.replaceStatement`
/// - `SwiftTranslator.translateStatement`
/// - `KotlinTranslator.translateSubtree`
/// - LibraryTranspilationPass's `Expression.matches`
public /*abstract*/ class Statement: PrintableAsTree, Equatable, CustomStringConvertible {
	let name: String
	let range: SourceFileRange?

	init(range: SourceFileRange?, name: String) {
		self.range = range
		self.name = name
	}

	// PrintableAsTree
	public var treeDescription: String { // gryphon annotation: override
		return name
	}

	public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		fatalError("Accessing field in abstract class Statement")
	}

	public static func == (lhs: Statement, rhs: Statement) -> Bool {
		if let lhs = lhs as? CommentStatement, let rhs = rhs as? CommentStatement {
			return lhs == rhs
		}
		if let lhs = lhs as? ExpressionStatement, let rhs = rhs as? ExpressionStatement {
			return lhs == rhs
		}
		if let lhs = lhs as? TypealiasDeclaration, let rhs = rhs as? TypealiasDeclaration {
			return lhs == rhs
		}
		if let lhs = lhs as? ExtensionDeclaration, let rhs = rhs as? ExtensionDeclaration {
			return lhs == rhs
		}
		if let lhs = lhs as? ImportDeclaration, let rhs = rhs as? ImportDeclaration {
			return lhs == rhs
		}
		if let lhs = lhs as? ClassDeclaration, let rhs = rhs as? ClassDeclaration {
			return lhs == rhs
		}
		if let lhs = lhs as? CompanionObject, let rhs = rhs as? CompanionObject {
			return lhs == rhs
		}
		if let lhs = lhs as? EnumDeclaration, let rhs = rhs as? EnumDeclaration {
			return lhs == rhs
		}
		if let lhs = lhs as? ProtocolDeclaration, let rhs = rhs as? ProtocolDeclaration {
			return lhs == rhs
		}
		if let lhs = lhs as? StructDeclaration, let rhs = rhs as? StructDeclaration {
			return lhs == rhs
		}
		if let lhs = lhs as? FunctionDeclaration, let rhs = rhs as? FunctionDeclaration {
			return lhs == rhs
		}
		if let lhs = lhs as? InitializerDeclaration, let rhs = rhs as? InitializerDeclaration {
			return lhs == rhs
		}
		if let lhs = lhs as? VariableDeclaration, let rhs = rhs as? VariableDeclaration {
			return lhs == rhs
		}
		if let lhs = lhs as? DoStatement, let rhs = rhs as? DoStatement {
			return lhs == rhs
		}
		if let lhs = lhs as? CatchStatement, let rhs = rhs as? CatchStatement {
			return lhs == rhs
		}
		if let lhs = lhs as? ForEachStatement, let rhs = rhs as? ForEachStatement {
			return lhs == rhs
		}
		if let lhs = lhs as? WhileStatement, let rhs = rhs as? WhileStatement {
			return lhs == rhs
		}
		if let lhs = lhs as? IfStatement, let rhs = rhs as? IfStatement {
			return lhs == rhs
		}
		if let lhs = lhs as? SwitchStatement, let rhs = rhs as? SwitchStatement {
			return lhs == rhs
		}
		if let lhs = lhs as? DeferStatement, let rhs = rhs as? DeferStatement {
			return lhs == rhs
		}
		if let lhs = lhs as? ThrowStatement, let rhs = rhs as? ThrowStatement {
			return lhs == rhs
		}
		if let lhs = lhs as? ReturnStatement, let rhs = rhs as? ReturnStatement {
			return lhs == rhs
		}
		if let lhs = lhs as? BreakStatement, let rhs = rhs as? BreakStatement {
			return lhs == rhs
		}
		if let lhs = lhs as? ContinueStatement, let rhs = rhs as? ContinueStatement {
			return lhs == rhs
		}
		if let lhs = lhs as? AssignmentStatement, let rhs = rhs as? AssignmentStatement {
			return lhs == rhs
		}
		if let lhs = lhs as? ErrorStatement, let rhs = rhs as? ErrorStatement {
			return lhs == rhs
		}

		return false
	}

	public var description: String { // gryphon ignore
		return prettyDescription()
	}
}

public class CommentStatement: Statement {
	let value: String

	init(range: SourceFileRange?, value: String) {
		self.value = value
		super.init(range: range, name: "CommentStatement".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		return [PrintableTree("//\(value)")]
	}

	public static func == (lhs: CommentStatement, rhs: CommentStatement) -> Bool {
		return lhs.value == rhs.value
	}
}

public class ExpressionStatement: Statement {
	let expression: Expression

	init(range: SourceFileRange?, expression: Expression) {
		self.expression = expression
		super.init(range: range, name: "ExpressionStatement".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		return [expression]
	}

	public static func == (lhs: ExpressionStatement, rhs: ExpressionStatement) -> Bool {
		return lhs.expression == rhs.expression
	}
}

public class TypealiasDeclaration: Statement {
	let identifier: String
	let typeName: String
	let access: String?
	let isImplicit: Bool

	init(
		range: SourceFileRange?,
		identifier: String,
		typeName: String,
		access: String?,
		isImplicit: Bool)
	{
		self.identifier = identifier
		self.typeName = typeName
		self.isImplicit = isImplicit
		self.access = access
		super.init(range: range, name: "TypealiasDeclaration".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		return [
			isImplicit ? PrintableTree("implicit") : nil,
			PrintableTree("identifier: \(identifier)"),
			PrintableTree("typeName: \(typeName)"),
			PrintableTree.initOrNil(access), ]
	}

	public static func == (lhs: TypealiasDeclaration, rhs: TypealiasDeclaration) -> Bool {
		return lhs.identifier == rhs.identifier &&
			lhs.typeName == rhs.typeName &&
			lhs.access == rhs.access &&
			lhs.isImplicit == rhs.isImplicit
	}
}

public class ExtensionDeclaration: Statement {
	let typeName: String
	let members: MutableList<Statement>

	init(
		range: SourceFileRange?,
		typeName: String,
		members: MutableList<Statement>)
	{
		self.typeName = typeName
		self.members = members
		super.init(range: range, name: "ExtensionDeclaration".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		return [
			PrintableTree(typeName),
			PrintableTree.ofStatements("members", members), ]
	}

	public static func == (lhs: ExtensionDeclaration, rhs: ExtensionDeclaration) -> Bool {
		return lhs.typeName == rhs.typeName &&
			lhs.members == rhs.members
	}
}

public class ImportDeclaration: Statement {
	let moduleName: String

	init(
		range: SourceFileRange?,
		moduleName: String)
	{
		self.moduleName = moduleName
		super.init(range: range, name: "ImportDeclaration".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		return [PrintableTree(moduleName)]
	}

	public static func == (lhs: ImportDeclaration, rhs: ImportDeclaration) -> Bool {
		return lhs.moduleName == rhs.moduleName
	}
}

public class ClassDeclaration: Statement {
	let className: String
	let annotations: MutableList<String>
	let access: String?
	let isOpen: Bool
	let inherits: MutableList<String>
	let members: MutableList<Statement>

	init(
		range: SourceFileRange?,
		className: String,
		annotations: MutableList<String>,
		access: String?,
		isOpen: Bool,
		inherits: MutableList<String>,
		members: MutableList<Statement>)
	{
		self.className = className
		self.annotations = annotations
		self.access = access
		self.isOpen = isOpen
		self.inherits = inherits
		self.members = members
		super.init(range: range, name: "ClassDeclaration".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		return  [
			PrintableTree(className),
			PrintableTree.ofStrings("annotations", annotations),
			PrintableTree.initOrNil(access),
			PrintableTree("open: \(isOpen)"),
			PrintableTree.ofStrings("inherits", inherits),
			PrintableTree.ofStatements("members", members), ]
	}

	public static func == (lhs: ClassDeclaration, rhs: ClassDeclaration) -> Bool {
		return lhs.className == rhs.className &&
			lhs.annotations == rhs.annotations &&
			lhs.access == rhs.access &&
			lhs.isOpen == rhs.isOpen &&
			lhs.inherits == rhs.inherits &&
			lhs.members == rhs.members
	}
}

public class CompanionObject: Statement {
	let members: MutableList<Statement>

	init(
		range: SourceFileRange?,
		members: MutableList<Statement>)
	{
		self.members = members
		super.init(range: range, name: "CompanionObject".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		return members.forceCast(to: List<PrintableAsTree?>.self)
	}

	public static func == (lhs: CompanionObject, rhs: CompanionObject) -> Bool {
		return lhs.members == rhs.members
	}
}

public class EnumDeclaration: Statement {
	let access: String?
	let enumName: String
	let annotations: String?
	let inherits: MutableList<String>
	let elements: MutableList<EnumElement>
	let members: MutableList<Statement>
	let isImplicit: Bool

	init(
		range: SourceFileRange?,
		access: String?,
		enumName: String,
		annotations: String?,
		inherits: MutableList<String>,
		elements: MutableList<EnumElement>,
		members: MutableList<Statement>,
		isImplicit: Bool)
	{
		self.access = access
		self.enumName = enumName
		self.annotations = annotations
		self.inherits = inherits
		self.elements = elements
		self.members = members
		self.isImplicit = isImplicit
		super.init(range: range, name: "EnumDeclaration".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		let elementTrees = elements.map
			{ (element: EnumElement) -> PrintableAsTree? in element }

		return [
			PrintableTree(enumName),
			PrintableTree.initOrNil(access),
			PrintableTree.initOrNil(
				"annotations", [PrintableTree.initOrNil(annotations)]),
			PrintableTree.ofStrings("inherits", inherits),
			PrintableTree("elements", elementTrees),
			PrintableTree.ofStatements("members", members),
			isImplicit ? PrintableTree("implicit") : nil,
		]
	}

	public static func == (lhs: EnumDeclaration, rhs: EnumDeclaration) -> Bool {
		return lhs.access == rhs.access &&
			lhs.enumName == rhs.enumName &&
			lhs.annotations == rhs.annotations &&
			lhs.inherits == rhs.inherits &&
			lhs.elements == rhs.elements &&
			lhs.members == rhs.members &&
			lhs.isImplicit == rhs.isImplicit
	}
}

public class ProtocolDeclaration: Statement {
	let protocolName: String
	let access: String?
	let annotations: String?
	let members: MutableList<Statement>

	init(
		range: SourceFileRange?,
		protocolName: String,
		access: String?,
		annotations: String?,
		members: MutableList<Statement>)
	{
		self.protocolName = protocolName
		self.access = access
		self.annotations = annotations
		self.members = members
		super.init(range: range, name: "ProtocolDeclaration".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		return [
			PrintableTree(protocolName),
			PrintableTree.initOrNil(access),
			PrintableTree.initOrNil(
				"annotations", [PrintableTree.initOrNil(annotations)]),
			PrintableTree.ofStatements("members", members), ]
	}

	public static func == (lhs: ProtocolDeclaration, rhs: ProtocolDeclaration) -> Bool {
		return lhs.protocolName == rhs.protocolName &&
			lhs.access == rhs.access &&
			lhs.annotations == rhs.annotations &&
			lhs.members == rhs.members
	}
}

public class StructDeclaration: Statement {
	let annotations: String?
	let structName: String
	let access: String?
	let inherits: MutableList<String>
	let members: MutableList<Statement>

	init(
		range: SourceFileRange?,
		annotations: String?,
		structName: String,
		access: String?,
		inherits: MutableList<String>,
		members: MutableList<Statement>)
	{
		self.annotations = annotations
		self.structName = structName
		self.access = access
		self.inherits = inherits
		self.members = members
		super.init(range: range, name: "StructDeclaration".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		return [
			PrintableTree.initOrNil(
				"annotations", [PrintableTree.initOrNil(annotations)]),
			PrintableTree(structName),
			PrintableTree.initOrNil(access),
			PrintableTree.ofStrings("inherits", inherits),
			PrintableTree.ofStatements("members", members), ]
	}

	public static func == (lhs: StructDeclaration, rhs: StructDeclaration) -> Bool {
		return lhs.annotations == rhs.annotations &&
			lhs.structName == rhs.structName &&
			lhs.access == rhs.access &&
			lhs.inherits == rhs.inherits &&
			lhs.members == rhs.members
	}
}

public class FunctionDeclaration: Statement {
	var prefix: String
	var parameters: MutableList<FunctionParameter>
	var returnType: String
	var functionType: String
	var genericTypes: MutableList<String>
	var isOpen: Bool
	var isImplicit: Bool
	var isStatic: Bool
	var isMutating: Bool
	var isPure: Bool
	var isJustProtocolInterface: Bool
	var extendsType: String?
	var statements: MutableList<Statement>?
	var access: String?
	var annotations: MutableList<String>

	init(
		range: SourceFileRange?,
		prefix: String,
		parameters: MutableList<FunctionParameter>,
		returnType: String,
		functionType: String,
		genericTypes: MutableList<String>,
		isOpen: Bool,
		isImplicit: Bool,
		isStatic: Bool,
		isMutating: Bool,
		isPure: Bool,
		isJustProtocolInterface: Bool,
		extendsType: String?,
		statements: MutableList<Statement>?,
		access: String?,
		annotations: MutableList<String>,
		name: String = "FunctionDeclaration".capitalizedAsCamelCase())
	{
		self.prefix = prefix
		self.parameters = parameters
		self.returnType = returnType
		self.functionType = functionType
		self.genericTypes = genericTypes
		self.isOpen = isOpen
		self.isImplicit = isImplicit
		self.isStatic = isStatic
		self.isMutating = isMutating
		self.isPure = isPure
		self.isJustProtocolInterface = isJustProtocolInterface
		self.extendsType = extendsType
		self.statements = statements
		self.access = access
		self.annotations = annotations
		super.init(range: range, name: name)
	}

	override public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		let parametersTrees = parameters
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
			extendsType.map { PrintableTree("extends type \($0)") },
			PrintableTree("open: \(isOpen)"),
			isImplicit ? PrintableTree("implicit") : nil,
			isStatic ? PrintableTree("static") : nil,
			isMutating ? PrintableTree("mutating") : nil,
			PrintableTree.initOrNil(access),
			PrintableTree.ofStrings("annotations", annotations),
			PrintableTree("type: \(functionType)"),
			PrintableTree.ofStrings("generic types", genericTypes),
			PrintableTree("prefix: \(prefix)"),
			PrintableTree("parameters", parametersTrees),
			PrintableTree("return type: \(returnType)"),
			PrintableTree.ofStatements(
				"statements", (statements ?? [])), ]
	}

	public static func == (lhs: FunctionDeclaration, rhs: FunctionDeclaration) -> Bool {
		return lhs.prefix == rhs.prefix &&
			lhs.parameters == rhs.parameters &&
			lhs.returnType == rhs.returnType &&
			lhs.functionType == rhs.functionType &&
			lhs.genericTypes == rhs.genericTypes &&
			lhs.isOpen == rhs.isOpen &&
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

public class InitializerDeclaration: FunctionDeclaration {
	let superCall: CallExpression?

	init(
		range: SourceFileRange?,
		parameters: MutableList<FunctionParameter>,
		returnType: String,
		functionType: String,
		genericTypes: MutableList<String>,
		isOpen: Bool,
		isImplicit: Bool,
		isStatic: Bool,
		isMutating: Bool,
		isPure: Bool,
		extendsType: String?,
		statements: MutableList<Statement>?,
		access: String?,
		annotations: MutableList<String>,
		superCall: CallExpression?,
		name: String = "FunctionDeclaration".capitalizedAsCamelCase())
	{
		self.superCall = superCall
		super.init(
			range: range,
			prefix: "init",
			parameters: parameters,
			returnType: returnType,
			functionType: functionType,
			genericTypes: genericTypes,
			isOpen: isOpen,
			isImplicit: isImplicit,
			isStatic: isStatic,
			isMutating: isMutating,
			isPure: isPure,
			isJustProtocolInterface: false,
			extendsType: extendsType,
			statements: statements,
			access: access,
			annotations: annotations,
			name: "InitializerDeclaration".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		let result = super.printableSubtrees.toMutableList()
		result.append(PrintableTree.initOrNil("super call", [superCall]))
		return result
	}

	public static func == (lhs: InitializerDeclaration, rhs: InitializerDeclaration) -> Bool {
		return
//			lhs.prefix == rhs.prefix &&	// Prefixes aren't checked because they're always "init"
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
			lhs.annotations == rhs.annotations &&
			lhs.superCall == rhs.superCall
	}
}

public class VariableDeclaration: Statement {
	var identifier: String
	var typeAnnotation: String?
	var expression: Expression?
	var getter: FunctionDeclaration?
	var setter: FunctionDeclaration?
	var access: String?
	var isOpen: Bool
	var isLet: Bool
	var isImplicit: Bool
	var isStatic: Bool
	var extendsType: String?
	var annotations: MutableList<String>

	init(
		range: SourceFileRange?,
		identifier: String,
		typeAnnotation: String?,
		expression: Expression?,
		getter: FunctionDeclaration?,
		setter: FunctionDeclaration?,
		access: String?,
		isOpen: Bool,
		isLet: Bool,
		isImplicit: Bool,
		isStatic: Bool,
		extendsType: String?,
		annotations: MutableList<String>)
	{
		self.identifier = identifier
		self.typeAnnotation = typeAnnotation
		self.expression = expression
		self.getter = getter
		self.setter = setter
		self.access = access
		self.isOpen = isOpen
		self.isLet = isLet
		self.isImplicit = isImplicit
		self.isStatic = isStatic
		self.extendsType = extendsType
		self.annotations = annotations
		super.init(range: range, name: "VariableDeclaration".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		return [
			PrintableTree.initOrNil(
				"extendsType", [PrintableTree.initOrNil(extendsType)]),
			isImplicit ? PrintableTree("implicit") : nil,
			isStatic ? PrintableTree("static") : nil,
			isLet ? PrintableTree("let") : PrintableTree("var"),
			PrintableTree(identifier),
			PrintableTree.initOrNil(
				"typeAnnotation", [PrintableTree.initOrNil(typeAnnotation)]),
			expression,
			PrintableTree.initOrNil(access),
			PrintableTree("open: \(isOpen)"),
			PrintableTree.initOrNil("getter", [getter]),
			PrintableTree.initOrNil("setter", [setter]),
			PrintableTree.ofStrings("annotations", annotations), ]
	}

	public static func == (
		lhs: VariableDeclaration,
		rhs: VariableDeclaration)
		-> Bool
	{
		return lhs.identifier == rhs.identifier &&
			lhs.typeAnnotation == rhs.typeAnnotation &&
			lhs.expression == rhs.expression &&
			lhs.getter == rhs.getter &&
			lhs.setter == rhs.setter &&
			lhs.access == rhs.access &&
			lhs.isOpen == rhs.isOpen &&
			lhs.isLet == rhs.isLet &&
			lhs.isImplicit == rhs.isImplicit &&
			lhs.isStatic == rhs.isStatic &&
			lhs.extendsType == rhs.extendsType &&
			lhs.annotations == rhs.annotations
	}
}

public class DoStatement: Statement {
	let statements: MutableList<Statement>

	init(
		range: SourceFileRange?,
		statements: MutableList<Statement>)
	{
		self.statements = statements
		super.init(range: range, name: "DoStatement".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		return statements.forceCast(to: List<PrintableAsTree?>.self)
	}

	public static func == (lhs: DoStatement, rhs: DoStatement) -> Bool {
		return lhs.statements == rhs.statements
	}
}

public class CatchStatement: Statement {
	let variableDeclaration: VariableDeclaration?
	let statements: MutableList<Statement>

	init(
		range: SourceFileRange?,
		variableDeclaration: VariableDeclaration?,
		statements: MutableList<Statement>)
	{
		self.variableDeclaration = variableDeclaration
		self.statements = statements
		super.init(range: range, name: "CatchStatement".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		return [
			PrintableTree(
				"variableDeclaration", MutableList<PrintableAsTree?>([variableDeclaration])),
			PrintableTree.ofStatements(
				"statements", statements),
		]
	}

	public static func == (lhs: CatchStatement, rhs: CatchStatement) -> Bool {
		return lhs.variableDeclaration == rhs.variableDeclaration &&
			lhs.statements == rhs.statements
	}
}

public class ForEachStatement: Statement {
	let collection: Expression
	let variable: Expression?
	let statements: MutableList<Statement>

	init(
		range: SourceFileRange?,
		collection: Expression,
		variable: Expression?,
		statements: MutableList<Statement>)
	{
		self.collection = collection
		self.variable = variable
		self.statements = statements
		super.init(range: range, name: "ForEachStatement".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		return [
			PrintableTree.initOrNil("variable", [variable]),
			PrintableTree("collection", [collection]),
			PrintableTree.ofStatements("statements", statements), ]
	}

	public static func == (lhs: ForEachStatement, rhs: ForEachStatement) -> Bool {
		return lhs.collection == rhs.collection &&
			lhs.variable == rhs.variable &&
			lhs.statements == rhs.statements
	}
}

public class WhileStatement: Statement {
	let expression: Expression
	let statements: MutableList<Statement>

	init(
		range: SourceFileRange?,
		expression: Expression,
		statements: MutableList<Statement>)
	{
		self.expression = expression
		self.statements = statements
		super.init(range: range, name: "WhileStatement".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		return [
			PrintableTree.ofExpressions("expression", [expression]),
			PrintableTree.ofStatements("statements", statements), ]
	}

	public static func == (lhs: WhileStatement, rhs: WhileStatement) -> Bool {
		return lhs.expression == rhs.expression &&
			lhs.statements == rhs.statements
	}
}

public class IfStatement: Statement {
	var conditions: MutableList<IfCondition>
	var declarations: MutableList<VariableDeclaration>
	var statements: MutableList<Statement>
	var elseStatement: IfStatement?
	var isGuard: Bool

	public enum IfCondition: Equatable {
		case condition(expression: Expression)
		case declaration(variableDeclaration: VariableDeclaration)

		func toStatement() -> Statement {
			switch self {
			case let .condition(expression: expression):
				return ExpressionStatement(range: nil, expression: expression)
			case let .declaration(variableDeclaration: variableDeclaration):
				return variableDeclaration
			}
		}
	}

	public init(
		range: SourceFileRange?,
		conditions: MutableList<IfCondition>,
		declarations: MutableList<VariableDeclaration>,
		statements: MutableList<Statement>,
		elseStatement: IfStatement?,
		isGuard: Bool)
	{
		self.conditions = conditions
		self.declarations = declarations
		self.statements = statements
		self.elseStatement = elseStatement
		self.isGuard = isGuard
		super.init(range: range, name: "IfStatement".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		let declarationTrees = declarations
		let conditionTrees = conditions.map { $0.toStatement() }
		let elseStatementTrees = elseStatement?.printableSubtrees ?? []
		return [
			isGuard ? PrintableTree("guard") : nil,
			PrintableTree(
				"declarations", declarationTrees.forceCast(to: List<PrintableAsTree?>.self)),
			PrintableTree.ofStatements(
				"conditions", conditionTrees),
			PrintableTree.ofStatements(
				"statements", statements),
			PrintableTree.initOrNil(
				"else", elseStatementTrees), ]
	}

	public static func == (
		lhs: IfStatement,
		rhs: IfStatement)
		-> Bool
	{
		return lhs.conditions == rhs.conditions &&
			lhs.declarations == rhs.declarations &&
			lhs.statements == rhs.statements &&
			lhs.elseStatement == rhs.elseStatement &&
			lhs.isGuard == rhs.isGuard
	}
}

public class SwitchStatement: Statement {
	let convertsToExpression: Statement?
	let expression: Expression
	let cases: MutableList<SwitchCase>

	init(
		range: SourceFileRange?,
		convertsToExpression: Statement?,
		expression: Expression,
		cases: MutableList<SwitchCase>)
	{
		self.convertsToExpression = convertsToExpression
		self.expression = expression
		self.cases = cases
		super.init(range: range, name: "SwitchStatement".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
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
	}

	public static func == (lhs: SwitchStatement, rhs: SwitchStatement) -> Bool {
		return lhs.convertsToExpression == rhs.convertsToExpression &&
			lhs.expression == rhs.expression &&
			lhs.cases == rhs.cases
	}
}

public class DeferStatement: Statement {
	let statements: MutableList<Statement>

	init(
		range: SourceFileRange?,
		statements: MutableList<Statement>)
	{
		self.statements = statements
		super.init(range: range, name: "DeferStatement".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		return statements.forceCast(to: List<PrintableAsTree?>.self)
	}

	public static func == (lhs: DeferStatement, rhs: DeferStatement) -> Bool {
		return lhs.statements == rhs.statements
	}
}

public class ThrowStatement: Statement {
	let expression: Expression

	init(
		range: SourceFileRange?,
		expression: Expression)
	{
		self.expression = expression
		super.init(range: range, name: "ThrowStatement".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		return [expression]
	}

	public static func == (lhs: ThrowStatement, rhs: ThrowStatement) -> Bool {
		return lhs.expression == rhs.expression
	}
}

public class ReturnStatement: Statement {
	let expression: Expression?
	let label: String?

	init(
		range: SourceFileRange?,
		expression: Expression?,
		label: String?)
	{
		self.expression = expression
		self.label = label
		super.init(range: range, name: "ReturnStatement".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		return [expression, PrintableTree.initOrNil(label)]
	}

	public static func == (lhs: ReturnStatement, rhs: ReturnStatement) -> Bool {
		return lhs.expression == rhs.expression &&
			lhs.label == rhs.label
	}
}

public class BreakStatement: Statement {
	init(range: SourceFileRange?) {
		super.init(range: range, name: "BreakStatement".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		return []
	}

	public static func == (lhs: BreakStatement, rhs: BreakStatement) -> Bool {
		return true
	}
}

public class ContinueStatement: Statement {
	init(range: SourceFileRange?) {
		super.init(range: range, name: "ContinueStatement".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		return []
	}

	public static func == (lhs: ContinueStatement, rhs: ContinueStatement) -> Bool {
		return true
	}
}

public class AssignmentStatement: Statement {
	let leftHand: Expression
	let rightHand: Expression

	init(
		range: SourceFileRange?,
		leftHand: Expression,
		rightHand: Expression)
	{
		self.leftHand = leftHand
		self.rightHand = rightHand
		super.init(range: range, name: "AssignmentStatement".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		return [leftHand, rightHand]
	}

	public static func == (lhs: AssignmentStatement, rhs: AssignmentStatement) -> Bool {
		return lhs.leftHand == rhs.leftHand &&
			lhs.rightHand == rhs.rightHand
	}
}

public class ErrorStatement: Statement {
	init(range: SourceFileRange?) {
		super.init(range: range, name: "ErrorStatement".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		return []
	}

	public static func == (lhs: ErrorStatement, rhs: ErrorStatement) -> Bool {
		return true
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////

extension PrintableTree {
	static func ofExpressions(
		_ description: String,
		_ subtrees: List<Expression>)
		-> PrintableAsTree?
	{
		let newSubtrees = subtrees.forceCast(to: List<PrintableAsTree?>.self)
		return PrintableTree.initOrNil(description, newSubtrees)
	}
}

/// Necessary changes when adding a new expression:
/// - GryphonAST's `Expression.==`
/// - `KotlinTranslator.translateExpression`
/// - `SwiftTranslator.translateExpression`
/// - `TranspilationPass.replaceExpression`
/// - LibraryTranspilationPass's `Expression.matches`
public /*abstract*/ class Expression: PrintableAsTree, Equatable, CustomStringConvertible {
	let name: String
	var range: SourceFileRange?

	init(range: SourceFileRange?, name: String) {
		self.range = range
		self.name = name
	}

	var swiftType: String? { // gryphon annotation: open
		get {
			return nil
		}
		set { }
	}

	// PrintableAsTree
	public var treeDescription: String { // gryphon annotation: override
		return name
	}

	public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		fatalError("Accessing field in abstract class Expression")
	}

	public static func == (lhs: Expression, rhs: Expression) -> Bool {
		if let lhs = lhs as? LiteralCodeExpression,
			let rhs = rhs as? LiteralCodeExpression
		{
			return lhs == rhs
		}
		if let lhs = lhs as? LiteralCodeExpression,
			let rhs = rhs as? LiteralCodeExpression
		{
			return lhs == rhs
		}
		if let lhs = lhs as? ParenthesesExpression,
			let rhs = rhs as? ParenthesesExpression
		{
			return lhs == rhs
		}
		if let lhs = lhs as? ForceValueExpression,
			let rhs = rhs as? ForceValueExpression
		{
			return lhs == rhs
		}
		if let lhs = lhs as? OptionalExpression,
			let rhs = rhs as? OptionalExpression
		{
			return lhs == rhs
		}
		if let lhs = lhs as? DeclarationReferenceExpression,
			let rhs = rhs as? DeclarationReferenceExpression
		{
			return lhs == rhs
		}
		if let lhs = lhs as? TypeExpression,
			let rhs = rhs as? TypeExpression
		{
			return lhs == rhs
		}
		if let lhs = lhs as? SubscriptExpression,
			let rhs = rhs as? SubscriptExpression
		{
			return lhs == rhs
		}
		if let lhs = lhs as? ArrayExpression,
			let rhs = rhs as? ArrayExpression
		{
			return lhs == rhs
		}
		if let lhs = lhs as? DictionaryExpression,
			let rhs = rhs as? DictionaryExpression
		{
			return lhs == rhs
		}
		if let lhs = lhs as? ReturnExpression,
			let rhs = rhs as? ReturnExpression
		{
			return lhs == rhs
		}
		if let lhs = lhs as? DotExpression,
			let rhs = rhs as? DotExpression
		{
			return lhs == rhs
		}
		if let lhs = lhs as? BinaryOperatorExpression,
			let rhs = rhs as? BinaryOperatorExpression
		{
			return lhs == rhs
		}
		if let lhs = lhs as? PrefixUnaryExpression,
			let rhs = rhs as? PrefixUnaryExpression
		{
			return lhs == rhs
		}
		if let lhs = lhs as? PostfixUnaryExpression,
			let rhs = rhs as? PostfixUnaryExpression
		{
			return lhs == rhs
		}
		if let lhs = lhs as? IfExpression,
			let rhs = rhs as? IfExpression
		{
			return lhs == rhs
		}
		if let lhs = lhs as? CallExpression,
			let rhs = rhs as? CallExpression
		{
			return lhs == rhs
		}
		if let lhs = lhs as? ClosureExpression,
			let rhs = rhs as? ClosureExpression
		{
			return lhs == rhs
		}
		if let lhs = lhs as? LiteralIntExpression,
			let rhs = rhs as? LiteralIntExpression
		{
			return lhs == rhs
		}
		if let lhs = lhs as? LiteralUIntExpression,
			let rhs = rhs as? LiteralUIntExpression
		{
			return lhs == rhs
		}
		if let lhs = lhs as? LiteralDoubleExpression,
			let rhs = rhs as? LiteralDoubleExpression
		{
			return lhs == rhs
		}
		if let lhs = lhs as? LiteralFloatExpression,
			let rhs = rhs as? LiteralFloatExpression
		{
			return lhs == rhs
		}
		if let lhs = lhs as? LiteralBoolExpression,
			let rhs = rhs as? LiteralBoolExpression
		{
			return lhs == rhs
		}
		if let lhs = lhs as? LiteralStringExpression,
			let rhs = rhs as? LiteralStringExpression
		{
			return lhs == rhs
		}
		if let lhs = lhs as? LiteralCharacterExpression,
			let rhs = rhs as? LiteralCharacterExpression
		{
			return lhs == rhs
		}
		if lhs is NilLiteralExpression,
			rhs is NilLiteralExpression
		{
			return true
		}
		if let lhs = lhs as? InterpolatedStringLiteralExpression,
			let rhs = rhs as? InterpolatedStringLiteralExpression
		{
			return lhs == rhs
		}
		if let lhs = lhs as? TupleExpression,
			let rhs = rhs as? TupleExpression
		{
			return lhs == rhs
		}
		if let lhs = lhs as? TupleShuffleExpression,
			let rhs = rhs as? TupleShuffleExpression
		{
			return lhs == rhs
		}
		if lhs is ErrorExpression,
			rhs is ErrorExpression
		{
			return lhs == rhs
		}

		return false
	}

	public var description: String { // gryphon ignore
		return prettyDescription()
	}
}

public class LiteralCodeExpression: Expression {
	let string: String
	let shouldGoToMainFunction: Bool

	init(range: SourceFileRange?, string: String, shouldGoToMainFunction: Bool) {
		self.string = string
		self.shouldGoToMainFunction = shouldGoToMainFunction
		super.init(range: range, name: "LiteralCodeExpression".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		return [
			PrintableTree(string),
			shouldGoToMainFunction ? PrintableTree("shouldGoToMainFunction") : nil, ]
	}

	public static func == (lhs: LiteralCodeExpression, rhs: LiteralCodeExpression) -> Bool {
		return lhs.string == rhs.string &&
			lhs.shouldGoToMainFunction == rhs.shouldGoToMainFunction
	}
}

/// Represents two expressions whose translations should be joined in the output code, with no
/// characters between them. Used mainly for concatenating templates.
public class ConcatenationExpression: Expression {
	let leftExpression: Expression
	let rightExpression: Expression

	init(range: SourceFileRange?, leftExpression: Expression, rightExpression: Expression) {
		self.leftExpression = leftExpression
		self.rightExpression = rightExpression
		super.init(range: range, name: "ConcatenationExpression".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		return [
			PrintableTree.ofExpressions("left", [leftExpression]),
			PrintableTree.ofExpressions("right", [rightExpression]), ]
	}

	public static func == (lhs: ConcatenationExpression, rhs: ConcatenationExpression) -> Bool {
		return lhs.leftExpression == rhs.leftExpression &&
			lhs.rightExpression == rhs.rightExpression
	}
}

public class ParenthesesExpression: Expression {
	let expression: Expression

	init(range: SourceFileRange?, expression: Expression) {
		self.expression = expression
		super.init(range: range, name: "ParenthesesExpression".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		return [expression]
	}

	override var swiftType: String? { // gryphon annotation: override
		get {
			return expression.swiftType
		}
		set {
			expression.swiftType = newValue
		}
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

	override public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		return [expression]
	}

	override var swiftType: String? { // gryphon annotation: override
		get {
			let subtype = expression.swiftType
			if let subtype = subtype, subtype.hasSuffix("?") {
				return String(subtype.dropLast())
			}
			else {
				return nil
			}
		}
		set {
			if let newValue = newValue {
				expression.swiftType = newValue + "?"
			}
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

	override public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		return [expression]
	}

	override var swiftType: String? { // gryphon annotation: override
		get {
			let subtype = expression.swiftType
			if let subtype = subtype, subtype.hasSuffix("?") {
				return String(subtype.dropLast())
			}
			else {
				return nil
			}
		}
		set {
			if let newValue = newValue {
				expression.swiftType = newValue + "?"
			}
		}
	}

	public static func == (lhs: OptionalExpression, rhs: OptionalExpression) -> Bool {
		return lhs.expression == rhs.expression
	}
}

public class DeclarationReferenceExpression: Expression {
	var identifier: String
	var typeName: String?
	var isStandardLibrary: Bool
	var isImplicit: Bool

	init(
		range: SourceFileRange?,
		identifier: String,
		typeName: String?,
		isStandardLibrary: Bool,
		isImplicit: Bool)
	{
		self.identifier = identifier
		self.typeName = typeName
		self.isStandardLibrary = isStandardLibrary
		self.isImplicit = isImplicit
		super.init(range: range, name: "DeclarationReferenceExpression".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		return [
			PrintableTree.initOrNil(
				"type", [PrintableTree.initOrNil(typeName)]),
			PrintableTree(identifier),
			isStandardLibrary ? PrintableTree("isStandardLibrary") : nil,
			isImplicit ? PrintableTree("implicit") : nil, ]
	}

	override var swiftType: String? { // gryphon annotation: override
		get {
			return typeName
		}
		set {
			if let newValue = newValue {
				typeName = newValue
			}
		}
	}

	public static func == (
		lhs: DeclarationReferenceExpression,
		rhs: DeclarationReferenceExpression)
		-> Bool
	{
		return lhs.identifier == rhs.identifier &&
			lhs.typeName == rhs.typeName &&
			lhs.isStandardLibrary == rhs.isStandardLibrary &&
			lhs.isImplicit == rhs.isImplicit
	}
}

public class TypeExpression: Expression {
	var typeName: String

	init(range: SourceFileRange?, typeName: String) {
		self.typeName = typeName
		super.init(range: range, name: "TypeExpression".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		return [PrintableTree(typeName)]
	}

	override var swiftType: String? { // gryphon annotation: override
		get {
			return typeName
		}
		set {
			if let newValue = newValue {
				typeName = newValue
			}
		}
	}

	public static func == (lhs: TypeExpression, rhs: TypeExpression) -> Bool {
		return lhs.typeName == rhs.typeName
	}
}

public class SubscriptExpression: Expression {
	let subscriptedExpression: Expression
	let indexExpression: Expression
	var typeName: String

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

	override public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		return [
			PrintableTree("type \(typeName)"),
			PrintableTree.ofExpressions("subscriptedExpression", [subscriptedExpression]),
			PrintableTree.ofExpressions("indexExpression", [indexExpression]), ]
	}

	override var swiftType: String? { // gryphon annotation: override
		get {
			return typeName
		}
		set {
			if let newValue = newValue {
				typeName = newValue
			}
		}
	}

	public static func == (lhs: SubscriptExpression, rhs: SubscriptExpression) -> Bool {
		return lhs.subscriptedExpression == rhs.subscriptedExpression &&
			lhs.indexExpression == rhs.indexExpression &&
			lhs.typeName == rhs.typeName
	}
}

public class ArrayExpression: Expression {
	let elements: MutableList<Expression>
	var typeName: String

	init(range: SourceFileRange?, elements: MutableList<Expression>, typeName: String) {
		self.elements = elements
		self.typeName = typeName
		super.init(range: range, name: "ArrayExpression".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		return [
			PrintableTree("type \(typeName)"),
			PrintableTree.ofExpressions("elements", elements), ]
	}

	override var swiftType: String? { // gryphon annotation: override
		get {
			return typeName
		}
		set {
			if let newValue = newValue {
				typeName = newValue
			}
		}
	}

	public static func == (lhs: ArrayExpression, rhs: ArrayExpression) -> Bool {
		return lhs.elements == rhs.elements &&
			lhs.typeName == rhs.typeName
	}
}

public class DictionaryExpression: Expression {
	let keys: MutableList<Expression>
	let values: MutableList<Expression>
	var typeName: String

	init(
		range: SourceFileRange?,
		keys: MutableList<Expression>,
		values: MutableList<Expression>,
		typeName: String)
	{
		self.keys = keys
		self.values = values
		self.typeName = typeName
		super.init(range: range, name: "DictionaryExpression".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		let keyValueTrees = zip(keys, values).map
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

	override var swiftType: String? { // gryphon annotation: override
		get {
			return typeName
		}
		set {
			if let newValue = newValue {
				typeName = newValue
			}
		}
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

	override public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		return [expression]
	}

	override var swiftType: String? { // gryphon annotation: override
		get {
			return expression?.swiftType
		}
		set {
			expression?.swiftType = newValue
		}
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

	override public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		return [
			PrintableTree.ofExpressions("left", [leftExpression]),
			PrintableTree.ofExpressions("right", [rightExpression]), ]
	}

	override var swiftType: String? { // gryphon annotation: override
		get {
			// Enum references should be considered to have the left type, as the right expression's
			// is a function type (something like `(MyEnum.Type) -> MyEnum` or
			// `(A.MyEnum.Type) -> A.MyEnum`).
			if let leftType = leftExpression as? TypeExpression,
				let rightDeclarationReference = rightExpression as? DeclarationReferenceExpression,
				let rightType = rightDeclarationReference.typeName
			{
				let enumType = leftType.typeName

				if rightType.hasPrefix("("),
					rightType.contains("\(enumType).Type) -> "),
					rightType.hasSuffix(enumType)
				{
					return enumType
				}
			}

			return rightExpression.swiftType
		}
		set {
			rightExpression.swiftType = newValue
		}
	}

	public static func == (lhs: DotExpression, rhs: DotExpression) -> Bool {
		return lhs.leftExpression == rhs.leftExpression &&
			lhs.rightExpression == rhs.rightExpression
	}
}

/// Does not take into consideration operator precedence, since that information isn't available in
/// SwiftSyntax. Other `BinaryOperatorExpressions` can show up recursively on the right side.
public class BinaryOperatorExpression: Expression {
	let leftExpression: Expression
	let rightExpression: Expression
	let operatorSymbol: String
	var typeName: String?

	init(
		range: SourceFileRange?,
		leftExpression: Expression,
		rightExpression: Expression,
		operatorSymbol: String,
		typeName: String?)
	{
		self.leftExpression = leftExpression
		self.rightExpression = rightExpression
		self.operatorSymbol = operatorSymbol
		self.typeName = typeName
		super.init(range: range, name: "BinaryOperatorExpression".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		return [
			PrintableTree.initOrNil(
				"type", [PrintableTree.initOrNil(typeName)]),
			PrintableTree.ofExpressions("left", [leftExpression]),
			PrintableTree("operator \(operatorSymbol)"),
			PrintableTree.ofExpressions("right", [rightExpression]), ]
	}

	override var swiftType: String? { // gryphon annotation: override
		get {
			return typeName
		}
		set {
			if let newValue = newValue {
				typeName = newValue
			}
		}
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
	var typeName: String

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

	override public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		return [
			PrintableTree("type \(typeName)"),
			PrintableTree("operator \(operatorSymbol)"),
			PrintableTree.ofExpressions("expression", [subExpression]), ]
	}

	override var swiftType: String? { // gryphon annotation: override
		get {
			return typeName
		}
		set {
			if let newValue = newValue {
				typeName = newValue
			}
		}
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
	var typeName: String

	init(
		range: SourceFileRange?,
		subExpression: Expression,
		operatorSymbol: String,
		typeName: String)
	{
		self.subExpression = subExpression
		self.operatorSymbol = operatorSymbol
		self.typeName = typeName
		super.init(range: range, name: "PostfixUnaryExpression".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		return [
			PrintableTree("type \(typeName)"),
			PrintableTree("operator \(operatorSymbol)"),
			PrintableTree.ofExpressions("expression", [subExpression]), ]
	}

	override var swiftType: String? { // gryphon annotation: override
		get {
			return typeName
		}
		set {
			if let newValue = newValue {
				typeName = newValue
			}
		}
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

	override public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		return [
			PrintableTree.ofExpressions("condition", [condition]),
			PrintableTree.ofExpressions("trueExpression", [trueExpression]),
			PrintableTree.ofExpressions("falseExpression", [falseExpression]), ]
	}

	override var swiftType: String? { // gryphon annotation: override
		get {
			return trueExpression.swiftType
		}
		set {
			trueExpression.swiftType = newValue
			falseExpression.swiftType = newValue
		}
	}

	public static func == (lhs: IfExpression, rhs: IfExpression) -> Bool {
		return lhs.condition == rhs.condition &&
			lhs.trueExpression == rhs.trueExpression &&
			lhs.falseExpression == rhs.falseExpression
	}
}

public class CallExpression: Expression {
	let function: Expression
	let parameters: Expression
	var typeName: String?

	init(
		range: SourceFileRange?,
		function: Expression,
		parameters: Expression,
		typeName: String?)
	{
		self.function = function
		self.parameters = parameters
		self.typeName = typeName
		super.init(range: range, name: "CallExpression".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		return [
			PrintableTree.initOrNil("type", [PrintableTree.initOrNil(typeName)]),
			PrintableTree.ofExpressions("function", [function]),
			PrintableTree.ofExpressions("parameters", [parameters]), ]
	}

	override var swiftType: String? { // gryphon annotation: override
		get {
			return typeName
		}
		set {
			if let newValue = newValue {
				typeName = newValue
			}
		}
	}

	public static func == (
		lhs: CallExpression,
		rhs: CallExpression)
		-> Bool
	{
		return lhs.function == rhs.function &&
			lhs.parameters == rhs.parameters &&
			lhs.typeName == rhs.typeName
	}
}

public class ClosureExpression: Expression {
	// Closures that use anonymous parameters (e.g. `$0`) may leave this empty
	let parameters: MutableList<LabeledType>
	let statements: MutableList<Statement>
	var typeName: String

	init(
		range: SourceFileRange?,
		parameters: MutableList<LabeledType>,
		statements: MutableList<Statement>,
		typeName: String)
	{
		self.parameters = parameters
		self.statements = statements
		self.typeName = typeName
		super.init(range: range, name: "ClosureExpression".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		let parametersString =
			"(" + parameters.map { $0.label + ":" }.joined(separator: ", ") + ")"
		return [
			PrintableTree(typeName),
			PrintableTree(parametersString),
			PrintableTree.ofStatements("statements", statements), ]
	}

	override var swiftType: String? { // gryphon annotation: override
		get {
			return typeName
		}
		set {
			if let newValue = newValue {
				typeName = newValue
			}
		}
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

	override public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		return [PrintableTree(String(value))]
	}

	override var swiftType: String? { // gryphon annotation: override
		get {
			return "Int"
		}
		set { }
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

	override public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		return [PrintableTree(String(value))]
	}

	override var swiftType: String? { // gryphon annotation: override
		get {
			return "UInt"
		}
		set { }
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

	override public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		return [PrintableTree(String(value))]
	}

	override var swiftType: String? { // gryphon annotation: override
		get {
			return "Double"
		}
		set { }
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

	override public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		return [PrintableTree(String(value))]
	}

	override var swiftType: String? { // gryphon annotation: override
		get {
			return "Float"
		}
		set { }
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

	override public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		return [PrintableTree(String(value))]
	}

	override var swiftType: String? { // gryphon annotation: override
		get {
			return "Bool"
		}
		set { }
	}

	public static func == (lhs: LiteralBoolExpression, rhs: LiteralBoolExpression) -> Bool {
		return lhs.value == rhs.value
	}
}

public class LiteralStringExpression: Expression {
	let value: String
	let isMultiline: Bool

	init(range: SourceFileRange?, value: String, isMultiline: Bool) {
		self.value = value
		self.isMultiline = isMultiline
		super.init(range: range, name: "LiteralStringExpression".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		return [
			PrintableTree(value),
			isMultiline ? PrintableTree("multiline") : nil,
		]
	}

	override var swiftType: String? { // gryphon annotation: override
		get {
			return "String"
		}
		set { }
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

	override public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		return [PrintableTree(String(value))]
	}

	override var swiftType: String? { // gryphon annotation: override
		get {
			return "Character"
		}
		set { }
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

	override public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		return []
	}

	public static func == (lhs: NilLiteralExpression, rhs: NilLiteralExpression) -> Bool {
		return true
	}
}

public class InterpolatedStringLiteralExpression: Expression {
	let expressions: MutableList<Expression>

	init(range: SourceFileRange?, expressions: MutableList<Expression>) {
		self.expressions = expressions
		super.init(
			range: range,
			name: "InterpolatedStringLiteralExpression".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		return [PrintableTree.ofExpressions("expressions", expressions)]
	}

	override var swiftType: String? { // gryphon annotation: override
		get {
			return "String"
		}
		set { }
	}

	public static func == (
		lhs: InterpolatedStringLiteralExpression,
		rhs: InterpolatedStringLiteralExpression)
		-> Bool
	{
		return lhs.expressions == rhs.expressions
	}

	var isMultiline: Bool {
		if let firstString = expressions.compactMap({ $0 as? LiteralStringExpression }).first {
			return firstString.isMultiline
		}
		return false
	}
}

public class TupleExpression: Expression {
	let pairs: MutableList<LabeledExpression>

	init(range: SourceFileRange?, pairs: MutableList<LabeledExpression>) {
		self.pairs = pairs
		super.init(range: range, name: "TupleExpression".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		return pairs.map {
			PrintableTree.ofExpressions(($0.label ?? "_") + ":", [$0.expression])
		}
	}

	override var swiftType: String? { // gryphon annotation: override
		get {
			let types = pairs.map { $0.expression.swiftType ?? "_" }
			return "(\(types.joined(separator: ", ")))"
		}
		set { }
	}

	public static func == (lhs: TupleExpression, rhs: TupleExpression) -> Bool {
		return lhs.pairs == rhs.pairs
	}
}

public class TupleShuffleExpression: Expression {
	let labels: MutableList<String?>
	let indices: MutableList<TupleShuffleIndex>
	let expressions: MutableList<Expression>

	init(
		range: SourceFileRange?,
		labels: MutableList<String?>,
		indices: MutableList<TupleShuffleIndex>,
		expressions: MutableList<Expression>)
	{
		self.labels = labels
		self.indices = indices
		self.expressions = expressions
		super.init(range: range, name: "TupleShuffleExpression".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		let labelStrings = labels.map { ($0 ?? "_") + ":" }
		return [
			PrintableTree.ofStrings("labels", labelStrings),
			PrintableTree.ofStrings("indices", indices.map { $0.description }),
			PrintableTree.ofExpressions("expressions", expressions), ]
	}

	public static func == (lhs: TupleShuffleExpression, rhs: TupleShuffleExpression) -> Bool {
		return lhs.labels == rhs.labels &&
			lhs.indices == rhs.indices &&
			lhs.expressions == rhs.expressions
	}

	override var swiftType: String? { // gryphon annotation: override
		get {
			return self.flattenToTupleExpression().swiftType
		}
		set { }
	}

	/// Check if this TupleShuffleExpression can be flattened into a TupleExpression without losing
	/// information about absent or variadic parameters
	var canBeFlattenedLosslessly: Bool {
		for index in self.indices {
			switch index {
			case .absent:
				return false
			case .present:
				break
			case .variadic:
				return false
			}
		}

		return true
	}

	/// Turns this TupleShuffleExpression into a TupleExpression, ignoring absent parameters and
	/// flattening variadics.
	public func flattenToTupleExpression() -> TupleExpression {
		let resultPairs: MutableList<LabeledExpression> = []

		var expressionIndex = 0

		// Variadic arguments can't be named, which means all arguments before them can't be named
		// either.
		let containsVariadics = self.indices.contains { $0.isVariadic }
		var isBeforeVariadic = containsVariadics

		for (label, index) in zip(self.labels, self.indices) {
			switch index {
			case .absent:
				break
			case .present:
				let expression = self.expressions[expressionIndex]

				let resultLabel: String?
				if !isBeforeVariadic, let label = label {
					resultLabel = label
				}
				else {
					resultLabel = nil
				}

				resultPairs.append(LabeledExpression(label: resultLabel, expression: expression))

				expressionIndex += 1
			case let .variadic(count: variadicCount):
				isBeforeVariadic = false
				for _ in 0..<variadicCount {
					let expression = self.expressions[expressionIndex]
					resultPairs.append(LabeledExpression(label: nil, expression: expression))
					expressionIndex += 1
				}
			}
		}

		return TupleExpression(range: self.range, pairs: resultPairs)
	}
}

public class ErrorExpression: Expression {
	init(range: SourceFileRange?) {
		super.init(range: range, name: "ErrorExpression".capitalizedAsCamelCase())
	}

	override public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
		return []
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
	/// The implementation name of the parameter.
	let label: String
	/// The name of the parameter used when calling the function. If it's `_` in Swift, it's `nil`
	/// here. If it's the same as the implementation name (e.g. `f(a: Int)`), it'll be the same
	/// here.
	let apiLabel: String?
	let typeName: String
	let value: Expression?
}

public class SwitchCase: Equatable {
	var expressions: MutableList<Expression>
	var statements: MutableList<Statement>

	init(
		expressions: MutableList<Expression>,
		statements: MutableList<Statement>)
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
	var associatedValues: MutableList<LabeledType>
	var rawValue: Expression?
	var annotations: String?

	init(
		name: String,
		associatedValues: MutableList<LabeledType>,
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

	public var treeDescription: String { // gryphon annotation: override
		return ".\(self.name)"
	}

	public var printableSubtrees: List<PrintableAsTree?> { // gryphon annotation: override
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

	public var isVariadic: Bool {
		switch self {
		case .variadic:
			return true
		default:
			return false
		}
	}
}
