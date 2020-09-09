//
// Copyright 2018 Vinicius Jorge Vendramini
//
// Licensed under the Hippocratic License, Version 2.1;
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://firstdonoharm.dev/version/2/1/license.md
//
// To the full extent allowed by law, this software comes "AS IS,"
// WITHOUT ANY WARRANTY, EXPRESS OR IMPLIED, and licensor and any other
// contributor shall not be liable to anyone for any damages or other
// liability arising from, out of, or in connection with the sotfware
// or this license, under any kind of legal claim.
// See the License for the specific language governing permissions and
// limitations under the License.
//

// gryphon output: Sources/GryphonLib/LibraryTranspilationPass.swiftAST
// gryphon output: Sources/GryphonLib/LibraryTranspilationPass.gryphonASTRaw
// gryphon output: Sources/GryphonLib/LibraryTranspilationPass.gryphonAST
// gryphon output: Bootstrap/LibraryTranspilationPass.kt

import Foundation

/// This pass records templates statically in TranspilationTemplate so they can be retrieved later.

public class RecordTemplatesTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	override func replaceFunctionDeclaration( // gryphon annotation: override
		_ functionDeclaration: FunctionDeclaration)
		-> List<Statement>
	{
		if functionDeclaration.prefix == "gryphonTemplates",
			functionDeclaration.parameters.isEmpty,
			let statements = functionDeclaration.statements
		{
			let topLevelExpressions: MutableList<Expression> = []
			for statement in statements {
				if let expressionStatement = statement as? ExpressionStatement {
					topLevelExpressions.append(expressionStatement.expression)
				}
			}

			var previousExpression: Expression?
			for templateExpression in topLevelExpressions {
				if let swiftExpression = previousExpression {
					if let typeName = templateExpression.swiftType,
						typeName == "_GRYLiteralTemplate" ||
							typeName == "_GRYDotTemplate" ||
							typeName == "_GRYCallTemplate" ||
							typeName == "_GRYConcatenatedTemplate" ||
							typeName == "GRYLiteralTemplate" ||
							typeName == "GRYDotTemplate" ||
							typeName == "GRYCallTemplate" ||
							typeName == "GRYConcatenatedTemplate"
					{
						let processedExpression =
							processTemplateNodeExpression(templateExpression)
						self.context.addTemplate(TranspilationContext.TranspilationTemplate(
							swiftExpression: swiftExpression,
							templateExpression: processedExpression))
					}
					if let literalString = getStringLiteralOrSum(templateExpression) {
						let cleanString = literalString.removingBackslashEscapes
						self.context.addTemplate(TranspilationContext.TranspilationTemplate(
							swiftExpression: swiftExpression,
							templateExpression: LiteralCodeExpression(
								syntax: templateExpression.syntax,
								range: templateExpression.range,
								string: cleanString,
								shouldGoToMainFunction: false,
								typeName: nil)))
						previousExpression = nil
					}
				}

				previousExpression = templateExpression
			}

			return []
		}

		return super.replaceFunctionDeclaration(functionDeclaration)
	}

	private func processTemplateNodeExpression(
		_ expression: Expression)
		-> Expression
	{
		if let callExpression = expression as? CallExpression {
			if let dotExpression = callExpression.function as? DotExpression,
				let tupleExpression = callExpression.parameters as? TupleExpression,
				tupleExpression.pairs.count == 2
			{
				if let declarationExpression =
					dotExpression.rightExpression as? DeclarationReferenceExpression
				{
					if declarationExpression.identifier == "call",
						let parametersExpression =
							tupleExpression.pairs[1].expression as? ArrayExpression
					{
						let function = processTemplateNodeExpression(
							tupleExpression.pairs[0].expression)
						let parameters = parametersExpression.elements.map {
								processTemplateParameter($0)
							}.toMutableList()
						return CallExpression(
							syntax: nil,
							range: nil,
							function: function,
							parameters: TupleExpression(
								syntax: nil,
								range: nil,
								pairs: parameters),
							typeName: nil,
							allowsTrailingClosure: true)
					}
					if declarationExpression.identifier == "dot",
						let stringExpression =
							tupleExpression.pairs[1].expression as? LiteralStringExpression
					{
						let left =
							processTemplateNodeExpression(tupleExpression.pairs[0].expression)
						let right = LiteralCodeExpression(
							syntax: nil,
							range: nil,
							string: stringExpression.value,
							shouldGoToMainFunction: false,
							typeName: nil)
						return DotExpression(
							syntax: nil,
							range: nil,
							leftExpression: left,
							rightExpression: right)
					}
				}
			}
		}
		else if let stringExpression = expression as? LiteralStringExpression {
			return LiteralCodeExpression(
				syntax: nil,
				range: nil,
				string: stringExpression.value,
				shouldGoToMainFunction: false,
				typeName: nil)
		}
		else if let binaryOperatorExpression = expression as? BinaryOperatorExpression,
			binaryOperatorExpression.operatorSymbol == "+"
		{
			return ConcatenationExpression(
				syntax: nil,
				range: nil,
				leftExpression: processTemplateNodeExpression(
					binaryOperatorExpression.leftExpression),
				rightExpression: processTemplateNodeExpression(
					binaryOperatorExpression.rightExpression))
		}

		Compiler.handleWarning(
			message: "Failed to interpret template",
			syntax: expression.syntax,
			ast: expression,
			sourceFile: ast.sourceFile,
			sourceFileRange: expression.range)

		return ErrorExpression(syntax: expression.syntax, range: expression.range)
	}

	private func processTemplateParameter(
		_ expression: Expression)
		-> LabeledExpression
	{
		if let expression = expression as? LiteralStringExpression {
			return LabeledExpression(
				label: nil,
				expression: LiteralCodeExpression(
					syntax: nil,
					range: nil,
					string: expression.value,
					shouldGoToMainFunction: false,
					typeName: nil))
		}
		else if let expression = expression as? CallExpression {
			if let dotExpression = expression.function as? DotExpression,
				let tupleExpression = expression.parameters as? TupleExpression,
				tupleExpression.pairs.count == 2
			{
				if let declarationExpression =
						dotExpression.rightExpression as? DeclarationReferenceExpression,
					declarationExpression.identifier == "labeledParameter",
					let stringExpression =
						tupleExpression.pairs[0].expression as? LiteralStringExpression
				{
					let expression =
						processTemplateNodeExpression(tupleExpression.pairs[1].expression)
					return LabeledExpression(
						label: stringExpression.value,
						expression: expression)
				}
			}
		}

		return LabeledExpression(
			label: nil,
			expression: processTemplateNodeExpression(expression))
	}

	/// Some String literals are written as sums of string literals (i.e. "a" + "b") or they'd be
	/// too large to fit in one line. This method should detect Strings both with and without sums.
	private func getStringLiteralOrSum(_ expression: Expression) -> String? {

		if let stringExpression = expression as? LiteralStringExpression {
			return stringExpression.value
		}

		if let binaryExpression = expression as? BinaryOperatorExpression,
			binaryExpression.operatorSymbol == "+",
			binaryExpression.typeName == "String"
		{
			if let leftString = getStringLiteralOrSum(binaryExpression.leftExpression),
				let rightString = getStringLiteralOrSum(binaryExpression.rightExpression)
			{
				return leftString + rightString
			}
		}

		return nil
	}
}

