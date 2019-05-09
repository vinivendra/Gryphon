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
