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

internal fun PrintableTree.Companion.ofStatements(
	description: String,
	subtrees: MutableList<Statement>)
	: PrintableAsTree?
{
	val newSubtrees: MutableList<PrintableAsTree?> = subtrees as MutableList<PrintableAsTree?>
	return PrintableTree.initOrNil(description, newSubtrees)
}

public sealed class Statement: PrintableAsTree {
	class ExpressionStatement(val expression: Expression): Statement()
	class TypealiasDeclaration(val identifier: String, val typeName: String, val isImplicit: Boolean): Statement()
	class ExtensionDeclaration(val typeName: String, val members: MutableList<Statement>): Statement()
	class ImportDeclaration(val moduleName: String): Statement()
	class ClassDeclaration(val className: String, val inherits: MutableList<String>, val members: MutableList<Statement>): Statement()
	class CompanionObject(val members: MutableList<Statement>): Statement()
	class EnumDeclaration(val access: String?, val enumName: String, val inherits: MutableList<String>, val elements: MutableList<EnumElement>, val members: MutableList<Statement>, val isImplicit: Boolean): Statement()
	class ProtocolDeclaration(val protocolName: String, val members: MutableList<Statement>): Statement()
	class StructDeclaration(val annotations: String?, val structName: String, val inherits: MutableList<String>, val members: MutableList<Statement>): Statement()
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

