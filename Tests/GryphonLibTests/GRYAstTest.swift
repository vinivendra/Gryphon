//
//  GRYAstTest.swift
//  GryphonLibTests
//
//  Created by Vinicius Vendramini on 18/09/18.
//

import Foundation
@testable import GryphonLib
import XCTest

class GRYAstTest: XCTestCase {

//	func testEquatable() {
//		let tests = createTestArray()
//		let equalTests = createTestArray()
//		let differentTests = equalTests.rotated()
//
//		for (test, equalTest) in zip(tests, equalTests) {
//			XCTAssertEqual(test, equalTest)
//		}
//
//		for (test, differentTest) in zip(tests, differentTests) {
//			XCTAssertNotEqual(test, differentTest)
//		}
//	}
//
//	func createTestArray() -> [GRYAstNode] {
//		let testExpressionA = GRYNilLiteralExpression()
//		let testExpressionB = GRYLiteralExpression(value: "testExpressionB")
//		let testExpressionC = GRYLiteralExpression(value: 0)
//		let testStatementA = GRYReturnStatement(expression: testExpressionA)
//		let testStatementB = GRYThrowStatement(expression: testExpressionB)
//		let testFunctionDeclarationA = GRYFunctionDeclaration(
//			prefix: "a", parameterNames: [], parameterTypes: [], returnType: "A",
//			isImplicit: true, statements: [], access: "")
//		let testFunctionDeclarationB = GRYFunctionDeclaration(
//		prefix: "b", parameterNames: [], parameterTypes: [], returnType: "A",
//		isImplicit: true, statements: [], access: "")
//		let elseStatement = GRYIfStatement(
//			conditions: [], declarations: [], statements: [], elseStatement: nil, isGuard: false)
//		let ifStatementWithElse = GRYIfStatement(
//			conditions: [testExpressionB], declarations: [], statements: [],
//			elseStatement: elseStatement, isGuard: false)
//
//		return [
//			GRYImportDeclaration("a"),
//			GRYImportDeclaration("b"),
//			GRYClassDeclaration(name: "A", inherits: [], members: []),
//			GRYClassDeclaration(name: "B", inherits: [], members: []),
//			GRYClassDeclaration(name: "B", inherits: ["A"], members: []),
//			GRYClassDeclaration(name: "B", inherits: ["A"], members: [testStatementA]),
//			GRYConstructorDeclaration(isImplicit: true),
//			GRYConstructorDeclaration(isImplicit: false),
//			GRYDestructorDeclaration(isImplicit: true),
//			GRYDestructorDeclaration(isImplicit: false),
//			GRYEnumDeclaration(access: "", name: "A", inherits: [], elements: []),
//			GRYEnumDeclaration(access: "a", name: "A", inherits: [], elements: []),
//			GRYEnumDeclaration(access: "a", name: "B", inherits: [], elements: []),
//			GRYEnumDeclaration(access: "a", name: "B", inherits: ["A"], elements: []),
//			GRYEnumDeclaration(access: "a", name: "B", inherits: ["A"], elements: ["b"]),
//			GRYProtocolDeclaration(name: "A"),
//			GRYProtocolDeclaration(name: "B"),
//			GRYStructDeclaration(name: "A"),
//			GRYStructDeclaration(name: "B"),
//			GRYFunctionDeclaration(
//				prefix: "a", parameterNames: [], parameterTypes: [], returnType: "A",
//				isImplicit: true, statements: [], access: ""),
//			GRYFunctionDeclaration(
//				prefix: "b", parameterNames: [], parameterTypes: [], returnType: "A",
//				isImplicit: true, statements: [], access: ""),
//			GRYFunctionDeclaration(
//				prefix: "b", parameterNames: ["a"], parameterTypes: ["A"], returnType: "A",
//				isImplicit: true, statements: [], access: ""),
//			GRYFunctionDeclaration(
//				prefix: "b", parameterNames: ["a"], parameterTypes: ["B"], returnType: "A",
//				isImplicit: true, statements: [], access: ""),
//			GRYFunctionDeclaration(
//				prefix: "b", parameterNames: ["b"], parameterTypes: ["B"], returnType: "A",
//				isImplicit: true, statements: [], access: ""),
//			GRYFunctionDeclaration(
//				prefix: "b", parameterNames: ["b"], parameterTypes: ["B"], returnType: "B",
//				isImplicit: true, statements: [], access: ""),
//			GRYFunctionDeclaration(
//				prefix: "b", parameterNames: ["b"], parameterTypes: ["B"], returnType: "B",
//				isImplicit: false, statements: [], access: ""),
//			GRYFunctionDeclaration(
//				prefix: "b", parameterNames: ["b"], parameterTypes: ["B"], returnType: "B",
//				isImplicit: false, statements: [testStatementA], access: ""),
//			GRYFunctionDeclaration(
//				prefix: "b", parameterNames: ["b"], parameterTypes: ["B"], returnType: "B",
//				isImplicit: false, statements: [testStatementA], access: "a"),
//			GRYVariableDeclaration(
//				expression: testExpressionA, identifier: "a", type: "A", getter: nil, setter: nil,
//				isLet: true, extendsType: nil),
//			GRYVariableDeclaration(
//				expression: testExpressionB, identifier: "a", type: "A", getter: nil, setter: nil,
//				isLet: true, extendsType: nil),
//			GRYVariableDeclaration(
//				expression: testExpressionB, identifier: "b", type: "A", getter: nil, setter: nil,
//				isLet: true, extendsType: nil),
//			GRYVariableDeclaration(
//				expression: testExpressionB, identifier: "b", type: "B", getter: nil, setter: nil,
//				isLet: true, extendsType: nil),
//			GRYVariableDeclaration(
//				expression: testExpressionB, identifier: "b", type: "B",
//				getter: testFunctionDeclarationA, setter: nil, isLet: true, extendsType: nil),
//			GRYVariableDeclaration(
//				expression: testExpressionB, identifier: "b", type: "B",
//				getter: testFunctionDeclarationA, setter: testFunctionDeclarationB, isLet: true,
//				extendsType: nil),
//			GRYVariableDeclaration(
//				expression: testExpressionB, identifier: "b", type: "B",
//				getter: testFunctionDeclarationA, setter: testFunctionDeclarationB, isLet: false,
//				extendsType: nil),
//			GRYVariableDeclaration(
//				expression: testExpressionB, identifier: "b", type: "B",
//				getter: testFunctionDeclarationA, setter: testFunctionDeclarationB, isLet: false,
//				extendsType: "String"),
//			GRYForEachStatement(
//				collection: testExpressionA, variable: testExpressionB, statements: []),
//			GRYForEachStatement(
//				collection: testExpressionC, variable: testExpressionB, statements: []),
//			GRYForEachStatement(
//				collection: testExpressionC, variable: testExpressionA, statements: []),
//			GRYForEachStatement(
//				collection: testExpressionC, variable: testExpressionA,
//				statements: [testStatementA]),
//			GRYIfStatement(
//				conditions: [], declarations: [], statements: [], elseStatement: nil,
//				isGuard: false),
//			GRYIfStatement(
//				conditions: [testExpressionA], declarations: [], statements: [], elseStatement: nil,
//				isGuard: false),
//			GRYIfStatement(
//				conditions: [testExpressionA], declarations: [testStatementA], statements: [],
//				elseStatement: nil, isGuard: false),
//			GRYIfStatement(
//				conditions: [testExpressionA], declarations: [testStatementA],
//				statements: [testStatementB], elseStatement: nil, isGuard: false),
//			GRYIfStatement(
//				conditions: [testExpressionA], declarations: [testStatementA],
//				statements: [testStatementB], elseStatement: elseStatement, isGuard: false),
//			GRYIfStatement(
//				conditions: [testExpressionA], declarations: [testStatementA],
//				statements: [testStatementB], elseStatement: ifStatementWithElse, isGuard: false),
//			GRYIfStatement(
//				conditions: [testExpressionA], declarations: [], statements: [], elseStatement: nil,
//				isGuard: false),
//			GRYIfStatement(
//				conditions: [testExpressionA], declarations: [], statements: [], elseStatement: nil,
//				isGuard: true),
//			GRYThrowStatement(expression: testExpressionA),
//			GRYThrowStatement(expression: testExpressionB),
//			GRYReturnStatement(expression: testExpressionA),
//			GRYReturnStatement(expression: testExpressionB),
//			GRYAssignmentStatement(leftHand: testExpressionA, rightHand: testExpressionB),
//			GRYAssignmentStatement(leftHand: testExpressionC, rightHand: testExpressionB),
//			GRYAssignmentStatement(leftHand: testExpressionC, rightHand: testExpressionA),
//			GRYForceValueExpression(expression: testExpressionA),
//			GRYForceValueExpression(expression: testExpressionB),
//			GRYDeclarationReferenceExpression(identifier: "a"),
//			GRYDeclarationReferenceExpression(identifier: "b"),
//			GRYTypeExpression(type: "A"),
//			GRYTypeExpression(type: "B"),
//			GRYSubscriptExpression(
//				subscriptedExpression: testExpressionA, indexExpression: testExpressionB),
//			GRYSubscriptExpression(
//				subscriptedExpression: testExpressionC, indexExpression: testExpressionB),
//			GRYSubscriptExpression(
//				subscriptedExpression: testExpressionC, indexExpression: testExpressionA),
//			GRYArrayExpression(elements: []),
//			GRYArrayExpression(elements: [testExpressionA]),
//			GRYArrayExpression(elements: [testExpressionB]),
//			GRYDotExpression(leftExpression: testExpressionA, rightExpression: testExpressionB),
//			GRYDotExpression(leftExpression: testExpressionC, rightExpression: testExpressionB),
//			GRYDotExpression(leftExpression: testExpressionC, rightExpression: testExpressionA),
//			GRYBinaryOperatorExpression(
//				leftExpression: testExpressionA, rightExpression: testExpressionB,
//				operatorSymbol: "+"),
//			GRYBinaryOperatorExpression(
//				leftExpression: testExpressionC, rightExpression: testExpressionB,
//				operatorSymbol: "+"),
//			GRYBinaryOperatorExpression(
//				leftExpression: testExpressionC, rightExpression: testExpressionA,
//				operatorSymbol: "+"),
//			GRYBinaryOperatorExpression(
//				leftExpression: testExpressionC, rightExpression: testExpressionA,
//				operatorSymbol: "-"),
//			GRYUnaryOperatorExpression(expression: testExpressionA, operatorSymbol: "-"),
//			GRYUnaryOperatorExpression(expression: testExpressionB, operatorSymbol: "-"),
//			GRYUnaryOperatorExpression(expression: testExpressionB, operatorSymbol: "!"),
//			GRYCallExpression(function: testExpressionA, parameters: []),
//			GRYCallExpression(function: testExpressionB, parameters: []),
//			GRYCallExpression(
//				function: testExpressionB,
//				parameters: [GRYTupleExpression.Pair(name: "b", expression: testExpressionB)]),
//			GRYLiteralExpression(value: 0),
//			GRYLiteralExpression(value: 1),
//			GRYLiteralExpression(value: ""),
//			GRYLiteralExpression(value: 0.0),
//			GRYLiteralExpression(value: true),
//			GRYNilLiteralExpression(),
//			GRYInterpolatedStringLiteralExpression(expressions: []),
//			GRYInterpolatedStringLiteralExpression(expressions: [testExpressionA]),
//			GRYTupleExpression(pairs: []),
//			GRYTupleExpression(
//				pairs: [GRYTupleExpression.Pair(name: "a", expression: testExpressionA)]),
//			GRYTupleExpression(
//				pairs: [GRYTupleExpression.Pair(name: "b", expression: testExpressionA)]),
//			GRYTupleExpression(
//				pairs: [GRYTupleExpression.Pair(name: "b", expression: testExpressionB)]),
//		]
//	}
//
//	static var allTests = [
//		("testEquatable", testEquatable),
//	]
}
