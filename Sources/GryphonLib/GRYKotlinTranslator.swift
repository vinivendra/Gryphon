/*
* Copyright 2018 Vinícius Jorge Vendramini
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

public class GRYKotlinTranslator {
	static let errorTranslation = "<<Error>>"

	static let lineLimit = 100

	/// Used for the translation of Swift types into Kotlin types.
	static let typeMappings = [
		"Bool": "Boolean",
		"Error": "Exception",
		"UInt8": "UByte",
		"UInt16": "UShort",
		"UInt32": "UInt",
		"UInt64": "ULong",
		"Int8": "Byte",
		"Int16": "Short",
		"Int32": "Int",
		"Int64": "Long",
		"Float32": "Float",
		"Float64": "Double",
	]

	private func translateType(_ type: String) -> String {
		let type = type.replacingOccurrences(of: "()", with: "Unit")

		if type.hasPrefix("[") {
			if type.contains(":") {
				let innerTypes =
					String(type.dropLast().dropFirst()).split(withStringSeparator: " : ")
				let keyType = innerTypes[0]
				let valueType = innerTypes[1]
				let translatedKey = translateType(keyType)
				let translatedValue = translateType(valueType)
				return "MutableMap<\(translatedKey), \(translatedValue)>"
			}
			else {
				let innerType = String(type.dropLast().dropFirst())
				let translatedInnerType = translateType(innerType)
				return "MutableList<\(translatedInnerType)>"
			}
		}
		else if type.hasPrefix("ArrayReference<") {
			let innerType = String(type.dropLast().dropFirst("ArrayReference<".count))
			let translatedInnerType = translateType(innerType)
			return "MutableList<\(translatedInnerType)>"
		}
		else {
			return GRYKotlinTranslator.typeMappings[type] ?? type
		}
	}

	/**
	This variable is used to store enum definitions in order to allow the translator
	to translate them as sealed classes (see the `translate(dotSyntaxCallExpression)` method).
	*/
	private static var enums = [String]()

	public static func addEnum(_ enumName: String) {
		enums.append(enumName)
	}

	// MARK: - Interface

	public func translateAST(_ sourceFile: GRYAST) throws -> String {
		let declarationsTranslation =
			try translate(subtrees: sourceFile.declarations, withIndentation: "")

		let indentation = increaseIndentation("")
		let statementsTranslation =
			try translate(subtrees: sourceFile.statements, withIndentation: indentation)

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

	// MARK: - Implementation

	private func translate(subtree: GRYTopLevelNode, withIndentation indentation: String) throws
		-> String
	{
		let result: String

		switch subtree {
		case .importDeclaration(name: _):
			result = ""
		case .extensionDeclaration(type: _, members: _):
			return try unexpectedASTStructureError(
				"Extension structure should have been removed in a transpilation pass",
				AST: subtree)
		case let .typealiasDeclaration(identifier: identifier, type: type, isImplicit: isImplicit):
			result = try translateTypealias(
				identifier: identifier, type: type, isImplicit: isImplicit,
				withIndentation: indentation)
		case let .classDeclaration(name: name, inherits: inherits, members: members):
			result = try translateClassDeclaration(
				name: name, inherits: inherits, members: members, withIndentation: indentation)
		case let .structDeclaration(name: name, inherits: inherits, members: members):
			result = try translateStructDeclaration(
				name: name, inherits: inherits, members: members, withIndentation: indentation)
		case let .companionObject(members: members):
			result = try translateCompanionObject(members: members, withIndentation: indentation)
		case let .enumDeclaration(
			access: access, name: name, inherits: inherits, elements: elements, members: members,
			isImplicit: isImplicit):

			result = try translateEnumDeclaration(
				access: access, name: name, inherits: inherits, elements: elements,
				members: members, isImplicit: isImplicit, withIndentation: indentation)
		case .enumElementDeclaration(
			name: _, associatedValueLabels: _, associatedValueTypes: _):

			return try unexpectedASTStructureError(
				"Enum element translation should only be called from within the translation of " +
				"its wrapping Enum Declaration, since it needs to know the Enum's name.",
				AST: subtree)
		case let .forEachStatement(
			collection: collection, variable: variable, statements: statements):

			result = try translateForEachStatement(
				collection: collection, variable: variable, statements: statements,
				withIndentation: indentation)
		case let .functionDeclaration(value: functionDeclaration):
			result = try translateFunctionDeclaration(
				functionDeclaration: functionDeclaration, withIndentation: indentation)
		case let .protocolDeclaration(name: name, members: members):
			result = try translateProtocolDeclaration(
				name: name, members: members, withIndentation: indentation)
		case let .throwStatement(expression: expression):
			result = try translateThrowStatement(
				expression: expression, withIndentation: indentation)
		case let .variableDeclaration(value: variableDeclaration):
			result = try translateVariableDeclaration(
				variableDeclaration: variableDeclaration, withIndentation: indentation)
		case let .assignmentStatement(leftHand: leftHand, rightHand: rightHand):
			result = try translateAssignmentStatement(
				leftHand: leftHand, rightHand: rightHand, withIndentation: indentation)
		case let .ifStatement(
			conditions: conditions, declarations: declarations, statements: statements,
			elseStatement: elseStatement, isGuard: isGuard):

			result = try translateIfStatement(
				conditions: conditions, declarations: declarations, statements: statements,
				elseStatement: elseStatement, isGuard: isGuard, isElseIf: false,
				withIndentation: indentation)
		case let .switchStatement(
			convertsToExpression: convertsToExpression, expression: expression,
			cases: cases):

			result = try translateSwitchStatement(
				convertsToExpression: convertsToExpression, expression: expression, cases: cases,
				withIndentation: indentation)
		case let .returnStatement(expression: expression):
			result = try translateReturnStatement(
				expression: expression, withIndentation: indentation)
		case let .expression(expression: expression):
			let expressionTranslation =
				try translateExpression(expression, withIndentation: indentation)
			if !expressionTranslation.isEmpty {
				return indentation + expressionTranslation + "\n"
			}
			else {
				return ""
			}
		case .error:
			return GRYKotlinTranslator.errorTranslation
		}

		return result
	}

	private func translate(
		subtrees: [GRYTopLevelNode], withIndentation indentation: String,
		limitForAddingNewlines: Int = 0) throws -> String
	{
		let treesAndTranslations = try subtrees.map {
				(subtree: $0, translation: try translate(subtree: $0, withIndentation: indentation))
			}.filter {
				!$0.translation.isEmpty
			}

		if treesAndTranslations.count <= limitForAddingNewlines {
			return treesAndTranslations.map { $0.translation }.joined()
		}

		var result = ""

		for (currentSubtree, nextSubtree)
			in zip(treesAndTranslations, treesAndTranslations.dropFirst())
		{
			result += currentSubtree.translation

			// Cases that should go together
			if case .variableDeclaration = currentSubtree.subtree,
				case .variableDeclaration = nextSubtree.subtree
			{
				continue
			}
			else if case .expression(expression: .callExpression) = currentSubtree.subtree,
				case .expression(expression: .callExpression) = nextSubtree.subtree
			{
				continue
			}
			else if case .expression(expression: .templateExpression) = currentSubtree.subtree,
				case .expression(expression: .templateExpression) = nextSubtree.subtree
			{
				continue
			}
			else if case .assignmentStatement = currentSubtree.subtree,
				case .assignmentStatement = nextSubtree.subtree
			{
				continue
			}
			else if case .typealiasDeclaration = currentSubtree.subtree,
				case .typealiasDeclaration = nextSubtree.subtree
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

	private func translateEnumDeclaration(
		access: String?, name enumName: String, inherits: [String], elements: [GRYTopLevelNode],
		members: [GRYTopLevelNode], isImplicit: Bool, withIndentation indentation: String)
		throws -> String
	{
		var result: String

		if let access = access {
			result = "\(indentation)\(access) sealed class " + enumName
		}
		else {
			result = "\(indentation)sealed class " + enumName
		}

		if !inherits.isEmpty {
			var translatedInheritedTypes = inherits.map(translateType)
			translatedInheritedTypes[0] = translatedInheritedTypes[0] + "()"
			result += ": \(translatedInheritedTypes.joined(separator: ", "))"
		}

		result += " {\n"

		let increasedIndentation = increaseIndentation(indentation)

		var casesTranslation = ""
		for element in elements {
			if case let .enumElementDeclaration(
				name: elementName, associatedValueLabels: associatedValueLabels,
				associatedValueTypes: associatedValueTypes) = element
			{
				casesTranslation += translateEnumElementDeclaration(
					enumName: enumName, elementName: elementName,
					associatedValueLabels: associatedValueLabels,
					associatedValueTypes: associatedValueTypes,
					withIndentation: increasedIndentation)
			}
			else {
				return try unexpectedASTStructureError(
					"Expected enum element to be an .enumElementDeclaration",
					AST: .enumDeclaration(
						access: access, name: enumName, inherits: inherits, elements: elements,
						members: members, isImplicit: isImplicit))
			}
		}
		result += casesTranslation

		let membersTranslation =
			try translate(subtrees: members, withIndentation: increasedIndentation)

		// Add a newline between cases and members if needed
		if !casesTranslation.isEmpty && !membersTranslation.isEmpty {
			result += "\n"
		}

		result += "\(membersTranslation)\(indentation)}\n"

		return result
	}

	private func translateEnumElementDeclaration(
		enumName: String, elementName: String, associatedValueLabels: [String],
		associatedValueTypes: [String], withIndentation indentation: String) -> String
	{
		let capitalizedElementName = elementName.capitalizedAsCamelCase

		if associatedValueLabels.isEmpty {
			return "\(indentation)class \(capitalizedElementName): \(enumName)()\n"
		}
		else {
			let associatedValuesString = zip(associatedValueLabels, associatedValueTypes)
				.map { "val \($0): \($1)" }.joined(separator: ", ")
			return "\(indentation)class \(capitalizedElementName)(\(associatedValuesString)): " +
				"\(enumName)()\n"
		}
	}

	private func translateProtocolDeclaration(
		name: String, members: [GRYTopLevelNode], withIndentation indentation: String) throws
		-> String
	{
		var result = "\(indentation)interface \(name) {\n"
		let contents = try translate(
			subtrees: members, withIndentation: increaseIndentation(indentation))
		result += contents
		result += "\(indentation)}\n"
		return result
	}

	private func translateTypealias(
		identifier: String, type: String, isImplicit: Bool, withIndentation indentation: String)
		throws -> String
	{
		let translatedType = translateType(type)
		return "\(indentation)typealias \(identifier) = \(translatedType)\n"
	}

	private func translateClassDeclaration(
		name: String, inherits: [String], members: [GRYTopLevelNode],
		withIndentation indentation: String) throws -> String
	{
		var result = "\(indentation)class \(name)"

		if !inherits.isEmpty {
			let translatedInheritances = inherits.map(translateType)
			result += ": " + translatedInheritances.joined(separator: ", ")
		}

		result += " {\n"

		let increasedIndentation = increaseIndentation(indentation)

		let classContents = try translate(
			subtrees: members,
			withIndentation: increasedIndentation)

		result += classContents + "\(indentation)}\n"

		return result
	}

	/// If a value type's members are all immutable, that value type can safely be translated as a
	/// class. Source: https://forums.swift.org/t/are-immutable-structs-like-classes/16270
	private func translateStructDeclaration(
		name: String, inherits: [String], members: [GRYTopLevelNode],
		withIndentation indentation: String) throws -> String
	{
		let increasedIndentation = increaseIndentation(indentation)

		var result = "\(indentation)data class \(name)(\n"

		let isProperty = { (member: GRYTopLevelNode) -> Bool in
			if case .variableDeclaration = member {
				return true
			}
			else {
				return false
			}
		}
		let properties = members.filter(isProperty)
		let otherMembers = members.filter { !isProperty($0) }

		// Translate properties individually, dropping the newlines at the end
		let propertyTranslations = try properties.map {
			try String(translate(subtree: $0, withIndentation: increasedIndentation).dropLast())
		}
		let propertiesTranslation = propertyTranslations.joined(separator: ",\n")

		result += propertiesTranslation + "\n\(indentation))"

		if !inherits.isEmpty {
			let translatedInheritances = inherits.map(translateType)
			result += ": " + translatedInheritances.joined(separator: ", ")
		}

		let otherMembersTranslation = try translate(
			subtrees: otherMembers,
			withIndentation: increasedIndentation)

		if !otherMembersTranslation.isEmpty {
			result += " {\n\(otherMembersTranslation)\(indentation)}\n"
		}
		else {
			result += "\n"
		}

		return result
	}

	private func translateCompanionObject(
		members: [GRYTopLevelNode], withIndentation indentation: String) throws -> String
	{
		var result = "\(indentation)companion object {\n"

		let increasedIndentation = increaseIndentation(indentation)

		let contents = try translate(
			subtrees: members,
			withIndentation: increasedIndentation)

		result += contents + "\(indentation)}\n"

		return result
	}

	private func translateFunctionDeclaration(
		functionDeclaration: GRYASTFunctionDeclaration, withIndentation indentation: String,
		shouldAddNewlines: Bool = false) throws -> String
	{
		guard !functionDeclaration.isImplicit else {
			return ""
		}

		var indentation = indentation
		var result = indentation

		let isInit = (functionDeclaration.prefix == "init")
		if isInit {
			result += "constructor("
		}
		else {
			if let access = functionDeclaration.access {
				result += access + " "
			}
			result += "fun "
			if let extensionType = functionDeclaration.extendsType {
				result += extensionType + "."
			}
			result += functionDeclaration.prefix + "("
		}

		let returnString: String
		if functionDeclaration.returnType != "()", !isInit {
			let translatedReturnType = translateType(functionDeclaration.returnType)
			returnString = ": \(translatedReturnType)"
		}
		else {
			returnString = ""
		}

		let translatedParameterTypes = functionDeclaration.parameterTypes.map(translateType)
		let valueStrings = try functionDeclaration.defaultValues
			.map { (defaultValue: GRYExpression?) -> String in
				if let defaultValue = defaultValue {
					return try " = " + translateExpression(
						defaultValue, withIndentation: indentation)
				}
				else {
					return ""
				}
			}
		let parameters = zip(functionDeclaration.parameterNames, translatedParameterTypes)
			.map { $0.0 + ": " + $0.1 }
		let parameterStrings = zip(parameters, valueStrings).map { $0.0 + $0.1 }

		if !shouldAddNewlines {
			result += parameterStrings.joined(separator: ", ") + ")" + returnString + " {\n"
			if result.count >= GRYKotlinTranslator.lineLimit {
				return try translateFunctionDeclaration(
					functionDeclaration: functionDeclaration, withIndentation: indentation,
					shouldAddNewlines: true)
			}
		}
		else {
			let parameterIndentation = increaseIndentation(indentation)
			let parametersString = parameterStrings.joined(separator: ",\n\(parameterIndentation)")
			result += "\n\(parameterIndentation)" + parametersString + ")\n"

			if !returnString.isEmpty {
				result += "\(parameterIndentation)\(returnString)\n"
			}

			result += "\(indentation){\n"
		}

		guard let statements = functionDeclaration.statements else {
			return result + "\n"
		}

		indentation = increaseIndentation(indentation)
		result += try translate(
			subtrees: statements, withIndentation: indentation, limitForAddingNewlines: 3)
		indentation = decreaseIndentation(indentation)
		result += indentation + "}\n"

		return result
	}

	private func translateForEachStatement(
		collection: GRYExpression, variable: GRYExpression, statements: [GRYTopLevelNode],
		withIndentation indentation: String) throws -> String
	{
		var result = "\(indentation)for ("

		let variableTranslation = try translateExpression(variable, withIndentation: indentation)

		result += variableTranslation + " in "

		let collectionTranslation =
			try translateExpression(collection, withIndentation: indentation)

		result += collectionTranslation + ") {\n"

		let increasedIndentation = increaseIndentation(indentation)
		let statementsTranslation = try translate(
			subtrees: statements, withIndentation: increasedIndentation, limitForAddingNewlines: 3)

		result += statementsTranslation

		result += indentation + "}\n"
		return result
	}

	private func translateIfStatement(
		conditions: [GRYExpression], declarations: [GRYTopLevelNode], statements: [GRYTopLevelNode],
		elseStatement: GRYTopLevelNode?, isGuard: Bool, isElseIf: Bool,
		withIndentation indentation: String) throws -> String
	{
		let keyword = (conditions.isEmpty && declarations.isEmpty) ?
			"else" :
			(isElseIf ? "else if" : "if")

		var result = indentation + keyword + " "

		let increasedIndentation = increaseIndentation(indentation)

		let conditionsTranslation = try conditions.map {
				try translateExpression($0, withIndentation: indentation)
			}.joined(separator: " && ")

		if keyword != "else" {
			let parenthesizedCondition = isGuard ?
				("(!(" + conditionsTranslation + ")) ") :
				("(" + conditionsTranslation + ") ")

			result += parenthesizedCondition
		}

		result += "{\n"

		let statementsString = try translate(
			subtrees: statements, withIndentation: increasedIndentation, limitForAddingNewlines: 3)

		result += statementsString + indentation + "}\n"

		if let unwrappedElse = elseStatement {
			if case let .ifStatement(
				conditions: conditions, declarations: declarations, statements: statements,
				elseStatement: elseStatement, isGuard: isGuard) = unwrappedElse
			{
				result += try translateIfStatement(
					conditions: conditions, declarations: declarations, statements: statements,
					elseStatement: elseStatement, isGuard: isGuard, isElseIf: true,
					withIndentation: indentation)
			}
			else {
				return try unexpectedASTStructureError(
					"Expected the else statement to be an ifStatement." +
					"If it's a variableDeclaration, this might come from an `else if let`, which" +
					"is not supported.",
					AST: .ifStatement(
						conditions: conditions, declarations: declarations, statements: statements,
						elseStatement: elseStatement, isGuard: isGuard))
			}
		}

		return result
	}

	// TODO: test
	private func translateSwitchStatement(
		convertsToExpression: GRYTopLevelNode?, expression: GRYExpression,
		cases: [GRYASTSwitchCase], withIndentation indentation: String) throws -> String
	{
		var result: String = ""

		if let convertsToExpression = convertsToExpression {
			if case .returnStatement(expression: _) = convertsToExpression {
				result = "\(indentation)return when ("
			}
			else if case let .assignmentStatement(
				leftHand: leftHand, rightHand: _) = convertsToExpression
			{
				let translatedLeftHand =
					try translateExpression(leftHand, withIndentation: indentation)
				result = "\(indentation)\(translatedLeftHand) = when ("
			}
			else if case let .variableDeclaration(value: variableDeclaration) = convertsToExpression
			{
				let newVariableDeclaration = GRYASTVariableDeclaration(
					identifier: variableDeclaration.identifier,
					typeName: variableDeclaration.typeName, expression: .nilLiteralExpression,
					getter: nil, setter: nil, isLet: variableDeclaration.isLet, isImplicit: false,
					isStatic: false, extendsType: nil, annotations: variableDeclaration.annotations)
				let translatedVariableDeclaration = try translateVariableDeclaration(
					variableDeclaration: newVariableDeclaration, withIndentation: indentation)
				let cleanTranslation = translatedVariableDeclaration.dropLast("null\n".count)
				result = "\(cleanTranslation)when ("
			}
		}

		if result.isEmpty {
			result = "\(indentation)when ("
		}

		let expressionTranslation =
			try translateExpression(expression, withIndentation: indentation)
		let increasedIndentation = increaseIndentation(indentation)

		result += "\(expressionTranslation)) {\n"

		for switchCase in cases {
			if let caseExpression = switchCase.expression {
				if case let GRYExpression.binaryOperatorExpression(
					leftExpression: leftExpression, rightExpression: _, operatorSymbol: _,
					type: _) = caseExpression
				{
					let translatedExpression = try translateExpression(
						leftExpression, withIndentation: increasedIndentation)

					// If it's a range
					if case let .templateExpression(pattern: pattern, matches: _) = leftExpression,
						pattern.contains("..") || pattern.contains("until")
					{
						result += "\(increasedIndentation)in \(translatedExpression) -> "
					}
					else {
						result += "\(increasedIndentation)\(translatedExpression) -> "
					}
				}
			}
			else {
				result += "\(increasedIndentation)else -> "
			}

			if switchCase.statements.count == 1,
				let onlyStatement = switchCase.statements.first
			{
				let statementTranslation =
					try translate(subtree: onlyStatement, withIndentation: "")
				result += statementTranslation
			}
			else {
				result += "{\n"
				let statementsIndentation = increaseIndentation(increasedIndentation)
				let statementsTranslation = try translate(
					subtrees: switchCase.statements, withIndentation: statementsIndentation,
					limitForAddingNewlines: 3)
				result += "\(statementsTranslation)\(increasedIndentation)}\n"
			}
		}

		result += "\(indentation)}\n"

		return result
	}

	private func translateThrowStatement(
		expression: GRYExpression, withIndentation indentation: String) throws -> String
	{
		let expressionString = try translateExpression(expression, withIndentation: indentation)
		return "\(indentation)throw \(expressionString)\n"
	}

	private func translateReturnStatement(
		expression: GRYExpression?, withIndentation indentation: String) throws -> String
	{
		if let expression = expression {
			let expressionString = try translateExpression(expression, withIndentation: indentation)
			return "\(indentation)return \(expressionString)\n"
		}
		else {
			return "\(indentation)return\n"
		}
	}

	private func translateVariableDeclaration(
		variableDeclaration: GRYASTVariableDeclaration, withIndentation indentation: String)
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
			extensionPrefix = "\(translatedExtendedType)."
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
			guard case let .functionDeclaration(value: functionDeclaration) = getter else {
				return try unexpectedASTStructureError(
					"Expected the getter to be a .functionDeclaration",
					AST: .variableDeclaration(value: variableDeclaration))
			}

			if let statements = functionDeclaration.statements {
				result += indentation1 + "get() {\n"
				result += try translate(
					subtrees: statements, withIndentation: indentation2, limitForAddingNewlines: 3)
				result += indentation1 + "}\n"
			}
		}

		if let setter = variableDeclaration.setter {
			guard case let .functionDeclaration(value: functionDeclaration) = setter else {
				return try unexpectedASTStructureError(
					"Expected the setter to be a .functionDeclaration",
					AST: .variableDeclaration(value: variableDeclaration))
			}

			if let statements = functionDeclaration.statements {
				result += indentation1 + "set(newValue) {\n"
				result += try translate(
					subtrees: statements, withIndentation: indentation2, limitForAddingNewlines: 3)
				result += indentation1 + "}\n"
			}
		}

		return result
	}

	private func translateAssignmentStatement(
		leftHand: GRYExpression, rightHand: GRYExpression, withIndentation indentation: String)
		throws -> String
	{
		let leftTranslation = try translateExpression(leftHand, withIndentation: indentation)
		let rightTranslation = try translateExpression(rightHand, withIndentation: indentation)
		return "\(indentation)\(leftTranslation) = \(rightTranslation)\n"
	}

	private func translateExpression(
		_ expression: GRYExpression, withIndentation indentation: String) throws -> String
	{
		switch expression {
		case let .templateExpression(pattern: pattern, matches: matches):
			return try translateTemplateExpression(
				pattern: pattern, matches: matches, withIndentation: indentation)
		case let .literalCodeExpression(string: string):
			return translateLiteralCodeExpression(string: string)
		case let .arrayExpression(elements: elements, type: type):
			return try translateArrayExpression(
				elements: elements, type: type, withIndentation: indentation)
		case let .dictionaryExpression(keys: keys, values: values, type: type):
			return try translateDictionaryExpression(
				keys: keys, values: values, type: type, withIndentation: indentation)
		case let .binaryOperatorExpression(
			leftExpression: leftExpression,
			rightExpression: rightExpression,
			operatorSymbol: operatorSymbol,
			type: type):

			return try translateBinaryOperatorExpression(
				leftExpression: leftExpression,
				rightExpression: rightExpression,
				operatorSymbol: operatorSymbol,
				type: type,
				withIndentation: indentation)
		case let .callExpression(function: function, parameters: parameters, type: type):
			return try translateCallExpression(
				function: function, parameters: parameters, type: type,
				withIndentation: indentation)
		case let .closureExpression(
			parameterNames: parameterNames, parameterTypes: parameterTypes, statements: statements,
			type: type):

			return try translateClosureExpression(
				parameterNames: parameterNames, parameterTypes: parameterTypes,
				statements: statements, type: type, withIndentation: indentation)
		case let .declarationReferenceExpression(
			identifier: identifier, type: type, isStandardLibrary: isStandardLibrary,
			isImplicit: isImplicit):

			return translateDeclarationReferenceExpression(
				identifier: identifier, type: type, isStandardLibrary: isStandardLibrary,
				isImplicit: isImplicit)
		case let .dotExpression(leftExpression: leftExpression, rightExpression: rightExpression):
			return try translateDotSyntaxCallExpression(
				leftExpression: leftExpression,
				rightExpression: rightExpression,
				withIndentation: indentation)
		case let .literalStringExpression(value: value):
			return translateStringLiteral(value: value)
		case let .interpolatedStringLiteralExpression(expressions: expressions):
			return try translateInterpolatedStringLiteralExpression(
				expressions: expressions, withIndentation: indentation)
		case let .prefixUnaryExpression(
			expression: expression, operatorSymbol: operatorSymbol, type: type):

			return try translatePrefixUnaryExpression(
				expression: expression, operatorSymbol: operatorSymbol, type: type,
				withIndentation: indentation)
		case let .postfixUnaryExpression(
			expression: expression, operatorSymbol: operatorSymbol, type: type):

			return try translatePostfixUnaryExpression(
				expression: expression, operatorSymbol: operatorSymbol, type: type,
				withIndentation: indentation)
		case let .typeExpression(type: type):
			return translateType(type)
		case let .subscriptExpression(
			subscriptedExpression: subscriptedExpression, indexExpression: indexExpression,
			type: type):

			return try translateSubscriptExpression(
				subscriptedExpression: subscriptedExpression, indexExpression: indexExpression,
				type: type, withIndentation: indentation)
		case let .parenthesesExpression(expression: expression):
			return try "(" + translateExpression(expression, withIndentation: indentation) + ")"
		case let .forceValueExpression(expression: expression):
			return try translateExpression(expression, withIndentation: indentation) + "!!"
		case let .optionalExpression(expression: expression):
			return try translateExpression(expression, withIndentation: indentation) + "?"
		case let .literalIntExpression(value: value):
			return String(value)
		case let .literalUIntExpression(value: value):
			return String(value) + "u"
		case let .literalDoubleExpression(value: value):
			return String(value)
		case let .literalFloatExpression(value: value):
			return String(value) + "f"
		case let .literalBoolExpression(value: value):
			return String(value)
		case .nilLiteralExpression:
			return "null"
		case let .tupleExpression(pairs: pairs):
			return try translateTupleExpression(pairs: pairs, withIndentation: indentation)
		case .error:
			return GRYKotlinTranslator.errorTranslation
		}
	}

	private func translateSubscriptExpression(
		subscriptedExpression: GRYExpression, indexExpression: GRYExpression, type: String,
		withIndentation indentation: String)
		throws -> String
	{
		return try translateExpression(subscriptedExpression, withIndentation: indentation) +
			"[\(try translateExpression(indexExpression, withIndentation: indentation))]"
	}

	private func translateArrayExpression(
		elements: [GRYExpression], type: String, withIndentation indentation: String) throws
		-> String
	{
		let expressionsString = try elements.map {
				try translateExpression($0, withIndentation: indentation)
			}.joined(separator: ", ")

		return "mutableListOf(\(expressionsString))"
	}

	private func translateDictionaryExpression(
		keys: [GRYExpression], values: [GRYExpression], type: String,
		withIndentation indentation: String) throws -> String
	{
		let keyExpressions =
			try keys.map { try translateExpression($0, withIndentation: indentation) }
		let valueExpressions =
			try values.map { try translateExpression($0, withIndentation: indentation) }
		let expressionsString =
			zip(keyExpressions, valueExpressions).map { "\($0) to \($1)" }.joined(separator: ", ")

		return "mutableMapOf(\(expressionsString))"
	}

	private func translateDotSyntaxCallExpression(
		leftExpression: GRYExpression, rightExpression: GRYExpression,
		withIndentation indentation: String) throws -> String
	{
		let leftHandString = try translateExpression(leftExpression, withIndentation: indentation)
		let rightHandString = try translateExpression(rightExpression, withIndentation: indentation)

		if GRYKotlinTranslator.enums.contains(leftHandString) {
			let capitalizedEnumCase = rightHandString.capitalizedAsCamelCase
			return "\(leftHandString).\(capitalizedEnumCase)()"
		}
		else {
			return "\(leftHandString).\(rightHandString)"
		}
	}

	private func translateBinaryOperatorExpression(
		leftExpression: GRYExpression, rightExpression: GRYExpression, operatorSymbol: String,
		type: String, withIndentation indentation: String) throws -> String
	{
		let leftTranslation = try translateExpression(leftExpression, withIndentation: indentation)
		let rightTranslation =
			try translateExpression(rightExpression, withIndentation: indentation)
		return "\(leftTranslation) \(operatorSymbol) \(rightTranslation)"
	}

	private func translatePrefixUnaryExpression(
		expression: GRYExpression, operatorSymbol: String, type: String,
		withIndentation indentation: String) throws -> String
	{
		let expressionTranslation =
			try translateExpression(expression, withIndentation: indentation)
		return operatorSymbol + expressionTranslation
	}

	private func translatePostfixUnaryExpression(
		expression: GRYExpression, operatorSymbol: String, type: String,
		withIndentation indentation: String) throws -> String
	{
		let expressionTranslation =
			try translateExpression(expression, withIndentation: indentation)
		return expressionTranslation + operatorSymbol
	}

	private func translateCallExpression(
		function: GRYExpression, parameters: GRYExpression, type: String,
		withIndentation indentation: String, shouldAddNewlines: Bool = false) throws -> String
	{
		guard case let .tupleExpression(pairs: pairs) = parameters else {
			return try unexpectedASTStructureError(
				"Expected the parameters to be a .tupleExpression",
				AST: .expression(expression:
					.callExpression(function: function, parameters: parameters, type: type)))
		}

		let functionTranslation =
			try translateExpression(function, withIndentation: indentation)
		let parametersTranslation = try translateTupleExpression(
			pairs: pairs, withIndentation: increaseIndentation(indentation),
			shouldAddNewlines: shouldAddNewlines)
		let result = functionTranslation + parametersTranslation

		if !shouldAddNewlines, result.count >= GRYKotlinTranslator.lineLimit {
			return try translateCallExpression(
				function: function, parameters: parameters, type: type,
				withIndentation: indentation, shouldAddNewlines: true)
		}
		else {
			return result
		}
	}

	private func translateClosureExpression(
		parameterNames: [String], parameterTypes: [String], statements: [GRYTopLevelNode],
		type: String, withIndentation indentation: String) throws -> String
	{
		var result = "{"

		let parametersString = parameterNames.joined(separator: ", ")

		if !parametersString.isEmpty {
			result += " " + parametersString + " ->"
		}

		if statements.count == 1,
			let firstStatement = statements.first,
			case let GRYTopLevelNode.expression(expression: expression) = firstStatement
		{
			result += try " " + translateExpression(expression, withIndentation: indentation) + " }"
		}
		else {
			result += "\n"
			let closingBraceIndentation = increaseIndentation(indentation)
			let contentsIndentation = increaseIndentation(closingBraceIndentation)
			result += try translate(subtrees: statements, withIndentation: contentsIndentation)
			result += closingBraceIndentation + "}"
		}

		return result
	}

	private func translateLiteralCodeExpression(string: String) -> String {
		return removeBackslashEscapes(string)
	}

	private func translateTemplateExpression(
		pattern: String, matches: [String: GRYExpression], withIndentation indentation: String)
		throws -> String
	{
		var result = pattern
		for (string, expression) in matches {
			while let range = result.range(of: string) {
				result.replaceSubrange(
					range, with: try translateExpression(expression, withIndentation: indentation))
			}
		}
		return result
	}

	private func translateDeclarationReferenceExpression(
		identifier: String, type: String, isStandardLibrary: Bool, isImplicit: Bool) -> String
	{
		return String(identifier.prefix { $0 != "(" })
	}

	private func translateTupleExpression(
		pairs: [GRYExpression.TuplePair], withIndentation indentation: String,
		shouldAddNewlines: Bool = false) throws -> String
	{
		guard !pairs.isEmpty else {
			return "()"
		}

		// TODO: test
		let expressionIndentation =
			shouldAddNewlines ? increaseIndentation(indentation) : indentation

		let translations = try pairs.map { (pair: GRYExpression.TuplePair) -> String in
			let expression =
				try translateExpression(pair.expression, withIndentation: expressionIndentation)

			if let name = pair.name {
				return "\(name) = \(expression)"
			}
			else {
				return expression
			}
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

	private func translateStringLiteral(value: String) -> String {
		return "\"\(value)\""
	}

	private func translateInterpolatedStringLiteralExpression(
		expressions: [GRYExpression], withIndentation indentation: String) throws -> String
	{
		var result = "\""

		for expression in expressions {
			if case let .literalStringExpression(value: string) = expression {
				// Empty strings, as a special case, are represented by the swift ast dump
				// as two double quotes with nothing between them, instead of an actual empty string
				guard string != "\"\"" else {
					continue
				}

				result += string
			}
			else {
				result +=
					try "${" + translateExpression(expression, withIndentation: indentation) + "}"
			}
		}

		result += "\""

		return result
	}

	// MARK: - Supporting methods
	private func removeBackslashEscapes(_ string: String) -> String {
		var result = ""
		var isEscaping = false

		for character in string {
			if !isEscaping {
				if character == "\\" {
					isEscaping = true
				}
				else {
					result.append(character)
				}
			}
			else {
				switch character {
				case "\\":
					result.append("\\")
				case "n":
					result.append("\n")
				case "t":
					result.append("\t")
				default:
					result.append(character)
					isEscaping = false
				}

				isEscaping = false
			}
		}

		return result
	}

	//
	private func increaseIndentation(_ indentation: String) -> String {
		return indentation + "\t"
	}

	private func decreaseIndentation(_ indentation: String) -> String {
		return String(indentation.dropLast())
	}
}

extension String {
	var capitalizedAsCamelCase: String {
		let firstCharacter = self.first!
		let capitalizedFirstCharacter = String(firstCharacter).uppercased()
		return String(capitalizedFirstCharacter + self.dropFirst())
	}
}

public enum GRYKotlinTranslatorError: Error, CustomStringConvertible {
	case unexpectedASTStructure(
		file: String,
		line: Int,
		function: String,
		message: String,
		AST: GRYTopLevelNode)

	public var description: String {
		switch self {
		case let .unexpectedASTStructure(
			file: file, line: line, function: function, message: message, AST: ast):

			var nodeDescription = ""
			ast.prettyPrint(horizontalLimit: 100) {
				nodeDescription += $0
			}

			return "Error: failed to translate Gryphon AST into Kotlin.\n" +
				"On file \(file), line \(line), function \(function).\n" +
				message + ".\n" +
			"Thrown when translating the following AST node:\n\(nodeDescription)"

		}
	}

	public var astName: String {
		switch self {
		case let .unexpectedASTStructure(file: _, line: _, function: _, message: _, AST: ast):
			return ast.name
		}
	}
}

func unexpectedASTStructureError(
	file: String = #file, line: Int = #line, function: String = #function, _ message: String,
	AST ast: GRYTopLevelNode) throws -> String
{
	let error = GRYKotlinTranslatorError.unexpectedASTStructure(
		file: file, line: line, function: function, message: message, AST: ast)
	try GRYCompiler.handleError(error)
	return GRYKotlinTranslator.errorTranslation
}
