open class TranspilationPass {
    companion object {
        internal fun isASwiftRawRepresentableType(typeName: String): Boolean {
            return mutableListOf("String", "Int", "Int8", "Int16", "Int32", "Int64", "UInt", "UInt8", "UInt16", "UInt32", "UInt64", "Float", "Float32", "Float64", "Float80", "Double").contains(typeName)
        }
    }

    var ast: GryphonAST
    var parents: MutableList<ASTNode> = mutableListOf()
    val parent: ASTNode
        get() {
            return parents.secondToLast!!
        }

    constructor(ast: GryphonAST) {
        this.ast = ast
    }

    open internal fun run(): GryphonAST {
        val replacedStatements: MutableList<Statement> = replaceStatements(ast.statements)
        val replacedDeclarations: MutableList<Statement> = replaceStatements(ast.declarations)
        return GryphonAST(
            sourceFile = ast.sourceFile,
            declarations = replacedDeclarations,
            statements = replacedStatements)
    }

    open internal fun replaceStatements(
        statements: MutableList<Statement>)
        : MutableList<Statement>
    {
        return statements.flatMap { replaceStatement(it) }.toMutableList()
    }

    open internal fun replaceStatement(statement: Statement): MutableList<Statement> {
        try {
            parents.add(ASTNode.StatementNode(value = statement))
            return when (statement) {
                is Statement.ExpressionStatement -> {
                    val expression: Expression = statement.expression
                    replaceExpressionStatement(expression = expression)
                }
                is Statement.ExtensionDeclaration -> {
                    val typeName: String = statement.typeName
                    val members: MutableList<Statement> = statement.members
                    replaceExtension(typeName = typeName, members = members)
                }
                is Statement.ImportDeclaration -> {
                    val moduleName: String = statement.moduleName
                    replaceImportDeclaration(moduleName = moduleName)
                }
                is Statement.TypealiasDeclaration -> {
                    val identifier: String = statement.identifier
                    val typeName: String = statement.typeName
                    val isImplicit: Boolean = statement.isImplicit

                    replaceTypealiasDeclaration(identifier = identifier, typeName = typeName, isImplicit = isImplicit)
                }
                is Statement.ClassDeclaration -> {
                    val name: String = statement.className
                    val inherits: MutableList<String> = statement.inherits
                    val members: MutableList<Statement> = statement.members

                    replaceClassDeclaration(name = name, inherits = inherits, members = members)
                }
                is Statement.CompanionObject -> {
                    val members: MutableList<Statement> = statement.members
                    replaceCompanionObject(members = members)
                }
                is Statement.EnumDeclaration -> {
                    val access: String? = statement.access
                    val enumName: String = statement.enumName
                    val inherits: MutableList<String> = statement.inherits
                    val elements: MutableList<EnumElement> = statement.elements
                    val members: MutableList<Statement> = statement.members
                    val isImplicit: Boolean = statement.isImplicit

                    replaceEnumDeclaration(
                        access = access,
                        enumName = enumName,
                        inherits = inherits,
                        elements = elements,
                        members = members,
                        isImplicit = isImplicit)
                }
                is Statement.ProtocolDeclaration -> {
                    val protocolName: String = statement.protocolName
                    val members: MutableList<Statement> = statement.members
                    replaceProtocolDeclaration(protocolName = protocolName, members = members)
                }
                is Statement.StructDeclaration -> {
                    val annotations: String? = statement.annotations
                    val structName: String = statement.structName
                    val inherits: MutableList<String> = statement.inherits
                    val members: MutableList<Statement> = statement.members

                    replaceStructDeclaration(
                        annotations = annotations,
                        structName = structName,
                        inherits = inherits,
                        members = members)
                }
                is Statement.FunctionDeclaration -> {
                    val functionDeclaration: FunctionDeclarationData = statement.data
                    replaceFunctionDeclaration(functionDeclaration)
                }
                is Statement.VariableDeclaration -> {
                    val variableDeclaration: VariableDeclarationData = statement.data
                    replaceVariableDeclaration(variableDeclaration)
                }
                is Statement.DoStatement -> {
                    val statements: MutableList<Statement> = statement.statements
                    replaceDoStatement(statements = statements)
                }
                is Statement.CatchStatement -> {
                    val variableDeclaration: VariableDeclarationData? = statement.variableDeclaration
                    val statements: MutableList<Statement> = statement.statements
                    replaceCatchStatement(variableDeclaration = variableDeclaration, statements = statements)
                }
                is Statement.ForEachStatement -> {
                    val collection: Expression = statement.collection
                    val variable: Expression = statement.variable
                    val statements: MutableList<Statement> = statement.statements

                    replaceForEachStatement(collection = collection, variable = variable, statements = statements)
                }
                is Statement.WhileStatement -> {
                    val expression: Expression = statement.expression
                    val statements: MutableList<Statement> = statement.statements
                    replaceWhileStatement(expression = expression, statements = statements)
                }
                is Statement.IfStatement -> {
                    val ifStatement: IfStatementData = statement.data
                    replaceIfStatement(ifStatement)
                }
                is Statement.SwitchStatement -> {
                    val convertsToExpression: Statement? = statement.convertsToExpression
                    val expression: Expression = statement.expression
                    val cases: MutableList<SwitchCase> = statement.cases

                    replaceSwitchStatement(
                        convertsToExpression = convertsToExpression,
                        expression = expression,
                        cases = cases)
                }
                is Statement.DeferStatement -> {
                    val statements: MutableList<Statement> = statement.statements
                    replaceDeferStatement(statements = statements)
                }
                is Statement.ThrowStatement -> {
                    val expression: Expression = statement.expression
                    replaceThrowStatement(expression = expression)
                }
                is Statement.ReturnStatement -> {
                    val expression: Expression? = statement.expression
                    replaceReturnStatement(expression = expression)
                }
                is Statement.BreakStatement -> mutableListOf(Statement.BreakStatement())
                is Statement.ContinueStatement -> mutableListOf(Statement.ContinueStatement())
                is Statement.AssignmentStatement -> {
                    val leftHand: Expression = statement.leftHand
                    val rightHand: Expression = statement.rightHand
                    replaceAssignmentStatement(leftHand = leftHand, rightHand = rightHand)
                }
                is Statement.Error -> mutableListOf(Statement.Error())
            }
        }
        finally {
            parents.removeLast()
        }
    }

