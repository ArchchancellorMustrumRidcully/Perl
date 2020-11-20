#! /usr/bin/perl -w
########################################################################
# Ver .4
# 20190919 Added ED_UPDATESCRIPT CHECK 
# 20201118 
# 	Added GAM-ADVX output parsing
#	moved to really HTML output with questionable blockquote usage.  (Could fix that with a counter\trigger)
# 20201119 
#	Added OU fetch with gam print orgs toplevelonly
# 	Added local exclusion list for non-student runs
########################################################################
# To Do
# 
# Clean up the HTML output, it's ugly.  Originally it was .txt file output
#
########################################################################

use strict;
use warnings;
use Data::Dumper;
use IO::Handle;
STDOUT->autoflush(1);

########################################################################
# Begin Variables ######################################################

my $RUNALL=0; #Excludes Students and Alumni.  
my $INPUTFILE_EDLIST = '/home/mustrum@unseenuniversity.edu/ED-UpdateScript.sh';  # just a list 
my $filename = 'READ_DELEGATES-EXPORTED.txt';
my $PATHTOGAM="/home/gam/gamadv-xtd3/gam";  #(Include gam executable)
my $OUT_DELEGATES = "/var/www/html/gam-stuff/DELEGATES.html";

#my @EXCLUSIONS = ();
my @EXCLUSIONS = ('Students', 'Alumni');
# End Variables ######################################################

my $FILEDATE = GET_DATETIME();

########################################################################
### The Gam Request Setup ###
########################################################################

### GET OUs from Google
my $GAMREQUEST="$PATHTOGAM print orgs toplevelonly";

my @OU_TEMP = qx($GAMREQUEST);  	#store the response
my @OU_CLEANING;								#house cleaning

foreach my $OUCHECK (@OU_TEMP)		## Clean up the return  
	{
	if ($OUCHECK =~ m/\/(.*),id:(.*),(.*),id:(.*)/)	# GAM-ADVX regex (GAM (stock) not checked for this command)
		{
		push(@OU_CLEANING,$1);				#store the OU names
		}
	}

### Filter for @EXCLUSIONS
my @OU_LIST = grep { not $_ ~~ @EXCLUSIONS } @OU_CLEANING;	#push clean list for use into array

#### From here, do a foreach @OU_LIST and prime the first output with > and all the others with >>
my $CHECKER = 0;

foreach my $OU_LIST(@OU_LIST)
	{
	## You could hold this in memory, I choose to put it out to file so I can error check later
	print "CHECKING: $OU_LIST\n";
	if ($CHECKER == 0)
		{
		$GAMREQUEST="$PATHTOGAM ou \"$OU_LIST\" show delegates > $filename";
		qx($GAMREQUEST);
		$CHECKER++;
		}
	else
		{
		$GAMREQUEST="$PATHTOGAM ou \"$OU_LIST\" show delegates >> $filename";
		qx($GAMREQUEST);
		$CHECKER++;
		}
	}

### END OF #2 CLEAN UP ##

########################################################################
#### Check ED_UPDATE.SH script #########
########################################################################
open(my $FH_EDLIST, '<:encoding(UTF-8)', $INPUTFILE_EDLIST) or die "Could not open file '$INPUTFILE_EDLIST' $!";
my @MANAGED_ACCOUNTS;
while (my $ROW_EDLIST = <$FH_EDLIST>) 
	{
	if ($ROW_EDLIST =~ /(python Head.py --action delegate --group )(.*)/) 
		{
		push @MANAGED_ACCOUNTS, $2;
		#print "$2\n";
		}
	else
		{}
	}

print "#**********************************************\n";
print "# Delegates Output Parser					\n";
print "#**********************************************\n";
print "# Usage: \n\n";
print "# Prepares an export from GAM using the following command:\n";
print "# gam all users show delegates > $filename";
print "#\n#\n# This script will convert that output to $OUT_DELEGATES\n";
print "#**********************************************\n";

### Start the output ####

open(my $fh, '<:encoding(UTF-8)', $filename) or die "Could not open file '$filename' $!";
my $DelegatorCheck="New";  #used to prime the variable and find out if there is a New account being parsed
open(my $OUTPUT_DELEGATES, '>', $OUT_DELEGATES) or die "Could not open file '$OUT_DELEGATES' $!";
print $OUTPUT_DELEGATES "Started: $FILEDATE<br><br>\n\n";

print $OUTPUT_DELEGATES "OUs being checked:<br>\n";

foreach my $OU_LIST(@OU_LIST)
	{
	print $OUTPUT_DELEGATES "----- $OU_LIST<br>\n";
	}

print $OUTPUT_DELEGATES "<br>OUs being excluded:<br>\n";

foreach my $NO(@EXCLUSIONS)
	{
	print $OUTPUT_DELEGATES "----- $NO<br>\n";
	}

print $OUTPUT_DELEGATES "<br><br>------------------------------------------------------------------<br><br>\n";

print "\n\nStarting conversion of $filename\n";

# Converted to GAM-ADVX output
# Should still work with GAM (stock) as well

