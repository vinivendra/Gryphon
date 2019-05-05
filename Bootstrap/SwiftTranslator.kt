class SwiftTranslator {
    data class PatternBindingDeclaration(
        val identifier: String,
        val typeName: String,
        val expression: Expression?
    )

    data class DeclarationInformation(
        val identifier: String,
        val isStandardLibrary: Boolean
    )

    var danglingPatternBindings: MutableList<SwiftTranslator.PatternBindingDeclaration?> = mutableListOf()
    val errorDanglingPatternDeclaration: PatternBindingDeclaration = PatternBindingDeclaration(
        identifier = "<<Error>>",
        typeName = "<<Error>>",
        expression = Expression.Error())
    var sourceFile: SourceFile? = null

    constructor() {
    }
}

internal fun translateBraceStatement(braceStatement: SwiftAST):
	MutableList<Statement>
{
	return mutableListOf()
}

internal fun SwiftTranslator.translateProtocolDeclaration(
    protocolDeclaration: SwiftAST)
    : Statement
{
    if (protocolDeclaration.name != "Protocol") {
        return unexpectedASTStructureError(
            "Trying to translate ${protocolDeclaration.name} as 'Protocol'",
            ast = protocolDeclaration,
            translator = this)
    }

    val protocolName: String? = protocolDeclaration.standaloneAttributes.firstOrNull()

    protocolName ?: return unexpectedASTStructureError("Unrecognized structure", ast = protocolDeclaration, translator = this)

    val members: MutableList<Statement> = mutableListOf<Statement>()

    return Statement.ProtocolDeclaration(protocolName = protocolName, members = members)
}

internal fun SwiftTranslator.translateAssignExpression(assignExpression: SwiftAST): Statement {
    if (assignExpression.name != "Assign Expression") {
        return unexpectedASTStructureError(
            "Trying to translate ${assignExpression.name} as 'Assign Expression'",
            ast = assignExpression,
            translator = this)
    }

    val leftExpression: SwiftAST? = assignExpression.subtree(index = 0)
    val rightExpression: SwiftAST? = assignExpression.subtree(index = 1)

    if (leftExpression != null && rightExpression != null) {
        if (leftExpression.name == "Discard Assignment Expression") {
            return Statement.ExpressionStatement(expression = translateExpression(rightExpression))
        }
        else {
            val leftTranslation: Expression = translateExpression(leftExpression)
            val rightTranslation: Expression = translateExpression(rightExpression)
            return Statement.AssignmentStatement(leftHand = leftTranslation, rightHand = rightTranslation)
        }
    }
    else {
        return unexpectedASTStructureError("Unrecognized structure", ast = assignExpression, translator = this)
    }
}

internal fun SwiftTranslator.translateTypealiasDeclaration(
    typealiasDeclaration: SwiftAST)
    : Statement
{
    val isImplicit: Boolean
    val identifier: String

    if (typealiasDeclaration.standaloneAttributes[0] == "implicit") {
        isImplicit = true
        identifier = typealiasDeclaration.standaloneAttributes[1]
    }
    else {
        isImplicit = false
        identifier = typealiasDeclaration.standaloneAttributes[0]
    }

    return Statement.TypealiasDeclaration(
        identifier = identifier,
        typeName = typealiasDeclaration["type"]!!,
        isImplicit = isImplicit)
}

internal fun SwiftTranslator.translateClassDeclaration(classDeclaration: SwiftAST): Statement? {
    if (classDeclaration.name != "Class Declaration") {
        return unexpectedASTStructureError(
            "Trying to translate ${classDeclaration.name} as 'Class Declaration'",
            ast = classDeclaration,
            translator = this)
    }

    if (getComment(ast = classDeclaration, key = "kotlin") == "ignore") {
        return null
    }

    val name: String = classDeclaration.standaloneAttributes.firstOrNull()!!
    val inheritanceArray: MutableList<String>
    val inheritanceList: String? = classDeclaration["inherits"]

    if (inheritanceList != null) {
        inheritanceArray = inheritanceList.split(separator = ", ") as MutableList<String>
    }
    else {
        inheritanceArray = mutableListOf()
    }

    val classContents: MutableList<Statement> = mutableListOf<Statement>()

    return Statement.ClassDeclaration(className = name, inherits = inheritanceArray, members = classContents)
}

internal fun SwiftTranslator.translateStructDeclaration(structDeclaration: SwiftAST): Statement? {
    if (structDeclaration.name != "Struct Declaration") {
        return unexpectedASTStructureError(
            "Trying to translate ${structDeclaration.name} as 'Struct Declaration'",
            ast = structDeclaration,
            translator = this)
    }

    if (getComment(ast = structDeclaration, key = "kotlin") == "ignore") {
        return null
    }

    val annotations: String? = getComment(ast = structDeclaration, key = "annotation")
    val name: String = structDeclaration.standaloneAttributes.firstOrNull()!!
    val inheritanceArray: MutableList<String>
    val inheritanceList: String? = structDeclaration["inherits"]

    if (inheritanceList != null) {
        inheritanceArray = inheritanceList.split(separator = ", ") as MutableList<String>
    }
    else {
        inheritanceArray = mutableListOf()
    }

    val structContents: MutableList<Statement> = mutableListOf<Statement>()

    return Statement.StructDeclaration(
        annotations = annotations,
        structName = name,
        inherits = inheritanceArray,
        members = structContents)
}

internal fun SwiftTranslator.translateThrowStatement(throwStatement: SwiftAST): Statement {
    if (throwStatement.name != "Throw Statement") {
        return unexpectedASTStructureError(
            "Trying to translate ${throwStatement.name} as 'Throw Statement'",
            ast = throwStatement,
            translator = this)
    }
    val expression: SwiftAST? = throwStatement.subtrees.lastOrNull()
    if (expression != null) {
        val expressionTranslation: Expression = translateExpression(expression)
        return Statement.ThrowStatement(expression = expressionTranslation)
    }
    else {
        return unexpectedASTStructureError("Unrecognized structure", ast = throwStatement, translator = this)
    }
}

internal fun SwiftTranslator.translateExtensionDeclaration(
    extensionDeclaration: SwiftAST)
    : Statement
{
    val typeName: String = cleanUpType(extensionDeclaration.standaloneAttributes[0])
    val members: MutableList<Statement> = mutableListOf<Statement>()
    return Statement.ExtensionDeclaration(typeName = typeName, members = members)
}

internal fun SwiftTranslator.translateEnumDeclaration(enumDeclaration: SwiftAST): Statement? {
    if (enumDeclaration.name != "Enum Declaration") {
        return unexpectedASTStructureError(
            "Trying to translate ${enumDeclaration.name} as 'Enum Declaration'",
            ast = enumDeclaration,
            translator = this)
    }

    if (getComment(ast = enumDeclaration, key = "kotlin") == "ignore") {
        return null
    }

    val access: String? = enumDeclaration["access"]
    val name: String
    val isImplicit: Boolean

    if (enumDeclaration.standaloneAttributes[0] == "implicit") {
        isImplicit = true
        name = enumDeclaration.standaloneAttributes[1]
    }
    else {
        isImplicit = false
        name = enumDeclaration.standaloneAttributes[0]
    }

    val inheritanceArray: MutableList<String>
    val inheritanceList: String? = enumDeclaration["inherits"]

    if (inheritanceList != null) {
        inheritanceArray = inheritanceList.split(separator = ", ") as MutableList<String>
    }
    else {
        inheritanceArray = mutableListOf()
    }

    var rawValues: MutableList<Expression> = mutableListOf()
    val constructorDeclarations: MutableList<SwiftAST> = enumDeclaration.subtrees.filter { it.name == "Constructor Declaration" }.toMutableList()

    for (constructorDeclaration in constructorDeclarations) {
        val arrayExpression: SwiftAST? = constructorDeclaration.subtree(name = "Brace Statement")?.subtree(name = "Switch Statement")?.subtree(
            name = "Call Expression")?.subtree(
            name = "Tuple Expression")?.subtree(
            name = "Array Expression")
        if (constructorDeclaration.standaloneAttributes.contains("init(rawValue:)") && constructorDeclaration.standaloneAttributes.contains("implicit") && arrayExpression != null) {
            val rawValueASTs: MutableList<SwiftAST> = arrayExpression.subtrees.dropLast(1) as MutableList<SwiftAST>
            rawValues = rawValueASTs.map { translateExpression(it) }.toMutableList()
            break
        }
    }

    val elements: MutableList<EnumElement> = mutableListOf()
    val enumElementDeclarations: MutableList<SwiftAST> = enumDeclaration.subtrees.filter { it.name == "Enum Element Declaration" }.toMutableList()

    for (index in enumElementDeclarations.indices) {
        val enumElementDeclaration: SwiftAST = enumElementDeclarations[index]

        if (getComment(ast = enumElementDeclaration, key = "kotlin") == "ignore") {
            continue
        }

        val elementName: String? = enumElementDeclaration.standaloneAttributes.firstOrNull()

        elementName ?: return unexpectedASTStructureError(
            "Expected the element name to be the first standalone attribute in an Enum" + "Declaration",
            ast = enumDeclaration,
            translator = this)

        val annotations: String? = getComment(ast = enumElementDeclaration, key = "annotation")

        if (!elementName.contains("(")) {
            elements.add(EnumElement(
                name = elementName,
                associatedValues = mutableListOf(),
                rawValue = rawValues.getSafe(index),
                annotations = annotations))
        }
        else {
            val parenthesisIndex: Int = elementName.indexOf('(')
            val prefix: String = elementName.substring(0, parenthesisIndex)
            val suffix: String = elementName.substring(parenthesisIndex)
            val valuesString: String = suffix.drop(1).dropLast(2)
            val valueLabels: MutableList<String> = valuesString.split(separator = ':').map { it }.toMutableList() as MutableList<String>
            val enumType: String? = enumElementDeclaration["interface type"]

            enumType ?: return unexpectedASTStructureError(
                "Expected an enum element with associated values to have an interface type",
                ast = enumDeclaration,
                translator = this)

            val enumTypeComponents: MutableList<String> = enumType.split(separator = " -> ")
            val valuesComponent: String = enumTypeComponents[1]
            val valueTypesString: String = valuesComponent.drop(1).dropLast(1)
            val valueTypes: MutableList<String> = Utilities.splitTypeList(valueTypesString)
            val associatedValues: MutableList<LabeledType> = valueLabels.zip(valueTypes).map { LabeledType(label = it.first, typeName = it.second) }.toMutableList()

            elements.add(EnumElement(
                name = prefix,
                associatedValues = associatedValues,
                rawValue = rawValues.getSafe(index),
                annotations = annotations))
        }
    }

    val members: MutableList<SwiftAST> = enumDeclaration.subtrees.filter { it.name != "Enum Element Declaration" && it.name != "Enum Case Declaration" }.toMutableList()

    val translatedMembers = mutableListOf<Statement>()

    return Statement.EnumDeclaration(
        access = access,
        enumName = name,
        inherits = inheritanceArray,
        elements = elements,
        members = translatedMembers,
        isImplicit = isImplicit)
}

internal fun SwiftTranslator.translateMemberReferenceExpression(
    memberReferenceExpression: SwiftAST)
    : Expression
{
    if (memberReferenceExpression.name != "Member Reference Expression") {
        return unexpectedExpressionStructureError(
            "Trying to translate ${memberReferenceExpression.name} as " + "'Member Reference Expression'",
            ast = memberReferenceExpression,
            translator = this)
    }

    val declaration: String? = memberReferenceExpression["decl"]
    val memberOwner: SwiftAST? = memberReferenceExpression.subtree(index = 0)
    val rawType: String? = memberReferenceExpression["type"]

    if (declaration != null && memberOwner != null && rawType != null) {
        val typeName: String = cleanUpType(rawType)
        val leftHand: Expression = translateExpression(memberOwner)
        val declarationInformation: SwiftTranslator.DeclarationInformation = getInformationFromDeclaration(declaration)
        val isImplicit: Boolean = memberReferenceExpression.standaloneAttributes.contains("implicit")
        val range: SourceFileRange? = getRangeRecursively(ast = memberReferenceExpression)
        val rightHand: Expression = Expression.DeclarationReferenceExpression(
            data = DeclarationReferenceData(
                    identifier = declarationInformation.identifier,
                    typeName = typeName,
                    isStandardLibrary = declarationInformation.isStandardLibrary,
                    isImplicit = isImplicit,
                    range = range))

        return Expression.DotExpression(leftExpression = leftHand, rightExpression = rightHand)
    }
    else {
        return unexpectedExpressionStructureError(
            "Unrecognized structure",
            ast = memberReferenceExpression,
            translator = this)
    }
}

