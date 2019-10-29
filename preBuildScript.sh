# Update AST dumps
echo " ➡️  Updating AST dumps for tests and library templates..."
perl dumpAST.pl Example\ ASTs/*.swift
perl dumpAST.pl Test\ Files/*.swift
perl dumpAST.pl .gryphon/*.swift

# Lint swift files
echo " ➡️  Linting swift files..."

if which swiftlint >/dev/null; then
  swiftlint lint
else
  echo "warning: SwiftLint not installed."
fi

