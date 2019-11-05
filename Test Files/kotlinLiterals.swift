//
// Copyright 2018 Vinícius Jorge Vendramini
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

// gryphon output: Test Files/Bootstrap Outputs/kotlinLiterals.swiftAST
// gryphon output: Test Files/Bootstrap Outputs/kotlinLiterals.gryphonASTRaw
// gryphon output: Test Files/Bootstrap Outputs/kotlinLiterals.gryphonAST
// gryphon output: Test Files/Bootstrap Outputs/kotlinLiterals.kt

////////////////////////////////////////////////////////////////////////////////////////////////////

// Insert code at the beginning of the file
// insert: println(\"Inserting at the beginning of the file\")

// Test imports in kotlin
// declaration: import java.util.*
// declaration:
// declaration: fun myFunction(): String {
// declaration: 	return \"Calling myFunction()\" // \\n \\t \\
// declaration: }

////////////////////////////////////////////////////////////////////////////////////////////////////
import Foundation

// Kotlin literals as expressions
let languageName = "swift" // value: \"kotlin\"
print("Hello from \(languageName)!")

let magicNumber: Int = 40 + // value: 40 + 5-3
	2 // value: this comment will be ignored
print(magicNumber)

func f(a: Int = 0,
	   b: Int = 0 // value: 1
	) {
	print(a + b)
}

f(a: 0,
  b: 0 // value: 1
)

////////////////////////////////////////////////////////////////////////////////////////////////////
// Kotlin literals as statements
// insert: println(\"This will be ignored by swift, but not by kotlin.\")
// insert:
// insert: println(myFunction())
// insert: println(myOtherFunction())

////////////////////////////////////////////////////////////////////////////////////////////////////
// Ignore swift statements
print("This will be ignored by kotlin, but not by swift.") // kotlin: ignore

////////////////////////////////////////////////////////////////////////////////////////////////////
// Call something swift can't parse
let squareRoot = sqrt(9) // value: Math.sqrt(9.0)
print(squareRoot)

////////////////////////////////////////////////////////////////////////////////////////////////////
// Ignore a swift declaration
class IgnoredClass // kotlin: ignore
{
}
enum IgnoredEnum // kotlin: ignore
{
}
enum IgnoredStruct // kotlin: ignore
{
}

func a() { // kotlin: ignore
}

////////////////////////////////////////////////////////////////////////////////////////////////////
// Add annotations to a property
protocol A {
	var x: Int { get }
	var y: Int { get }
}

class B: A {
	var x: Int = 1 // annotation: override
	var y: Int = // annotation: override
		2 // value: 3
	var z: Int = 0
}

print(B().x)
print(B().y)

////////////////////////////////////////////////////////////////////////////////////////////////////
// Test inserts and declarations
if true {
	// insert: println(\"if 1\")
	print("if 2")
	// insert: println(\"if 3\")
	print("if 4")
	// insert: println(\"if 5\")
}

for i in [1] {
	// insert: println(\"for 1\")
	print("for 2")
	// insert: println(\"for 3\")
	print("for 4")
	// insert: println(\"for 5\")
}

func insertFunction() {
	// insert: println(\"func 1\")
	print("func 2")
	// insert: println(\"func 3\")
	print("func 4")
	// insert: println(\"func 5\")
}
insertFunction()

class InsertClass {
	// insert: var a: String = \"class a\"
	var b: String = "class b"
	// insert: var c: String = \"class c\"
	var d: String = "class d"
	// insert: var e: String = \"class e\"

	func insertMethod() {
		// insert: println(\"method 1\")
		print("method 2")
		// insert: println(\"method 3\")
		print("method 4")
		// insert: println(\"method 5\")
	}
}
let insertClass = InsertClass()
// insert: println(insertClass.a)
// insert: println(insertClass.b)
// insert: println(insertClass.c)
// insert: println(insertClass.d)
// insert: println(insertClass.e)
insertClass.insertMethod()


////////////////////////////////////////////////////////////////////////////////////////////////////
// Insert code at the end of the file

// insert: println(\"Code at the end of file.\")

// declaration: fun myOtherFunction(): String {
// declaration: 	return \"Calling myOtherFunction()\" // \\n \\t \\
// declaration: }
