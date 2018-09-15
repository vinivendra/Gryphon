
$astDumpExtension = "swiftASTDump"

foreach (@ARGV) {
    $astDumpFilePath = $_;

    # Grab the filename without the extension
    if ($astDumpFilePath =~ /(.*)\.swiftASTDump/) {
        $pathWithoutExtension = $1;

        # Open the ast file
        open(my $astDumpFileHandle, "$astDumpFilePath") or die "Could not read from ast file '$astDumpFilePath' $!";

        # Tell perl to read it as binary
        binmode($astDumpFileHandle);
        # And tell it not to stop reading at a newline
        undef $/;
        # Read the file into memory
        my $astDump = <$astDumpFileHandle>;

        # Start a counter for the output file names
        $i = 0;

        # OK to start
        print "Separating $astDumpFilePath\n";
        while ($astDump =~ s/(\(source_file[\s\S]+?)(!?\(source_file)/(source_file/) {

            # Increase the filename counter
            $i = $i + 1;

            # Form the output file name
            $partFileName = "$pathWithoutExtension$i.$astDumpExtension";

            print "Processing $partFileName...\n";
            # Open or create the output file
            open(my $fileHandle, '>', "$partFileName") or die "Could not open file '$pathWithoutExtension$i.$astDumpExtension' $!";
            # Overwrite it with the new ast dump
            print $fileHandle $1;
            # Close the output file
            close $fileHandle;
        }

        # By now all the output files have been created except for the last one. Let's create it:
        # Increase the filename counter
        $i = $i + 1;
        # Form the output file name
        $partFileName = "$pathWithoutExtension$i.$astDumpExtension";
        print "Processing $partFileName...\n";
        # Open or create the output file
        open(my $fileHandle, '>', "$partFileName") or die "Could not open file '$pathWithoutExtension$i.$astDumpExtension' $!";
        # Overwrite it with the remainder of the ast dump
        print $fileHandle $astDump;
        # Close the output file
        close $fileHandle;
    }
}

print "Done!\n";