    open internal fun replaceExpressionStatement(expression: Expression): MutableList<Statement> {
        return mutableListOf(Statement.ExpressionStatement(expression = replaceExpression(expression)))
    }

    open internal fun replaceExtension(
        typeName: String,
        members: MutableList<Statement>)
        : MutableList<Statement>
    {
        return mutableListOf(Statement.ExtensionDeclaration(typeName = typeName, members = replaceStatements(members)))
    }

    open internal fun replaceImportDeclaration(moduleName: String): MutableList<Statement> {
        return mutableListOf(Statement.ImportDeclaration(moduleName = moduleName))
    }

    open internal fun replaceTypealiasDeclaration(
        identifier: String,
        typeName: String,
        isImplicit: Boolean)
        : MutableList<Statement>
    {
        return mutableListOf(Statement.TypealiasDeclaration(
            identifier = identifier,
            typeName = typeName,
            isImplicit = isImplicit))
    }

    open internal fun replaceClassDeclaration(
        name: String,
        inherits: MutableList<String>,
        members: MutableList<Statement>)
        : MutableList<Statement>
    {
        return mutableListOf(Statement.ClassDeclaration(
            className = name,
            inherits = inherits,
            members = replaceStatements(members)))
    }

    open internal fun replaceCompanionObject(
        members: MutableList<Statement>)
        : MutableList<Statement>
    {
        return mutableListOf(Statement.CompanionObject(members = replaceStatements(members)))
    }

    open internal fun replaceEnumDeclaration(
        access: String?,
        enumName: String,
        inherits: MutableList<String>,
        elements: MutableList<EnumElement>,
        members: MutableList<Statement>,
        isImplicit: Boolean)
        : MutableList<Statement>
    {
        return mutableListOf(Statement.EnumDeclaration(
            access = access,
            enumName = enumName,
            inherits = inherits,
            elements = elements.flatMap { replaceEnumElementDeclaration(
                    enumName = it.name,
                    associatedValues = it.associatedValues,
                    rawValue = it.rawValue,
                    annotations = it.annotations) }.toMutableList(),
            members = replaceStatements(members),
            isImplicit = isImplicit))
    }

    open internal fun replaceEnumElementDeclaration(
        enumName: String,
        associatedValues: MutableList<LabeledType>,
        rawValue: Expression?,
        annotations: String?)
        : MutableList<EnumElement>
    {
        return mutableListOf(EnumElement(
            name = enumName,
            associatedValues = associatedValues,
            rawValue = rawValue,
            annotations = annotations))
    }

    open internal fun replaceProtocolDeclaration(
        protocolName: String,
        members: MutableList<Statement>)
        : MutableList<Statement>
    {
        return mutableListOf(Statement.ProtocolDeclaration(protocolName = protocolName, members = replaceStatements(members)))
    }

    open internal fun replaceStructDeclaration(
        annotations: String?,
        structName: String,
        inherits: MutableList<String>,
        members: MutableList<Statement>)
        : MutableList<Statement>
    {
        return mutableListOf(Statement.StructDeclaration(
            annotations = annotations,
            structName = structName,
            inherits = inherits,
            members = replaceStatements(members)))
    }

    open internal fun replaceFunctionDeclaration(
        functionDeclaration: FunctionDeclarationData)
        : MutableList<Statement>
    {
        val result: FunctionDeclarationData? = replaceFunctionDeclarationData(functionDeclaration)
        if (result != null) {
            return mutableListOf(Statement.FunctionDeclaration(data = result))
        }
        else {
            return mutableListOf()
        }
    }

    open internal fun replaceFunctionDeclarationData(
        functionDeclaration: FunctionDeclarationData)
        : FunctionDeclarationData?
    {
        val replacedParameters: MutableList<FunctionParameter> = functionDeclaration.parameters.map { FunctionParameter(
            label = it.label,
            apiLabel = it.apiLabel,
            typeName = it.typeName,
            value = it.value?.let { replaceExpression(it) }) }.toMutableList()
        val functionDeclaration: FunctionDeclarationData = functionDeclaration

        functionDeclaration.parameters = replacedParameters
        functionDeclaration.statements = functionDeclaration.statements?.let { replaceStatements(it) }

        return functionDeclaration
    }

    open internal fun replaceVariableDeclaration(
        variableDeclaration: VariableDeclarationData)
        : MutableList<Statement>
    {
        return mutableListOf(Statement.VariableDeclaration(data = replaceVariableDeclarationData(variableDeclaration)))
    }

    open internal fun replaceVariableDeclarationData(
        variableDeclaration: VariableDeclarationData)
        : VariableDeclarationData
    {
        val variableDeclaration: VariableDeclarationData = variableDeclaration

        variableDeclaration.expression = variableDeclaration.expression?.let { replaceExpression(it) }

        val getter: FunctionDeclarationData? = variableDeclaration.getter

        if (getter != null) {
            variableDeclaration.getter = replaceFunctionDeclarationData(getter)
        }

        val setter: FunctionDeclarationData? = variableDeclaration.setter

        if (setter != null) {
            variableDeclaration.setter = replaceFunctionDeclarationData(setter)
        }

        return variableDeclaration
    }

    open internal fun replaceDoStatement(
        statements: MutableList<Statement>)
        : MutableList<Statement>
    {
        return mutableListOf(Statement.DoStatement(statements = replaceStatements(statements)))
    }

    open internal fun replaceCatchStatement(
        variableDeclaration: VariableDeclarationData?,
        statements: MutableList<Statement>)
        : MutableList<Statement>
    {
        return mutableListOf(Statement.CatchStatement(
            variableDeclaration = variableDeclaration?.let { replaceVariableDeclarationData(it) },
            statements = replaceStatements(statements)))
    }

    open internal fun replaceForEachStatement(
        collection: Expression,
        variable: Expression,
        statements: MutableList<Statement>)
        : MutableList<Statement>
    {
        return mutableListOf(Statement.ForEachStatement(
            collection = replaceExpression(collection),
            variable = replaceExpression(variable),
            statements = replaceStatements(statements)))
    }

