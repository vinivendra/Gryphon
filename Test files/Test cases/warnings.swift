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

// gryphon ignore
internal class GRYTemplate {
	static func dot(_ left: GRYTemplate, _ right: String) -> GRYDotTemplate {
		return GRYDotTemplate(left, right)
	}

	static func dot(_ left: String, _ right: String) -> GRYDotTemplate {
		return GRYDotTemplate(GRYLiteralTemplate(string: left), right)
	}

	static func call(
		_ function: GRYTemplate,
		_ parameters: [GRYParameterTemplate])
		-> GRYCallTemplate
	{
		return GRYCallTemplate(function, parameters)
	}

	static func call(
		_ function: String,
		_ parameters: [GRYParameterTemplate])
		-> GRYCallTemplate
	{
		return GRYCallTemplate(function, parameters)
	}
}

// gryphon ignore
internal class GRYDotTemplate: GRYTemplate {
	let left: GRYTemplate
	let right: String

	init(_ left: GRYTemplate, _ right: String) {
		self.left = left
		self.right = right
	}
}

// gryphon ignore
internal class GRYCallTemplate: GRYTemplate {
	let function: GRYTemplate
	let parameters: [GRYParameterTemplate]

	init(_ function: GRYTemplate, _ parameters: [GRYParameterTemplate]) {
		self.function = function
		self.parameters = parameters
	}

	//
	init(_ function: String, _ parameters: [GRYParameterTemplate]) {
		self.function = GRYLiteralTemplate(string: function)
		self.parameters = parameters
	}
}

// gryphon ignore
internal class GRYParameterTemplate: ExpressibleByStringLiteral {
	let label: String?
	let template: GRYTemplate

	internal init(_ label: String?, _ template: GRYTemplate) {
		if let existingLabel = label {
			if existingLabel == "_" || existingLabel == "" {
				self.label = nil
			}
			else {
				self.label = label
			}
		}
		else {
			self.label = label
		}

		self.template = template
	}

	required init(stringLiteral: String) {
		self.label = nil
		self.template = GRYLiteralTemplate(string: stringLiteral)
	}

	static func labeledParameter(
		_ label: String?,
		_ template: GRYTemplate)
		-> GRYParameterTemplate
	{
		return GRYParameterTemplate(label, template)
	}

	static func labeledParameter(
		_ label: String?,
		_ template: String)
		-> GRYParameterTemplate
	{
		return GRYParameterTemplate(label, GRYLiteralTemplate(string: template))
	}

	static func dot(
		_ left: GRYTemplate,
		_ right: String)
		-> GRYParameterTemplate
	{
		return GRYParameterTemplate(nil, GRYDotTemplate(left, right))
	}

	static func dot(
		_ left: String,
		_ right: String)
		-> GRYParameterTemplate
	{
		return GRYParameterTemplate(nil, GRYDotTemplate(GRYLiteralTemplate(string: left), right))
	}

	static func call(
		_ function: GRYTemplate,
		_ parameters: [GRYParameterTemplate])
		-> GRYParameterTemplate
	{
		return GRYParameterTemplate(nil, GRYCallTemplate(function, parameters))
	}

	static func call(
		_ function: String,
		_ parameters: [GRYParameterTemplate])
		-> GRYParameterTemplate
	{
		return GRYParameterTemplate(nil, GRYCallTemplate(function, parameters))
	}
}

// gryphon ignore
internal class GRYLiteralTemplate: GRYTemplate {
	let string: String

	init(string: String) {
		self.string = string
	}
}

// gryphon ignore
internal class GRYConcatenatedTemplate: GRYTemplate {
	let left: GRYTemplate
	let right: GRYTemplate

	init(left: GRYTemplate, right: GRYTemplate) {
		self.left = left
		self.right = right
	}
}

// gryphon ignore
internal func + (
	left: GRYTemplate,
	right: GRYTemplate)
	-> GRYConcatenatedTemplate
{
	GRYConcatenatedTemplate(left: left, right: right)
}

