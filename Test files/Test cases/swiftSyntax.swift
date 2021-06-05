//
// Copyright 2018 Vinicius Jorge Vendramini
//
// Licensed under the Hippocratic License, Version 2.1;
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://firstdonoharm.dev/version/2/1/license
//
// To the full extent allowed by law, this software comes "AS IS,"
// WITHOUT ANY WARRANTY, EXPRESS OR IMPLIED, and licensor and any other
// contributor shall not be liable to anyone for any damages or other
// liability arising from, out of, or in connection with the sotfware
// or this license, under any kind of legal claim.
// See the License for the specific language governing permissions and
// limitations under the License.
//

/// Tests for the SwiftSyntaxDecoder

// Operators
// - Multiplication over addition
1 + 2 * 3
1 * 2 + 3
// - Left associativity of addition
1 + 2 + 3
// - Parentheses
2 * (3 + 4)
// - Addition over casts
1 + 0 as Int
// - Conditional casts
0 as? Int
// - Prefix unary expressions
-1 + -2 * -3
// - Assignments over other operators
var x = 1 + 2
x = 1 + 2
// - Discarded assignments
_ = 1 + 2
// - Other operators over ternary expressions
0 == 1 ? 2 == 3 : 4 == 5
// - Ternary expressions over assignments
var y = true
y = 0 == 1 ? 2 == 3 : 4 == 5