internal fun SwiftTranslator.translateTupleElementExpression(
    tupleElementExpression: SwiftAST)
    : Expression
{
    if (tupleElementExpression.name != "Tuple Element Expression") {
        return unexpectedExpressionStructureError(
            "Trying to translate ${tupleElementExpression.name} as " + "'Tuple Element Expression'",
            ast = tupleElementExpression,
            translator = this)
    }

    val numberString: String? = tupleElementExpression.standaloneAttributes.find { it.startsWith("#") }?.drop(1)
    val number: Int? = numberString?.let { it.toIntOrNull() } ?: null
    val declarationReference: SwiftAST? = tupleElementExpression.subtree(name = "Declaration Reference Expression")
    val tuple: String? = declarationReference?.get("type")

    if (number != null && declarationReference != null && tuple != null) {
        val leftHand: Expression = translateDeclarationReferenceExpression(declarationReference)
        val tupleComponents: MutableList<String> = tuple.drop(1).dropLast(1).split(separator = ", ")
        val tupleComponent: String? = tupleComponents.getSafe(number)
        val labelAndType: MutableList<String>? = tupleComponent?.split(separator = ": ")
        val label: String? = labelAndType?.getSafe(0)
        val typeName: String? = labelAndType?.getSafe(1)

        if (label != null && typeName != null && leftHand is Expression.DeclarationReferenceExpression) {
            val leftExpression: DeclarationReferenceData = leftHand.data
            return Expression.DotExpression(
                leftExpression = leftHand,
                rightExpression = Expression.DeclarationReferenceExpression(
                        data = DeclarationReferenceData(
                                identifier = label,
                                typeName = typeName,
                                isStandardLibrary = leftExpression.isStandardLibrary,
                                isImplicit = false,
                                range = leftExpression.range)))
        }
        else if (leftHand is Expression.DeclarationReferenceExpression && tupleComponent != null) {
            val leftExpression: DeclarationReferenceData = leftHand.data
            val memberName: String = if (number == 0) { "first" } else { "second" }
            return Expression.DotExpression(
                leftExpression = leftHand,
                rightExpression = Expression.DeclarationReferenceExpression(
                        data = DeclarationReferenceData(
                                identifier = memberName,
                                typeName = tupleComponent,
                                isStandardLibrary = leftExpression.isStandardLibrary,
                                isImplicit = false,
                                range = leftExpression.range)))
        }
    }

    return unexpectedExpressionStructureError(
        "Unable to get either the tuple element's number or its label.",
        ast = tupleElementExpression,
        translator = this)
}

internal fun SwiftTranslator.translatePrefixUnaryExpression(
    prefixUnaryExpression: SwiftAST)
    : Expression
{
    if (prefixUnaryExpression.name != "Prefix Unary Expression") {
        return unexpectedExpressionStructureError(
            "Trying to translate ${prefixUnaryExpression.name} as 'Prefix Unary Expression'",
            ast = prefixUnaryExpression,
            translator = this)
    }

    val rawType: String? = prefixUnaryExpression["type"]
    val declaration: String? = prefixUnaryExpression.subtree(name = "Dot Syntax Call Expression")?.subtree(
        name = "Declaration Reference Expression")?.get("decl")
    val expression: SwiftAST? = prefixUnaryExpression.subtree(index = 1)

    if (rawType != null && declaration != null && expression != null) {
        val typeName: String = cleanUpType(rawType)
        val expressionTranslation: Expression = translateExpression(expression)
        val operatorInformation: SwiftTranslator.DeclarationInformation = getInformationFromDeclaration(declaration)

        return Expression.PrefixUnaryExpression(
            expression = expressionTranslation,
            operatorSymbol = operatorInformation.identifier,
            typeName = typeName)
    }
    else {
        return unexpectedExpressionStructureError(
            "Expected Prefix Unary Expression to have a Dot Syntax Call Expression with a " + "Declaration Reference Expression, for the operator, and expected it to have " + "a second expression as the operand.",
            ast = prefixUnaryExpression,
            translator = this)
    }
}

internal fun SwiftTranslator.translatePostfixUnaryExpression(
    postfixUnaryExpression: SwiftAST)
    : Expression
{
    if (postfixUnaryExpression.name != "Postfix Unary Expression") {
        return unexpectedExpressionStructureError(
            "Trying to translate ${postfixUnaryExpression.name} as 'Postfix Unary Expression'",
            ast = postfixUnaryExpression,
            translator = this)
    }

    val rawType: String? = postfixUnaryExpression["type"]
    val declaration: String? = postfixUnaryExpression.subtree(name = "Dot Syntax Call Expression")?.subtree(
        name = "Declaration Reference Expression")?.get("decl")
    val expression: SwiftAST? = postfixUnaryExpression.subtree(index = 1)

    if (rawType != null && declaration != null && expression != null) {
        val typeName: String = cleanUpType(rawType)
        val expressionTranslation: Expression = translateExpression(expression)
        val operatorInformation: SwiftTranslator.DeclarationInformation = getInformationFromDeclaration(declaration)

        return Expression.PostfixUnaryExpression(
            expression = expressionTranslation,
            operatorSymbol = operatorInformation.identifier,
            typeName = typeName)
    }
    else {
        return unexpectedExpressionStructureError(
            "Expected Postfix Unary Expression to have a Dot Syntax Call Expression with a " + "Declaration Reference Expression, for the operator, and expected it to have " + "a second expression as the operand.",
            ast = postfixUnaryExpression,
            translator = this)
    }
}

internal fun SwiftTranslator.translateBinaryExpression(binaryExpression: SwiftAST): Expression {
    if (binaryExpression.name != "Binary Expression") {
        return unexpectedExpressionStructureError(
            "Trying to translate ${binaryExpression.name} as 'Binary Expression'",
            ast = binaryExpression,
            translator = this)
    }

    val declarationFromDotSyntax: SwiftAST? = binaryExpression.subtree(name = "Dot Syntax Call Expression")?.subtree(
        name = "Declaration Reference Expression")
    val directDeclaration: SwiftAST? = binaryExpression.subtree(name = "Declaration Reference Expression")
    val declaration: String? = declarationFromDotSyntax?.get("decl") ?: directDeclaration?.get("decl")
    val tupleExpression: SwiftAST? = binaryExpression.subtree(name = "Tuple Expression")
    val leftHandExpression: SwiftAST? = tupleExpression?.subtree(index = 0)
    val rightHandExpression: SwiftAST? = tupleExpression?.subtree(index = 1)
    val rawType: String? = binaryExpression["type"]

    if (rawType != null && declaration != null && leftHandExpression != null && rightHandExpression != null) {
        val typeName: String = cleanUpType(rawType)
        val operatorInformation: SwiftTranslator.DeclarationInformation = getInformationFromDeclaration(declaration)
        val leftHandTranslation: Expression = translateExpression(leftHandExpression)
        val rightHandTranslation: Expression = translateExpression(rightHandExpression)

        return Expression.BinaryOperatorExpression(
            leftExpression = leftHandTranslation,
            rightExpression = rightHandTranslation,
            operatorSymbol = operatorInformation.identifier,
            typeName = typeName)
    }
    else {
        return unexpectedExpressionStructureError(
            "Unrecognized structure",
            ast = binaryExpression,
            translator = this)
    }
}

internal fun SwiftTranslator.translateIfExpression(ifExpression: SwiftAST): Expression {
    if (ifExpression.name != "If Expression") {
        return unexpectedExpressionStructureError(
            "Trying to translate ${ifExpression.name} as 'If Expression'",
            ast = ifExpression,
            translator = this)
    }

    if (ifExpression.subtrees.size != 3) {
        return unexpectedExpressionStructureError(
            "Expected If Expression to have three subtrees (a condition, a true expression " + "and a false expression)",
            ast = ifExpression,
            translator = this)
    }

    val condition: Expression = translateExpression(ifExpression.subtrees[0])
    val trueExpression: Expression = translateExpression(ifExpression.subtrees[1])
    val falseExpression: Expression = translateExpression(ifExpression.subtrees[2])

    return Expression.IfExpression(
        condition = condition,
        trueExpression = trueExpression,
        falseExpression = falseExpression)
}

internal fun SwiftTranslator.translateDotSyntaxCallExpression(
    dotSyntaxCallExpression: SwiftAST)
    : Expression
{
    if (dotSyntaxCallExpression.name != "Dot Syntax Call Expression") {
        return unexpectedExpressionStructureError(
            "Trying to translate ${dotSyntaxCallExpression.name} as " + "'Dot Syntax Call Expression'",
            ast = dotSyntaxCallExpression,
            translator = this)
    }

    val leftHandExpression: SwiftAST? = dotSyntaxCallExpression.subtree(index = 1)
    val rightHandExpression: SwiftAST? = dotSyntaxCallExpression.subtree(index = 0)

    if (leftHandExpression != null && rightHandExpression != null) {
        val rightHand: Expression = translateExpression(rightHandExpression)
        val leftHand: Expression = translateExpression(leftHandExpression)

        if (leftHand is Expression && rightHand is Expression.DeclarationReferenceExpression) {
            val rightExpression: DeclarationReferenceData = rightHand.data
            if (rightExpression.identifier == "none") {
                return Expression.NilLiteralExpression()
            }
        }

        return Expression.DotExpression(leftExpression = leftHand, rightExpression = rightHand)
    }
    else {
        return unexpectedExpressionStructureError(
            "Unrecognized structure",
            ast = dotSyntaxCallExpression,
            translator = this)
    }
}

internal fun SwiftTranslator.translateReturnStatement(returnStatement: SwiftAST): Statement {
    if (returnStatement.name != "Return Statement") {
        return unexpectedASTStructureError(
            "Trying to translate ${returnStatement.name} as 'Return Statement'",
            ast = returnStatement,
            translator = this)
    }
    val expression: SwiftAST? = returnStatement.subtrees.lastOrNull()
    if (expression != null) {
        val translatedExpression: Expression = translateExpression(expression)
        return Statement.ReturnStatement(expression = translatedExpression)
    }
    else {
        return Statement.ReturnStatement(expression = null)
    }
}

internal fun SwiftTranslator.translateDoCatchStatement(
    doCatchStatement: SwiftAST)
    : MutableList<Statement?>
{
    if (doCatchStatement.name != "Do Catch Statement") {
        return mutableListOf(unexpectedASTStructureError(
            "Trying to translate ${doCatchStatement.name} as 'Do Catch Statement'",
            ast = doCatchStatement,
            translator = this))
    }

    val braceStatement: SwiftAST? = doCatchStatement.subtrees.firstOrNull()

    if (!(braceStatement != null && braceStatement.name == "Brace Statement")) {
        return mutableListOf(unexpectedASTStructureError(
            "Unable to find do statement's inner statements. Expected there to be a Brace " + "Statement as the first subtree.",
            ast = doCatchStatement,
            translator = this))
    }

    val translatedInnerDoStatements: MutableList<Statement> = translateBraceStatement(braceStatement)
    val translatedDoStatement: Statement = Statement.DoStatement(statements = translatedInnerDoStatements)
    val catchStatements: MutableList<Statement> = mutableListOf()

    for (catchStatement in doCatchStatement.subtrees.drop(1)) {
        if (catchStatement.name != "Catch") {
            continue
        }

        val variableDeclaration: VariableDeclarationData?
        val patternNamed: SwiftAST? = catchStatement.subtree(name = "Pattern Let")?.subtree(name = "Pattern Named")
        val patternAttributes: MutableList<String>? = patternNamed?.standaloneAttributes
        val variableName: String? = patternAttributes?.firstOrNull()
        val variableType: String? = patternNamed?.get("type")

        if (variableName != null && variableType != null) {
            variableDeclaration = VariableDeclarationData(
                identifier = variableName,
                typeName = variableType,
                expression = null,
                getter = null,
                setter = null,
                isLet = true,
                isImplicit = false,
                isStatic = false,
                extendsType = null,
                annotations = null)
        }
        else {
            variableDeclaration = null
        }

        val braceStatement: SwiftAST? = catchStatement.subtree(name = "Brace Statement")

        braceStatement ?: return mutableListOf(unexpectedASTStructureError(
            "Unable to find catch statement's inner statements. Expected there to be a " + "Brace Statement.",
            ast = doCatchStatement,
            translator = this))

        val translatedStatements: MutableList<Statement> = translateBraceStatement(braceStatement)

        catchStatements.add(Statement.CatchStatement(
            variableDeclaration = variableDeclaration,
            statements = translatedStatements))
    }

    val resultingStatements = (listOf(translatedDoStatement) + catchStatements)
    	.toMutableList<Statement?>()

    return resultingStatements
}

