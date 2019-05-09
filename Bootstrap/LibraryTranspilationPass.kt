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
