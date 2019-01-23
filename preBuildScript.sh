# Compile gyb files
echo " ➡️  Compiling .gyb files..."

find . -name '*.gyb' | \
while read file; do \
./gyb --line-directive '' -o "${file%.gyb}" "$file"; \
done


# Update AST dumps
echo " ➡️  Updating AST dumps..."

perl dump-ast.pl Example\ ASTs/*.swift
perl dump-ast.pl Test\ Files/*.swift
perl dump-ast.pl Library\ Templates/*.swift


# Lint swift files
echo " ➡️  Linting swift files..."

if which swiftlint >/dev/null; then
  swiftlint lint
else
  echo "warning: SwiftLint not installed."
fi
