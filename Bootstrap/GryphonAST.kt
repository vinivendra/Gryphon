class GryphonAST: PrintableAsTree {
	val sourceFile: SourceFile?
	val declarations: MutableList<Statement>
	val statements: MutableList<Statement>

	constructor(
		sourceFile: SourceFile?,
		declarations: MutableList<Statement>,
		statements: MutableList<Statement>)
	{
		this.sourceFile = sourceFile
		this.declarations = declarations
		this.statements = statements
	}

	override val treeDescription: String
		get() {
			return "Source File"
		}
	override val printableSubtrees: MutableList<PrintableAsTree?>
		get() {
			return mutableListOf(PrintableTree("Declarations", declarations as MutableList<PrintableAsTree?>), PrintableTree("Statements", statements as MutableList<PrintableAsTree?>))
		}

	override fun toString(): String {
		return prettyDescription()
	}
}

public sealed class Statement {
	class Expression(val expression: Expression): Statement()
	class TypealiasDeclaration(val identifier: String, val type: String, val isImplicit: Boolean): Statement()
	class ExtensionDeclaration(val type: String, val members: MutableList<Statement>): Statement()
	class ImportDeclaration(val name: String): Statement()
	class ClassDeclaration(val name: String, val inherits: MutableList<String>, val members: MutableList<Statement>): Statement()
	class CompanionObject(val members: MutableList<Statement>): Statement()
	class EnumDeclaration(val access: String?, val name: String, val inherits: MutableList<String>, val elements: MutableList<EnumElement>, val members: MutableList<Statement>, val isImplicit: Boolean): Statement()
	class ProtocolDeclaration(val name: String, val members: MutableList<Statement>): Statement()
	class StructDeclaration(val annotations: String?, val name: String, val inherits: MutableList<String>, val members: MutableList<Statement>): Statement()
	class FunctionDeclaration(val data: FunctionDeclarationData): Statement()
	class VariableDeclaration(val data: VariableDeclarationData): Statement()
	class ForEachStatement(val collection: Expression, val variable: Expression, val statements: MutableList<Statement>): Statement()
	class WhileStatement(val expression: Expression, val statements: MutableList<Statement>): Statement()
	class IfStatement(val data: IfStatementData): Statement()
	class SwitchStatement(val convertsToExpression: Statement?, val expression: Expression, val cases: MutableList<SwitchCase>): Statement()
	class DeferStatement(val statements: MutableList<Statement>): Statement()
	class ThrowStatement(val expression: Expression): Statement()
	class ReturnStatement(val expression: Expression?): Statement()
	class BreakStatement: Statement()
	class ContinueStatement: Statement()
	class AssignmentStatement(val leftHand: Expression, val rightHand: Expression): Statement()
	class Error: Statement()
}

public sealed class Expression {
	class LiteralCodeExpression(val string: String): Expression()
	class LiteralDeclarationExpression(val string: String): Expression()
	class TemplateExpression(val pattern: String, val matches: MutableMap<String, Expression>): Expression()
	class ParenthesesExpression(val expression: Expression): Expression()
	class ForceValueExpression(val expression: Expression): Expression()
	class OptionalExpression(val expression: Expression): Expression()
	class DeclarationReferenceExpression(val data: DeclarationReferenceData): Expression()
	class TypeExpression(val type: String): Expression()
	class SubscriptExpression(val subscriptedExpression: Expression, val indexExpression: Expression, val type: String): Expression()
	class ArrayExpression(val elements: MutableList<Expression>, val type: String): Expression()
	class DictionaryExpression(val keys: MutableList<Expression>, val values: MutableList<Expression>, val type: String): Expression()
	class ReturnExpression(val expression: Expression?): Expression()
	class DotExpression(val leftExpression: Expression, val rightExpression: Expression): Expression()
	class BinaryOperatorExpression(val leftExpression: Expression, val rightExpression: Expression, val operatorSymbol: String, val type: String): Expression()
	class PrefixUnaryExpression(val expression: Expression, val operatorSymbol: String, val type: String): Expression()
	class PostfixUnaryExpression(val expression: Expression, val operatorSymbol: String, val type: String): Expression()
	class IfExpression(val condition: Expression, val trueExpression: Expression, val falseExpression: Expression): Expression()
	class CallExpression(val data: CallExpressionData): Expression()
	class ClosureExpression(val parameters: MutableList<LabeledType>, val statements: MutableList<Statement>, val type: String): Expression()
	class LiteralIntExpression(val value: Long): Expression()
	class LiteralUIntExpression(val value: ULong): Expression()
	class LiteralDoubleExpression(val value: Double): Expression()
	class LiteralFloatExpression(val value: Float): Expression()
	class LiteralBoolExpression(val value: Boolean): Expression()
	class LiteralStringExpression(val value: String): Expression()
	class LiteralCharacterExpression(val value: String): Expression()
	class NilLiteralExpression: Expression()
	class InterpolatedStringLiteralExpression(val expressions: MutableList<Expression>): Expression()
	class TupleExpression(val pairs: MutableList<LabeledExpression>): Expression()
	class TupleShuffleExpression(val labels: MutableList<String>, val indices: MutableList<TupleShuffleIndex>, val expressions: MutableList<Expression>): Expression()
	class Error: Expression()
}

