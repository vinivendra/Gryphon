//
// Copyright 2018 Vinicius Jorge Vendramini
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
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
let languageName = "swift" // gryphon value: \"kotlin\"
print("Hello from \(languageName)!")

let magicNumber: Int = 40 + // gryphon value: 40 + 5-3
	2 // gryphon value: this comment will be ignored
print(magicNumber)

func f(a: Int = 0,
	   b: Int = 0 // gryphon value: 1
	) {
	print(a + b)
}

f(a: 0,
  b: 0 // gryphon value: 1
)

////////////////////////////////////////////////////////////////////////////////////////////////////
// Kotlin literals as statements
// gryphon insertInMain: println(\"This will be ignored by swift, but not by kotlin.\")
// gryphon insertInMain:
// gryphon insertInMain: println(myFunction())
// gryphon insertInMain: println(myOtherFunction())

////////////////////////////////////////////////////////////////////////////////////////////////////
// Ignore swift statements
print("This will be ignored by kotlin, but not by swift.") // gryphon ignore

////////////////////////////////////////////////////////////////////////////////////////////////////
// Call something swift can't parse
let squareRoot = sqrt(9) // gryphon value: Math.sqrt(9.0)
print(squareRoot)

////////////////////////////////////////////////////////////////////////////////////////////////////
// Ignore a swift declaration
class IgnoredClass // gryphon ignore
{
}
enum IgnoredEnum // gryphon ignore
{
}
enum IgnoredStruct // gryphon ignore
{
}

func a() { // gryphon ignore
}

////////////////////////////////////////////////////////////////////////////////////////////////////
// Test annotations
protocol A {
	var x: Int { get }
	var y: Int { get }

	func foo()
}

class B: A {
	var x: Int = 1 // gryphon annotation: override
	var y: Int = // gryphon annotation: override
		2 // gryphon value: 3
	var z: Int = 0

	func foo() { } // gryphon annotation: override
}

print(B().x)
print(B().y)

protocol C { // gryphon annotation: open
}

enum D { // gryphon annotation: final
	case a
}

struct E { // gryphon annotation: final
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

class InsertClass {
	// gryphon insert: open var a: String = \"class a\"
	var b: String = "class b"
	// gryphon insert: open var c: String = \"class c\"
	var d: String = "class d"
	// gryphon insert: open var e: String = \"class e\"

	func insertMethod() {
		// gryphon insert: println(\"method 1\")
		print("method 2")
		// gryphon insert: println(\"method 3\")
		print("method 4")
		// gryphon insert: println(\"method 5\")
	}
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
