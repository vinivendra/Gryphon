---
layout: tutorialLayout
---

# Adding the Gryphon libraries

## Step 1: Generating the libraries

Both the Android errors and the Gryphon warnings have a common cause: we're not using Gryphon's libraries for our apps.

Gryphon tries to translate everything it can into equivalent Kotlin code. When it finds something it can't translate, it relies on custom libraries to fill the gaps. These libraries consist of two files: one for the iOS app, and one for the Android app.

Run the following command to generate them:

```` bash
$ gryphon generate-libraries
````

The two files will be created in the current directory.
- Add the `GryphonSwiftLibrary.swift` file to the iOS app by dragging it to Xcode, next to the `Model.swift` file in the left-hand sidebar;
- add the `GryphonKotlinLibrary.kt` file to the Android app by dragging it to Android Studio, to the folder that contains the `Model.kt` file in the left-hand sidebar.

The Kotlin library needs to know the name of our android app in order to compile successfully. Open it in Android Studio and replace the `package` statement at the top of the file with:

```` kotlin
package com.example.myawesomeandroidapp
````

## Step 2: Using the libraries

Now that both apps have access to the libraries, we can fix the code. Gryphon already clued us in on what the problem might be with its warning message: we're using native Swift `Arrays` instead of Gryphon's `Lists`.

Gryphon warns us of this problem because it knows this code might behave differently on Kotlin than on Swift. In fact, it does: the Kotlin version works, but the Swift version has a bug. We could see the problem if we tried using the model:

```` swift
let model = Model()
model.initializeDeck()
print("There are \(model.deck.count) cards in the deck.")
print("Drawing a \(model.draw()!)...")
print("Oh no, there are still \(model.deck.count) cards in the deck.")

// Prints:
// There are 52 cards in the deck.
// Drawing a 13♣️...
// Oh no, there are still 52 cards in the deck.
````

This happens because Swift's `Arrays` are passed by value, but Kotlin's `Lists` are passed by reference. There's a more detailed explanation of this problem (and of the reasoning behind its solution) [in the documentation](collections.html), but the solution here is pretty simple: open the `Model.swift` file in Xcode and switch the `deck`'s type from `Array<Card>` to `MutableList<Card>`.

```` swift
class Model {
    var deck: MutableList<Card> = []
````

Switch to the Gryphon target and translate the code with **⌘+B**. The warnings that showed up before should be gone now.

We might also want to turn the `currentDeck` variable into a `let` to silence the Swift warning that pops up:

```` swift
    func draw() -> Card? {
        let currentDeck = self.deck
        // ...
````

If we switch to the `MyAwesoneiOSApp` target and build it, it should build and run correctly, as should the Android app.

When programming with Gryphon, it's always recommended to use `Lists` or `MutableLists` instead of Swift `Arrays`, and `Maps` or `MutableMaps` instead of Swift `Dictionaries`. This can prevent compilation errors, as well as bugs like these that can be hard to track down. For more information on using `Lists` and `Maps`, see the [collections guide](collections.html).

---

*Next: [Adding manual translations](addingManualTranslations.html)*