data class LabeledExpression(
	val label: String?,
	val expression: Expression
)

data class LabeledType(
	val label: String,
	val type: String
)

data class FunctionParameter(
	val label: String,
	val apiLabel: String?,
	val type: String,
	val value: Expression?
)

class VariableDeclarationData {
	var identifier: String
	var typeName: String
	var expression: Expression? = null
	var getter: FunctionDeclarationData? = null
	var setter: FunctionDeclarationData? = null
	var isLet: Boolean
	var isImplicit: Boolean
	var isStatic: Boolean
	var extendsType: String? = null
	var annotations: String? = null

	constructor(
		identifier: String,
		typeName: String,
		expression: Expression?,
		getter: FunctionDeclarationData?,
		setter: FunctionDeclarationData?,
		isLet: Boolean,
		isImplicit: Boolean,
		isStatic: Boolean,
		extendsType: String?,
		annotations: String?)
	{
		this.identifier = identifier
		this.typeName = typeName
		this.expression = expression
		this.getter = getter
		this.setter = setter
		this.isLet = isLet
		this.isImplicit = isImplicit
		this.isStatic = isStatic
		this.extendsType = extendsType
		this.annotations = annotations
	}
}

class DeclarationReferenceData {
	var identifier: String
	var type: String
	var isStandardLibrary: Boolean
	var isImplicit: Boolean
	var range: SourceFileRange? = null

	constructor(
		identifier: String,
		type: String,
		isStandardLibrary: Boolean,
		isImplicit: Boolean,
		range: SourceFileRange?)
	{
		this.identifier = identifier
		this.type = type
		this.isStandardLibrary = isStandardLibrary
		this.isImplicit = isImplicit
		this.range = range
	}
}

class CallExpressionData {
	var function: Expression
	var parameters: Expression
	var type: String
	var range: SourceFileRange? = null

	constructor(
		function: Expression,
		parameters: Expression,
		type: String,
		range: SourceFileRange?)
	{
		this.function = function
		this.parameters = parameters
		this.type = type
		this.range = range
	}
}

class FunctionDeclarationData {
	var prefix: String
	var parameters: MutableList<FunctionParameter>
	var returnType: String
	var functionType: String
	var genericTypes: MutableList<String>
	var isImplicit: Boolean
	var isStatic: Boolean
	var isMutating: Boolean
	var extendsType: String? = null
	var statements: MutableList<Statement>? = null
	var access: String? = null
	var annotations: String? = null

	constructor(
		prefix: String,
		parameters: MutableList<FunctionParameter>,
		returnType: String,
		functionType: String,
		genericTypes: MutableList<String>,
		isImplicit: Boolean,
		isStatic: Boolean,
		isMutating: Boolean,
		extendsType: String?,
		statements: MutableList<Statement>?,
		access: String?,
		annotations: String?)
	{
		this.prefix = prefix
		this.parameters = parameters
		this.returnType = returnType
		this.functionType = functionType
		this.genericTypes = genericTypes
		this.isImplicit = isImplicit
		this.isStatic = isStatic
		this.isMutating = isMutating
		this.extendsType = extendsType
		this.statements = statements
		this.access = access
		this.annotations = annotations
	}
}

class IfStatementData {
	var conditions: MutableList<IfStatementData.IfCondition>
	var declarations: MutableList<VariableDeclarationData>
	var statements: MutableList<Statement>
	var elseStatement: IfStatementData? = null
	var isGuard: Boolean

	public sealed class IfCondition {
		class Condition(val expression: Expression): IfCondition()
		class Declaration(val variableDeclaration: VariableDeclarationData): IfCondition()
	}

	constructor(
		conditions: MutableList<IfStatementData.IfCondition>,
		declarations: MutableList<VariableDeclarationData>,
		statements: MutableList<Statement>,
		elseStatement: IfStatementData?,
		isGuard: Boolean)
	{
		this.conditions = conditions
		this.declarations = declarations
		this.statements = statements
		this.elseStatement = elseStatement
		this.isGuard = isGuard
	}
}

class SwitchCase {
	var expression: Expression? = null
	var statements: MutableList<Statement>

	constructor(expression: Expression?, statements: MutableList<Statement>) {
		this.expression = expression
		this.statements = statements
	}
}

class EnumElement {
	var name: String
	var associatedValues: MutableList<LabeledType>
	var rawValue: Expression? = null
	var annotations: String? = null

	constructor(
		name: String,
		associatedValues: MutableList<LabeledType>,
		rawValue: Expression?,
		annotations: String?)
	{
		this.name = name
		this.associatedValues = associatedValues
		this.rawValue = rawValue
		this.annotations = annotations
	}
}

public sealed class TupleShuffleIndex {
	class Variadic(val count: Int): TupleShuffleIndex()
	class Absent: TupleShuffleIndex()
	class Present: TupleShuffleIndex()

	override fun toString(): String {
		return when (this) {
			is TupleShuffleIndex.Variadic -> {
				val count: Int = this.count
				"variadics: ${count}"
			}
			is TupleShuffleIndex.Absent -> "absent"
			is TupleShuffleIndex.Present -> "present"
		}
	}
}
