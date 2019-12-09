# Update AST dumps
echo " ➡️  Updating AST dumps for tests and library templates..."
perl dumpASTs.pl ".gryphon/StandardLibrary.template.swift"
perl dumpASTs.pl ".gryphon/GryphonXCTest.swift"
perl dumpASTs.pl "Example ASTs/test.swift"
for testFile in Test\ Files/*.swift; do
    perl dumpASTs.pl "$testFile"
done

# Lint swift files
echo " ➡️  Linting swift files..."

if which swiftlint >/dev/null; then
  swiftlint lint
else
  echo "warning: SwiftLint not installed."
fi
