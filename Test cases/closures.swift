//
// Copyright 2018 Vinicius Jorge Vendramini
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

// gryphon output: Test cases/Bootstrap Outputs/closures.swiftAST
// gryphon output: Test cases/Bootstrap Outputs/closures.gryphonASTRaw
// gryphon output: Test cases/Bootstrap Outputs/closures.gryphonAST
// gryphon output: Test cases/Bootstrap Outputs/closures.kt

let printClosure: (String) -> () = { print($0) }
printClosure("Hello, world!")

let plusClosure: (Int, Int) -> Int = { a, b in return a + b }
print(plusClosure(2, 3))

func useClosure(closure: (String) -> ()) {
	closure("Calling from function!")
}
useClosure(closure: printClosure)

func defaultClosure(closure: (String) -> () = { print($0) }) {
	closure("Calling from default closure!")
}
defaultClosure()

let multiLineClosure: (Int) -> () = { a in
	if a == 10 {
		print("It's ten!")
	}
	else {
		print("It's not ten.")
	}
}
multiLineClosure(10)
multiLineClosure(20)

