open class KotlinTranslator {
    companion object {
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

        var indentationString: String = "\t"
        val errorTranslation: String = "<<Error>>"
        val lineLimit: Int = 100
    }

    data class FunctionTranslation(
        val swiftAPIName: String,
        val typeName: String,
        val prefix: String,
        val parameters: MutableList<String>
    )

    constructor() {
    }

    public fun translateAST(sourceFile: GryphonAST): String {
        val declarationsTranslation: String = translateSubtrees(subtrees = sourceFile.declarations, indentation = "")
        val indentation: String = increaseIndentation("")
        val statementsTranslation: String = translateSubtrees(subtrees = sourceFile.statements, indentation = indentation)
        var result: String = declarationsTranslation

        if (statementsTranslation.isEmpty()) {
            return result
        }

        if (!declarationsTranslation.isEmpty()) {
            result += "\n"
        }

        result += "fun main(args: Array<String>) {\n${statementsTranslation}}\n"

        return result
    }

    data class TreeAndTranslation(
        val subtree: Statement,
        val translation: String
    )

    private fun translateSubtrees(
        subtrees: MutableList<Statement>,
        indentation: String,
        limitForAddingNewlines: Int = 0)
        : String
    {
        val treesAndTranslations: MutableList<KotlinTranslator.TreeAndTranslation> = subtrees.map { TreeAndTranslation(subtree = it, translation = translateSubtree(it, indentation = indentation)) }.toMutableList().filter { !it.translation.isEmpty() }.toMutableList()

        if (treesAndTranslations.size <= limitForAddingNewlines) {
            return treesAndTranslations.map { it.translation }.toMutableList().joinToString(separator = "")
        }

        val treesAndTranslationsWithoutFirst: MutableList<KotlinTranslator.TreeAndTranslation> = treesAndTranslations.drop(1).toMutableList<TreeAndTranslation>()
        var result: String = ""

        for ((currentSubtree, nextSubtree) in treesAndTranslations.zip(treesAndTranslationsWithoutFirst)) {
            result += currentSubtree.translation

            if (currentSubtree.subtree is Statement.VariableDeclaration && nextSubtree.subtree is Statement.VariableDeclaration) {
                continue
            }

            if (currentSubtree.subtree is Statement.ExpressionStatement && nextSubtree.subtree is Statement.ExpressionStatement) {
                val currentExpression: Expression = currentSubtree.subtree.expression
                val nextExpression: Expression = nextSubtree.subtree.expression
                if (currentExpression is Expression.CallExpression && nextExpression is Expression.CallExpression) {
                    continue
                }
            }

            if (currentSubtree.subtree is Statement.ExpressionStatement && nextSubtree.subtree is Statement.ExpressionStatement) {
                val currentExpression: Expression = currentSubtree.subtree.expression
                val nextExpression: Expression = nextSubtree.subtree.expression
                if (currentExpression is Expression.TemplateExpression && nextExpression is Expression.TemplateExpression) {
                    continue
                }
            }

            if (currentSubtree.subtree is Statement.ExpressionStatement && nextSubtree.subtree is Statement.ExpressionStatement) {
                val currentExpression: Expression = currentSubtree.subtree.expression
                val nextExpression: Expression = nextSubtree.subtree.expression
                if (currentExpression is Expression.LiteralCodeExpression && nextExpression is Expression.LiteralCodeExpression) {
                    continue
                }
            }

            if (currentSubtree.subtree is Statement.AssignmentStatement && nextSubtree.subtree is Statement.AssignmentStatement) {
                continue
            }

            if (currentSubtree.subtree is Statement.TypealiasDeclaration && nextSubtree.subtree is Statement.TypealiasDeclaration) {
                continue
            }

            if (currentSubtree.subtree is Statement.DoStatement && nextSubtree.subtree is Statement.CatchStatement) {
                continue
            }

            if (currentSubtree.subtree is Statement.CatchStatement && nextSubtree.subtree is Statement.CatchStatement) {
                continue
            }

            result += "\n"
        }

        val lastSubtree: TreeAndTranslation? = treesAndTranslations.lastOrNull()

        if (lastSubtree != null) {
            result += lastSubtree.translation
        }

        return result
    }