    open internal fun replaceWhileStatement(
        expression: Expression,
        statements: MutableList<Statement>)
        : MutableList<Statement>
    {
        return mutableListOf(Statement.WhileStatement(
            expression = replaceExpression(expression),
            statements = replaceStatements(statements)))
    }

    open internal fun replaceIfStatement(ifStatement: IfStatementData): MutableList<Statement> {
        return mutableListOf(Statement.IfStatement(data = replaceIfStatementData(ifStatement)))
    }

    open internal fun replaceIfStatementData(ifStatement: IfStatementData): IfStatementData {
        val ifStatement: IfStatementData = ifStatement

        ifStatement.conditions = replaceIfConditions(ifStatement.conditions)
        ifStatement.declarations = ifStatement.declarations.map { replaceVariableDeclarationData(it) }.toMutableList()
        ifStatement.statements = replaceStatements(ifStatement.statements)
        ifStatement.elseStatement = ifStatement.elseStatement?.let { replaceIfStatementData(it) }

        return ifStatement
    }

    open internal fun replaceIfConditions(
        conditions: MutableList<IfStatementData.IfCondition>)
        : MutableList<IfStatementData.IfCondition>
    {
        return conditions.map { replaceIfCondition(it) }.toMutableList()
    }

    open internal fun replaceIfCondition(
        condition: IfStatementData.IfCondition)
        : IfStatementData.IfCondition
    {
        return when (condition) {
            is IfStatementData.IfCondition.Condition -> {
                val expression: Expression = condition.expression
                IfStatementData.IfCondition.Condition(expression = replaceExpression(expression))
            }
            is IfStatementData.IfCondition.Declaration -> {
                val variableDeclaration: VariableDeclarationData = condition.variableDeclaration
                IfStatementData.IfCondition.Declaration(
                    variableDeclaration = replaceVariableDeclarationData(variableDeclaration))
            }
        }
    }

    open internal fun replaceSwitchStatement(
        convertsToExpression: Statement?,
        expression: Expression,
        cases: MutableList<SwitchCase>)
        : MutableList<Statement>
    {
        val replacedConvertsToExpression: Statement?

        if (convertsToExpression != null) {
            val replacedExpression: Statement? = replaceStatement(convertsToExpression).firstOrNull()
            if (replacedExpression != null) {
                replacedConvertsToExpression = replacedExpression
            }
            else {
                replacedConvertsToExpression = null
            }
        }
        else {
            replacedConvertsToExpression = null
        }

        val replacedCases: MutableList<SwitchCase> = cases.map { SwitchCase(
            expressions = it.expressions.map { replaceExpression(it) }.toMutableList(),
            statements = replaceStatements(it.statements)) }.toMutableList()

        return mutableListOf(Statement.SwitchStatement(
            convertsToExpression = replacedConvertsToExpression,
            expression = replaceExpression(expression),
            cases = replacedCases))
    }

    open internal fun replaceDeferStatement(
        statements: MutableList<Statement>)
        : MutableList<Statement>
    {
        return mutableListOf(Statement.DeferStatement(statements = replaceStatements(statements)))
    }

    open internal fun replaceThrowStatement(expression: Expression): MutableList<Statement> {
        return mutableListOf(Statement.ThrowStatement(expression = replaceExpression(expression)))
    }

    open internal fun replaceReturnStatement(expression: Expression?): MutableList<Statement> {
        return mutableListOf(Statement.ReturnStatement(expression = expression?.let { replaceExpression(it) }))
    }

    open internal fun replaceAssignmentStatement(
        leftHand: Expression,
        rightHand: Expression)
        : MutableList<Statement>
    {
        return mutableListOf(Statement.AssignmentStatement(
            leftHand = replaceExpression(leftHand),
            rightHand = replaceExpression(rightHand)))
    }