public class ReplaceTemplatesTranspilationPass: TranspilationPass {
	// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
	// gryphon insert:     super(ast, context) { }

	override func replaceExpression( // gryphon annotation: override
		_ expression: Expression)
		-> Expression
	{
		for template in context.templates {
			if let matches = expression.matches(template.swiftExpression, inContext: self.context) {

				// Make the matches dictionary into a list
				let matchesList: MutableList<(String, Expression)> = []
				for (string, expression) in matches {
					let tuple = (string, expression)
					matchesList.append(tuple)
				}
				// Replace the templates recursively on the list
				let replacedMatches = matchesList.map {
						return ($0.0, replaceExpression($0.1))
					}
				// Sort the list so that longer strings are before shorter ones.
				// This issues when one string is a substring of another
				let sortedMatches = replacedMatches.sorted { a, b in
						a.0.count > b.0.count
					}

				// Replace any underscored variables found in the templates's LiteralCodeExpressions
				// with their matched expressions
				let pass = ReplaceTemplateMatchesTranspilationPass(ast: ast, context: context)
				pass.matches = sortedMatches
				let result = pass.replaceExpression(template.templateExpression)

				// Set the original expression's type and range to the template expression that's
				// replacing it
				if let swiftType = expression.swiftType {
					result.swiftType = swiftType
				}
				result.range = expression.range

				return result
			}
		}
		return super.replaceExpression(expression)
	}
}

