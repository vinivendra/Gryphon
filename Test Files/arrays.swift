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

protocol GRYIgnore { }

/// According to http://swiftdoc.org/v3.0/type/Array/hierarchy/
/// (link found via https://www.raywenderlich.com/139591/building-custom-collection-swift)
/// the Array type in Swift conforms exactly to these protocols,
/// plus CustomReflectable (which is beyond Gryphon's scope for now).
class ArrayReference<Element>: GRYIgnore,
	ExpressibleByArrayLiteral, CustomStringConvertible, CustomDebugStringConvertible, RandomAccessCollection, MutableCollection, RangeReplaceableCollection
{
	typealias ArrayLiteralElement = Element
	
	//
	var array: Array<Element>
	
	init(array: Array<Element>) {
		self.array = array
	}
	
	// Expressible By Array Literal
	required init(arrayLiteral elements: Element...) {
		self.array = elements
	}
	
	//
	subscript (_ index: Int) -> Element {
		get {
			return array[index]
		}
		set {
			array[index] = newValue
		}
	}
	
	// Custom (Debug) String Convertible
	var description: String {
		return array.description
	}
	
	var debugDescription: String {
		return array.debugDescription
	}
	
	// Collection
	var startIndex: Int {
		return array.startIndex
	}
	
	var endIndex: Int {
		return array.endIndex
	}
	
	func index(after i: Int) -> Int {
		return i + 1
	}
	
	// Bidirectional Collection
	func index(before i: Int) -> Int {
		return i - 1
	}
	
	// Range Replaceable Collection
	func append<S>(contentsOf newElements: S) where S : Sequence, Element == S.Element {
		self.array.append(contentsOf: newElements)
	}
	
	required init<S>(_ elements: S) where S : Sequence, Element == S.Element {
		self.array = Array<Element>(elements)
	}
	
	required init() {
		self.array = Array<Element>()
	}
}

let array1: ArrayReference = [1, 2, 3]
let array2 = array1
array1[0] = 10
print(array1)
print(array2)
print(array2[0])

for i in array1 {
	print(i)
}

for j in array2 {
	print(j)
}

for i in array1 {
	for j in array2 {
		print("\(i), \(j)")
	}
}