    open internal fun replaceExpression(expression: Expression): Expression {
        try {
            parents.add(ASTNode.ExpressionNode(value = expression))
            return when (expression) {
                is Expression.TemplateExpression -> {
                    val pattern: String = expression.pattern
                    val matches: MutableMap<String, Expression> = expression.matches
                    replaceTemplateExpression(pattern = pattern, matches = matches)
                }
                is Expression.LiteralCodeExpression -> {
                    val string: String = expression.string
                    replaceLiteralCodeExpression(string = string)
                }
                is Expression.LiteralDeclarationExpression -> {
                    val string: String = expression.string
                    replaceLiteralCodeExpression(string = string)
                }
                is Expression.ParenthesesExpression -> {
                    val expression: Expression = expression.expression
                    replaceParenthesesExpression(expression = expression)
                }
                is Expression.ForceValueExpression -> {
                    val expression: Expression = expression.expression
                    replaceForceValueExpression(expression = expression)
                }
                is Expression.OptionalExpression -> {
                    val expression: Expression = expression.expression
                    replaceOptionalExpression(expression = expression)
                }
                is Expression.DeclarationReferenceExpression -> {
                    val declarationReferenceExpression: DeclarationReferenceData = expression.data
                    replaceDeclarationReferenceExpression(declarationReferenceExpression)
                }
                is Expression.TypeExpression -> {
                    val typeName: String = expression.typeName
                    replaceTypeExpression(typeName = typeName)
                }
                is Expression.SubscriptExpression -> {
                    val subscriptedExpression: Expression = expression.subscriptedExpression
                    val indexExpression: Expression = expression.indexExpression
                    val typeName: String = expression.typeName

                    replaceSubscriptExpression(
                        subscriptedExpression = subscriptedExpression,
                        indexExpression = indexExpression,
                        typeName = typeName)
                }
                is Expression.ArrayExpression -> {
                    val elements: MutableList<Expression> = expression.elements
                    val typeName: String = expression.typeName
                    replaceArrayExpression(elements = elements, typeName = typeName)
                }
                is Expression.DictionaryExpression -> {
                    val keys: MutableList<Expression> = expression.keys
                    val values: MutableList<Expression> = expression.values
                    val typeName: String = expression.typeName

                    replaceDictionaryExpression(keys = keys, values = values, typeName = typeName)
                }
                is Expression.ReturnExpression -> {
                    val innerExpression: Expression? = expression.expression
                    replaceReturnExpression(innerExpression = innerExpression)
                }
                is Expression.DotExpression -> {
                    val leftExpression: Expression = expression.leftExpression
                    val rightExpression: Expression = expression.rightExpression
                    replaceDotExpression(leftExpression = leftExpression, rightExpression = rightExpression)
                }
                is Expression.BinaryOperatorExpression -> {
                    val leftExpression: Expression = expression.leftExpression
                    val rightExpression: Expression = expression.rightExpression
                    val operatorSymbol: String = expression.operatorSymbol
                    val typeName: String = expression.typeName

                    replaceBinaryOperatorExpression(
                        leftExpression = leftExpression,
                        rightExpression = rightExpression,
                        operatorSymbol = operatorSymbol,
                        typeName = typeName)
                }
                is Expression.PrefixUnaryExpression -> {
                    val subExpression: Expression = expression.subExpression
                    val operatorSymbol: String = expression.operatorSymbol
                    val typeName: String = expression.typeName

                    replacePrefixUnaryExpression(
                        subExpression = subExpression,
                        operatorSymbol = operatorSymbol,
                        typeName = typeName)
                }
                is Expression.PostfixUnaryExpression -> {
                    val subExpression: Expression = expression.subExpression
                    val operatorSymbol: String = expression.operatorSymbol
                    val typeName: String = expression.typeName

                    replacePostfixUnaryExpression(
                        subExpression = subExpression,
                        operatorSymbol = operatorSymbol,
                        typeName = typeName)
                }
                is Expression.IfExpression -> {
                    val condition: Expression = expression.condition
                    val trueExpression: Expression = expression.trueExpression
                    val falseExpression: Expression = expression.falseExpression

                    replaceIfExpression(
                        condition = condition,
                        trueExpression = trueExpression,
                        falseExpression = falseExpression)
                }
                is Expression.CallExpression -> {
                    val callExpression: CallExpressionData = expression.data
                    replaceCallExpression(callExpression)
                }
                is Expression.ClosureExpression -> {
                    val parameters: MutableList<LabeledType> = expression.parameters
                    val statements: MutableList<Statement> = expression.statements
                    val typeName: String = expression.typeName

                    replaceClosureExpression(parameters = parameters, statements = statements, typeName = typeName)
                }
                is Expression.LiteralIntExpression -> {
                    val value: Long = expression.value
                    replaceLiteralIntExpression(value = value)
                }
                is Expression.LiteralUIntExpression -> {
                    val value: ULong = expression.value
                    replaceLiteralUIntExpression(value = value)
                }
                is Expression.LiteralDoubleExpression -> {
                    val value: Double = expression.value
                    replaceLiteralDoubleExpression(value = value)
                }
                is Expression.LiteralFloatExpression -> {
                    val value: Float = expression.value
                    replaceLiteralFloatExpression(value = value)
                }
                is Expression.LiteralBoolExpression -> {
                    val value: Boolean = expression.value
                    replaceLiteralBoolExpression(value = value)
                }
                is Expression.LiteralStringExpression -> {
                    val value: String = expression.value
                    replaceLiteralStringExpression(value = value)
                }
                is Expression.LiteralCharacterExpression -> {
                    val value: String = expression.value
                    replaceLiteralCharacterExpression(value = value)
                }
                is Expression.NilLiteralExpression -> replaceNilLiteralExpression()
                is Expression.InterpolatedStringLiteralExpression -> {
                    val expressions: MutableList<Expression> = expression.expressions
                    replaceInterpolatedStringLiteralExpression(expressions = expressions)
                }
                is Expression.TupleExpression -> {
                    val pairs: MutableList<LabeledExpression> = expression.pairs
                    replaceTupleExpression(pairs = pairs)
                }
                is Expression.TupleShuffleExpression -> {
                    val labels: MutableList<String> = expression.labels
                    val indices: MutableList<TupleShuffleIndex> = expression.indices
                    val expressions: MutableList<Expression> = expression.expressions

                    replaceTupleShuffleExpression(labels = labels, indices = indices, expressions = expressions)
                }
                is Expression.Error -> Expression.Error()
            }
        }
        finally {
            parents.removeLast()
        }
    }

    open internal fun replaceTemplateExpression(
        pattern: String,
        matches: MutableMap<String, Expression>)
        : Expression
    {
        val newMatches = matches.mapValues { replaceExpression(it.value) }.toMutableMap()
        return Expression.TemplateExpression(pattern = pattern, matches = newMatches)
    }

    open internal fun replaceLiteralCodeExpression(string: String): Expression {
        return Expression.LiteralCodeExpression(string = string)
    }

    open internal fun replaceParenthesesExpression(expression: Expression): Expression {
        return Expression.ParenthesesExpression(expression = replaceExpression(expression))
    }

    open internal fun replaceForceValueExpression(expression: Expression): Expression {
        return Expression.ForceValueExpression(expression = replaceExpression(expression))
    }

    open internal fun replaceOptionalExpression(expression: Expression): Expression {
        return Expression.OptionalExpression(expression = replaceExpression(expression))
    }

    open internal fun replaceDeclarationReferenceExpression(
        declarationReferenceExpression: DeclarationReferenceData)
        : Expression
    {
        return Expression.DeclarationReferenceExpression(
            data = replaceDeclarationReferenceExpressionData(declarationReferenceExpression))
    }

    open internal fun replaceDeclarationReferenceExpressionData(
        declarationReferenceExpression: DeclarationReferenceData)
        : DeclarationReferenceData
    {
        return declarationReferenceExpression
    }

    open internal fun replaceTypeExpression(typeName: String): Expression {
        return Expression.TypeExpression(typeName = typeName)
    }

    open internal fun replaceSubscriptExpression(
        subscriptedExpression: Expression,
        indexExpression: Expression,
        typeName: String)
        : Expression
    {
        return Expression.SubscriptExpression(
            subscriptedExpression = replaceExpression(subscriptedExpression),
            indexExpression = replaceExpression(indexExpression),
            typeName = typeName)
    }