/// To be called on a strutured template expression; replaces any matches inside it with the given
/// expressions in the `matches` list.
private class ReplaceTemplateMatchesTranspilationPass: TranspilationPass {
// gryphon insert: constructor(ast: GryphonAST, context: TranspilationContext):
// gryphon insert:     super(ast, context) { }

	var matches: List<(String, Expression)> = []

	override func replaceLiteralCodeExpression( // gryphon annotation: override
		_ literalCodeExpression: LiteralCodeExpression)
		-> Expression
	{
		let string = literalCodeExpression.string
		let stringEndIndex = string.endIndex
		var previousMatchEndIndex = string.startIndex
		var currentIndex = string.startIndex
		let expressions: MutableList<Expression> = []
		while currentIndex != stringEndIndex {
			let character = string[currentIndex]

			// If we might have found a replaceable string
			if character == "_" {
				let substring = string[currentIndex...]
				var matchFound = false

				// Look through the matches to see if any of them equals our replaceable string
				for (matchString, matchExpression) in matches {

					// If one of them does
					if substring.hasPrefix(matchString) {

						// Add the substring that accumulated before the match (if it's not empty)
						if previousMatchEndIndex != currentIndex {
							let precedingString =
								String(string[previousMatchEndIndex..<currentIndex])
							let precedingStringExpression = LiteralCodeExpression(
								syntax: nil,
								range: nil,
								string: precedingString,
								shouldGoToMainFunction: false,
								typeName: nil)
							expressions.append(precedingStringExpression)
						}

						// Add the matched expression
						expressions.append(matchExpression)

						// Jump ahead to after the matched string
						let matchEndIndex = string.index(currentIndex, offsetBy: matchString.count)
						previousMatchEndIndex = matchEndIndex
						currentIndex = matchEndIndex

						// Stop looking for matches
						matchFound = true
						break
					}
				}

				// If wew found a match we already updated the index, so avoid doing it again
				if matchFound {
					continue
				}
			}

			currentIndex = string.index(after: currentIndex)
		}

		// Check if there's a trailing string we need to add
		if previousMatchEndIndex != stringEndIndex {
			expressions.append(LiteralCodeExpression(
				syntax: nil,
				range: nil,
				string: String(string[previousMatchEndIndex...]),
				shouldGoToMainFunction: false,
				typeName: nil))
		}

		// Create the resulting expression
		var result: Expression?
		for expression in expressions {
			if let previousResult = result {
				result = ConcatenationExpression(
					syntax: nil,
					range: nil,
					leftExpression: previousResult,
					rightExpression: expression)
			}
			else {
				result = expression
			}
		}

		if let existingResult = result {
			return existingResult
		}
		else {
			Compiler.handleWarning(
				message: "Unexpected empty result when replacing matches on template",
				syntax: literalCodeExpression.syntax,
				ast: literalCodeExpression,
				sourceFile: ast.sourceFile,
				sourceFileRange: literalCodeExpression.range)
			return literalCodeExpression
		}
	}
}