	val name: String
		get() {
			return when (this) {
				is Statement.ExpressionStatement -> "expressionStatement".capitalizedAsCamelCase()
				is Statement.ExtensionDeclaration -> "extensionDeclaration".capitalizedAsCamelCase()
				is Statement.ImportDeclaration -> "importDeclaration".capitalizedAsCamelCase()
				is Statement.TypealiasDeclaration -> "typealiasDeclaration".capitalizedAsCamelCase()
				is Statement.ClassDeclaration -> "classDeclaration".capitalizedAsCamelCase()
				is Statement.CompanionObject -> "companionObject".capitalizedAsCamelCase()
				is Statement.EnumDeclaration -> "enumDeclaration".capitalizedAsCamelCase()
				is Statement.ProtocolDeclaration -> "protocolDeclaration".capitalizedAsCamelCase()
				is Statement.StructDeclaration -> "structDeclaration".capitalizedAsCamelCase()
				is Statement.FunctionDeclaration -> "functionDeclaration".capitalizedAsCamelCase()
				is Statement.VariableDeclaration -> "variableDeclaration".capitalizedAsCamelCase()
				is Statement.ForEachStatement -> "forEachStatement".capitalizedAsCamelCase()
				is Statement.WhileStatement -> "whileStatement".capitalizedAsCamelCase()
				is Statement.IfStatement -> "ifStatement".capitalizedAsCamelCase()
				is Statement.SwitchStatement -> "switchStatement".capitalizedAsCamelCase()
				is Statement.DeferStatement -> "deferStatement".capitalizedAsCamelCase()
				is Statement.ThrowStatement -> "throwStatement".capitalizedAsCamelCase()
				is Statement.ReturnStatement -> "returnStatement".capitalizedAsCamelCase()
				is Statement.BreakStatement -> "breakStatement".capitalizedAsCamelCase()
				is Statement.ContinueStatement -> "continueStatement".capitalizedAsCamelCase()
				is Statement.AssignmentStatement -> "assignmentStatement".capitalizedAsCamelCase()
				is Statement.Error -> "error".capitalizedAsCamelCase()
			}
		}
	override val treeDescription: String
		get() {
			return name
		}
	override val printableSubtrees: MutableList<PrintableAsTree?>
		get() {
			return when (this) {
				is Statement.ExpressionStatement -> {
					val expression: Expression = this.expression
					mutableListOf(expression)
				}
				is Statement.ExtensionDeclaration -> {
					val typeName: String = this.typeName
					val members: MutableList<Statement> = this.members
					mutableListOf(PrintableTree(typeName), PrintableTree.ofStatements("members", members))
				}
				is Statement.ImportDeclaration -> {
					val moduleName: String = this.moduleName
					mutableListOf(PrintableTree(moduleName))
				}
				is Statement.TypealiasDeclaration -> {
					val identifier: String = this.identifier
					val typeName: String = this.typeName
					val isImplicit: Boolean = this.isImplicit

					mutableListOf(if (isImplicit) { PrintableTree(("implicit")) } else { null }, PrintableTree("identifier: ${identifier}"), PrintableTree("typeName: ${typeName}"))
				}
				is Statement.ClassDeclaration -> {
					val className: String = this.className
					val inherits: MutableList<String> = this.inherits
					val members: MutableList<Statement> = this.members

					mutableListOf(PrintableTree(className), PrintableTree.ofStrings("inherits", inherits), PrintableTree.ofStatements("members", members))
				}
				is Statement.CompanionObject -> {
					val members: MutableList<Statement> = this.members
					members as MutableList<PrintableAsTree?>
				}
				is Statement.EnumDeclaration -> {
					val access: String? = this.access
					val enumName: String = this.enumName
					val inherits: MutableList<String> = this.inherits
					val elements: MutableList<EnumElement> = this.elements
					val members: MutableList<Statement> = this.members
					val isImplicit: Boolean = this.isImplicit

					mutableListOf(if (isImplicit) { PrintableTree(("implicit")) } else { null }, PrintableTree.initOrNil(access), PrintableTree(enumName), PrintableTree.ofStrings("inherits", inherits), PrintableTree("elements", elements as MutableList<PrintableAsTree?>), PrintableTree.ofStatements("members", members))
				}
				is Statement.ProtocolDeclaration -> {
					val protocolName: String = this.protocolName
					val members: MutableList<Statement> = this.members
					mutableListOf(PrintableTree(protocolName), PrintableTree.ofStatements("members", members))
				}
				is Statement.StructDeclaration -> {
					val annotations: String? = this.annotations
					val structName: String = this.structName
					val inherits: MutableList<String> = this.inherits
					val members: MutableList<Statement> = this.members

					mutableListOf(PrintableTree.initOrNil("annotations", mutableListOf(PrintableTree.initOrNil(annotations))), PrintableTree(structName), PrintableTree.ofStrings("inherits", inherits), PrintableTree.ofStatements("members", members))
				}
				is Statement.FunctionDeclaration -> {
					val functionDeclaration: FunctionDeclarationData = this.data
					val parametersTrees: MutableList<PrintableAsTree?> = functionDeclaration.parameters.map { parameter -> PrintableTree(
						"parameter",
						mutableListOf(parameter.apiLabel?.let { PrintableTree("api label: ${it}") }, PrintableTree("label: ${parameter.label}"), PrintableTree("type: ${parameter.typeName}"), PrintableTree.initOrNil("value", mutableListOf(parameter.value)))) }.toMutableList()
					mutableListOf(functionDeclaration.extendsType?.let { PrintableTree("extends type ${it}") }, if (functionDeclaration.isImplicit) { PrintableTree(("implicit")) } else { null }, if (functionDeclaration.isStatic) { PrintableTree(("static")) } else { null }, if (functionDeclaration.isMutating) { PrintableTree(("mutating")) } else { null }, PrintableTree.initOrNil(functionDeclaration.access), PrintableTree("type: ${functionDeclaration.functionType}"), PrintableTree("prefix: ${functionDeclaration.prefix}"), PrintableTree("parameters", parametersTrees), PrintableTree("return type: ${functionDeclaration.returnType}"), PrintableTree.ofStatements("statements", functionDeclaration.statements ?: mutableListOf()))
				}
				is Statement.VariableDeclaration -> {
					val variableDeclaration: VariableDeclarationData = this.data
					mutableListOf(PrintableTree.initOrNil(
						"extendsType",
						mutableListOf(PrintableTree.initOrNil(variableDeclaration.extendsType))), if (variableDeclaration.isImplicit) { PrintableTree(("implicit")) } else { null }, if (variableDeclaration.isStatic) { PrintableTree(("static")) } else { null }, if (variableDeclaration.isLet) { PrintableTree(("let")) } else { PrintableTree(("var")) }, PrintableTree(variableDeclaration.identifier), PrintableTree(variableDeclaration.typeName), variableDeclaration.expression, PrintableTree.initOrNil(
						"getter",
						mutableListOf(variableDeclaration.getter?.let { Statement.FunctionDeclaration(data = it) })), PrintableTree.initOrNil(
						"setter",
						mutableListOf(variableDeclaration.setter?.let { Statement.FunctionDeclaration(data = it) })), PrintableTree.initOrNil(
						"annotations",
						mutableListOf(PrintableTree.initOrNil(variableDeclaration.annotations))))
				}
				is Statement.ForEachStatement -> {
					val collection: Expression = this.collection
					val variable: Expression = this.variable
					val statements: MutableList<Statement> = this.statements

					mutableListOf(PrintableTree("variable", mutableListOf(variable)), PrintableTree("collection", mutableListOf(collection)), PrintableTree.ofStatements("statements", statements))
				}
				is Statement.WhileStatement -> {
					val expression: Expression = this.expression
					val statements: MutableList<Statement> = this.statements
					mutableListOf(PrintableTree.ofExpressions("expression", mutableListOf(expression)), PrintableTree.ofStatements("statements", statements))
				}
				is Statement.IfStatement -> {
					val ifStatement: IfStatementData = this.data
					val declarationTrees: MutableList<Statement> = ifStatement.declarations.map { Statement.VariableDeclaration(data = it) }.toMutableList()
					val conditionTrees: MutableList<Statement> = ifStatement.conditions.map { it.toStatement() }.toMutableList()
					val elseStatementTrees: MutableList<PrintableAsTree?> = ifStatement.elseStatement?.let { Statement.IfStatement(data = it) }?.printableSubtrees ?: mutableListOf()

					mutableListOf(if (ifStatement.isGuard) { PrintableTree(("guard")) } else { null }, PrintableTree.ofStatements("declarations", declarationTrees), PrintableTree.ofStatements("conditions", conditionTrees), PrintableTree.ofStatements("statements", ifStatement.statements), PrintableTree.initOrNil("else", elseStatementTrees))
				}
				is Statement.SwitchStatement -> {
					val convertsToExpression: Statement? = this.convertsToExpression
					val expression: Expression = this.expression
					val cases: MutableList<SwitchCase> = this.cases
					val caseItems: MutableList<PrintableAsTree?> = cases.map { switchCase -> PrintableTree(
						"case item",
						mutableListOf(PrintableTree("expression", mutableListOf(switchCase.expression) as MutableList<PrintableAsTree?>), PrintableTree("statements", switchCase.statements as MutableList<PrintableAsTree?>))) }.toMutableList()

					mutableListOf(PrintableTree.ofStatements(
						"converts to expression",
						convertsToExpression?.let { mutableListOf(it) } ?: mutableListOf()), PrintableTree.ofExpressions("expression", mutableListOf(expression)), PrintableTree("case items", caseItems))
				}
				is Statement.DeferStatement -> {
					val statements: MutableList<Statement> = this.statements
					statements as MutableList<PrintableAsTree?>
				}
				is Statement.ThrowStatement -> {
					val expression: Expression = this.expression
					mutableListOf(expression)
				}
				is Statement.ReturnStatement -> {
					val expression: Expression? = this.expression
					mutableListOf(expression)
				}
				is Statement.BreakStatement -> mutableListOf()
				is Statement.ContinueStatement -> mutableListOf()
				is Statement.AssignmentStatement -> {
					val leftHand: Expression = this.leftHand
					val rightHand: Expression = this.rightHand
					mutableListOf(leftHand, rightHand)
				}
				is Statement.Error -> mutableListOf()
			}
		}
}

