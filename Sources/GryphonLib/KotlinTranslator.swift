//
// Copyright 2018 Vinícius Jorge Vendramini
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

// declaration: import kotlin.system.*

public class KotlinTranslator {
	// MARK: - Interface

	public init() { }

	public func translateAST(_ sourceFile: GryphonAST) throws -> String {
		let declarationsTranslation =
			try translateSubtrees(sourceFile.declarations, withIndentation: "")

		let indentation = increaseIndentation("")
		let statementsTranslation =
			try translateSubtrees(sourceFile.statements, withIndentation: indentation)

		var result = declarationsTranslation

		guard !statementsTranslation.isEmpty else {
			return result
		}

		// Add newline between declarations and the main function, if needed
		if !declarationsTranslation.isEmpty {
			result += "\n"
		}

		result += "fun main(args: Array<String>) {\n\(statementsTranslation)}\n"

		return result
	}

	// MARK: - Properties for translation

	static let context = TranspilationContext()

	internal static var indentationString = "\t"

	static let errorTranslation = "<<Error>>"

	static let lineLimit = 100

	// MARK: - Statement translations

	struct TreeAndTranslation {
		let subtree: Statement
		let translation: String
	}

	private func translateSubtrees(
		_ subtrees: ArrayClass<Statement>,
		withIndentation indentation: String,
		limitForAddingNewlines: Int = 0) throws -> String
	{
		let treesAndTranslations = try subtrees.map {
			TreeAndTranslation(
				subtree: $0,
				translation: try translateSubtree($0, withIndentation: indentation))
			}.filter {
				!$0.translation.isEmpty
		}

		if treesAndTranslations.count <= limitForAddingNewlines {
			return treesAndTranslations.map { $0.translation }.joined()
		}

		let treesAndTranslationsWithoutFirst =
			ArrayClass<TreeAndTranslation>(treesAndTranslations.dropFirst())

		var result = ""

		for (currentSubtree, nextSubtree)
			in zipToClass(treesAndTranslations, treesAndTranslationsWithoutFirst)
		{
			result += currentSubtree.translation

			// Cases that should go together
			if currentSubtree.subtree is CommentStatement {
				continue
			}
			if currentSubtree.subtree is VariableDeclaration,
				nextSubtree.subtree is VariableDeclaration
			{
				continue
			}
			if let currentExpressionStatement = currentSubtree.subtree as? ExpressionStatement,
				let nextExpressionStatement = nextSubtree.subtree as? ExpressionStatement
			{
				if currentExpressionStatement.expression is CallExpression,
					nextExpressionStatement.expression is CallExpression
				{
					continue
				}
				if currentExpressionStatement.expression is TemplateExpression,
					nextExpressionStatement.expression is TemplateExpression
				{
					continue
				}
				if currentExpressionStatement.expression is LiteralCodeExpression,
					nextExpressionStatement.expression is LiteralCodeExpression
				{
					continue
				}
				if currentExpressionStatement.expression is LiteralDeclarationExpression,
					nextExpressionStatement.expression is LiteralDeclarationExpression
				{
					continue
				}
			}
			if currentSubtree.subtree is AssignmentStatement,
				nextSubtree.subtree is AssignmentStatement
			{
				continue
			}
			if currentSubtree.subtree is TypealiasDeclaration,
				nextSubtree.subtree is TypealiasDeclaration
			{
				continue
			}
			if currentSubtree.subtree is DoStatement,
				nextSubtree.subtree is CatchStatement
			{
				continue
			}
			if currentSubtree.subtree is CatchStatement,
				nextSubtree.subtree is CatchStatement
			{
				continue
			}

			result += "\n"
		}

		if let lastSubtree = treesAndTranslations.last {
			result += lastSubtree.translation
		}

		return result
	}

	private func translateSubtree(
		_ subtree: Statement,
		withIndentation indentation: String)
		throws -> String
	{
		if let commentStatement = subtree as? CommentStatement {
			return "\(indentation)//\(commentStatement.value)\n"
		}
		if subtree is ImportDeclaration {
			return ""
		}
		if subtree is ExtensionDeclaration {
			return try unexpectedASTStructureError(
				"Extension structure should have been removed in a transpilation pass",
				AST: subtree)
		}
		if subtree is DeferStatement {
			return try unexpectedASTStructureError(
				"Defer statements are only supported as top-level statements in function bodies",
				AST: subtree)
		}
		if let typealiasDeclaration = subtree as? TypealiasDeclaration {
			return try translateTypealias(typealiasDeclaration, withIndentation: indentation)
		}
		if let classDeclaration = subtree as? ClassDeclaration {
			return try translateClassDeclaration(classDeclaration, withIndentation: indentation)
		}
		if let structDeclaration = subtree as? StructDeclaration {
			return try translateStructDeclaration(structDeclaration, withIndentation: indentation)
		}
		if let companionObject = subtree as? CompanionObject {
			return try translateCompanionObject(companionObject, withIndentation: indentation)
		}
		if let enumDeclaration = subtree as? EnumDeclaration {
			return try translateEnumDeclaration(enumDeclaration, withIndentation: indentation)
		}
		if let doStatement = subtree as? DoStatement {
			return try translateDoStatement(doStatement, withIndentation: indentation)
		}
		if let catchStatement = subtree as? CatchStatement {
			return try translateCatchStatement(catchStatement, withIndentation: indentation)
		}
		if let forEachStatement = subtree as? ForEachStatement {
			return try translateForEachStatement(forEachStatement, withIndentation: indentation)
		}
		if let whileStatement = subtree as? WhileStatement {
			return try translateWhileStatement(whileStatement, withIndentation: indentation)
		}
		if let functionDeclaration = subtree as? FunctionDeclaration {
			return try translateFunctionDeclaration(
				functionDeclaration: functionDeclaration, withIndentation: indentation)
		}
		if let protocolDeclaration = subtree as? ProtocolDeclaration {
			return try translateProtocolDeclaration(
				protocolDeclaration, withIndentation: indentation)
		}
		if let throwStatement = subtree as? ThrowStatement {
			return try translateThrowStatement(throwStatement, withIndentation: indentation)
		}
		if let variableDeclaration = subtree as? VariableDeclaration {
			return try translateVariableDeclaration(
				variableDeclaration, withIndentation: indentation)
		}
		if let assignmentStatement = subtree as? AssignmentStatement {
			return try translateAssignmentStatement(
				assignmentStatement, withIndentation: indentation)
		}
		if let ifStatement = subtree as? IfStatement {
			return try translateIfStatement(ifStatement, withIndentation: indentation)
		}
		if let switchStatement = subtree as? SwitchStatement {
			return try translateSwitchStatement(switchStatement, withIndentation: indentation)
		}
		if let returnStatement = subtree as? ReturnStatement {
			return try translateReturnStatement(returnStatement, withIndentation: indentation)
		}
		if subtree is BreakStatement {
			return "\(indentation)break\n"
		}
		if subtree is ContinueStatement {
			return "\(indentation)continue\n"
		}
		if let expressionStatement = subtree as? ExpressionStatement {
			let expressionTranslation = try translateExpression(
				expressionStatement.expression,
				withIndentation: indentation)
			if !expressionTranslation.isEmpty {
				return indentation + expressionTranslation + "\n"
			}
			else {
				return "\n"
			}
		}
		if subtree is ErrorStatement {
			return KotlinTranslator.errorTranslation
		}

		fatalError("This should never be reached.")
	}

