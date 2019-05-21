//
// Copyright 2018 Vinícius Jorge Vendramini
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

let x = 0
let y = x + 1
let z = 2 + 3

print(x)
print(y)
print(z)

//
let multiplication = 0 * 1
let division = 10 / 2
let subtraction = 3 - 1
let sum = 4 + 1

print(multiplication)
print(division)
print(subtraction)
print(sum)

// Without spaces
let multiplication2 = 0*1
let division2 = 10/2
let subtraction2 = 3-1
let sum2 = 4+1

print(multiplication2)
print(division2)
print(subtraction2)
print(sum2)

// With negative numbers
var multiplication3 = 0 * -1
var division3 = -10 / 2
var subtraction3 = -3 - 1
var sum3 = 4 + -1

print(multiplication3)
print(division3)
print(subtraction3)
print(sum3)

// In assignments (as opposed to variable declarations)
multiplication3 = 1 * 2
division3 = 1 / 2
subtraction3 = 1 - 2
sum3 = 1 + 2

print(multiplication3)
print(division3)
print(subtraction3)
print(sum3)

// Equality
if x == 0 {
	print("true")
}

if x == 1 {
	print("false")
}

if x != 1 {
	print("true")
}
