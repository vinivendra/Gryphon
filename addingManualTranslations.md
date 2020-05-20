---
layout: tutorialLayout
---

# Adding manual translations

The last step in developing our Model is adding the ability to shuffle the deck. We'll do that by adding the method below to the `Model` class:

```` swift
    func shuffleDeck() {
        guard !deck.isEmpty else {
            return
        }

        let currentDeck = self.deck
        let n = currentDeck.count
        for i in 1..<n {
            let index = n - i
            let random = Int.random(in: 0...index)
            let temp = deck[index]
            deck[index] = deck [random]
            deck[random] = temp
        }
    }
````

Switch to the Gryphon target and translate the model with **⌘+B**. Gryphon will raise a warning:

![Warning: Reference to standard library "random(in:)" was not translated.](assets/images/iOS/ios10.png)

This happens because Gryphon doesn't yet support the new `random` methods from the Swift standard library.

This statement could be translated to Kotlin as `(0..index).random()`; we can teach Gryphon to do that in two ways:

#### Method 1: Translation comments

Remember the `// gryphon insert:` comment we added to the beginning of the file a few steps ago? That's an example of a *translation comment* - a special kind of comment that can be used to insert code, remove it, change it, etc. We can use a similar translation comment, `// gryphon value:`, to manually specify the value we want to use for the `random` variable:

```` swift
let random = Int.random(in: 0...index) // gryphon value: (0..10).random()
````

If you try translating this code again (**⌘+B** on the Gryphon target), you'll see the warning's now gone and the Android app builds and runs successfully.

You can learn more about this and other translation comments in the [documentation](translationComments.html).

#### Method 2: Templates

Translation comments work well for dealing with unsupported methods that appear occasionally. If a method shows up too often, however, it might be better to use the more general solution of creating a *template*. Let's do that now for the `random` method above as a quick example - for more details, check out the [templates documentation](templates.html).

Start by declaring a new function called `gryphonTemplates` at the beginning of the `Model.swift` file:

```` swift
private func gryphonTemplates() {
    // Supporting variables
    let index: Int = 0

    // Template:
    Int.random(in: 0...index)
    // Translation:
    "(0..index).random()"
}
````

Here's what this function does:
- First, it declares an auxiliary `index` variable that we'll need to define our template.
- Then, it defines the template itself, which is the expression we want to translate - in this case, the `Int.random(in: 0...index)` expression. Every time Gryphon finds this expression in the code, it'll look up our translation and use it.
- Finally, it states the translation to be used, as a literal string.

This definition already works - if you remove the `// gryphon value:` comment from before, everything should translate and compile correctly. However, templates really shine when they can be used for different cases - this one will only work if we want a random number from `0` to `index`, since that's what we wrote. We can change that by replacing these hard coded values with variables that start with an underscore, which act as placeholders. Gryphon knows it can match underscored variables in templates to any expression of the same type.

Replace the `gryphonTemplates` function with the one below:

```` swift
private func gryphonTemplates() {
    // Supporting variables
    let _startNumber: Int = 0
    let _endNumber: Int = 0

    // Template:
    Int.random(in: _startNumber..._endNumber)
    // Translation:
    "(_startNumber.._endNumber).random()"
}
````

This template will work for any expression of the form `Int.random(in: _startNumber..._endNumber)`, no matter what values they use for `_startNumber` and `_endNumber` - so long as they're both `Ints`. In particular, it will still match our `Int.random(in: 0...index)` expression, since both `0` and `index` are `Ints`.

The only remaining issue is that Swift is raising warnings for unused expressions. We can silence them with an empty assignment to `_`:

```` swift
// Template:
_ = Int.random(in: _startNumber..._endNumber)
// Translation:
_ = "(_startNumber.._endNumber).random()"
````

You should now be able to translate the code (**⌘+B** on the Gryphon target), build the iOS app (**⌘+B** on the MyAwesomeiOSApp target) and build the Android app (**⌘+B** on the Kotlin target), and everything should be working fine.

For more information on using templates, check out the [templates guide](templates.html).

## That's it!

This covers the basics on using Gryphon to share iOS code with Android. For more information, check out the docs on using Gryphon's [collections](collections.html), [translation comments](translationComments.html), and [templates](templates.html), or learn to use the [command line interface](translatingCommandLinePrograms.html). If you still have any doubts, [ask a question on Twitter](https://twitter.com/gryphonblog).

If you are interested in knowing how Gryphon works inside or contributing to it, check out [Contributing to Gryphon](contributing.html).