extension Expression {
	func matches(
		_ template: Expression,
		inContext context: TranspilationContext,
		shouldSkipRootTypeComparison: Bool = true)
		-> MutableMap<String, Expression>?
	{
		let result: MutableMap<String, Expression> = [:]
		let success = self.matches(template, result, context,
			shouldSkipRootTypeComparison: shouldSkipRootTypeComparison)
		if success {
			return result
		}
		else {
			return nil
		}
	}

	/// Checks if `self` matches the given `template` expression, and stores any matching
	/// underscored variables in the `matches` dictionary. Uses the `context` to calculate subtypes.
	///
	/// Note: SourceKit sometimes provides supertypes of expressions instead of their specific
	/// types. For instance, `print()` expects an `Any`, so the `expression` in `print(expression)`
	/// will always have type `Any`. This can cause problems when matching `expression` with a
	/// template of type `Int`, for instance, since the types won't match. To handle this case, the
	/// `shouldSkipRootTypeComparison` parameter can be used to avoid comparing the root
	/// expression's type. It isn't set in recursive calls so that inner types get compared
	/// normally (with the exception of dot expressions, whose types are usually determined by
	/// their right expression's type).
	private func matches(
		_ template: Expression,
		_ matches: MutableMap<String, Expression>,
		_ context: TranspilationContext,
		shouldSkipRootTypeComparison: Bool = false)
		-> Bool
	{
		let lhs = self
		let rhs = template

		if let declarationExpression = rhs as? DeclarationReferenceExpression {
			if declarationExpression.identifier.hasPrefix("_"),
				let declarationType = declarationExpression.typeName,
				shouldSkipRootTypeComparison || lhs.isOfType(declarationType, inContext: context)
			{
				matches[declarationExpression.identifier] = lhs
				return true
			}
		}

		if let lhs = lhs as? LiteralCodeExpression, let rhs = rhs as? LiteralCodeExpression {
			return lhs.string == rhs.string
		}
		if let lhs = lhs as? ParenthesesExpression,
			let rhs = rhs as? ParenthesesExpression
		{
			return lhs.expression.matches(rhs.expression, matches, context)
		}
		if let lhs = lhs as? ForceValueExpression,
			let rhs = rhs as? ForceValueExpression
		{
			return lhs.expression.matches(rhs.expression, matches, context)
		}
		if let lhs = lhs as? DeclarationReferenceExpression,
			let rhs = rhs as? DeclarationReferenceExpression
		{
			let typeMatches: Bool
			if shouldSkipRootTypeComparison {
				typeMatches = true
			}
			else if let leftType = lhs.typeName,
				let rightType = rhs.typeName
			{
				typeMatches = context.isSubtype(leftType, of: rightType)
			}
			else {
				typeMatches = false
			}

			// Consider only the prefix of functions, since SwiftSyntax may not include arguments
			// with default values.
			let lhsPrefix = String(lhs.identifier.prefix { $0 != "(" })
			let rhsPrefix = String(rhs.identifier.prefix { $0 != "(" })

			return typeMatches &&
				lhsPrefix == rhsPrefix &&
				lhs.isImplicit == rhs.isImplicit
		}
		if let lhs = lhs as? OptionalExpression,
			let rhs = rhs as? OptionalExpression
		{
			return lhs.expression.matches(rhs.expression, matches, context)
		}
		if let lhs = lhs as? TypeExpression,
			let rhs = rhs as? TypeExpression
		{
			return context.isSubtype(lhs.typeName, of: rhs.typeName)
		}
		if let lhs = lhs as? TypeExpression,
			let rhs = rhs as? DeclarationReferenceExpression
		{
			guard declarationExpressionMatchesImplicitTypeExpression(rhs) else {
				return false
			}

			if let typeName = rhs.typeName {
				let expressionType = String(typeName.dropLast(".Type".count))
				return context.isSubtype(lhs.typeName, of: expressionType)
			}
			else {
				return false
			}
		}
		if let lhs = lhs as? DeclarationReferenceExpression,
			let rhs = rhs as? TypeExpression
		{
			guard declarationExpressionMatchesImplicitTypeExpression(lhs) else {
				return false
			}

			if let typeName = lhs.typeName {
				let expressionType = String(typeName.dropLast(".Type".count))
				return context.isSubtype(expressionType, of: rhs.typeName)
			}
			else {
				return false
			}
		}
		if let lhs = lhs as? SubscriptExpression,
			let rhs = rhs as? SubscriptExpression
		{
			return lhs.subscriptedExpression.matches(rhs.subscriptedExpression, matches, context)
				&& lhs.indexExpression.matches(rhs.indexExpression, matches, context)
				&& (shouldSkipRootTypeComparison ||
					context.isSubtype(lhs.typeName, of: rhs.typeName))
		}
		if let lhs = lhs as? ArrayExpression,
			let rhs = rhs as? ArrayExpression
		{
			var result = (lhs.elements.count == rhs.elements.count)
			for (leftElement, rightElement) in zip(lhs.elements, rhs.elements) {
				result = result && leftElement.matches(rightElement, matches, context)
			}
			return result && (shouldSkipRootTypeComparison ||
					context.isSubtype(lhs.typeName, of: rhs.typeName))
		}
		if let lhs = lhs as? DotExpression,
			let rhs = rhs as? DotExpression
		{
			return lhs.leftExpression.matches(rhs.leftExpression, matches, context) &&
				lhs.rightExpression.matches(rhs.rightExpression, matches, context,
					shouldSkipRootTypeComparison: true)
		}
		if let lhs = lhs as? BinaryOperatorExpression,
			let rhs = rhs as? BinaryOperatorExpression
		{
			let typeMatches: Bool
			if shouldSkipRootTypeComparison {
				typeMatches = true
			}
			else if let leftType = lhs.typeName, let rightType = rhs.typeName {
				typeMatches = context.isSubtype(leftType, of: rightType)
			}
			else {
				typeMatches = true
			}

			return lhs.leftExpression.matches(rhs.leftExpression, matches, context) &&
				lhs.rightExpression.matches(rhs.rightExpression, matches, context) &&
				lhs.operatorSymbol == rhs.operatorSymbol &&
				typeMatches
		}
		if let lhs = lhs as? PrefixUnaryExpression,
			let rhs = rhs as? PrefixUnaryExpression
		{
			return lhs.subExpression.matches(rhs.subExpression, matches, context) &&
				lhs.operatorSymbol == rhs.operatorSymbol &&
				(shouldSkipRootTypeComparison || context.isSubtype(lhs.typeName, of: rhs.typeName))
		}
		if let lhs = lhs as? PostfixUnaryExpression,
			let rhs = rhs as? PostfixUnaryExpression
		{
			return lhs.subExpression.matches(rhs.subExpression, matches, context) &&
				lhs.operatorSymbol == rhs.operatorSymbol &&
				(shouldSkipRootTypeComparison || context.isSubtype(lhs.typeName, of: rhs.typeName))
		}
		if let lhs = lhs as? CallExpression,
			let rhs = rhs as? CallExpression
		{
			let typeMatches: Bool
			if shouldSkipRootTypeComparison {
				typeMatches = true
			}
			else if let lhsType = lhs.typeName,
				let rhsType = rhs.typeName
			{
				typeMatches = context.isSubtype(lhsType, of: rhsType)
			}
			else {
				typeMatches = true
			}

			return lhs.function.matches(rhs.function, matches, context) &&
				lhs.parameters.matches(rhs.parameters, matches, context) &&
				typeMatches
		}
		if let lhs = lhs as? LiteralIntExpression,
			let rhs = rhs as? LiteralIntExpression
		{
			return lhs.value == rhs.value
		}
		if let lhs = lhs as? LiteralDoubleExpression,
			let rhs = rhs as? LiteralDoubleExpression
		{
			return lhs.value == rhs.value
		}
		if let lhs = lhs as? LiteralFloatExpression,
			let rhs = rhs as? LiteralFloatExpression
		{
			return lhs.value == rhs.value
		}
		if let lhs = lhs as? LiteralBoolExpression,
			let rhs = rhs as? LiteralBoolExpression
		{
			return lhs.value == rhs.value
		}
		if let lhs = lhs as? LiteralStringExpression,
			let rhs = rhs as? LiteralStringExpression
		{
			return lhs.value == rhs.value
		}
		if lhs is NilLiteralExpression,
			rhs is NilLiteralExpression
		{
			return true
		}
		if let lhs = lhs as? InterpolatedStringLiteralExpression,
			let rhs = rhs as? InterpolatedStringLiteralExpression
		{
			var result = (lhs.expressions.count == rhs.expressions.count)
			for (leftExpression, rightExpression) in zip(lhs.expressions, rhs.expressions) {
				result = result && leftExpression.matches(rightExpression, matches, context)
			}
			return result
		}
		if let lhs = lhs as? TupleExpression,
			let rhs = rhs as? TupleExpression
		{
			// Check manually for matches in trailing closures (that don't have labels in code
			// but do in templates)
			if lhs.pairs.count == 1,
				let onlyLeftPair = lhs.pairs.first,
				rhs.pairs.count == 1,
				let onlyRightPair = rhs.pairs.first
			{
				if let closureInParentheses = onlyLeftPair.expression as? ParenthesesExpression {
					if closureInParentheses.expression is ClosureExpression {
						// Unwrap a redundant parentheses expression if needed
						if let templateInParentheses =
							onlyRightPair.expression as? ParenthesesExpression
						{
							return closureInParentheses.expression.matches(
								templateInParentheses.expression, matches, context)
						}
						else {
							return closureInParentheses.expression.matches(
								onlyRightPair.expression, matches, context)
						}
					}
				}
			}

			var result = true

			// Make sure the tuples are of the same size
			result = result && (lhs.pairs.count == rhs.pairs.count)

			// Check if the expressions inside them match
			for (leftPair, rightPair) in zip(lhs.pairs, rhs.pairs) {
				result = result &&
					leftPair.expression.matches(rightPair.expression, matches, context) &&
					leftPair.label == rightPair.label
			}
			return result
		}
		if let lhs = lhs as? TupleShuffleExpression,
			let rhs = rhs as? TupleShuffleExpression
		{
			var result = (lhs.labels == rhs.labels)

			for (leftIndex, rightIndex) in zip(lhs.indices, rhs.indices) {
				result = result && leftIndex == rightIndex
			}

			for (leftExpression, rightExpression) in zip(lhs.expressions, rhs.expressions) {
				result = result && leftExpression.matches(rightExpression, matches, context)
			}

			return result
		}
		if let lhs = lhs as? TupleExpression,
			let rhs = rhs as? TupleShuffleExpression
		{
			let rhsAsTupleExpression = rhs.flattenToTupleExpression()
			return lhs.matches(rhsAsTupleExpression, matches, context)
		}
		if let lhs = lhs as? TupleShuffleExpression,
			let rhs = rhs as? TupleExpression
		{
			let lhsAsTupleExpression = lhs.flattenToTupleExpression()
			return lhsAsTupleExpression.matches(rhs, matches, context)
		}

		// If no matches were found
		return false
	}

