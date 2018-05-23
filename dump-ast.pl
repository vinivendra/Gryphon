use File::Basename;
use File::stat;
use Time::localtime;

foreach (@ARGV) {
	$swiftFilePath = $_;
	
	$astFilePath = $swiftFilePath;
	$astFilePath =~ s/(.*).swift/$1.ast/;
	
	# If the ast file already exists, check if it's up to date
	if (-e $astFilePath) {
		# If it's up to date, skip it
		if (-C $swiftFilePath > -C $astFilePath) {
			print "Skipping $swiftFilePath...\n";
			next;
		}
	}
	
	print "Processing $swiftFilePath...\n";
	
	# Get the AST dump from the swift compiler
	$swiftAstDump = `swiftc -dump-ast \"$swiftFilePath\" 2>&1`;

	# Remove possible warnings printed before the AST dump
	$swiftAstDump =~ s/^((.*)\n)*\(source\_file\n/\(source\_file\n/;
	
	# Replace file paths with placeholders
	while ($swiftAstDump =~ s/$swiftFilePath/\<<testFilePath>>/) { }
	
    # Replace random memory addresses with placeholders
    while ($swiftAstDump =~ s/0x[\da-f]+/<<memory address>>/) { }

	# Get the name of the output file
	if ($swiftFilePath =~ /(.*).swift/) {
		# Write to the output file
		open(my $fh, '>', $astFilePath) or die "Could not open file '$$astFileName' $!";
		print $fh $swiftAstDump;
		close $fh;
	}
}

print "Done!\n";
