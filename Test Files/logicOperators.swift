let t = true
let f = false

//
var x = t || f
var y = t && f
print("\(x)")
print("\(y)")

//
x = f || f
y = f && f
print("\(x)")
print("\(y)")

//
print("\(t || t)")
print("\(t && t)")

//
print("\(true || false)")
print("\(true && false)")

//
x = true || false
print("\(x)")

//
var z = !x
print("\(z)")

z = !y
print("\(z)")

//
if x {
	print("true") // Will get printed
}

if !x {
	print("false") // Won't get printed
}

if t && (!f) || f {
	print("true") // Will get printed
}