while (my $row = <$fh>) 
	{
	chomp $row;
	#print ".";
	#print "$row\n";

	if ($row =~ /(Delegator: )(.*)/) 
			{
			my $tmp=$2;
			if ($tmp eq $DelegatorCheck)
				 {#ignore - same account
					 print "1) [$DelegatorCheck - $tmp]\n";
				}
			else
				{
				print "2A - [$DelegatorCheck - $tmp]\n";
				$DelegatorCheck=$tmp;

				my $MANAGE_RETURN=CHECK_MANAGED($tmp);

				#print $OUTPUT_DELEGATES "Delegator: $tmp\n";
				#print $OUTPUT_DELEGATES "gam user $tmp [MANAGED]\n";
				print $OUTPUT_DELEGATES "</BLOCKQUOTE>\nDelegator: $tmp $MANAGE_RETURN\n<BLOCKQUOTE>";
				print "2B - [$DelegatorCheck - $tmp]\n";
				}
			}
	elsif ($row =~ /(User: )(.*), Show (.*) Delegates (.*)/) 
			{
			my $tmp=$2;
			my $GotDelegates=$3;
			if ($tmp eq $DelegatorCheck)
				 {#ignore - same account
					 print "1) [$DelegatorCheck - $tmp]\n";
				}
                        elsif ($GotDelegates == 0)
				{
				#ignore, no delegates
				}
			else
				{
				print "2A - [$DelegatorCheck - $tmp]\n";
				$DelegatorCheck=$tmp;

				my $MANAGE_RETURN=CHECK_MANAGED($tmp);

				#print $OUTPUT_DELEGATES "Delegator: $tmp\n";
				#print $OUTPUT_DELEGATES "gam user $tmp [MANAGED]\n";
				print $OUTPUT_DELEGATES "</BLOCKQUOTE>\nDelegator: $tmp $MANAGE_RETURN\n<BLOCKQUOTE>";
				print "2B - [$DelegatorCheck - $tmp]\n";
				}
			}
	elsif ($row =~ /(User: )(.*), Show (.*) Delegate (.*)/) 
			{
			my $tmp=$2;
			my $GotDelegates=$3;
			if ($tmp eq $DelegatorCheck)
				 {#ignore - same account
					 print "1) [$DelegatorCheck - $tmp]\n";
				}
                        elsif ($GotDelegates == 0)
				{
				#ignore, no delegates
				}
			else
				{
				print "2A - [$DelegatorCheck - $tmp]\n";
				$DelegatorCheck=$tmp;

				my $MANAGE_RETURN=CHECK_MANAGED($tmp);

				print $OUTPUT_DELEGATES "</BLOCKQUOTE>\nDelegator: $tmp $MANAGE_RETURN\n<BLOCKQUOTE>";
				print "2B - [$DelegatorCheck - $tmp]\n";
				}
			}


		elsif ($row =~ /(Delegate ID:)(.*)/) 
			{
			#### Drop These Items
			}
			
			
                elsif ($row =~ /(Delegate: )(.*)/)
                        {
                        chomp $row;
                        print $OUTPUT_DELEGATES "<br>$2\n";
                        #push @GAM_HOLD,$2;
                        }

		elsif ($row =~ /(Delegate Email: )(.*)/)
			{
			chomp $row;
			print $OUTPUT_DELEGATES "<br>$2\n";
			#push @GAM_HOLD,"       $2";
			}
                elsif ($row =~ /(Status: )(EXPIRED)/i)
                        {
                        chomp $row;
                        print $OUTPUT_DELEGATES "$2 **\n ";
                        #push @GAM_HOLD,"       $2";
                        }

		else 
			{
			#### Drop These Items
			print "WHAT: $row\n";
			}
	}

my $FILEDATEEND = GET_DATETIME();

print $OUTPUT_DELEGATES "</BLOCKQUOTE>\n\n<br><br>Ended: $FILEDATEEND \n\n";

close $OUT_DELEGATES;

print "\n\nConversion completed and results are in $OUT_DELEGATES.\n\n";



sub GET_DATETIME
	{
	my($sec,$min,$hour,$day, $month, $year) = (localtime)[0,1,2,3,4,5];

	$sec = sprintf '%02d', $sec;
	$min = sprintf '%02d', $min;
	$month = sprintf '%02d', $month+1;
	$day   = sprintf '%02d', $day;
	$year = $year+1900;
	my $date = "$year$month$day-$hour$min$sec";
	return $date;
	}

sub CHECK_MANAGED
	{
	my $CHECK_IN="@_";
	print "CHECK_IN: $CHECK_IN\n";

	my $MATCH="";
	
	foreach my $i (0 .. $#MANAGED_ACCOUNTS) 
		{

		if ($MANAGED_ACCOUNTS[$i] =~ /$CHECK_IN/i)
			{
			#print "MATCHED: $MANAGED_ACCOUNTS[$i] = $CHECK_IN\n";
			$MATCH="[MANAGED]";
			return $MATCH;
			}
		else
			{
                        #print "NO MATCH: $CHECK_IN\n";
			$MATCH="[UNMANAGED]";
			
			#return $MATCH;		
			}
		}
	print $CHECK_IN;
	return $MATCH;
	}
