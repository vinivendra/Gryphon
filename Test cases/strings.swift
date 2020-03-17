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

// gryphon output: Test cases/Bootstrap Outputs/strings.swiftAST
// gryphon output: Test cases/Bootstrap Outputs/strings.gryphonASTRaw
// gryphon output: Test cases/Bootstrap Outputs/strings.gryphonAST
// gryphon output: Test cases/Bootstrap Outputs/strings.kt

// String Literal
let x = "Hello, world!"
let y = "The string above is \(x)"
let z = 0
let w = "Here's another interpolated string: \(x), \(y) and \(z)"

let escapedString = "A string with \"escaped double quotes\" \\ and escaped backslashes \n\t and some escaped characters too."

let singleInterpolation = "\(x)"
let interpolationWithDoubleQuotes = "\"\"\(x)"

// Characters
let character: Character = "i"
