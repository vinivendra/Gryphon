open class GryphonAST: PrintableAsTree {
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

    override open fun equals(other: Any?): Boolean {
        val lhs: GryphonAST = this
        val rhs: Any? = other
        if (rhs is GryphonAST) {
            return lhs.declarations == rhs.declarations && lhs.statements == rhs.statements
        }
        else {
            return false
        }
    }

    override val treeDescription: String
        get() {
            return "Source File"
        }
    override val printableSubtrees: MutableList<PrintableAsTree?>
        get() {
            return mutableListOf(PrintableTree("Declarations", declarations.toMutableList<PrintableAsTree?>()), PrintableTree("Statements", statements.toMutableList<PrintableAsTree?>()))
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
    val newSubtrees: MutableList<PrintableAsTree?> = subtrees.toMutableList<PrintableAsTree?>()
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
    class DoStatement(val statements: MutableList<Statement>): Statement()
    class CatchStatement(val variableDeclaration: VariableDeclarationData?, val statements: MutableList<Statement>): Statement()
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
                is Statement.DoStatement -> "doStatement".capitalizedAsCamelCase()
                is Statement.CatchStatement -> "catchStatement".capitalizedAsCamelCase()
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
                    members.toMutableList<PrintableAsTree?>()
                }
                is Statement.EnumDeclaration -> {
                    val access: String? = this.access
                    val enumName: String = this.enumName
                    val inherits: MutableList<String> = this.inherits
                    val elements: MutableList<EnumElement> = this.elements
                    val members: MutableList<Statement> = this.members
                    val isImplicit: Boolean = this.isImplicit

                    mutableListOf(if (isImplicit) { PrintableTree(("implicit")) } else { null }, PrintableTree.initOrNil(access), PrintableTree(enumName), PrintableTree.ofStrings("inherits", inherits), PrintableTree("elements", elements.toMutableList<PrintableAsTree?>()), PrintableTree.ofStatements("members", members))
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
                is Statement.DoStatement -> {
                    val statements: MutableList<Statement> = this.statements
                    statements.toMutableList<PrintableAsTree?>()
                }
                is Statement.CatchStatement -> {
                    val variableDeclaration: VariableDeclarationData? = this.variableDeclaration
                    val statements: MutableList<Statement> = this.statements
                    mutableListOf(PrintableTree(
                        "variableDeclaration",
                        mutableListOf(variableDeclaration?.let { Statement.VariableDeclaration(data = it) }).toMutableList<PrintableAsTree?>()), PrintableTree.ofStatements("statements", statements))
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
                        mutableListOf(PrintableTree.ofExpressions("expressions", switchCase.expressions), PrintableTree.ofStatements("statements", switchCase.statements))) }.toMutableList()

                    mutableListOf(PrintableTree.ofStatements(
                        "converts to expression",
                        convertsToExpression?.let { mutableListOf(it) } ?: mutableListOf()), PrintableTree.ofExpressions("expression", mutableListOf(expression)), PrintableTree("case items", caseItems))
                }
                is Statement.DeferStatement -> {
                    val statements: MutableList<Statement> = this.statements
                    statements.toMutableList<PrintableAsTree?>()
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

    override open fun equals(other: Any?): Boolean {
        val lhs: Statement = this
        val rhs: Any? = other
        if (rhs is Statement) {
            if (lhs is Statement.ExpressionStatement && rhs is Statement.ExpressionStatement) {
                val leftExpression: Expression = lhs.expression
                val rightExpression: Expression = rhs.expression
                return leftExpression == rightExpression
            }

            if (lhs is Statement.TypealiasDeclaration && rhs is Statement.TypealiasDeclaration) {
                val leftIdentifier: String = lhs.identifier
                val leftTypeName: String = lhs.typeName
                val leftIsImplicit: Boolean = lhs.isImplicit
                val rightIdentifier: String = rhs.identifier
                val rightTypeName: String = rhs.typeName
                val rightIsImplicit: Boolean = rhs.isImplicit

                return leftIdentifier == rightIdentifier && leftTypeName == rightTypeName && leftIsImplicit == rightIsImplicit
            }

            if (lhs is Statement.ExtensionDeclaration && rhs is Statement.ExtensionDeclaration) {
                val leftTypeName: String = lhs.typeName
                val leftMembers: MutableList<Statement> = lhs.members
                val rightTypeName: String = rhs.typeName
                val rightMembers: MutableList<Statement> = rhs.members

                return leftTypeName == rightTypeName && leftMembers == rightMembers
            }

            if (lhs is Statement.ImportDeclaration && rhs is Statement.ImportDeclaration) {
                val leftModuleName: String = lhs.moduleName
                val rightModuleName: String = rhs.moduleName
                return leftModuleName == rightModuleName
            }

            if (lhs is Statement.ClassDeclaration && rhs is Statement.ClassDeclaration) {
                val leftClassName: String = lhs.className
                val leftInherits: MutableList<String> = lhs.inherits
                val leftMembers: MutableList<Statement> = lhs.members
                val rightClassName: String = rhs.className
                val rightInherits: MutableList<String> = rhs.inherits
                val rightMembers: MutableList<Statement> = rhs.members

                return leftClassName == rightClassName && leftInherits == rightInherits && leftMembers == rightMembers
            }

            if (lhs is Statement.CompanionObject && rhs is Statement.CompanionObject) {
                val leftMembers: MutableList<Statement> = lhs.members
                val rightMembers: MutableList<Statement> = rhs.members
                return leftMembers == rightMembers
            }

            if (lhs is Statement.EnumDeclaration && rhs is Statement.EnumDeclaration) {
                val leftAccess: String? = lhs.access
                val leftEnumName: String = lhs.enumName
                val leftInherits: MutableList<String> = lhs.inherits
                val leftElements: MutableList<EnumElement> = lhs.elements
                val leftMembers: MutableList<Statement> = lhs.members
                val leftIsImplicit: Boolean = lhs.isImplicit
                val rightAccess: String? = rhs.access
                val rightEnumName: String = rhs.enumName
                val rightInherits: MutableList<String> = rhs.inherits
                val rightElements: MutableList<EnumElement> = rhs.elements
                val rightMembers: MutableList<Statement> = rhs.members
                val rightIsImplicit: Boolean = rhs.isImplicit

                return leftAccess == rightAccess && leftEnumName == rightEnumName && leftInherits == rightInherits && leftElements == rightElements && leftMembers == rightMembers && leftIsImplicit == rightIsImplicit
            }

            if (lhs is Statement.ProtocolDeclaration && rhs is Statement.ProtocolDeclaration) {
                val leftProtocolName: String = lhs.protocolName
                val leftMembers: MutableList<Statement> = lhs.members
                val rightProtocolName: String = rhs.protocolName
                val rightMembers: MutableList<Statement> = rhs.members

                return leftProtocolName == rightProtocolName && leftMembers == rightMembers
            }

            if (lhs is Statement.StructDeclaration && rhs is Statement.StructDeclaration) {
                val leftAnnotations: String? = lhs.annotations
                val leftStructName: String = lhs.structName
                val leftInherits: MutableList<String> = lhs.inherits
                val leftMembers: MutableList<Statement> = lhs.members
                val rightAnnotations: String? = rhs.annotations
                val rightStructName: String = rhs.structName
                val rightInherits: MutableList<String> = rhs.inherits
                val rightMembers: MutableList<Statement> = rhs.members

                return leftAnnotations == rightAnnotations && leftStructName == rightStructName && leftInherits == rightInherits && leftMembers == rightMembers
            }

            if (lhs is Statement.FunctionDeclaration && rhs is Statement.FunctionDeclaration) {
                val leftData: FunctionDeclarationData = lhs.data
                val rightData: FunctionDeclarationData = rhs.data
                return leftData == rightData
            }

            if (lhs is Statement.VariableDeclaration && rhs is Statement.VariableDeclaration) {
                val leftData: VariableDeclarationData = lhs.data
                val rightData: VariableDeclarationData = rhs.data
                return leftData == rightData
            }

            if (lhs is Statement.DoStatement && rhs is Statement.DoStatement) {
                val leftStatements: MutableList<Statement> = lhs.statements
                val rightStatements: MutableList<Statement> = rhs.statements
                return leftStatements == rightStatements
            }

            if (lhs is Statement.CatchStatement && rhs is Statement.CatchStatement) {
                val leftVariableDeclaration: VariableDeclarationData? = lhs.variableDeclaration
                val leftStatements: MutableList<Statement> = lhs.statements
                val rightVariableDeclaration: VariableDeclarationData? = rhs.variableDeclaration
                val rightStatements: MutableList<Statement> = rhs.statements

                return leftVariableDeclaration == rightVariableDeclaration && leftStatements == rightStatements
            }

            if (lhs is Statement.ForEachStatement && rhs is Statement.ForEachStatement) {
                val leftCollection: Expression = lhs.collection
                val leftVariable: Expression = lhs.variable
                val leftStatements: MutableList<Statement> = lhs.statements
                val rightCollection: Expression = rhs.collection
                val rightVariable: Expression = rhs.variable
                val rightStatements: MutableList<Statement> = rhs.statements

                return leftCollection == rightCollection && leftVariable == rightVariable && leftStatements == rightStatements
            }

            if (lhs is Statement.WhileStatement && rhs is Statement.WhileStatement) {
                val leftExpression: Expression = lhs.expression
                val leftStatements: MutableList<Statement> = lhs.statements
                val rightExpression: Expression = rhs.expression
                val rightStatements: MutableList<Statement> = rhs.statements

                return leftExpression == rightExpression && leftStatements == rightStatements
            }

            if (lhs is Statement.IfStatement && rhs is Statement.IfStatement) {
                val leftData: IfStatementData = lhs.data
                val rightData: IfStatementData = rhs.data
                return leftData == rightData
            }

            if (lhs is Statement.SwitchStatement && rhs is Statement.SwitchStatement) {
                val leftConvertsToExpression: Statement? = lhs.convertsToExpression
                val leftExpression: Expression = lhs.expression
                val leftCases: MutableList<SwitchCase> = lhs.cases
                val rightConvertsToExpression: Statement? = rhs.convertsToExpression
                val rightExpression: Expression = rhs.expression
                val rightCases: MutableList<SwitchCase> = rhs.cases

                return leftConvertsToExpression == rightConvertsToExpression && leftExpression == rightExpression && leftCases == rightCases
            }

            if (lhs is Statement.DeferStatement && rhs is Statement.DeferStatement) {
                val leftStatements: MutableList<Statement> = lhs.statements
                val rightStatements: MutableList<Statement> = rhs.statements
                return leftStatements == rightStatements
            }

            if (lhs is Statement.ThrowStatement && rhs is Statement.ThrowStatement) {
                val leftExpression: Expression = lhs.expression
                val rightExpression: Expression = rhs.expression
                return leftExpression == rightExpression
            }

            if (lhs is Statement.ReturnStatement && rhs is Statement.ReturnStatement) {
                val leftExpression: Expression? = lhs.expression
                val rightExpression: Expression? = rhs.expression
                return leftExpression == rightExpression
            }

            if (lhs is Statement.BreakStatement && rhs is Statement.BreakStatement) {
                return true
            }

            if (lhs is Statement.ContinueStatement && rhs is Statement.ContinueStatement) {
                return true
            }

            if (lhs is Statement.AssignmentStatement && rhs is Statement.AssignmentStatement) {
                val leftLeftHand: Expression = lhs.leftHand
                val leftRightHand: Expression = lhs.rightHand
                val rightLeftHand: Expression = rhs.leftHand
                val rightRightHand: Expression = rhs.rightHand

                return leftLeftHand == rightLeftHand && leftRightHand == rightRightHand
            }

            if (lhs is Statement.Error && rhs is Statement.Error) {
                return true
            }
            else {
                return false
            }
        }
        else {
            return false
        }
    }
}

