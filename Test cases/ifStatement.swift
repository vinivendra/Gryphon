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

// gryphon output: Test cases/Bootstrap Outputs/ifStatement.swiftAST
// gryphon output: Test cases/Bootstrap Outputs/ifStatement.gryphonASTRaw
// gryphon output: Test cases/Bootstrap Outputs/ifStatement.gryphonAST
// gryphon output: Test cases/Bootstrap Outputs/ifStatement.kt

//
if true {
	print("Simple if's")
}

if false {
	print("--")
}

//
func trueFunction() -> Bool {
	return true
}

if trueFunction() {
	print("If with a function")
}

//
if true {
	print("Simple, with empty else if and else")
}
else {
}

if true {
	print("Simple, with empty else if and else #2")
}
else if true {
}
else {
}

if true {
	print("Simple, with empty else if and else #3")
}
else if true {
}
else if true {
}
else {
}

//
if trueFunction() {
	print("Else if and else with contents")
}
else if trueFunction() {
	print("--")
}
else {
	print("--")
}

if trueFunction() {
	print("Else if and else with contents #2")
}
else if trueFunction() {
	print("--")
}
else if trueFunction() {
	print("--")
}
else {
	print("--")
}

//
if false {
	print("--")
}
else if true {
	print("Else if and else with contents that get executed")
}
else {
	print("--")
}

if false {
	print("--")
}
else if false {
	print("--")
}
else {
	print("Else if and else with contents that get executed #2")
}

//
func testGuards() {
	let x = 0
	guard x == 0 else {
		print("--")
		return
	}
	guard x != 1 else {
		print("--")
		return
	}
	guard !false else {
		print("--")
		return
	}
	print("Guard")
}
testGuards()

//
let x: Int? = 0
let y: Int? = 0
let z: Int? = nil

func bla() -> Int? { return 0 }

if let a = x {
	print("\(a)")
	print("If let")
}

if let b = x {
	print("\(b)")
	print("If let #2")
}
else if x == 0 {
	print("--")
}
else {
	print("--")
}

if let c = z {
	print("--")
}
else {
	print("\(z)")
	print("If let #3")
}

if let f = bla(), var d = x, let e = y, x == 0 {
	print("\(d), \(e), \(f), \(x!)")
	print("If let #4")
}
else if x == 1 {
	print("--")
}
else {
	print("--")
}

if let x = x {
	print("If let #5")
}

//
enum A {
	case a1
	case a2
}

enum B {
	case c(d: Int)
	case e(f: Int, g: String)
}

//
let aEnum1 = A.a1
let aEnum2 = A.a2

if case .a1 = aEnum1 {
	print("If case #1")
}

if case .a2 = aEnum1 {
	print("--")
}

if case .a1 = aEnum2 {
	print("--")
}

if case .a2 = aEnum2 {
	print("If case #2")
}

//
let bEnum = B.c(d: 0)
let bEnum2 = B.e(f: 0, g: "foo")

if case .c = bEnum {
	print("If case let #1")
}

if case let .c(d: foo) = bEnum {
	print("If case let #2: \(foo)")
}

if case let .e(f: foo, g: bar) = bEnum {
	print("--")
}

if case let .e(f: foo, g: bar) = bEnum2 {
	print("If case let #3: \(foo), \(bar)")
}

if case let .e(f: _, g: bar) = bEnum2 {
	print("If case let #4: \(bar)")
}

if case let .e(f: foo, g: _) = bEnum2 {
	print("If case let #5: \(foo)")
}

if case let .e(f: _, g: _) = bEnum2 {
	print("If case let #6")
}

if false {
	print("--")
}
else if case let .c(d: foo) = bEnum {
	print("If case let #7: \(foo)")
}
else if case let .e(f: foo, g: bar) = bEnum2 {
	print("--")
}

if false {
	print("--")
}
else if case let .e(f: foo, g: bar) = bEnum2 {
	print("If case let #8: \(foo), \(bar)")
}
else if case let .c(d: foo) = bEnum {
	print("--")
}

//
if case let .e(f: foo, g: "foo") = bEnum2 {
	print("If case let comparison #1: \(foo)")
}
if case let .e(f: 0, g: foo) = bEnum2 {
	print("If case let comparison #2: \(foo)")
}
if case let .e(f: foo, g: bar) = bEnum2 {
	print("If case let comparison #3: \(foo), \(bar)")
}

// Parentheses around or expressions
if true || true, false {
	print("--")
	if true || true, false {
		print("--")
	}
}
else if true || true, false {
	print("--")
}

if true || true && false {
	print("If case operator precedence")
}
