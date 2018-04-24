use File::Basename;
use File::stat;
use Time::localtime;

foreach (@ARGV) {
	$filePath = $_;
	
	$astFilePath = $filePath;
	$astFilePath =~ s/(.*).swift/$1.ast/;
	$astFileHandle = IO::File->new($astFilePath,'r');
	$astModifiedDate = localtime(stat($astFileHandle)->mtime);
	
	$swiftFileHandle = IO::File->new($filePath,'r');
	$swiftModifiedDate = localtime(stat($swiftFileHandle)->mtime);
	
	# If the ast file was modified after the swift file, skip it
	if (-C $filePath > -C $astFilePath) {
		next;
	}
	
	print "Processing $filePath...\n";
	
	# Get the AST dump from the swift compiler
	$swiftAstDump = `swiftc -dump-ast \"$filePath\" 2>&1`;

	# Remove possible warnings printed before the AST dump
	$swiftAstDump =~ s/^((.*)\n)*\(source\_file\n/\(source\_file\n/;
	
	# Replace file paths with placeholders
	while ($swiftAstDump =~ s/$filePath/\<<testFilePath>>/) { }
	
	# Get the name of the output file
	if ($filePath =~ /(.*).swift/) {
		# Write to the output file
		open(my $fh, '>', $astFilePath) or die "Could not open file '$$astFileName' $!";
		print $fh $swiftAstDump;
		close $fh;
	}
}

print "Done!\n";
