/*
* Copyright 2018 Vinícius Jorge Vendramini
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

// Function calls without return types
func foo() { }
func foo1(bar: Int) { }
func foo2(_ bar: Int) { }
func foo3(bar: Int, baz: Int) { }
func foo4(_ bar: Int, baz: Int) { }
//func foo5(bar: Int, _ baz: Int) { }
func foo6(_ bar: Int, _ baz: Int) { }

foo()
foo1(bar: 0)
foo2(0)
foo3(bar: 0, baz: 0)
foo4(0, baz: 0)
// foo5(bar: 0, 0) // Results in Kotlin error: mixing named and positioned arguments is not allowed
foo6(0, 0)



// Function calls with return types
func bla() -> Int { return 0 }
func bla1(bar: Int) -> Int { return 1 }
func bla2(_ bar: Int) -> Int { return 2 }
func bla3(bar: Int, baz: Int) -> Int { return 3 }
func bla4(_ bar: Int, baz: Int) -> Int { return 4 }
//func bla5(bar: Int, _ baz: Int) -> Int { return 5 }
func bla6(_ bar: Int, _ baz: Int) -> Int { return 6 }

print("\(bla())")
print("\(bla1(bar: 0))")
print("\(bla2(0))")
print("\(bla3(bar: 0, baz: 0))")
print("\(bla4(0, baz: 0))")
// print("\(bla5(bar: 0, 0))") // Results in Kotlin error: mixing named and positioned arguments is not allowed
print("\(bla6(0, 0))")

// Function calls with parameters with default values
func bar1(a: Int = 1) { }
func bar2(a: Int = 1, b: Int = 2) { }
func bar3(a: Int = 1, b: Int) { }
func bar4(a: Int, b: Int = 2) { }

bar1()
bar1(a: 0)

bar2()
bar2(a: 0)
bar2(b: 0)
bar2(a: 0, b: 0)

bar3(b: 0)
bar3(a: 0, b: 0)

bar4(a: 0)
bar4(a: 0, b: 0)

// Function calls with many parameters
func fooBarBaz(a: Int, b: Int, c: Int, d: Int)
fooBarBaz(a: 0, b: 0, c: 0, d: 0)