	private func translateEnumDeclaration(
		_ enumDeclaration: EnumDeclaration,
		withIndentation indentation: String)
		throws -> String
	{
		let isEnumClass = KotlinTranslator.context.enumClasses.contains(enumDeclaration.enumName)

		let accessString = enumDeclaration.access ?? ""
		let enumString = isEnumClass ? "enum" : "sealed"

		var result = "\(indentation)\(accessString) \(enumString) class " + enumDeclaration.enumName

		if !enumDeclaration.inherits.isEmpty {
			var translatedInheritedTypes = enumDeclaration.inherits.map { translateType($0) }
			translatedInheritedTypes = translatedInheritedTypes.map {
				KotlinTranslator.context.protocols.contains($0) ?
					$0 :
					$0 + "()"
			}
			result += ": \(translatedInheritedTypes.joined(separator: ", "))"
		}

		result += " {\n"

		let increasedIndentation = increaseIndentation(indentation)

		var casesTranslation = ""
		if isEnumClass {
			casesTranslation += enumDeclaration.elements.map {
					increasedIndentation +
						(($0.annotations == nil) ? "" : "\($0.annotations!) ") +
						$0.name
				}.joined(separator: ",\n") + ";\n"
		}
		else {
			for element in enumDeclaration.elements {
				casesTranslation += translateEnumElementDeclaration(
					enumName: enumDeclaration.enumName,
					element: element,
					withIndentation: increasedIndentation)
			}
		}
		result += casesTranslation

		let membersTranslation =
			try translateSubtrees(enumDeclaration.members, withIndentation: increasedIndentation)

		// Add a newline between cases and members if needed
		if !casesTranslation.isEmpty && !membersTranslation.isEmpty {
			result += "\n"
		}

		result += "\(membersTranslation)\(indentation)}\n"

		return result
	}

	private func translateEnumElementDeclaration(
		enumName: String,
		element: EnumElement,
		withIndentation indentation: String) -> String
	{
		let capitalizedElementName = element.name.capitalizedAsCamelCase()
		let annotationsString = (element.annotations == nil) ? "" : "\(element.annotations!) "

		let result = "\(indentation)\(annotationsString)class \(capitalizedElementName)"

		if element.associatedValues.isEmpty {
			return result + ": \(enumName)()\n"
		}
		else {
			let associatedValuesString =
				element.associatedValues
					.map { "val \($0.label): \(translateType($0.typeName))" }
					.joined(separator: ", ")
			return result + "(\(associatedValuesString)): \(enumName)()\n"
		}
	}

	private func translateProtocolDeclaration(
		_ protocolDeclaration: ProtocolDeclaration,
		withIndentation indentation: String)
		throws -> String
	{
		var result = "\(indentation)interface \(protocolDeclaration.protocolName) {\n"
		let contents = try translateSubtrees(
			protocolDeclaration.members, withIndentation: increaseIndentation(indentation))
		result += contents
		result += "\(indentation)}\n"
		return result
	}

	private func translateTypealias(
		_ typealiasDeclaration: TypealiasDeclaration,
		withIndentation indentation: String)
		throws -> String
	{
		let translatedType = translateType(typealiasDeclaration.typeName)
		return "\(indentation)typealias \(typealiasDeclaration.identifier) = \(translatedType)\n"
	}

	private func translateClassDeclaration(
		_ classDeclaration: ClassDeclaration,
		withIndentation indentation: String)
		throws -> String
	{
		var result = "\(indentation)open class \(classDeclaration.className)"

		if !classDeclaration.inherits.isEmpty {
			let translatedInheritances = classDeclaration.inherits.map { translateType($0) }
			result += ": " + translatedInheritances.joined(separator: ", ")
		}

		result += " {\n"

		let increasedIndentation = increaseIndentation(indentation)

		let classContents = try translateSubtrees(
			classDeclaration.members,
			withIndentation: increasedIndentation)

		result += classContents + "\(indentation)}\n"

		return result
	}

	/// If a value type's members are all immutable, that value type can safely be translated as a
	/// class. Source: https://forums.swift.org/t/are-immutable-structs-like-classes/16270
	private func translateStructDeclaration(
		_ structDeclaration: StructDeclaration,
		withIndentation indentation: String)
		throws -> String
	{
		let increasedIndentation = increaseIndentation(indentation)

		let annotationsString = structDeclaration.annotations.map { "\(indentation)\($0)\n" } ?? ""

		var result = "\(annotationsString)\(indentation)data class " +
			"\(structDeclaration.structName)(\n"

		let properties = structDeclaration.members.filter { statementIsStructProperty($0) }
		let otherMembers = structDeclaration.members.filter { !statementIsStructProperty($0) }

		// Translate properties individually, dropping the newlines at the end
		let propertyTranslations = try properties.map {
			try String(translateSubtree($0, withIndentation: increasedIndentation).dropLast())
		}
		let propertiesTranslation = propertyTranslations.joined(separator: ",\n")

		result += propertiesTranslation + "\n\(indentation))"

		if !structDeclaration.inherits.isEmpty {
			var translatedInheritedTypes = structDeclaration.inherits.map { translateType($0) }
			translatedInheritedTypes = translatedInheritedTypes.map {
				KotlinTranslator.context.protocols.contains($0) ?
					$0 :
					$0 + "()"
			}
			result += ": \(translatedInheritedTypes.joined(separator: ", "))"
		}

		let otherMembersTranslation = try translateSubtrees(
			otherMembers,
			withIndentation: increasedIndentation)

		if !otherMembersTranslation.isEmpty {
			result += " {\n\(otherMembersTranslation)\(indentation)}\n"
		}
		else {
			result += "\n"
		}

		return result
	}

	private func statementIsStructProperty(
		_ statement: Statement)
		-> Bool
	{
		if let variableDeclaration = statement as? VariableDeclaration {
			if variableDeclaration.getter == nil,
				variableDeclaration.setter == nil,
				!variableDeclaration.isStatic
			{
				return true
			}
		}

		return false
	}

	private func translateCompanionObject(
		_ companionObject: CompanionObject,
		withIndentation indentation: String)
		throws -> String
	{
		var result = "\(indentation)companion object {\n"

		let increasedIndentation = increaseIndentation(indentation)

		let contents = try translateSubtrees(
			companionObject.members,
			withIndentation: increasedIndentation)

		result += contents + "\(indentation)}\n"

		return result
	}

