open class KotlinTranslator {
    companion object {
        var indentationString: String = "\t"
        val errorTranslation: String = "<<Error>>"
        val lineLimit: Int = 100
        var sealedClasses: MutableList<String> = mutableListOf()

        public fun addSealedClass(className: String) {
            sealedClasses.add(className)
        }

        var enumClasses: MutableList<String> = mutableListOf()

        public fun addEnumClass(className: String) {
            enumClasses.add(className)
        }

        var protocols: MutableList<String> = mutableListOf()

        public fun addProtocol(protocolName: String) {
            protocols.add(protocolName)
        }

        var functionTranslations: MutableList<KotlinTranslator.FunctionTranslation> = mutableListOf()

        public fun addFunctionTranslation(newValue: KotlinTranslator.FunctionTranslation) {
            functionTranslations.add(newValue)
        }

        public fun getFunctionTranslation(
            name: String,
            typeName: String)
            : KotlinTranslator.FunctionTranslation?
        {
            for (functionTranslation in functionTranslations) {
                if (functionTranslation.swiftAPIName.startsWith(name) && functionTranslation.typeName == typeName) {
                    return functionTranslation
                }
            }
            return null
        }

        var pureFunctions: MutableList<FunctionDeclarationData> = mutableListOf()

        public fun recordPureFunction(newValue: FunctionDeclarationData) {
            pureFunctions.add(newValue)
        }

        public fun isReferencingPureFunction(callExpression: CallExpressionData): Boolean {
            var finalCallExpression: Expression = callExpression.function

            while (true) {
                if (finalCallExpression is Expression.DotExpression) {
                    val nextCallExpression: Expression = finalCallExpression.rightExpression
                    finalCallExpression = nextCallExpression
                }
                else {
                    break
                }
            }

            if (finalCallExpression is Expression.DeclarationReferenceExpression) {
                val declarationReferenceExpression: DeclarationReferenceData = finalCallExpression.data
                for (functionDeclaration in pureFunctions) {
                    if (declarationReferenceExpression.identifier.startsWith(functionDeclaration.prefix) && declarationReferenceExpression.typeName == functionDeclaration.functionType) {
                        return true
                    }
                }
            }

            return false
        }
    }

    data class FunctionTranslation(
        val swiftAPIName: String,
        val typeName: String,
        val prefix: String,
        val parameters: MutableList<String>
    )

    constructor() {
    }

    internal fun translateType(typeName: String): String {
        val typeName: String = typeName.replace("()", "Unit")
        if (typeName.endsWith("?")) {
            return translateType(typeName.dropLast(1)) + "?"
        }
        else if (typeName.startsWith("[")) {
            if (typeName.contains(":")) {
                val innerType: String = typeName.dropLast(1).drop(1)
                val innerTypes: MutableList<String> = Utilities.splitTypeList(innerType)
                val keyType: String = innerTypes[0]
                val valueType: String = innerTypes[1]
                val translatedKey: String = translateType(keyType)
                val translatedValue: String = translateType(valueType)

                return "MutableMap<${translatedKey}, ${translatedValue}>"
            }
            else {
                val innerType: String = typeName.dropLast(1).drop(1)
                val translatedInnerType: String = translateType(innerType)
                return "MutableList<${translatedInnerType}>"
            }
        }
        else if (typeName.startsWith("ArrayClass<")) {
            val innerType: String = typeName.dropLast(1).drop("ArrayClass<".length)
            val translatedInnerType: String = translateType(innerType)
            return "MutableList<${translatedInnerType}>"
        }
        else if (typeName.startsWith("DictionaryClass<")) {
            val innerTypes: String = typeName.dropLast(1).drop("DictionaryClass<".length)
            val keyValue: MutableList<String> = Utilities.splitTypeList(innerTypes)
            val key: String = keyValue[0]
            val value: String = keyValue[1]
            val translatedKey: String = translateType(key)
            val translatedValue: String = translateType(value)

            return "MutableMap<${translatedKey}, ${translatedValue}>"
        }
        else if (Utilities.isInEnvelopingParentheses(typeName)) {
            val innerTypeString: String = typeName.drop(1).dropLast(1)
            val innerTypes: MutableList<String> = Utilities.splitTypeList(innerTypeString, separators = mutableListOf(", "))
            if (innerTypes.size == 2) {
                return "Pair<${innerTypes.joinToString(separator = ", ")}>"
            }
            else {
                return translateType(typeName.drop(1).dropLast(1))
            }
        }
        else if (typeName.contains(" -> ")) {
            val functionComponents: MutableList<String> = Utilities.splitTypeList(typeName, separators = mutableListOf(" -> "))
            val translatedComponents: MutableList<String> = functionComponents.map { translateFunctionTypeComponent(it) }.toMutableList()
            val firstTypes: MutableList<String> = translatedComponents.dropLast(1).map { "(${it})" }.toMutableList()
            val lastType: String = translatedComponents.lastOrNull()!!
            var allTypes: MutableList<String> = firstTypes

            allTypes.add(lastType)

            return allTypes.joinToString(separator = " -> ")
        }
        else {
            return Utilities.getTypeMapping(typeName = typeName) ?: typeName
        }
    }