    open internal fun replaceArrayExpression(
        elements: MutableList<Expression>,
        typeName: String)
        : Expression
    {
        return Expression.ArrayExpression(
            elements = elements.map { replaceExpression(it) }.toMutableList(),
            typeName = typeName)
    }

    open internal fun replaceDictionaryExpression(
        keys: MutableList<Expression>,
        values: MutableList<Expression>,
        typeName: String)
        : Expression
    {
        return Expression.DictionaryExpression(keys = keys, values = values, typeName = typeName)
    }

    open internal fun replaceReturnExpression(innerExpression: Expression?): Expression {
        return Expression.ReturnExpression(expression = innerExpression?.let { replaceExpression(it) })
    }

    open internal fun replaceDotExpression(
        leftExpression: Expression,
        rightExpression: Expression)
        : Expression
    {
        return Expression.DotExpression(
            leftExpression = replaceExpression(leftExpression),
            rightExpression = replaceExpression(rightExpression))
    }

    open internal fun replaceBinaryOperatorExpression(
        leftExpression: Expression,
        rightExpression: Expression,
        operatorSymbol: String,
        typeName: String)
        : Expression
    {
        return Expression.BinaryOperatorExpression(
            leftExpression = replaceExpression(leftExpression),
            rightExpression = replaceExpression(rightExpression),
            operatorSymbol = operatorSymbol,
            typeName = typeName)
    }

    open internal fun replacePrefixUnaryExpression(
        subExpression: Expression,
        operatorSymbol: String,
        typeName: String)
        : Expression
    {
        return Expression.PrefixUnaryExpression(
            subExpression = replaceExpression(subExpression),
            operatorSymbol = operatorSymbol,
            typeName = typeName)
    }

    open internal fun replacePostfixUnaryExpression(
        subExpression: Expression,
        operatorSymbol: String,
        typeName: String)
        : Expression
    {
        return Expression.PostfixUnaryExpression(
            subExpression = replaceExpression(subExpression),
            operatorSymbol = operatorSymbol,
            typeName = typeName)
    }

    open internal fun replaceIfExpression(
        condition: Expression,
        trueExpression: Expression,
        falseExpression: Expression)
        : Expression
    {
        return Expression.IfExpression(
            condition = replaceExpression(condition),
            trueExpression = replaceExpression(trueExpression),
            falseExpression = replaceExpression(falseExpression))
    }

    open internal fun replaceCallExpression(callExpression: CallExpressionData): Expression {
        return Expression.CallExpression(data = replaceCallExpressionData(callExpression))
    }

    open internal fun replaceCallExpressionData(
        callExpression: CallExpressionData)
        : CallExpressionData
    {
        return CallExpressionData(
            function = replaceExpression(callExpression.function),
            parameters = replaceExpression(callExpression.parameters),
            typeName = callExpression.typeName,
            range = callExpression.range)
    }

    open internal fun replaceClosureExpression(
        parameters: MutableList<LabeledType>,
        statements: MutableList<Statement>,
        typeName: String)
        : Expression
    {
        return Expression.ClosureExpression(
            parameters = parameters,
            statements = replaceStatements(statements),
            typeName = typeName)
    }

    open internal fun replaceLiteralIntExpression(value: Long): Expression {
        return Expression.LiteralIntExpression(value = value)
    }

    open internal fun replaceLiteralUIntExpression(value: ULong): Expression {
        return Expression.LiteralUIntExpression(value = value)
    }

    open internal fun replaceLiteralDoubleExpression(value: Double): Expression {
        return Expression.LiteralDoubleExpression(value = value)
    }

    open internal fun replaceLiteralFloatExpression(value: Float): Expression {
        return Expression.LiteralFloatExpression(value = value)
    }

    open internal fun replaceLiteralBoolExpression(value: Boolean): Expression {
        return Expression.LiteralBoolExpression(value = value)
    }

    open internal fun replaceLiteralStringExpression(value: String): Expression {
        return Expression.LiteralStringExpression(value = value)
    }

    open internal fun replaceLiteralCharacterExpression(value: String): Expression {
        return Expression.LiteralCharacterExpression(value = value)
    }

    open internal fun replaceNilLiteralExpression(): Expression {
        return Expression.NilLiteralExpression()
    }

    open internal fun replaceInterpolatedStringLiteralExpression(
        expressions: MutableList<Expression>)
        : Expression
    {
        return Expression.InterpolatedStringLiteralExpression(
            expressions = expressions.map { replaceExpression(it) }.toMutableList())
    }

    open internal fun replaceTupleExpression(pairs: MutableList<LabeledExpression>): Expression {
        return Expression.TupleExpression(
            pairs = pairs.map { LabeledExpression(label = it.label, expression = replaceExpression(it.expression)) }.toMutableList())
    }

    open internal fun replaceTupleShuffleExpression(
        labels: MutableList<String>,
        indices: MutableList<TupleShuffleIndex>,
        expressions: MutableList<Expression>)
        : Expression
    {
        return Expression.TupleShuffleExpression(
            labels = labels,
            indices = indices,
            expressions = expressions.map { replaceExpression(it) }.toMutableList())
    }
}

open class DescriptionAsToStringTranspilationPass: TranspilationPass {
    constructor(ast: GryphonAST): super(ast) { }

    override internal fun replaceVariableDeclaration(
        variableDeclaration: VariableDeclarationData)
        : MutableList<Statement>
    {
        val getter: FunctionDeclarationData? = variableDeclaration.getter
        if (variableDeclaration.identifier == "description" && variableDeclaration.typeName == "String" && getter != null) {
            return mutableListOf(Statement.FunctionDeclaration(
                data = FunctionDeclarationData(
                        prefix = "toString",
                        parameters = mutableListOf(),
                        returnType = "String",
                        functionType = "() -> String",
                        genericTypes = mutableListOf(),
                        isImplicit = false,
                        isStatic = false,
                        isMutating = false,
                        isPure = false,
                        extendsType = variableDeclaration.extendsType,
                        statements = getter.statements,
                        access = null,
                        annotations = variableDeclaration.annotations)))
        }
        return super.replaceVariableDeclaration(variableDeclaration)
    }
}

open class RemoveParenthesesTranspilationPass: TranspilationPass {
    constructor(ast: GryphonAST): super(ast) { }

