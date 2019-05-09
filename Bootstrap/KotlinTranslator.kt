open class KotlinTranslator {
    companion object {
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
}