    private fun translateSubtree(subtree: Statement, indentation: String): String {
        val result: String
        when (subtree) {
            is Statement.ImportDeclaration -> result = ""
            is Statement.ExtensionDeclaration -> return unexpectedASTStructureError(
    "Extension structure should have been removed in a transpilation pass",
    ast = subtree)
            is Statement.DeferStatement -> return unexpectedASTStructureError(
    "Defer statements are only supported as top-level statements in function bodies",
    ast = subtree)
            is Statement.TypealiasDeclaration -> {
                val identifier: String = subtree.identifier
                val typeName: String = subtree.typeName
                val isImplicit: Boolean = subtree.isImplicit

                result = translateTypealias(
                    identifier = identifier,
                    typeName = typeName,
                    isImplicit = isImplicit,
                    indentation = indentation)
            }
            is Statement.ClassDeclaration -> {
                val className: String = subtree.className
                val inherits: MutableList<String> = subtree.inherits
                val members: MutableList<Statement> = subtree.members

                result = translateClassDeclaration(
                    className = className,
                    inherits = inherits,
                    members = members,
                    indentation = indentation)
            }
            is Statement.StructDeclaration -> {
                val annotations: String? = subtree.annotations
                val structName: String = subtree.structName
                val inherits: MutableList<String> = subtree.inherits
                val members: MutableList<Statement> = subtree.members

                result = translateStructDeclaration(
                    annotations = annotations,
                    structName = structName,
                    inherits = inherits,
                    members = members,
                    indentation = indentation)
            }
            is Statement.CompanionObject -> {
                val members: MutableList<Statement> = subtree.members
                result = translateCompanionObject(members = members, indentation = indentation)
            }
            is Statement.EnumDeclaration -> {
                val access: String? = subtree.access
                val enumName: String = subtree.enumName
                val inherits: MutableList<String> = subtree.inherits
                val elements: MutableList<EnumElement> = subtree.elements
                val members: MutableList<Statement> = subtree.members
                val isImplicit: Boolean = subtree.isImplicit

                result = translateEnumDeclaration(
                    access = access,
                    enumName = enumName,
                    inherits = inherits,
                    elements = elements,
                    members = members,
                    isImplicit = isImplicit,
                    indentation = indentation)
            }
            is Statement.DoStatement -> {
                val statements: MutableList<Statement> = subtree.statements
                result = translateDoStatement(statements = statements, indentation = indentation)
            }
            is Statement.CatchStatement -> {
                val variableDeclaration: VariableDeclarationData? = subtree.variableDeclaration
                val statements: MutableList<Statement> = subtree.statements
                result = translateCatchStatement(
                    variableDeclaration = variableDeclaration,
                    statements = statements,
                    indentation = indentation)
            }
            is Statement.ForEachStatement -> {
                val collection: Expression = subtree.collection
                val variable: Expression = subtree.variable
                val statements: MutableList<Statement> = subtree.statements

                result = translateForEachStatement(
                    collection = collection,
                    variable = variable,
                    statements = statements,
                    indentation = indentation)
            }
            is Statement.WhileStatement -> {
                val expression: Expression = subtree.expression
                val statements: MutableList<Statement> = subtree.statements
                result = translateWhileStatement(
                    expression = expression,
                    statements = statements,
                    indentation = indentation)
            }
            is Statement.FunctionDeclaration -> {
                val functionDeclaration: FunctionDeclarationData = subtree.data
                result = translateFunctionDeclaration(functionDeclaration = functionDeclaration, indentation = indentation)
            }
            is Statement.ProtocolDeclaration -> {
                val protocolName: String = subtree.protocolName
                val members: MutableList<Statement> = subtree.members
                result = translateProtocolDeclaration(
                    protocolName = protocolName,
                    members = members,
                    indentation = indentation)
            }
            is Statement.ThrowStatement -> {
                val expression: Expression = subtree.expression
                result = translateThrowStatement(expression = expression, indentation = indentation)
            }
            is Statement.VariableDeclaration -> {
                val variableDeclaration: VariableDeclarationData = subtree.data
                result = translateVariableDeclaration(variableDeclaration, indentation = indentation)
            }
            is Statement.AssignmentStatement -> {
                val leftHand: Expression = subtree.leftHand
                val rightHand: Expression = subtree.rightHand
                result = translateAssignmentStatement(leftHand = leftHand, rightHand = rightHand, indentation = indentation)
            }
            is Statement.IfStatement -> {
                val ifStatement: IfStatementData = subtree.data
                result = translateIfStatement(ifStatement = ifStatement, indentation = indentation)
            }
            is Statement.SwitchStatement -> {
                val convertsToExpression: Statement? = subtree.convertsToExpression
                val expression: Expression = subtree.expression
                val cases: MutableList<SwitchCase> = subtree.cases

                result = translateSwitchStatement(
                    convertsToExpression = convertsToExpression,
                    expression = expression,
                    cases = cases,
                    indentation = indentation)
            }
            is Statement.ReturnStatement -> {
                val expression: Expression? = subtree.expression
                result = translateReturnStatement(expression = expression, indentation = indentation)
            }
            is Statement.BreakStatement -> result = "${indentation}break\n"
            is Statement.ContinueStatement -> result = "${indentation}continue\n"
            is Statement.ExpressionStatement -> {
                val expression: Expression = subtree.expression
                val expressionTranslation: String = translateExpression(expression, indentation = indentation)
                if (!expressionTranslation.isEmpty()) {
                    return indentation + expressionTranslation + "\n"
                }
                else {
                    return "\n"
                }
            }
            is Statement.Error -> return KotlinTranslator.errorTranslation
        }
        return result
    }