    override internal fun replaceSubscriptExpression(
        subscriptedExpression: Expression,
        indexExpression: Expression,
        typeName: String)
        : Expression
    {
        if (indexExpression is Expression.ParenthesesExpression) {
            val innerExpression: Expression = indexExpression.expression
            return super.replaceSubscriptExpression(
                subscriptedExpression = subscriptedExpression,
                indexExpression = innerExpression,
                typeName = typeName)
        }
        return super.replaceSubscriptExpression(
            subscriptedExpression = subscriptedExpression,
            indexExpression = indexExpression,
            typeName = typeName)
    }

    override internal fun replaceParenthesesExpression(expression: Expression): Expression {
        val myParent: ASTNode = this.parent
        if (myParent is ASTNode.ExpressionNode) {
            val parentExpression: Expression = myParent.value
            when (parentExpression) {
                is Expression.TupleExpression, is Expression.InterpolatedStringLiteralExpression -> return replaceExpression(expression)
            }
        }
        return Expression.ParenthesesExpression(expression = replaceExpression(expression))
    }

    override internal fun replaceIfExpression(
        condition: Expression,
        trueExpression: Expression,
        falseExpression: Expression)
        : Expression
    {
        val replacedCondition: Expression

        if (condition is Expression.ParenthesesExpression) {
            val innerExpression: Expression = condition.expression
            replacedCondition = innerExpression
        }
        else {
            replacedCondition = condition
        }

        val replacedTrueExpression: Expression

        if (trueExpression is Expression.ParenthesesExpression) {
            val innerExpression: Expression = trueExpression.expression
            replacedTrueExpression = innerExpression
        }
        else {
            replacedTrueExpression = trueExpression
        }

        val replacedFalseExpression: Expression

        if (falseExpression is Expression.ParenthesesExpression) {
            val innerExpression: Expression = falseExpression.expression
            replacedFalseExpression = innerExpression
        }
        else {
            replacedFalseExpression = falseExpression
        }

        return Expression.IfExpression(
            condition = replacedCondition,
            trueExpression = replacedTrueExpression,
            falseExpression = replacedFalseExpression)
    }
}

open class RemoveImplicitDeclarationsTranspilationPass: TranspilationPass {
    constructor(ast: GryphonAST): super(ast) { }

    override internal fun replaceEnumDeclaration(
        access: String?,
        enumName: String,
        inherits: MutableList<String>,
        elements: MutableList<EnumElement>,
        members: MutableList<Statement>,
        isImplicit: Boolean)
        : MutableList<Statement>
    {
        if (isImplicit) {
            return mutableListOf()
        }
        else {
            return super.replaceEnumDeclaration(
                access = access,
                enumName = enumName,
                inherits = inherits,
                elements = elements,
                members = members,
                isImplicit = isImplicit)
        }
    }

    override internal fun replaceTypealiasDeclaration(
        identifier: String,
        typeName: String,
        isImplicit: Boolean)
        : MutableList<Statement>
    {
        if (isImplicit) {
            return mutableListOf()
        }
        else {
            return super.replaceTypealiasDeclaration(
                identifier = identifier,
                typeName = typeName,
                isImplicit = isImplicit)
        }
    }

    override internal fun replaceVariableDeclaration(
        variableDeclaration: VariableDeclarationData)
        : MutableList<Statement>
    {
        if (variableDeclaration.isImplicit) {
            return mutableListOf()
        }
        else {
            return super.replaceVariableDeclaration(variableDeclaration)
        }
    }

    override internal fun replaceFunctionDeclarationData(
        functionDeclaration: FunctionDeclarationData)
        : FunctionDeclarationData?
    {
        if (functionDeclaration.isImplicit) {
            return null
        }
        else {
            return super.replaceFunctionDeclarationData(functionDeclaration)
        }
    }
}

open class OptionalInitsTranspilationPass: TranspilationPass {
    constructor(ast: GryphonAST): super(ast) { }

    var isFailableInitializer: Boolean = false

    override internal fun replaceFunctionDeclarationData(
        functionDeclaration: FunctionDeclarationData)
        : FunctionDeclarationData?
    {
        if (functionDeclaration.isStatic == true && functionDeclaration.extendsType == null && functionDeclaration.prefix == "init") {
            if (functionDeclaration.returnType.endsWith("?")) {
                val functionDeclaration: FunctionDeclarationData = functionDeclaration

                isFailableInitializer = true

                val newStatements: MutableList<Statement> = replaceStatements(functionDeclaration.statements ?: mutableListOf())

                isFailableInitializer = false
                functionDeclaration.prefix = "invoke"
                functionDeclaration.statements = newStatements

                return functionDeclaration
            }
        }
        return super.replaceFunctionDeclarationData(functionDeclaration)
    }

    override internal fun replaceAssignmentStatement(
        leftHand: Expression,
        rightHand: Expression)
        : MutableList<Statement>
    {
        if (isFailableInitializer && leftHand is Expression.DeclarationReferenceExpression) {
            val expression: DeclarationReferenceData = leftHand.data
            if (expression.identifier == "self") {
                return mutableListOf(Statement.ReturnStatement(expression = rightHand))
            }
        }
        return super.replaceAssignmentStatement(leftHand = leftHand, rightHand = rightHand)
    }
}

open class RemoveExtraReturnsInInitsTranspilationPass: TranspilationPass {
    constructor(ast: GryphonAST): super(ast) { }

    override internal fun replaceFunctionDeclarationData(
        functionDeclaration: FunctionDeclarationData)
        : FunctionDeclarationData?
    {
        val lastStatement: Statement? = functionDeclaration.statements?.lastOrNull()
        if (functionDeclaration.isStatic == true && functionDeclaration.extendsType == null && functionDeclaration.prefix == "init" && lastStatement != null && lastStatement is Statement.ReturnStatement) {
            val functionDeclaration: FunctionDeclarationData = functionDeclaration
            functionDeclaration.statements?.removeLast()
            return functionDeclaration
        }
        return functionDeclaration
    }
}

open class StaticMembersTranspilationPass: TranspilationPass {
    constructor(ast: GryphonAST): super(ast) { }

