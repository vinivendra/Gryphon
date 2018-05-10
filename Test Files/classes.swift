class Box {
	var a: Int = 5
	
	var b: String {
		get {
			return "get b"
		}
		set {
			print("set b")
		}
	}
	
	var c: Int?
	
	func returnFive() -> Int {
		return a
	}
	
	func returnInt(a: Int) -> Int {
		return a
	}
}

let box1 = Box()

print(box1.a)
print(box1.returnFive())
print(box1.returnInt(a: 10))
print(box1.b)
box1.b = "whatever"
print(box1.c)
