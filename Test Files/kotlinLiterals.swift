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
import Foundation

// Test imports in kotlin

// declaration: import java.util.*

// Test \n's, \t's and \\'s

// declaration:
// declaration: fun myFunction(): String {
// declaration: 	return \"Calling myFunction()\" // \\n \\t \\
// declaration: }

// Kotlin literals as expressions
let languageName = "swift" // value: \"kotlin\"
print("Hello from \(languageName)!")

let magicNumber: Int = 40 + // value: 40 + 5-3
	2 // value: this will be ignored
print(magicNumber)

func f(a: Int = 0,
	   b: Int = 0 // value: 1
	) {
	print(a + b)
}

f(a: 0,
  b: 0 // value: 1
)

// Kotlin literals as statements
// insert: println(\"This will be ignored by swift, but not by kotlin.\")
// insert:
// insert: myFunction()

// Ignore swift statements
print("This will be ignored by kotlin, but not by swift.") // kotlin: ignore

// Call something swift can't parse
let squareRoot = sqrt(9) // value: Math.sqrt(9.0)
print(squareRoot)

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

// Insert some code at the end of a file
// insert: println(\"Code at the end of file.\")