internal fun SwiftTranslator.translateForEachStatement(forEachStatement: SwiftAST): Statement {
    if (forEachStatement.name != "For Each Statement") {
        return unexpectedASTStructureError(
            "Trying to translate ${forEachStatement.name} as 'For Each Statement'",
            ast = forEachStatement,
            translator = this)
    }

    val variableRange: SourceFileRange? = getRangeRecursively(ast = forEachStatement.subtrees[0])
    val variable: Expression
    val collectionExpression: SwiftAST
    val maybeCollectionExpression: SwiftAST? = forEachStatement.subtree(index = 2)
    val variableSubtreeTuple: SwiftAST? = forEachStatement.subtree(name = "Pattern Tuple")
    val variableSubtreeNamed: SwiftAST? = forEachStatement.subtree(name = "Pattern Named")
    val variableSubtreeAny: SwiftAST? = forEachStatement.subtree(name = "Pattern Any")
    val rawTypeNamed: String? = variableSubtreeNamed?.get("type")
    val rawTypeAny: String? = variableSubtreeAny?.get("type")
    val variableAttributes: MutableList<String>? = variableSubtreeNamed?.standaloneAttributes
    val variableName: String? = variableAttributes?.firstOrNull()

    if (rawTypeNamed != null && maybeCollectionExpression != null && variableName != null) {
        variable = Expression.DeclarationReferenceExpression(
            data = DeclarationReferenceData(
                    identifier = variableName,
                    typeName = cleanUpType(rawTypeNamed),
                    isStandardLibrary = false,
                    isImplicit = false,
                    range = variableRange))
        collectionExpression = maybeCollectionExpression
    }
    else if (variableSubtreeTuple != null && maybeCollectionExpression != null) {
        val variableNames: MutableList<String> = variableSubtreeTuple.subtrees.map { it.standaloneAttributes[0] }.toMutableList()
        val variableTypes: MutableList<String> = variableSubtreeTuple.subtrees.map { it.keyValueAttributes["type"]!! }.toMutableList()
        val variables: MutableList<LabeledExpression> = variableNames.zip(variableTypes).map { LabeledExpression(
            label = null,
            expression = Expression.DeclarationReferenceExpression(
                    data = DeclarationReferenceData(
                            identifier = it.first,
                            typeName = cleanUpType(it.second),
                            isStandardLibrary = false,
                            isImplicit = false,
                            range = variableRange))) }.toMutableList()

        variable = Expression.TupleExpression(pairs = variables)
        collectionExpression = maybeCollectionExpression
    }
    else if (rawTypeAny != null && maybeCollectionExpression != null) {
        val typeName: String = cleanUpType(rawTypeAny)
        variable = Expression.DeclarationReferenceExpression(
            data = DeclarationReferenceData(
                    identifier = "_0",
                    typeName = typeName,
                    isStandardLibrary = false,
                    isImplicit = false,
                    range = variableRange))
        collectionExpression = maybeCollectionExpression
    }
    else {
        return unexpectedASTStructureError(
            "Unable to detect variable or collection",
            ast = forEachStatement,
            translator = this)
    }

    val braceStatement: SwiftAST? = forEachStatement.subtrees.lastOrNull()

    if (!(braceStatement != null && braceStatement.name == "Brace Statement")) {
        return unexpectedASTStructureError(
            "Unable to detect body of statements",
            ast = forEachStatement,
            translator = this)
    }

    val collectionTranslation: Expression = translateExpression(collectionExpression)
    val statements: MutableList<Statement> = translateBraceStatement(braceStatement)

    return Statement.ForEachStatement(
        collection = collectionTranslation,
        variable = variable,
        statements = statements)
}

internal fun SwiftTranslator.translateWhileStatement(whileStatement: SwiftAST): Statement {
    if (whileStatement.name != "While Statement") {
        return unexpectedASTStructureError(
            "Trying to translate ${whileStatement.name} as 'While Statement'",
            ast = whileStatement,
            translator = this)
    }

    val expressionSubtree: SwiftAST? = whileStatement.subtrees.firstOrNull()

    expressionSubtree ?: return unexpectedASTStructureError("Unable to detect expression", ast = whileStatement, translator = this)

    val braceStatement: SwiftAST? = whileStatement.subtrees.lastOrNull()

    if (!(braceStatement != null && braceStatement.name == "Brace Statement")) {
        return unexpectedASTStructureError(
            "Unable to detect body of statements",
            ast = whileStatement,
            translator = this)
    }

    val expression: Expression = translateExpression(expressionSubtree)
    val statements: MutableList<Statement> = translateBraceStatement(braceStatement)

    return Statement.WhileStatement(expression = expression, statements = statements)
}

internal fun SwiftTranslator.translateDeferStatement(deferStatement: SwiftAST): Statement {
    if (deferStatement.name != "Defer Statement") {
        return unexpectedASTStructureError(
            "Trying to translate ${deferStatement.name} as a 'Defer Statement'",
            ast = deferStatement,
            translator = this)
    }

    val braceStatement: SwiftAST? = deferStatement.subtree(name = "Function Declaration")?.subtree(name = "Brace Statement")

    braceStatement ?: return unexpectedASTStructureError(
        "Expected defer statement to have a function declaration with a brace statement " + "containing the deferred statements.",
        ast = deferStatement,
        translator = this)

    val statements: MutableList<Statement> = translateBraceStatement(braceStatement)

    return Statement.DeferStatement(statements = statements)
}

internal fun SwiftTranslator.translateIfStatement(ifStatement: SwiftAST): Statement {
    try {
        val result: IfStatementData = translateIfStatementData(ifStatement)
        return Statement.IfStatement(data = result)
    }
    catch (error: Exception) {
        return handleUnexpectedASTStructureError(error)
    }
}

internal fun SwiftTranslator.translateIfStatementData(ifStatement: SwiftAST): IfStatementData {
    if (!(ifStatement.name == "If Statement" || ifStatement.name == "Guard Statement")) {
        throw createUnexpectedASTStructureError(
            "Trying to translate ${ifStatement.name} as an if or guard statement",
            ast = ifStatement,
            translator = this)
    }

    val isGuard: Boolean = (ifStatement.name == "Guard Statement")
    val ifConditions: IfConditionsTranslation = translateIfConditions(ifStatement = ifStatement)
    val conditions: MutableList<IfStatementData.IfCondition> = ifConditions.conditions
    val extraStatements: MutableList<Statement> = ifConditions.statements
    val braceStatement: SwiftAST
    val elseStatement: IfStatementData?
    val secondToLastTree: SwiftAST? = ifStatement.subtrees.secondToLast
    val lastTree: SwiftAST? = ifStatement.subtrees.lastOrNull()

    if (ifStatement.subtrees.size > 2 && secondToLastTree != null && secondToLastTree.name == "Brace Statement" && lastTree != null && lastTree.name == "If Statement") {
        braceStatement = secondToLastTree
        elseStatement = translateIfStatementData(lastTree)
    }
    else if (ifStatement.subtrees.size > 2 && secondToLastTree != null && secondToLastTree.name == "Brace Statement" && lastTree != null && lastTree.name == "Brace Statement") {
        braceStatement = secondToLastTree
        val statements: MutableList<Statement> = translateBraceStatement(lastTree)
        elseStatement = IfStatementData(
            conditions = mutableListOf(),
            declarations = mutableListOf(),
            statements = statements,
            elseStatement = null,
            isGuard = false)
    }
    else if (lastTree != null && lastTree.name == "Brace Statement") {
        braceStatement = lastTree
        elseStatement = null
    }
    else {
        throw createUnexpectedASTStructureError(
            "Unable to detect body of statements",
            ast = ifStatement,
            translator = this)
    }

    val statements: MutableList<Statement> = translateBraceStatement(braceStatement)

    val resultingStatements = (extraStatements + statements).toMutableList()

    return IfStatementData(
        conditions = conditions,
        declarations = mutableListOf(),
        statements = resultingStatements,
        elseStatement = elseStatement,
        isGuard = isGuard)
}

internal fun SwiftTranslator.translateSwitchStatement(switchStatement: SwiftAST): Statement {
    if (switchStatement.name != "Switch Statement") {
        return unexpectedASTStructureError(
            "Trying to translate ${switchStatement.name} as 'Switch Statement'",
            ast = switchStatement,
            translator = this)
    }

    val expression: SwiftAST? = switchStatement.subtrees.firstOrNull()

    expression ?: return unexpectedASTStructureError(
        "Unable to detect primary expression for switch statement",
        ast = switchStatement,
        translator = this)

    val translatedExpression: Expression = translateExpression(expression)
    val cases: MutableList<SwitchCase> = mutableListOf()
    val caseSubtrees: MutableList<SwiftAST> = switchStatement.subtrees.drop(1) as MutableList<SwiftAST>

    for (caseSubtree in caseSubtrees) {
        val caseExpression: Expression?
        var extraStatements: MutableList<Statement>
        val caseLabelItem: SwiftAST? = caseSubtree.subtree(name = "Case Label Item")

        if (caseLabelItem != null) {
            val firstSubtreeSubtrees: MutableList<SwiftAST>? = caseLabelItem.subtrees.firstOrNull()?.subtrees
            val maybeExpression: SwiftAST? = firstSubtreeSubtrees?.firstOrNull()
            val patternLet: SwiftAST? = caseLabelItem.subtree(name = "Pattern Let")
            val patternLetResult: EnumPatternTranslation? = translateEnumPattern(patternLet)
            val patternEnumElement: SwiftAST? = caseLabelItem.subtree(name = "Pattern Enum Element")
            val expression: SwiftAST? = maybeExpression

            if (patternLetResult != null && patternLet != null) {
                val enumType: String = patternLetResult.enumType
                val enumCase: String = patternLetResult.enumCase
                val declarations: MutableList<AssociatedValueDeclaration> = patternLetResult.declarations
                val enumClassName: String = enumType + "." + enumCase.capitalizedAsCamelCase()

                caseExpression = Expression.BinaryOperatorExpression(
                    leftExpression = translatedExpression,
                    rightExpression = Expression.TypeExpression(typeName = enumClassName),
                    operatorSymbol = "is",
                    typeName = "Bool")

                val range: SourceFileRange? = getRangeRecursively(ast = patternLet)

                extraStatements = declarations.map { Statement.VariableDeclaration(
                    data = VariableDeclarationData(
                            identifier = it.newVariable,
                            typeName = it.associatedValueType,
                            expression = Expression.DotExpression(
                                    leftExpression = translatedExpression,
                                    rightExpression = Expression.DeclarationReferenceExpression(
                                            data = DeclarationReferenceData(
                                                    identifier = it.associatedValueName,
                                                    typeName = it.associatedValueType,
                                                    isStandardLibrary = false,
                                                    isImplicit = false,
                                                    range = range))),
                            getter = null,
                            setter = null,
                            isLet = true,
                            isImplicit = false,
                            isStatic = false,
                            extendsType = null,
                            annotations = null)) }.toMutableList()
            }
            else if (patternEnumElement != null) {
                caseExpression = translateSimplePatternEnumElement(patternEnumElement)
                extraStatements = mutableListOf()
            }
            else if (expression != null) {
                val translatedExpression: Expression = translateExpression(expression)
                caseExpression = translatedExpression
                extraStatements = mutableListOf()
            }
            else {
                caseExpression = null
                extraStatements = mutableListOf()
            }
        }
        else {
            caseExpression = null
            extraStatements = mutableListOf()
        }

        val braceStatement: SwiftAST? = caseSubtree.subtree(name = "Brace Statement")

        braceStatement ?: return unexpectedASTStructureError(
            "Unable to find a case's statements",
            ast = switchStatement,
            translator = this)

        val translatedStatements: MutableList<Statement> = translateBraceStatement(braceStatement)

        val resultingStatements =
        	(extraStatements + translatedStatements).toMutableList()

        cases.add(SwitchCase(expression = caseExpression, statements = resultingStatements))
    }

    return Statement.SwitchStatement(
        convertsToExpression = null,
        expression = translatedExpression,
        cases = cases)
}

