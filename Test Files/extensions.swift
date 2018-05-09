extension String {
	var isString: Bool {
		return true
	}
	
	var world: String {
		return "World!"
	}
}

print("\("Hello!".isString)")
print("\("Hello!".world)")