    private fun sendStaticMembersToCompanionObject(
        members: MutableList<Statement>)
        : MutableList<Statement>
    {
        val isStaticMember: (Statement) -> Boolean = { member ->
                if (member is Statement.FunctionDeclaration) {
                    val functionDeclaration: FunctionDeclarationData = member.data
                    if (functionDeclaration.isStatic == true && functionDeclaration.extendsType == null && functionDeclaration.prefix != "init") {
                        true
                    }
                }

                if (member is Statement.VariableDeclaration) {
                    val variableDeclaration: VariableDeclarationData = member.data
                    if (variableDeclaration.isStatic) {
                        true
                    }
                }

                false
            }
        val staticMembers: MutableList<Statement> = members.filter { isStaticMember(it) }.toMutableList()

        if (staticMembers.isEmpty()) {
            return members
        }

        val nonStaticMembers: MutableList<Statement> = members.filter { !isStaticMember(it) }.toMutableList()
        val newMembers: MutableList<Statement> = mutableListOf(Statement.CompanionObject(members = staticMembers)).toMutableList<Statement>()

        newMembers.addAll(nonStaticMembers)

        return newMembers
    }

    override internal fun replaceClassDeclaration(
        name: String,
        inherits: MutableList<String>,
        members: MutableList<Statement>)
        : MutableList<Statement>
    {
        val newMembers: MutableList<Statement> = sendStaticMembersToCompanionObject(members)
        return super.replaceClassDeclaration(name = name, inherits = inherits, members = newMembers)
    }

    override internal fun replaceStructDeclaration(
        annotations: String?,
        structName: String,
        inherits: MutableList<String>,
        members: MutableList<Statement>)
        : MutableList<Statement>
    {
        val newMembers: MutableList<Statement> = sendStaticMembersToCompanionObject(members)
        return super.replaceStructDeclaration(
            annotations = annotations,
            structName = structName,
            inherits = inherits,
            members = newMembers)
    }

    override internal fun replaceEnumDeclaration(
        access: String?,
        enumName: String,
        inherits: MutableList<String>,
        elements: MutableList<EnumElement>,
        members: MutableList<Statement>,
        isImplicit: Boolean)
        : MutableList<Statement>
    {
        val newMembers: MutableList<Statement> = sendStaticMembersToCompanionObject(members)
        return super.replaceEnumDeclaration(
            access = access,
            enumName = enumName,
            inherits = inherits,
            elements = elements,
            members = newMembers,
            isImplicit = isImplicit)
    }
}

open class InnerTypePrefixesTranspilationPass: TranspilationPass {
    constructor(ast: GryphonAST): super(ast) { }

    var typeNamesStack: MutableList<String> = mutableListOf()

    internal fun removePrefixes(typeName: String): String {
        var result: String = typeName
        for (typeName in typeNamesStack) {
            val prefix: String = typeName + "."
            if (result.startsWith(prefix)) {
                result = result.drop(prefix.length)
            }
            else {
                return result
            }
        }
        return result
    }

    override internal fun replaceClassDeclaration(
        name: String,
        inherits: MutableList<String>,
        members: MutableList<Statement>)
        : MutableList<Statement>
    {
        typeNamesStack.add(name)

        val result: MutableList<Statement> = super.replaceClassDeclaration(name = name, inherits = inherits, members = members)

        typeNamesStack.removeLast()

        return result
    }

    override internal fun replaceStructDeclaration(
        annotations: String?,
        structName: String,
        inherits: MutableList<String>,
        members: MutableList<Statement>)
        : MutableList<Statement>
    {
        typeNamesStack.add(structName)

        val result: MutableList<Statement> = super.replaceStructDeclaration(
            annotations = annotations,
            structName = structName,
            inherits = inherits,
            members = members)

        typeNamesStack.removeLast()

        return result
    }

    override internal fun replaceVariableDeclarationData(
        variableDeclaration: VariableDeclarationData)
        : VariableDeclarationData
    {
        val variableDeclaration: VariableDeclarationData = variableDeclaration
        variableDeclaration.typeName = removePrefixes(variableDeclaration.typeName)
        return super.replaceVariableDeclarationData(variableDeclaration)
    }

    override internal fun replaceTypeExpression(typeName: String): Expression {
        return Expression.TypeExpression(typeName = removePrefixes(typeName))
    }
}

open class RenameOperatorsTranspilationPass: TranspilationPass {
    constructor(ast: GryphonAST): super(ast) { }

    override internal fun replaceBinaryOperatorExpression(
        leftExpression: Expression,
        rightExpression: Expression,
        operatorSymbol: String,
        typeName: String)
        : Expression
    {
        if (operatorSymbol == "??") {
            return super.replaceBinaryOperatorExpression(
                leftExpression = leftExpression,
                rightExpression = rightExpression,
                operatorSymbol = "?:",
                typeName = typeName)
        }
        else {
            return super.replaceBinaryOperatorExpression(
                leftExpression = leftExpression,
                rightExpression = rightExpression,
                operatorSymbol = operatorSymbol,
                typeName = typeName)
        }
    }
}

open class SelfToThisTranspilationPass: TranspilationPass {
    constructor(ast: GryphonAST): super(ast) { }

    override internal fun replaceDotExpression(
        leftExpression: Expression,
        rightExpression: Expression)
        : Expression
    {
        if (leftExpression is Expression.DeclarationReferenceExpression) {
            val expression: DeclarationReferenceData = leftExpression.data
            if (expression.identifier == "self" && expression.isImplicit) {
                return replaceExpression(rightExpression)
            }
        }
        return Expression.DotExpression(
            leftExpression = replaceExpression(leftExpression),
            rightExpression = replaceExpression(rightExpression))
    }

    override internal fun replaceDeclarationReferenceExpressionData(
        expression: DeclarationReferenceData)
        : DeclarationReferenceData
    {
        if (expression.identifier == "self") {
            val expression: DeclarationReferenceData = expression
            expression.identifier = "this"
            return expression
        }
        return super.replaceDeclarationReferenceExpressionData(expression)
    }
}

open class CleanInheritancesTranspilationPass: TranspilationPass {
    constructor(ast: GryphonAST): super(ast) { }

