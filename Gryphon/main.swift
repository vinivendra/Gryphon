// TODO: Automatically calculate -dump-ast from terminal output
// TODO: Move test.swift into the project directory, change absolute paths to be relative, change the project's location

import Foundation

var contents = """
(source_file
  (func_decl "foo(bar:baz:)" interface type='(Int, String) -> ()' access=internal
    (parameter_list
      (parameter "bar" apiName=bar type='Int' interface type='Int')
      (parameter "baz" apiName=baz type='String' interface type='String'))
    (brace_stmt
      (pattern_binding_decl
        (pattern_typed type='Int'
          (pattern_named type='Int' 'x')
          (type_ident
            (component id='Int' bind=Swift.(file).Int)))
        (call_expr implicit type='Int' location=test.swift:3:15 range=[test.swift:3:15 - line:3:15] nothrow arg_labels=_builtinIntegerLiteral:
          (constructor_ref_call_expr implicit type='(_MaxBuiltinIntegerType) -> Int' location=test.swift:3:15 range=[test.swift:3:15 - line:3:15] nothrow
            (declref_expr implicit type='(Int.Type) -> (_MaxBuiltinIntegerType) -> Int' location=test.swift:3:15 range=[test.swift:3:15 - line:3:15] decl=Swift.(file).Int.init(_builtinIntegerLiteral:) function_ref=single)
            (type_expr implicit type='Int.Type' location=test.swift:3:15 range=[test.swift:3:15 - line:3:15] typerepr='Int'))
          (tuple_expr implicit type='(_builtinIntegerLiteral: Int2048)' location=test.swift:3:15 range=[test.swift:3:15 - line:3:15] names=_builtinIntegerLiteral
            (integer_literal_expr type='Int2048' location=test.swift:3:15 range=[test.swift:3:15 - line:3:15] value=0))))

      (var_decl "x" type='Int' interface type='Int' access=private storage_kind=stored)
)))
"""

////////////////////////////////////////////////////////////////////////////////

func main() {
	print("-- Gryphon AST --")
	let ast = GRYAst(fileContents: contents)
	ast.prettyPrint()
	
	print()
}

main()
