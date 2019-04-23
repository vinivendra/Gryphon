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

import Foundation

public class SwiftTranslator {
	// MARK: - Properties
	typealias PatternBindingDeclaration =
		(identifier: String, type: String, expression: Expression?)?
	var danglingPatternBindings = [PatternBindingDeclaration?]()
	let errorDanglingPatternDeclaration: PatternBindingDeclaration =
		(identifier: "<<Error>>", type: "<<Error>>", expression: Expression.error)

	fileprivate var sourceFile: SourceFile?

	// MARK: - Interface
	public init() { }

	public func translateAST(_ ast: SwiftAST, asMainFile isMainFile: Bool) throws
		-> GryphonAST
	{
		let filePath = ast.standaloneAttributes[0]
		if let contents = try? String(contentsOfFile: filePath) {
			sourceFile = SourceFile(path: filePath, contents: contents)
		}

		let fileRange = sourceFile.map {
			SourceFileRange(lineStart: 0, lineEnd: $0.numberOfLines, columnStart: 0, columnEnd: 0)
		}
		let translatedSubtrees = try translate(
			subtrees: ast.subtrees.array,
			inScope: fileRange)

		let isDeclaration = { (ast: Statement) -> Bool in
			switch ast {
			case .expression(expression: .literalDeclarationExpression),
				.protocolDeclaration,
				.classDeclaration,
				.structDeclaration,
				.extensionDeclaration,
				.functionDeclaration,
				.enumDeclaration,
				.typealiasDeclaration:

				return true
			default:
				return false
			}
		}

		if isMainFile {
			let declarations = translatedSubtrees.filter(isDeclaration)
			let statements = translatedSubtrees.filter({ !isDeclaration($0) })

			return GryphonAST(
				sourceFile: sourceFile,
				declarations: ArrayClass(declarations),
				statements: ArrayClass(statements))
		}
		else {
			return GryphonAST(
				sourceFile: sourceFile,
				declarations: ArrayClass(translatedSubtrees),
				statements: [])
		}
	}

	// MARK: - Top-level translations
	internal func translate(subtree: SwiftAST) throws -> [Statement?] {

		if getComment(forNode: subtree, key: "kotlin") == "ignore" {
			return []
		}

		let result: [Statement?]
		switch subtree.name {
		case "Top Level Code Declaration":
			result = [try translate(topLevelCode: subtree)]
		case "Import Declaration":
			result = [.importDeclaration(name: subtree.standaloneAttributes[0])]
		case "Typealias":
			result = [try translate(typealiasDeclaration: subtree)]
		case "Class Declaration":
			result = [try translate(classDeclaration: subtree)]
		case "Struct Declaration":
			result = [try translate(structDeclaration: subtree)]
		case "Enum Declaration":
			result = [try translate(enumDeclaration: subtree)]
		case "Extension Declaration":
			result = [try translate(extensionDeclaration: subtree)]
		case "For Each Statement":
			result = [try translate(forEachStatement: subtree)]
		case "While Statement":
			result = [try translate(whileStatement: subtree)]
		case "Function Declaration", "Constructor Declaration":
			result = [try translate(functionDeclaration: subtree)]
		case "Subscript Declaration":
			result = try subtree.subtrees.filter { $0.name == "Accessor Declaration" }
				.map { try translate(functionDeclaration: $0) }
		case "Protocol":
			result = [try translate(protocolDeclaration: subtree)]
		case "Throw Statement":
			result = [try translate(throwStatement: subtree)]
		case "Variable Declaration":
			result = [try translate(variableDeclaration: subtree)]
		case "Assign Expression":
			result = [try translate(assignExpression: subtree)]
		case "If Statement", "Guard Statement":
			result = [try translate(ifStatement: subtree)]
		case "Switch Statement":
			result = [try translate(switchStatement: subtree)]
		case "Defer Statement":
			result = [try translate(deferStatement: subtree)]
		case "Pattern Binding Declaration":
			try process(patternBindingDeclaration: subtree)
			result = []
		case "Return Statement":
			result = [try translate(returnStatement: subtree)]
		case "Break Statement":
			result = [.breakStatement]
		case "Continue Statement":
			result = [.continueStatement]
		case "Fail Statement":
			result = [.returnStatement(expression: .nilLiteralExpression)]
		default:
			if subtree.name.hasSuffix("Expression") {
				let expression = try translate(expression: subtree)
				result = [.expression(expression: expression)]
			}
			else {
				result = []
			}
		}

		let shouldInspect = (getComment(forNode: subtree, key: "gryphon") == "inspect")
		if shouldInspect {
			print("===\nInspecting:")
			print(subtree)
			for statement in result {
				statement?.prettyPrint()
			}
		}

		return result
	}

	internal func translate(expression: SwiftAST) throws -> Expression {

		if let valueReplacement = getComment(forNode: expression, key: "value") {
			return Expression.literalCodeExpression(string: valueReplacement)
		}

		let result: Expression
		switch expression.name {
		case "Array Expression":
			result = try translate(arrayExpression: expression)
		case "Dictionary Expression":
			result = try translate(dictionaryExpression: expression)
		case "Binary Expression":
			result = try translate(binaryExpression: expression)
		case "If Expression":
			result = try translate(ifExpression: expression)
		case "Call Expression":
			result = try translate(callExpression: expression)
		case "Closure Expression":
			result = try translate(closureExpression: expression)
		case "Declaration Reference Expression":
			result = try translate(declarationReferenceExpression: expression)
		case "Dot Syntax Call Expression":
			result = try translate(dotSyntaxCallExpression: expression)
		case "String Literal Expression":
			result = try translate(stringLiteralExpression: expression)
		case "Interpolated String Literal Expression":
			result = try translate(interpolatedStringLiteralExpression: expression)
		case "Erasure Expression":
			if let lastExpression = expression.subtrees.last {
				result = try translate(expression: lastExpression)
			}
			else {
				result = try unexpectedExpressionStructureError(
					"Unrecognized structure in automatic expression",
					AST: expression, translator: self)
			}
		case "Prefix Unary Expression":
			result = try translate(prefixUnaryExpression: expression)
		case "Postfix Unary Expression":
			result = try translate(postfixUnaryExpression: expression)
		case "Type Expression":
			result = try translate(typeExpression: expression)
		case "Member Reference Expression":
			result = try translate(memberReferenceExpression: expression)
		case "Tuple Element Expression":
			result = try translate(tupleElementExpression: expression)
		case "Tuple Expression":
			result = try translate(tupleExpression: expression)
		case "Subscript Expression":
			result = try translate(subscriptExpression: expression)
		case "Nil Literal Expression":
			result = .nilLiteralExpression
		case "Open Existential Expression":
			let processedExpression = try process(openExistentialExpression: expression)
			result = try translate(expression: processedExpression)
		case "Parentheses Expression":
			if let innerExpression = expression.subtree(at: 0) {
				// Swift 5: Compiler-created parentheses expressions may be marked with "implicit"
				if expression.standaloneAttributes.contains("implicit") {
					result = try translate(expression: innerExpression)
				}
				else {
					result = .parenthesesExpression(
						expression: try translate(expression: innerExpression))
				}
			}
			else {
				result = try unexpectedExpressionStructureError(
					"Expected parentheses expression to have at least one subtree",
					AST: expression, translator: self)
			}
		case "Force Value Expression":
			if let firstExpression = expression.subtree(at: 0) {
				let expression = try translate(expression: firstExpression)
				result = .forceValueExpression(expression: expression)
			}
			else {
				result = try unexpectedExpressionStructureError(
					"Expected force value expression to have at least one subtree",
					AST: expression, translator: self)
			}
		case "Bind Optional Expression":
			if let firstExpression = expression.subtree(at: 0) {
				let expression = try translate(expression: firstExpression)
				result = .optionalExpression(expression: expression)
			}
			else {
				result = try unexpectedExpressionStructureError(
					"Expected optional expression to have at least one subtree",
					AST: expression, translator: self)
			}
		case "Conditional Checked Cast Expression":
			if let type = expression["type"],
				let bindOptionalExpression = expression.subtrees.first,
				let subExpression = bindOptionalExpression.subtrees.first
			{
				result = .binaryOperatorExpression(
					leftExpression: try translate(expression: subExpression),
					rightExpression: .typeExpression(type: type),
					operatorSymbol: "as?",
					type: type)
			}
			else {
				result = try unexpectedExpressionStructureError(
					"Expected Conditional Checked Cast Expression to have a type and two nested " +
						"subtrees",
					AST: expression, translator: self)
			}
		case "Autoclosure Expression",
			"Inject Into Optional",
			"Optional Evaluation Expression",
			"Inout Expression",
			"Load Expression",
			"Function Conversion Expression",
			"Try Expression",
			"Force Try Expression",
			"Dot Self Expression":

			if let lastExpression = expression.subtrees.last {
				result = try translate(expression: lastExpression)
			}
			else {
				result = try unexpectedExpressionStructureError(
					"Unrecognized structure in automatic expression",
					AST: expression, translator: self)
			}
		case "Collection Upcast Expression":
			if let firstExpression = expression.subtrees.first {
				result = try translate(expression: firstExpression)
			}
			else {
				result = try unexpectedExpressionStructureError(
					"Unrecognized structure in automatic expression",
					AST: expression, translator: self)
			}
		default:
			result = try unexpectedExpressionStructureError(
				"Unknown expression", AST: expression, translator: self)
		}

		let shouldInspect = (getComment(forNode: expression, key: "gryphon") == "inspect")
		if shouldInspect {
			print("===\nInspecting:")
			print(expression)
			result.prettyPrint()
		}

		return result
	}

	internal func translate(
		subtrees: [SwiftAST],
		inScope scope: SwiftAST,
		asDeclarations: Bool = false) throws -> [Statement]
	{
		let scopeRange = getRange(ofNode: scope)
		return try translate(
			subtrees: subtrees, inScope: scopeRange)
	}

	internal func translate(
		subtrees: [SwiftAST],
		inScope scopeRange: SourceFileRange?) throws -> [Statement]
	{
		var result = [Statement]()

		var lastRange: SourceFileRange
		// I we have a scope, start at its lower bound
		if let scopeRange = scopeRange {
			lastRange = SourceFileRange(
				lineStart: -1,
				lineEnd: scopeRange.lineStart,
				columnStart: 0,
				columnEnd: 0)
		}
		// If we don't, start at the first statement with a range
		else if let subtree = subtrees.first(where: { getRange(ofNode: $0) != nil }) {
			lastRange = getRange(ofNode: subtree)!
		}
		// If there is no info on ranges, then just translate the subtrees normally
		else {
			return try subtrees.flatMap(translate(subtree:)).compactMap { $0 }
		}

		let commentToAST = { (comment: SourceFile.Comment) -> Statement? in
				if comment.key == "insert" {
					return Statement.expression(expression:
						.literalCodeExpression(string: comment.value))
				}
				else if comment.key == "declaration" {
					return Statement.expression(expression:
						.literalDeclarationExpression(string: comment.value))
				}
				else {
					return nil
				}
			}

		for subtree in subtrees {
			if let currentRange = getRange(ofNode: subtree),
				lastRange.lineEnd < currentRange.lineStart
			{
				let comments = insertedCode(inRange: lastRange.lineEnd..<currentRange.lineStart)
				result += comments.compactMap(commentToAST)

				lastRange = currentRange
			}

			result.append(contentsOf: try translate(subtree: subtree).compactMap { $0 })
		}

		// Insert code in comments after the last translated node
		if let scopeRange = scopeRange,
			lastRange.lineEnd < scopeRange.lineEnd
		{
			let comments = insertedCode(
				inRange: lastRange.lineEnd..<scopeRange.lineEnd)
			result += comments.compactMap(commentToAST)
		}

		return result
	}

