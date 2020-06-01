
class Template { // gryphon ignore
	static func dot(_ left: Template, _ right: String) -> DotTemplate {
		return DotTemplate(left, right)
	}

	static func dot(_ left: String, _ right: String) -> DotTemplate {
		return DotTemplate(LiteralTemplate(string: left), right)
	}

	static func call(_ function: Template, _ parameters: [ParameterTemplate]) -> CallTemplate {
		return CallTemplate(function, parameters)
	}

	static func call(_ function: String, _ parameters: [ParameterTemplate]) -> CallTemplate {
		return CallTemplate(function, parameters)
	}
}

class DotTemplate: Template { // gryphon ignore
	let left: Template
	let right: String

	init(_ left: Template, _ right: String) {
		self.left = left
		self.right = right
	}
}

class CallTemplate: Template { // gryphon ignore
	let function: Template
	let parameters: [ParameterTemplate]

	init(_ function: Template, _ parameters: [ParameterTemplate]) {
		self.function = function
		self.parameters = parameters
	}

	//
	init(_ function: String, _ parameters: [ParameterTemplate]) {
		self.function = LiteralTemplate(string: function)
		self.parameters = parameters
	}
}

class ParameterTemplate: ExpressibleByStringLiteral { // gryphon ignore
	let label: String?
	let template: Template

	private init(_ label: String?, _ template: Template) {
		if let existingLabel = label {
			if existingLabel == "_" || existingLabel == "" {
				self.label = nil
			}
			else {
				self.label = label
			}
		}
		else {
			self.label = label
		}

		self.template = template
	}

	required init(stringLiteral: String) {
		self.label = nil
		self.template = LiteralTemplate(string: stringLiteral)
	}

	static func labeledParameter(_ label: String?, _ template: Template) -> ParameterTemplate {
		return ParameterTemplate(label, template)
	}

	static func labeledParameter(_ label: String?, _ template: String) -> ParameterTemplate {
		return ParameterTemplate(label, LiteralTemplate(string: template))
	}

	static func dot(_ left: Template, _ right: String) -> ParameterTemplate {
		return ParameterTemplate(nil, DotTemplate(left, right))
	}

	static func dot(_ left: String, _ right: String) -> ParameterTemplate {
		return ParameterTemplate(nil, DotTemplate(LiteralTemplate(string: left), right))
	}

	static func call(_ function: Template, _ parameters: [ParameterTemplate]) -> ParameterTemplate {
		return ParameterTemplate(nil, CallTemplate(function, parameters))
	}

	static func call(_ function: String, _ parameters: [ParameterTemplate]) -> ParameterTemplate {
		return ParameterTemplate(nil, CallTemplate(function, parameters))
	}
}

class LiteralTemplate: Template { // gryphon ignore
	let string: String

	init(string: String) {
		self.string = string
	}
}

func gryphonTemplates() {

	_ = [1, 2, 3].first.map { $0 }
	_ = Template.call(.dot(.dot("[1, 2, 3]", "first"), "map"), ["{ $0 }"])

//	_ = print("")
//	_ = "MyClass"․"_array"․"map"⟮"closure2"∶"_closure2"、"closure3"∶"_closure3"⟯․"map"⟮"closure2"∶"_closure2"、"closure3"∶"_closure3"⟯
}