    private fun translateEnumDeclaration(
        access: String?,
        enumName: String,
        inherits: MutableList<String>,
        elements: MutableList<EnumElement>,
        members: MutableList<Statement>,
        isImplicit: Boolean,
        indentation: String)
        : String
    {
        val isEnumClass: Boolean = KotlinTranslator.enumClasses.contains(enumName)
        val accessString: String = access ?: ""
        val enumString: String = if (isEnumClass) { "enum" } else { "sealed" }
        var result: String = "${indentation}${accessString} ${enumString} class " + enumName

        if (!inherits.isEmpty()) {
            var translatedInheritedTypes: MutableList<String> = inherits.map { translateType(it) }.toMutableList()
            translatedInheritedTypes = translatedInheritedTypes.map { if (KotlinTranslator.protocols.contains(it)) { it } else { it + "()" } }.toMutableList()
            result += ": ${translatedInheritedTypes.joinToString(separator = ", ")}"
        }

        result += " {\n"

        val increasedIndentation: String = increaseIndentation(indentation)
        var casesTranslation: String = ""

        if (isEnumClass) {
            casesTranslation += elements.map { increasedIndentation + (if (it.annotations == null) { "" } else { "${it.annotations!!} " }) + it.name }.toMutableList().joinToString(separator = ",\n") + ";\n"
        }
        else {
            for (element in elements) {
                casesTranslation += translateEnumElementDeclaration(
                    enumName = enumName,
                    element = element,
                    indentation = increasedIndentation)
            }
        }

        result += casesTranslation

        val membersTranslation: String = translateSubtrees(subtrees = members, indentation = increasedIndentation)

        if (!casesTranslation.isEmpty() && !membersTranslation.isEmpty()) {
            result += "\n"
        }

        result += "${membersTranslation}${indentation}}\n"

        return result
    }

    private fun translateEnumElementDeclaration(
        enumName: String,
        element: EnumElement,
        indentation: String)
        : String
    {
        val capitalizedElementName: String = element.name.capitalizedAsCamelCase()
        val annotationsString: String = if (element.annotations == null) { "" } else { "${element.annotations!!} " }
        val result: String = "${indentation}${annotationsString}class ${capitalizedElementName}"

        if (element.associatedValues.isEmpty()) {
            return result + ": ${enumName}()\n"
        }
        else {
            val associatedValuesString: String = element.associatedValues.map { "val ${it.label}: ${translateType(it.typeName)}" }.toMutableList().joinToString(separator = ", ")
            return result + "(${associatedValuesString}): ${enumName}()\n"
        }
    }

    private fun translateProtocolDeclaration(
        protocolName: String,
        members: MutableList<Statement>,
        indentation: String)
        : String
    {
        var result: String = "${indentation}interface ${protocolName} {\n"
        val contents: String = translateSubtrees(subtrees = members, indentation = increaseIndentation(indentation))

        result += contents

        result += "${indentation}}\n"

        return result
    }