	private func translateFunctionDeclaration(
		functionDeclaration: FunctionDeclaration,
		withIndentation indentation: String,
		shouldAddNewlines: Bool = false)
		throws -> String
	{
		guard !functionDeclaration.isImplicit else {
			return ""
		}

		var indentation = indentation
		var result = indentation

		let isInit = (functionDeclaration is InitializerDeclaration)
		if isInit {
			result += "constructor("
		}
		else if functionDeclaration.prefix == "invoke" {
			result += "operator fun invoke("
		}
		else {
			if let annotations = functionDeclaration.annotations {
				result += annotations + " "
			}
			if let access = functionDeclaration.access {
				result += access + " "
			}
			result += "fun "
			if let extensionType = functionDeclaration.extendsType {
				let translatedExtensionType = translateType(extensionType)
				// TODO: test
				let companionString = functionDeclaration.isStatic ? "Companion." : ""

				// TODO: tests
				let genericString: String
				if let genericExtensionIndex = translatedExtensionType.index(of: "<") {
					let genericExtensionString =
						translatedExtensionType.suffix(from: genericExtensionIndex)
					let genericTypes = ArrayClass<String>(genericExtensionString
						.dropFirst().dropLast()
						.split(separator: ",")
						.map { String($0) })
					genericTypes.append(contentsOf: functionDeclaration.genericTypes)
					genericString = "<\(genericTypes.joined(separator: ", "))> "
				}
				else if !functionDeclaration.genericTypes.isEmpty {
					genericString = "<\(functionDeclaration.genericTypes.joined(separator: ", "))> "
				}
				else {
					genericString = ""
				}

				result += genericString + translatedExtensionType + "." + companionString
			}
			else {
				if !functionDeclaration.genericTypes.isEmpty {
					let genericString =
						"<\(functionDeclaration.genericTypes.joined(separator: ", "))> "
					result += genericString
				}
			}

			result += functionDeclaration.prefix + "("
		}

		// Check if we need to call a superclass initializer or if we need to specify a return type
		// after the parameters
		var returnOrSuperCallString: String = ""
		if let initializerDeclaration = functionDeclaration as? InitializerDeclaration {
			if let superCall = initializerDeclaration.superCall {
				let superCallTranslation = try translateCallExpression(
					superCall,
					withIndentation: increaseIndentation(indentation))
				returnOrSuperCallString = ": \(superCallTranslation)"
			}
		}
		else if functionDeclaration.returnType != "()", !isInit {
			// If it doesn't, that place might be used for the return type

			let translatedReturnType = translateType(functionDeclaration.returnType)
			returnOrSuperCallString = ": \(translatedReturnType)"
		}

		let parameterStrings = try functionDeclaration.parameters
			.map { try translateFunctionDeclarationParameter($0, withIndentation: indentation) }

		if !shouldAddNewlines {
			result += parameterStrings.joined(separator: ", ") + ")" +
				returnOrSuperCallString + " {\n"
			if result.count >= KotlinTranslator.lineLimit {
				return try translateFunctionDeclaration(
					functionDeclaration: functionDeclaration, withIndentation: indentation,
					shouldAddNewlines: true)
			}
		}
		else {
			let parameterIndentation = increaseIndentation(indentation)
			let parametersString = parameterStrings.joined(separator: ",\n\(parameterIndentation)")
			result += "\n\(parameterIndentation)" + parametersString + ")\n"

			if !returnOrSuperCallString.isEmpty {
				result += "\(parameterIndentation)\(returnOrSuperCallString)\n"
			}

			result += "\(indentation){\n"
		}

		guard let statements = functionDeclaration.statements else {
			return result + "\n"
		}

		// Get all statements that have been deferred
		let innerDeferStatements = statements.flatMap { extractInnerDeferStatements($0) }
		// Get all other statements
		let nonDeferStatements = statements.filter { !isDeferStatement($0) }

		indentation = increaseIndentation(indentation)

		if !innerDeferStatements.isEmpty {
			let increasedIndentation = increaseIndentation(indentation)
			result += "\(indentation)try {\n"
			result += try translateSubtrees(
				nonDeferStatements,
				withIndentation: increasedIndentation,
				limitForAddingNewlines: 3)
			result += "\(indentation)}\n"
			result += "\(indentation)finally {\n"
			result += try translateSubtrees(
				innerDeferStatements,
				withIndentation: increasedIndentation,
				limitForAddingNewlines: 3)
			result += "\(indentation)}\n"
		}
		else {
			result += try translateSubtrees(
				statements,
				withIndentation: indentation,
				limitForAddingNewlines: 3)
		}

		indentation = decreaseIndentation(indentation)
		result += indentation + "}\n"

		return result
	}

	private func isDeferStatement(
		_ maybeDeferStatement: Statement)
		-> Bool
	{
		if maybeDeferStatement is DeferStatement {
			return true
		}
		else {
			return false
		}
	}

	private func extractInnerDeferStatements(
		_ maybeDeferStatement: Statement)
		-> ArrayClass<Statement>
	{
		if let deferStatement = maybeDeferStatement as? DeferStatement {
			return deferStatement.statements
		}
		else {
			return []
		}
	}

	private func translateFunctionDeclarationParameter(
		_ parameter: FunctionParameter,
		withIndentation indentation: String)
		throws -> String
	{
		let labelAndTypeString = parameter.label + ": " + translateType(parameter.typeName)
		if let defaultValue = parameter.value {
			return try labelAndTypeString + " = "
				+ translateExpression(defaultValue, withIndentation: indentation)
		}
		else {
			return labelAndTypeString
		}
	}

	private func translateDoStatement(
		_ doStatement: DoStatement,
		withIndentation indentation: String)
		throws -> String
	{
		let translatedStatements = try translateSubtrees(
			doStatement.statements,
			withIndentation: increaseIndentation(indentation),
			limitForAddingNewlines: 3)
		return "\(indentation)try {\n\(translatedStatements)\(indentation)}\n"
	}

	private func translateCatchStatement(
		_ catchStatement: CatchStatement,
		withIndentation indentation: String)
		throws -> String
	{
		var result = ""

		if let variableDeclaration = catchStatement.variableDeclaration {
			let translatedType = translateType(variableDeclaration.typeName)
			result = "\(indentation)catch " +
			"(\(variableDeclaration.identifier): \(translatedType)) {\n"
		}
		else {
			result = "\(indentation)catch {\n"
		}

		let translatedStatements = try translateSubtrees(
			catchStatement.statements,
			withIndentation: increaseIndentation(indentation),
			limitForAddingNewlines: 3)

		result += "\(translatedStatements)"
		result += "\(indentation)}\n"

		return result
	}

