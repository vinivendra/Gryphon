//
// Copyright 2018 Vinicius Jorge Vendramini
//
// Licensed under the Hippocratic License, Version 2.1;
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://firstdonoharm.dev/version/2/1/license.md
//
// To the full extent allowed by law, this software comes "AS IS,"
// WITHOUT ANY WARRANTY, EXPRESS OR IMPLIED, and licensor and any other
// contributor shall not be liable to anyone for any damages or other
// liability arising from, out of, or in connection with the sotfware
// or this license, under any kind of legal claim.
// See the License for the specific language governing permissions and
// limitations under the License.
//

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
	// Will get printed
	print("true")
}

if !x {
	// Won't get printed
	print("false")
}

if t && (!f) || f {
	// Will get printed
	print("true")
}