internal fun SwiftTranslator.translateSimplePatternEnumElement(
    simplePatternEnumElement: SwiftAST)
    : Expression
{
    if (simplePatternEnumElement.name != "Pattern Enum Element") {
        return unexpectedExpressionStructureError(
            "Trying to translate ${simplePatternEnumElement.name} as 'Pattern Enum Element'",
            ast = simplePatternEnumElement,
            translator = this)
    }

    val enumReference: String? = simplePatternEnumElement.standaloneAttributes.firstOrNull()
    val typeName: String? = simplePatternEnumElement["type"]

    if (!(enumReference != null && typeName != null)) {
        return unexpectedExpressionStructureError(
            "Expected a Pattern Enum Element to have a reference to the enum case and a type.",
            ast = simplePatternEnumElement,
            translator = this)
    }

    var enumElements: MutableList<String> = enumReference.split(separator = '.')
    val lastEnumElement: String? = enumElements.lastOrNull()

    lastEnumElement ?: return unexpectedExpressionStructureError(
        "Expected a Pattern Enum Element to have a period (i.e. `MyEnum.myEnumCase`)",
        ast = simplePatternEnumElement,
        translator = this)

    val range: SourceFileRange? = getRangeRecursively(ast = simplePatternEnumElement)
    val lastExpression: Expression = Expression.DeclarationReferenceExpression(
        data = DeclarationReferenceData(
                identifier = lastEnumElement,
                typeName = typeName,
                isStandardLibrary = false,
                isImplicit = false,
                range = range))

    enumElements.removeLast()

    if (!enumElements.isEmpty()) {
        return Expression.DotExpression(
            leftExpression = Expression.TypeExpression(typeName = enumElements.joinToString(separator = ".")),
            rightExpression = lastExpression)
    }
    else {
        return lastExpression
    }
}

private fun SwiftTranslator.translateIfConditions(
    ifStatement: SwiftAST)
    : IfConditionsTranslation
{
    if (!(ifStatement.name == "If Statement" || ifStatement.name == "Guard Statement")) {
        return IfConditionsTranslation(
            conditions = mutableListOf(),
            statements = mutableListOf(unexpectedASTStructureError(
                    "Trying to translate ${ifStatement.name} as an if or guard statement",
                    ast = ifStatement,
                    translator = this)))
    }

    val conditionsResult: MutableList<IfStatementData.IfCondition> = mutableListOf()
    val statementsResult: MutableList<Statement> = mutableListOf()
    val conditions: MutableList<SwiftAST> = ifStatement.subtrees.filter { it.name != "If Statement" && it.name != "Brace Statement" }.toMutableList()

    for (condition in conditions) {
        val patternEnumElement: SwiftAST? = condition.subtree(name = "Pattern Enum Element")
        val enumElementType: String? = patternEnumElement?.get("type")
        val optionalSomeElement: SwiftAST? = condition.subtree(name = "Optional Some Element") ?: condition.subtree(name = "Pattern Optional Some")
        val patternLet: SwiftAST? = condition.subtree(name = "Pattern Let")
        val declarationReferenceAST: SwiftAST? = condition.subtrees.lastOrNull()
        val declarationReference: SwiftAST? = condition.subtree(name = "Declaration Reference Expression")

        if (condition.name == "Pattern" && optionalSomeElement != null) {
            val patternNamed: SwiftAST
            val isLet: Boolean
            val unwrappedPatternLetNamed: SwiftAST? = optionalSomeElement.subtree(name = "Pattern Let")?.subtree(name = "Pattern Named")
            val unwrappedPatternVariableNamed: SwiftAST? = optionalSomeElement.subtree(name = "Pattern Variable")?.subtree(name = "Pattern Named")

            if (unwrappedPatternLetNamed != null) {
                patternNamed = unwrappedPatternLetNamed
                isLet = true
            }
            else if (unwrappedPatternVariableNamed != null) {
                patternNamed = unwrappedPatternVariableNamed
                isLet = false
            }
            else {
                return IfConditionsTranslation(
                    conditions = mutableListOf(),
                    statements = mutableListOf(unexpectedASTStructureError(
                            "Unable to detect pattern in let declaration",
                            ast = ifStatement,
                            translator = this)))
            }

            val rawType: String? = optionalSomeElement["type"]

            rawType ?: return IfConditionsTranslation(
                conditions = mutableListOf(),
                statements = mutableListOf(unexpectedASTStructureError(
                        "Unable to detect type in let declaration",
                        ast = ifStatement,
                        translator = this)))

            val typeName: String = cleanUpType(rawType)
            val name: String? = patternNamed.standaloneAttributes.firstOrNull()
            val lastCondition: SwiftAST? = condition.subtrees.lastOrNull()

            if (!(name != null && lastCondition != null)) {
                return IfConditionsTranslation(
                    conditions = mutableListOf(),
                    statements = mutableListOf(unexpectedASTStructureError(
                            "Unable to get expression in let declaration",
                            ast = ifStatement,
                            translator = this)))
            }

            val expression: Expression = translateExpression(lastCondition)

            conditionsResult.add(IfStatementData.IfCondition.Declaration(
                variableDeclaration = VariableDeclarationData(
                        identifier = name,
                        typeName = typeName,
                        expression = expression,
                        getter = null,
                        setter = null,
                        isLet = isLet,
                        isImplicit = false,
                        isStatic = false,
                        extendsType = null,
                        annotations = null)))
        }
        else if (condition.name == "Pattern" && patternLet != null && condition.subtrees.size >= 2 && declarationReferenceAST != null) {
            val patternLetResult: EnumPatternTranslation? = translateEnumPattern(patternLet)

            patternLetResult ?: return IfConditionsTranslation(
                conditions = mutableListOf(),
                statements = mutableListOf(unexpectedASTStructureError(
                        "Unable to translate Pattern Let",
                        ast = ifStatement,
                        translator = this)))

            val enumType: String = patternLetResult.enumType
            val enumCase: String = patternLetResult.enumCase
            val declarations: MutableList<AssociatedValueDeclaration> = patternLetResult.declarations
            val enumClassName: String = enumType + "." + enumCase.capitalizedAsCamelCase()
            val declarationReference: Expression = translateExpression(declarationReferenceAST)

            conditionsResult.add(IfStatementData.IfCondition.Condition(
                expression = Expression.BinaryOperatorExpression(
                        leftExpression = declarationReference,
                        rightExpression = Expression.TypeExpression(typeName = enumClassName),
                        operatorSymbol = "is",
                        typeName = "Bool")))

            for (declaration in declarations) {
                val range: SourceFileRange? = getRangeRecursively(ast = patternLet)
                statementsResult.add(Statement.VariableDeclaration(
                    data = VariableDeclarationData(
                            identifier = declaration.newVariable,
                            typeName = declaration.associatedValueType,
                            expression = Expression.DotExpression(
                                    leftExpression = declarationReference,
                                    rightExpression = Expression.DeclarationReferenceExpression(
                                            data = DeclarationReferenceData(
                                                    identifier = declaration.associatedValueName,
                                                    typeName = declaration.associatedValueType,
                                                    isStandardLibrary = false,
                                                    isImplicit = false,
                                                    range = range))),
                            getter = null,
                            setter = null,
                            isLet = true,
                            isImplicit = false,
                            isStatic = false,
                            extendsType = null,
                            annotations = null)))
            }
        }
        else if (condition.name == "Pattern" && enumElementType != null && declarationReference != null) {
            val translatedDeclarationReference: Expression = translateDeclarationReferenceExpression(declarationReference)
            val translatedType: String = cleanUpType(enumElementType)
            conditionsResult.add(IfStatementData.IfCondition.Condition(
                expression = Expression.BinaryOperatorExpression(
                        leftExpression = translatedDeclarationReference,
                        rightExpression = Expression.TypeExpression(typeName = translatedType),
                        operatorSymbol = "is",
                        typeName = "Bool")))
        }
        else {
            conditionsResult.add(IfStatementData.IfCondition.Condition(expression = translateExpression(condition)))
        }
    }

    return IfConditionsTranslation(conditions = conditionsResult, statements = statementsResult)
}

private fun SwiftTranslator.translateEnumPattern(
    enumPattern: SwiftAST?)
    : EnumPatternTranslation?
{
    if (!(enumPattern != null && (enumPattern.name == "Pattern Let" || enumPattern.name == "Pattern"))) {
        return null
    }

    val maybeEnumType: String? = enumPattern["type"]
    val maybePatternEnumElement: SwiftAST? = enumPattern.subtree(name = "Pattern Enum Element")
    val maybePatternTuple: SwiftAST? = maybePatternEnumElement?.subtree(name = "Pattern Tuple")
    val maybeAssociatedValueTuple: String? = maybePatternTuple?.get("type")
    val enumType: String? = maybeEnumType
    val patternEnumElement: SwiftAST? = maybePatternEnumElement
    val patternTuple: SwiftAST? = maybePatternTuple
    val associatedValueTuple: String? = maybeAssociatedValueTuple

    if (!(enumType != null && patternEnumElement != null && patternTuple != null && associatedValueTuple != null)) {
        return null
    }

    val valuesTupleWithoutParentheses: String = associatedValueTuple.drop(1).dropLast(1)
    val valueTuplesComponents: MutableList<String> = Utilities.splitTypeList(valuesTupleWithoutParentheses, separators = mutableListOf(","))
    val associatedValueNames: MutableList<String> = valueTuplesComponents.map { it.split(separator = ":")[0] }.toMutableList()
    val declarations: MutableList<AssociatedValueDeclaration> = mutableListOf()
    val caseName: String = patternEnumElement.standaloneAttributes[0].split(separator = '.').lastOrNull()!!

    if (associatedValueNames.size != patternTuple.subtrees.size) {
        return null
    }

    val associatedValuesInfo: List<Pair<String, SwiftAST>> =
    	associatedValueNames.zip(patternTuple.subtrees)

    val patternsNamed: MutableList<Pair<String, SwiftAST>> = associatedValuesInfo.filter { it.second.name == "Pattern Named" }.toMutableList()

    for (patternNamed in patternsNamed) {
        val associatedValueName: String = patternNamed.first
        val ast: SwiftAST = patternNamed.second
        val associatedValueType: String? = ast["type"]

        associatedValueType ?: return null

        declarations.add(AssociatedValueDeclaration(
            associatedValueName = associatedValueName,
            associatedValueType = associatedValueType,
            newVariable = ast.standaloneAttributes[0]))
    }

    return EnumPatternTranslation(enumType = enumType, enumCase = caseName, declarations = declarations)
}