    private fun isASwiftProtocol(protocolName: String): Boolean {
        return mutableListOf("Equatable", "Codable", "Decodable", "Encodable", "CustomStringConvertible").contains(protocolName)
    }

    override internal fun replaceEnumDeclaration(
        access: String?,
        enumName: String,
        inherits: MutableList<String>,
        elements: MutableList<EnumElement>,
        members: MutableList<Statement>,
        isImplicit: Boolean)
        : MutableList<Statement>
    {
        return super.replaceEnumDeclaration(
            access = access,
            enumName = enumName,
            inherits = inherits.filter { !isASwiftProtocol(it) && !TranspilationPass.isASwiftRawRepresentableType(it) }.toMutableList(),
            elements = elements,
            members = members,
            isImplicit = isImplicit)
    }

    override internal fun replaceStructDeclaration(
        annotations: String?,
        structName: String,
        inherits: MutableList<String>,
        members: MutableList<Statement>)
        : MutableList<Statement>
    {
        return super.replaceStructDeclaration(
            annotations = annotations,
            structName = structName,
            inherits = inherits.filter { !isASwiftProtocol(it) }.toMutableList(),
            members = members)
    }

    override internal fun replaceClassDeclaration(
        name: String,
        inherits: MutableList<String>,
        members: MutableList<Statement>)
        : MutableList<Statement>
    {
        return super.replaceClassDeclaration(
            name = name,
            inherits = inherits.filter { !isASwiftProtocol(it) }.toMutableList(),
            members = members)
    }
}

open class AnonymousParametersTranspilationPass: TranspilationPass {
    constructor(ast: GryphonAST): super(ast) { }

    override internal fun replaceDeclarationReferenceExpressionData(
        expression: DeclarationReferenceData)
        : DeclarationReferenceData
    {
        if (expression.identifier == "$0") {
            val expression: DeclarationReferenceData = expression
            expression.identifier = "it"
            return expression
        }
        else {
            return super.replaceDeclarationReferenceExpressionData(expression)
        }
    }

    override internal fun replaceClosureExpression(
        parameters: MutableList<LabeledType>,
        statements: MutableList<Statement>,
        typeName: String)
        : Expression
    {
        if (parameters.size == 1 && parameters[0].label == "$0") {
            return super.replaceClosureExpression(
                parameters = mutableListOf(),
                statements = statements,
                typeName = typeName)
        }
        else {
            return super.replaceClosureExpression(
                parameters = parameters,
                statements = statements,
                typeName = typeName)
        }
    }
}

open class CovarianceInitsAsCallsTranspilationPass: TranspilationPass {
    constructor(ast: GryphonAST): super(ast) { }

    override internal fun replaceCallExpression(callExpression: CallExpressionData): Expression {
        if (callExpression.function is Expression.TypeExpression && callExpression.parameters is Expression.TupleExpression) {
            val typeName: String = callExpression.function.typeName
            val pairs: MutableList<LabeledExpression> = callExpression.parameters.pairs
            val onlyPair: LabeledExpression? = pairs.firstOrNull()

            if (typeName.startsWith("ArrayClass<") && pairs.size == 1 && onlyPair != null) {
                val arrayClassElementType: String = typeName.drop("ArrayClass<".length).dropLast(1)
                val mappedElementType: String = Utilities.getTypeMapping(typeName = arrayClassElementType) ?: arrayClassElementType
                if (onlyPair.label == "array") {
                    val arrayType: String? = onlyPair.expression.swiftType
                    if (arrayType != null) {
                        val arrayElementType: String = arrayType.drop(1).dropLast(1)
                        if (arrayElementType != arrayClassElementType) {
                            return Expression.DotExpression(
                                leftExpression = replaceExpression(onlyPair.expression),
                                rightExpression = Expression.CallExpression(
                                        data = CallExpressionData(
                                                function = Expression.DeclarationReferenceExpression(
                                                        data = DeclarationReferenceData(
                                                                identifier = "toMutableList<${mappedElementType}>",
                                                                typeName = typeName,
                                                                isStandardLibrary = false,
                                                                isImplicit = false,
                                                                range = null)),
                                                parameters = Expression.TupleExpression(pairs = mutableListOf()),
                                                typeName = typeName,
                                                range = null)))
                        }
                    }
                    return replaceExpression(onlyPair.expression)
                }
                else {
                    return Expression.DotExpression(
                        leftExpression = replaceExpression(onlyPair.expression),
                        rightExpression = Expression.CallExpression(
                                data = CallExpressionData(
                                        function = Expression.DeclarationReferenceExpression(
                                                data = DeclarationReferenceData(
                                                        identifier = "toMutableList<${mappedElementType}>",
                                                        typeName = typeName,
                                                        isStandardLibrary = false,
                                                        isImplicit = false,
                                                        range = null)),
                                        parameters = Expression.TupleExpression(pairs = mutableListOf()),
                                        typeName = typeName,
                                        range = null)))
                }
            }
        }
        if (callExpression.function is Expression.DotExpression) {
            val leftExpression: Expression = callExpression.function.leftExpression
            val rightExpression: Expression = callExpression.function.rightExpression
            val leftType: String? = leftExpression.swiftType

            if (leftType != null && leftType.startsWith("ArrayClass") && rightExpression is Expression.DeclarationReferenceExpression && callExpression.parameters is Expression.TupleExpression) {
                val declarationReferenceExpression: DeclarationReferenceData = rightExpression.data
                val pairs: MutableList<LabeledExpression> = callExpression.parameters.pairs
                val onlyPair: LabeledExpression? = pairs.firstOrNull()

                if (declarationReferenceExpression.identifier == "as" && pairs.size == 1 && onlyPair != null && onlyPair.expression is Expression.TypeExpression) {
                    val typeName: String = onlyPair.expression.typeName
                    return Expression.BinaryOperatorExpression(
                        leftExpression = leftExpression,
                        rightExpression = Expression.TypeExpression(typeName = typeName),
                        operatorSymbol = "as?",
                        typeName = typeName + "?")
                }
            }
        }
        return super.replaceCallExpression(callExpression)
    }
}

public sealed class ASTNode {
    class StatementNode(val value: Statement): ASTNode()
    class ExpressionNode(val value: Expression): ASTNode()
}