internal fun PrintableTree.Companion.ofExpressions(
	description: String,
	subtrees: MutableList<Expression>)
	: PrintableAsTree?
{
	val newSubtrees: MutableList<PrintableAsTree?> = subtrees as MutableList<PrintableAsTree?>
	return PrintableTree.initOrNil(description, newSubtrees)
}

public sealed class Expression: PrintableAsTree {
	class LiteralCodeExpression(val string: String): Expression()
	class LiteralDeclarationExpression(val string: String): Expression()
	class TemplateExpression(val pattern: String, val matches: MutableMap<String, Expression>): Expression()
	class ParenthesesExpression(val expression: Expression): Expression()
	class ForceValueExpression(val expression: Expression): Expression()
	class OptionalExpression(val expression: Expression): Expression()
	class DeclarationReferenceExpression(val data: DeclarationReferenceData): Expression()
	class TypeExpression(val typeName: String): Expression()
	class SubscriptExpression(val subscriptedExpression: Expression, val indexExpression: Expression, val typeName: String): Expression()
	class ArrayExpression(val elements: MutableList<Expression>, val typeName: String): Expression()
	class DictionaryExpression(val keys: MutableList<Expression>, val values: MutableList<Expression>, val typeName: String): Expression()
	class ReturnExpression(val expression: Expression?): Expression()
	class DotExpression(val leftExpression: Expression, val rightExpression: Expression): Expression()
	class BinaryOperatorExpression(val leftExpression: Expression, val rightExpression: Expression, val operatorSymbol: String, val typeName: String): Expression()
	class PrefixUnaryExpression(val expression: Expression, val operatorSymbol: String, val typeName: String): Expression()
	class PostfixUnaryExpression(val expression: Expression, val operatorSymbol: String, val typeName: String): Expression()
	class IfExpression(val condition: Expression, val trueExpression: Expression, val falseExpression: Expression): Expression()
	class CallExpression(val data: CallExpressionData): Expression()
	class ClosureExpression(val parameters: MutableList<LabeledType>, val statements: MutableList<Statement>, val typeName: String): Expression()
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