internal fun SwiftTranslator.translateFunctionDeclaration(
    functionDeclaration: SwiftAST)
    : Statement?
{
    val compatibleASTNodes: MutableList<String> = mutableListOf("Function Declaration", "Constructor Declaration", "Accessor Declaration")

    if (!(compatibleASTNodes.contains(functionDeclaration.name))) {
        return unexpectedASTStructureError(
            "Trying to translate ${functionDeclaration.name} as 'Function Declaration'",
            ast = functionDeclaration,
            translator = this)
    }

    val isSubscript: Boolean = (functionDeclaration.name == "Accessor Declaration")
    val isGetterOrSetter: Boolean = (functionDeclaration["getter_for"] != null) || (functionDeclaration["setter_for"] != null)
    val isImplicit: Boolean = functionDeclaration.standaloneAttributes.contains("implicit")

    if (!(!isImplicit && !isGetterOrSetter)) {
        return null
    }

    val functionName: String

    if (isSubscript) {
        if (functionDeclaration["get_for"] != null) {
            functionName = "get"
        }
        else if (functionDeclaration["set_for"] != null) {
            functionName = "set"
        }
        else {
            return unexpectedASTStructureError(
                "Trying to translate subscript declaration that isn't getter or setter",
                ast = functionDeclaration,
                translator = this)
        }
    }
    else {
        functionName = functionDeclaration.standaloneAttributes.firstOrNull() ?: ""
    }

    val access: String? = functionDeclaration["access"]
    val maybeInterfaceType: String? = functionDeclaration["interface type"]
    val maybeInterfaceTypeComponents: MutableList<String>? = functionDeclaration["interface type"]?.split(separator = " -> ")
    val maybeFirstInterfaceTypeComponent: String? = maybeInterfaceTypeComponents?.firstOrNull()
    val interfaceType: String? = maybeInterfaceType
    val interfaceTypeComponents: MutableList<String>? = maybeInterfaceTypeComponents
    val firstInterfaceTypeComponent: String? = maybeFirstInterfaceTypeComponent

    if (!(interfaceType != null && interfaceTypeComponents != null && firstInterfaceTypeComponent != null)) {
        return unexpectedASTStructureError(
            "Unable to find out if function is static",
            ast = functionDeclaration,
            translator = this)
    }

    val isStatic: Boolean = firstInterfaceTypeComponent.contains(".Type")
    val isMutating: Boolean = firstInterfaceTypeComponent.contains("inout")
    val genericTypes: MutableList<String>
    val firstGenericString: String? = functionDeclaration.standaloneAttributes.find { it.startsWith("<") }

    if (firstGenericString != null) {
        genericTypes = firstGenericString.dropLast(1).drop(1).split(separator = ',').map { it }.toMutableList() as MutableList<String>
    }
    else {
        genericTypes = mutableListOf()
    }

    val functionNamePrefix: String = functionName.takeWhile { it != '(' }
    val parameterList: SwiftAST?
    val list: SwiftAST? = functionDeclaration.subtree(name = "Parameter List")
    val listStandaloneAttributes: MutableList<String>? = list?.subtree(index = 0, name = "Parameter")?.standaloneAttributes
    val name: String? = listStandaloneAttributes?.firstOrNull()
    val unwrapped: SwiftAST? = functionDeclaration.subtree(index = 1, name = "Parameter List")

    if (list != null && name != null && name != "self") {
        parameterList = list
    }
    else if (unwrapped != null) {
        parameterList = unwrapped
    }
    else {
        parameterList = null
    }

    val parameters: MutableList<FunctionParameter> = mutableListOf()

    if (parameterList != null) {
        for (parameter in parameterList.subtrees) {
            val name: String? = parameter.standaloneAttributes.firstOrNull()
            val typeName: String? = parameter["interface type"]
            if (name != null && typeName != null) {
                if (name == "self") {
                    continue
                }

                val parameterName: String = name
                val parameterApiLabel: String? = parameter["apiName"]
                val parameterType: String = cleanUpType(typeName)
                val defaultValue: Expression?
                val defaultValueTree: SwiftAST? = parameter.subtrees.firstOrNull()

                if (defaultValueTree != null) {
                    defaultValue = translateExpression(defaultValueTree)
                }
                else {
                    defaultValue = null
                }

                parameters.add(FunctionParameter(
                    label = parameterName,
                    apiLabel = parameterApiLabel,
                    typeName = parameterType,
                    value = defaultValue))
            }
            else {
                return unexpectedASTStructureError(
                    "Unable to detect name or attribute for a parameter",
                    ast = functionDeclaration,
                    translator = this)
            }
        }
    }

    if (isSubscript) {
        parameters.reverse()
    }

    val returnType: String? = interfaceTypeComponents.lastOrNull()

    returnType ?: return unexpectedASTStructureError(
        "Unable to get return type",
        ast = functionDeclaration,
        translator = this)

    val statements: MutableList<Statement>
    val braceStatement: SwiftAST? = functionDeclaration.subtree(name = "Brace Statement")

    if (braceStatement != null) {
        statements = translateBraceStatement(braceStatement)
    }
    else {
        statements = mutableListOf()
    }

    var annotations: MutableList<String?> = mutableListOf()

    annotations.add(getComment(ast = functionDeclaration, key = "annotation"))

    if (isSubscript) {
        annotations.add("operator")
    }

    val joinedAnnotations: String = annotations.map { it }.filterNotNull().toMutableList().joinToString(separator = " ")
    val annotationsResult: String? = if (joinedAnnotations.isEmpty()) { null } else { joinedAnnotations }
    val isPure: Boolean = (getComment(ast = functionDeclaration, key = "gryphon") == "pure")

    return Statement.FunctionDeclaration(
        data = FunctionDeclarationData(
                prefix = functionNamePrefix,
                parameters = parameters,
                returnType = returnType,
                functionType = interfaceType,
                genericTypes = genericTypes,
                isImplicit = isImplicit,
                isStatic = isStatic,
                isMutating = isMutating,
                isPure = isPure,
                extendsType = null,
                statements = statements,
                access = access,
                annotations = annotationsResult))
}

internal fun SwiftTranslator.translateTopLevelCode(
    topLevelCodeDeclaration: SwiftAST)
    : MutableList<Statement?>
{
    if (topLevelCodeDeclaration.name != "Top Level Code Declaration") {
        return mutableListOf(unexpectedASTStructureError(
            "Trying to translate ${topLevelCodeDeclaration.name} as " + "'Top Level Code Declaration'",
            ast = topLevelCodeDeclaration,
            translator = this))
    }

    val braceStatement: SwiftAST? = topLevelCodeDeclaration.subtree(name = "Brace Statement")

    braceStatement ?: return mutableListOf(unexpectedASTStructureError(
        "Unrecognized structure",
        ast = topLevelCodeDeclaration,
        translator = this))

    val subtrees: MutableList<Statement> = translateBraceStatement(braceStatement)

    return subtrees as MutableList<Statement?>
}

internal fun SwiftTranslator.translateVariableDeclaration(
    variableDeclaration: SwiftAST)
    : Statement
{
    if (variableDeclaration.name != "Variable Declaration") {
        return unexpectedASTStructureError(
            "Trying to translate ${variableDeclaration.name} as 'Variable Declaration'",
            ast = variableDeclaration,
            translator = this)
    }

    val isImplicit: Boolean = variableDeclaration.standaloneAttributes.contains("implicit")
    val annotations: String? = getComment(ast = variableDeclaration, key = "annotation")
    val isStatic: Boolean
    val accessorDeclaration: SwiftAST? = variableDeclaration.subtree(name = "Accessor Declaration")
    val interfaceType: String? = accessorDeclaration?.get("interface type")
    val typeComponents: MutableList<String>? = interfaceType?.split(separator = " -> ")
    val firstTypeComponent: String? = typeComponents?.firstOrNull()

    if (firstTypeComponent != null && firstTypeComponent.contains(".Type")) {
        isStatic = true
    }
    else {
        isStatic = false
    }

    val identifier: String? = variableDeclaration.standaloneAttributes.find { it != "implicit" }
    val rawType: String? = variableDeclaration["interface type"]

    if (!(identifier != null && rawType != null)) {
        return unexpectedASTStructureError(
            "Failed to get identifier and type",
            ast = variableDeclaration,
            translator = this)
    }

    val isLet: Boolean = variableDeclaration.standaloneAttributes.contains("let")
    val typeName: String = cleanUpType(rawType)
    var expression: Expression? = null
    val firstBindingExpression: SwiftTranslator.PatternBindingDeclaration?? = danglingPatternBindings.firstOrNull()

    if (firstBindingExpression != null) {
        val bindingExpression: SwiftTranslator.PatternBindingDeclaration? = firstBindingExpression
        if (bindingExpression != null) {
            if ((bindingExpression.identifier == identifier && bindingExpression.typeName == typeName) || (bindingExpression.identifier == "<<Error>>")) {
                expression = bindingExpression.expression
            }
        }
        danglingPatternBindings.removeAt(0)
    }

    val valueReplacement: String? = getComment(ast = variableDeclaration, key = "value")

    if (valueReplacement != null && expression == null) {
        expression = Expression.LiteralCodeExpression(string = valueReplacement)
    }

    var getter: FunctionDeclarationData? = null
    var setter: FunctionDeclarationData? = null

    for (subtree in variableDeclaration.subtrees) {
        val access: String? = subtree["access"]
        val statements: MutableList<Statement>
        val braceStatement: SwiftAST? = subtree.subtree(name = "Brace Statement")

        if (braceStatement != null) {
            statements = translateBraceStatement(braceStatement)
        }
        else {
            statements = mutableListOf()
        }

        val isImplicit: Boolean = subtree.standaloneAttributes.contains("implicit")
        val isPure: Boolean = (getComment(ast = subtree, key = "gryphon") == "pure")
        val annotations: String? = getComment(ast = subtree, key = "annotation")

        if (subtree["get_for"] != null) {
            getter = FunctionDeclarationData(
                prefix = "get",
                parameters = mutableListOf(),
                returnType = typeName,
                functionType = "() -> (${typeName})",
                genericTypes = mutableListOf(),
                isImplicit = isImplicit,
                isStatic = false,
                isMutating = false,
                isPure = isPure,
                extendsType = null,
                statements = statements,
                access = access,
                annotations = annotations)
        }
        else if (subtree["materializeForSet_for"] != null || subtree["set_for"] != null) {
            setter = FunctionDeclarationData(
                prefix = "set",
                parameters = mutableListOf(FunctionParameter(label = "newValue", apiLabel = null, typeName = typeName, value = null)),
                returnType = "()",
                functionType = "(${typeName}) -> ()",
                genericTypes = mutableListOf(),
                isImplicit = isImplicit,
                isStatic = false,
                isMutating = false,
                isPure = isPure,
                extendsType = null,
                statements = statements,
                access = access,
                annotations = annotations)
        }
    }

    return Statement.VariableDeclaration(
        data = VariableDeclarationData(
                identifier = identifier,
                typeName = typeName,
                expression = expression,
                getter = getter,
                setter = setter,
                isLet = isLet,
                isImplicit = isImplicit,
                isStatic = isStatic,
                extendsType = null,
                annotations = annotations))
}