	private func translateForEachStatement(
		_ forEachStatement: ForEachStatement,
		withIndentation indentation: String)
		throws -> String
	{
		var result = "\(indentation)for ("

		let variableTranslation =
			try translateExpression(forEachStatement.variable, withIndentation: indentation)

		result += variableTranslation + " in "

		let collectionTranslation =
			try translateExpression(forEachStatement.collection, withIndentation: indentation)

		result += collectionTranslation + ") {\n"

		let increasedIndentation = increaseIndentation(indentation)
		let statementsTranslation = try translateSubtrees(
			forEachStatement.statements,
			withIndentation: increasedIndentation,
			limitForAddingNewlines: 3)

		result += statementsTranslation

		result += indentation + "}\n"
		return result
	}

	// TODO: Update stdlib tests
	// TODO: Test whiles
	private func translateWhileStatement(
		_ whileStatement: WhileStatement,
		withIndentation indentation: String)
		throws -> String
	{
		var result = "\(indentation)while ("

		let expressionTranslation =
			try translateExpression(whileStatement.expression, withIndentation: indentation)
		result += expressionTranslation + ") {\n"

		let increasedIndentation = increaseIndentation(indentation)
		let statementsTranslation = try translateSubtrees(
			whileStatement.statements,
			withIndentation: increasedIndentation,
			limitForAddingNewlines: 3)

		result += statementsTranslation

		result += indentation + "}\n"
		return result
	}

	private func translateIfStatement(
		_ ifStatement: IfStatement,
		isElseIf: Bool = false,
		withIndentation indentation: String)
		throws -> String
	{
		let keyword = (ifStatement.conditions.isEmpty && ifStatement.declarations.isEmpty) ?
			"else" :
			(isElseIf ? "else if" : "if")

		var result = indentation + keyword + " "

		let increasedIndentation = increaseIndentation(indentation)

		let conditionsTranslation = try ifStatement.conditions.compactMap {
				conditionToExpression($0)
			}.map {
				try translateExpression($0, withIndentation: indentation)
			}.joined(separator: " && ")

		if keyword != "else" {
			let parenthesizedCondition = ifStatement.isGuard ?
				("(!(" + conditionsTranslation + ")) ") :
				("(" + conditionsTranslation + ") ")

			result += parenthesizedCondition
		}

		result += "{\n"

		let statementsString = try translateSubtrees(
			ifStatement.statements,
			withIndentation: increasedIndentation,
			limitForAddingNewlines: 3)

		result += statementsString + indentation + "}\n"

		if let unwrappedElse = ifStatement.elseStatement {
			result += try translateIfStatement(
				unwrappedElse, isElseIf: true, withIndentation: indentation)
		}

		return result
	}

	private func conditionToExpression(_ condition: IfStatement.IfCondition) -> Expression? {
		if case let .condition(expression: expression) = condition {
			return expression
		}
		else {
			return nil
		}
	}

	private func translateSwitchStatement(
		_ switchStatement: SwitchStatement,
		withIndentation indentation: String)
		throws -> String
	{
		var result: String = ""

		if let convertsToExpression = switchStatement.convertsToExpression {
			if convertsToExpression is ReturnStatement {
				result = "\(indentation)return when ("
			}
			else if let assignmentStatement = convertsToExpression as? AssignmentStatement {
				let translatedLeftHand = try translateExpression(
					assignmentStatement.leftHand,
					withIndentation: indentation)
				result = "\(indentation)\(translatedLeftHand) = when ("
			}
			else if let variableDeclaration = convertsToExpression as? VariableDeclaration {
				let newVariableDeclaration = VariableDeclaration(
					range: nil,
					identifier: variableDeclaration.identifier,
					typeName: variableDeclaration.typeName,
					expression: NilLiteralExpression(range: nil),
					getter: nil,
					setter: nil,
					isLet: variableDeclaration.isLet,
					isImplicit: false,
					isStatic: false,
					extendsType: nil,
					annotations: variableDeclaration.annotations)
				let translatedVariableDeclaration = try translateVariableDeclaration(
					newVariableDeclaration,
					withIndentation: indentation)
				let cleanTranslation = translatedVariableDeclaration.dropLast("null\n".count)
				result = "\(cleanTranslation)when ("
			}
		}

		if result.isEmpty {
			result = "\(indentation)when ("
		}

		let expressionTranslation =
			try translateExpression(switchStatement.expression, withIndentation: indentation)
		let increasedIndentation = increaseIndentation(indentation)

		result += "\(expressionTranslation)) {\n"

		for switchCase in switchStatement.cases {
			guard !switchCase.statements.isEmpty else {
				continue
			}

			result += increasedIndentation

			let translatedExpressions: ArrayClass<String> = []

			for caseExpression in switchCase.expressions {
				let translatedExpression = try translateSwitchCaseExpression(
					caseExpression,
					withSwitchExpression: switchStatement.expression,
					indentation: increasedIndentation)
				translatedExpressions.append(translatedExpression)
			}

			if translatedExpressions.isEmpty {
				result += "else -> "
			}
			else {
				result += translatedExpressions.joined(separator: ", ") + " -> "
			}

			if switchCase.statements.count == 1,
				let onlyStatement = switchCase.statements.first
			{
				let statementTranslation =
					try translateSubtree(onlyStatement, withIndentation: "")
				result += statementTranslation
			}
			else {
				result += "{\n"
				let statementsIndentation = increaseIndentation(increasedIndentation)
				let statementsTranslation = try translateSubtrees(
					switchCase.statements,
					withIndentation: statementsIndentation,
					limitForAddingNewlines: 3)
				result += "\(statementsTranslation)\(increasedIndentation)}\n"
			}
		}

		result += "\(indentation)}\n"

		return result
	}

	private func translateSwitchCaseExpression(
		_ caseExpression: Expression,
		withSwitchExpression switchExpression: Expression,
		indentation: String)
		throws -> String
	{
		if let binaryExpression = caseExpression as? BinaryOperatorExpression {
			if binaryExpression.leftExpression == switchExpression,
				binaryExpression.operatorSymbol == "is",
				binaryExpression.typeName == "Bool"
			{
				// TODO: test
				let translatedType = try translateExpression(
					binaryExpression.rightExpression,
					withIndentation: indentation)
				return "is \(translatedType)"
			}
			else {
				let translatedExpression = try translateExpression(
					binaryExpression.leftExpression,
					withIndentation: indentation)

				// If it's a range
				if let template = binaryExpression.leftExpression as? TemplateExpression {
					if template.pattern.contains("..") ||
						template.pattern.contains("until") ||
						template.pattern.contains("rangeTo")
					{
						return "in \(translatedExpression)"
					}
				}

				return translatedExpression
			}
		}

		let translatedExpression = try translateExpression(
			caseExpression,
			withIndentation: indentation)
		return translatedExpression
	}

	private func translateThrowStatement(
		_ throwStatement: ThrowStatement,
		withIndentation indentation: String)
		throws -> String
	{
		let expressionString =
			try translateExpression(throwStatement.expression, withIndentation: indentation)
		return "\(indentation)throw \(expressionString)\n"
	}

