data class TranspilationTemplate(
    val expression: Expression,
    val string: String
) {
    companion object {
        var templates: MutableList<TranspilationTemplate> = mutableListOf()
    }
}

open class RecordTemplatesTranspilationPass: TranspilationPass {
    constructor(ast: GryphonAST): super(ast) { }

    override internal fun replaceFunctionDeclaration(
        functionDeclaration: FunctionDeclarationData)
        : MutableList<Statement>
    {
        val statements: MutableList<Statement>? = functionDeclaration.statements
        if (functionDeclaration.prefix == "gryphonTemplates" && functionDeclaration.parameters.isEmpty() && statements != null) {
            val topLevelExpressions: MutableList<Expression> = mutableListOf()

            for (statement in statements) {
                if (statement is Statement.ExpressionStatement) {
                    val expression: Expression = statement.expression
                    topLevelExpressions.add(expression)
                }
            }

            var previousExpression: Expression? = null

            for (expression in topLevelExpressions) {
                val templateExpression: Expression? = previousExpression
                if (templateExpression != null) {
                    val literalString: String? = getStringLiteralOrSum(expression)

                    if (literalString == null) {
                        continue
                    }

                    val cleanString: String = literalString.removingBackslashEscapes

                    TranspilationTemplate.templates.add(0, TranspilationTemplate(expression = templateExpression, string = cleanString))

                    previousExpression = null
                }
                else {
                    previousExpression = expression
                }
            }

            return mutableListOf()
        }
        return super.replaceFunctionDeclaration(functionDeclaration)
    }

    private fun getStringLiteralOrSum(expression: Expression): String? {
        if (expression is Expression.LiteralStringExpression) {
            val value: String = expression.value
            return value
        }
        if (expression is Expression.BinaryOperatorExpression && expression.operatorSymbol == "+" && expression.typeName == "String") {
            val leftExpression: Expression = expression.leftExpression
            val rightExpression: Expression = expression.rightExpression
            val leftString: String? = getStringLiteralOrSum(leftExpression)
            val rightString: String? = getStringLiteralOrSum(rightExpression)

            if (leftString != null && rightString != null) {
                return leftString + rightString
            }
        }
        return null
    }
}

internal fun Expression.matches(template: Expression): MutableMap<String, Expression>? {
    val result: MutableMap<String, Expression> = mutableMapOf()
    val success: Boolean = matches(template, result)
    if (success) {
        return result
    }
    else {
        return null
    }
}

