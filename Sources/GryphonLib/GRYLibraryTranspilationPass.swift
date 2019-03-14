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

// TODO: Add tests for all standard library translations
public class GRYLibraryTranspilationPass: GRYTranspilationPass {
	struct Template {
		let expression: GRYExpression
		let string: String
	}

	static var templates = [Template]()

	static func loadTemplates() {
		try! GRYUtils.updateLibraryFiles()

		let libraryFilesPath: String = Process().currentDirectoryPath + "/Library Templates/"
		let currentURL = URL(fileURLWithPath: libraryFilesPath)
		let fileURLs = try! FileManager.default.contentsOfDirectory(
			at: currentURL,
			includingPropertiesForKeys: nil)
		let templateFiles = fileURLs.filter {
				$0.pathExtension == GRYFileExtension.gryRawAST.rawValue
		}.sorted { (url1: URL, url2: URL) -> Bool in
					url1.absoluteString < url2.absoluteString
		}

		var previousExpression: GRYExpression?
		for file in templateFiles {
			let filePath = file.path
			let ast = try! GRYAST(decodeFromFile: filePath)
			let expressions = ast.statements.compactMap
			{ (node: GRYTopLevelNode) -> GRYExpression? in
				if case let .expression(expression: expression) = node {
					return expression
				}
				else {
					return nil
				}
			}

			for expression in expressions {
				if let templateExpression = previousExpression {
					guard case let .literalStringExpression(value: value) = expression else {
						continue
					}
					templates.append(Template(expression: templateExpression, string: value))
					previousExpression = nil
				}
				else {
					previousExpression = expression
				}
			}
		}
	}

	override func run(on sourceFile: GRYAST) -> GRYAST {
		if GRYLibraryTranspilationPass.templates.isEmpty {
			GRYLibraryTranspilationPass.loadTemplates()
		}
		return super.run(on: sourceFile)
	}

	override func replaceExpression(_ expression: GRYExpression) -> GRYExpression {
		for template in GRYLibraryTranspilationPass.templates {
			if let matches = expression.matches(template.expression) {
				let replacedMatches = matches.mapValues {
					self.replaceExpression($0)
				}
				return .templateExpression(pattern: template.string, matches: replacedMatches)
			}
		}
		return super.replaceExpression(expression)
	}
}

extension GRYExpression {
	func matches(_ template: GRYExpression) -> [String: GRYExpression]? {
		var result = [String: GRYExpression]()
		let success = matches(template, &result)
		if success {
			return result
		}
		else {
			return nil
		}
	}

