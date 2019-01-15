# Library Templates

The library templates work as follows:

- First, all template files in the Library Templates folder are loaded. The template files are Swift files structured as:
   - Variable declarations, that will be ignored;
   - Pairs of expressions and string patterns.

- The pairs represent expressions that will be searched for in the source files, and the strings that should replace them in the translations. The expressions may contain variables that start with an underscore; these variables don't need to appear literally in the source code. Instead, they will match any expression of the same type (i.e. `String` variables match any expression with a `String` type). If these variables are matched, the match will be recorded. Any occurrences of the variables in the string will then be replaced with the matched expression.

## Example

Say there's a template file as follows:

```` Swift
// Variable declarations
let _string: String

// Template
_string.count     // The pattern that will be looked for in the source code
"_string.length"  // The string that will replace the pattern when it's found
````

The pattern `_string.count` includes a variable `_string` that starts with a `_`. Therefore, the source code doesn't need to include the pattern literally. It can include, for instance, `functionThatReturnsAString().count`. Since the `_string` variable is a `String` and the `functionThatReturnsAString()` is also typed as a `String`, the pattern will be detected. The transpiler will record that the `_string` variable was matched by the `functionThatReturnsAString()` expression and will use that in the translation. Therefore, instead of translating the pattern literally as `_string.length`, it will replace the variable with the expression and translate it as `functionThatReturnsAString().length`.



