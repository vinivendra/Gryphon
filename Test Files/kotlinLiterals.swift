func GRYKotlinLiteral(_ kotlinExpression: String) { }

func GRYKotlinLiteral<T>(_ swiftExpression: T, _ kotlinExpression: String) -> T {
	return swiftExpression
}

let languageName = GRYKotlinLiteral("swift", "\"kotlin\"")
print("Hello from \(languageName)!")
GRYKotlinLiteral("println(\"This will be ignored by swift, but not by kotlin.\")")