	// MARK: - Leaf translations
	internal func translate(subtreesOf ast: SwiftAST) throws -> [Statement] {
		return try translate(subtrees: ast.subtrees.array, inScope: ast)
	}

	internal func translate(braceStatement: SwiftAST) throws -> [Statement] {
		guard braceStatement.name == "Brace Statement" else {
			throw createUnexpectedASTStructureError(
				"Trying to translate \(braceStatement.name) as a brace statement",
				AST: braceStatement, translator: self)
		}

		return try translate(subtrees: braceStatement.subtrees.array, inScope: braceStatement)
	}

	internal func translate(protocolDeclaration: SwiftAST) throws -> Statement {
		guard protocolDeclaration.name == "Protocol" else {
			return try unexpectedASTStructureError(
				"Trying to translate \(protocolDeclaration.name) as 'Protocol'",
				AST: protocolDeclaration, translator: self)
		}

		guard let protocolName = protocolDeclaration.standaloneAttributes.first else {
			return try unexpectedASTStructureError(
				"Unrecognized structure",
				AST: protocolDeclaration, translator: self)
		}

		let members = try translate(subtreesOf: protocolDeclaration)

		return .protocolDeclaration(name: protocolName, members: ArrayClass(members))
	}

	internal func translate(assignExpression: SwiftAST) throws -> Statement {
		guard assignExpression.name == "Assign Expression" else {
			return try unexpectedASTStructureError(
				"Trying to translate \(assignExpression.name) as 'Assign Expression'",
				AST: assignExpression, translator: self)
		}

		if let leftExpression = assignExpression.subtree(at: 0),
			let rightExpression = assignExpression.subtree(at: 1)
		{
			if leftExpression.name == "Discard Assignment Expression" {
				return try .expression(expression: translate(expression: rightExpression))
			}
			else {
				let leftTranslation = try translate(expression: leftExpression)
				let rightTranslation = try translate(expression: rightExpression)

				return .assignmentStatement(leftHand: leftTranslation, rightHand: rightTranslation)
			}
		}
		else {
			return try unexpectedASTStructureError(
				"Unrecognized structure",
				AST: assignExpression, translator: self)
		}
	}

	internal func translate(typealiasDeclaration: SwiftAST) throws -> Statement {
		let isImplicit: Bool
		let identifier: String
		if typealiasDeclaration.standaloneAttributes[0] == "implicit" {
			isImplicit = true
			identifier = typealiasDeclaration.standaloneAttributes[1]
		}
		else {
			isImplicit = false
			identifier = typealiasDeclaration.standaloneAttributes[0]
		}

		return .typealiasDeclaration(
			identifier: identifier, type: typealiasDeclaration["type"]!, isImplicit: isImplicit)
	}

	internal func translate(classDeclaration: SwiftAST) throws -> Statement? {
		guard classDeclaration.name == "Class Declaration" else {
			return try unexpectedASTStructureError(
				"Trying to translate \(classDeclaration.name) as 'Class Declaration'",
				AST: classDeclaration, translator: self)
		}

		if getComment(forNode: classDeclaration, key: "kotlin") == "ignore" {
			return nil
		}

		// Get the class name
		let name = classDeclaration.standaloneAttributes.first!

		// Check for inheritance
		let inheritanceArray: ArrayClass<String>
		if let inheritanceList = classDeclaration["inherits"] {
			inheritanceArray = ArrayClass(inheritanceList.split(withStringSeparator: ", "))
		}
		else {
			inheritanceArray = []
		}

		// Translate the contents
		let classContents = try translate(subtreesOf: classDeclaration)

		return .classDeclaration(
			name: name,
			inherits: inheritanceArray,
			members: ArrayClass(classContents))
	}

	internal func translate(structDeclaration: SwiftAST) throws -> Statement? {
		guard structDeclaration.name == "Struct Declaration" else {
			return try unexpectedASTStructureError(
				"Trying to translate \(structDeclaration.name) as 'Struct Declaration'",
				AST: structDeclaration, translator: self)
		}

		if getComment(forNode: structDeclaration, key: "kotlin") == "ignore" {
			return nil
		}

		let annotations = getComment(forNode: structDeclaration, key: "annotation")

		// Get the struct name
		let name = structDeclaration.standaloneAttributes.first!

		// Check for inheritance
		let inheritanceArray: ArrayClass<String>
		if let inheritanceList = structDeclaration["inherits"] {
			inheritanceArray = ArrayClass(inheritanceList.split(withStringSeparator: ", "))
		}
		else {
			inheritanceArray = []
		}

		// Translate the contents
		let structContents = try translate(subtreesOf: structDeclaration)

		return .structDeclaration(
			annotations: annotations,
			name: name,
			inherits: inheritanceArray,
			members: ArrayClass(structContents))
	}

	internal func translate(throwStatement: SwiftAST) throws -> Statement {
		guard throwStatement.name == "Throw Statement" else {
			return try unexpectedASTStructureError(
				"Trying to translate \(throwStatement.name) as 'Throw Statement'",
				AST: throwStatement, translator: self)
		}

		if let expression = throwStatement.subtrees.last {
			let expressionTranslation = try translate(expression: expression)
			return .throwStatement(expression: expressionTranslation)
		}
		else {
			return try unexpectedASTStructureError(
				"Unrecognized structure",
				AST: throwStatement, translator: self)
		}
	}

	internal func translate(extensionDeclaration: SwiftAST) throws -> Statement {
		let type = cleanUpType(extensionDeclaration.standaloneAttributes[0])
		let members = try translate(subtreesOf: extensionDeclaration)
		return .extensionDeclaration(type: type, members: ArrayClass(members))
	}

	internal func translate(enumDeclaration: SwiftAST) throws -> Statement? {
		guard enumDeclaration.name == "Enum Declaration" else {
			return try unexpectedASTStructureError(
				"Trying to translate \(enumDeclaration.name) as 'Enum Declaration'",
				AST: enumDeclaration, translator: self)
		}

		if getComment(forNode: enumDeclaration, key: "kotlin") == "ignore" {
			return nil
		}

		let access = enumDeclaration["access"]

		let name: String
		let isImplicit: Bool
		if enumDeclaration.standaloneAttributes[0] == "implicit" {
			isImplicit = true
			name = enumDeclaration.standaloneAttributes[1]
		}
		else {
			isImplicit = false
			name = enumDeclaration.standaloneAttributes[0]
		}

		let inheritanceArray: ArrayClass<String>
		if let inheritanceList = enumDeclaration["inherits"] {
			inheritanceArray = ArrayClass(inheritanceList.split(withStringSeparator: ", "))
		}
		else {
			inheritanceArray = []
		}

		var rawValues: [Expression] = []
		let constructorDeclarations = enumDeclaration.subtrees.filter {
			$0.name ==  "Constructor Declaration"
		}
		for constructorDeclaration in constructorDeclarations {
			if constructorDeclaration.standaloneAttributes.contains("init(rawValue:)"),
				constructorDeclaration.standaloneAttributes.contains("implicit"),
				let arrayExpression = constructorDeclaration.subtree(named: "Brace Statement")?
					.subtree(named: "Switch Statement")?
					.subtree(named: "Call Expression")?
					.subtree(named: "Tuple Expression")?
					.subtree(named: "Array Expression")
			{
				let rawValueASTs = Array(arrayExpression.subtrees.dropLast())
				rawValues = try rawValueASTs.map { try translate(expression: $0) }
				break
			}
		}

		let elements: ArrayClass<EnumElement> = []
		let enumElementDeclarations =
			enumDeclaration.subtrees.filter { $0.name == "Enum Element Declaration" }
		for index in enumElementDeclarations.indices {
			let enumElementDeclaration = enumElementDeclarations[index]

			guard getComment(forNode: enumElementDeclaration, key: "kotlin") != "ignore" else {
				continue
			}

			guard let elementName = enumElementDeclaration.standaloneAttributes.first else {
				return try unexpectedASTStructureError(
					"Expected the element name to be the first standalone attribute in an Enum" +
					"Declaration",
					AST: enumDeclaration, translator: self)
			}

			let annotations = getComment(forNode: enumElementDeclaration, key: "annotation")

			if !elementName.contains("(") {
				elements.append(EnumElement(
					name: elementName,
					associatedValues: [],
					rawValue: rawValues[safe: index],
					annotations: annotations))
			}
			else {
				let parenthesisIndex = elementName.firstIndex(of: "(")!
				let prefix = String(elementName[elementName.startIndex..<parenthesisIndex])
				let suffix = elementName[parenthesisIndex...]
				let valuesString = suffix.dropFirst().dropLast(2)
				let valueLabels = ArrayClass(valuesString.split(separator: ":")).map(String.init)

				guard let enumType = enumElementDeclaration["interface type"] else {
					return try unexpectedASTStructureError(
						"Expected an enum element with associated values to have an interface type",
						AST: enumDeclaration, translator: self)
				}
				let enumTypeComponents = enumType.split(withStringSeparator: " -> ")
				let valuesComponent = enumTypeComponents[1]
				let valueTypesString = String(valuesComponent.dropFirst().dropLast())
				let valueTypes = Utilities.splitTypeList(valueTypesString)

				let associatedValues = zipToClass(valueLabels, valueTypes).map(LabeledType.init)

				elements.append(EnumElement(
					name: prefix,
					associatedValues: associatedValues,
					rawValue: rawValues[safe: index],
					annotations: annotations))
			}
		}

		let members = enumDeclaration.subtrees.filter {
			$0.name != "Enum Element Declaration" && $0.name != "Enum Case Declaration"
		}
		let translatedMembers = try translate(subtrees: members.array, inScope: enumDeclaration)

		return .enumDeclaration(
			access: access,
			name: name,
			inherits: inheritanceArray,
			elements: elements,
			members: ArrayClass(translatedMembers),
			isImplicit: isImplicit)
	}

