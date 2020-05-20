---
layout: tutorialLayout
---

# Translating command line programs

## Translating a single file

Let's start by translating a simple Swift file from the command line.

### Step 1: Creating the file

Create a file called `main.swift` and add the following contents to it:

```` swift
func getMessage() -> String {
    return "Hello from Gryphon!"
}

print(getMessage())
````

### Step 2: Translating

Translate the `main.swift` file using the following command:

```` bash
$ gryphon main.swift

internal fun getMessage(): String {
    return "Hello from Gryphon!"
}

fun main(args: Array<String>) {
    println(getMessage())
}
````

As you can see, Gryphon outputs the result to the console by default. This is a pretty straightforward translation, except for a few details - like the `internal` access modifier and the `main` function - to make sure it works the same.

### Step 3: Setting an output file

To make Gryphon write the translation to a `main.kt` file, add the following comment to the top of the `main.swift` file:

```` swift
// gryphon output: main.kt
````

Then, translate it again:

```` bash
$ gryphon main.swift
````

This time there's no console output - instead, Gryphon created a `main.kt` file with the contents of the translation. We can run both versions and see that they work:

```` bash
$ swiftc main.swift
$ ./main
Hello from Gryphon!

$ kotlinc -include-runtime -d main.jar main.kt
$ java -jar main.jar
Hello from Gryphon!
````


## Translating multiple files

### Step 1: Creating a new file

Create a new file called `message.swift` and move the `getMessage` function to it. The `main.swift` file should now contain:

```` swift
// gryphon output: main.kt

print(getMessage())
````

And the new `message.swift` file will contain:

```` swift
// gryphon output: message.kt

func getMessage() -> String {
    return "Hello from Gryphon!"
}
````

Notice the `// gryphon output:` comment at the top of both files that specifies the output file path for each one. If we translate them both, we'll notice Gryphon generates the two files accordingly:

```` bash
$ gryphon message.swift main.swift
````

And we can compile them just like before:

```` bash
$ swiftc message.swift main.swift
$ ./main
Hello from Gryphon!

$ kotlinc -include-runtime -d main.jar message.kt main.kt
$ java -jar main.jar
Hello from Gryphon!
````

### Step 2: Skipping platform-specific files

Now that our message has been separated from the main file, let's customize it for each language. Make the `message.swift` file say `"Hello from Swift!"`:

```` swift
func getMessage() -> String {
    return "Hello from Swift!"
}
````

And change the contents of `message.kt` to say `"Hello from Kotlin!"`:

```` kotlin
internal fun getMessage(): String {
    return "Hello from Kotlin!"
}
````

Because the `message.swift` file is now "platform-specific", so we no longer need to translate it. However, if try calling Gryphon without it, we'll get an error:

```` bash
$ gryphon main.swift
🚨 Error calling the Swift compiler.
Swift compiler output:

main.swift:3:7: error: use of unresolved identifier 'getMessage'
print(getMessage())
      ^~~~~~~~~~
````

This happens because Gryphon needs to partially compile the Swift code, which means it needs to know of all necessary files to compile a program. We can tell Gryphon the `message.swift` file should be compiled - but not translated - by passing it after the `--skip` flag:

```` bash
$ gryphon main.swift --skip message.swift
````

Now the translation can finish successfully. We can test it out with:

```` bash
$ swiftc message.swift main.swift
$ ./main
Hello from Swift!

$ kotlinc -include-runtime -d main.jar message.kt main.kt
$ java -jar main.jar
Hello from Kotlin!
````

There are a few other flags that can be used to customize translations. The `--indentation` flag changes the indentation used in the Kotlin files; the `--default-final` flag makes declarations `final` by default instead of `open`; etc. You can see the full list using `gryphon --help`.

## That's it!

Next: check out how to [translate a new iOS app to Android](translatingANewiOSAppToAndroid.html) or how to [add Gryphon to an existing app](addingGryphonToAnExistingApp.html).

For more in-depth information, check out the documentation on using Gryphon's [collections](collections.html), [translation comments](translationComments.html), and [templates](templates.html).

Have any doubts? [Ask a question on Twitter](https://twitter.com/gryphonblog).

If you are interested in knowing how Gryphon works inside or contributing to it, check out [Contributing to Gryphon](contributing.html).
