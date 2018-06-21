
foreach (@ARGV) {
    $astFilePath = $_;

    # Grab the filename without the extension
    if ($astFilePath =~ /(.*)\.ast/) {
        $pathWithoutExtension = $1;

        # Open the ast file
        open(my $astFileHandle, "$astFilePath") or die "Could not read from ast file '$astFilePath' $!";

        # Tell perl to read it as binary
        binmode($astFileHandle);
        # And tell it not to stop reading at a newline
        undef $/;
        # Read the file into memory
        my $astDump = <$astFileHandle>;

        # Start a counter for the output file names
        $i = 0;

        # OK to start
        print "Separating $astFilePath\n";
        while ($astDump =~ s/(\(source_file[\s\S]+?)(!?\(source_file)/(source_file/) {

            # Increase the filename counter
            $i = $i + 1;

            # Form the output file name
            $partFileName = "$pathWithoutExtension$i.ast";

            print "Processing $partFileName...\n";
            # Open or create the output file
            open(my $fileHandle, '>', "$partFileName") or die "Could not open file '$pathWithoutExtension$i.ast' $!";
            # Overwrite it with the new ast dump
            print $fileHandle $1;
            # Close the output file
            close $fileHandle;
        }

        # By now all the output files have been created except for the last one. Let's create it:
        # Increase the filename counter
        $i = $i + 1;
        # Form the output file name
        $partFileName = "$pathWithoutExtension$i.ast";
        print "Processing $partFileName...\n";
        # Open or create the output file
        open(my $fileHandle, '>', "$partFileName") or die "Could not open file '$pathWithoutExtension$i.ast' $!";
        # Overwrite it with the remainder of the ast dump
        print $fileHandle $astDump;
        # Close the output file
        close $fileHandle;
    }
}

print "Done!\n";
