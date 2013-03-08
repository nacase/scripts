#!/usr/bin/perl
# 
# This perl script checks an HTML file for broken links.
#
# Reports an error to stderr and returns -1 error code if a broken
# link is found.
#
# Author: Nate case
#

use Cwd;
use File::Basename;

use strict;

########################################################################
# Check an HTML file for broken links.
#
# INPUTS:
# 	$fname: Full pathname to HTML flie
# RETURNS:
# 	0 on success (links OK), -1 if broken links exist,
# 
sub CheckLinks {
	my ($fname) = @_;

	open(f, "<$fname") or die("Unable to open $fname\n");

	# Save the current working dir
	my $cwd = cwd();

	# Change to the directory of the document temporarily
	my $path = Cwd::abs_path(File::Basename::dirname($fname));
	chdir($path) or die("Unable to cd to '$path'\n");

	# Read in the file to a buffer, replacing newlines with spaces
	my $buf = "";
	while (<f>) {
		$buf .= $_;
	}
	$buf =~ s/[\n\r]/ /g;

	my $ok = 1;
	# Find all links
	while($buf =~ m/href\s*=\s*"([^\#\"]*)(\#*[^\"]*)"/gi) {
		# link = $1, anchor = $2
		# In-document anchor?  Skip test
		if ($1 eq '' and (not $2 eq '')) {
			# print "Skipping in-document anchor '$2'\n";
			next;
		}
		if ($1 eq '') {
			printf(STDERR "Warning: Empty link found\n");
		}
		# If not a http link
		if (not lc(substr($1, 0, 4)) eq "http") {
			$fname = $1;
			# Strip out "file://" if it's there
			$fname =~ s/file:\/+//;
			if (-e $fname) {
				# print "File '$fname' exists\n";
			} else {
				$ok = 0;
				printf(STDERR
			"Broken link!  File '$fname' not found\n");
			}
		}
	}
	close(f);

	# Restore the current working directory
	chdir($cwd);

	if ($ok) {
		return 0;
	} else {
		return -1;
	}
}

if ($ARGV[0] eq "") {
        print "checklinks.pl: Check for broken links in an HTML document\n";
        print "usage: $0 <html file>\n";
        exit(-1);
}

print "Checking $ARGV[0] for broken links ..\n";

my $ret = CheckLinks($ARGV[0]);

if ($ret == 0) {
	printf("File is OK, no broken links found.\n");
}
exit($ret);