	private func matches(
		_ template: GRYExpression, _ matches: inout [String: GRYExpression]) -> Bool
	{
		if case let .declarationReferenceExpression(
				identifier: identifier, type: templateType, isStandardLibrary: _,
				isImplicit: _) = template,
			identifier.hasPrefix("_"),
			self.isOfType(templateType)
		{
			matches[identifier] = self
			return true
		}
		else {
			switch (self, template) {
			case let (
				.literalCodeExpression(string: leftString),
				.literalCodeExpression(string: rightString)):

				return leftString == rightString
			case let (
				.parenthesesExpression(expression: leftExpression),
				.parenthesesExpression(expression: rightExpression)):

				return leftExpression.matches(rightExpression, &matches)
			case let (
				.forceValueExpression(expression: leftExpression),
				.forceValueExpression(expression: rightExpression)):

				return leftExpression.matches(rightExpression, &matches)
			case let
				(.declarationReferenceExpression(
					identifier: leftIdentifier, type: leftType,
					isStandardLibrary: _, isImplicit: leftIsImplicit),
				 .declarationReferenceExpression(
					identifier: rightIdentifier, type: rightType,
					isStandardLibrary: _, isImplicit: rightIsImplicit)):

				return leftIdentifier == rightIdentifier && leftType.isSubtype(of: rightType) &&
					leftIsImplicit == rightIsImplicit
			case let
				(.typeExpression(type: leftType),
				 .typeExpression(type: rightType)):

				return leftType.isSubtype(of: rightType)
			case let
				(.subscriptExpression(
					subscriptedExpression: leftSubscriptedExpression,
					indexExpression: leftIndexExpression, type: leftType),
				 .subscriptExpression(
					subscriptedExpression: rightSubscriptedExpression,
					indexExpression: rightIndexExpression, type: rightType)):

					return leftSubscriptedExpression.matches(rightSubscriptedExpression, &matches)
						&& leftIndexExpression.matches(rightIndexExpression, &matches)
						&& leftType.isSubtype(of: rightType)
			case let
				(.arrayExpression(elements: leftElements, type: leftType),
				 .arrayExpression(elements: rightElements, type: rightType)):

				var result = true
				for (leftElement, rightElement) in zip(leftElements, rightElements) {
					result = result && leftElement.matches(rightElement, &matches)
				}
				return result && (leftType.isSubtype(of: rightType))
			case let
				(.dotExpression(
					leftExpression: leftLeftExpression, rightExpression: leftRightExpression),
				 .dotExpression(
					leftExpression: rightLeftExpression, rightExpression: rightRightExpression)):

				return leftLeftExpression.matches(rightLeftExpression, &matches) &&
					leftRightExpression.matches(rightRightExpression, &matches)
			case let
				(.binaryOperatorExpression(
					leftExpression: leftLeftExpression, rightExpression: leftRightExpression,
					operatorSymbol: leftOperatorSymbol, type: leftType),
				 .binaryOperatorExpression(
					leftExpression: rightLeftExpression, rightExpression: rightRightExpression,
					operatorSymbol: rightOperatorSymbol, type: rightType)):

				return leftLeftExpression.matches(rightLeftExpression, &matches) &&
					leftRightExpression.matches(rightRightExpression, &matches) &&
					(leftOperatorSymbol == rightOperatorSymbol) &&
					(leftType.isSubtype(of: rightType))
			case let
				(.prefixUnaryExpression(
					expression: leftExpression, operatorSymbol: leftOperatorSymbol, type: leftType),
				 .prefixUnaryExpression(
					expression: rightExpression, operatorSymbol: rightOperatorSymbol,
					type: rightType)):

				return leftExpression.matches(rightExpression, &matches) &&
					(leftOperatorSymbol == rightOperatorSymbol)
					&& (leftType.isSubtype(of: rightType))
			case let
				(.postfixUnaryExpression(
					expression: leftExpression, operatorSymbol: leftOperatorSymbol, type: leftType),
				 .postfixUnaryExpression(
					expression: rightExpression, operatorSymbol: rightOperatorSymbol,
					type: rightType)):

				return leftExpression.matches(rightExpression, &matches) &&
					(leftOperatorSymbol == rightOperatorSymbol)
					&& (leftType.isSubtype(of: rightType))
			case let
				(.callExpression(
					function: leftFunction, parameters: leftParameters, type: leftType),
				 .callExpression(
					function: rightFunction, parameters: rightParameters, type: rightType)):

				return leftFunction.matches(rightFunction, &matches) &&
					leftParameters.matches(rightParameters, &matches) &&
					(leftType.isSubtype(of: rightType))
			case let
				(.literalIntExpression(value: leftValue),
				 .literalIntExpression(value: rightValue)):

				return leftValue == rightValue
			case let
				(.literalDoubleExpression(value: leftValue),
				 .literalDoubleExpression(value: rightValue)):

				return leftValue == rightValue
			case let
				(.literalBoolExpression(value: leftValue),
				 .literalBoolExpression(value: rightValue)):

				return leftValue == rightValue
			case let
				(.literalStringExpression(value: leftValue),
				 .literalStringExpression(value: rightValue)):

				return leftValue == rightValue
			case (.nilLiteralExpression, .nilLiteralExpression):
				return true
			case let
				(.interpolatedStringLiteralExpression(expressions: leftExpressions),
				 .interpolatedStringLiteralExpression(expressions: rightExpressions)):

				var result = true
				for (leftExpression, rightExpression) in zip(leftExpressions, rightExpressions) {
					result = result && leftExpression.matches(rightExpression, &matches)
				}
				return result
			case let
				(.tupleExpression(pairs: leftPairs),
				 .tupleExpression(pairs: rightPairs)):

				var result = true
				for (leftPair, rightPair) in zip(leftPairs, rightPairs) {
					result = result && leftPair.expression.matches(rightPair.expression, &matches)
						&& leftPair.label == rightPair.label
				}
				return result
			case let
				(.tupleShuffleExpression(
					labels: leftLabels, indices: leftIndices, expressions: leftExpressions),
				 .tupleShuffleExpression(
					labels: rightLabels, indices: rightIndices, expressions: rightExpressions)):

				var result = (leftLabels == rightLabels) && (leftIndices == rightIndices)
				for (leftExpression, rightExpression) in zip(leftExpressions, rightExpressions) {
					result = result && leftExpression.matches(rightExpression, &matches)
				}
				return result
			default:
				return false
			}
		}
	}

	func isOfType(_ superType: String) -> Bool {
		guard let type = self.type else {
			return false
		}

		return type.isSubtype(of: superType)
	}
}

