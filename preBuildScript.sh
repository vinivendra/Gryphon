# Update AST dumps
echo " ➡️  Updating AST dumps for tests and library templates..."

perl dumpASTs.pl ".gryphon/StandardLibrary.template.swift"
[ $? -eq 0 ] || exit 1

perl dumpASTs.pl ".gryphon/GryphonXCTest.swift"
[ $? -eq 0 ] || exit 1

perl dumpASTs.pl "Example ASTs/test.swift"
[ $? -eq 0 ] || exit 1

for testFile in Test\ Files/*.swift; do
    perl dumpASTs.pl "$testFile"
    [ $? -eq 0 ] || exit 1
done

# Lint swift files
echo " ➡️  Linting swift files..."

if which swiftlint >/dev/null; then
  swiftlint lint
else
  echo "warning: SwiftLint not installed."
fi
