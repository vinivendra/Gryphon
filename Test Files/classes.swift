class Box {
	var a: Int = 5
	
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
