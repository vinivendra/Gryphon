func GRYIgnoreNext() { }

func GRYInsert(_ kotlinExpression: String) { }

func GRYAlternative<T>(swift swiftExpression: T, kotlin kotlinExpression: String) -> T {
	return swiftExpression
}

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
