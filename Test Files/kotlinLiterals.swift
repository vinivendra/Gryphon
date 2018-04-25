func GRYKotlinIgnoreNext() { }

func GRYKotlinLiteral(_ kotlinExpression: String) { }

func GRYKotlinLiteral<T>(_ swiftExpression: T, _ kotlinExpression: String) -> T {
	return swiftExpression
}

// Kotlin literals as expressions
let languageName = GRYKotlinLiteral("swift", "\"kotlin\"")
print("Hello from \(languageName)!")

let magicNumber = 40 + GRYKotlinLiteral(2, "5-3")
print(magicNumber)

// Kotlin literals as statements
GRYKotlinLiteral("println(\"This will be ignored by swift, but not by kotlin.\")")

// Ignore swift statements
GRYKotlinIgnoreNext()
import Foundation // There's no Foundation in kotlin

GRYKotlinIgnoreNext()
print("This will be ignored by kotlin, but not by swift.")

// Call something swift can't parse
let squareRoot = GRYKotlinLiteral(sqrt(9), "Math.sqrt(9.0)")
print(squareRoot)