    private fun translateFunctionTypeComponent(component: String): String {
        if (Utilities.isInEnvelopingParentheses(component)) {
            val openComponent: String = component.drop(1).dropLast(1)
            val componentParts: MutableList<String> = Utilities.splitTypeList(openComponent, separators = mutableListOf(", "))
            val translatedParts: MutableList<String> = componentParts.map { translateType(it) }.toMutableList()

            return translatedParts.joinToString(separator = ", ")
        }
        else {
            return translateType(component)
        }
    }
}

private fun KotlinTranslator.translateDoStatement(
    statements: MutableList<Statement>,
    indentation: String)
    : String
{
    val translatedStatements: String = translateSubtrees(
        statements,
        indentation = increaseIndentation(indentation),
        limitForAddingNewlines = 3)
    return "${indentation}try {\n${translatedStatements}${indentation}}\n"
}

private fun KotlinTranslator.translateCatchStatement(
    variableDeclaration: VariableDeclarationData?,
    statements: MutableList<Statement>,
    indentation: String)
    : String
{
    var result: String = ""

    if (variableDeclaration != null) {
        val translatedType: String = translateType(variableDeclaration.typeName)
        result = "${indentation}catch " + "(${variableDeclaration.identifier}: ${translatedType}) {\n"
    }
    else {
        result = "${indentation}catch {\n"
    }

    val translatedStatements: String = translateSubtrees(
        statements,
        indentation = increaseIndentation(indentation),
        limitForAddingNewlines = 3)

    result += "${translatedStatements}"

    result += "${indentation}}\n"

    return result
}

private fun KotlinTranslator.translateForEachStatement(
    collection: Expression,
    variable: Expression,
    statements: MutableList<Statement>,
    indentation: String)
    : String
{
    var result: String = "${indentation}for ("
    val variableTranslation: String = translateExpression(variable, indentation = indentation)

    result += variableTranslation + " in "

    val collectionTranslation: String = translateExpression(collection, indentation = indentation)

    result += collectionTranslation + ") {\n"

    val increasedIndentation: String = increaseIndentation(indentation)
    val statementsTranslation: String = translateSubtrees(statements, indentation = increasedIndentation, limitForAddingNewlines = 3)

    result += statementsTranslation

    result += indentation + "}\n"

    return result
}

private fun KotlinTranslator.translateWhileStatement(
    expression: Expression,
    statements: MutableList<Statement>,
    indentation: String)
    : String
{
    var result: String = "${indentation}while ("
    val expressionTranslation: String = translateExpression(expression, indentation = indentation)

    result += expressionTranslation + ") {\n"

    val increasedIndentation: String = increaseIndentation(indentation)
    val statementsTranslation: String = translateSubtrees(statements, indentation = increasedIndentation, limitForAddingNewlines = 3)

    result += statementsTranslation

    result += indentation + "}\n"

    return result
}

private fun KotlinTranslator.translateIfStatement(
    ifStatement: IfStatementData,
    isElseIf: Boolean = false,
    indentation: String)
    : String
{
    val keyword: String = if (ifStatement.conditions.isEmpty() && ifStatement.declarations.isEmpty()) { "else" } else { if (isElseIf) { "else if" } else { "if" } }
    var result: String = indentation + keyword + " "
    val increasedIndentation: String = increaseIndentation(indentation)
    val conditionsTranslation: String = ifStatement.conditions.map { conditionToExpression(it) }.filterNotNull().toMutableList().map { translateExpression(it, indentation = indentation) }.toMutableList().joinToString(separator = " && ")

    if (keyword != "else") {
        val parenthesizedCondition: String = if (ifStatement.isGuard) { "(!(" + conditionsTranslation + ")) " } else { "(" + conditionsTranslation + ") " }
        result += parenthesizedCondition
    }

    result += "{\n"

    val statementsString: String = translateSubtrees(
        ifStatement.statements,
        indentation = increasedIndentation,
        limitForAddingNewlines = 3)

    result += statementsString + indentation + "}\n"

    val unwrappedElse: IfStatementData? = ifStatement.elseStatement

    if (unwrappedElse != null) {
        result += translateIfStatement(unwrappedElse, isElseIf = true, indentation = indentation)
    }

    return result
}

private fun KotlinTranslator.conditionToExpression(
    condition: IfStatementData.IfCondition)
    : Expression?
{
    if (condition is IfStatementData.IfCondition.Condition) {
        val expression: Expression = condition.expression
        return expression
    }
    else {
        return null
    }
}

