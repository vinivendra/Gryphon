//
if true {
	print("Hi!")
}

if false {
	print("Bye!")
}

//
func trueFunction() -> Bool {
	return true
}

if trueFunction() {
	print("Hi again!")
}

//
if trueFunction() {
	print("Hello!")
}
else if trueFunction() {
	print("Oops, almost!")
}
else if trueFunction() {
	print("Not quite...")
}
else {
	print("Bye!")
}
