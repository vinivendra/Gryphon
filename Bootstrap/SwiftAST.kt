class SwiftAST {
	companion object {
		var horizontalLimitWhenPrinting: Int = Int.MAX_VALUE
	}

	val name: String
	val standaloneAttributes: MutableList<String>
	val keyValueAttributes: MutableMap<String, String>
	val subtrees: MutableList<SwiftAST>

	constructor(name: String, subtrees: MutableList<SwiftAST> = mutableListOf()) {
		this.name = name
		this.standaloneAttributes = mutableListOf()
		this.keyValueAttributes = mutableMapOf()
		this.subtrees = subtrees
	}

	constructor(
		name: String,
		standaloneAttributes: MutableList<String>,
		keyValueAttributes: MutableMap<String, String>,
		subtrees: MutableList<SwiftAST> = mutableListOf())
	{
		this.name = name
		this.standaloneAttributes = standaloneAttributes
		this.keyValueAttributes = keyValueAttributes
		this.subtrees = subtrees
	}

	operator internal fun get(key: String): String? {
		return keyValueAttributes[key]
	}

	operator internal fun set(key: String, newValue: String?) {
		println(newValue)
	}

	fun f() {
		val ast = SwiftAST(name = "",
			standaloneAttributes = mutableListOf(),
			keyValueAttributes = mutableMapOf(),
			subtrees = mutableListOf())
		println(ast["Bla"])
		ast["Bla"] = "hue"
	}
}
