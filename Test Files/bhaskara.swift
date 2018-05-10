func GRYAlternative<T>(swift swiftExpression: T, kotlin kotlinExpression: String) -> T {
	return swiftExpression
}

import Foundation

func bhaskara(a: Double, b: Double, c: Double) -> Double {
	let delta = b*b - 4*a*c
	let deltaRoot = GRYAlternative(swift: sqrt(delta),
								   kotlin: "Math.sqrt(delta)")
	let root1 = (-b + deltaRoot) / (2*a)
	return root1
}

print(bhaskara(a: 1, b: 0, c: -9))