	private func translateReturnStatement(
		_ returnStatement: ReturnStatement,
		withIndentation indentation: String)
		throws -> String
	{
		if let expression = returnStatement.expression {
			let expressionString = try translateExpression(expression, withIndentation: indentation)
			return "\(indentation)return \(expressionString)\n"
		}
		else {
			return "\(indentation)return\n"
		}
	}

	private func translateVariableDeclaration(
		_ variableDeclaration: VariableDeclaration,
		withIndentation indentation: String)
		throws -> String
	{
		guard !variableDeclaration.isImplicit else {
			return ""
		}

		var result = indentation

		if let annotations = variableDeclaration.annotations {
			result += "\(annotations) "
		}

		var keyword: String
		if variableDeclaration.getter != nil && variableDeclaration.setter != nil {
			keyword = "var"
		}
		else if variableDeclaration.getter != nil && variableDeclaration.setter == nil {
			keyword = "val"
		}
		else {
			if variableDeclaration.isLet {
				keyword = "val"
			}
			else {
				keyword = "var"
			}
		}

		result += "\(keyword) "

		let extensionPrefix: String
		if let extendsType = variableDeclaration.extendsType {
			let translatedExtendedType = translateType(extendsType)

			let genericString: String
			if let genericIndex = translatedExtendedType.index(of: "<") {
				let genericContents = translatedExtendedType.suffix(from: genericIndex)
				genericString = "\(genericContents) "
			}
			else {
				genericString = ""
			}

			extensionPrefix = genericString + translatedExtendedType + "."
		}
		else {
			extensionPrefix = ""
		}

		result += "\(extensionPrefix)\(variableDeclaration.identifier): "

		let translatedType = translateType(variableDeclaration.typeName)
		result += translatedType

		if let expression = variableDeclaration.expression {
			let expressionTranslation =
				try translateExpression(expression, withIndentation: indentation)
			result += " = " + expressionTranslation
		}

		result += "\n"

		let indentation1 = increaseIndentation(indentation)
		let indentation2 = increaseIndentation(indentation1)
		if let getter = variableDeclaration.getter {
			if let statements = getter.statements {
				result += indentation1 + "get() {\n"
				result += try translateSubtrees(
					statements,
					withIndentation: indentation2,
					limitForAddingNewlines: 3)
				result += indentation1 + "}\n"
			}
		}

		if let setter = variableDeclaration.setter {
			if let statements = setter.statements {
				result += indentation1 + "set(newValue) {\n"
				result += try translateSubtrees(
					statements,
					withIndentation: indentation2,
					limitForAddingNewlines: 3)
				result += indentation1 + "}\n"
			}
		}

		return result
	}

	private func translateAssignmentStatement(
		_ assignmentStatement: AssignmentStatement,
		withIndentation indentation: String)
		throws -> String
	{
		let leftTranslation =
			try translateExpression(assignmentStatement.leftHand, withIndentation: indentation)
		let rightTranslation =
			try translateExpression(assignmentStatement.rightHand, withIndentation: indentation)
		return "\(indentation)\(leftTranslation) = \(rightTranslation)\n"
	}

	// MARK: - Expression translations

	private func translateExpression(
		_ expression: Expression,
		withIndentation indentation: String)
		throws -> String
	{
		if let templateExpression = expression as? TemplateExpression {
			return try translateTemplateExpression(templateExpression, withIndentation: indentation)
		}
		if let literalCodeExpression = expression as? LiteralCodeExpression {
			return translateLiteralCodeExpression(string: literalCodeExpression.string)
		}
		if let literalDeclarationExpression = expression as? LiteralDeclarationExpression {
			return translateLiteralCodeExpression(string: literalDeclarationExpression.string)
		}
		if let arrayExpression = expression as? ArrayExpression {
			return try translateArrayExpression(arrayExpression, withIndentation: indentation)
		}
		if let dictionaryExpression = expression as? DictionaryExpression {
			return try translateDictionaryExpression(
				dictionaryExpression, withIndentation: indentation)
		}
		if let binaryOperatorExpression = expression as? BinaryOperatorExpression {
			return try translateBinaryOperatorExpression(
				binaryOperatorExpression, withIndentation: indentation)
		}
		if let callExpression = expression as? CallExpression {
			return try translateCallExpression(callExpression, withIndentation: indentation)
		}
		if let closureExpression = expression as? ClosureExpression {
			return try translateClosureExpression(closureExpression, withIndentation: indentation)
		}
		if let declarationReferenceExpression = expression as? DeclarationReferenceExpression {
			return translateDeclarationReferenceExpression(declarationReferenceExpression)
		}
		if let returnExpression = expression as? ReturnExpression {
			return try translateReturnExpression(returnExpression, withIndentation: indentation)
		}
		if let dotExpression = expression as? DotExpression {
			return try translateDotSyntaxCallExpression(dotExpression, withIndentation: indentation)
		}
		if let literalStringExpression = expression as? LiteralStringExpression {
			return translateStringLiteral(literalStringExpression)
		}
		if let literalCharacterExpression = expression as? LiteralCharacterExpression {
			return translateCharacterLiteral(literalCharacterExpression)
		}
		if let interpolatedStringLiteralExpression =
			expression as? InterpolatedStringLiteralExpression
		{
			return try translateInterpolatedStringLiteralExpression(
				interpolatedStringLiteralExpression, withIndentation: indentation)
		}
		if let prefixUnaryExpression = expression as? PrefixUnaryExpression {
			return try translatePrefixUnaryExpression(
				prefixUnaryExpression, withIndentation: indentation)
		}
		if let postfixUnaryExpression = expression as? PostfixUnaryExpression {
			return try translatePostfixUnaryExpression(
				postfixUnaryExpression, withIndentation: indentation)
		}
		if let ifExpression = expression as? IfExpression {
			return try translateIfExpression(ifExpression, withIndentation: indentation)
		}
		if let typeExpression = expression as? TypeExpression {
			return translateType(typeExpression.typeName)
		}
		if let subscriptExpression = expression as? SubscriptExpression {
			return try translateSubscriptExpression(
				subscriptExpression, withIndentation: indentation)
		}
		if let parenthesesExpression = expression as? ParenthesesExpression {
			return try "(" +
				translateExpression(
					parenthesesExpression.expression,
					withIndentation: indentation) +
				")"
		}
		if let forceValueExpression = expression as? ForceValueExpression {
			return try translateExpression(
					forceValueExpression.expression,
					withIndentation: indentation) +
				"!!"
		}
		if let optionalExpression = expression as? OptionalExpression {
			return try translateExpression(
					optionalExpression.expression,
					withIndentation: indentation) +
				"?"
		}
		if let literalIntExpression = expression as? LiteralIntExpression {
			return String(literalIntExpression.value)
		}
		if let literalUIntExpression = expression as? LiteralUIntExpression {
			return String(literalUIntExpression.value) + "u"
		}
		if let literalDoubleExpression = expression as? LiteralDoubleExpression {
			return String(literalDoubleExpression.value)
		}
		if let literalFloatExpression = expression as? LiteralFloatExpression {
			return String(literalFloatExpression.value) + "f"
		}
		if let literalBoolExpression = expression as? LiteralBoolExpression {
			return String(literalBoolExpression.value)
		}
		if expression is NilLiteralExpression {
			return "null"
		}
		if let tupleExpression = expression as? TupleExpression {
			return try translateTupleExpression(tupleExpression, withIndentation: indentation)
		}
		if let tupleShuffleExpression = expression as? TupleShuffleExpression {
			return try translateTupleShuffleExpression(
				tupleShuffleExpression, withIndentation: indentation)
		}
		if expression is ErrorExpression {
			return KotlinTranslator.errorTranslation
		}

		fatalError("This should never be reached.")
	}