	internal func translate(memberReferenceExpression: SwiftAST) throws -> Expression {
		guard memberReferenceExpression.name == "Member Reference Expression" else {
			return try unexpectedExpressionStructureError(
				"Trying to translate \(memberReferenceExpression.name) as " +
				"'Member Reference Expression'",
				AST: memberReferenceExpression, translator: self)
		}

		if let declaration = memberReferenceExpression["decl"],
			let memberOwner = memberReferenceExpression.subtree(at: 0),
			let rawType = memberReferenceExpression["type"]
		{
			let type = cleanUpType(rawType)
			let leftHand = try translate(expression: memberOwner)
			let (member, isStandardLibrary) = getIdentifierFromDeclaration(declaration)
			let isImplicit = memberReferenceExpression.standaloneAttributes.contains("implicit")
			let range = getRangeRecursively(ofNode: memberReferenceExpression)
			let rightHand = Expression.declarationReferenceExpression(data:
				DeclarationReferenceData(
					identifier: member,
					type: type,
					isStandardLibrary: isStandardLibrary,
					isImplicit: isImplicit,
					range: range))
			return .dotExpression(leftExpression: leftHand,
								  rightExpression: rightHand)
		}
		else {
			return try unexpectedExpressionStructureError(
				"Unrecognized structure",
				AST: memberReferenceExpression, translator: self)
		}
	}

	internal func translate(tupleElementExpression: SwiftAST) throws -> Expression {
		guard tupleElementExpression.name == "Tuple Element Expression" else {
			return try unexpectedExpressionStructureError(
				"Trying to translate \(tupleElementExpression.name) as " +
				"'Tuple Element Expression'",
				AST: tupleElementExpression, translator: self)
		}

		if let numberString =
				tupleElementExpression.standaloneAttributes.first(where: { $0.hasPrefix("#") }),
			let number = Int(numberString.dropFirst()),
			let declarationReference =
				tupleElementExpression.subtree(named: "Declaration Reference Expression"),
			let tuple = declarationReference["type"]
		{
			let leftHand = try translate(declarationReferenceExpression: declarationReference)
			let tupleComponents =
				String(tuple.dropFirst().dropLast()).split(withStringSeparator: ", ")
			let tupleComponent = tupleComponents[safe: number]
			if let labelAndType = tupleComponent?.split(withStringSeparator: ": "),
				let label = labelAndType[safe: 0],
				let type = labelAndType[safe: 1],
				case let .declarationReferenceExpression(data: leftExpression) = leftHand
			{
				return .dotExpression(
					leftExpression: leftHand,
					rightExpression: .declarationReferenceExpression(data:
						DeclarationReferenceData(
							identifier: label,
							type: type,
							isStandardLibrary: leftExpression.isStandardLibrary,
							isImplicit: false,
							range: leftExpression.range)))
			}
		}

		return try unexpectedExpressionStructureError(
			"Unable to get either the tuple element's number or its label.",
			AST: tupleElementExpression, translator: self)
	}

	internal func translate(prefixUnaryExpression: SwiftAST) throws -> Expression {
		guard prefixUnaryExpression.name == "Prefix Unary Expression" else {
			return try unexpectedExpressionStructureError(
				"Trying to translate \(prefixUnaryExpression.name) as 'Prefix Unary Expression'",
				AST: prefixUnaryExpression, translator: self)
		}

		if let rawType = prefixUnaryExpression["type"],
			let declaration = prefixUnaryExpression
			.subtree(named: "Dot Syntax Call Expression")?
			.subtree(named: "Declaration Reference Expression")?["decl"],
			let expression = prefixUnaryExpression.subtree(at: 1)
		{
			let type = cleanUpType(rawType)
			let expressionTranslation = try translate(expression: expression)
			let (operatorIdentifier, _) = getIdentifierFromDeclaration(declaration)

			return .prefixUnaryExpression(
				expression: expressionTranslation, operatorSymbol: operatorIdentifier, type: type)
		}
		else {
			return try unexpectedExpressionStructureError(
				"Expected Prefix Unary Expression to have a Dot Syntax Call Expression with a " +
				"Declaration Reference Expression, for the operator, and expected it to have " +
				"a second expression as the operand.",
				AST: prefixUnaryExpression, translator: self)
		}
	}

	internal func translate(postfixUnaryExpression: SwiftAST) throws -> Expression {
		guard postfixUnaryExpression.name == "Postfix Unary Expression" else {
			return try unexpectedExpressionStructureError(
				"Trying to translate \(postfixUnaryExpression.name) as 'Postfix Unary Expression'",
				AST: postfixUnaryExpression, translator: self)
		}

		if let rawType = postfixUnaryExpression["type"],
			let declaration = postfixUnaryExpression
				.subtree(named: "Dot Syntax Call Expression")?
				.subtree(named: "Declaration Reference Expression")?["decl"],
			let expression = postfixUnaryExpression.subtree(at: 1)
		{
			let type = cleanUpType(rawType)
			let expressionTranslation = try translate(expression: expression)
			let (operatorIdentifier, _) = getIdentifierFromDeclaration(declaration)

			return .postfixUnaryExpression(
				expression: expressionTranslation, operatorSymbol: operatorIdentifier, type: type)
		}
		else {
			return try unexpectedExpressionStructureError(
				"Expected Postfix Unary Expression to have a Dot Syntax Call Expression with a " +
				"Declaration Reference Expression, for the operator, and expected it to have " +
				"a second expression as the operand.",
				AST: postfixUnaryExpression, translator: self)
		}
	}

	internal func translate(binaryExpression: SwiftAST) throws -> Expression {
		guard binaryExpression.name == "Binary Expression" else {
			return try unexpectedExpressionStructureError(
				"Trying to translate \(binaryExpression.name) as 'Binary Expression'",
				AST: binaryExpression, translator: self)
		}

		let operatorIdentifier: String

		if let rawType = binaryExpression["type"],
			let declaration = binaryExpression
				.subtree(named: "Dot Syntax Call Expression")?
				.subtree(named: "Declaration Reference Expression")?["decl"] ??
					binaryExpression.subtree(named: "Declaration Reference Expression")?["decl"],
			let tupleExpression = binaryExpression.subtree(named: "Tuple Expression"),
			let leftHandExpression = tupleExpression.subtree(at: 0),
			let rightHandExpression = tupleExpression.subtree(at: 1)
		{
			let type = cleanUpType(rawType)
			(operatorIdentifier, _) = getIdentifierFromDeclaration(declaration)
			let leftHandTranslation = try translate(expression: leftHandExpression)
			let rightHandTranslation = try translate(expression: rightHandExpression)

			return .binaryOperatorExpression(
				leftExpression: leftHandTranslation,
				rightExpression: rightHandTranslation,
				operatorSymbol: operatorIdentifier,
				type: type)
		}
		else {
			return try unexpectedExpressionStructureError(
				"Unrecognized structure",
				AST: binaryExpression, translator: self)
		}
	}

	internal func translate(ifExpression: SwiftAST) throws -> Expression {
		guard ifExpression.name == "If Expression" else {
			return try unexpectedExpressionStructureError(
				"Trying to translate \(ifExpression.name) as 'If Expression'",
				AST: ifExpression, translator: self)
		}

		guard ifExpression.subtrees.count == 3 else {
			return try unexpectedExpressionStructureError(
				"Expected If Expression to have three subtrees (a condition, a true expression " +
					"and a false expression)",
				AST: ifExpression, translator: self)
		}

		let condition = try translate(expression: ifExpression.subtrees[0])
		let trueExpression = try translate(expression: ifExpression.subtrees[1])
		let falseExpression = try translate(expression: ifExpression.subtrees[2])

		return .ifExpression(
			condition: condition, trueExpression: trueExpression, falseExpression: falseExpression)
	}

	internal func translate(typeExpression: SwiftAST) throws -> Expression {
		guard typeExpression.name == "Type Expression" else {
			return try unexpectedExpressionStructureError(
				"Trying to translate \(typeExpression.name) as 'Type Expression'",
				AST: typeExpression, translator: self)
		}

		guard let type = typeExpression["typerepr"] else {
			return try unexpectedExpressionStructureError(
				"Unrecognized structure",
				AST: typeExpression, translator: self)
		}

		return .typeExpression(type: cleanUpType(type))
	}

	internal func translate(dotSyntaxCallExpression: SwiftAST) throws -> Expression {
		guard dotSyntaxCallExpression.name == "Dot Syntax Call Expression" else {
			return try unexpectedExpressionStructureError(
				"Trying to translate \(dotSyntaxCallExpression.name) as " +
				"'Dot Syntax Call Expression'",
				AST: dotSyntaxCallExpression, translator: self)
		}

		if let leftHandTree = dotSyntaxCallExpression.subtree(at: 1),
			let rightHandExpression = dotSyntaxCallExpression.subtree(at: 0)
		{
			let rightHand = try translate(expression: rightHandExpression)
			let leftHand = try translate(typeExpression: leftHandTree)

			// Swift 4.2
			if case .typeExpression(type: _) = leftHand,
				case let .declarationReferenceExpression(data: rightExpression) = rightHand,
				rightExpression.identifier == "none"
			{
				return .nilLiteralExpression
			}

			return .dotExpression(leftExpression: leftHand, rightExpression: rightHand)
		}
		else {
			return try unexpectedExpressionStructureError(
				"Unrecognized structure",
				AST: dotSyntaxCallExpression, translator: self)
		}
	}

	internal func translate(returnStatement: SwiftAST) throws -> Statement {
		guard returnStatement.name == "Return Statement" else {
			return try unexpectedASTStructureError(
				"Trying to translate \(returnStatement.name) as 'Return Statement'",
				AST: returnStatement, translator: self)
		}

		if let expression = returnStatement.subtrees.last {
			let expression = try translate(expression: expression)
			return .returnStatement(expression: expression)
		}
		else {
			return .returnStatement(expression: nil)
		}
	}

	internal func translate(forEachStatement: SwiftAST) throws -> Statement {
		guard forEachStatement.name == "For Each Statement" else {
			return try unexpectedASTStructureError(
				"Trying to translate \(forEachStatement.name) as 'For Each Statement'",
				AST: forEachStatement, translator: self)
		}

		let variableRange = getRangeRecursively(ofNode: forEachStatement.subtrees[0])

		let variable: Expression
		let collectionExpression: SwiftAST
		if let variableSubtree = forEachStatement.subtree(named: "Pattern Named"),
			let rawType = variableSubtree["type"],
			let maybeCollectionExpression = forEachStatement.subtree(at: 2),
			let variableName = variableSubtree.standaloneAttributes.first
		{
			variable = Expression.declarationReferenceExpression(data:
				DeclarationReferenceData(
					identifier: variableName,
					type: cleanUpType(rawType),
					isStandardLibrary: false,
					isImplicit: false,
					range: variableRange))
			collectionExpression = maybeCollectionExpression
		}
		else if let variableSubtree = forEachStatement.subtree(named: "Pattern Tuple"),
			let maybeCollectionExpression = forEachStatement.subtree(at: 2)
		{
			let variableNames = variableSubtree.subtrees.map { $0.standaloneAttributes[0] }
			let variableTypes = variableSubtree.subtrees.map { $0.keyValueAttributes["type"]! }

			let variables = zipToClass(variableNames, variableTypes).map {
				LabeledExpression(
					label: nil,
					expression: .declarationReferenceExpression(data:
						DeclarationReferenceData(
							identifier: $0.0,
							type: cleanUpType($0.1),
							isStandardLibrary: false,
							isImplicit: false,
							range: variableRange)))
			}

			variable = .tupleExpression(pairs: variables)
			collectionExpression = maybeCollectionExpression
		}
		else {
			return try unexpectedASTStructureError(
				"Unable to detect variable or collection",
				AST: forEachStatement, translator: self)
		}

		guard let braceStatement = forEachStatement.subtrees.last,
			braceStatement.name == "Brace Statement" else
		{
			return try unexpectedASTStructureError(
				"Unable to detect body of statements",
				AST: forEachStatement, translator: self)
		}

		let collectionTranslation = try translate(expression: collectionExpression)
		let statements = try translate(braceStatement: braceStatement)

		return .forEachStatement(
			collection: collectionTranslation,
			variable: variable,
			statements: ArrayClass(statements))
	}

