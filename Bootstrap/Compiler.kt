class Compiler {
	companion object {
		val kotlinCompilerPath: String = if (OS.osName == "Linux") { "/opt/kotlinc/bin/kotlinc" } else { "/usr/local/bin/kotlinc" }
		var log: ((String) -> Unit) = { println(it) }

		public fun shouldLogProgress(value: Boolean) {
			if (value) {
				log = { println(it) }
			}
			else {
				log = { }
			}
		}
	}
}