	private func translateSubscriptExpression(
		_ subscriptExpression: SubscriptExpression,
		withIndentation indentation: String)
		throws -> String
	{
		let translatedSubscriptExpression = try translateExpression(
			subscriptExpression.indexExpression,
			withIndentation: indentation)

		return try translateExpression(
				subscriptExpression.subscriptedExpression,
				withIndentation: indentation) +
			"[\(translatedSubscriptExpression)]"
	}

	private func translateArrayExpression(
		_ arrayExpression: ArrayExpression,
		withIndentation indentation: String)
		throws -> String
	{
		let expressionsString = try arrayExpression.elements.map {
			try translateExpression($0, withIndentation: indentation)
			}.joined(separator: ", ")

		if arrayExpression.typeName.hasPrefix("ArrayClass") {
			return "mutableListOf(\(expressionsString))"
		}
		else if arrayExpression.typeName.hasPrefix("FixedArray") {
			return "listOf(\(expressionsString))"
		}
		else {
			return "mutableListOf(\(expressionsString))"
		}
	}

	private func translateDictionaryExpression(
		_ dictionaryExpression: DictionaryExpression,
		withIndentation indentation: String)
		throws -> String
	{
		let keyExpressions = try dictionaryExpression.keys.map {
				try translateExpression($0, withIndentation: indentation)
			}
		let valueExpressions = try dictionaryExpression.values.map {
				try translateExpression($0, withIndentation: indentation)
			}
		let expressionsString = zipToClass(keyExpressions, valueExpressions).map { keyValueTuple in
				"\(keyValueTuple.0) to \(keyValueTuple.1)"
			}.joined(separator: ", ")

		return "mutableMapOf(\(expressionsString))"
	}

	private func translateReturnExpression(
		_ returnExpression: ReturnExpression,
		withIndentation indentation: String)
		throws -> String
	{
		if let expression = returnExpression.expression {
			let expressionString = try translateExpression(expression, withIndentation: indentation)
			return "return \(expressionString)"
		}
		else {
			return "return"
		}
	}

	private func translateDotSyntaxCallExpression(
		_ dotExpression: DotExpression,
		withIndentation indentation: String)
		throws -> String
	{
		let leftHandString =
			try translateExpression(dotExpression.leftExpression, withIndentation: indentation)
		let rightHandString =
			try translateExpression(dotExpression.rightExpression, withIndentation: indentation)

		if KotlinTranslator.context.sealedClasses.contains(leftHandString) {
			let translatedEnumCase = rightHandString.capitalizedAsCamelCase()
			return "\(leftHandString).\(translatedEnumCase)()"
		}
		else {
			let enumName = leftHandString.split(withStringSeparator: ".").last!
			if KotlinTranslator.context.enumClasses.contains(enumName) {
				let translatedEnumCase = rightHandString.upperSnakeCase()
				return "\(leftHandString).\(translatedEnumCase)"
			}
			else {
				return "\(leftHandString).\(rightHandString)"
			}
		}
	}

	private func translateBinaryOperatorExpression(
		_ binaryOperatorExpression: BinaryOperatorExpression,
		withIndentation indentation: String)
		throws -> String
	{
		let leftTranslation = try translateExpression(
			binaryOperatorExpression.leftExpression,
			withIndentation: indentation)
		let rightTranslation = try translateExpression(
			binaryOperatorExpression.rightExpression,
			withIndentation: indentation)
		return "\(leftTranslation) \(binaryOperatorExpression.operatorSymbol) \(rightTranslation)"
	}

	private func translatePrefixUnaryExpression(
		_ prefixUnaryExpression: PrefixUnaryExpression,
		withIndentation indentation: String)
		throws -> String
	{
		let expressionTranslation = try translateExpression(
			prefixUnaryExpression.subExpression,
			withIndentation: indentation)
		return prefixUnaryExpression.operatorSymbol + expressionTranslation
	}

	private func translatePostfixUnaryExpression(
		_ postfixUnaryExpression: PostfixUnaryExpression,
		withIndentation indentation: String)
		throws -> String
	{
		let expressionTranslation = try translateExpression(
			postfixUnaryExpression.subExpression,
			withIndentation: indentation)
		return expressionTranslation + postfixUnaryExpression.operatorSymbol
	}

	private func translateIfExpression(
		_ ifExpression: IfExpression,
		withIndentation indentation: String)
		throws -> String
	{
		let conditionTranslation =
			try translateExpression(ifExpression.condition, withIndentation: indentation)
		let trueExpressionTranslation =
			try translateExpression(ifExpression.trueExpression, withIndentation: indentation)
		let falseExpressionTranslation =
			try translateExpression(ifExpression.falseExpression, withIndentation: indentation)

		return "if (\(conditionTranslation)) { \(trueExpressionTranslation) } else " +
		"{ \(falseExpressionTranslation) }"
	}

	private func translateCallExpression(
		_ callExpression: CallExpression,
		withIndentation indentation: String,
		shouldAddNewlines: Bool = false)
		throws -> String
	{
		var result = ""

		var functionExpression = callExpression.function
		while true {
			if let expression = functionExpression as? DotExpression {
				result += try translateExpression(
					expression.leftExpression,
					withIndentation: indentation) + "."
				functionExpression = expression.rightExpression
			}
			else {
				break
			}
		}

		let functionTranslation: TranspilationContext.FunctionTranslation?
		if let expression = functionExpression as? DeclarationReferenceExpression {
			functionTranslation = KotlinTranslator.context.getFunctionTranslation(
				forName: expression.identifier,
				typeName: expression.typeName)
		}
		else {
			functionTranslation = nil
		}

		let prefix = try functionTranslation?.prefix ??
			translateExpression(functionExpression, withIndentation: indentation)

		let parametersTranslation = try translateParameters(
			forCallExpression: callExpression,
			withFunctionTranslation: functionTranslation,
			withIndentation: indentation,
			shouldAddNewlines: shouldAddNewlines)

		result += "\(prefix)\(parametersTranslation)"

		if !shouldAddNewlines, result.count >= KotlinTranslator.lineLimit {
			return try translateCallExpression(
				callExpression,
				withIndentation: indentation,
				shouldAddNewlines: true)
		}
		else {
			return result
		}
	}