	///
	/// In a static context, some type expressions can be omitted. When that happens, they get
	/// translated as declaration references instead of type expressions. However, they should still
	/// match type expressions, as they're basically the same. This method should detect those
	/// cases.
	///
	/// Example:
	///
	/// ```
	/// class A {
	/// 	static func a() { }
	/// 	static func b() {
	/// 		a() // implicitly this is A.a(), and the implicit `A` gets dumped as a declaration
	/// 		// reference expression instead of a type expression.
	/// 	}
	/// ```
	///
	private func declarationExpressionMatchesImplicitTypeExpression(
		_ expression: DeclarationReferenceExpression) -> Bool
	{
		if let typeName = expression.typeName,
			typeName.hasSuffix(".Type"),
			expression.identifier == "self",
			expression.isImplicit
		{
			return true
		}
		else {
			return false
		}
	}

	func isOfType(_ superType: String, inContext context: TranspilationContext) -> Bool {
		guard let typeName = self.swiftType else {
			return false
		}

		return context.isSubtype(typeName, of: superType)
	}
}

internal extension TranspilationContext {
	func isSubtype(_ subType: String, of superType: String) -> Bool {
			// Check common cases
			if subType == superType {
				return true
			}
			else if subType.isEmpty || superType.isEmpty {
				return false
			}
			else if superType == "Any" ||
				superType == "_Any" ||
				superType == "_Hashable" ||
				superType == "_Comparable" ||
				superType == "_Optional"
			{
				return true
			}
			else if superType == "_CustomStringConvertible" {
				if let subTypeInheritances = inheritances[subType] {
					return subTypeInheritances.contains("CustomStringConvertible")
				}
				else {
					// If the subType was defined externally, assume it's CustomStringConvertible
					return true
				}
			}
			else if superType == "_Optional?" {
				return subType.hasSuffix("?")
			}
			else if superType == "XCTestCase" {
				return subType.contains("Test")
			}

			// Handle tuples
			if Utilities.isInEnvelopingParentheses(subType),
				Utilities.isInEnvelopingParentheses(superType)
			{
				let subContents = String(subType.dropFirst().dropLast())
				let superContents = String(superType.dropFirst().dropLast())

				let subComponents = subContents.split(withStringSeparator: ", ")
				let superComponents = superContents.split(withStringSeparator: ", ")

				guard subComponents.count == superComponents.count else {
					return false
				}

				for (subComponent, superComponent) in zip(subComponents, superComponents) {
					guard self.isSubtype(subComponent, of: superComponent) else {
						return false
					}
				}

				return true
			}

			// Simplify the types
			let simpleSubType = simplifyType(string: subType)
			let simpleSuperType = simplifyType(string: superType)
			if simpleSubType != subType || simpleSuperType != superType {
				return self.isSubtype(simpleSubType, of: simpleSuperType)
			}

			// Handle optionals
			if subType.last! == "?", superType.last! == "?" {
				let newSubType = String(subType.dropLast())
				let newSuperType = String(superType.dropLast())
				return self.isSubtype(newSubType, of: newSuperType)
			}
			else if superType.last! == "?" {
				let newSuperType = String(superType.dropLast())
				return self.isSubtype(subType, of: newSuperType)
			}

			// Analyze components of function types
			if superType.contains(" -> ") {
				guard subType.contains(" -> ") else {
					return false
				}

				return true
			}

			// Handle arrays and dictionaries
			if subType.first! == "[", subType.last! == "]",
				superType.first! == "[", superType.last! == "]"
			{
				if subType.contains(" : ") && superType.contains(" : ") {
					let subKeyValue =
						String(subType.dropFirst().dropLast()).split(withStringSeparator: " : ")
					let superKeyValue =
						String(superType.dropFirst().dropLast()).split(withStringSeparator: " : ")
					let subKey = subKeyValue[0]
					let subValue = subKeyValue[1]
					let superKey = superKeyValue[0]
					let superValue = superKeyValue[1]
					return self.isSubtype(subKey, of: superKey) &&
						self.isSubtype(subValue, of: superValue)
				}
				else if !subType.contains(":") && !superType.contains(":") {
					let subElement = String(subType.dropFirst().dropLast())
					let superTypeElement = String(superType.dropFirst().dropLast())
					return self.isSubtype(subElement, of: superTypeElement)
				}
			}

			// Handle generics
			if subType.contains("<"), subType.last! == ">",
				superType.contains("<"), superType.last! == ">"
			{
				let subStartGenericsIndex = subType.firstIndex(of: "<")!
				let superTypeStartGenericsIndex = superType.firstIndex(of: "<")!

				let subGenericArguments =
					String(subType[subStartGenericsIndex...].dropFirst().dropLast())
				let superTypeGenericArguments =
					String(superType[superTypeStartGenericsIndex...].dropFirst().dropLast())

				let subTypeComponents = subGenericArguments.split(withStringSeparator: ", ")
				let superTypeComponents = superTypeGenericArguments.split(withStringSeparator: ", ")

				guard superTypeComponents.count == subTypeComponents.count else {
					return false
				}

				for (subTypeComponent, superTypeComponent) in
					zip(subTypeComponents, superTypeComponents)
				{
					if !self.isSubtype(subTypeComponent, of: superTypeComponent) {
						return false
					}
				}

				return true
			}
			else if subType.contains("<"), subType.last! == ">" {
				let typeWithoutGenerics = String(subType.prefix {
					$0 !=
						"<" // gryphon value: '<'
				})
				return self.isSubtype(typeWithoutGenerics, of: superType)
			}
			else if superType.contains("<"), superType.last! == ">" {
				let typeWithoutGenerics = String(superType.prefix {
					$0 !=
						"<" // gryphon value: '<'
				})
				return self.isSubtype(subType, of: typeWithoutGenerics)
			}

			// If no subtype cases were met, say it's not a subtype
			return false
		}
}