	val name: String
		get() {
			return when (this) {
				is Expression.TemplateExpression -> "templateExpression".capitalizedAsCamelCase()
				is Expression.LiteralCodeExpression -> "literalCodeExpression".capitalizedAsCamelCase()
				is Expression.LiteralDeclarationExpression -> "literalDeclarationExpression".capitalizedAsCamelCase()
				is Expression.ParenthesesExpression -> "parenthesesExpression".capitalizedAsCamelCase()
				is Expression.ForceValueExpression -> "forceValueExpression".capitalizedAsCamelCase()
				is Expression.OptionalExpression -> "optionalExpression".capitalizedAsCamelCase()
				is Expression.DeclarationReferenceExpression -> "declarationReferenceExpression".capitalizedAsCamelCase()
				is Expression.TypeExpression -> "typeExpression".capitalizedAsCamelCase()
				is Expression.SubscriptExpression -> "subscriptExpression".capitalizedAsCamelCase()
				is Expression.ArrayExpression -> "arrayExpression".capitalizedAsCamelCase()
				is Expression.DictionaryExpression -> "dictionaryExpression".capitalizedAsCamelCase()
				is Expression.ReturnExpression -> "returnExpression".capitalizedAsCamelCase()
				is Expression.DotExpression -> "dotExpression".capitalizedAsCamelCase()
				is Expression.BinaryOperatorExpression -> "binaryOperatorExpression".capitalizedAsCamelCase()
				is Expression.PrefixUnaryExpression -> "prefixUnaryExpression".capitalizedAsCamelCase()
				is Expression.PostfixUnaryExpression -> "postfixUnaryExpression".capitalizedAsCamelCase()
				is Expression.IfExpression -> "ifExpression".capitalizedAsCamelCase()
				is Expression.CallExpression -> "callExpression".capitalizedAsCamelCase()
				is Expression.ClosureExpression -> "closureExpression".capitalizedAsCamelCase()
				is Expression.LiteralIntExpression -> "literalIntExpression".capitalizedAsCamelCase()
				is Expression.LiteralUIntExpression -> "literalUIntExpression".capitalizedAsCamelCase()
				is Expression.LiteralDoubleExpression -> "literalDoubleExpression".capitalizedAsCamelCase()
				is Expression.LiteralFloatExpression -> "literalFloatExpression".capitalizedAsCamelCase()
				is Expression.LiteralBoolExpression -> "literalBoolExpression".capitalizedAsCamelCase()
				is Expression.LiteralStringExpression -> "literalStringExpression".capitalizedAsCamelCase()
				is Expression.LiteralCharacterExpression -> "literalCharacterExpression".capitalizedAsCamelCase()
				is Expression.NilLiteralExpression -> "nilLiteralExpression".capitalizedAsCamelCase()
				is Expression.InterpolatedStringLiteralExpression -> "interpolatedStringLiteralExpression".capitalizedAsCamelCase()
				is Expression.TupleExpression -> "tupleExpression".capitalizedAsCamelCase()
				is Expression.TupleShuffleExpression -> "tupleShuffleExpression".capitalizedAsCamelCase()
				is Expression.Error -> "error".capitalizedAsCamelCase()
			}
		}
	override val treeDescription: String
		get() {
			return name
		}
	override val printableSubtrees: MutableList<PrintableAsTree?>
		get() {
			return when (this) {
				is Expression.TemplateExpression -> {
					val pattern: String = this.pattern
					val matches: MutableMap<String, Expression> = this.matches
					val matchesTrees: MutableList<PrintableAsTree?> = matches.map { PrintableTree(it.key, mutableListOf(it.value)) }.toMutableList() as MutableList<PrintableAsTree?>

					mutableListOf(PrintableTree("pattern \"${pattern}\""), PrintableTree("matches", matchesTrees))
				}
				is Expression.LiteralCodeExpression -> mutableListOf(PrintableTree(string))
				is Expression.LiteralDeclarationExpression -> mutableListOf(PrintableTree(string))
				is Expression.ParenthesesExpression -> {
					val expression: Expression = this.expression
					mutableListOf(expression)
				}
				is Expression.ForceValueExpression -> {
					val expression: Expression = this.expression
					mutableListOf(expression)
				}
				is Expression.OptionalExpression -> {
					val expression: Expression = this.expression
					mutableListOf(expression)
				}
				is Expression.DeclarationReferenceExpression -> {
					val expression: DeclarationReferenceData = this.data
					mutableListOf(PrintableTree(expression.typeName), PrintableTree(expression.identifier), if (expression.isStandardLibrary) { PrintableTree(("isStandardLibrary")) } else { null }, if (expression.isImplicit) { PrintableTree(("implicit")) } else { null })
				}
				is Expression.TypeExpression -> {
					val typeName: String = this.typeName
					mutableListOf(PrintableTree(typeName))
				}
				is Expression.SubscriptExpression -> {
					val subscriptedExpression: Expression = this.subscriptedExpression
					val indexExpression: Expression = this.indexExpression
					val typeName: String = this.typeName

					mutableListOf(PrintableTree("type ${typeName}"), PrintableTree.ofExpressions("subscriptedExpression", mutableListOf(subscriptedExpression)), PrintableTree.ofExpressions("indexExpression", mutableListOf(indexExpression)))
				}
				is Expression.ArrayExpression -> {
					val elements: MutableList<Expression> = this.elements
					val typeName: String = this.typeName
					mutableListOf(PrintableTree("type ${typeName}"), PrintableTree.ofExpressions("elements", elements))
				}
				is Expression.DictionaryExpression -> {
					val keys: MutableList<Expression> = this.keys
					val values: MutableList<Expression> = this.values
					val typeName: String = this.typeName
					val keyValueStrings: MutableList<String> = keys.zip(values).map { pair -> "${pair.first}: ${pair.second}" }.toMutableList()

					mutableListOf(PrintableTree("type ${typeName}"), PrintableTree.ofStrings("key value pairs", keyValueStrings))
				}
				is Expression.ReturnExpression -> {
					val expression: Expression? = this.expression
					mutableListOf(expression)
				}
				is Expression.DotExpression -> {
					val leftExpression: Expression = this.leftExpression
					val rightExpression: Expression = this.rightExpression
					mutableListOf(PrintableTree.ofExpressions("left", mutableListOf(leftExpression)), PrintableTree.ofExpressions("right", mutableListOf(rightExpression)))
				}
				is Expression.BinaryOperatorExpression -> {
					val leftExpression: Expression = this.leftExpression
					val rightExpression: Expression = this.rightExpression
					val operatorSymbol: String = this.operatorSymbol
					val typeName: String = this.typeName

					mutableListOf(PrintableTree("type ${typeName}"), PrintableTree.ofExpressions("left", mutableListOf(leftExpression)), PrintableTree("operator ${operatorSymbol}"), PrintableTree.ofExpressions("right", mutableListOf(rightExpression)))
				}
				is Expression.PrefixUnaryExpression -> {
					val expression: Expression = this.expression
					val operatorSymbol: String = this.operatorSymbol
					val typeName: String = this.typeName

					mutableListOf(PrintableTree("type ${typeName}"), PrintableTree("operator ${operatorSymbol}"), PrintableTree.ofExpressions("expression", mutableListOf(expression)))
				}
				is Expression.IfExpression -> {
					val condition: Expression = this.condition
					val trueExpression: Expression = this.trueExpression
					val falseExpression: Expression = this.falseExpression

					mutableListOf(PrintableTree.ofExpressions("condition", mutableListOf(condition)), PrintableTree.ofExpressions("trueExpression", mutableListOf(trueExpression)), PrintableTree.ofExpressions("falseExpression", mutableListOf(falseExpression)))
				}
				is Expression.PostfixUnaryExpression -> {
					val expression: Expression = this.expression
					val operatorSymbol: String = this.operatorSymbol
					val typeName: String = this.typeName

					mutableListOf(PrintableTree("type ${typeName}"), PrintableTree("operator ${operatorSymbol}"), PrintableTree.ofExpressions("expression", mutableListOf(expression)))
				}
				is Expression.CallExpression -> {
					val callExpression: CallExpressionData = this.data
					mutableListOf(PrintableTree("type ${callExpression.typeName}"), PrintableTree.ofExpressions("function", mutableListOf(callExpression.function)), PrintableTree.ofExpressions("parameters", mutableListOf(callExpression.parameters)))
				}
				is Expression.ClosureExpression -> {
					val parameters: MutableList<LabeledType> = this.parameters
					val statements: MutableList<Statement> = this.statements
					val typeName: String = this.typeName
					val parametersString: String = "(" + parameters.map { it.label + ":" }.toMutableList().joinToString(separator = ", ") + ")"

					mutableListOf(PrintableTree(typeName), PrintableTree(parametersString), PrintableTree.ofStatements("statements", statements))
				}
				is Expression.TupleExpression -> {
					val pairs: MutableList<LabeledExpression> = this.pairs
					pairs.map { PrintableTree.ofExpressions((it.label ?: "_") + ":", mutableListOf(it.expression)) }.toMutableList()
				}
				is Expression.TupleShuffleExpression -> {
					val labels: MutableList<String> = this.labels
					val indices: MutableList<TupleShuffleIndex> = this.indices
					val expressions: MutableList<Expression> = this.expressions

					mutableListOf(PrintableTree.ofStrings("labels", labels), PrintableTree.ofStrings("indices", indices.map { it.toString() }.toMutableList()), PrintableTree.ofExpressions("expressions", expressions))
				}
				is Expression.LiteralIntExpression -> {
					val value: Long = this.value
					mutableListOf(PrintableTree(value.toString()))
				}
				is Expression.LiteralUIntExpression -> {
					val value: ULong = this.value
					mutableListOf(PrintableTree(value.toString()))
				}
				is Expression.LiteralDoubleExpression -> {
					val value: Double = this.value
					mutableListOf(PrintableTree(value.toString()))
				}
				is Expression.LiteralFloatExpression -> {
					val value: Float = this.value
					mutableListOf(PrintableTree(value.toString()))
				}
				is Expression.LiteralBoolExpression -> {
					val value: Boolean = this.value
					mutableListOf(PrintableTree(value.toString()))
				}
				is Expression.LiteralStringExpression -> {
					val value: String = this.value
					mutableListOf(PrintableTree("\"${value}\""))
				}
				is Expression.LiteralCharacterExpression -> {
					val value: String = this.value
					mutableListOf(PrintableTree("'${value}'"))
				}
				is Expression.NilLiteralExpression -> mutableListOf()
				is Expression.InterpolatedStringLiteralExpression -> {
					val expressions: MutableList<Expression> = this.expressions
					mutableListOf(PrintableTree.ofExpressions("expressions", expressions))
				}
				is Expression.Error -> mutableListOf()
			}
		}
	val swiftType: String?
		get() {
			when (this) {
				is Expression.TemplateExpression -> return null
				is Expression.LiteralCodeExpression -> return null
				is Expression.LiteralDeclarationExpression -> return null
				is Expression.ParenthesesExpression -> {
					val expression: Expression = this.expression
					return expression.swiftType
				}
				is Expression.ForceValueExpression -> {
					val expression: Expression = this.expression
					val subtype: String? = expression.swiftType
					if (subtype != null && subtype.endsWith("?")) {
						return subtype.dropLast(1)
					}
					else {
						return expression.swiftType
					}
				}
				is Expression.OptionalExpression -> {
					val expression: Expression = this.expression
					val typeName: String? = expression.swiftType
					if (typeName != null) {
						return typeName.dropLast(1)
					}
					else {
						return null
					}
				}
				is Expression.DeclarationReferenceExpression -> {
					val declarationReferenceExpression: DeclarationReferenceData = this.data
					return declarationReferenceExpression.typeName
				}
				is Expression.TypeExpression -> {
					val typeName: String = this.typeName
					return typeName
				}
				is Expression.SubscriptExpression -> {
					val typeName: String = this.typeName
					return typeName
				}
				is Expression.ArrayExpression -> {
					val typeName: String = this.typeName
					return typeName
				}
				is Expression.DictionaryExpression -> {
					val typeName: String = this.typeName
					return typeName
				}
				is Expression.ReturnExpression -> {
					val expression: Expression? = this.expression
					return expression?.swiftType
				}
				is Expression.DotExpression -> {
					val leftExpression: Expression = this.leftExpression
					val rightExpression: Expression = this.rightExpression

					if (leftExpression is Expression.TypeExpression && rightExpression is Expression.DeclarationReferenceExpression) {
						val enumType: String = leftExpression.typeName
						val declarationReferenceExpression: DeclarationReferenceData = rightExpression.data
						if (declarationReferenceExpression.typeName.startsWith("(") && declarationReferenceExpression.typeName.contains("${enumType}.Type) -> ") && declarationReferenceExpression.typeName.endsWith(enumType)) {
							return enumType
						}
					}

					return rightExpression.swiftType
				}
				is Expression.BinaryOperatorExpression -> {
					val typeName: String = this.typeName
					return typeName
				}
				is Expression.PrefixUnaryExpression -> {
					val typeName: String = this.typeName
					return typeName
				}
				is Expression.PostfixUnaryExpression -> {
					val typeName: String = this.typeName
					return typeName
				}
				is Expression.IfExpression -> {
					val trueExpression: Expression = this.trueExpression
					return trueExpression.swiftType
				}
				is Expression.CallExpression -> {
					val callExpression: CallExpressionData = this.data
					return callExpression.typeName
				}
				is Expression.ClosureExpression -> {
					val typeName: String = this.typeName
					return typeName
				}
				is Expression.LiteralIntExpression -> return "Int"
				is Expression.LiteralUIntExpression -> return "UInt"
				is Expression.LiteralDoubleExpression -> return "Double"
				is Expression.LiteralFloatExpression -> return "Float"
				is Expression.LiteralBoolExpression -> return "Bool"
				is Expression.LiteralStringExpression -> return "String"
				is Expression.LiteralCharacterExpression -> return "Character"
				is Expression.NilLiteralExpression -> return null
				is Expression.InterpolatedStringLiteralExpression -> return "String"
				is Expression.TupleExpression -> return null
				is Expression.TupleShuffleExpression -> return null
				is Expression.Error -> return "<<Error>>"
			}
		}
	val range: SourceFileRange?
		get() {
			return when (this) {
				is Expression.DeclarationReferenceExpression -> {
					val declarationReferenceExpression: DeclarationReferenceData = this.data
					declarationReferenceExpression.range
				}
				is Expression.CallExpression -> {
					val callExpression: CallExpressionData = this.data
					callExpression.range
				}
				else -> null
			}
		}
}

