<div style="height: 70; overflow: auto"><img src="https://github.com/vinivendra/Gryphon/raw/master/Gryphon%20Logo.svg" alt="Gryphon logo" height="70" style="max-width=100%;"></div>

# Gryphon


Gryphon is (or rather, will be) a Swift to Kotlin translator. It is intended to generate correct Kotlin code, such that a user never has to manually edit the generated files. The code is also meant to be human readable, so that a user can stop using this compiler at any time and still have two fully maintainable codebases (one in Kotlin and one in Swift).

This is a highly unstable program for now, and anything can change at a moment's notice. It's currently in version 0.2 (beta).

## Cloning and running

To try Gryphon out and/or contribute to it, just clone this repo :)

The pre-build script (`preBuildScript.sh`) should be run before building the project as it generates important files for the build phase. After that, since the project structured as a swift package, running `swift test` or `swift run` in the root directory is already a good place to start. If you want to try out different things, check out the `Driver.swift` file for the accepted commands. You can start by running `gryphon -init` to initialize the working directory, then something like `gryphon /path/to/file.swift -emit-kotlin -indentation=t` to start translating files.

Here's how I set up my environment (you might want to do something similar):

- I use macOS and Xcode as my standard IDE, with the default Xcode project created by `swift package generate-xcodeproj`. I use Xcode to change code, run the app and run the macOS tests.  In Xcode, I change the current working directory (`⌘<` → Run → Options → Use Custom Working Directory → "$SRCROOT") and add a new **Run Script** build phase (just before *Compile Sources*) to make life easier:

````
cd "$SRCROOT"
bash preBuildScript.sh
````

- I use Docker to run the app and the tests on a linux container before commiting, just to make sure everything works on linux as well. The docker container can be built with `docker build -t swift_ubuntu .` and run with `docker run -it --rm --privileged -v /path/to/local/Gryphon:/app/Gryphon swift_ubuntu`, replacing `/path/to/local/Gryphon` with the path to the cloned git repo in your computer. Once inside docker, I can run the app with `swift run` and test it with `swift test` as appropriate.

	- *Note:* Sometimes running `swift test` or `swift run` in Docker results in an unknown error like `Exited with signal code 7` or `Bus error`. I believe this is an issue with the swift version used by the container. If this happens, juts run `swift test` or `swift run` again and it should work fine.

### Contributing

Any issues and pull requests via github are welcome!