	private func translateParameters(
		forCallExpression callExpression: CallExpression,
		withFunctionTranslation functionTranslation: TranspilationContext.FunctionTranslation?,
		withIndentation indentation: String,
		shouldAddNewlines: Bool)
		throws -> String
	{
		if let tupleExpression = callExpression.parameters as? TupleExpression {
			if let closurePair = tupleExpression.pairs.last {
				if let closureExpression = closurePair.expression as? ClosureExpression
				{
					let closureTranslation = try translateClosureExpression(
						closureExpression,
						withIndentation: increaseIndentation(indentation))
					if closureExpression.parameters.count > 1 {
						let newTupleExpression = TupleExpression(
							range: tupleExpression.range,
							pairs: ArrayClass<LabeledExpression>(tupleExpression.pairs.dropLast()))

						let firstParametersTranslation = try translateTupleExpression(
							newTupleExpression,
							translation: functionTranslation,
							withIndentation: increaseIndentation(indentation),
							shouldAddNewlines: shouldAddNewlines)
						return "\(firstParametersTranslation) \(closureTranslation)"
					}
					else {
						return " \(closureTranslation)"
					}
				}
			}

			return try translateTupleExpression(
				tupleExpression,
				translation: functionTranslation,
				withIndentation: increaseIndentation(indentation),
				shouldAddNewlines: shouldAddNewlines)
		}
		else if let tupleShuffleExpression = callExpression.parameters as? TupleShuffleExpression {
			return try translateTupleShuffleExpression(
				tupleShuffleExpression,
				translation: functionTranslation,
				withIndentation: increaseIndentation(indentation),
				shouldAddNewlines: shouldAddNewlines)
		}

		return try unexpectedASTStructureError(
			"Expected the parameters to be either a .tupleExpression or a " +
			".tupleShuffleExpression",
			AST: ExpressionStatement(
				range: callExpression.range,
				expression: callExpression))
	}

	private func translateClosureExpression(
		_ closureExpression: ClosureExpression,
		withIndentation indentation: String)
		throws -> String
	{
		guard !closureExpression.statements.isEmpty else {
			return "{ }"
		}

		var result = "{"

		let parametersString = closureExpression.parameters.map{ $0.label }.joined(separator: ", ")

		if !parametersString.isEmpty {
			result += " " + parametersString + " ->"
		}

		let firstStatement = closureExpression.statements.first
		if closureExpression.statements.count == 1,
			let firstStatement = firstStatement,
			let expressionStatement = firstStatement as? ExpressionStatement
		{
			result += try " " +
				translateExpression(expressionStatement.expression, withIndentation: indentation) +
				" }"
		}
		else {
			result += "\n"
			let closingBraceIndentation = increaseIndentation(indentation)
			let contentsIndentation = increaseIndentation(closingBraceIndentation)
			result += try translateSubtrees(
				closureExpression.statements,
				withIndentation: contentsIndentation)
			result += closingBraceIndentation + "}"
		}

		return result
	}

	private func translateLiteralCodeExpression(string: String) -> String {
		return string.removingBackslashEscapes
	}

	private func translateTemplateExpression(
		_ templateExpression: TemplateExpression,
		withIndentation indentation: String)
		throws -> String
	{
		var result = templateExpression.pattern
		for (string, expression) in templateExpression.matches {
			let expressionTranslation =
				try translateExpression(expression, withIndentation: indentation)
			result = result.replacingOccurrences(of: string, with: expressionTranslation)
		}
		return result
	}

	private func translateDeclarationReferenceExpression(
		_ declarationReferenceExpression: DeclarationReferenceExpression) -> String
	{
		return String(declarationReferenceExpression.identifier.prefix {
			$0 !=
				"(" // value: '('
		})
	}

	private func translateTupleExpression(
		_ tupleExpression: TupleExpression,
		translation: TranspilationContext.FunctionTranslation? = nil,
		withIndentation indentation: String,
		shouldAddNewlines: Bool = false)
		throws -> String
	{
		guard !tupleExpression.pairs.isEmpty else {
			return "()"
		}

		// In tuple expressions (when used as parameters for call expressions) there seems to be
		// little risk of triggering errors in Kotlin. Therefore, we can try to omit some parameter
		// labels in the call when they've also been omitted in Swift.
		let parameters: ArrayClass<String?>
		if let translationParameters = translation?.parameters {
			parameters = zipToClass(translationParameters, tupleExpression.pairs).map
				{ translationPairTuple in
					(translationPairTuple.1.label == nil) ? nil : translationPairTuple.0
				}
		}
		else {
			parameters = tupleExpression.pairs.map { $0.label }
		}

		let expressions = tupleExpression.pairs.map { $0.expression }

		let expressionIndentation =
			shouldAddNewlines ? increaseIndentation(indentation) : indentation

		let translations = try zipToClass(parameters, expressions)
			.map { parameterExpressionTuple -> String in
				try translateParameter(
					withLabel: parameterExpressionTuple.0,
					expression: parameterExpressionTuple.1,
					indentation: expressionIndentation)
			}

		if !shouldAddNewlines {
			let contents = translations.joined(separator: ", ")
			return "(\(contents))"
		}
		else {
			let contents = translations.joined(separator: ",\n\(indentation)")
			return "(\n\(indentation)\(contents))"
		}
	}

	private func translateParameter(
		withLabel label: String?,
		expression: Expression,
		indentation: String)
		throws -> String
	{
		let expression = try translateExpression(expression, withIndentation: indentation)

		if let label = label {
			return "\(label) = \(expression)"
		}
		else {
			return expression
		}
	}