    private fun translateTypealias(
        identifier: String,
        typeName: String,
        isImplicit: Boolean,
        indentation: String)
        : String
    {
        val translatedType: String = translateType(typeName)
        return "${indentation}typealias ${identifier} = ${translatedType}\n"
    }

    private fun translateClassDeclaration(
        className: String,
        inherits: MutableList<String>,
        members: MutableList<Statement>,
        indentation: String)
        : String
    {
        var result: String = "${indentation}open class ${className}"

        if (!inherits.isEmpty()) {
            val translatedInheritances: MutableList<String> = inherits.map { translateType(it) }.toMutableList()
            result += ": " + translatedInheritances.joinToString(separator = ", ")
        }

        result += " {\n"

        val increasedIndentation: String = increaseIndentation(indentation)
        val classContents: String = translateSubtrees(subtrees = members, indentation = increasedIndentation)

        result += classContents + "${indentation}}\n"

        return result
    }

    private fun translateStructDeclaration(
        annotations: String?,
        structName: String,
        inherits: MutableList<String>,
        members: MutableList<Statement>,
        indentation: String)
        : String
    {
        val increasedIndentation: String = increaseIndentation(indentation)
        val annotationsString: String = annotations?.let { "${indentation}${it}\n" } ?: ""
        var result: String = "${annotationsString}${indentation}data class ${structName}(\n"
        val properties: MutableList<Statement> = members.filter { statementIsStructProperty(it) }.toMutableList()
        val otherMembers: MutableList<Statement> = members.filter { !statementIsStructProperty(it) }.toMutableList()
        val propertyTranslations: MutableList<String> = properties.map { translateSubtree(it, indentation = increasedIndentation).dropLast(1) }.toMutableList()
        val propertiesTranslation: String = propertyTranslations.joinToString(separator = ",\n")

        result += propertiesTranslation + "\n${indentation})"

        if (!inherits.isEmpty()) {
            var translatedInheritedTypes: MutableList<String> = inherits.map { translateType(it) }.toMutableList()
            translatedInheritedTypes = translatedInheritedTypes.map { if (KotlinTranslator.protocols.contains(it)) { it } else { it + "()" } }.toMutableList()
            result += ": ${translatedInheritedTypes.joinToString(separator = ", ")}"
        }

        val otherMembersTranslation: String = translateSubtrees(subtrees = otherMembers, indentation = increasedIndentation)

        if (!otherMembersTranslation.isEmpty()) {
            result += " {\n${otherMembersTranslation}${indentation}}\n"
        }
        else {
            result += "\n"
        }

        return result
    }

    private fun statementIsStructProperty(statement: Statement): Boolean {
        if (statement is Statement.VariableDeclaration) {
            val variableDeclaration: VariableDeclarationData = statement.data
            if (variableDeclaration.getter == null && variableDeclaration.setter == null && !variableDeclaration.isStatic) {
                return true
            }
        }
        return false
    }

    private fun translateCompanionObject(
        members: MutableList<Statement>,
        indentation: String)
        : String
    {
        var result: String = "${indentation}companion object {\n"
        val increasedIndentation: String = increaseIndentation(indentation)
        val contents: String = translateSubtrees(subtrees = members, indentation = increasedIndentation)

        result += contents + "${indentation}}\n"

        return result
    }

