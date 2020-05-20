---
layout: tutorialLayout
---

# Building the Android app using Xcode

Let's continue developing our app. Add the following code to `Model.swift`:

```` swift
class Model {
    var deck: Array<Card> = []

    func initializeDeck() {
        deck = []

        for rank in 1...13 {
            deck.append(Card(rank: rank, suit: .hearts))
            deck.append(Card(rank: rank, suit: .diamonds))
            deck.append(Card(rank: rank, suit: .spades))
            deck.append(Card(rank: rank, suit: .clubs))
        }
    }

    func draw() -> Card? {
        var currentDeck = self.deck
        let result = currentDeck.last
        currentDeck.removeLast()
        return result
    }
}
````

In Xcode, switch to the Gryphon target if needed and hit build (**⌘ + B**) to translate the new code. You'll see Gryphon raises a few warnings, but we have bigger problems at the moment: if you switch to Android Studio and tell it to build the app, it'll say the translated code has a few errors.

We could try to fix these problems in Android Studio, where we can see what the errors are, but our changes would be overwritten as soon as we translated the Swift code again. Ideally, warnings and errors in the translated Kotlin code would be reported in the Swift lines that generated the errors, so that we could fix them at the source. This can be done using the `Kotlin` target in Xcode - we just have to tell it where the Android app is.

Switch to Xcode, click the `MyAwesomeiOSApp` project in the left sidebar, then click the `Kotlin` target. Click `Build Settings` and type `Android` in the search box. You'll see an `ANDROID_ROOT` build setting, which should point to the folder containing the Android project. It's set to `../Android` by default, but our android app is at `../MyAwesomeAndroidApp`. Let's change that:

![The Kotlin target's Build Settings in Xcode](assets/images/iOS/ios8.png)

Once that's done, switch to the `Kotlin` target and hit build (**⌘ + B**). Xcode should report the Android errors at the correct place in the Swift code now:

![Kotlin errors in Xcode](assets/images/iOS/ios9.png)

---

*Next: [Adding the Gryphon libraries](addingTheGryphonLibraries.html)*


