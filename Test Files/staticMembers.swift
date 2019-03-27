class A {
	var x = 0

	static func a() -> A {
		return A()
	}

	func b() -> A {
		return A()
	}

	static func c() -> A? {
		return A()
	}

	static func d() -> A? {
		return nil
	}

	func e() -> Int {
		print("Hello, world!")
		return 1
	}

	static func f() -> Int {
		return 1
	}
}

struct B {
	let x: Int

	init(x: Int) { // kotlin: ignore
		self.x = x
	}

	init?(string: String?) {
		guard let string = string else {
			return nil
		}

		switch string {
		case "A": self = B(x: 0)
		case "B": self = B(x: 0)
		case "C": self = B(x: 0)
		case "D": self = B(x: 0)
		case "E": self = B(x: 0)
		default: return nil
		}
	}
}

print(A.a().x)
print(A().b().x)

var a = A.c()
if let ac = a {
	print(ac.x)
}

a = A.d()
if let ad = a {
	print(ad.x)
}

print(A().e())
print(A.f())

print(B(x: 10))
print(B(string: "not supported"))
print(B(string: "A")!)