	internal func translate(whileStatement: SwiftAST) throws -> Statement {
		guard whileStatement.name == "While Statement" else {
			return try unexpectedASTStructureError(
				"Trying to translate \(whileStatement.name) as 'While Statement'",
				AST: whileStatement, translator: self)
		}

		guard let expressionSubtree = whileStatement.subtrees.first else {
			return try unexpectedASTStructureError(
				"Unable to detect expression",
				AST: whileStatement, translator: self)
		}

		guard let braceStatement = whileStatement.subtrees.last,
			braceStatement.name == "Brace Statement" else
		{
			return try unexpectedASTStructureError(
				"Unable to detect body of statements",
				AST: whileStatement, translator: self)
		}

		let expression = try translate(expression: expressionSubtree)
		let statements = try translate(braceStatement: braceStatement)

		return .whileStatement(expression: expression, statements: ArrayClass(statements))
	}

	internal func translate(deferStatement: SwiftAST) throws -> Statement {
		guard deferStatement.name == "Defer Statement" else {
			return try unexpectedASTStructureError(
				"Trying to translate \(deferStatement.name) as a 'Defer Statement'",
				AST: deferStatement, translator: self)
		}

		guard let functionDeclaration = deferStatement.subtree(named: "Function Declaration"),
			let braceStatement = functionDeclaration.subtree(named: "Brace Statement") else
		{
			return try unexpectedASTStructureError(
				"Expected defer statement to have a function declaration with a brace statement " +
					"containing the deferred statements.",
				AST: deferStatement, translator: self)
		}

		let statements = try translate(braceStatement: braceStatement)
		return .deferStatement(statements: ArrayClass(statements))
	}

	internal func translate(ifStatement: SwiftAST) throws -> Statement {
		do {
			let result: IfStatementData = try translate(ifStatement: ifStatement)
			return .ifStatement(data: result)
		}
		catch let error {
			return try handleUnexpectedASTStructureError(error)
		}
	}

	internal func translate(ifStatement: SwiftAST) throws -> IfStatementData {
		guard ifStatement.name == "If Statement" || ifStatement.name == "Guard Statement" else {
			throw createUnexpectedASTStructureError(
				"Trying to translate \(ifStatement.name) as an if or guard statement",
				AST: ifStatement, translator: self)
		}

		let isGuard = (ifStatement.name == "Guard Statement")

		let (conditions, extraStatements) = try translateIfConditions(forIfStatement: ifStatement)

		let braceStatement: SwiftAST
		let elseStatement: IfStatementData?

		if ifStatement.subtrees.count > 2,
			let unwrappedBraceStatement = ifStatement.subtrees.secondToLast,
			unwrappedBraceStatement.name == "Brace Statement",
			let elseIfAST = ifStatement.subtrees.last,
			elseIfAST.name == "If Statement"
		{
			braceStatement = unwrappedBraceStatement
			elseStatement = try translate(ifStatement: elseIfAST)
		}
		else if ifStatement.subtrees.count > 2,
			let unwrappedBraceStatement = ifStatement.subtrees.secondToLast,
			unwrappedBraceStatement.name == "Brace Statement",
			let elseAST = ifStatement.subtrees.last,
			elseAST.name == "Brace Statement"
		{
			braceStatement = unwrappedBraceStatement
			let statements = try translate(braceStatement: elseAST)
			elseStatement = IfStatementData(
				conditions: [], declarations: [],
				statements: ArrayClass(statements),
				elseStatement: nil,
				isGuard: false)
		}
		else if let unwrappedBraceStatement = ifStatement.subtrees.last,
			unwrappedBraceStatement.name == "Brace Statement"
		{
			braceStatement = unwrappedBraceStatement
			elseStatement = nil
		}
		else {
			throw createUnexpectedASTStructureError(
				"Unable to detect body of statements",
				AST: ifStatement, translator: self)
		}

		let statements = try translate(braceStatement: braceStatement)

		return IfStatementData(
			conditions: ArrayClass(conditions),
			declarations: [],
			statements: extraStatements + ArrayClass(statements),
			elseStatement: elseStatement,
			isGuard: isGuard)
	}

	internal func translate(switchStatement: SwiftAST) throws -> Statement {
		guard switchStatement.name == "Switch Statement" else {
			return try unexpectedASTStructureError(
				"Trying to translate \(switchStatement.name) as 'Switch Statement'",
				AST: switchStatement, translator: self)
		}

		guard let expression = switchStatement.subtrees.first else {
			return try unexpectedASTStructureError(
				"Unable to detect primary expression for switch statement",
				AST: switchStatement, translator: self)
		}

		let translatedExpression = try translate(expression: expression)

		let cases: ArrayClass<SwitchCase> = []
		let caseSubtrees = switchStatement.subtrees.dropFirst()
		for caseSubtree in caseSubtrees {
			let caseExpression: Expression?
			var extraStatements: ArrayClass<Statement>

			if let caseLabelItem = caseSubtree.subtree(named: "Case Label Item") {
				if let patternLet = caseLabelItem.subtree(named: "Pattern Let"),
					let patternLetResult = try translate(enumPatternLet: patternLet)
				{
					let enumType = patternLetResult.enumType
					let enumCase = patternLetResult.enumCase
					let declarations = patternLetResult.declarations
					let enumClassName = enumType + "." + enumCase.capitalizedAsCamelCase

					caseExpression = .binaryOperatorExpression(
						leftExpression: translatedExpression,
						rightExpression: .typeExpression(type: enumClassName),
						operatorSymbol: "is",
						type: "Bool")

					let range = getRangeRecursively(ofNode: patternLet)

					extraStatements = ArrayClass(declarations).map {
						Statement.variableDeclaration(data: VariableDeclarationData(
							identifier: $0.newVariable,
							typeName: $0.associatedValueType,
							expression: .dotExpression(
								leftExpression: translatedExpression,
								rightExpression: .declarationReferenceExpression(data:
									DeclarationReferenceData(
										identifier: $0.associatedValueName,
										type: $0.associatedValueType,
										isStandardLibrary: false,
										isImplicit: false,
										range: range))),
							getter: nil,
							setter: nil,
							isLet: true,
							isImplicit: false,
							isStatic: false,
							extendsType: nil,
							annotations: nil))
					}
				}
				else if let expression = caseLabelItem.subtrees.first?.subtrees.first {
					let translateExpression = try translate(expression: expression)
					caseExpression = translateExpression
					extraStatements = []
				}
				else if let patternEnumElement =
					caseLabelItem.subtree(named: "Pattern Enum Element")
				{
					caseExpression = try translate(simplePatternEnumElement: patternEnumElement)
					extraStatements = []
				}
				else {
					caseExpression = nil
					extraStatements = []
				}
			}
			else {
				caseExpression = nil
				extraStatements = []
			}

			guard let braceStatement = caseSubtree.subtree(named: "Brace Statement") else {
				return try unexpectedASTStructureError(
					"Unable to find a case's statements",
					AST: switchStatement, translator: self)
			}

			let translatedStatements = try translate(braceStatement: braceStatement)

			cases.append(SwitchCase(
				expression: caseExpression, statements: extraStatements + translatedStatements))
		}

		return .switchStatement(
			convertsToExpression: nil,
			expression: translatedExpression,
			cases: cases)
	}

	internal func translate(simplePatternEnumElement: SwiftAST) throws -> Expression {
		guard simplePatternEnumElement.name == "Pattern Enum Element" else {
			return try unexpectedExpressionStructureError(
				"Trying to translate \(simplePatternEnumElement.name) as 'Pattern Enum Element'",
				AST: simplePatternEnumElement, translator: self)
		}

		guard let enumReference = simplePatternEnumElement.standaloneAttributes.first,
			let type = simplePatternEnumElement["type"] else
		{
			return try unexpectedExpressionStructureError(
				"Expected a Pattern Enum Element to have a reference to the enum case and a type.",
				AST: simplePatternEnumElement, translator: self)
		}

		var enumElements = enumReference.split(separator: ".")

		guard let lastEnumElement = enumElements.last else {
			return try unexpectedExpressionStructureError(
				"Expected a Pattern Enum Element to have a period (i.e. `MyEnum.myEnumCase`)",
				AST: simplePatternEnumElement, translator: self)
		}

		let range = getRangeRecursively(ofNode: simplePatternEnumElement)
		let lastExpression = Expression.declarationReferenceExpression(data:
			DeclarationReferenceData(
				identifier: String(lastEnumElement),
				type: type,
				isStandardLibrary: false,
				isImplicit: false,
				range: range))

		enumElements.removeLast()
		if !enumElements.isEmpty {
			return .dotExpression(
				leftExpression: .typeExpression(type:
					enumElements.joined(separator: ".")),
				rightExpression: lastExpression)
		}
		else {
			return lastExpression
		}
	}

