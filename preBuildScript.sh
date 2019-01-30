# Compile gyb files
echo " ➡️  Compiling .gyb files..."

find . -name '*.gyb' | \
while read file; do \
./gyb --line-directive '' -o "${file%.gyb}" "$file"; \
done


# Update AST dumps
echo " ➡️  Updating AST dumps..."

perl dumpAST.pl Example\ ASTs/*.swift
perl dumpAST.pl Test\ Files/*.swift
perl dumpAST.pl Library\ Templates/*.swift


# Lint swift files
echo " ➡️  Linting swift files..."

if which swiftlint >/dev/null; then
  swiftlint lint
else
  echo "warning: SwiftLint not installed."
fi