internal fun SwiftTranslator.translateExpression(expression: SwiftAST): Expression {
    val valueReplacement: String? = getComment(ast = expression, key = "value")

    if (valueReplacement != null) {
        return Expression.LiteralCodeExpression(string = valueReplacement)
    }

    val result: Expression

    when (expression.name) {
        "Array Expression" -> result = translateArrayExpression(expression)
        "Dictionary Expression" -> result = translateDictionaryExpression(expression)
        "Binary Expression" -> result = translateBinaryExpression(expression)
        "If Expression" -> result = translateIfExpression(expression)
        "Call Expression" -> result = translateCallExpression(expression)
        "Closure Expression" -> result = translateClosureExpression(expression)
        "Declaration Reference Expression" -> result = translateDeclarationReferenceExpression(expression)
        "Dot Syntax Call Expression" -> result = translateDotSyntaxCallExpression(expression)
        "String Literal Expression" -> result = translateStringLiteralExpression(expression)
        "Interpolated String Literal Expression" -> result = translateInterpolatedStringLiteralExpression(expression)
        "Erasure Expression" -> {
            val lastExpression: SwiftAST? = expression.subtrees.lastOrNull()
            if (lastExpression != null) {
                val innerExpression: SwiftAST? = lastExpression.subtrees.lastOrNull()
                if (lastExpression.name == "Bind Optional Expression" && innerExpression != null) {
                    result = translateExpression(innerExpression)
                }
                else {
                    result = translateExpression(lastExpression)
                }
            }
            else {
                result = unexpectedExpressionStructureError(
                    "Unrecognized structure in automatic expression",
                    ast = expression,
                    translator = this)
            }
        }
        "Prefix Unary Expression" -> result = translatePrefixUnaryExpression(expression)
        "Postfix Unary Expression" -> result = translatePostfixUnaryExpression(expression)
        "Type Expression" -> result = translateTypeExpression(expression)
        "Member Reference Expression" -> result = translateMemberReferenceExpression(expression)
        "Tuple Element Expression" -> result = translateTupleElementExpression(expression)
        "Tuple Expression" -> result = translateTupleExpression(expression)
        "Subscript Expression" -> result = translateSubscriptExpression(expression)
        "Nil Literal Expression" -> result = Expression.NilLiteralExpression()
        "Open Existential Expression" -> {
            val processedExpression: SwiftAST = processOpenExistentialExpression(expression)
            result = translateExpression(processedExpression)
        }
        "Parentheses Expression" -> {
            val innerExpression: SwiftAST? = expression.subtree(index = 0)
            if (innerExpression != null) {
                if (expression.standaloneAttributes.contains("implicit")) {
                    result = translateExpression(innerExpression)
                }
                else {
                    result = Expression.ParenthesesExpression(expression = translateExpression(innerExpression))
                }
            }
            else {
                result = unexpectedExpressionStructureError(
                    "Expected parentheses expression to have at least one subtree",
                    ast = expression,
                    translator = this)
            }
        }
        "Force Value Expression" -> {
            val firstExpression: SwiftAST? = expression.subtree(index = 0)
            if (firstExpression != null) {
                val expression: Expression = translateExpression(firstExpression)
                result = Expression.ForceValueExpression(expression = expression)
            }
            else {
                result = unexpectedExpressionStructureError(
                    "Expected force value expression to have at least one subtree",
                    ast = expression,
                    translator = this)
            }
        }
        "Bind Optional Expression" -> {
            val firstExpression: SwiftAST? = expression.subtree(index = 0)
            if (firstExpression != null) {
                val expression: Expression = translateExpression(firstExpression)
                result = Expression.OptionalExpression(expression = expression)
            }
            else {
                result = unexpectedExpressionStructureError(
                    "Expected optional expression to have at least one subtree",
                    ast = expression,
                    translator = this)
            }
        }
        "Conditional Checked Cast Expression" -> {
            val bindOptionalExpression: SwiftAST? = expression.subtrees.firstOrNull()
            val bindOptionalSubtrees: MutableList<SwiftAST>? = bindOptionalExpression?.subtrees
            val subExpression: SwiftAST? = bindOptionalSubtrees?.firstOrNull()
            val typeName: String? = expression["type"]

            if (typeName != null && subExpression != null) {
                result = Expression.BinaryOperatorExpression(
                    leftExpression = translateExpression(subExpression),
                    rightExpression = Expression.TypeExpression(typeName = typeName),
                    operatorSymbol = "as?",
                    typeName = typeName)
            }
            else {
                result = unexpectedExpressionStructureError(
                    "Expected Conditional Checked Cast Expression to have a type and two nested " + "subtrees",
                    ast = expression,
                    translator = this)
            }
        }
        "Autoclosure Expression" -> {
            val lastExpression: SwiftAST? = expression.subtrees.lastOrNull()
            if (lastExpression != null) {
                result = translateExpression(lastExpression)
            }
            else {
                result = unexpectedExpressionStructureError(
                    "Unrecognized structure in automatic expression",
                    ast = expression,
                    translator = this)
            }
        }
        "Collection Upcast Expression" -> {
            val firstExpression: SwiftAST? = expression.subtrees.firstOrNull()
            if (firstExpression != null) {
                result = translateExpression(firstExpression)
            }
            else {
                result = unexpectedExpressionStructureError(
                    "Unrecognized structure in automatic expression",
                    ast = expression,
                    translator = this)
            }
        }
        else -> result = unexpectedExpressionStructureError("Unknown expression", ast = expression, translator = this)
    }

    val shouldInspect: Boolean = (getComment(ast = expression, key = "gryphon") == "inspect")

    if (shouldInspect) {
        println("===\nInspecting:")
        println(expression)
        result.prettyPrint()
    }

    return result
}

internal fun SwiftTranslator.translateTypeExpression(typeExpression: SwiftAST): Expression {
    if (typeExpression.name != "Type Expression") {
        return unexpectedExpressionStructureError(
            "Trying to translate ${typeExpression.name} as 'Type Expression'",
            ast = typeExpression,
            translator = this)
    }

    val typeName: String? = typeExpression["typerepr"]

    typeName ?: return unexpectedExpressionStructureError(
        "Unrecognized structure",
        ast = typeExpression,
        translator = this)

    return Expression.TypeExpression(typeName = cleanUpType(typeName))
}

internal fun SwiftTranslator.translateCallExpression(callExpression: SwiftAST): Expression {
    if (callExpression.name != "Call Expression") {
        return unexpectedExpressionStructureError(
            "Trying to translate ${callExpression.name} as 'Call Expression'",
            ast = callExpression,
            translator = this)
    }

    val argumentLabels: String? = callExpression["arg_labels"]

    if (argumentLabels != null) {
        if (argumentLabels == "_builtinIntegerLiteral:" || argumentLabels == "_builtinFloatLiteral:") {
            return translateAsNumericLiteral(callExpression)
        }
        else if (argumentLabels == "_builtinBooleanLiteral:") {
            return translateAsBooleanLiteral(callExpression)
        }
        else if (argumentLabels == "nilLiteral:") {
            return Expression.NilLiteralExpression()
        }
    }

    val function: Expression
    val dotSyntaxSubtrees: MutableList<SwiftAST>? = callExpression.subtree(name = "Dot Syntax Call Expression")?.subtrees
    val containedExpression: SwiftAST? = dotSyntaxSubtrees?.lastOrNull()

    if (containedExpression != null && callExpression.standaloneAttributes.contains("implicit") && callExpression["arg_labels"] == "" && callExpression["type"] == "Int1") {
        return translateExpression(containedExpression)
    }

    val rawType: String? = callExpression["type"]

    rawType ?: return unexpectedExpressionStructureError(
        "Failed to recognize type",
        ast = callExpression,
        translator = this)

    val typeName: String = cleanUpType(rawType)
    val dotSyntaxCallExpression: SwiftAST? = callExpression.subtree(name = "Dot Syntax Call Expression")
    val methodName: SwiftAST? = dotSyntaxCallExpression?.subtree(index = 0, name = "Declaration Reference Expression")
    val methodOwner: SwiftAST? = dotSyntaxCallExpression?.subtree(index = 1)
    val declarationReferenceExpression: SwiftAST? = callExpression.subtree(name = "Declaration Reference Expression")
    val typeExpression: SwiftAST? = callExpression.subtree(name = "Constructor Reference Call Expression")?.subtree(
        name = "Type Expression")

    if (methodName != null && methodOwner != null) {
        val methodName: Expression = translateDeclarationReferenceExpression(methodName)
        val methodOwner: Expression = translateExpression(methodOwner)
        function = Expression.DotExpression(leftExpression = methodOwner, rightExpression = methodName)
    }
    else if (declarationReferenceExpression != null) {
        function = translateDeclarationReferenceExpression(declarationReferenceExpression)
    }
    else if (typeExpression != null) {
        function = translateTypeExpression(typeExpression)
    }
    else {
        function = translateExpression(callExpression.subtrees[0])
    }

    val parameters: Expression = translateCallExpressionParameters(callExpression)
    val range: SourceFileRange? = getRange(ast = callExpression)

    return Expression.CallExpression(
        data = CallExpressionData(
                function = function,
                parameters = parameters,
                typeName = typeName,
                range = range))
}

internal fun SwiftTranslator.translateClosureExpression(closureExpression: SwiftAST): Expression {
    if (closureExpression.name != "Closure Expression") {
        return unexpectedExpressionStructureError(
            "Trying to translate ${closureExpression.name} as 'Closure Expression'",
            ast = closureExpression,
            translator = this)
    }

    val parameterList: SwiftAST?
    val unwrapped: SwiftAST? = closureExpression.subtree(name = "Parameter List")

    if (unwrapped != null) {
        parameterList = unwrapped
    }
    else {
        parameterList = null
    }

    val parameters: MutableList<LabeledType> = mutableListOf()

    if (parameterList != null) {
        for (parameter in parameterList.subtrees) {
            val name: String? = parameter.standaloneAttributes.firstOrNull()
            val typeName: String? = parameter["interface type"]
            if (name != null && typeName != null) {
                if (name.startsWith("anonname=0x")) {
                    continue
                }
                parameters.add(LabeledType(label = name, typeName = cleanUpType(typeName)))
            }
            else {
                return unexpectedExpressionStructureError(
                    "Unable to detect name or attribute for a parameter",
                    ast = closureExpression,
                    translator = this)
            }
        }
    }

    val typeName: String? = closureExpression["type"]

    typeName ?: return unexpectedExpressionStructureError(
        "Unable to get type or return type",
        ast = closureExpression,
        translator = this)

    val lastSubtree: SwiftAST? = closureExpression.subtrees.lastOrNull()

    lastSubtree ?: return unexpectedExpressionStructureError(
        "Unable to get closure body",
        ast = closureExpression,
        translator = this)

    val statements: MutableList<Statement>

    if (lastSubtree.name == "Brace Statement") {
        statements = translateBraceStatement(lastSubtree)
    }
    else {
        val expression: Expression = translateExpression(lastSubtree)
        statements = mutableListOf(Statement.ExpressionStatement(expression = expression))
    }

    return Expression.ClosureExpression(
        parameters = parameters,
        statements = statements,
        typeName = cleanUpType(typeName))
}

internal fun SwiftTranslator.translateCallExpressionParameters(
    callExpression: SwiftAST)
    : Expression
{
    if (callExpression.name != "Call Expression") {
        return unexpectedExpressionStructureError(
            "Trying to translate ${callExpression.name} as 'Call Expression'",
            ast = callExpression,
            translator = this)
    }

    val parameters: Expression
    val parenthesesExpression: SwiftAST? = callExpression.subtree(name = "Parentheses Expression")
    val tupleExpression: SwiftAST? = callExpression.subtree(name = "Tuple Expression")
    val tupleShuffleExpression: SwiftAST? = callExpression.subtree(name = "Tuple Shuffle Expression")

    if (parenthesesExpression != null) {
        val expression: Expression = translateExpression(parenthesesExpression)
        parameters = Expression.TupleExpression(
            pairs = mutableListOf(LabeledExpression(label = null, expression = expression)))
    }
    else if (tupleExpression != null) {
        parameters = translateTupleExpression(tupleExpression)
    }
    else if (tupleShuffleExpression != null) {
        val parenthesesExpression: SwiftAST? = tupleShuffleExpression.subtree(name = "Parentheses Expression")
        val tupleExpression: SwiftAST? = tupleShuffleExpression.subtree(name = "Tuple Expression")
        val typeName: String? = tupleShuffleExpression["type"]
        val elements: String? = tupleShuffleExpression["elements"]
        val rawIndicesStrings: MutableList<String>? = elements?.split(separator = ", ")
        val rawIndices: MutableList<Int?>? = rawIndicesStrings?.let { it.map { it.toIntOrNull() }.toMutableList() }

        if (parenthesesExpression != null) {
            val expression: Expression = translateExpression(parenthesesExpression)
            parameters = Expression.TupleExpression(
                pairs = mutableListOf(LabeledExpression(label = null, expression = expression)))
        }
        else if (tupleExpression != null && typeName != null && rawIndices != null) {
            val indices: MutableList<TupleShuffleIndex> = mutableListOf()

            for (rawIndex in rawIndices) {
                rawIndex ?: return unexpectedExpressionStructureError(
                    "Expected Tuple shuffle index but found nil",
                    ast = callExpression,
                    translator = this)
                if (rawIndex == -2) {
                    val variadicSources: MutableList<String>? = tupleShuffleExpression["variadic_sources"]?.split(separator = ", ")
                    val variadicCount: Int? = variadicSources?.size

                    variadicCount ?: return unexpectedExpressionStructureError(
                        "Failed to read variadic sources",
                        ast = callExpression,
                        translator = this)

                    indices.add(TupleShuffleIndex.Variadic(count = variadicCount))
                }
                else if (rawIndex == -1) {
                    indices.add(TupleShuffleIndex.Absent())
                }
                else if (rawIndex >= 0) {
                    indices.add(TupleShuffleIndex.Present())
                }
                else {
                    return unexpectedExpressionStructureError(
                        "Unknown tuple shuffle index: ${rawIndex}",
                        ast = callExpression,
                        translator = this)
                }
            }

            val tupleComponents: MutableList<String> = typeName.drop(1).dropLast(1).split(separator = ", ") as MutableList<String>
            val labels: MutableList<String> = tupleComponents.map { it.takeWhile { it != ':' } }.toMutableList().map { it }.toMutableList()
            val expressions: MutableList<Expression> = tupleExpression.subtrees.map { translateExpression(it) }.toMutableList()

            parameters = Expression.TupleShuffleExpression(labels = labels, indices = indices, expressions = expressions)
        }
        else {
            return unexpectedExpressionStructureError(
                "Unrecognized structure in parameters",
                ast = callExpression,
                translator = this)
        }
    }
    else {
        return unexpectedExpressionStructureError(
            "Unrecognized structure in parameters",
            ast = callExpression,
            translator = this)
    }

    return parameters
}

