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

Now that both apps have access to the libraries, we can fix the code. If you switch to the `Gryphon` target, you'll see it already clued us in on what the problem might be with its warning message: we're using native Swift `Arrays` instead of Gryphon's `Lists`.

Gryphon warns us of this problem because it knows this code might behave differently in Kotlin than in Swift. In fact, it does: the Kotlin version works, but the Swift version has a bug. We could see the problem if we tried using our `Model` class:

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

This happens because Kotlin uses `Lists` (and `MutableLists`), which are passed by reference, but Swift uses `Arrays`, which are passed by value. We can fix this by replacing Swift `Arrays` with Gryphon's `Lists` (and `MutableLists`), which are also passed by reference. Try opening the `Model.swift` file in Xcode and switching the `deck`'s type from `Array<Card>` to `MutableList<Card>`.

```` swift
class Model {
    var deck: MutableList<Card> = []
````

Now, if you translate the code with **⌘+B** on the Gryphon target, the warnings and errors that showed up before will be gone. Using Gryphon's `List` and `MutableList` instead of Swift's `Array` is recommended to avoid these bugs. For more information, check out the documentation on [collections](collections.html).

Finally, we might also want to turn the `currentDeck` variable into a `let` to silence the Swift warning that pops up:

```` swift
    func draw() -> Card? {
        let currentDeck = self.deck
        // ...
````

If we switch to the `MyAwesoneiOSApp` target, it should build correctly, as should the `Kotlin` target.

---

*Next: [Adding manual translations](addingManualTranslations.html)*

