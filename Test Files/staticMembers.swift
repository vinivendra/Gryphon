class A {
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

	func e() {
		print("Hello, world!")
	}

	static func f() -> Int {
		return 0
	}
}
