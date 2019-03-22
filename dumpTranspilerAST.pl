use File::Basename;
use File::stat;
use Time::localtime;

$needsToUpdate = 0; # false

$swiftFolder = "Sources/GryphonLib";
$astDumpFolder = "Bootstrap";

# Check if any file is outdated
opendir my $dir, $swiftFolder or die "🚨 Cannot open directory: $!";
my @allSourceFiles = readdir $dir;
closedir $dir;
my @swiftFiles = grep { $_ =~ /.*\.swift$/ } @allSourceFiles;
@swiftFiles = sort @swiftFiles;

opendir my $dir, $astDumpFolder or die "🚨 Cannot open directory: $!";
my @astDumpFiles = readdir $dir;
closedir $dir;
@astDumpFiles = grep { $_ =~ /.*\.swiftASTDump$/ } @astDumpFiles;
@astDumpFiles = sort @astDumpFiles;

if (scalar @astDumpFiles != scalar @swiftFiles) {
	print "Different number of swift files and AST dump files!\n";
	print "Needs to update.\n";
	$needsToUpdate = 1; # true
}
else {
	for (my $i=0; $i < scalar @astDumpFiles; $i++) {
		$swiftFilePath = $swiftFolder . "/" . @swiftFiles[$i];
		$astDumpFilePath = $astDumpFolder . "/" . @astDumpFiles[$i];

		# If it's out of date
		if (-C $swiftFilePath < -C $astDumpFilePath) {
			print "Outdated file: $astDumpFilePath.\n";
			print "Needs to update.\n";
			$needsToUpdate = 1; # true
			last;
		}
	}
}

if ($needsToUpdate) {
	print "Calling the Swift compiler...\n";

	# Get the AST dumps and write them to the files
	my $output = `xcrun -toolchain org.swift.4220190203a swiftc Sources/GryphonLib/*.swift -dump-ast -module-name=ModuleName -output-file-map=output-file-map.json 2>&1`;

	# If the compilation failed (if the exit status isn't 0)
	if ($? != 0) {
		print "🚨 Error in the Swift compiler:\n";
		print "$output\n";
	}
  else {
    print "Done.\n";
  }
}
else {
	print "All files are up to date.\n";
}