private fun KotlinTranslator.translateSwitchStatement(
    convertsToExpression: Statement?,
    expression: Expression,
    cases: MutableList<SwitchCase>,
    indentation: String)
    : String
{
    var result: String = ""

    if (convertsToExpression != null) {
        if (convertsToExpression is Statement.ReturnStatement) {
            result = "${indentation}return when ("
        }
        else if (convertsToExpression is Statement.AssignmentStatement) {
            val leftHand: Expression = convertsToExpression.leftHand
            val translatedLeftHand: String = translateExpression(leftHand, indentation = indentation)
            result = "${indentation}${translatedLeftHand} = when ("
        }
        else if (convertsToExpression is Statement.VariableDeclaration) {
            val variableDeclaration: VariableDeclarationData = convertsToExpression.data
            val newVariableDeclaration: VariableDeclarationData = VariableDeclarationData(
                identifier = variableDeclaration.identifier,
                typeName = variableDeclaration.typeName,
                expression = Expression.NilLiteralExpression(),
                getter = null,
                setter = null,
                isLet = variableDeclaration.isLet,
                isImplicit = false,
                isStatic = false,
                extendsType = null,
                annotations = variableDeclaration.annotations)
            val translatedVariableDeclaration: String = translateVariableDeclaration(newVariableDeclaration, indentation = indentation)
            val cleanTranslation: String = translatedVariableDeclaration.dropLast("null\n".length)

            result = "${cleanTranslation}when ("
        }
    }

    if (result.isEmpty()) {
        result = "${indentation}when ("
    }

    val expressionTranslation: String = translateExpression(expression, indentation = indentation)
    val increasedIndentation: String = increaseIndentation(indentation)

    result += "${expressionTranslation}) {\n"

    for (switchCase in cases) {
        if (switchCase.statements.isEmpty()) {
            continue
        }

        result += increasedIndentation

        val translatedExpressions: MutableList<String> = mutableListOf()

        for (caseExpression in switchCase.expressions) {
            val translatedExpression: String = translateSwitchCaseExpression(
                caseExpression,
                switchExpression = expression,
                indentation = increasedIndentation)
            translatedExpressions.add(translatedExpression)
        }

        if (translatedExpressions.isEmpty()) {
            result += "else -> "
        }
        else {
            result += translatedExpressions.joinToString(separator = ", ") + " -> "
        }

        val onlyStatement: Statement? = switchCase.statements.firstOrNull()

        if (switchCase.statements.size == 1 && onlyStatement != null) {
            val statementTranslation: String = translateSubtree(onlyStatement, indentation = "")
            result += statementTranslation
        }
        else {
            result += "{\n"

            val statementsIndentation: String = increaseIndentation(increasedIndentation)
            val statementsTranslation: String = translateSubtrees(
                switchCase.statements,
                indentation = statementsIndentation,
                limitForAddingNewlines = 3)

            result += "${statementsTranslation}${increasedIndentation}}\n"
        }
    }

    result += "${indentation}}\n"

    return result
}

private fun KotlinTranslator.translateSwitchCaseExpression(
    caseExpression: Expression,
    switchExpression: Expression,
    indentation: String)
    : String
{
    if (caseExpression is Expression.BinaryOperatorExpression) {
        val leftExpression: Expression = caseExpression.leftExpression
        val rightExpression: Expression = caseExpression.rightExpression
        val operatorSymbol: String = caseExpression.operatorSymbol
        val typeName: String = caseExpression.typeName

        if (leftExpression == switchExpression && operatorSymbol == "is" && typeName == "Bool") {
            val translatedType: String = translateExpression(rightExpression, indentation = indentation)
            return "is ${translatedType}"
        }
        else {
            val translatedExpression: String = translateExpression(leftExpression, indentation = indentation)
            if (leftExpression is Expression.TemplateExpression) {
                val pattern: String = leftExpression.pattern
                if (pattern.contains("..") || pattern.contains("until") || pattern.contains("rangeTo")) {
                    return "in ${translatedExpression}"
                }
            }
            return translatedExpression
        }
    }
    val translatedExpression: String = translateExpression(caseExpression, indentation = indentation)
    return translatedExpression
}

private fun KotlinTranslator.translateThrowStatement(
    expression: Expression,
    indentation: String)
    : String
{
    val expressionString: String = translateExpression(expression, indentation = indentation)
    return "${indentation}throw ${expressionString}\n"
}

private fun KotlinTranslator.translateReturnStatement(
    expression: Expression?,
    indentation: String)
    : String
{
    if (expression != null) {
        val expressionString: String = translateExpression(expression, indentation = indentation)
        return "${indentation}return ${expressionString}\n"
    }
    else {
        return "${indentation}return\n"
    }
}

