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

// gryphon output: Test files/Test cases/Bootstrap Outputs/functionCalls.swiftAST
// gryphon output: Test files/Test cases/Bootstrap Outputs/functionCalls.gryphonASTRaw
// gryphon output: Test files/Test cases/Bootstrap Outputs/functionCalls.gryphonAST
// gryphon output: Test files/Test cases/Bootstrap Outputs/functionCalls.kt

////////////////////////////////////////////////////////////////////////////////////////////////////
// Function definitions

// Empty function
func definition1() {
}

// With a body
func definition2() {
	var x: Int = 0
}

// With parameters
func definition3(x: Int, y: Int) {
}

// With a return type
func definition4() -> Int {
	return 0
}

// Single-expression func
func definition5() -> Int {
	5
}

func aaaaaaaaaaaaa(bbbbbbbbbbbbbbbb: Int, ccccccccccccc: Int, ddddddddddddddddddddddddd: Int, eeeeeeeeeee: Int) -> String {
	"abc"
}

func d() -> String {
	aaaaaaaaaaaaa(bbbbbbbbbbbbbbbb: 0, ccccccccccccc: 0, ddddddddddddddddddddddddd: 0, eeeeeeeeeee: 0)
}

////////////////////////////////////////////////////////////////////////////////////////////////////
// Function calls without return types

func foo() { }
func foo1(bar: Int) { }
func foo2(_ bar: Int) { }
func foo3(bar: Int, baz: Int) { }
func foo4(_ bar: Int, baz: Int) { }
//func foo5(bar: Int, _ baz: Int) { }
func foo6(_ bar: Int, _ baz: Int) { }

foo()
foo1(bar: 0)
foo2(0)
foo3(bar: 0, baz: 0)
foo4(0, baz: 0)
// foo5(bar: 0, 0) // Results in Kotlin error: mixing named and positioned arguments is not allowed
foo6(0, 0)

////////////////////////////////////////////////////////////////////////////////////////////////////
// Function calls with return types
func bla() -> Int { return 0 }
func bla1(bar: Int) -> Int { return 1 }
func bla2(_ bar: Int) -> Int { return 2 }
func bla3(bar: Int, baz: Int) -> Int { return 3 }
func bla4(_ bar: Int, baz: Int) -> Int { return 4 }
//func bla5(bar: Int, _ baz: Int) -> Int { return 5 }
func bla6(_ bar: Int, _ baz: Int) -> Int { return 6 }

print("\(bla())")
print("\(bla1(bar: 0))")
print("\(bla2(0))")
print("\(bla3(bar: 0, baz: 0))")
print("\(bla4(0, baz: 0))")
// print("\(bla5(bar: 0, 0))") // Results in Kotlin error: mixing named and positioned arguments is not allowed
print("\(bla6(0, 0))")

////////////////////////////////////////////////////////////////////////////////////////////////////
// Function calls with parameters with default values
func bar1(a: Int = 1) { }
func bar2(a: Int = 1, b: Int = 2) { }
func bar3(a: Int = 1, b: Int) { }
func bar4(a: Int, b: Int = 2) { }

bar1()
bar1(a: 0)

bar2()
bar2(a: 0)
bar2(b: 0)
bar2(a: 0, b: 0)

bar3(b: 0)
bar3(a: 0, b: 0)

bar4(a: 0)
bar4(a: 0, b: 0)

////////////////////////////////////////////////////////////////////////////////////////////////////
// Calls to optional functions
var baz: (() -> ())? = nil
baz?()

class A {
	var baz: (() -> ())? = nil
}
A().baz?()

let a: A? = nil
a?.baz?()

////////////////////////////////////////////////////////////////////////////////////////////////////
// Tuple Shuffles
print("Testing tuple shuffles")
print("- Named parameters with default values")

func f(a: Int = 0, b: Int = 0, c: Int = 0) {
	print("\(a) \(b) \(c)")
}

f(a: 1)
f(b: 1)
f(a: 1, b: 1)
f(c: 1)
f(a: 1, c: 1)
f(b: 1, c: 1)
f(a: 1, b: 1, c: 1)

print("- Unnamed parameters with default values")

func f1(_ a: Int = 0, _ b: Int = 0, _ c: Int = 0) {
	print("\(a) \(b) \(c)")
}

f1(1)
f1(1, 1)
f1(1, 1, 1)

print("- Variadics and default values")

func variadics(a: Int, b: Int..., c: Int = 0) {
	print(a, terminator: "")
	for element in b {
		print(element, terminator: "")
	}
	print(c)
}

variadics(a: 1, b: 1, 2, 3, c: 1)
variadics(a: 1, b: 1, 2, 3)

print("- Trailing closures and default arguments")

func f2(a: Int = 0, b: (Int) -> () = { print($0) }) { }
f2 { print($0) }

////////////////////////////////////////////////////////////////////////////////////////////////////
// Function calls with many parameters
class AClassWithABigName { }

func fooBarBaz(
	someBigName: AClassWithABigName,
	anotherBigName: AClassWithABigName,
	yetAnEvenBiggerName: AClassWithABigName,
	aSmallerName: AClassWithABigName)
{
}
fooBarBaz(
	someBigName: AClassWithABigName(),
	anotherBigName: AClassWithABigName(),
	yetAnEvenBiggerName: AClassWithABigName(),
	aSmallerName: AClassWithABigName())

func fooFooBarBaz(
	someBigName: AClassWithABigName,
	anotherBigName: AClassWithABigName,
	yetAnEvenBiggerName: AClassWithABigName,
	aSmallerName: AClassWithABigName)
	-> AClassWithABigName
{
	return AClassWithABigName()
}
fooFooBarBaz(
	someBigName: AClassWithABigName(),
	anotherBigName: AClassWithABigName(),
	yetAnEvenBiggerName: AClassWithABigName(),
	aSmallerName: AClassWithABigName())

func fooFooBarBazFoo(
	someBigName: AClassWithABigName,
	anotherBigName: AClassWithABigName,
	yetAnEvenBiggerName: AClassWithABigName,
	aParameterWithADefaultValue: Int = 0,
	aSmallerName: AClassWithABigName)
	-> AClassWithABigName
{
	return AClassWithABigName()
}
fooFooBarBazFoo(
	someBigName: AClassWithABigName(),
	anotherBigName: AClassWithABigName(),
	yetAnEvenBiggerName: AClassWithABigName(),
	aSmallerName: AClassWithABigName())
fooFooBarBazFoo(
	someBigName: AClassWithABigName(),
	anotherBigName: AClassWithABigName(),
	yetAnEvenBiggerName: AClassWithABigName(),
	aParameterWithADefaultValue: 1,
	aSmallerName: AClassWithABigName())
