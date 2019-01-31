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