	internal func translateIfConditions(
		forIfStatement ifStatement: SwiftAST) throws
		-> (conditions: [IfStatementData.IfCondition], statements: [Statement])
	{
		guard ifStatement.name == "If Statement" || ifStatement.name == "Guard Statement" else {
			return try (
				conditions: [],
				statements: [unexpectedASTStructureError(
					"Trying to translate \(ifStatement.name) as an if or guard statement",
					AST: ifStatement, translator: self), ])
		}

		var conditionsResult = [IfStatementData.IfCondition]()
		var statementsResult = [Statement]()

		let conditions = ifStatement.subtrees.filter {
			$0.name != "If Statement" && $0.name != "Brace Statement"
		}

		for condition in conditions {
			// If it's an `if let`
			if condition.name == "Pattern",
				let optionalSomeElement =
					condition.subtree(named: "Optional Some Element") ?? // Swift 4.1
					condition.subtree(named: "Pattern Optional Some") // Swift 4.2
			{
				let patternNamed: SwiftAST
				let isLet: Bool
				if let patternLet = optionalSomeElement.subtree(named: "Pattern Let"),
					let unwrapped = patternLet.subtree(named: "Pattern Named")
				{
					patternNamed = unwrapped
					isLet = true
				}
				else if let unwrapped = optionalSomeElement
					.subtree(named: "Pattern Variable")?
					.subtree(named: "Pattern Named")
				{
					patternNamed = unwrapped
					isLet = false
				}
				else {
					return try (
						conditions: [],
						statements: [unexpectedASTStructureError(
							"Unable to detect pattern in let declaration",
							AST: ifStatement, translator: self), ])
				}

				guard let rawType = optionalSomeElement["type"] else {
					return try (
						conditions: [],
						statements: [unexpectedASTStructureError(
							"Unable to detect type in let declaration",
							AST: ifStatement, translator: self), ])
				}

				let type = cleanUpType(rawType)

				guard let name = patternNamed.standaloneAttributes.first,
					let lastCondition = condition.subtrees.last else
				{
					return try (
						conditions: [],
						statements: [unexpectedASTStructureError(
							"Unable to get expression in let declaration",
							AST: ifStatement, translator: self), ])
				}

				let expression = try translate(expression: lastCondition)

				conditionsResult.append(.declaration(variableDeclaration: VariableDeclarationData(
					identifier: name,
					typeName: type,
					expression: expression,
					getter: nil, setter: nil,
					isLet: isLet,
					isImplicit: false,
					isStatic: false,
					extendsType: nil,
					annotations: nil)))
			}
			// If it's an `if case let`
			else if condition.name == "Pattern",
				let patternLet = condition.subtree(named: "Pattern Let"),
				condition.subtrees.count >= 2,
				let declarationReferenceAST = condition.subtrees.last
			{
				// TODO: test
				guard let patternLetResult = try translate(enumPatternLet: patternLet) else {
					return try (
						conditions: [],
						statements: [unexpectedASTStructureError(
							"Unable to translate Pattern Let",
							AST: ifStatement, translator: self), ])
				}

				let enumType = patternLetResult.enumType
				let enumCase = patternLetResult.enumCase
				let declarations = patternLetResult.declarations
				let enumClassName = enumType + "." + enumCase.capitalizedAsCamelCase

				let declarationReference = try translate(expression: declarationReferenceAST)

				conditionsResult.append(.condition(expression: .binaryOperatorExpression(
					leftExpression: declarationReference,
					rightExpression: .typeExpression(type: enumClassName),
					operatorSymbol: "is",
					type: "Bool")))

				for declaration in declarations {
					let range = getRangeRecursively(ofNode: patternLet)

					statementsResult.append(.variableDeclaration(data: VariableDeclarationData(
						identifier: declaration.newVariable,
						typeName: declaration.associatedValueType,
						expression: .dotExpression(
							leftExpression: declarationReference,
							rightExpression: .declarationReferenceExpression(data:
								DeclarationReferenceData(
									identifier: String(declaration.associatedValueName),
									type: declaration.associatedValueType,
									isStandardLibrary: false,
									isImplicit: false,
									range: range))),
						getter: nil,
						setter: nil,
						isLet: true,
						isImplicit: false,
						isStatic: false,
						extendsType: nil,
						annotations: nil)))
				}
			}
			else {
				conditionsResult.append(.condition(expression:
					try translate(expression: condition)))
			}
		}

		return (conditions: conditionsResult, statements: statementsResult)
	}

	private func translate(enumPatternLet: SwiftAST) throws
		-> (enumType: String,
		enumCase: String,
		declarations: [(
			associatedValueName: String,
			associatedValueType: String,
			newVariable: String)])?
	{
		guard enumPatternLet.name == "Pattern Let",
			let enumType = enumPatternLet["type"],
			let patternEnumElement = enumPatternLet.subtree(named: "Pattern Enum Element"),
			let patternTuple = patternEnumElement.subtree(named: "Pattern Tuple"),
			let associatedValueTuple = patternTuple["type"] else
		{
			return nil
		}

		// Process a string like `(label1: Type1, label2: Type2)` to get the labels
		let valuesTupleWithoutParentheses = String(associatedValueTuple.dropFirst().dropLast())
		let valueTuplesComponents = valuesTupleWithoutParentheses.split(withStringSeparator: ", ")
		let associatedValueNames =
			valueTuplesComponents.map { $0.split(withStringSeparator: ": ")[0] }

		var declarations =
			[(associatedValueName: String, associatedValueType: String, newVariable: String)]()

		let caseName =
			String(patternEnumElement.standaloneAttributes[0].split(separator: ".").last!)

		let patternsNamed = patternTuple.subtrees.filter { $0.name == "Pattern Named" }
		guard associatedValueNames.count == patternsNamed.count else {
			return nil
		}

		for (associatedValueName, patternNamed)
			in zip(associatedValueNames, patternsNamed)
		{
			guard let associatedValueType = patternNamed["type"] else {
				return nil
			}

			declarations.append((
				associatedValueName: String(associatedValueName),
				associatedValueType: associatedValueType,
				newVariable: patternNamed.standaloneAttributes[0]))
		}

		return (enumType: enumType, enumCase: caseName, declarations: declarations)
	}

	internal func translate(functionDeclaration: SwiftAST) throws -> Statement? {
		let compatibleASTNodes =
			["Function Declaration", "Constructor Declaration", "Accessor Declaration"]
		guard compatibleASTNodes.contains(functionDeclaration.name) else {
			return try unexpectedASTStructureError(
				"Trying to translate \(functionDeclaration.name) as 'Function Declaration'",
				AST: functionDeclaration, translator: self)
		}

		// Subscripts get translated as `get(i)` or `set(i, a)` functions
		let isSubscript = (functionDeclaration.name == "Accessor Declaration")

		// Getters and setters will appear again in the Variable Declaration AST and get translated
		let isGetterOrSetter =
			(functionDeclaration["getter_for"] != nil) || (functionDeclaration["setter_for"] != nil)
		let isImplicit = functionDeclaration.standaloneAttributes.contains("implicit")
		guard !isImplicit && !isGetterOrSetter else {
			return nil
		}

		// TODO: test subscripts
		let functionName: String
		if isSubscript {
			if functionDeclaration["get_for"] != nil {
				functionName = "get"
			}
			else if functionDeclaration["set_for"] != nil {
				functionName = "set"
			}
			else {
				return try unexpectedASTStructureError(
					"Trying to translate subscript declaration that isn't getter or setter",
					AST: functionDeclaration, translator: self)
			}
		}
		else {
			functionName = functionDeclaration.standaloneAttributes.first ?? ""
		}

		let access = functionDeclaration["access"]

		// Find out if it's static and if it's mutating
		guard let interfaceType = functionDeclaration["interface type"],
			let interfaceTypeComponents = functionDeclaration["interface type"]?
				.split(withStringSeparator: " -> "),
			let firstInterfaceTypeComponent = interfaceTypeComponents.first else
		{
			return try unexpectedASTStructureError(
				"Unable to find out if function is static",
				AST: functionDeclaration,
				translator: self)
		}
		let isStatic = firstInterfaceTypeComponent.contains(".Type")
		let isMutating = firstInterfaceTypeComponent.contains("inout")

		let genericTypes = ArrayClass(functionDeclaration.standaloneAttributes
			.first { $0.hasPrefix("<") }?
			.dropLast().dropFirst()
			.split(separator: ",")
			.map(String.init)
			?? [])

		let functionNamePrefix = functionName.prefix { $0 != "(" }

		// Get the function parameters.
		let parameterList: SwiftAST?

		// If it's a method, it includes an extra Parameter List with only `self`
		if let list = functionDeclaration.subtree(named: "Parameter List"),
			let name = list.subtree(at: 0, named: "Parameter")?.standaloneAttributes.first,
			name != "self"
		{
			parameterList = list
		}
		else if let unwrapped = functionDeclaration.subtree(at: 1, named: "Parameter List") {
			parameterList = unwrapped
		}
		else {
			parameterList = nil
		}

		// Translate the parameters
		var parameters: ArrayClass<FunctionParameter> = []
		if let parameterList = parameterList {
			for parameter in parameterList.subtrees {
				if let name = parameter.standaloneAttributes.first,
					let type = parameter["interface type"]
				{
					guard name != "self" else {
						continue
					}

					let parameterName = name
					let parameterApiLabel = parameter["apiName"]
					let parameterType = cleanUpType(type)

					let defaultValue: Expression?
					if let defaultValueTree = parameter.subtrees.first {
						defaultValue = try translate(expression: defaultValueTree)
					}
					else {
						defaultValue = nil
					}

					parameters.append(FunctionParameter(
						label: parameterName,
						apiLabel: parameterApiLabel,
						type: parameterType,
						value: defaultValue))
				}
				else {
					return try unexpectedASTStructureError(
						"Unable to detect name or attribute for a parameter",
						AST: functionDeclaration, translator: self)
				}
			}
		}

		// Subscript setters in Kotlin must be (index, newValue) instead of Swift's
		// (newValue, index)
		if isSubscript {
			parameters.reverse()
		}

		// Translate the return type
		// FIXME: Doesn't allow to return function types
		guard let returnType = interfaceTypeComponents.last else
		{
			return try unexpectedASTStructureError(
				"Unable to get return type", AST: functionDeclaration, translator: self)
		}

		// Translate the function body
		let statements: ArrayClass<Statement>
		if let braceStatement = functionDeclaration.subtree(named: "Brace Statement") {
			statements = try ArrayClass(translate(braceStatement: braceStatement))
		}
		else {
			statements = []
		}

		// TODO: test annotations in functions
		var annotations: [String?] = []
		annotations.append(getComment(forNode: functionDeclaration, key: "annotation"))
		if isSubscript {
			annotations.append("operator")
		}
		let joinedAnnotations = annotations.compactMap { $0 }.joined(separator: " ")
		let annotationsResult = joinedAnnotations.isEmpty ? nil : joinedAnnotations

		return .functionDeclaration(data: FunctionDeclarationData(
			prefix: String(functionNamePrefix),
			parameters: parameters,
			returnType: returnType,
			functionType: interfaceType,
			genericTypes: genericTypes,
			isImplicit: isImplicit,
			isStatic: isStatic,
			isMutating: isMutating,
			extendsType: nil,
			statements: statements,
			access: access,
			annotations: annotationsResult))
	}

	internal func translate(topLevelCode topLevelCodeDeclaration: SwiftAST) throws
		-> Statement?
	{
		guard topLevelCodeDeclaration.name == "Top Level Code Declaration" else {
			return try unexpectedASTStructureError(
				"Trying to translate \(topLevelCodeDeclaration.name) as " +
				"'Top Level Code Declaration'",
				AST: topLevelCodeDeclaration, translator: self)
		}

		guard let braceStatement = topLevelCodeDeclaration.subtree(named: "Brace Statement") else {
			return try unexpectedASTStructureError(
				"Unrecognized structure", AST: topLevelCodeDeclaration, translator: self)
		}

		let subtrees = try translate(braceStatement: braceStatement)

		return subtrees.first
	}