	private func translateTupleShuffleExpression(
		_ tupleShuffleExpression: TupleShuffleExpression,
		translation: TranspilationContext.FunctionTranslation? = nil,
		withIndentation indentation: String,
		shouldAddNewlines: Bool = false)
		throws -> String
	{
		let parameters = translation?.parameters ?? tupleShuffleExpression.labels

		let increasedIndentation = increaseIndentation(indentation)

		let translations: ArrayClass<String> = []
		var expressionIndex = 0

		// Variadic arguments can't be named, which means all arguments before them can't be named
		// either.
		let containsVariadics = tupleShuffleExpression.indices.contains { indexIsVariadic($0) }
		var isBeforeVariadic = containsVariadics

		guard parameters.count == tupleShuffleExpression.indices.count else {
			return try unexpectedASTStructureError(
				"Different number of labels and indices in a tuple shuffle expression. " +
					"Labels: \(tupleShuffleExpression.labels), " +
					"indices: \(tupleShuffleExpression.indices)",
				AST: ExpressionStatement(
					range: nil,
					expression: TupleShuffleExpression(
						range: nil,
						labels: tupleShuffleExpression.labels,
						indices: tupleShuffleExpression.indices,
						expressions: tupleShuffleExpression.expressions)))
		}

		for (label, index) in zipToClass(parameters, tupleShuffleExpression.indices) {
			switch index {
			case .absent:
				break
			case .present:
				let expression = tupleShuffleExpression.expressions[expressionIndex]

				var result = ""

				if !isBeforeVariadic {
					result += "\(label) = "
				}

				result += try translateExpression(expression, withIndentation: increasedIndentation)

				translations.append(result)

				expressionIndex += 1
			case let .variadic(count: variadicCount):
				isBeforeVariadic = false
				for _ in 0..<variadicCount {
					let expression = tupleShuffleExpression.expressions[expressionIndex]
					let result = try translateExpression(
						expression, withIndentation: increasedIndentation)
					translations.append(result)
					expressionIndex += 1
				}
			}
		}

		var result = "("

		if shouldAddNewlines {
			result += "\n\(indentation)"
		}
		let separator = shouldAddNewlines ? ",\n\(indentation)" : ", "

		result += translations.joined(separator: separator) + ")"

		return result
	}

	private func indexIsVariadic(_ index: TupleShuffleIndex) -> Bool {
		if case .variadic = index {
			return true
		}
		else {
			return false
		}
	}

	private func translateStringLiteral(
		_ literalStringExpression: LiteralStringExpression)
		-> String
	{
		return "\"\(literalStringExpression.value)\""
	}

	// TODO: Test chars
	private func translateCharacterLiteral(
		_ literalCharacterExpression: LiteralCharacterExpression)
		-> String
	{
		return "'\(literalCharacterExpression.value)'"
	}

	private func translateInterpolatedStringLiteralExpression(
		_ interpolatedStringLiteralExpression: InterpolatedStringLiteralExpression,
		withIndentation indentation: String)
		throws -> String
	{
		var result = "\""

		for expression in interpolatedStringLiteralExpression.expressions {
			if let literalStringExpression = expression as? LiteralStringExpression {
				// Empty strings, as a special case, are represented by the swift ast dump
				// as two double quotes with nothing between them, instead of an actual empty string
				guard literalStringExpression.value != "\"\"" else {
					continue
				}

				result += literalStringExpression.value
			}
			else {
				let startDelimiter = "${" // value: \"\\${\"
				result += try startDelimiter +
					translateExpression(expression, withIndentation: indentation) +
					"}"
			}
		}

		result += "\""

		return result
	}

	// MARK: - Supporting methods

	internal func translateType(_ typeName: String) -> String {
		let typeName = typeName.replacingOccurrences(of: "()", with: "Unit")

		if typeName.hasSuffix("?") {
			return translateType(String(typeName.dropLast())) + "?"
		}
		else if typeName.hasPrefix("[") {
			if typeName.contains(":") {
				let innerType = String(typeName.dropLast().dropFirst())
				let innerTypes = Utilities.splitTypeList(innerType)
				let keyType = innerTypes[0]
				let valueType = innerTypes[1]
				let translatedKey = translateType(keyType)
				let translatedValue = translateType(valueType)
				return "MutableMap<\(translatedKey), \(translatedValue)>"
			}
			else {
				let innerType = String(typeName.dropLast().dropFirst())
				let translatedInnerType = translateType(innerType)
				return "MutableList<\(translatedInnerType)>"
			}
		}
		else if typeName.hasPrefix("ArrayClass<") {
			let innerType = String(typeName.dropLast().dropFirst("ArrayClass<".count))
			let translatedInnerType = translateType(innerType)
			return "MutableList<\(translatedInnerType)>"
		}
		else if typeName.hasPrefix("FixedArray<") {
			let innerType = String(typeName.dropLast().dropFirst("FixedArray<".count))
			let translatedInnerType = translateType(innerType)
			return "List<\(translatedInnerType)>"
		}
		else if typeName.hasPrefix("DictionaryClass<") {
			let innerTypes = String(typeName.dropLast().dropFirst("DictionaryClass<".count))
			let keyValue = Utilities.splitTypeList(innerTypes)
			let key = keyValue[0]
			let value = keyValue[1]
			let translatedKey = translateType(key)
			let translatedValue = translateType(value)
			return "MutableMap<\(translatedKey), \(translatedValue)>"
		}
		else if Utilities.isInEnvelopingParentheses(typeName) {
			let innerTypeString = String(typeName.dropFirst().dropLast())
			let innerTypes = Utilities.splitTypeList(innerTypeString, separators: [", "])
			if innerTypes.count == 2 {
				return "Pair<\(innerTypes.joined(separator: ", "))>"
			}
			else {
				return translateType(String(typeName.dropFirst().dropLast()))
			}
		}
		else if typeName.contains(" -> ") {
			let functionComponents = Utilities.splitTypeList(typeName, separators: [" -> "])
			let translatedComponents = functionComponents.map {
				translateFunctionTypeComponent($0)
			}

			let firstTypes = ArrayClass<String>(translatedComponents.dropLast().map { "(\($0))" })
			let lastType = translatedComponents.last!

			let allTypes = firstTypes
			allTypes.append(lastType)
			return allTypes.joined(separator: " -> ")
		}
		else {
			return Utilities.getTypeMapping(for: typeName) ?? typeName
		}
	}

	private func translateFunctionTypeComponent(_ component: String) -> String {
		if Utilities.isInEnvelopingParentheses(component) {
			let openComponent = String(component.dropFirst().dropLast())
			let componentParts = Utilities.splitTypeList(openComponent, separators: [", "])
			let translatedParts = componentParts.map { translateType($0) }
			return translatedParts.joined(separator: ", ")
		}
		else {
			return translateType(component)
		}
	}

	private func increaseIndentation(_ indentation: String) -> String {
		return indentation + KotlinTranslator.indentationString
	}

	private func decreaseIndentation(_ indentation: String) -> String {
		return String(indentation.dropLast(KotlinTranslator.indentationString.count))
	}
}

// MARK: - Error handling

struct KotlinTranslatorError: Error, CustomStringConvertible {
	let errorMessage: String
	let ast: Statement

	public var description: String {
		var nodeDescription = ""
		ast.prettyPrint(horizontalLimit: 100) {
			nodeDescription += $0
		}

		return "Error: failed to translate Gryphon AST into Kotlin.\n" +
			errorMessage + ".\n" +
			"Thrown when translating the following AST node:\n\(nodeDescription)"
	}
}

func unexpectedASTStructureError(
	_ errorMessage: String,
	AST ast: Statement)
	throws -> String
{
	let error = KotlinTranslatorError(errorMessage: errorMessage, ast: ast)
	try Compiler.handleError(error)
	return KotlinTranslator.errorTranslation
}
