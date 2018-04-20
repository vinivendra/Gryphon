func foo() { }
func foo1(bar: Int) { }
func foo2(_ bar: Int) { }
func foo3(bar: Int, baz: Int) { }
func foo4(_ bar: Int, baz: Int) { }
func foo5(bar: Int, _ baz: Int) { }
func foo6(_ bar: Int, _ baz: Int) { }

foo()
foo1(bar: 0)
foo2(0)
foo3(bar: 0, baz: 0)
foo4(0, baz: 0)
// foo5(bar: 0, 0) // Results in Kotlin error: mixing named and positioned arguments is not allowed
foo6(0, 0)