	internal func translate(variableDeclaration: SwiftAST) throws -> Statement {
		guard variableDeclaration.name == "Variable Declaration" else {
			return try unexpectedASTStructureError(
				"Trying to translate \(variableDeclaration.name) as 'Variable Declaration'",
				AST: variableDeclaration, translator: self)
		}

		let isImplicit = variableDeclaration.standaloneAttributes.contains("implicit")

		let annotations = getComment(forNode: variableDeclaration, key: "annotation")

		let isStatic: Bool
		if let accessorDeclaration = variableDeclaration.subtree(named: "Accessor Declaration"),
			let interfaceType = accessorDeclaration["interface type"],
			let firstTypeComponent = interfaceType.split(withStringSeparator: " -> ").first,
			firstTypeComponent.contains(".Type")
		{
			isStatic = true
		}
		else {
			isStatic = false
		}

		guard let identifier =
				variableDeclaration.standaloneAttributes.first(where: { $0 != "implicit" }),
			let rawType = variableDeclaration["interface type"] else
		{
			return try unexpectedASTStructureError(
				"Failed to get identifier and type", AST: variableDeclaration, translator: self)
		}

		let isLet = variableDeclaration.standaloneAttributes.contains("let")
		let type = cleanUpType(rawType)

		var expression: Expression?
		if let firstBindingExpression = danglingPatternBindings.first {
			if let maybeBindingExpression = firstBindingExpression,
				let bindingExpression = maybeBindingExpression,
				(bindingExpression.identifier == identifier &&
						bindingExpression.type == type) ||
					(bindingExpression.identifier == "<<Error>>")
			{
				expression = bindingExpression.expression
			}

			_ = danglingPatternBindings.removeFirst()
		}

		if expression == nil,
			let valueReplacement = getComment(forNode: variableDeclaration, key: "value")
		{
			expression = .literalCodeExpression(string: valueReplacement)
		}

		var getter: FunctionDeclarationData?
		var setter: FunctionDeclarationData?
		for subtree in variableDeclaration.subtrees {
			let access = subtree["access"]

			let statements: ArrayClass<Statement>
			if let braceStatement = subtree.subtree(named: "Brace Statement") {
				statements = try ArrayClass(translate(braceStatement: braceStatement))
			}
			else {
				statements = []
			}

			let isImplicit = subtree.standaloneAttributes.contains("implicit")
			let annotations = getComment(forNode: subtree, key: "annotation")

			if subtree["get_for"] != nil {
				getter = FunctionDeclarationData(
					prefix: "get",
					parameters: [],
					returnType: type,
					functionType: "() -> (\(type))",
					genericTypes: [],
					isImplicit: isImplicit,
					isStatic: false,
					isMutating: false,
					extendsType: nil,
					statements: statements,
					access: access,
					annotations: annotations)
			}
			else if subtree["materializeForSet_for"] != nil || subtree["set_for"] != nil {
				setter = FunctionDeclarationData(
					prefix: "set",
					parameters: [FunctionParameter(
						label: "newValue", apiLabel: nil, type: type, value: nil), ],
					returnType: "()",
					functionType: "(\(type)) -> ()",
					genericTypes: [],
					isImplicit: isImplicit,
					isStatic: false,
					isMutating: false,
					extendsType: nil,
					statements: statements,
					access: access,
					annotations: annotations)
			}
		}

		return .variableDeclaration(data: VariableDeclarationData(
			identifier: identifier,
			typeName: type,
			expression: expression,
			getter: getter,
			setter: setter,
			isLet: isLet,
			isImplicit: isImplicit,
			isStatic: isStatic,
			extendsType: nil,
			annotations: annotations))
	}

	internal func translate(callExpression: SwiftAST) throws -> Expression {
		guard callExpression.name == "Call Expression" else {
			return try unexpectedExpressionStructureError(
				"Trying to translate \(callExpression.name) as 'Call Expression'",
				AST: callExpression, translator: self)
		}

		// If the call expression corresponds to an integer literal
		if let argumentLabels = callExpression["arg_labels"] {
			if argumentLabels == "_builtinIntegerLiteral:" ||
				argumentLabels == "_builtinFloatLiteral:"
			{
				return try translate(asNumericLiteral: callExpression)
			}
			else if argumentLabels == "_builtinBooleanLiteral:" {
				return try translate(asBooleanLiteral: callExpression)
			}
			else if argumentLabels == "nilLiteral:" {
				return .nilLiteralExpression
			}
		}

		let function: Expression

		// If it's an empty expression used in an "if" condition
		if callExpression.standaloneAttributes.contains("implicit"),
			callExpression["arg_labels"] == "",
			callExpression["type"] == "Int1",
			let containedExpression = callExpression
				.subtree(named: "Dot Syntax Call Expression")?
				.subtrees.last
		{
			return try translate(expression: containedExpression)
		}

		guard let rawType = callExpression["type"] else {
			return try unexpectedExpressionStructureError(
				"Failed to recognize type", AST: callExpression, translator: self)
		}
		let type = cleanUpType(rawType)

		if let declarationReferenceExpression = callExpression
			.subtree(named: "Declaration Reference Expression")
		{
			function = try translate(
				declarationReferenceExpression: declarationReferenceExpression)
		}
		else if let dotSyntaxCallExpression = callExpression
				.subtree(named: "Dot Syntax Call Expression"),
			let methodName = dotSyntaxCallExpression
				.subtree(at: 0, named: "Declaration Reference Expression"),
			let methodOwner = dotSyntaxCallExpression.subtree(at: 1)
		{
			let methodName = try translate(declarationReferenceExpression: methodName)
			let methodOwner = try translate(expression: methodOwner)
			function = .dotExpression(leftExpression: methodOwner, rightExpression: methodName)
		}
		else if let typeExpression = callExpression
			.subtree(named: "Constructor Reference Call Expression")?
			.subtree(named: "Type Expression")
		{
			function = try translate(typeExpression: typeExpression)
		}
		else {
			function = try translate(expression: callExpression.subtrees[0])
		}

		let parameters = try translate(callExpressionParameters: callExpression)

		let range = getRange(ofNode: callExpression)

		return .callExpression(data: CallExpressionData(
			function: function,
			parameters: parameters,
			type: type,
			range: range))
	}

	internal func translate(closureExpression: SwiftAST) throws -> Expression {
		guard closureExpression.name == "Closure Expression" else {
			return try unexpectedExpressionStructureError(
				"Trying to translate \(closureExpression.name) as 'Closure Expression'",
				AST: closureExpression, translator: self)
		}

		// Get the parameters.
		let parameterList: SwiftAST?

		if let unwrapped = closureExpression.subtree(named: "Parameter List") {
			parameterList = unwrapped
		}
		else {
			parameterList = nil
		}

		// Translate the parameters
		let parameters: ArrayClass<LabeledType> = []
		if let parameterList = parameterList {
			for parameter in parameterList.subtrees {
				if let name = parameter.standaloneAttributes.first,
					let type = parameter["interface type"]
				{
					if name.hasPrefix("anonname=0x") {
						continue
					}
					parameters.append(LabeledType(label: name, type: cleanUpType(type)))
				}
				else {
					return try unexpectedExpressionStructureError(
						"Unable to detect name or attribute for a parameter",
						AST: closureExpression, translator: self)
				}
			}
		}

		// Translate the return type
		// FIXME: Doesn't allow to return function types
		guard let type = closureExpression["type"] else
		{
			return try unexpectedExpressionStructureError(
				"Unable to get type or return type", AST: closureExpression, translator: self)
		}

		// Translate the closure body
		guard let lastSubtree = closureExpression.subtrees.last else {
			return try unexpectedExpressionStructureError(
				"Unable to get closure body", AST: closureExpression, translator: self)
		}

		let statements: [Statement]
		if lastSubtree.name == "Brace Statement" {
			statements = try translate(braceStatement: lastSubtree)
		}
		else {
			let expression = try translate(expression: lastSubtree)
			statements = [Statement.expression(expression: expression)]
		}

		return .closureExpression(
			parameters: parameters,
			statements: ArrayClass<Statement>(statements),
			type: cleanUpType(type))
	}

	internal func translate(callExpressionParameters callExpression: SwiftAST) throws
		-> Expression
	{
		guard callExpression.name == "Call Expression" else {
			return try unexpectedExpressionStructureError(
				"Trying to translate \(callExpression.name) as 'Call Expression'",
				AST: callExpression, translator: self)
		}

		let parameters: Expression
		if let parenthesesExpression = callExpression.subtree(named: "Parentheses Expression") {
			let expression = try translate(expression: parenthesesExpression)
			parameters = .tupleExpression(
				pairs: [LabeledExpression(label: nil, expression: expression)])
		}
		else if let tupleExpression = callExpression.subtree(named: "Tuple Expression") {
			parameters = try translate(tupleExpression: tupleExpression)
		}
		else if let tupleShuffleExpression = callExpression
			.subtree(named: "Tuple Shuffle Expression")
		{
			if let parenthesesExpression = tupleShuffleExpression
				.subtree(named: "Parentheses Expression")
			{
				let expression = try translate(expression: parenthesesExpression)
				parameters = .tupleExpression(
					pairs: [LabeledExpression(label: nil, expression: expression)])
			}
			else if let tupleExpression = tupleShuffleExpression.subtree(named: "Tuple Expression"),
				let type = tupleShuffleExpression["type"],
				let elements = tupleShuffleExpression["elements"],
				let rawIndices = elements.split(withStringSeparator: ", ").map(Int.init) as? [Int]
			{
				let indices: ArrayClass<TupleShuffleIndex> = []
				for rawIndex in rawIndices {
					if rawIndex == -2 {
						guard let variadicCount = tupleShuffleExpression["variadic_sources"]?
							.split(withStringSeparator: ", ").count else
						{
							return try unexpectedExpressionStructureError(
								"Failed to read variadic sources",
								AST: callExpression,
								translator: self)
						}
						indices.append(.variadic(count: variadicCount))
					}
					else if rawIndex == -1 {
						indices.append(.absent)
					}
					else if rawIndex >= 0 {
						indices.append(.present)
					}
					else {
						return try unexpectedExpressionStructureError(
							"Unknown tuple shuffle index: \(rawIndex)",
							AST: callExpression,
							translator: self)
					}
				}

				let tupleComponents = ArrayClass(
					String(type.dropFirst().dropLast())
						.split(withStringSeparator: ", "))
				let labels = tupleComponents
					.map { $0.prefix(while: { $0 != ":" }) }
					.map(String.init)
				let expressions = try tupleExpression.subtrees.map(translate(expression:))
				parameters = .tupleShuffleExpression(
					labels: labels,
					indices: indices,
					expressions: expressions)
			}
			else {
				return try unexpectedExpressionStructureError(
					"Unrecognized structure in parameters", AST: callExpression, translator: self)
			}
		}
		else {
			return try unexpectedExpressionStructureError(
				"Unrecognized structure in parameters", AST: callExpression, translator: self)
		}

		return parameters
	}