private fun Expression.matches(
    template: Expression,
    matches: MutableMap<String, Expression>)
    : Boolean
{
    if (template is Expression.DeclarationReferenceExpression) {
        val templateExpression: DeclarationReferenceData = template.data
        if (templateExpression.identifier.startsWith("_") && this.isOfType(templateExpression.typeName)) {
            matches[templateExpression.identifier] = this
            return true
        }
    }
    if (this is Expression.LiteralCodeExpression && template is Expression.LiteralCodeExpression) {
        val leftString: String = this.string
        val rightString: String = template.string
        return leftString == rightString
    }
    else if (this is Expression.ParenthesesExpression && template is Expression.ParenthesesExpression) {
        val leftExpression: Expression = this.expression
        val rightExpression: Expression = template.expression
        return leftExpression.matches(rightExpression, matches)
    }
    else if (this is Expression.ForceValueExpression && template is Expression.ForceValueExpression) {
        val leftExpression: Expression = this.expression
        val rightExpression: Expression = template.expression
        return leftExpression.matches(rightExpression, matches)
    }
    else if (this is Expression.DeclarationReferenceExpression && template is Expression.DeclarationReferenceExpression) {
        val leftExpression: DeclarationReferenceData = this.data
        val rightExpression: DeclarationReferenceData = template.data
        return leftExpression.identifier == rightExpression.identifier && leftExpression.typeName.isSubtype(superType = rightExpression.typeName) && leftExpression.isImplicit == rightExpression.isImplicit
    }
    else if (this is Expression.OptionalExpression && template is Expression.DeclarationReferenceExpression) {
        val leftExpression: Expression = this.expression
        return leftExpression.matches(template, matches)
    }
    else if (this is Expression.TypeExpression && template is Expression.TypeExpression) {
        val leftType: String = this.typeName
        val rightType: String = template.typeName
        return leftType.isSubtype(superType = rightType)
    }
    else if (this is Expression.TypeExpression && template is Expression.DeclarationReferenceExpression) {
        val leftType: String = this.typeName
        val rightExpression: DeclarationReferenceData = template.data

        if (!(declarationExpressionMatchesImplicitTypeExpression(rightExpression))) {
            return false
        }

        val expressionType: String = rightExpression.typeName.dropLast(".Type".length)

        return leftType.isSubtype(superType = expressionType)
    }
    else if (this is Expression.DeclarationReferenceExpression && template is Expression.TypeExpression) {
        val leftExpression: DeclarationReferenceData = this.data
        val rightType: String = template.typeName

        if (!(declarationExpressionMatchesImplicitTypeExpression(leftExpression))) {
            return false
        }

        val expressionType: String = leftExpression.typeName.dropLast(".Type".length)

        return expressionType.isSubtype(superType = rightType)
    }
    else if (this is Expression.SubscriptExpression && template is Expression.SubscriptExpression) {
        val leftSubscriptedExpression: Expression = this.subscriptedExpression
        val leftIndexExpression: Expression = this.indexExpression
        val leftType: String = this.typeName
        val rightSubscriptedExpression: Expression = template.subscriptedExpression
        val rightIndexExpression: Expression = template.indexExpression
        val rightType: String = template.typeName

        return leftSubscriptedExpression.matches(rightSubscriptedExpression, matches) && leftIndexExpression.matches(rightIndexExpression, matches) && leftType.isSubtype(superType = rightType)
    }
    else if (this is Expression.ArrayExpression && template is Expression.ArrayExpression) {
        val leftElements: MutableList<Expression> = this.elements
        val leftType: String = this.typeName
        val rightElements: MutableList<Expression> = template.elements
        val rightType: String = template.typeName
        var result: Boolean = true

        for ((leftElement, rightElement) in leftElements.zip(rightElements)) {
            result = result && leftElement.matches(rightElement, matches)
        }

        return result && (leftType.isSubtype(superType = rightType))
    }
    else if (this is Expression.DotExpression && template is Expression.DotExpression) {
        val leftLeftExpression: Expression = this.leftExpression
        val leftRightExpression: Expression = this.rightExpression
        val rightLeftExpression: Expression = template.leftExpression
        val rightRightExpression: Expression = template.rightExpression

        return leftLeftExpression.matches(rightLeftExpression, matches) && leftRightExpression.matches(rightRightExpression, matches)
    }
    else if (this is Expression.BinaryOperatorExpression && template is Expression.BinaryOperatorExpression) {
        val leftLeftExpression: Expression = this.leftExpression
        val leftRightExpression: Expression = this.rightExpression
        val leftOperatorSymbol: String = this.operatorSymbol
        val leftType: String = this.typeName
        val rightLeftExpression: Expression = template.leftExpression
        val rightRightExpression: Expression = template.rightExpression
        val rightOperatorSymbol: String = template.operatorSymbol
        val rightType: String = template.typeName

        return leftLeftExpression.matches(rightLeftExpression, matches) && leftRightExpression.matches(rightRightExpression, matches) && (leftOperatorSymbol == rightOperatorSymbol) && (leftType.isSubtype(superType = rightType))
    }
    else if (this is Expression.PrefixUnaryExpression && template is Expression.PrefixUnaryExpression) {
        val leftExpression: Expression = this.subExpression
        val leftOperatorSymbol: String = this.operatorSymbol
        val leftType: String = this.typeName
        val rightExpression: Expression = template.subExpression
        val rightOperatorSymbol: String = template.operatorSymbol
        val rightType: String = template.typeName

        return leftExpression.matches(rightExpression, matches) && (leftOperatorSymbol == rightOperatorSymbol) && (leftType.isSubtype(superType = rightType))
    }
    else if (this is Expression.PostfixUnaryExpression && template is Expression.PostfixUnaryExpression) {
        val leftExpression: Expression = this.subExpression
        val leftOperatorSymbol: String = this.operatorSymbol
        val leftType: String = this.typeName
        val rightExpression: Expression = template.subExpression
        val rightOperatorSymbol: String = template.operatorSymbol
        val rightType: String = template.typeName

        return leftExpression.matches(rightExpression, matches) && (leftOperatorSymbol == rightOperatorSymbol) && (leftType.isSubtype(superType = rightType))
    }
    else if (this is Expression.CallExpression && template is Expression.CallExpression) {
        val leftCallExpression: CallExpressionData = this.data
        val rightCallExpression: CallExpressionData = template.data
        return leftCallExpression.function.matches(rightCallExpression.function, matches) && leftCallExpression.parameters.matches(rightCallExpression.parameters, matches) && leftCallExpression.typeName.isSubtype(superType = rightCallExpression.typeName)
    }
    else if (this is Expression.LiteralIntExpression && template is Expression.LiteralIntExpression) {
        val leftValue: Long = this.value
        val rightValue: Long = template.value
        return leftValue == rightValue
    }
    else if (this is Expression.LiteralDoubleExpression && template is Expression.LiteralDoubleExpression) {
        val leftValue: Double = this.value
        val rightValue: Double = template.value
        return leftValue == rightValue
    }
    else if (this is Expression.LiteralBoolExpression && template is Expression.LiteralBoolExpression) {
        val leftValue: Boolean = this.value
        val rightValue: Boolean = template.value
        return leftValue == rightValue
    }
    else if (this is Expression.LiteralStringExpression && template is Expression.LiteralStringExpression) {
        val leftValue: String = this.value
        val rightValue: String = template.value
        return leftValue == rightValue
    }
    else if (this is Expression.LiteralStringExpression && template is Expression.DeclarationReferenceExpression) {
        val leftValue: String = this.value
        val characterExpression: Expression = Expression.LiteralCharacterExpression(value = leftValue)
        return characterExpression.matches(template, matches)
    }
    if (this is Expression.NilLiteralExpression && template is Expression.NilLiteralExpression) {
        return true
    }
    else if (this is Expression.InterpolatedStringLiteralExpression && template is Expression.InterpolatedStringLiteralExpression) {
        val leftExpressions: MutableList<Expression> = this.expressions
        val rightExpressions: MutableList<Expression> = template.expressions
        var result: Boolean = true

        for ((leftExpression, rightExpression) in leftExpressions.zip(rightExpressions)) {
            result = result && leftExpression.matches(rightExpression, matches)
        }

        return result
    }
    else if (this is Expression.TupleExpression && template is Expression.TupleExpression) {
        val leftPairs: MutableList<LabeledExpression> = this.pairs
        val rightPairs: MutableList<LabeledExpression> = template.pairs
        val onlyLeftPair: LabeledExpression? = leftPairs.firstOrNull()
        val onlyRightPair: LabeledExpression? = rightPairs.firstOrNull()

        if (leftPairs.size == 1 && onlyLeftPair != null && rightPairs.size == 1 && onlyRightPair != null) {
            if (onlyLeftPair.expression is Expression.ParenthesesExpression) {
                val closureExpression: Expression = onlyLeftPair.expression.expression
                if (closureExpression is Expression.ClosureExpression) {
                    if (onlyRightPair.expression is Expression.ParenthesesExpression) {
                        val templateExpression: Expression = onlyRightPair.expression.expression
                        return closureExpression.matches(templateExpression, matches)
                    }
                    else {
                        return closureExpression.matches(onlyRightPair.expression, matches)
                    }
                }
            }
        }

        var result: Boolean = true

        for ((leftPair, rightPair) in leftPairs.zip(rightPairs)) {
            result = result && leftPair.expression.matches(rightPair.expression, matches) && leftPair.label == rightPair.label
        }

        return result
    }
    else if (this is Expression.TupleShuffleExpression && template is Expression.TupleShuffleExpression) {
        val leftLabels: MutableList<String> = this.labels
        val leftIndices: MutableList<TupleShuffleIndex> = this.indices
        val leftExpressions: MutableList<Expression> = this.expressions
        val rightLabels: MutableList<String> = template.labels
        val rightIndices: MutableList<TupleShuffleIndex> = template.indices
        val rightExpressions: MutableList<Expression> = template.expressions
        var result: Boolean = (leftLabels == rightLabels) && (leftIndices == rightIndices)

        for ((leftExpression, rightExpression) in leftExpressions.zip(rightExpressions)) {
            result = result && leftExpression.matches(rightExpression, matches)
        }

        return result
    }
    else {
        return false
    }
}