internal fun PrintableTree.Companion.ofExpressions(
    description: String,
    subtrees: MutableList<Expression>)
    : PrintableAsTree?
{
    val newSubtrees: MutableList<PrintableAsTree?> = subtrees.toMutableList<PrintableAsTree?>()
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
    class PrefixUnaryExpression(val subExpression: Expression, val operatorSymbol: String, val typeName: String): Expression()
    class PostfixUnaryExpression(val subExpression: Expression, val operatorSymbol: String, val typeName: String): Expression()
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
                    val matchesTrees: MutableList<PrintableTree> = matches.map { PrintableTree(it.key, mutableListOf(it.value)) }.toMutableList()
                    val sortedMatchesTrees: MutableList<PrintableTree> = matchesTrees.sorted(isAscending = { a, b -> a.treeDescription < b.treeDescription })

                    mutableListOf(PrintableTree("pattern \"${pattern}\""), PrintableTree("matches", sortedMatchesTrees.toMutableList<PrintableAsTree?>()))
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
                    val keyValueTrees: MutableList<PrintableAsTree?> = keys.zip(values).map { pair -> PrintableTree(
                        "pair",
                        mutableListOf(PrintableTree.ofExpressions("key", mutableListOf(pair.first)), PrintableTree.ofExpressions("value", mutableListOf(pair.second)))) }.toMutableList()

                    mutableListOf(PrintableTree("type ${typeName}"), PrintableTree("key value pairs", keyValueTrees))
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
                    val subExpression: Expression = this.subExpression
                    val operatorSymbol: String = this.operatorSymbol
                    val typeName: String = this.typeName

                    mutableListOf(PrintableTree("type ${typeName}"), PrintableTree("operator ${operatorSymbol}"), PrintableTree.ofExpressions("expression", mutableListOf(subExpression)))
                }
                is Expression.IfExpression -> {
                    val condition: Expression = this.condition
                    val trueExpression: Expression = this.trueExpression
                    val falseExpression: Expression = this.falseExpression

                    mutableListOf(PrintableTree.ofExpressions("condition", mutableListOf(condition)), PrintableTree.ofExpressions("trueExpression", mutableListOf(trueExpression)), PrintableTree.ofExpressions("falseExpression", mutableListOf(falseExpression)))
                }
                is Expression.PostfixUnaryExpression -> {
                    val subExpression: Expression = this.subExpression
                    val operatorSymbol: String = this.operatorSymbol
                    val typeName: String = this.typeName

                    mutableListOf(PrintableTree("type ${typeName}"), PrintableTree("operator ${operatorSymbol}"), PrintableTree.ofExpressions("expression", mutableListOf(subExpression)))
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

    override open fun equals(other: Any?): Boolean {
        val lhs: Expression = this
        val rhs: Any? = other
        if (rhs is Expression) {
            if (lhs is Expression.LiteralCodeExpression && rhs is Expression.LiteralCodeExpression) {
                val leftString: String = lhs.string
                val rightString: String = rhs.string
                return leftString == rightString
            }
            else if (lhs is Expression.ParenthesesExpression && rhs is Expression.ParenthesesExpression) {
                val leftExpression: Expression = lhs.expression
                val rightExpression: Expression = rhs.expression
                return leftExpression == rightExpression
            }
            else if (lhs is Expression.ForceValueExpression && rhs is Expression.ForceValueExpression) {
                val leftExpression: Expression = lhs.expression
                val rightExpression: Expression = rhs.expression
                return leftExpression == rightExpression
            }
            else if (lhs is Expression.DeclarationReferenceExpression && rhs is Expression.DeclarationReferenceExpression) {
                val leftExpression: DeclarationReferenceData = lhs.data
                val rightExpression: DeclarationReferenceData = rhs.data
                return leftExpression == rightExpression
            }
            else if (lhs is Expression.TypeExpression && rhs is Expression.TypeExpression) {
                val leftType: String = lhs.typeName
                val rightType: String = rhs.typeName
                return leftType == rightType
            }
            else if (lhs is Expression.SubscriptExpression && rhs is Expression.SubscriptExpression) {
                val leftSubscriptedExpression: Expression = lhs.subscriptedExpression
                val leftIndexExpression: Expression = lhs.indexExpression
                val leftType: String = lhs.typeName
                val rightSubscriptedExpression: Expression = rhs.subscriptedExpression
                val rightIndexExpression: Expression = rhs.indexExpression
                val rightType: String = rhs.typeName

                return leftSubscriptedExpression == rightSubscriptedExpression && leftIndexExpression == rightIndexExpression && leftType == rightType
            }
            else if (lhs is Expression.ArrayExpression && rhs is Expression.ArrayExpression) {
                val leftElements: MutableList<Expression> = lhs.elements
                val leftType: String = lhs.typeName
                val rightElements: MutableList<Expression> = rhs.elements
                val rightType: String = rhs.typeName

                return leftElements == rightElements && leftType == rightType
            }
            else if (lhs is Expression.DotExpression && rhs is Expression.DotExpression) {
                val leftLeftExpression: Expression = lhs.leftExpression
                val leftRightExpression: Expression = lhs.rightExpression
                val rightLeftExpression: Expression = rhs.leftExpression
                val rightRightExpression: Expression = rhs.rightExpression

                return leftLeftExpression == rightLeftExpression && leftRightExpression == rightRightExpression
            }
            else if (lhs is Expression.BinaryOperatorExpression && rhs is Expression.BinaryOperatorExpression) {
                val leftLeftExpression: Expression = lhs.leftExpression
                val leftRightExpression: Expression = lhs.rightExpression
                val leftOperatorSymbol: String = lhs.operatorSymbol
                val leftType: String = lhs.typeName
                val rightLeftExpression: Expression = rhs.leftExpression
                val rightRightExpression: Expression = rhs.rightExpression
                val rightOperatorSymbol: String = rhs.operatorSymbol
                val rightType: String = rhs.typeName

                return leftLeftExpression == rightLeftExpression && leftRightExpression == rightRightExpression && leftOperatorSymbol == rightOperatorSymbol && leftType == rightType
            }
            else if (lhs is Expression.PrefixUnaryExpression && rhs is Expression.PrefixUnaryExpression) {
                val leftExpression: Expression = lhs.subExpression
                val leftOperatorSymbol: String = lhs.operatorSymbol
                val leftType: String = lhs.typeName
                val rightExpression: Expression = rhs.subExpression
                val rightOperatorSymbol: String = rhs.operatorSymbol
                val rightType: String = rhs.typeName

                return leftExpression == rightExpression && leftOperatorSymbol == rightOperatorSymbol && leftType == rightType
            }
            else if (lhs is Expression.PostfixUnaryExpression && rhs is Expression.PostfixUnaryExpression) {
                val leftExpression: Expression = lhs.subExpression
                val leftOperatorSymbol: String = lhs.operatorSymbol
                val leftType: String = lhs.typeName
                val rightExpression: Expression = rhs.subExpression
                val rightOperatorSymbol: String = rhs.operatorSymbol
                val rightType: String = rhs.typeName

                return leftExpression == rightExpression && leftOperatorSymbol == rightOperatorSymbol && leftType == rightType
            }
            else if (lhs is Expression.CallExpression && rhs is Expression.CallExpression) {
                val leftCallExpression: CallExpressionData = lhs.data
                val rightCallExpression: CallExpressionData = rhs.data
                return leftCallExpression == rightCallExpression
            }
            else if (lhs is Expression.LiteralIntExpression && rhs is Expression.LiteralIntExpression) {
                val leftValue: Long = lhs.value
                val rightValue: Long = rhs.value
                return leftValue == rightValue
            }
            else if (lhs is Expression.LiteralDoubleExpression && rhs is Expression.LiteralDoubleExpression) {
                val leftValue: Double = lhs.value
                val rightValue: Double = rhs.value
                return leftValue == rightValue
            }
            else if (lhs is Expression.LiteralBoolExpression && rhs is Expression.LiteralBoolExpression) {
                val leftValue: Boolean = lhs.value
                val rightValue: Boolean = rhs.value
                return leftValue == rightValue
            }
            else if (lhs is Expression.LiteralStringExpression && rhs is Expression.LiteralStringExpression) {
                val leftValue: String = lhs.value
                val rightValue: String = rhs.value
                return leftValue == rightValue
            }
            if (lhs is Expression.NilLiteralExpression && rhs is Expression.NilLiteralExpression) {
                return true
            }
            else if (lhs is Expression.InterpolatedStringLiteralExpression && rhs is Expression.InterpolatedStringLiteralExpression) {
                val leftExpressions: MutableList<Expression> = lhs.expressions
                val rightExpressions: MutableList<Expression> = rhs.expressions
                return leftExpressions == rightExpressions
            }
            else if (lhs is Expression.TupleExpression && rhs is Expression.TupleExpression) {
                val leftPairs: MutableList<LabeledExpression> = lhs.pairs
                val rightPairs: MutableList<LabeledExpression> = rhs.pairs
                return leftPairs == rightPairs
            }
            else if (lhs is Expression.TupleShuffleExpression && rhs is Expression.TupleShuffleExpression) {
                val leftLabels: MutableList<String> = lhs.labels
                val leftIndices: MutableList<TupleShuffleIndex> = lhs.indices
                val leftExpressions: MutableList<Expression> = lhs.expressions
                val rightLabels: MutableList<String> = rhs.labels
                val rightIndices: MutableList<TupleShuffleIndex> = rhs.indices
                val rightExpressions: MutableList<Expression> = rhs.expressions

                return leftLabels == rightLabels && leftIndices == rightIndices && leftExpressions == rightExpressions
            }
            else {
                return false
            }
        }
        else {
            return false
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

open class VariableDeclarationData {
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

    override open fun equals(other: Any?): Boolean {
        val lhs: VariableDeclarationData = this
        val rhs: Any? = other
        if (rhs is VariableDeclarationData) {
            return lhs.identifier == rhs.identifier && lhs.typeName == rhs.typeName && lhs.expression == rhs.expression && lhs.getter == rhs.getter && lhs.setter == rhs.setter && lhs.isLet == rhs.isLet && lhs.isImplicit == rhs.isImplicit && lhs.isStatic == rhs.isStatic && lhs.extendsType == rhs.extendsType && lhs.annotations == rhs.annotations
        }
        else {
            return false
        }
    }
}

open class DeclarationReferenceData {
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

    override open fun equals(other: Any?): Boolean {
        val lhs: DeclarationReferenceData = this
        val rhs: Any? = other
        if (rhs is DeclarationReferenceData) {
            return lhs.identifier == rhs.identifier && lhs.typeName == rhs.typeName && lhs.isStandardLibrary == rhs.isStandardLibrary && lhs.isImplicit == rhs.isImplicit && lhs.range == rhs.range
        }
        else {
            return false
        }
    }
}

open class CallExpressionData {
    val function: Expression
    val parameters: Expression
    val typeName: String
    val range: SourceFileRange?

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

    override open fun equals(other: Any?): Boolean {
        val lhs: CallExpressionData = this
        val rhs: Any? = other
        if (rhs is CallExpressionData) {
            return lhs.function == rhs.function && lhs.parameters == rhs.parameters && lhs.typeName == rhs.typeName && lhs.range == rhs.range
        }
        else {
            return false
        }
    }
}

open class FunctionDeclarationData {
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

    override open fun equals(other: Any?): Boolean {
        val lhs: FunctionDeclarationData = this
        val rhs: Any? = other
        if (rhs is FunctionDeclarationData) {
            return lhs.prefix == rhs.prefix && lhs.parameters == rhs.parameters && lhs.returnType == rhs.returnType && lhs.functionType == rhs.functionType && lhs.genericTypes == rhs.genericTypes && lhs.isImplicit == rhs.isImplicit && lhs.isStatic == rhs.isStatic && lhs.isMutating == rhs.isMutating && lhs.isPure == rhs.isPure && lhs.extendsType == rhs.extendsType && lhs.statements == rhs.statements && lhs.access == rhs.access && lhs.annotations == rhs.annotations
        }
        else {
            return false
        }
    }
}

open class IfStatementData {
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

    override open fun equals(other: Any?): Boolean {
        val lhs: IfStatementData = this
        val rhs: Any? = other
        if (rhs is IfStatementData) {
            return lhs.conditions == rhs.conditions && lhs.declarations == rhs.declarations && lhs.statements == rhs.statements && lhs.elseStatement == rhs.elseStatement && lhs.isGuard == rhs.isGuard
        }
        else {
            return false
        }
    }
}

open class SwitchCase {
    var expressions: MutableList<Expression>
    var statements: MutableList<Statement>

    constructor(expressions: MutableList<Expression>, statements: MutableList<Statement>) {
        this.expressions = expressions
        this.statements = statements
    }

    override open fun equals(other: Any?): Boolean {
        val lhs: SwitchCase = this
        val rhs: Any? = other
        if (rhs is SwitchCase) {
            return lhs.expressions == rhs.expressions && lhs.statements == rhs.statements
        }
        else {
            return false
        }
    }
}

open class EnumElement: PrintableAsTree {
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

    override open fun equals(other: Any?): Boolean {
        val lhs: EnumElement = this
        val rhs: Any? = other
        if (rhs is EnumElement) {
            return lhs.name == rhs.name && lhs.associatedValues == rhs.associatedValues && lhs.rawValue == rhs.rawValue && lhs.annotations == rhs.annotations
        }
        else {
            return false
        }
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

    override open fun equals(other: Any?): Boolean {
        val lhs: TupleShuffleIndex = this
        val rhs: Any? = other
        if (rhs is TupleShuffleIndex) {
            if (lhs is TupleShuffleIndex.Variadic && rhs is TupleShuffleIndex.Variadic) {
                val lhsCount: Int = lhs.count
                val rhsCount: Int = rhs.count
                return (lhsCount == rhsCount)
            }
            else if (lhs is TupleShuffleIndex.Absent && rhs is TupleShuffleIndex.Absent) {
                return true
            }
            else if (lhs is TupleShuffleIndex.Present && rhs is TupleShuffleIndex.Present) {
                return true
            }
            else {
                return false
            }
        }
        else {
            return false
        }
    }
}