	internal func translate(tupleExpression: SwiftAST) throws -> Expression {
		guard tupleExpression.name == "Tuple Expression" else {
			return try unexpectedExpressionStructureError(
				"Trying to translate \(tupleExpression.name) as 'Tuple Expression'",
				AST: tupleExpression, translator: self)
		}

		// Only empty tuples don't have a list of names
		guard let names = tupleExpression["names"] else {
			return .tupleExpression(pairs: [])
		}

		let namesArray = names.split(separator: ",")

		let tuplePairs: ArrayClass<LabeledExpression> = []

		for (name, expression) in zip(namesArray, tupleExpression.subtrees) {
			let expression = try translate(expression: expression)

			// Empty names (like the underscore in "foo(_:)") are represented by ''
			if name == "_" {
				tuplePairs.append(LabeledExpression(label: nil, expression: expression))
			}
			else {
				tuplePairs.append(
					LabeledExpression(label: String(name), expression: expression))
			}
		}

		return .tupleExpression(pairs: tuplePairs)
	}

	internal func translate(asNumericLiteral callExpression: SwiftAST) throws -> Expression {
		guard callExpression.name == "Call Expression" else {
			return try unexpectedExpressionStructureError(
				"Trying to translate \(callExpression.name) as 'Call Expression'",
				AST: callExpression, translator: self)
		}

		// FIXME: Negative float literals are translated as positive becuase the AST dump doesn't
		// seemd to include any info showing they're negative.
		// Bug filed at https://bugs.swift.org/browse/SR-10131
		if let tupleExpression = callExpression.subtree(named: "Tuple Expression"),
			let literalExpression = tupleExpression.subtree(named: "Integer Literal Expression") ??
				tupleExpression.subtree(named: "Float Literal Expression"),
			let value = literalExpression["value"],

			let constructorReferenceCallExpression = callExpression
				.subtree(named: "Constructor Reference Call Expression"),
			let typeExpression = constructorReferenceCallExpression
				.subtree(named: "Type Expression"),
			let rawType = typeExpression["typerepr"]
		{
			if value.hasPrefix("0b") || value.hasPrefix("0o") || value.hasPrefix("0x") {
				// Fixable
				return try unexpectedExpressionStructureError(
					"No support yet for alternative integer formats",
					AST: callExpression,
					translator: self)
			}

			let signedValue: String
			if literalExpression.standaloneAttributes.contains("negative") {
				signedValue = "-" + value
			}
			else {
				signedValue = value
			}

			let type = cleanUpType(rawType)
			if type == "Double" || type == "Float64" {
				return .literalDoubleExpression(value: Double(signedValue)!)
			}
			else if type == "Float" || type == "Float32" {
				return .literalFloatExpression(value: Float(signedValue)!)
			}
			else if type == "Float80" {
				return try unexpectedExpressionStructureError(
					"No support for 80-bit Floats", AST: callExpression, translator: self)
			}
			else if type.hasPrefix("U") {
				return .literalUIntExpression(value: UInt64(signedValue)!)
			}
			else {
				if signedValue == "-9223372036854775808" {
					return try unexpectedExpressionStructureError(
						"Kotlin's Long (equivalent to Int64) only goes down to " +
							"-9223372036854775807", AST: callExpression, translator: self)
				}
				else {
					return .literalIntExpression(value: Int64(signedValue)!)
				}
			}
		}
		else {
			return try unexpectedExpressionStructureError(
				"Unrecognized structure for numeric literal", AST: callExpression, translator: self)
		}
	}

	internal func translate(asBooleanLiteral callExpression: SwiftAST) throws
		-> Expression
	{
		guard callExpression.name == "Call Expression" else {
			return try unexpectedExpressionStructureError(
				"Trying to translate \(callExpression.name) as 'Call Expression'",
				AST: callExpression, translator: self)
		}

		if let tupleExpression = callExpression.subtree(named: "Tuple Expression"),
			let booleanLiteralExpression = tupleExpression
				.subtree(named: "Boolean Literal Expression"),
			let value = booleanLiteralExpression["value"]
		{
			return .literalBoolExpression(value: (value == "true"))
		}
		else {
			return try unexpectedExpressionStructureError(
				"Unrecognized structure for boolean literal", AST: callExpression, translator: self)
		}
	}

	internal func translate(stringLiteralExpression: SwiftAST) throws -> Expression {
		guard stringLiteralExpression.name == "String Literal Expression" else {
			return try unexpectedExpressionStructureError(
				"Trying to translate \(stringLiteralExpression.name) as " +
				"'String Literal Expression'",
				AST: stringLiteralExpression, translator: self)
		}

		if let value = stringLiteralExpression["value"] {
			if stringLiteralExpression["type"] == "Character" {
				if value == "\'" {
					return .literalCharacterExpression(value: "\\\'")
				}
				else {
					return .literalCharacterExpression(value: value)
				}
			}
			else {
				return .literalStringExpression(value: value)
			}
		}
		else {
			return try unexpectedExpressionStructureError(
				"Unrecognized structure", AST: stringLiteralExpression, translator: self)
		}
	}

	internal func translate(interpolatedStringLiteralExpression: SwiftAST) throws
		-> Expression
	{
		guard interpolatedStringLiteralExpression.name == "Interpolated String Literal Expression"
			else
		{
			return try unexpectedExpressionStructureError(
				"Trying to translate \(interpolatedStringLiteralExpression.name) as " +
				"'Interpolated String Literal Expression'",
				AST: interpolatedStringLiteralExpression, translator: self)
		}

		guard let tapExpression =
			interpolatedStringLiteralExpression.subtree(named: "Tap Expression"),
			let braceStatement = tapExpression.subtree(named: "Brace Statement") else
		{
			return try unexpectedExpressionStructureError(
				"Expected the Interpolated String Literal Expression to contain a Tap" +
					"Expression containing a Brace Statement containing the String " +
				"interpolation contents",
				AST: interpolatedStringLiteralExpression, translator: self)
		}

		let expressions: ArrayClass<Expression> = []

		for callExpression in braceStatement.subtrees.dropFirst() {
			guard callExpression.name == "Call Expression",
				let parenthesesExpression = callExpression.subtree(named: "Parentheses Expression"),
				let expression = parenthesesExpression.subtrees.first else
			{
				return try unexpectedExpressionStructureError(
					"Expected the brace statement to contain only Call Expressions containing " +
					"Parentheses Expressions containing the relevant expressions.",
					AST: interpolatedStringLiteralExpression, translator: self)
			}

			let translatedExpression = try translate(expression: expression)
			expressions.append(translatedExpression)
		}

		return .interpolatedStringLiteralExpression(expressions: expressions)
	}

	internal func translate(declarationReferenceExpression: SwiftAST) throws
		-> Expression
	{
		guard declarationReferenceExpression.name == "Declaration Reference Expression" else {
			return try unexpectedExpressionStructureError(
				"Trying to translate \(declarationReferenceExpression.name) as " +
				"'Declaration Reference Expression'",
				AST: declarationReferenceExpression, translator: self)
		}

		guard let rawType = declarationReferenceExpression["type"] else {
			return try unexpectedExpressionStructureError(
				"Failed to recognize type", AST: declarationReferenceExpression, translator: self)
		}
		let type = cleanUpType(rawType)

		let isImplicit = declarationReferenceExpression.standaloneAttributes.contains("implicit")

		let range = getRange(ofNode: declarationReferenceExpression)

		if let discriminator = declarationReferenceExpression["discriminator"] {
			let (identifier, isStandardLibrary) = getIdentifierFromDeclaration(discriminator)
			return .declarationReferenceExpression(data: DeclarationReferenceData(
					identifier: identifier,
					type: type,
					isStandardLibrary: isStandardLibrary,
					isImplicit: isImplicit,
					range: range))
		}
		else if let codeDeclaration = declarationReferenceExpression.standaloneAttributes.first,
			codeDeclaration.hasPrefix("code.")
		{
			let (identifier, isStandardLibrary) = getIdentifierFromDeclaration(codeDeclaration)
			return .declarationReferenceExpression(data: DeclarationReferenceData(
				identifier: identifier,
				type: type,
				isStandardLibrary: isStandardLibrary,
				isImplicit: isImplicit,
				range: range))
		}
		else if let declaration = declarationReferenceExpression["decl"] {
			let (identifier, isStandardLibrary) = getIdentifierFromDeclaration(declaration)
			return .declarationReferenceExpression(data: DeclarationReferenceData(
				identifier: identifier,
				type: type,
				isStandardLibrary: isStandardLibrary,
				isImplicit: isImplicit,
				range: range))
		}
		else {
			return try unexpectedExpressionStructureError(
				"Unrecognized structure", AST: declarationReferenceExpression, translator: self)
		}
	}

	internal func translate(subscriptExpression: SwiftAST) throws -> Expression {
		guard subscriptExpression.name == "Subscript Expression" else {
			return try unexpectedExpressionStructureError(
				"Trying to translate \(subscriptExpression.name) as 'Subscript Expression'",
				AST: subscriptExpression, translator: self)
		}

		if let rawType = subscriptExpression["type"],
			let subscriptContents = subscriptExpression.subtree(
					at: 1,
					named: "Parentheses Expression") ??
				subscriptExpression.subtree(
					at: 1, named: "Tuple Expression"),
			let subscriptedExpression = subscriptExpression.subtree(at: 0)
		{
			let type = cleanUpType(rawType)
			let subscriptContentsTranslation = try translate(expression: subscriptContents)
			let subscriptedExpressionTranslation = try translate(expression: subscriptedExpression)

			return .subscriptExpression(
				subscriptedExpression: subscriptedExpressionTranslation,
				indexExpression: subscriptContentsTranslation, type: type)
		}
		else {
			return try unexpectedExpressionStructureError(
				"Unrecognized structure", AST: subscriptExpression, translator: self)
		}
	}

	internal func translate(arrayExpression: SwiftAST) throws -> Expression {
		guard arrayExpression.name == "Array Expression" else {
			return try unexpectedExpressionStructureError(
				"Trying to translate \(arrayExpression.name) as 'Array Expression'",
				AST: arrayExpression, translator: self)
		}

		// Drop the "Semantic Expression" at the end
		let expressionsToTranslate = ArrayClass(arrayExpression.subtrees.dropLast())

		let expressionsArray = try expressionsToTranslate.map(translate(expression:))

		guard let rawType = arrayExpression["type"] else {
			return try unexpectedExpressionStructureError(
				"Failed to get type", AST: arrayExpression, translator: self)
		}
		let type = cleanUpType(rawType)

		return .arrayExpression(elements: expressionsArray, type: type)
	}

