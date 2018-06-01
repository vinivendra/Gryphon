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

func GRYIgnoreNext() { }

func GRYInsert(_ kotlinExpression: String) { }

func GRYAlternative<T>(swift swiftExpression: T, kotlin kotlinExpression: String) -> T {
	return swiftExpression
}

protocol GRYIgnore { }

//
import Foundation

private func GRYDeclarations() {
	// Just to test imports in kotlin
	GRYInsert("import java.util.*")
}

// Kotlin literals as expressions
let languageName = GRYAlternative(swift: "swift", kotlin: "\"kotlin\"")
print("Hello from \(languageName)!")

let magicNumber = 40 + GRYAlternative(swift: 2, kotlin: "5-3")
print(magicNumber)

// Kotlin literals as statements
GRYInsert("println(\"This will be ignored by swift, but not by kotlin.\")")

// Ignore swift statements
GRYIgnoreNext()
print("This will be ignored by kotlin, but not by swift.")

// Call something swift can't parse
let squareRoot = GRYAlternative(swift: sqrt(9), kotlin: "Math.sqrt(9.0)")
print(squareRoot)

// Ignore a swift class or an enum
class IgnoredClass: GRYIgnore { }
enum IgnoredEnum: GRYIgnore { }

