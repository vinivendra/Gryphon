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

indirect enum GryphonType: CustomStringConvertible, Equatable {
	case named(String)
	case optional(GryphonType)
	case tuple([GryphonType])
	case function(parameters: [GryphonType], returnType: GryphonType)
	case generic(typeName: GryphonType, genericArguments: [GryphonType])
	case dot(left: GryphonType, right: String)

	var description: String {
		switch self {
		case let .named(typeName: typeName):
			return typeName
		case let .optional(subType: subType):
			switch subType {
			case .function:
				return "(\(subType))?"
			default:
				return "\(subType)?"
			}
		case let .tuple(subTypes: subTypes):
			let innerTypes = subTypes.map { $0.description }.joined(separator: ", ")
			return "(\(innerTypes))"
		case let .function(parameters: parameters, returnType: returnType):
			let parameterStrings = parameters.map { $0.description }.joined(separator: ", ")
			return "(\(parameterStrings)) -> \(returnType)"
		case let .generic(typeName: typeName, genericArguments: genericArguments):
			let genericStrings = genericArguments.map { $0.description }.joined(separator: ", ")
			return "\(typeName)<\(genericStrings)>"
		case let .dot(left: left, right: right):
			return "\(left).\(right)"
		}
	}
}