private fun KotlinTranslator.translateVariableDeclaration(
    variableDeclaration: VariableDeclarationData,
    indentation: String)
    : String
{
    if (variableDeclaration.isImplicit) {
        return ""
    }

    var result: String = indentation
    val annotations: String? = variableDeclaration.annotations

    if (annotations != null) {
        result += "${annotations} "
    }

    var keyword: String

    if (variableDeclaration.getter != null && variableDeclaration.setter != null) {
        keyword = "var"
    }
    else if (variableDeclaration.getter != null && variableDeclaration.setter == null) {
        keyword = "val"
    }
    else {
        if (variableDeclaration.isLet) {
            keyword = "val"
        }
        else {
            keyword = "var"
        }
    }

    result += "${keyword} "

    val extensionPrefix: String
    val extendsType: String? = variableDeclaration.extendsType

    if (extendsType != null) {
        val translatedExtendedType: String = translateType(extendsType)
        val genericString: String
        val genericIndex: Int? = translatedExtendedType.indexOrNull('<')

        if (genericIndex != null) {
            val genericContents: String = translatedExtendedType.suffix(startIndex = genericIndex)
            genericString = "${genericContents} "
        }
        else {
            genericString = ""
        }

        extensionPrefix = genericString + translatedExtendedType + "."
    }
    else {
        extensionPrefix = ""
    }

    result += "${extensionPrefix}${variableDeclaration.identifier}: "

    val translatedType: String = translateType(variableDeclaration.typeName)

    result += translatedType

    val expression: Expression? = variableDeclaration.expression

    if (expression != null) {
        val expressionTranslation: String = translateExpression(expression, indentation = indentation)
        result += " = " + expressionTranslation
    }

    result += "\n"

    val indentation1: String = increaseIndentation(indentation)
    val indentation2: String = increaseIndentation(indentation1)
    val getter: FunctionDeclarationData? = variableDeclaration.getter

    if (getter != null) {
        val statements: MutableList<Statement>? = getter.statements
        if (statements != null) {
            result += indentation1 + "get() {\n"
            result += translateSubtrees(statements, indentation = indentation2, limitForAddingNewlines = 3)
            result += indentation1 + "}\n"
        }
    }

    val setter: FunctionDeclarationData? = variableDeclaration.setter

    if (setter != null) {
        val statements: MutableList<Statement>? = setter.statements
        if (statements != null) {
            result += indentation1 + "set(newValue) {\n"
            result += translateSubtrees(statements, indentation = indentation2, limitForAddingNewlines = 3)
            result += indentation1 + "}\n"
        }
    }

    return result
}

private fun KotlinTranslator.translateAssignmentStatement(
    leftHand: Expression,
    rightHand: Expression,
    indentation: String)
    : String
{
    val leftTranslation: String = translateExpression(leftHand, indentation = indentation)
    val rightTranslation: String = translateExpression(rightHand, indentation = indentation)
    return "${indentation}${leftTranslation} = ${rightTranslation}\n"
}

