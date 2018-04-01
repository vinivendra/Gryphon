import Foundation

var contents = """
(source_file
  (func_decl "foo(bar:baz:)" interface type='(Int, String) -> ()' access=internal
    (parameter_list
      (parameter "bar" apiName=bar type='Int' interface type='Int')
      (parameter "baz" apiName=baz type='String' interface type='String'))
    (brace_stmt)))
"""

////////////////////////////////////////////////////////////////////////////////

func main() {
	print("-- Swift AST --")
	let root = GRYDynamicAst(fileContents: contents)
	root.prettyPrint()
	
	print("\n-- Gryphon AST --")
	let ast = GRYAst(fileContents: contents)
	ast.prettyPrint()
	
	print()
}

main()