// gryphon ignore
internal func + (left: String, right: GRYTemplate) -> GRYConcatenatedTemplate {
	GRYConcatenatedTemplate(left: GRYLiteralTemplate(string: left), right: right)
}

// gryphon ignore
internal func + (left: GRYTemplate, right: String) -> GRYConcatenatedTemplate {
	GRYConcatenatedTemplate(left: left, right: GRYLiteralTemplate(string: right))
}

// MARK: - Templates
// Replacement for Comparable
// gryphon ignore
private struct _Comparable: Comparable {
	static func < (lhs: _Comparable, rhs: _Comparable) -> Bool {
		return false
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////
// Test warnings for mutable value types
struct UnsupportedStruct {
	let immutableVariable = 0
	var mutableVariable = 0

	func pureFunction() { }
	mutating func mutatingFunction() { }

	var computedVarIsOK: Int {
		return 0
	}
}

enum UnsupportedEnum {
	case a(int: Int)

	mutating func mutatingFunction() { }

	var computedVarIsOK: Int {
		return 0
	}
}

// Test warnings for native declarations
let nativeArray: [Int] = []
let nativeDictionary: [Int: Int] = [:]

// Test warnings for nested fileprivate members
class MyClass {
	fileprivate var filePrivateVariable: Int = 0
}

// Test warnings for pure function
func f() -> Bool? { return true }
// gryphon pure
func g() -> Bool? { return true }

if let a1 = f(), let a2 = g() { }
if let a4 = g(), let a3 = f() { }
if true, let a5 = g() { }
if true, let a6 = f() { }

// Warnings for impure arguments of pure functions
// gryphon pure
func f1(_ a: Int?) -> Int? { return nil }
func g1() -> Int? { return nil }
if let b = g1(), let c = f1(g1()) { }

// Test warnings for double optionals
let maybeInt: Int?? = 0
let whatever = maybeInt

// Test warnings for multiple super calls
class A {
	var x = 0

	init(x: Int) {
		self.x = x
	}
}

class B: A {
	init(y: Int) {
		if y == 10 {
			super.init(x: y)
		}
		else {
			super.init(x: 0)
		}
	}
}

// Test warnings on struct initializers
struct C {
	let c = 0

	init() { } // warning here
}

struct D {
	let d = 0

	class E {
		init() { } // no warning here
	}
}

// Test muting warnings
// gryphon mute
let noWarnings: [Int] = []

// No warnings for failing to match a call expression to a non-existent memberwise initializer
struct H {
	let i: Int

	// gryphon ignore
	init(_ i: Int) {
		self.i = i
	}
}

let j = H(1)

// No warnings for pure templates
class K {
	let k1: Int? = nil
	let k2: Int? = nil
}

func gryphonTemplates() {
	let _k: K = K()

	_ = _k.k1
	_ = /* gryphon pure */ GRYTemplate.call(.dot("_k", "k1"), [])

	_ = _k.k2 // gryphon pure
	_ = GRYTemplate.call(.dot("_k", "k2"), [])
}

let k = K()
if let l = k.k1, let m = k.k1 { }
if let l = k.k2, let m = k.k2 { }

func n() -> Int? { return nil }
if let o = n(), let p = /* gryphon pure */ n() { }

let q = ""
if let r = q.first, let s = q.first { }

if true, let b = /* gryphon pure */ nativeArray.first(where: { $0 == 0 }) { }

// Warnings for custom operators
// gryphon ignore
infix operator +++: AdditionPrecedence

// gryphon ignore
extension Int {
	static func +++ (left: Int, right: Int) -> Int {
		return left + 3 * right
	}
}

print(1 + 2 +++ 3 + 4)

// Warnings for legacy translation comments
// gryphon multiline
let foo = """
aaa
"""

let languageName = "swift" // gryphon value: \"kotlin\"

let foo1 = "" // gryphon ignore

protocol Foo { // gryphon annotation: open
}

func foo2() { // gryphon pure
}

let foo3 = "" // gryphon mute