    private fun translateFunctionDeclaration(
        functionDeclaration: FunctionDeclarationData,
        indentation: String,
        shouldAddNewlines: Boolean = false)
        : String
    {
        if (functionDeclaration.isImplicit) {
            return ""
        }

        var indentation: String = indentation
        var result: String = indentation
        val isInit: Boolean = (functionDeclaration.prefix == "init")

        if (isInit) {
            result += "constructor("
        }
        else if (functionDeclaration.prefix == "invoke") {
            result += "operator fun invoke("
        }
        else {
            val annotations: String? = functionDeclaration.annotations

            if (annotations != null) {
                result += annotations + " "
            }

            val access: String? = functionDeclaration.access

            if (access != null) {
                result += access + " "
            }

            result += "fun "

            val extensionType: String? = functionDeclaration.extendsType

            if (extensionType != null) {
                val translatedExtensionType: String = translateType(extensionType)
                val companionString: String = if (functionDeclaration.isStatic) { "Companion." } else { "" }
                val genericString: String
                val genericExtensionIndex: Int? = translatedExtensionType.indexOrNull('<')

                if (genericExtensionIndex != null) {
                    val genericExtensionString: String = translatedExtensionType.suffix(startIndex = genericExtensionIndex)
                    var genericTypes: MutableList<String> = genericExtensionString.drop(1).dropLast(1).split(separator = ',').map { it }.toMutableList()

                    genericTypes.addAll(functionDeclaration.genericTypes)

                    genericString = "<${genericTypes.joinToString(separator = ", ")}> "
                }
                else if (!functionDeclaration.genericTypes.isEmpty()) {
                    genericString = "<${functionDeclaration.genericTypes.joinToString(separator = ", ")}> "
                }
                else {
                    genericString = ""
                }

                result += genericString + translatedExtensionType + "." + companionString
            }

            result += functionDeclaration.prefix + "("
        }

        val returnString: String

        if (functionDeclaration.returnType != "()" && !isInit) {
            val translatedReturnType: String = translateType(functionDeclaration.returnType)
            returnString = ": ${translatedReturnType}"
        }
        else {
            returnString = ""
        }

        val parameterStrings: MutableList<String> = functionDeclaration.parameters.map { translateFunctionDeclarationParameter(it, indentation = indentation) }.toMutableList()

        if (!shouldAddNewlines) {
            result += parameterStrings.joinToString(separator = ", ") + ")" + returnString + " {\n"
            if (result.length >= KotlinTranslator.lineLimit) {
                return translateFunctionDeclaration(
                    functionDeclaration = functionDeclaration,
                    indentation = indentation,
                    shouldAddNewlines = true)
            }
        }
        else {
            val parameterIndentation: String = increaseIndentation(indentation)
            val parametersString: String = parameterStrings.joinToString(separator = ",\n${parameterIndentation}")

            result += "\n${parameterIndentation}" + parametersString + ")\n"

            if (!returnString.isEmpty()) {
                result += "${parameterIndentation}${returnString}\n"
            }

            result += "${indentation}{\n"
        }

        val statements: MutableList<Statement>? = functionDeclaration.statements

        statements ?: return result + "\n"

        val innerDeferStatements: MutableList<Statement> = statements.flatMap { extractInnerDeferStatements(it) }.toMutableList()
        val nonDeferStatements: MutableList<Statement> = statements.filter { !isDeferStatement(it) }.toMutableList()

        indentation = increaseIndentation(indentation)

        if (!innerDeferStatements.isEmpty()) {
            val increasedIndentation: String = increaseIndentation(indentation)

            result += "${indentation}try {\n"

            result += translateSubtrees(
                nonDeferStatements,
                indentation = increasedIndentation,
                limitForAddingNewlines = 3)

            result += "${indentation}}\n"

            result += "${indentation}finally {\n"

            result += translateSubtrees(
                innerDeferStatements,
                indentation = increasedIndentation,
                limitForAddingNewlines = 3)

            result += "${indentation}}\n"
        }
        else {
            result += translateSubtrees(statements, indentation = indentation, limitForAddingNewlines = 3)
        }

        indentation = decreaseIndentation(indentation)

        result += indentation + "}\n"

        return result
    }

    private fun isDeferStatement(maybeDeferStatement: Statement): Boolean {
        if (maybeDeferStatement is Statement.DeferStatement) {
            return true
        }
        else {
            return false
        }
    }

    private fun extractInnerDeferStatements(
        maybeDeferStatement: Statement)
        : MutableList<Statement>
    {
        if (maybeDeferStatement is Statement.DeferStatement) {
            val innerStatements: MutableList<Statement> = maybeDeferStatement.statements
            return innerStatements
        }
        else {
            return mutableListOf()
        }
    }

    private fun translateFunctionDeclarationParameter(
        parameter: FunctionParameter,
        indentation: String)
        : String
    {
        val labelAndTypeString: String = parameter.label + ": " + translateType(parameter.typeName)
        val defaultValue: Expression? = parameter.value
        if (defaultValue != null) {
            return labelAndTypeString + " = " + translateExpression(defaultValue, indentation = indentation)
        }
        else {
            return labelAndTypeString
        }
    }