private fun KotlinTranslator.translateExpression(
    expression: Expression,
    indentation: String)
    : String
{
    return when (expression) {
        is Expression.TemplateExpression -> {
            val pattern: String = expression.pattern
            val matches: MutableMap<String, Expression> = expression.matches
            translateTemplateExpression(pattern = pattern, matches = matches, indentation = indentation)
        }
        is Expression.LiteralCodeExpression -> {
            val string: String = expression.string
            translateLiteralCodeExpression(string = string)
        }
        is Expression.LiteralDeclarationExpression -> {
            val string: String = expression.string
            translateLiteralCodeExpression(string = string)
        }
        is Expression.ArrayExpression -> {
            val elements: MutableList<Expression> = expression.elements
            val typeName: String = expression.typeName
            translateArrayExpression(elements = elements, typeName = typeName, indentation = indentation)
        }
        is Expression.DictionaryExpression -> {
            val keys: MutableList<Expression> = expression.keys
            val values: MutableList<Expression> = expression.values
            val typeName: String = expression.typeName

            translateDictionaryExpression(
                keys = keys,
                values = values,
                typeName = typeName,
                indentation = indentation)
        }
        is Expression.BinaryOperatorExpression -> {
            val leftExpression: Expression = expression.leftExpression
            val rightExpression: Expression = expression.rightExpression
            val operatorSymbol: String = expression.operatorSymbol
            val typeName: String = expression.typeName

            translateBinaryOperatorExpression(
                leftExpression = leftExpression,
                rightExpression = rightExpression,
                operatorSymbol = operatorSymbol,
                typeName = typeName,
                indentation = indentation)
        }
        is Expression.CallExpression -> {
            val callExpression: CallExpressionData = expression.data
            translateCallExpression(callExpression = callExpression, indentation = indentation)
        }
        is Expression.ClosureExpression -> {
            val parameters: MutableList<LabeledType> = expression.parameters
            val statements: MutableList<Statement> = expression.statements
            val typeName: String = expression.typeName

            translateClosureExpression(
                parameters = parameters,
                statements = statements,
                typeName = typeName,
                indentation = indentation)
        }
        is Expression.DeclarationReferenceExpression -> {
            val declarationReferenceExpression: DeclarationReferenceData = expression.data
            translateDeclarationReferenceExpression(declarationReferenceExpression)
        }
        is Expression.ReturnExpression -> {
            val expression: Expression? = expression.expression
            translateReturnExpression(expression = expression, indentation = indentation)
        }
        is Expression.DotExpression -> {
            val leftExpression: Expression = expression.leftExpression
            val rightExpression: Expression = expression.rightExpression
            translateDotSyntaxCallExpression(
                leftExpression = leftExpression,
                rightExpression = rightExpression,
                indentation = indentation)
        }
        is Expression.LiteralStringExpression -> {
            val value: String = expression.value
            translateStringLiteral(value = value)
        }
        is Expression.LiteralCharacterExpression -> {
            val value: String = expression.value
            translateCharacterLiteral(value = value)
        }
        is Expression.InterpolatedStringLiteralExpression -> {
            val expressions: MutableList<Expression> = expression.expressions
            translateInterpolatedStringLiteralExpression(expressions = expressions, indentation = indentation)
        }
        is Expression.PrefixUnaryExpression -> {
            val subExpression: Expression = expression.subExpression
            val operatorSymbol: String = expression.operatorSymbol
            val typeName: String = expression.typeName

            translatePrefixUnaryExpression(
                subExpression = subExpression,
                operatorSymbol = operatorSymbol,
                typeName = typeName,
                indentation = indentation)
        }
        is Expression.PostfixUnaryExpression -> {
            val subExpression: Expression = expression.subExpression
            val operatorSymbol: String = expression.operatorSymbol
            val typeName: String = expression.typeName

            translatePostfixUnaryExpression(
                subExpression = subExpression,
                operatorSymbol = operatorSymbol,
                typeName = typeName,
                indentation = indentation)
        }
        is Expression.IfExpression -> {
            val condition: Expression = expression.condition
            val trueExpression: Expression = expression.trueExpression
            val falseExpression: Expression = expression.falseExpression

            translateIfExpression(
                condition = condition,
                trueExpression = trueExpression,
                falseExpression = falseExpression,
                indentation = indentation)
        }
        is Expression.TypeExpression -> {
            val typeName: String = expression.typeName
            translateType(typeName)
        }
        is Expression.SubscriptExpression -> {
            val subscriptedExpression: Expression = expression.subscriptedExpression
            val indexExpression: Expression = expression.indexExpression
            val typeName: String = expression.typeName

            translateSubscriptExpression(
                subscriptedExpression = subscriptedExpression,
                indexExpression = indexExpression,
                typeName = typeName,
                indentation = indentation)
        }
        is Expression.ParenthesesExpression -> {
            val expression: Expression = expression.expression
            "(" + translateExpression(expression, indentation = indentation) + ")"
        }
        is Expression.ForceValueExpression -> {
            val expression: Expression = expression.expression
            translateExpression(expression, indentation = indentation) + "!!"
        }
        is Expression.OptionalExpression -> {
            val expression: Expression = expression.expression
            translateExpression(expression, indentation = indentation) + "?"
        }
        is Expression.LiteralIntExpression -> {
            val value: Long = expression.value
            value.toString()
        }
        is Expression.LiteralUIntExpression -> {
            val value: ULong = expression.value
            value.toString() + "u"
        }
        is Expression.LiteralDoubleExpression -> {
            val value: Double = expression.value
            value.toString()
        }
        is Expression.LiteralFloatExpression -> {
            val value: Float = expression.value
            value.toString() + "f"
        }
        is Expression.LiteralBoolExpression -> {
            val value: Boolean = expression.value
            value.toString()
        }
        is Expression.NilLiteralExpression -> "null"
        is Expression.TupleExpression -> {
            val pairs: MutableList<LabeledExpression> = expression.pairs
            translateTupleExpression(pairs = pairs, indentation = indentation)
        }
        is Expression.TupleShuffleExpression -> {
            val labels: MutableList<String> = expression.labels
            val indices: MutableList<TupleShuffleIndex> = expression.indices
            val expressions: MutableList<Expression> = expression.expressions

            translateTupleShuffleExpression(
                labels = labels,
                indices = indices,
                expressions = expressions,
                indentation = indentation)
        }
        is Expression.Error -> KotlinTranslator.errorTranslation
    }
}

private fun KotlinTranslator.translateSubscriptExpression(
    subscriptedExpression: Expression,
    indexExpression: Expression,
    typeName: String,
    indentation: String)
    : String
{
    return translateExpression(subscriptedExpression, indentation = indentation) + "[${translateExpression(indexExpression, indentation = indentation)}]"
}

private fun KotlinTranslator.translateArrayExpression(
    elements: MutableList<Expression>,
    typeName: String,
    indentation: String)
    : String
{
    val expressionsString: String = elements.map { translateExpression(it, indentation = indentation) }.toMutableList().joinToString(separator = ", ")
    return "mutableListOf(${expressionsString})"
}