private func simplifyType(string: String) -> String {
	// Deal with standard library types that can be handled as other types
	if let result = Utilities.getTypeMapping(for: string) {
		return result
	}

	// Treat MutableList as Array
	if string.hasPrefix("MutableList<"), string.last! == ">" {
		let elementType = String(string.dropFirst("MutableList<".count).dropLast())
		return "[\(elementType)]"
	}
	if string.hasPrefix("List<"), string.last! == ">" {
		let elementType = String(string.dropFirst("List<".count).dropLast())
		return "[\(elementType)]"
	}

	// Treat Slice as Array
	if string.hasPrefix("Slice<MutableList<"), string.hasSuffix(">>") {
		let elementType =
			String(string.dropFirst("Slice<MutableList<".count).dropLast(">>".count))
		return "[\(elementType)]"
	}
	else if string.hasPrefix("ArraySlice<"), string.hasSuffix(">") {
		let elementType = String(string.dropFirst("ArraySlice<".count).dropLast())
		return "[\(elementType)]"
	}
	else if string.hasPrefix("Array<"), string.hasSuffix(">.SubSequence") {
		let elementType = String(string.dropFirst("Array<".count).dropLast(">.SubSequence".count))
		return "[\(elementType)]"
	}

	// Treat MutableMap as Dictionary
	if string.hasPrefix("MutableMap<"), string.last! == ">" {
		let keyValue = String(string.dropFirst("MutableMap<".count).dropLast())
			.split(withStringSeparator: ", ")
		let key = keyValue[0]
		let value = keyValue[1]
		return "[\(key) : \(value)]"
	}
	else if string.hasPrefix("Map<"), string.last! == ">" {
		let keyValue = String(string.dropFirst("Map<".count).dropLast())
			.split(withStringSeparator: ", ")
		let key = keyValue[0]
		let value = keyValue[1]
		return "[\(key) : \(value)]"
	}

	// Convert Array<T> into [T]
	if string.hasPrefix("Array<"), string.last! == ">" {
		let elementType = String(string.dropFirst("Array<".count).dropLast())
		return "[\(elementType)]"
	}

	// Remove parentheses
	if Utilities.isInEnvelopingParentheses(string) {
		return String(string.dropFirst().dropLast())
	}

	// Handle inout types
	if string.hasPrefix("inout ") {
		return String(string.dropFirst("inout ".count))
	}

	// Handle `__owned` types
	if string.hasPrefix("__owned ") {
		return String(string.dropFirst("__owned ".count))
	}

	return string
}
