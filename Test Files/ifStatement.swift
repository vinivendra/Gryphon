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
func testGuard() {
	let x = 0
	guard x == 0 else {
		print("--")
		return
	}
	print("Guard")
}
testGuard()

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

if var d = x, let e = y, let f = bla(), x == 0 {
	print("\(d), \(e), \(f), \(x!)")
	print("If let #4")
}
else if x == 1 {
	print("--")
}
else {
	print("--")
}