private fun KotlinTranslator.translateDictionaryExpression(
    keys: MutableList<Expression>,
    values: MutableList<Expression>,
    typeName: String,
    indentation: String)
    : String
{
    val keyExpressions: MutableList<String> = keys.map { translateExpression(it, indentation = indentation) }.toMutableList()
    val valueExpressions: MutableList<String> = values.map { translateExpression(it, indentation = indentation) }.toMutableList()
    val expressionsString: String = keyExpressions.zip(valueExpressions).map { keyValueTuple -> "${keyValueTuple.first} to ${keyValueTuple.second}" }.toMutableList().joinToString(separator = ", ")

    return "mutableMapOf(${expressionsString})"
}

private fun KotlinTranslator.translateReturnExpression(
    expression: Expression?,
    indentation: String)
    : String
{
    if (expression != null) {
        val expressionString: String = translateExpression(expression, indentation = indentation)
        return "return ${expressionString}"
    }
    else {
        return "return"
    }
}

private fun KotlinTranslator.translateDotSyntaxCallExpression(
    leftExpression: Expression,
    rightExpression: Expression,
    indentation: String)
    : String
{
    val leftHandString: String = translateExpression(leftExpression, indentation = indentation)
    val rightHandString: String = translateExpression(rightExpression, indentation = indentation)
    if (KotlinTranslator.sealedClasses.contains(leftHandString)) {
        val translatedEnumCase: String = rightHandString.capitalizedAsCamelCase()
        return "${leftHandString}.${translatedEnumCase}()"
    }
    else {
        val enumName: String = leftHandString.split(separator = ".").lastOrNull()!!
        if (KotlinTranslator.enumClasses.contains(enumName)) {
            val translatedEnumCase: String = rightHandString.upperSnakeCase()
            return "${leftHandString}.${translatedEnumCase}"
        }
        else {
            return "${leftHandString}.${rightHandString}"
        }
    }
}

private fun KotlinTranslator.translateBinaryOperatorExpression(
    leftExpression: Expression,
    rightExpression: Expression,
    operatorSymbol: String,
    typeName: String,
    indentation: String)
    : String
{
    val leftTranslation: String = translateExpression(leftExpression, indentation = indentation)
    val rightTranslation: String = translateExpression(rightExpression, indentation = indentation)
    return "${leftTranslation} ${operatorSymbol} ${rightTranslation}"
}

private fun KotlinTranslator.translatePrefixUnaryExpression(
    subExpression: Expression,
    operatorSymbol: String,
    typeName: String,
    indentation: String)
    : String
{
    val expressionTranslation: String = translateExpression(subExpression, indentation = indentation)
    return operatorSymbol + expressionTranslation
}

private fun KotlinTranslator.translatePostfixUnaryExpression(
    subExpression: Expression,
    operatorSymbol: String,
    typeName: String,
    indentation: String)
    : String
{
    val expressionTranslation: String = translateExpression(subExpression, indentation = indentation)
    return expressionTranslation + operatorSymbol
}

private fun KotlinTranslator.translateIfExpression(
    condition: Expression,
    trueExpression: Expression,
    falseExpression: Expression,
    indentation: String)
    : String
{
    val conditionTranslation: String = translateExpression(condition, indentation = indentation)
    val trueExpressionTranslation: String = translateExpression(trueExpression, indentation = indentation)
    val falseExpressionTranslation: String = translateExpression(falseExpression, indentation = indentation)

    return "if (${conditionTranslation}) { ${trueExpressionTranslation} } else " + "{ ${falseExpressionTranslation} }"
}

private fun KotlinTranslator.translateCallExpression(
    callExpression: CallExpressionData,
    indentation: String,
    shouldAddNewlines: Boolean = false)
    : String
{
    var result: String = ""
    var functionExpression: Expression = callExpression.function

    while (true) {
        if (functionExpression is Expression.DotExpression) {
            val leftExpression: Expression = functionExpression.leftExpression
            val rightExpression: Expression = functionExpression.rightExpression

            result += translateExpression(leftExpression, indentation = indentation) + "."

            functionExpression = rightExpression
        }
        else {
            break
        }
    }

    val functionTranslation: KotlinTranslator.FunctionTranslation?

    if (functionExpression is Expression.DeclarationReferenceExpression) {
        val expression: DeclarationReferenceData = functionExpression.data
        functionTranslation = KotlinTranslator.getFunctionTranslation(
            name = expression.identifier,
            typeName = expression.typeName)
    }
    else {
        functionTranslation = null
    }

    val prefix: String = functionTranslation?.prefix ?: translateExpression(functionExpression, indentation = indentation)
    val parametersTranslation: String = translateParameters(
        callExpression = callExpression,
        functionTranslation = functionTranslation,
        indentation = indentation,
        shouldAddNewlines = shouldAddNewlines)

    result += "${prefix}${parametersTranslation}"

    if (!shouldAddNewlines && result.length >= KotlinTranslator.lineLimit) {
        return translateCallExpression(callExpression, indentation = indentation, shouldAddNewlines = true)
    }
    else {
        return result
    }
}

