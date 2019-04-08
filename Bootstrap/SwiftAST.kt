class SwiftAST: PrintableAsTree {
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

	override val treeDescription: String
		get() {
			return name
		}
	override val printableSubtrees: MutableList<PrintableAsTree?>
		get() {
			val keyValueStrings: MutableList<PrintableTree> = keyValueAttributes.map({ "${it.key} → ${it.value}" }).sorted().map { PrintableTree(it) }.toMutableList()
			val keyValueArray: MutableList<PrintableAsTree?> = keyValueStrings as MutableList<PrintableAsTree?>
			val standaloneAttributesArray: MutableList<PrintableAsTree?> = standaloneAttributes.map { PrintableTree(it) }.toMutableList() as MutableList<PrintableAsTree?>
			val subtreesArray: MutableList<PrintableAsTree?> = subtrees as MutableList<PrintableAsTree?>

			val result = (standaloneAttributesArray + keyValueArray + subtreesArray)
				.toMutableList()

			return result
		}
}
