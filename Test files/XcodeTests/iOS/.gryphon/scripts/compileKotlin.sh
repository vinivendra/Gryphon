# Exit if any command fails
set -e

# Remove old logs
# The `-f` option is here to avoid reporting errors when the files are not found
rm -f "$SRCROOT/.gryphon/gradleOutput.txt"
rm -f "$SRCROOT/.gryphon/gradleErrors.txt"

# Switch to the Android folder so we can use pre-built gradle info to speed up the compilation.
cd "$ANDROID_ROOT"

# Compile the Android sources and save the logs gack to the iOS folder
# This command is allowed to fail so we add "|| true" to the end
./gradlew compileDebugSources > 	"$SRCROOT/.gryphon/gradleOutput.txt" 2> 	"$SRCROOT/.gryphon/gradleErrors.txt" 	|| true

# Switch back to the iOS folder
cd "$SRCROOT"

# Map the Kotlin errors back to Swift
swift .gryphon/scripts/mapGradleErrorsToSwift.swift < 	.gryphon/gradleOutput.txt

swift .gryphon/scripts/mapGradleErrorsToSwift.swift < 	.gryphon/gradleErrors.txt
