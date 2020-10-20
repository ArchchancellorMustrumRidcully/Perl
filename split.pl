use strict;
use warnings;

#######################################################
# Take a command line input for File and Output Size and chunk process a file.
# Has no care for repeating headers.  It could, but it doesn't.
#######################################################
# Usage: perl split.pl <filename> <size in MB>
#######################################################
# 2020-10-20
#######################################################

# Credit for the barebones -> PG: 
# https://www.perlmonks.org/bare/?node_id=313252

my ($filename, $filesize) = @ARGV;

if ($filesize < 1)
	{
	# will throw an unitialized value - could change the check to something else but in the end, it doesn't
	# matter.
	print "\n";
	print "------------------------------------------------------------------------------\n";
	print "Please add the filesize output in MB.  Example: perl split.pl filename.csv 100\n";
	print "------------------------------------------------------------------------------\n";
	print "\n";
	exit;
	}

my $outputfilename="";
my $outputfileext="";

if ($filename =~ m/(.*)\.(.*)/)
	{
	$outputfilename = $1;
	$outputfileext = $2;
	}
	else
	{
	print "\n";
	print "------------------------------------------------------------------------------\n";
	print "Please include the whole filename, with an extension.\n  Example: perl split.pl filename.csv 100\n";
	print "------------------------------------------------------------------------------\n";
	print "\n";
	exit;
		}

# convert the size over something useful

my $size = ($filesize * 1000000);

open (FH, "< $filename") or die "Could not open source file. $!";

my $i = 0;

while (1) {
    my $chunk;
	my $fullfilenameoutput = "$outputfilename-$i\.$outputfileext";
	
	print "processing $filename into $fullfilenameoutput\n";

	open(OUT, ">$fullfilenameoutput") or die "Could not open destination file";
	$i ++;
	if (!eof(FH)) {
		read(FH, $chunk, $size);
		print OUT $chunk;
	} 
	if (!eof(FH)) {
		$chunk = <FH>;
		print OUT $chunk;
	}
	close(OUT);
	last if eof(FH);
}
