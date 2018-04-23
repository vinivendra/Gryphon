use File::Basename;

foreach (@ARGV) {
	$filePath = $_;
	
	print "Processing $filePath...\n";
	
	# Get the AST dump from the swift compiler
	$swiftAstDump = `swiftc -dump-ast \"$filePath\" 2>&1`;

	# Remove possible warnings printed before the AST dump
	$swiftAstDump =~ s/^((.*)\n)*\(source\_file\n/\(source\_file\n/;
	
	# Replace file paths with placeholders
	while ($swiftAstDump =~ s/$filePath/\<<testFilePath>>/) { }
	
	# Get the name of the output file
	if ($filePath =~ /(.*).swift/) {
		$nameWithoutExtension = $1;
		$astFileName = "$nameWithoutExtension.ast";
		
		# Write to the output file
		open(my $fh, '>', $astFileName) or die "Could not open file '$$astFileName' $!";
		print $fh $swiftAstDump;
		close $fh;
	}
}

print "Done!\n";
