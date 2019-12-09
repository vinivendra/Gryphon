# Used to dump the ASTs of a file (or group of files).
# Usage: `perl dumpASTs.pl path/to/myFile1.swift path/to/myFile2.swift ...`
# All files must be specified using relative paths (i.e. path/to/file.swift rather than
# /Users/me/Desktop/path/to/file.swift)
# ASTDumps will be saved at ".gryphon/ASTDumps/path/to/myFile1.swiftASTDump" etc.

use File::Basename;
use File::stat;
use Time::localtime;

$false = 0;
$true = 1;

my $gryphonFolder = ".gryphon/";
my $gryphonASTDumpsFolder = $gryphonFolder . "ASTDumps/";

my $needsToUpdate = $false;

sub outputFileForInputFile {
	my $inputFileName = $_[0]; # First parameter

	# If it's in the root .gryphon folder instead of the ASTDumps folder then the AST dump should be
	# there too
	if ($inputFileName =~ /(.*)\.gryphon\//) {
		return $inputFileName . "ASTDump"
	}
	else {
		my $outputFileName = $gryphonASTDumpsFolder . "$inputFileName" . "ASTDump";
		return $outputFileName;
	}
}

# Get swift files
my @swiftFiles = grep { $_ =~ /.*\.swift$/ } @ARGV;
@swiftFiles = sort @swiftFiles;

# Get corresponding output files
my @astDumpFiles = map { outputFileForInputFile($_) } @swiftFiles;

# Check if any files are outdated
if (scalar @astDumpFiles != scalar @swiftFiles) {
	print "Different number of swift files and AST dump files!\n";
	print "Needs to update.\n";
	$needsToUpdate = $true;
}
else {
	for (my $i=0; $i < scalar @astDumpFiles; $i++) {
		my $swiftFilePath = @swiftFiles[$i];
		my $astDumpFilePath = @astDumpFiles[$i];

		# If the AST dump doesn't exist or is out of date
		if (!(-e $astDumpFilePath) || (-C $swiftFilePath < -C $astDumpFilePath)) {
			print "⚠️ Outdated file: $astDumpFilePath.\n";
			print "Needs to update.\n";
			$needsToUpdate = $true;
			last;
		}
	}
}

if ($needsToUpdate) {
	# Create the output file map contents
	my $outputFileMapContents = "{\n";
	my $i = 0;
	while ($i < scalar @swiftFiles) {
		my $swiftFilePath = $swiftFiles[$i];
		my $astDumpFilePath = $astDumpFiles[$i];
		$outputFileMapContents = $outputFileMapContents .
			"\t\"$swiftFilePath\": {\n" .
			"\t\t\"ast-dump\": \"$astDumpFilePath\",\n" .
			"\t},\n";
			$i += 1;
	}
	$outputFileMapContents = $outputFileMapContents . "}\n";

	# Write them to a file
	my $ofmFilePath = $gryphonFolder . "temp-output-file-map.json";
	open(my $fh, '>', $ofmFilePath) or die "Could not open file '$ofmFilePath' $!";
	print $fh $outputFileMapContents;
	close $fh;

	# Create the output folders and files
	foreach (@astDumpFiles) {
		my $astDumpFile = $_;
		# If we can get the path without the file name (which corresponds to the folders we want to
		# create inside ".gryphon/ASTDumps/"), create the folder and then the file inside it.
		if ($astDumpFile =~ /(.*)\/[^\/]+/) {
			# Create the folder
			`mkdir -p \"$1\"`;
			# If it was created successfully, then create the file
			if ($? != 0) {
				`touch \"$astDumpFile\"\n`;
			}
		}
	}

	# Call the compiler to dump the ASTs
	# TODO: Remove this specific toolchain call
	print "Calling the Swift compiler...\n";
	my @quotedSwiftFiles = map { "\"$_\"" } @swiftFiles;
	my $inputFiles = join(" ", @quotedSwiftFiles);
	my $output = `swiftc $inputFiles -dump-ast -module-name=ModuleName -output-file-map=$ofmFilePath -D IS_DUMPING_ASTS 2>&1`;

	# Delete the output file map
	unlink($ofmFilePath);

	# If the compilation failed (if the exit status isn't 0)
	my $status = $?;
	if ($status != 0) {
		print "🚨 Error in the Swift compiler:\n";
		print "$output\n";
		exit 1;
	}
	else {
		print "✅ Done.\n";
	}
}
else {
	my @checkedSwiftFiles = map { "✅ $_" } @swiftFiles;
	my $inputFiles = join("\n", @checkedSwiftFiles);
	print $inputFiles. "\n";
}
