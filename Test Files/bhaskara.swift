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

import Foundation

func bhaskara(a: Double, b: Double, c: Double) -> Double {
	let delta = b*b - 4*a*c
	let deltaRoot = sqrt(delta)
	let root1 = (-b + deltaRoot) / (2*a)
	return root1
}

print(bhaskara(a: 1, b: 0, c: -9))