internal fun SwiftTranslator.translateTupleExpression(tupleExpression: SwiftAST): Expression {
    if (tupleExpression.name != "Tuple Expression") {
        return unexpectedExpressionStructureError(
            "Trying to translate ${tupleExpression.name} as 'Tuple Expression'",
            ast = tupleExpression,
            translator = this)
    }

    val names: String? = tupleExpression["names"]

    names ?: return Expression.TupleExpression(pairs = mutableListOf())

    val namesArray: MutableList<String> = names.split(separator = ',')
    val tuplePairs: MutableList<LabeledExpression> = mutableListOf()

    for ((name, expression) in namesArray.zip(tupleExpression.subtrees)) {
        val expression: Expression = translateExpression(expression)
        if (name == "_") {
            tuplePairs.add(LabeledExpression(label = null, expression = expression))
        }
        else {
            tuplePairs.add(LabeledExpression(label = name, expression = expression))
        }
    }

    return Expression.TupleExpression(pairs = tuplePairs)
}

internal fun SwiftTranslator.translateInterpolatedStringLiteralExpression(
    interpolatedStringLiteralExpression: SwiftAST)
    : Expression
{
    if (interpolatedStringLiteralExpression.name != "Interpolated String Literal Expression") {
        return unexpectedExpressionStructureError(
            "Trying to translate ${interpolatedStringLiteralExpression.name} as " + "'Interpolated String Literal Expression'",
            ast = interpolatedStringLiteralExpression,
            translator = this)
    }

    val braceStatement: SwiftAST? = interpolatedStringLiteralExpression.subtree(name = "Tap Expression")?.subtree(
        name = "Brace Statement")

    braceStatement ?: return unexpectedExpressionStructureError(
        "Expected the Interpolated String Literal Expression to contain a Tap" + "Expression containing a Brace Statement containing the String " + "interpolation contents",
        ast = interpolatedStringLiteralExpression,
        translator = this)

    val expressions: MutableList<Expression> = mutableListOf()

    for (callExpression in braceStatement.subtrees.drop(1)) {
        val maybeSubtrees: MutableList<SwiftAST>? = callExpression.subtree(name = "Parentheses Expression")?.subtrees
        val maybeExpression: SwiftAST? = maybeSubtrees?.firstOrNull()
        val expression: SwiftAST? = maybeExpression

        if (!(callExpression.name == "Call Expression" && expression != null)) {
            return unexpectedExpressionStructureError(
                "Expected the brace statement to contain only Call Expressions containing " + "Parentheses Expressions containing the relevant expressions.",
                ast = interpolatedStringLiteralExpression,
                translator = this)
        }

        val translatedExpression: Expression = translateExpression(expression)

        expressions.add(translatedExpression)
    }

    return Expression.InterpolatedStringLiteralExpression(expressions = expressions)
}

internal fun SwiftTranslator.translateSubscriptExpression(
    subscriptExpression: SwiftAST)
    : Expression
{
    if (subscriptExpression.name != "Subscript Expression") {
        return unexpectedExpressionStructureError(
            "Trying to translate ${subscriptExpression.name} as 'Subscript Expression'",
            ast = subscriptExpression,
            translator = this)
    }

    val rawType: String? = subscriptExpression["type"]
    val subscriptContents: SwiftAST? = subscriptExpression.subtree(index = 1, name = "Parentheses Expression") ?: subscriptExpression.subtree(index = 1, name = "Tuple Expression")
    val subscriptedExpression: SwiftAST? = subscriptExpression.subtree(index = 0)

    if (rawType != null && subscriptContents != null && subscriptedExpression != null) {
        val typeName: String = cleanUpType(rawType)
        val subscriptContentsTranslation: Expression = translateExpression(subscriptContents)
        val subscriptedExpressionTranslation: Expression = translateExpression(subscriptedExpression)

        return Expression.SubscriptExpression(
            subscriptedExpression = subscriptedExpressionTranslation,
            indexExpression = subscriptContentsTranslation,
            typeName = typeName)
    }
    else {
        return unexpectedExpressionStructureError(
            "Unrecognized structure",
            ast = subscriptExpression,
            translator = this)
    }
}

internal fun SwiftTranslator.translateArrayExpression(arrayExpression: SwiftAST): Expression {
    if (arrayExpression.name != "Array Expression") {
        return unexpectedExpressionStructureError(
            "Trying to translate ${arrayExpression.name} as 'Array Expression'",
            ast = arrayExpression,
            translator = this)
    }

    val expressionsToTranslate: MutableList<SwiftAST> = arrayExpression.subtrees.dropLast(1) as MutableList<SwiftAST>
    val expressionsArray: MutableList<Expression> = mutableListOf<Expression>()
    val rawType: String? = arrayExpression["type"]

    rawType ?: return unexpectedExpressionStructureError("Failed to get type", ast = arrayExpression, translator = this)

    val typeName: String = cleanUpType(rawType)

    return Expression.ArrayExpression(elements = expressionsArray, typeName = typeName)
}

internal fun SwiftTranslator.translateDictionaryExpression(
    dictionaryExpression: SwiftAST)
    : Expression
{
    if (dictionaryExpression.name != "Dictionary Expression") {
        return unexpectedExpressionStructureError(
            "Trying to translate ${dictionaryExpression.name} as 'Dictionary Expression'",
            ast = dictionaryExpression,
            translator = this)
    }

    val keys: MutableList<Expression> = mutableListOf()
    val values: MutableList<Expression> = mutableListOf()

    for (tupleExpression in dictionaryExpression.subtrees) {
        if (tupleExpression.name != "Tuple Expression") {
            continue
        }

        val keyAST: SwiftAST? = tupleExpression.subtree(index = 0)
        val valueAST: SwiftAST? = tupleExpression.subtree(index = 1)

        if (!(keyAST != null && valueAST != null)) {
            return unexpectedExpressionStructureError(
                "Unable to get either key or value for one of the tuple expressions",
                ast = dictionaryExpression,
                translator = this)
        }

        val keyTranslation: Expression = translateExpression(keyAST)
        val valueTranslation: Expression = translateExpression(valueAST)

        keys.add(keyTranslation)
        values.add(valueTranslation)
    }

    val typeName: String? = dictionaryExpression["type"]

    typeName ?: return unexpectedExpressionStructureError(
        "Unable to get type",
        ast = dictionaryExpression,
        translator = this)

    return Expression.DictionaryExpression(keys = keys, values = values, typeName = typeName)
}

internal fun SwiftTranslator.translateAsNumericLiteral(callExpression: SwiftAST): Expression {
    if (callExpression.name != "Call Expression") {
        return unexpectedExpressionStructureError(
            "Trying to translate ${callExpression.name} as 'Call Expression'",
            ast = callExpression,
            translator = this)
    }

    val tupleExpression: SwiftAST? = callExpression.subtree(name = "Tuple Expression")
    val literalExpression: SwiftAST? = tupleExpression?.subtree(name = "Integer Literal Expression") ?: tupleExpression?.subtree(name = "Float Literal Expression")
    val value: String? = literalExpression?.get("value")
    val constructorReferenceCallExpression: SwiftAST? = callExpression.subtree(name = "Constructor Reference Call Expression")
    val typeExpression: SwiftAST? = constructorReferenceCallExpression?.subtree(name = "Type Expression")
    val rawType: String? = typeExpression?.get("typerepr")

    if (value != null && literalExpression != null && rawType != null) {
        if (value.startsWith("0b") || value.startsWith("0o") || value.startsWith("0x")) {
            return unexpectedExpressionStructureError(
                "No support yet for alternative integer formats",
                ast = callExpression,
                translator = this)
        }

        val signedValue: String

        if (literalExpression.standaloneAttributes.contains("negative")) {
            signedValue = "-" + value
        }
        else {
            signedValue = value
        }

        val typeName: String = cleanUpType(rawType)

        if (typeName == "Double" || typeName == "Float64") {
            return Expression.LiteralDoubleExpression(value = signedValue.toDouble()!!)
        }
        else if (typeName == "Float" || typeName == "Float32") {
            return Expression.LiteralFloatExpression(value = signedValue.toFloat()!!)
        }
        else if (typeName == "Float80") {
            return unexpectedExpressionStructureError(
                "No support for 80-bit Floats",
                ast = callExpression,
                translator = this)
        }
        else if (typeName.startsWith("U")) {
            return Expression.LiteralUIntExpression(value = signedValue.toULong()!!)
        }
        else {
            if (signedValue == "-9223372036854775808") {
                return unexpectedExpressionStructureError(
                    "Kotlin's Long (equivalent to Int64) only goes down to " + "-9223372036854775807",
                    ast = callExpression,
                    translator = this)
            }
            else {
                return Expression.LiteralIntExpression(value = signedValue.toLong()!!)
            }
        }
    }
    else {
        return unexpectedExpressionStructureError(
            "Unrecognized structure for numeric literal",
            ast = callExpression,
            translator = this)
    }
}

internal fun SwiftTranslator.translateAsBooleanLiteral(callExpression: SwiftAST): Expression {
    if (callExpression.name != "Call Expression") {
        return unexpectedExpressionStructureError(
            "Trying to translate ${callExpression.name} as 'Call Expression'",
            ast = callExpression,
            translator = this)
    }
    val value: String? = callExpression.subtree(name = "Tuple Expression")?.subtree(name = "Boolean Literal Expression")?.get("value")
    if (value != null) {
        return Expression.LiteralBoolExpression(value = value == "true")
    }
    else {
        return unexpectedExpressionStructureError(
            "Unrecognized structure for boolean literal",
            ast = callExpression,
            translator = this)
    }
}

internal fun SwiftTranslator.translateStringLiteralExpression(
    stringLiteralExpression: SwiftAST)
    : Expression
{
    if (stringLiteralExpression.name != "String Literal Expression") {
        return unexpectedExpressionStructureError(
            "Trying to translate ${stringLiteralExpression.name} as " + "'String Literal Expression'",
            ast = stringLiteralExpression,
            translator = this)
    }
    val value: String? = stringLiteralExpression["value"]
    if (value != null) {
        if (stringLiteralExpression["type"] == "Character") {
            if (value == "'") {
                return Expression.LiteralCharacterExpression(value = "\\'")
            }
            else {
                return Expression.LiteralCharacterExpression(value = value)
            }
        }
        else {
            return Expression.LiteralStringExpression(value = value)
        }
    }
    else {
        return unexpectedExpressionStructureError(
            "Unrecognized structure",
            ast = stringLiteralExpression,
            translator = this)
    }
}

