///*
//* Copyright 2018 Vinícius Jorge Vendramini
//*
//* Licensed under the Apache License, Version 2.0 (the "License");
//* you may not use this file except in compliance with the License.
//* You may obtain a copy of the License at
//*
//* http://www.apache.org/licenses/LICENSE-2.0
//*
//* Unless required by applicable law or agreed to in writing, software
//* distributed under the License is distributed on an "AS IS" BASIS,
//* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//* See the License for the specific language governing permissions and
//* limitations under the License.
//*/

/// According to https://swiftdoc.org/v4.2/type/dictionary/hierarchy/
/// the Dictionary type in Swift conforms exactly to these protocols,
/// plus CustomReflectable (which is beyond Gryphon's scope for now).
public final class DictionaryClass<Key, Value>: // kotlin: ignore
	ExpressibleByDictionaryLiteral, CustomStringConvertible, CustomDebugStringConvertible,
	Collection
	where Key: Hashable
{
	public typealias Buffer = [Key: Value]

	public var dictionary: Buffer

	public init(dictionary: Buffer) {
		self.dictionary = dictionary
	}

	public init<K, V>(_ dictionaryReference: DictionaryClass<K, V>) {
		self.dictionary = dictionaryReference.dictionary as! Buffer
	}

	public func copy() -> DictionaryClass<Key, Value> {
		return DictionaryClass(dictionary: dictionary)
	}

	// Expressible By Dictionary Literal
	public required init(dictionaryLiteral elements: (Key, Value)...) {
		self.dictionary = Buffer(uniqueKeysWithValues: elements)
	}

	// ...
	public subscript (_ key: Key) -> Value? {
		get {
			return dictionary[key]
		}
		set {
			dictionary[key] = newValue
		}
	}

	// Custom (Debug) String Convertible
	public var description: String {
		return dictionary.description
	}

	public var debugDescription: String {
		return dictionary.debugDescription
	}

	// Collection
	public typealias SubSequence = Slice<[Key: Value]>

	@inlinable public var startIndex: Buffer.Index {
		return dictionary.startIndex
	}

	@inlinable public var endIndex: Buffer.Index {
		return dictionary.endIndex
	}

	@inlinable
	public func index(after i: Buffer.Index) -> Buffer.Index
	{
		return dictionary.index(after: i)
	}

	@inlinable
	public func formIndex(after i: inout Buffer.Index) {
		dictionary.formIndex(after: &i)
	}

	@inlinable
	public func index(forKey key: Key) -> Buffer.Index? {
		return dictionary.index(forKey: key)
	}

	@inlinable
	public subscript(position: Buffer.Index) -> Buffer.Element {
		return dictionary[position]
	}

	@inlinable public var count: Int {
		return dictionary.count
	}

	@inlinable public var isEmpty: Bool {
		return dictionary.isEmpty
	}
}

extension DictionaryClass: Equatable where Value: Equatable { // kotlin: ignore
	public static func == (
		lhs: DictionaryClass, rhs: DictionaryClass) -> Bool
	{
		return lhs.dictionary == rhs.dictionary
	}
}

extension DictionaryClass: Hashable where Value: Hashable { // kotlin: ignore
	public func hash(into hasher: inout Hasher) {
		dictionary.hash(into: &hasher)
	}
}

extension DictionaryClass: Codable where Key: Codable, Value: Codable { // kotlin: ignore
	public func encode(to encoder: Encoder) throws {
		try dictionary.encode(to: encoder)
	}

	public convenience init(from decoder: Decoder) throws {
		try self.init(dictionary: Buffer(from: decoder))
	}
}

// Traditional dictionaries
let dictionaryA = ["a": 1, "b": 2, "c": 3]
let dictionaryB: [Int: Int] = [:]

print(dictionaryA["a"])
print(dictionaryA["b"])
print(dictionaryA["c"])
print(dictionaryA["d"])

print(dictionaryB[0])

// Dictionary references
let dictionary1: DictionaryClass = ["a": 1, "b": 2, "c": 3]
let dictionary2 = dictionary1
dictionary1["a"] = 10

print(dictionary1["a"])
print(dictionary1["b"])
print(dictionary1["c"])
print(dictionary1["d"])

print(dictionary2["a"])
print(dictionary2["b"])
print(dictionary2["c"])
print(dictionary2["d"])

let dictionary3: DictionaryClass<String, Int> = [:]

print(dictionary3["a"])
print(dictionary3["d"])