private fun KotlinTranslator.translateParameters(
    callExpression: CallExpressionData,
    functionTranslation: KotlinTranslator.FunctionTranslation?,
    indentation: String,
    shouldAddNewlines: Boolean)
    : String
{
    if (callExpression.parameters is Expression.TupleExpression) {
        val pairs: MutableList<LabeledExpression> = callExpression.parameters.pairs
        val closurePair: LabeledExpression? = pairs.lastOrNull()

        if (closurePair != null) {
            if (closurePair.expression is Expression.ClosureExpression) {
                val parameters: MutableList<LabeledType> = closurePair.expression.parameters
                val statements: MutableList<Statement> = closurePair.expression.statements
                val typeName: String = closurePair.expression.typeName
                val closureTranslation: String = translateClosureExpression(
                    parameters = parameters,
                    statements = statements,
                    typeName = typeName,
                    indentation = increaseIndentation(indentation))

                if (parameters.size > 1) {
                    val firstParametersTranslation: String = translateTupleExpression(
                        pairs = pairs.dropLast(1).toMutableList<LabeledExpression>(),
                        translation = functionTranslation,
                        indentation = increaseIndentation(indentation),
                        shouldAddNewlines = shouldAddNewlines)
                    return "${firstParametersTranslation} ${closureTranslation}"
                }
                else {
                    return " ${closureTranslation}"
                }
            }
        }

        return translateTupleExpression(
            pairs = pairs,
            translation = functionTranslation,
            indentation = increaseIndentation(indentation),
            shouldAddNewlines = shouldAddNewlines)
    }
    else if (callExpression.parameters is Expression.TupleShuffleExpression) {
        val labels: MutableList<String> = callExpression.parameters.labels
        val indices: MutableList<TupleShuffleIndex> = callExpression.parameters.indices
        val expressions: MutableList<Expression> = callExpression.parameters.expressions

        return translateTupleShuffleExpression(
            labels = labels,
            indices = indices,
            expressions = expressions,
            translation = functionTranslation,
            indentation = increaseIndentation(indentation),
            shouldAddNewlines = shouldAddNewlines)
    }
    return unexpectedASTStructureError(
        "Expected the parameters to be either a .tupleExpression or a " + ".tupleShuffleExpression",
        ast = Statement.ExpressionStatement(expression = Expression.CallExpression(data = callExpression)))
}

private fun KotlinTranslator.translateClosureExpression(
    parameters: MutableList<LabeledType>,
    statements: MutableList<Statement>,
    typeName: String,
    indentation: String)
    : String
{
    if (statements.isEmpty()) {
        return "{ }"
    }

    var result: String = "{"
    val parametersString: String = parameters.map { it.label }.toMutableList().joinToString(separator = ", ")

    if (!parametersString.isEmpty()) {
        result += " " + parametersString + " ->"
    }

    val firstStatement: Statement? = statements.firstOrNull()

    if (statements.size == 1 && firstStatement != null && firstStatement is Statement.ExpressionStatement) {
        val expression: Expression = firstStatement.expression
        result += " " + translateExpression(expression, indentation = indentation) + " }"
    }
    else {
        result += "\n"

        val closingBraceIndentation: String = increaseIndentation(indentation)
        val contentsIndentation: String = increaseIndentation(closingBraceIndentation)

        result += translateSubtrees(subtrees = statements, indentation = contentsIndentation)

        result += closingBraceIndentation + "}"
    }

    return result
}

private fun KotlinTranslator.translateLiteralCodeExpression(string: String): String {
    return string.removingBackslashEscapes
}

private fun KotlinTranslator.translateTemplateExpression(
    pattern: String,
    matches: MutableMap<String, Expression>,
    indentation: String)
    : String
{
    var result: String = pattern
    for ((string, expression) in matches) {
        val expressionTranslation: String = translateExpression(expression, indentation = indentation)
        result = result.replace(string, expressionTranslation)
    }
    return result
}

private fun KotlinTranslator.translateDeclarationReferenceExpression(
    declarationReferenceExpression: DeclarationReferenceData)
    : String
{
    return declarationReferenceExpression.identifier.takeWhile { it != '(' }
}

private fun KotlinTranslator.translateTupleExpression(
    pairs: MutableList<LabeledExpression>,
    translation: KotlinTranslator.FunctionTranslation? = null,
    indentation: String,
    shouldAddNewlines: Boolean = false)
    : String
{
    if (pairs.isEmpty()) {
        return "()"
    }

    val parameters: MutableList<String?>
    val translationParameters: MutableList<String>? = translation?.parameters

    if (translationParameters != null) {
        parameters = translationParameters.zip(pairs).map { translationPairTuple -> if (translationPairTuple.second.label == null) { null } else { translationPairTuple.first } }.toMutableList()
    }
    else {
        parameters = pairs.map { it.label }.toMutableList()
    }

    val expressions: MutableList<Expression> = pairs.map { it.expression }.toMutableList()
    val expressionIndentation: String = if (shouldAddNewlines) { increaseIndentation((indentation)) } else { indentation }
    val translations: MutableList<String> = parameters.zip(expressions).map { parameterExpressionTuple -> translateParameter(
        label = parameterExpressionTuple.first,
        expression = parameterExpressionTuple.second,
        indentation = expressionIndentation) }.toMutableList()

    if (!shouldAddNewlines) {
        val contents: String = translations.joinToString(separator = ", ")
        return "(${contents})"
    }
    else {
        val contents: String = translations.joinToString(separator = ",\n${indentation}")
        return "(\n${indentation}${contents})"
    }
}