internal fun SwiftTranslator.translateDeclarationReferenceExpression(
    declarationReferenceExpression: SwiftAST)
    : Expression
{
    if (declarationReferenceExpression.name != "Declaration Reference Expression") {
        return unexpectedExpressionStructureError(
            "Trying to translate ${declarationReferenceExpression.name} as " + "'Declaration Reference Expression'",
            ast = declarationReferenceExpression,
            translator = this)
    }

    val rawType: String? = declarationReferenceExpression["type"]

    rawType ?: return unexpectedExpressionStructureError(
        "Failed to recognize type",
        ast = declarationReferenceExpression,
        translator = this)

    val typeName: String = cleanUpType(rawType)
    val isImplicit: Boolean = declarationReferenceExpression.standaloneAttributes.contains("implicit")
    val range: SourceFileRange? = getRange(ast = declarationReferenceExpression)
    val discriminator: String? = declarationReferenceExpression["discriminator"]
    val codeDeclaration: String? = declarationReferenceExpression.standaloneAttributes.firstOrNull()
    val declaration: String? = declarationReferenceExpression["decl"]

    if (discriminator != null) {
        val declarationInformation: SwiftTranslator.DeclarationInformation = getInformationFromDeclaration(discriminator)
        return Expression.DeclarationReferenceExpression(
            data = DeclarationReferenceData(
                    identifier = declarationInformation.identifier,
                    typeName = typeName,
                    isStandardLibrary = declarationInformation.isStandardLibrary,
                    isImplicit = isImplicit,
                    range = range))
    }
    else if (codeDeclaration != null && codeDeclaration.startsWith("code.")) {
        val declarationInformation: SwiftTranslator.DeclarationInformation = getInformationFromDeclaration(codeDeclaration)
        return Expression.DeclarationReferenceExpression(
            data = DeclarationReferenceData(
                    identifier = declarationInformation.identifier,
                    typeName = typeName,
                    isStandardLibrary = declarationInformation.isStandardLibrary,
                    isImplicit = isImplicit,
                    range = range))
    }
    else if (declaration != null) {
        val declarationInformation: SwiftTranslator.DeclarationInformation = getInformationFromDeclaration(declaration)
        return Expression.DeclarationReferenceExpression(
            data = DeclarationReferenceData(
                    identifier = declarationInformation.identifier,
                    typeName = typeName,
                    isStandardLibrary = declarationInformation.isStandardLibrary,
                    isImplicit = isImplicit,
                    range = range))
    }
    else {
        return unexpectedExpressionStructureError(
            "Unrecognized structure",
            ast = declarationReferenceExpression,
            translator = this)
    }
}

internal fun SwiftTranslator.insertedCode(range: IntRange): MutableList<SourceFile.Comment> {
    val result: MutableList<SourceFile.Comment> = mutableListOf()
    for (lineNumber in range) {
        val insertComment: SourceFile.Comment? = sourceFile?.getCommentFromLine(lineNumber)
        if (insertComment != null) {
            result.add(insertComment)
        }
    }
    return result
}

internal fun SwiftTranslator.getRangeRecursively(ast: SwiftAST): SourceFileRange? {
    val range: SourceFileRange? = getRange(ast = ast)

    if (range != null) {
        return range
    }

    for (subtree in ast.subtrees) {
        val range: SourceFileRange? = getRange(ast = subtree)
        if (range != null) {
            return range
        }
    }

    return null
}

internal fun SwiftTranslator.getComment(ast: SwiftAST, key: String): String? {
    val comment: SourceFile.Comment? = getComment(ast = ast)
    if (comment != null && comment.key == key) {
        return comment.value
    }
    return null
}

internal fun SwiftTranslator.getComment(ast: SwiftAST): SourceFile.Comment? {
    val lineNumber: Int? = getRange(ast = ast)?.lineStart
    if (lineNumber != null) {
        return sourceFile?.getCommentFromLine(lineNumber)
    }
    else {
        return null
    }
}

internal fun SwiftTranslator.getRange(ast: SwiftAST): SourceFileRange? {
    val rangeString: String? = ast["range"]

    rangeString ?: return null

    val firstSwiftExtensionEndIndex: Int? = rangeString.occurrences(searchedSubstring = ".swift:").firstOrNull()?.endInclusive

    firstSwiftExtensionEndIndex ?: return null

    var numberStartIndex: Int = firstSwiftExtensionEndIndex
    var numberEndIndex: Int = numberStartIndex

    while (rangeString[numberEndIndex].isNumber) {
        numberEndIndex = numberEndIndex + 1
    }

    val lineStartString: String = rangeString.substring(numberStartIndex, numberEndIndex)
    val lineStart: Int? = lineStartString.toIntOrNull()

    lineStart ?: return null

    numberStartIndex = numberEndIndex + 1
    numberEndIndex = numberStartIndex

    while (rangeString[numberEndIndex].isNumber) {
        numberEndIndex = numberEndIndex + 1
    }

    val columnStartString: String = rangeString.substring(numberStartIndex, numberEndIndex)
    val columnStart: Int? = columnStartString.toIntOrNull()

    columnStart ?: return null

    numberStartIndex = numberEndIndex + " - line:".length
    numberEndIndex = numberStartIndex

    while (rangeString[numberEndIndex].isNumber) {
        numberEndIndex = numberEndIndex + 1
    }

    val lineEndString: String = rangeString.substring(numberStartIndex, numberEndIndex)
    val lineEnd: Int? = lineEndString.toIntOrNull()

    lineEnd ?: return null

    numberStartIndex = numberEndIndex + 1
    numberEndIndex = numberStartIndex

    while (numberEndIndex < rangeString.length) {
        numberEndIndex = numberEndIndex + 1
    }

    val columnEndString: String = rangeString.substring(numberStartIndex, numberEndIndex)
    val columnEnd: Int? = columnEndString.toIntOrNull()

    columnEnd ?: return null

    return SourceFileRange(
        lineStart = lineStart,
        lineEnd = lineEnd,
        columnStart = columnStart,
        columnEnd = columnEnd)
}

internal fun SwiftTranslator.processPatternBindingDeclaration(
    patternBindingDeclaration: SwiftAST)
{
    if (patternBindingDeclaration.name != "Pattern Binding Declaration") {
        unexpectedExpressionStructureError(
            "Trying to translate ${patternBindingDeclaration.name} as " + "'Pattern Binding Declaration'",
            ast = patternBindingDeclaration,
            translator = this)
        danglingPatternBindings = mutableListOf(errorDanglingPatternDeclaration)
        return
    }

    val result: MutableList<SwiftTranslator.PatternBindingDeclaration?> = mutableListOf()
    val subtrees: MutableList<SwiftAST> = patternBindingDeclaration.subtrees

    while (!subtrees.isEmpty()) {
        var pattern: SwiftAST = subtrees.removeAt(0)
        val newPattern: SwiftAST? = pattern.subtree(name = "Pattern Named")

        if (newPattern != null && pattern.name == "Pattern Typed") {
            pattern = newPattern
        }

        val expression: SwiftAST? = subtrees.firstOrNull()

        if (expression != null && astIsExpression(expression)) {
            subtrees.removeAt(0)

            val translatedExpression: Expression = translateExpression(expression)
            val identifier: String? = pattern.standaloneAttributes.firstOrNull()
            val rawType: String? = pattern["type"]

            if (!(identifier != null && rawType != null)) {
                unexpectedExpressionStructureError(
                    "Type not recognized",
                    ast = patternBindingDeclaration,
                    translator = this)
                result.add(errorDanglingPatternDeclaration)
                continue
            }

            val typeName: String = cleanUpType(rawType)

            result.add(SwiftTranslator.PatternBindingDeclaration(
                identifier = identifier,
                typeName = typeName,
                expression = translatedExpression))
        }
        else {
            result.add(null)
        }
    }

    danglingPatternBindings = result
}

internal fun SwiftTranslator.processOpenExistentialExpression(
    openExistentialExpression: SwiftAST)
    : SwiftAST
{
    if (openExistentialExpression.name != "Open Existential Expression") {
        unexpectedExpressionStructureError(
            "Trying to translate ${openExistentialExpression.name} as " + "'Open Existential Expression'",
            ast = openExistentialExpression,
            translator = this)
        return SwiftAST("Error", mutableListOf(), mutableMapOf(), mutableListOf())
    }

    val replacementSubtree: SwiftAST? = openExistentialExpression.subtree(index = 1)
    val resultSubtree: SwiftAST? = openExistentialExpression.subtrees.lastOrNull()

    if (!(replacementSubtree != null && resultSubtree != null)) {
        unexpectedExpressionStructureError(
            "Expected the AST to contain 3 subtrees: an Opaque Value Expression, an " + "expression to replace the opaque value, and an expression containing " + "opaque values to be replaced.",
            ast = openExistentialExpression,
            translator = this)
        return SwiftAST("Error", mutableListOf(), mutableMapOf(), mutableListOf())
    }

    return astReplacingOpaqueValues(ast = resultSubtree, replacementAST = replacementSubtree)
}

internal fun SwiftTranslator.astReplacingOpaqueValues(
    ast: SwiftAST,
    replacementAST: SwiftAST)
    : SwiftAST
{
    if (ast.name == "Opaque Value Expression") {
        return replacementAST
    }

    val newSubtrees: MutableList<SwiftAST> = mutableListOf()

    for (subtree in ast.subtrees) {
        newSubtrees.add(astReplacingOpaqueValues(ast = subtree, replacementAST = replacementAST))
    }

    return SwiftAST(ast.name, ast.standaloneAttributes, ast.keyValueAttributes, newSubtrees)
}

internal fun SwiftTranslator.getInformationFromDeclaration(
    declaration: String)
    : SwiftTranslator.DeclarationInformation
{
    val isStandardLibrary: Boolean = declaration.startsWith("Swift")
    var index: Int = 0
    var lastPeriodIndex: Int = 0

    while (index != declaration.length) {
        val character: Char = declaration[index]

        if (character == '.') {
            lastPeriodIndex = index
        }

        if (character == '@') {
            break
        }

        index = index + 1
    }

    var beforeLastPeriodIndex: Int = lastPeriodIndex - 1

    while (declaration[beforeLastPeriodIndex] == '.') {
        lastPeriodIndex = beforeLastPeriodIndex
        beforeLastPeriodIndex = lastPeriodIndex - 1
    }

    val identifierStartIndex: Int = lastPeriodIndex + 1
    val identifier: String = declaration.substring(identifierStartIndex, index)

    return SwiftTranslator.DeclarationInformation(
        identifier = identifier,
        isStandardLibrary = isStandardLibrary)
}

internal fun SwiftTranslator.cleanUpType(typeName: String): String {
    if (typeName.startsWith("@lvalue ")) {
        return typeName.suffix(startIndex = "@lvalue ".length)
    }
    else if (typeName.startsWith("(") && typeName.endsWith(")") && !typeName.contains("->") && !typeName.contains(",")) {
        return typeName.drop(1).dropLast(1)
    }
    else {
        return typeName
    }
}

internal fun SwiftTranslator.astIsExpression(ast: SwiftAST): Boolean {
    return ast.name.endsWith("Expression") || ast.name == "Inject Into Optional"
}

internal fun SwiftTranslator.createUnexpectedASTStructureError(
    errorMessage: String,
    ast: SwiftAST,
    translator: SwiftTranslator)
    : SwiftTranslatorError
{
    return SwiftTranslatorError(errorMessage = errorMessage, ast = ast, translator = translator)
}

internal fun SwiftTranslator.handleUnexpectedASTStructureError(error: Exception): Statement {
    Compiler.handleError(error)
    return Statement.Error()
}

internal fun SwiftTranslator.unexpectedASTStructureError(
    errorMessage: String,
    ast: SwiftAST,
    translator: SwiftTranslator)
    : Statement
{
    val error: SwiftTranslatorError = createUnexpectedASTStructureError(errorMessage, ast = ast, translator = translator)
    return handleUnexpectedASTStructureError(error)
}

internal fun SwiftTranslator.unexpectedExpressionStructureError(
    errorMessage: String,
    ast: SwiftAST,
    translator: SwiftTranslator)
    : Expression
{
    val error: SwiftTranslatorError = SwiftTranslatorError(errorMessage = errorMessage, ast = ast, translator = translator)
    Compiler.handleError(error)
    return Expression.Error()
}

data class IfConditionsTranslation(
    val conditions: MutableList<IfStatementData.IfCondition>,
    val statements: MutableList<Statement>
)

data class EnumPatternTranslation(
    val enumType: String,
    val enumCase: String,
    val declarations: MutableList<AssociatedValueDeclaration>
)

data class AssociatedValueDeclaration(
    val associatedValueName: String,
    val associatedValueType: String,
    val newVariable: String
)

data class SwiftTranslatorError(
    val errorMessage: String,
    val ast: SwiftAST,
    val translator: SwiftTranslator
): Exception() {
    override fun toString(): String {
        var nodeDescription: String = ""

        ast.prettyPrint { nodeDescription += it }

        val details: String = "When translating the following AST node:\n${nodeDescription}"

        return Compiler.createErrorOrWarningMessage(
            message = errorMessage,
            details = details,
            sourceFile = translator.sourceFile,
            sourceFileRange = translator.getRangeRecursively(ast = ast))
    }
}