    private fun translateDoStatement(
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

    private fun translateCatchStatement(
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

    private fun translateForEachStatement(
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

    private fun translateWhileStatement(
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

    private fun translateIfStatement(
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

    private fun conditionToExpression(condition: IfStatementData.IfCondition): Expression? {
        if (condition is IfStatementData.IfCondition.Condition) {
            val expression: Expression = condition.expression
            return expression
        }
        else {
            return null
        }
    }

    private fun translateSwitchStatement(
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

    private fun translateSwitchCaseExpression(
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

    private fun translateThrowStatement(expression: Expression, indentation: String): String {
        val expressionString: String = translateExpression(expression, indentation = indentation)
        return "${indentation}throw ${expressionString}\n"
    }

    private fun translateReturnStatement(expression: Expression?, indentation: String): String {
        if (expression != null) {
            val expressionString: String = translateExpression(expression, indentation = indentation)
            return "${indentation}return ${expressionString}\n"
        }
        else {
            return "${indentation}return\n"
        }
    }

    private fun translateVariableDeclaration(
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

    private fun translateAssignmentStatement(
        leftHand: Expression,
        rightHand: Expression,
        indentation: String)
        : String
    {
        val leftTranslation: String = translateExpression(leftHand, indentation = indentation)
        val rightTranslation: String = translateExpression(rightHand, indentation = indentation)
        return "${indentation}${leftTranslation} = ${rightTranslation}\n"
    }

    private fun translateExpression(expression: Expression, indentation: String): String {
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

    private fun translateSubscriptExpression(
        subscriptedExpression: Expression,
        indexExpression: Expression,
        typeName: String,
        indentation: String)
        : String
    {
        return translateExpression(subscriptedExpression, indentation = indentation) + "[${translateExpression(indexExpression, indentation = indentation)}]"
    }

    private fun translateArrayExpression(
        elements: MutableList<Expression>,
        typeName: String,
        indentation: String)
        : String
    {
        val expressionsString: String = elements.map { translateExpression(it, indentation = indentation) }.toMutableList().joinToString(separator = ", ")
        return "mutableListOf(${expressionsString})"
    }

    private fun translateDictionaryExpression(
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

    private fun translateReturnExpression(expression: Expression?, indentation: String): String {
        if (expression != null) {
            val expressionString: String = translateExpression(expression, indentation = indentation)
            return "return ${expressionString}"
        }
        else {
            return "return"
        }
    }

    private fun translateDotSyntaxCallExpression(
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

    private fun translateBinaryOperatorExpression(
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

    private fun translatePrefixUnaryExpression(
        subExpression: Expression,
        operatorSymbol: String,
        typeName: String,
        indentation: String)
        : String
    {
        val expressionTranslation: String = translateExpression(subExpression, indentation = indentation)
        return operatorSymbol + expressionTranslation
    }

    private fun translatePostfixUnaryExpression(
        subExpression: Expression,
        operatorSymbol: String,
        typeName: String,
        indentation: String)
        : String
    {
        val expressionTranslation: String = translateExpression(subExpression, indentation = indentation)
        return expressionTranslation + operatorSymbol
    }

    private fun translateIfExpression(
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

    private fun translateCallExpression(
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

        val functionTranslation: FunctionTranslation?

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

    private fun translateParameters(
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

    private fun translateClosureExpression(
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

    private fun translateLiteralCodeExpression(string: String): String {
        return string.removingBackslashEscapes
    }

    private fun translateTemplateExpression(
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

    private fun translateDeclarationReferenceExpression(
        declarationReferenceExpression: DeclarationReferenceData)
        : String
    {
        return declarationReferenceExpression.identifier.takeWhile { it != '(' }
    }

    private fun translateTupleExpression(
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

    private fun translateParameter(
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

    private fun translateTupleShuffleExpression(
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

    private fun translateStringLiteral(value: String): String {
        return "\"${value}\""
    }

    private fun translateCharacterLiteral(value: String): String {
        return "'${value}'"
    }

    private fun translateInterpolatedStringLiteralExpression(
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
                val startDelimiter: String = "\${"
                result += startDelimiter + translateExpression(expression, indentation = indentation) + "}"
            }
        }

        result += "\""

        return result
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

    private fun increaseIndentation(indentation: String): String {
        return indentation + KotlinTranslator.indentationString
    }

    private fun decreaseIndentation(indentation: String): String {
        return indentation.dropLast(KotlinTranslator.indentationString.length)
    }
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