private fun KotlinTranslator.translateParameter(
    label: String?,
    expression: Expression,
    indentation: String)
    : String
{
    val expression: String = translateExpression(expression, indentation = indentation)
    if (label != null) {
        return "${label} = ${expression}"
    }
    else {
        return expression
    }
}

private fun KotlinTranslator.translateTupleShuffleExpression(
    labels: MutableList<String>,
    indices: MutableList<TupleShuffleIndex>,
    expressions: MutableList<Expression>,
    translation: KotlinTranslator.FunctionTranslation? = null,
    indentation: String,
    shouldAddNewlines: Boolean = false)
    : String
{
    val parameters: MutableList<String> = translation?.parameters ?: labels
    val increasedIndentation: String = increaseIndentation(indentation)
    val translations: MutableList<String> = mutableListOf()
    var expressionIndex: Int = 0
    val containsVariadics: Boolean = (indices.find { index ->
            if (index is TupleShuffleIndex.Variadic) {
                true
            }

            false
        } != null)
    var isBeforeVariadic: Boolean = containsVariadics

    if (parameters.size != indices.size) {
        return unexpectedASTStructureError(
            "Different number of labels and indices in a tuple shuffle expression. " + "Labels: ${labels}, indices: ${indices}",
            ast = Statement.ExpressionStatement(
                    expression = Expression.TupleShuffleExpression(labels = labels, indices = indices, expressions = expressions)))
    }

    for ((label, index) in parameters.zip(indices)) {
        when (index) {
            is TupleShuffleIndex.Present -> {
                val expression: Expression = expressions[expressionIndex]
                var result: String = ""

                if (!isBeforeVariadic) {
                    result += "${label} = "
                }

                result += translateExpression(expression, indentation = increasedIndentation)

                translations.add(result)

                expressionIndex += 1
            }
            is TupleShuffleIndex.Variadic -> {
                val variadicCount: Int = index.count
                isBeforeVariadic = false
                for (_0 in 0 until variadicCount) {
                    val expression: Expression = expressions[expressionIndex]
                    val result: String = translateExpression(expression, indentation = increasedIndentation)

                    translations.add(result)

                    expressionIndex += 1
                }
            }
        }
    }

    var result: String = "("

    if (shouldAddNewlines) {
        result += "\n${indentation}"
    }

    val separator: String = if (shouldAddNewlines) { ",\n${indentation}" } else { ", " }

    result += translations.joinToString(separator = separator) + ")"

    return result
}

private fun KotlinTranslator.translateStringLiteral(value: String): String {
    return "\"${value}\""
}

private fun KotlinTranslator.translateCharacterLiteral(value: String): String {
    return "'${value}'"
}

private fun KotlinTranslator.translateInterpolatedStringLiteralExpression(
    expressions: MutableList<Expression>,
    indentation: String)
    : String
{
    var result: String = "\""

    for (expression in expressions) {
        if (expression is Expression.LiteralStringExpression) {
            val string: String = expression.value
            if (string == "\"\"") {
                continue
            }
            result += string
        }
        else {
            result += "${" + translateExpression(expression, indentation = indentation) + "}"
        }
    }

    result += "\""

    return result
}

private fun KotlinTranslator.translateSubtrees(
    subtrees: MutableList<Statement>,
    indentation: String,
    limitForAddingNewlines: Int = 0)
    : String
{
    return ""
}

private fun KotlinTranslator.translateSubtree(subtree: Statement, indentation: String): String {
    return ""
}

private fun KotlinTranslator.increaseIndentation(indentation: String): String {
    return indentation + KotlinTranslator.indentationString
}

private fun KotlinTranslator.decreaseIndentation(indentation: String): String {
    return indentation.dropLast(KotlinTranslator.indentationString.length)
}

data class KotlinTranslatorError(
    val errorMessage: String,
    val ast: Statement
): Exception() {
    override fun toString(): String {
        var nodeDescription: String = ""
        ast.prettyPrint(horizontalLimit = 100, printFunction = { nodeDescription += it })
        return "Error: failed to translate Gryphon AST into Kotlin.\n" + errorMessage + ".\n" + "Thrown when translating the following AST node:\n${nodeDescription}"
    }
}

internal fun unexpectedASTStructureError(errorMessage: String, ast: Statement): String {
    val error: KotlinTranslatorError = KotlinTranslatorError(errorMessage = errorMessage, ast = ast)
    Compiler.handleError(error)
    return KotlinTranslator.errorTranslation
}