private fun Expression.declarationExpressionMatchesImplicitTypeExpression(
    expression: DeclarationReferenceData)
    : Boolean
{
    if (expression.identifier == "self" && expression.typeName.endsWith(".Type") && expression.isImplicit) {
        return true
    }
    else {
        return true
    }
}

internal fun Expression.isOfType(superType: String): Boolean {
    val typeName: String? = this.swiftType
    typeName ?: return false
    return typeName.isSubtype(superType = superType)
}

internal fun String.isSubtype(superType: String): Boolean {
    if (this == superType) {
        return true
    }
    else if (this.isEmpty() || superType.isEmpty()) {
        return false
    }
    else if (superType == "Any" || superType == "AnyType" || superType == "Hash" || superType == "Compare" || superType == "MyOptional") {
        return true
    }
    else if (superType == "MyOptional?") {
        return this.endsWith("?")
    }

    if (Utilities.isInEnvelopingParentheses(this) && Utilities.isInEnvelopingParentheses(superType)) {
        val selfContents: String = this.drop(1).dropLast(1)
        val superContents: String = superType.drop(1).dropLast(1)
        val selfComponents: MutableList<String> = selfContents.split(separator = ", ")
        val superComponents: MutableList<String> = superContents.split(separator = ", ")

        if (selfComponents.size != superComponents.size) {
            return false
        }

        for ((selfComponent, superComponent) in selfComponents.zip(superComponents)) {
            if (!(selfComponent.isSubtype(superType = superComponent))) {
                return false
            }
        }

        return true
    }

    val simpleSelf: String = simplifyType(string = this)
    val simpleSuperType: String = simplifyType(string = superType)

    if (simpleSelf != this || simpleSuperType != superType) {
        return simpleSelf.isSubtype(superType = simpleSuperType)
    }

    if (this.lastOrNull()!! == '?' && superType.lastOrNull()!! == '?') {
        val newSelf: String = this.dropLast(1)
        val newSuperType: String = superType.dropLast(1)
        return newSelf.isSubtype(superType = newSuperType)
    }
    else if (superType.lastOrNull()!! == '?') {
        val newSuperType: String = superType.dropLast(1)
        return this.isSubtype(superType = newSuperType)
    }

    if (superType.contains(" -> ")) {
        if (!(this.contains(" -> "))) {
            return false
        }
        return true
    }

    if (this.firstOrNull()!! == '[' && this.lastOrNull()!! == ']' && superType.firstOrNull()!! == '[' && superType.lastOrNull()!! == ']') {
        if (this.contains(":") && superType.contains(":")) {
            val selfKeyValue: MutableList<String> = this.drop(1).dropLast(1).split(separator = " : ")
            val superKeyValue: MutableList<String> = superType.drop(1).dropLast(1).split(separator = " : ")
            val selfKey: String = selfKeyValue[0]
            val selfValue: String = selfKeyValue[1]
            val superKey: String = superKeyValue[0]
            val superValue: String = superKeyValue[1]

            return selfKey.isSubtype(superType = superKey) && selfValue.isSubtype(superType = superValue)
        }
        else if (!this.contains(":") && !superType.contains(":")) {
            val selfElement: String = this.drop(1).dropLast(1)
            val superTypeElement: String = superType.drop(1).dropLast(1)
            return selfElement.isSubtype(superType = superTypeElement)
        }
    }

    if (this.contains("<") && this.lastOrNull()!! == '>' && superType.contains("<") && superType.lastOrNull()!! == '>') {
        val selfStartGenericsIndex: Int = this.indexOf('<')
        val superTypeStartGenericsIndex: Int = superType.indexOf('<')
        val selfGenericArguments: String = this.substring(selfStartGenericsIndex).drop(1).dropLast(1)
        val superTypeGenericArguments: String = superType.substring(superTypeStartGenericsIndex).drop(1).dropLast(1)
        val selfTypeComponents: MutableList<String> = selfGenericArguments.split(separator = ", ")
        val superTypeComponents: MutableList<String> = superTypeGenericArguments.split(separator = ", ")

        if (superTypeComponents.size != selfTypeComponents.size) {
            return false
        }

        for ((selfTypeComponent, superTypeComponent) in selfTypeComponents.zip(superTypeComponents)) {
            if (!selfTypeComponent.isSubtype(superType = superTypeComponent)) {
                return false
            }
        }

        return true
    }
    else if (this.contains("<") && this.lastOrNull()!! == '>') {
        val typeWithoutGenerics: String = this.takeWhile { it != '<' }
        return typeWithoutGenerics.isSubtype(superType = superType)
    }
    else if (superType.contains("<") && superType.lastOrNull()!! == '>') {
        val typeWithoutGenerics: String = superType.takeWhile { it != '<' }
        return this.isSubtype(superType = typeWithoutGenerics)
    }

    return false
}

