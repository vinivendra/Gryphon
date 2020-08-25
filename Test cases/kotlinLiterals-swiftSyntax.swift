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

// gryphon output: Test cases/Bootstrap Outputs/kotlinLiterals.swiftAST
// gryphon output: Test cases/Bootstrap Outputs/kotlinLiterals.gryphonASTRaw
// gryphon output: Test cases/Bootstrap Outputs/kotlinLiterals.gryphonAST
// gryphon output: Test cases/Bootstrap Outputs/kotlinLiterals.kt

////////////////////////////////////////////////////////////////////////////////////////////////////

// Insert code at the beginning of the file
// gryphon insertInMain: println(\"Inserting at the beginning of the file\")

// Test imports in kotlin
// gryphon insert: import java.util.*
// gryphon insert:
// gryphon insert: fun myFunction(): String {
// gryphon insert: 	return \"Calling myFunction()\" // \\n \\t \\
// gryphon insert: }

////////////////////////////////////////////////////////////////////////////////////////////////////
import Foundation

// Kotlin literals as expressions
let languageName = /* gryphon value: \"kotlin\" */ "swift"
print("Hello from \(languageName)!")

let magicNumber: Int = /* gryphon value: 40 + 5-3 */ 40 + 2
print(magicNumber)

func f(a: Int = 0, b: Int = /* gryphon value: 1 */ 0) {
	print(a + b)
}

f(a: 0, b: /* gryphon value: 1 */ 0)

////////////////////////////////////////////////////////////////////////////////////////////////////
// Kotlin literals as statements
// gryphon insertInMain: println(\"This will be ignored by swift, but not by kotlin.\")
// gryphon insertInMain:
// gryphon insertInMain: println(myFunction())
// gryphon insertInMain: println(myOtherFunction())

////////////////////////////////////////////////////////////////////////////////////////////////////
// Ignore swift statements
// gryphon ignore
print("This will be ignored by kotlin, but not by swift.")

////////////////////////////////////////////////////////////////////////////////////////////////////
// Call something swift can't parse
let squareRoot = /* gryphon value: Math.sqrt(9.0) */ sqrt(9)
print(squareRoot)

////////////////////////////////////////////////////////////////////////////////////////////////////
// Ignore a swift declaration
// gryphon ignore
class IgnoredClass
{
}

// gryphon ignore
enum IgnoredEnum
{
}

// gryphon ignore
enum IgnoredStruct
{
}

// gryphon ignore
func a() {
}

////////////////////////////////////////////////////////////////////////////////////////////////////
// Test annotations
protocol A {
	var x: Int { get }
	var y: Int { get }

	func foo()
}

class B: A {
	// gryphon annotation: override
	var x: Int = 1
	// gryphon annotation: override
	var y: Int = /* gryphon value: 3 */ 2
	var z: Int = 0

	// gryphon annotation: override
	func foo() { }
}

print(B().x)
print(B().y)

// gryphon annotation: open
protocol C {
}

// gryphon annotation: final
enum D {
	case a
}

// gryphon annotation: final
struct E {
	let a: Int = 0
}

////////////////////////////////////////////////////////////////////////////////////////////////////
// Test inserts and declarations
if true {
	// gryphon insert: println(\"if 1\")
	print("if 2")
	// gryphon insert: println(\"if 3\")
	print("if 4")
	// gryphon insert: println(\"if 5\")
}

for i in [1] {
	// gryphon insert: println(\"for 1\")
	print("for 2")
	// gryphon insert: println(\"for 3\")
	print("for 4")
	// gryphon insert: println(\"for 5\")
}

func insertFunction() {
	// gryphon insert: println(\"func 1\")
	print("func 2")
	// gryphon insert: println(\"func 3\")
	print("func 4")
	// gryphon insert: println(\"func 5\")
}
insertFunction()

var closure = {
	// gryphon insert: println(\"closure 1\")
	print("closure 2")
	// gryphon insert: println(\"closure 3\")
	print("closure 4")
	// gryphon insert: println(\"closure 5\")
}
closure()

class InsertClass {
	func insertMethod() {
		// gryphon insert: println(\"method 1\")
		print("method 2")
		// gryphon insert: println(\"method 3\")
		print("method 4")
		// gryphon insert: println(\"method 5\")
	}

	// gryphon insert: open var a: String = \"class a\"
	var b: String = "class b"
	// gryphon insert: open var c: String = \"class c\"
	var d: String = "class d"
	// gryphon insert: open var e: String = \"class e\"
}

let insertClass = InsertClass()
// gryphon insertInMain: println(insertClass.a)
// gryphon insertInMain: println(insertClass.b)
// gryphon insertInMain: println(insertClass.c)
// gryphon insertInMain: println(insertClass.d)
// gryphon insertInMain: println(insertClass.e)
insertClass.insertMethod()


////////////////////////////////////////////////////////////////////////////////////////////////////
// Insert code at the end of the file

// gryphon insertInMain: println(\"Code at the end of file.\")

// gryphon insert: fun myOtherFunction(): String {
// gryphon insert: 	return \"Calling myOtherFunction()\" // \\n \\t \\
// gryphon insert: }