fileprivate extension String {
	func isSubtype(of superType: String) -> Bool {
		// Check common cases
		if self == superType {
			return true
		}
		else if superType == "Any" || superType == "Hash" {
			return true
		}

		// Handle optionals
		if self.last == "?", superType.last == "?" {
			let newSelf = String(self.dropLast())
			let newSuperType = String(superType.dropLast())
			return newSelf.isSubtype(of: newSuperType)
		}

		// Treat ArrayReference as Array
		if self.hasPrefix("ArrayReference<"), self.last == ">" {
			let elementType = String(self.dropFirst("ArrayReference<".count).dropLast())
			let newSelf = "[\(elementType)]"
			return newSelf.isSubtype(of: superType)
		}

		// Treat Slice<ArrayReference<T>> as ArraySlice<T>
		if self.hasPrefix("Slice<ArrayReference<"), self.hasSuffix(">>") {
			let elementType =
				String(self.dropFirst("Slice<ArrayReference<".count).dropLast(">>".count))
			let newSelf = "ArraySlice<\(elementType)>"
			return newSelf.isSubtype(of: superType)
		}

		// Convert Array<T> into [T]
		if self.hasPrefix("Array<"), self.last == ">" {
			let elementType = String(self.dropFirst("Reference<".count).dropLast())
			let newSelf = "[\(elementType)]"
			return newSelf.isSubtype(of: superType)
		}
		else if superType.hasPrefix("Array<"), superType.last == ">" {
			let elementType = String(superType.dropFirst("Array<".count).dropLast())
			let newSuperType = "[\(elementType)]"
			return self.isSubtype(of: newSuperType)
		}

		// Analyze components of function types
		if superType.contains(" -> ") {
			guard self.contains(" -> ") else {
				return false
			}

			return true
		}

		// Remove parentheses
		if self.first == "(", self.last == ")" {
			return String(self.dropFirst().dropLast()).isSubtype(of: superType)
		}
		if superType.first == "(", superType.last == ")" {
			return self.isSubtype(of: String(superType.dropFirst().dropLast()))
		}

		// Handle arrays
		if self.first == "[", self.last == "]", superType.first == "[", superType.last == "]" {
			if self.contains(":") && superType.contains(":") {
				let selfKeyValue =
					String(self.dropFirst().dropLast()).split(withStringSeparator: " : ")
				let superKeyValue =
					String(superType.dropFirst().dropLast()).split(withStringSeparator: " : ")
				let selfKey = selfKeyValue[0]
				let selfValue = selfKeyValue[1]
				let superKey = superKeyValue[0]
				let superValue = superKeyValue[1]
				return selfKey.isSubtype(of: superKey) && selfValue.isSubtype(of: superValue)
			}
			else if !self.contains(":") && !superType.contains(":") {
				let selfElement = String(self.dropFirst().dropLast())
				let superTypeElement = String(superType.dropFirst().dropLast())
				return selfElement.isSubtype(of: superTypeElement)
			}
		}

		// Handle inout types
		if self.hasPrefix("inout ") {
			let selfWithoutInout = String(self.dropFirst("inout ".count))
			return selfWithoutInout.isSubtype(of: superType)
		}
		else if superType.hasPrefix("inout ") {
			let superTypeWithoutInout = String(superType.dropFirst("inout ".count))
			return self.isSubtype(of: superTypeWithoutInout)
		}

		// Handle `__owned` types
		if self.hasPrefix("__owned ") {
			let selfWithoutOwned = String(self.dropFirst("__owned ".count))
			return selfWithoutOwned.isSubtype(of: superType)
		}
		else if superType.hasPrefix("__owned ") {
			let superTypeWithoutOwned = String(superType.dropFirst("__owned ".count))
			return self.isSubtype(of: superTypeWithoutOwned)
		}

		// Handle generics
		if self.contains("<"), self.last == ">", superType.contains("<"), superType.last == ">" {
			let selfStartGenericsIndex = self.firstIndex(of: "<")!
			let superTypeStartGenericsIndex = superType.firstIndex(of: "<")!

			let selfGenericArguments =
				String(self[selfStartGenericsIndex...].dropFirst().dropLast())
			let superTypeGenericArguments =
				String(superType[superTypeStartGenericsIndex...].dropFirst().dropLast())

			let selfTypeComponents = selfGenericArguments.split(withStringSeparator: ", ")
			let superTypeComponents = superTypeGenericArguments.split(withStringSeparator: ", ")

			guard superTypeComponents.count == selfTypeComponents.count else {
				return false
			}

			for (selfTypeComponent, superTypeComponent) in
				zip(selfTypeComponents, superTypeComponents)
			{
				if !selfTypeComponent.isSubtype(of: superTypeComponent) {
					return false
				}
			}

			return true
		}

		// If no subtype cases were met, say it's not a subtype
		return false
	}
}