data class LabeledExpression(
	val label: String?,
	val expression: Expression
)

data class LabeledType(
	val label: String,
	val typeName: String
)

data class FunctionParameter(
	val label: String,
	val apiLabel: String?,
	val typeName: String,
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
	var typeName: String
	var isStandardLibrary: Boolean
	var isImplicit: Boolean
	var range: SourceFileRange? = null

	constructor(
		identifier: String,
		typeName: String,
		isStandardLibrary: Boolean,
		isImplicit: Boolean,
		range: SourceFileRange?)
	{
		this.identifier = identifier
		this.typeName = typeName
		this.isStandardLibrary = isStandardLibrary
		this.isImplicit = isImplicit
		this.range = range
	}
}

class CallExpressionData {
	var function: Expression
	var parameters: Expression
	var typeName: String
	var range: SourceFileRange? = null

	constructor(
		function: Expression,
		parameters: Expression,
		typeName: String,
		range: SourceFileRange?)
	{
		this.function = function
		this.parameters = parameters
		this.typeName = typeName
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
	var isPure: Boolean
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
		isPure: Boolean,
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
		this.isPure = isPure
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

		internal fun toStatement(): Statement {
			return when (this) {
				is IfCondition.Condition -> {
					val expression: Expression = this.expression
					Statement.ExpressionStatement(expression = expression)
				}
				is IfCondition.Declaration -> {
					val variableDeclaration: VariableDeclarationData = this.variableDeclaration
					Statement.VariableDeclaration(data = variableDeclaration)
				}
			}
		}
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

class EnumElement: PrintableAsTree {
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

	override val treeDescription: String
		get() {
			return ".${this.name}"
		}
	override val printableSubtrees: MutableList<PrintableAsTree?>
		get() {
			val associatedValues: String = this.associatedValues.map { "${it.label}: ${it.typeName}" }.toMutableList().joinToString(separator = ", ")
			val associatedValuesString: String? = if (associatedValues.isEmpty()) { null } else { "values: ${associatedValues}" }
			return mutableListOf(PrintableTree.initOrNil(associatedValuesString), PrintableTree.initOrNil(this.annotations))
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