private fun simplifyType(string: String): String {
    val result: String? = Utilities.getTypeMapping(typeName = string)

    if (result != null) {
        return result
    }

    if (string.startsWith("ArrayClass<") && string.lastOrNull()!! == '>') {
        val elementType: String = string.drop("ArrayClass<".length).dropLast(1)
        return "[${elementType}]"
    }

    if (string.startsWith("Slice<ArrayClass<") && string.endsWith(">>")) {
        val elementType: String = string.drop("Slice<ArrayClass<".length).dropLast(">>".length)
        return "[${elementType}]"
    }
    else if (string.startsWith("ArraySlice<") && string.endsWith(">")) {
        val elementType: String = string.drop("ArraySlice<".length).dropLast(1)
        return "[${elementType}]"
    }

    if (string.startsWith("DictionaryClass<") && string.lastOrNull()!! == '>') {
        val keyValue: MutableList<String> = string.drop("DictionaryClass<".length).dropLast(1).split(separator = ", ")
        val key: String = keyValue[0]
        val value: String = keyValue[1]

        return "[${key} : ${value}]"
    }

    if (string.startsWith("Array<") && string.lastOrNull()!! == '>') {
        val elementType: String = string.drop("Reference<".length).dropLast(1)
        return "[${elementType}]"
    }

    if (Utilities.isInEnvelopingParentheses(string)) {
        return string.drop(1).dropLast(1)
    }

    if (string.startsWith("inout ")) {
        return string.drop("inout ".length)
    }

    if (string.startsWith("__owned ")) {
        return string.drop("__owned ".length)
    }

    return string
}