	internal func translate(dictionaryExpression: SwiftAST) throws -> Expression {
		guard dictionaryExpression.name == "Dictionary Expression" else {
			return try unexpectedExpressionStructureError(
				"Trying to translate \(dictionaryExpression.name) as 'Dictionary Expression'",
				AST: dictionaryExpression, translator: self)
		}

		let keys: ArrayClass<Expression> = []
		let values: ArrayClass<Expression> = []
		for tupleExpression in dictionaryExpression.subtrees {
			guard tupleExpression.name == "Tuple Expression" else {
				continue
			}
			guard let keyAST = tupleExpression.subtree(at: 0),
				let valueAST = tupleExpression.subtree(at: 1) else
			{
				return try unexpectedExpressionStructureError(
					"Unable to get either key or value for one of the tuple expressions",
					AST: dictionaryExpression, translator: self)
			}

			let keyTranslation = try translate(expression: keyAST)
			let valueTranslation = try translate(expression: valueAST)
			keys.append(keyTranslation)
			values.append(valueTranslation)
		}

		guard let type = dictionaryExpression["type"] else {
			return try unexpectedExpressionStructureError(
				"Unable to get type",
				AST: dictionaryExpression, translator: self)
		}

		return .dictionaryExpression(keys: keys, values: values, type: type)
	}

	// MARK: - Supporting methods
	internal func process(openExistentialExpression: SwiftAST) throws -> SwiftAST {
		guard openExistentialExpression.name == "Open Existential Expression" else {
			_ = try unexpectedExpressionStructureError(
				"Trying to translate \(openExistentialExpression.name) as " +
				"'Open Existential Expression'",
				AST: openExistentialExpression, translator: self)
			return SwiftAST("Error", [], [:], [])
		}

		guard let replacementSubtree = openExistentialExpression.subtree(at: 1),
			let resultSubtree = openExistentialExpression.subtrees.last else
		{
			_ = try unexpectedExpressionStructureError(
				"Expected the AST to contain 3 subtrees: an Opaque Value Expression, an " +
				"expression to replace the opaque value, and an expression containing " +
				"opaque values to be replaced.",
				AST: openExistentialExpression, translator: self)
			return SwiftAST("Error", [], [:], [])
		}

		return astReplacingOpaqueValues(in: resultSubtree, with: replacementSubtree)
	}

	internal func astReplacingOpaqueValues(in ast: SwiftAST, with replacementAST: SwiftAST)
		-> SwiftAST
	{
		if ast.name == "Opaque Value Expression" {
			return replacementAST
		}

		var newSubtrees = [SwiftAST]()
		for subtree in ast.subtrees {
			newSubtrees.append(astReplacingOpaqueValues(in: subtree, with: replacementAST))
		}

		return SwiftAST(
			ast.name,
			ast.standaloneAttributes,
			ast.keyValueAttributes,
			ArrayClass(newSubtrees))
	}

	internal func process(patternBindingDeclaration: SwiftAST) throws {
		guard patternBindingDeclaration.name == "Pattern Binding Declaration" else {
			_ = try unexpectedExpressionStructureError(
				"Trying to translate \(patternBindingDeclaration.name) as " +
				"'Pattern Binding Declaration'",
				AST: patternBindingDeclaration, translator: self)
			danglingPatternBindings = [errorDanglingPatternDeclaration]
			return
		}

		var result = [PatternBindingDeclaration]()

		let subtrees = patternBindingDeclaration.subtrees
		while !subtrees.isEmpty {
			var pattern = subtrees.removeFirst()
			if pattern.name == "Pattern Typed",
				let newPattern = pattern.subtree(named: "Pattern Named")
			{
				pattern = newPattern
			}

			if let expression = subtrees.first, ASTIsExpression(expression) {
				_ = subtrees.removeFirst()

				let translatedExpression = try translate(expression: expression)

				guard let identifier = pattern.standaloneAttributes.first,
					let rawType = pattern["type"] else
				{
					_ = try unexpectedExpressionStructureError(
						"Type not recognized", AST: patternBindingDeclaration, translator: self)
					result.append(errorDanglingPatternDeclaration)
					continue
				}

				let type = cleanUpType(rawType)

				result.append(
					(identifier: identifier,
					 type: type,
					 expression: translatedExpression))
			}
			else {
				result.append(nil)
			}
		}

		danglingPatternBindings = result
	}

	internal func getIdentifierFromDeclaration(_ declaration: String)
		-> (declaration: String, isStandardLibrary: Bool)
	{
		let isStandardLibrary = declaration.hasPrefix("Swift")

		var index = declaration.startIndex
		var lastPeriodIndex = declaration.startIndex
		while index != declaration.endIndex {
			let character = declaration[index]

			if character == "." {
				lastPeriodIndex = index
			}
			if character == "@" {
				break
			}

			index = declaration.index(after: index)
		}

		// If it's an identifier that contains periods, like the range operators `..<` etc
		var beforeLastPeriodIndex = declaration.index(before: lastPeriodIndex)
		while declaration[beforeLastPeriodIndex] == "." {
			lastPeriodIndex = beforeLastPeriodIndex
			beforeLastPeriodIndex = declaration.index(before: lastPeriodIndex)
		}

		let identifierStartIndex = declaration.index(after: lastPeriodIndex)

		let identifier = declaration[identifierStartIndex..<index]

		return (declaration: String(identifier), isStandardLibrary: isStandardLibrary)
	}

	/// Extracts the range numbers from a string in the form
	/// `Path/to/file.swift:1:2 - line:3:4`, where the numbers 1, 2, 3 and 4 represent (in order)
	/// the lineStart, columnStart, lineEnd and columndEnd.
	internal func getRange(ofNode ast: SwiftAST) -> SourceFileRange? {
		guard let rangeString = ast["range"],
			let maybeSwiftIndex = rangeString.range(of: ".swift:")?.upperBound else
		{
			return nil
		}

		var currentSubstring: Substring

		let lineStartIndex = maybeSwiftIndex
		currentSubstring = rangeString[lineStartIndex...]
		let lineStartString = currentSubstring.prefix(while: { $0.isNumber })
		guard let lineStart = Int(lineStartString) else {
			return nil
		}

		// skip the ":"
		let columnStartIndex = rangeString.index(after: lineStartString.endIndex)
		currentSubstring = rangeString[columnStartIndex...]
		let columnStartString = currentSubstring.prefix(while: { $0.isNumber })
		guard let columnStart = Int(columnStartString) else {
			return nil
		}

		// skip the " - line:"
		let lineEndIndex =
			rangeString.index(columnStartString.endIndex, offsetBy: " - line:".count)
		currentSubstring = rangeString[lineEndIndex...]
		let lineEndString = currentSubstring.prefix(while: { $0.isNumber })
		guard let lineEnd = Int(lineEndString) else {
			return nil
		}

		// skip the ":"
		let columnEndIndex = rangeString.index(after: lineEndString.endIndex)
		currentSubstring = rangeString[columnEndIndex...]
		let columnEndString = currentSubstring.prefix(while: { $0.isNumber })
		guard let columnEnd = Int(columnEndString) else {
			return nil
		}

		return SourceFileRange(
			lineStart: lineStart,
			lineEnd: lineEnd,
			columnStart: columnStart,
			columnEnd: columnEnd)
	}

	internal func getRangeRecursively(ofNode ast: SwiftAST) -> SourceFileRange? {
		if let range = getRange(ofNode: ast) {
			return range
		}

		for subtree in ast.subtrees {
			if let range = getRange(ofNode: subtree) {
				return range
			}
		}

		return nil
	}

	internal func getComment(forNode ast: SwiftAST, key: String) -> String? {
		if let comment = getComment(forNode: ast), comment.key == key {
			return comment.value
		}
		return nil
	}

	internal func getComment(forNode ast: SwiftAST) -> SourceFile.Comment? {
		if let lineNumber = getRange(ofNode: ast)?.lineStart {
			return sourceFile?.getCommentFromLine(lineNumber)
		}
		else {
			return nil
		}
	}

	internal func insertedCode(inRange range: Range<Int>) -> [SourceFile.Comment] {
		var result = [SourceFile.Comment]()
		for lineNumber in range {
			if let insertComment = sourceFile?.getCommentFromLine(lineNumber) {
				result.append(insertComment)
			}
		}
		return result
	}

	internal func cleanUpType(_ type: String) -> String {
		if type.hasPrefix("@lvalue ") {
			return String(type.suffix(from: "@lvalue ".endIndex))
		}
		else if type.hasPrefix("("), type.hasSuffix(")"), !type.contains("->"), !type.contains(",")
		{
			return String(type.dropFirst().dropLast())
		}
		else {
			return type
		}
	}

	internal func ASTIsExpression(_ ast: SwiftAST) -> Bool {
		return ast.name.hasSuffix("Expression") || ast.name == "Inject Into Optional"
	}

	// MARK: Error handling
	func createUnexpectedASTStructureError(
		file: String = #file, line: Int = #line, function: String = #function, _ message: String,
		AST ast: SwiftAST, translator: SwiftTranslator) -> SwiftTranslatorError
	{
		return SwiftTranslatorError.unexpectedASTStructure(
			file: file,
			line: line,
			function: function,
			message: message,
			AST: ast,
			translator: translator)
	}

	func handleUnexpectedASTStructureError(_ error: Error) throws -> Statement {
		try Compiler.handleError(error)
		return .error
	}

	func unexpectedASTStructureError(
		file: String = #file, line: Int = #line, function: String = #function, _ message: String,
		AST ast: SwiftAST, translator: SwiftTranslator) throws -> Statement
	{
		let error = createUnexpectedASTStructureError(
			file: file, line: line, function: function, message, AST: ast, translator: translator)
		return try handleUnexpectedASTStructureError(error)
	}

	func unexpectedExpressionStructureError(
		file: String = #file, line: Int = #line, function: String = #function, _ message: String,
		AST ast: SwiftAST, translator: SwiftTranslator) throws -> Expression
	{
		let error = SwiftTranslatorError.unexpectedASTStructure(
			file: file,
			line: line,
			function: function,
			message: message,
			AST: ast,
			translator: translator)
		try Compiler.handleError(error)
		return .error
	}
}

enum SwiftTranslatorError: Error, CustomStringConvertible {
	case unexpectedASTStructure(
		file: String,
		line: Int,
		function: String,
		message: String,
		AST: SwiftAST,
		translator: SwiftTranslator)

	var description: String {
		switch self {
		case let .unexpectedASTStructure(
			file: file,
			line: line,
			function: function,
			message: message,
			AST: ast,
			translator: translator):

			var nodeDescription = ""
			ast.prettyPrint {
				nodeDescription += $0
			}
			let details = "When translating the following AST node:\n\(nodeDescription)"

			return Compiler.createErrorOrWarningMessage(
				file: file,
				line: line,
				function: function,
				message: message,
				details: details,
				sourceFile: translator.sourceFile,
				sourceFileRange: translator.getRangeRecursively(ofNode: ast))
		}
	}

	var astName: String {
		switch self {
		case let .unexpectedASTStructure(
			file: _, line: _, function: _, message: _, AST: ast, translator: _):

			return ast.name
		}
	}
}
