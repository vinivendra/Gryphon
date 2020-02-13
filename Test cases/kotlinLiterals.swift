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
// insertInMain: println(\"Inserting at the beginning of the file\")

// Test imports in kotlin
// insert: import java.util.*
// insert:
// insert: fun myFunction(): String {
// insert: 	return \"Calling myFunction()\" // \\n \\t \\
// insert: }

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
// insertInMain: println(\"This will be ignored by swift, but not by kotlin.\")
// insertInMain:
// insertInMain: println(myFunction())
// insertInMain: println(myOtherFunction())

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
	// insertInMain: println(\"if 1\")
	print("if 2")
	// insertInMain: println(\"if 3\")
	print("if 4")
	// insertInMain: println(\"if 5\")
}

for i in [1] {
	// insertInMain: println(\"for 1\")
	print("for 2")
	// insertInMain: println(\"for 3\")
	print("for 4")
	// insertInMain: println(\"for 5\")
}

func insertFunction() {
	// insertInMain: println(\"func 1\")
	print("func 2")
	// insertInMain: println(\"func 3\")
	print("func 4")
	// insertInMain: println(\"func 5\")
}
insertFunction()

class InsertClass {
	// insertInMain: var a: String = \"class a\"
	var b: String = "class b"
	// insertInMain: var c: String = \"class c\"
	var d: String = "class d"
	// insertInMain: var e: String = \"class e\"

	func insertMethod() {
		// insertInMain: println(\"method 1\")
		print("method 2")
		// insertInMain: println(\"method 3\")
		print("method 4")
		// insertInMain: println(\"method 5\")
	}
}
let insertClass = InsertClass()
// insertInMain: println(insertClass.a)
// insertInMain: println(insertClass.b)
// insertInMain: println(insertClass.c)
// insertInMain: println(insertClass.d)
// insertInMain: println(insertClass.e)
insertClass.insertMethod()


////////////////////////////////////////////////////////////////////////////////////////////////////
// Insert code at the end of the file

// insertInMain: println(\"Code at the end of file.\")

// insert: fun myOtherFunction(): String {
// insert: 	return \"Calling myOtherFunction()\" // \\n \\t \\
// insert: }
