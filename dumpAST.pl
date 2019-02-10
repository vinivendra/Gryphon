use File::Basename;
use File::stat;
use Time::localtime;

$swift5Toolchain = "org.swift.4220190203a";

foreach (@ARGV) {
	$swiftFilePath = $_;
	
	$astFilePath = $swiftFilePath;
	$astFilePath =~ s/(.*).swift/$1.swiftASTDump/;
	
	# If the AST file already exists, check if it's up to date
	if (-e $astFilePath) {
		# If it's up to date, skip it
		if (-C $swiftFilePath > -C $astFilePath) {
			print "Skipping $swiftFilePath...\n";
			next;
		}
	}
	
	print "Processing $swiftFilePath...\n";

	# Get the AST dump from the swift compiler
	$swiftASTDump = `xcrun -toolchain $swift5Toolchain swiftc -dump-ast -module-name=ModuleName -output-file-map=output-file-map.json \"$swiftFilePath\" 2>&1`;

	# Remove possible warnings printed before the AST dump
	$swiftASTDump =~ s/^((.*)\n)*\(source\_file/\(source\_file/;
	
	# Replace file paths with placeholders
	while ($swiftASTDump =~ s/$swiftFilePath/\<<testFilePath>>/) { }
	
    # Replace random memory addresses with placeholders
    while ($swiftASTDump =~ s/0x[\da-f]+/<<memory address>>/) { }

	# Get the name of the output file
	if ($swiftFilePath =~ /(.*).swift/) {
		# Write to the output file
		open(my $fh, '>', $astFilePath) or die "Could not open file '$$astFileName' $!";
		print $fh $swiftASTDump;
		close $fh;
	}
}

print "Done!\n";
