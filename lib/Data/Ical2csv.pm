#!/usr/bin/perl

=head1 NAME

Ical2csv - Converts an iCal file (aka .ics) to a CSV file. B<Still early stage>

=head1 VERSION

Version 0.3.2, 20150225.

=head1 SYNOPSYS

Ical2csv.pm --file=F<< <FILE> >> [--outputfile=<FILE>] [--sep=,] [--verbosity=0|1|2|3]

Ical2csv.pm --url=F<< <url> >> [--outputfile=<FILE>] [--sep=,] [--verbosity=0|1|2|3]

Usage: $ perl ./Ical2csv.pm --file=thisical.ics

Usage: $ perl ./Ical2csv.pm --file=thisical.ics --sep=; --vprop=SUMMARY,LOCATION,DTSTART,DTEND,DESCRIPTION

--> Create a CSV file called thisical.ics.csv

Usage: $ perl ./Ical2csv.pm --url=http://example.com/calendar.ics

--> Create a CSV fille called basic.ics.csv

Should work with a basic Perl (without particular module). Needs curl tool to import ics file from an URL.

=head1 DESCRIPTION

ICAL is a file format to represent calendars. ICAL data is produced and managed by calendars applications.
But these applications haven't been build to own complex manipulations of the data, such as statistics,
mass operations, filtered exports, etc.

Ical2csv converts an ICS file to a CSV file -- a simple file format where each line represent a record.
CSV file format allows easier data manipulation with tools such as spreadsheet processors, common data tools
or languages (R, Perl, Python, AWK...).

Ical2csv takes each event of the calendars and build a record for it.

Options:

    --file            complete name of the ICS file.
    --url             URL of the ICS file.
    --dlmtr           [optional] delimiter (separator) of the CSV file produced. Generally "," (default) or ";"
                      Ex. --dlmtr=";"
    --endofline       [optional] type of end of line. It can be: "\n" (Unices), "\r" (MacOS) or "\r\n" (Windows)? Default "\r\n".
    --outputfile      [optional] name of the file to produce. Default is <sourcefile>.csv.
                      Ex. --outputfile=2015.csv
    --v, --verbosity  [optional] verbose mode represented by a number between 0 and 3. Default is "1" which means small verbosity.
                      0 means no verbosity at all.
                      Ex. --v=1


=head1 INSTALLATION

To use this script:

=over1

=item simply download L<https://raw.githubusercontent.com/CharlesNepote/ical2csv/master/lib/Data/Ical2csv.pm>

=item use it with perl interpreter. Example:

=over2

=item perl ./Ical2csv.pm --file=thisical.ics

=back

=back


This should work under Linux, MacOS and may be Windows as well (except the --url option).

Alternatively, you can make the script executable, thus you can use it without 'perl' command.

Under Linux:

    chmod a+x Ical2csv.pm
    ./Ical2csv.pm --file=thisical.ics

Under MacOS:

    chmod a+x Ical2csv.pm
    ./Ical2csv.pm --file=thisical.ics


=cut

# TODO: Use named arguments: http://perldesignpatterns.com/?NamedArguments
# TODO: more documentation:
#       * how to install?
#       * how to contribute/report problems
# TODO: sub valid_url without using external modules
# TODO: output on STDOUT, without creating any new file; examples of usages:
# 		* sort lines (pipe with sort)
# 		* filter some lines (pipe with grep)
# TODO: evaluate File::Fetch instead of curl: https://metacpan.org/pod/File::Fetch
#       (a core module as said on http://perldoc.perl.org/File/Fetch.html ?)

=head1 AUTHOR

Charles Nepote <charles@nepote.org>

=head1 LICENCE

Open Source software under BSD licence.

=cut


package Data::Ical2csv;
use strict; 				# At the very beginning as suggested by Perl::Critic
use warnings;
use 5.6.0; 					# Because "three-argument" open() comes with Perl 5.6 [2001]

our $VERSION = '0.3.1'; 	# Every CPAN module needs a version


__PACKAGE__->run( @ARGV ) unless caller;


sub run {
	use Getopt::Long;
	our($inputfile, $url, $outputfile, $sep, @vprop, @overidevprop, $verbosity);

	# 1. Configuration ---------------
	# Separator
	$sep = ",";
	# List of wanted properties
	@vprop = ("SUMMARY", "LOCATION", "DTSTART", "DTEND", "CREATED", "DESCRIPTION", "LAST-MODIFIED", "SEQUENCE", "STATUS", "CONFIRMED", "TRANSP");
	#@vprop = ("SUMMARY", "DTSTART", "DTEND", "DTSTAMP", "UID", "CREATED", "DESCRIPTION", "LAST-MODIFIED", "LOCATION", "SEQUENCE", "STATUS", "CONFIRMED", "TRANSP");
	# Choose the end of line of the CSV file produced.
	#   \n (ie LF) is ok for unices.
	#   RFC 4180 suggest, for CSV files, that "Each record is located on a separate line, delimited by a line break (CRLF)" [\r\n].
	my $endofline = "\r\n";


	# 2. Command line parameters -----
	GetOptions ("file:s" 		=> \$inputfile,
				"url:s" 		=> \$url,
				"outputfile:s" 	=> \$outputfile,
				"sep:s" 		=> \$sep,
				"vprop:s" 		=> \@overidevprop,
				"v|verbosity:i" => \$verbosity);
	if (@overidevprop) { undef @vprop; my @vprop = split(',',join(',',@overidevprop)); }

	&ical2csv ($inputfile, $url, $outputfile, $sep, \@vprop, $endofline, $verbosity);
	return 0;
}


# 3. Actions ---------------------
sub ical2csv {
	no strict "refs"; # Because use strict disables the use of symbolic references, and we need it here.
	my ($inputfile, $url, $outputfile, $sep, $refvprop, $endofline, $verbosity) = @_;
	if (!(defined $verbosity)) 	{ $verbosity = 1 };

	# ---- Input controls
	if ($inputfile && $url)		{
		print	"\nError. You must provide EITHER a filename OR an URL with options " .
				"--file=xxxx or --url=http://xxxxx\n\n"
				if ($verbosity >= 1);
		return 2;
	}
	if (!$inputfile && !$url)	{
		print	"\nError. You MUST provide either a filename or an URL with options " .
				"--file=xxxx or --url=http://xxxxx\n\n"
				if ($verbosity >= 1);
		return 1;
	}


	#~ if (&validurl($inputfile)) { $url = $inputfile; } # TODO

	# ---- If an URL is provided, try to import ics file
	if ($url) {
		# TODO: validate URL
		# Transfert ics from the web to the filesystem
		my @args = ("curl", "$url", "-o", "basic.ics");
		if (system (@args) != 0) {
			print "\nSystem @args failed: $? \n\n" if ($verbosity >= 1);
			return 3;
		}
		$inputfile = "basic.ics";
	}

	# ---- Default values if no option is provided. Separator, wanted properties, endfoline and verbosity.
	if (!$outputfile) 			{ $outputfile = $inputfile . ".csv"; }
	if (!$sep) 					{ my $sep = ";" } 				#
	if (!$endofline) 			{ my $endofline = "\r\n"; } 	# Following RFC 4180 https://tools.ietf.org/html/rfc4180
	my (@props) = ();
	# TODO: control @props based on exiting properties in iCal RFC
	if (@{$refvprop}) 			{ my (@props) = @{$_[3]}; }
	if (!@props) 				{ @props = ( 	"SUMMARY", "LOCATION", "DTSTART", "DTEND",
												"CREATED", "DESCRIPTION", "LAST-MODIFIED", "SEQUENCE",
												"STATUS", "CONFIRMED", "TRANSP"); }

	$endofline =~ s/\\r/\r/; $endofline =~ s/\\n/\n/;

	print STDOUT "\nVerbosity: $verbosity\n" 	if ($verbosity >= 2);
	print STDOUT "\$inputfile: $inputfile\n" 	if ($verbosity >= 2 && $inputfile);
	print STDOUT "\$url: $url\n" 				if ($verbosity >= 2 && $url);
	print STDOUT "\$sep: $sep\n" 				if ($verbosity >= 2);
	print STDOUT "\$endofline: $endofline\n" 	if ($verbosity >= 2);
	print STDOUT "\@props: @props\n\n" 			if ($verbosity >= 2);

	print STDOUT "\nExtracting events from file: $inputfile\n\n" if ($verbosity >= 1);

	# ---- Process long lines and end of lines
	# RFC says:
	# Lines of text SHOULD NOT be longer than 75 octets [...].
	# Long content lines SHOULD be split into a multiple line representations
	# using a line "folding" technique.  That is, a long line can be split
	# between any two characters by inserting a CRLF immediately followed
	# by a single linear white-space character (i.e., SPACE or HTAB).
	my ($ics, $tmp);
	if (!(open ($ics, "<", "$inputfile")))		{ print "\nCannot open $inputfile: $!\n\n" if ($verbosity >= 1); 		return 4; }
	if (!(open ($tmp, ">", "$inputfile.tmp")))	{ print "\nCannot open $inputfile.tmp: $!\n\n" if ($verbosity >= 1); 	return 5; }
	undef $/; # "file-slurp" mode: \n is no more a special char
	while (<$ics>) {
		$_=~ s/(\r\n|\n|\r)( |\t)//mg;
		$_=~ s/(\r\n|\n\\r)/\n/mg;
		print $tmp "$_";
	}
	close ($ics);
	close ($tmp);

	# ---- Main processes
	my ($SOURCE, $EXPORT);
	if (!(open ($SOURCE, "<", "$inputfile.tmp")))  { print "\nCannot open $inputfile.tmp: $!\n\n" if ($verbosity >= 1);  return 6; }
	if (!(open ($EXPORT, ">", "$outputfile")))     { print "\nCannot open $outputfile: $!\n\n" if ($verbosity >= 1);     return 7; }

	my $event_nb = 0;
	my %event = ();
	$/ = "\n";

	# CSV header
	foreach my $h (@props) { print $EXPORT '"' . $h . '"' . $sep; print STDOUT "Property: $h\n" if ($verbosity >= 2); }
	print $EXPORT $endofline;

	# Process properties
	while (<$SOURCE>) {
		my ($prop, $va) = split(':', $_, 2);	# iCal records lines with property/value separated by a ":"
		chop $va 	if ($va);					# Removes any trailing string that corresponds to the current value of $/ (should be \n)
		print STDOUT "$prop ----> $va\n" if ($verbosity >= 3); # print each pair property/value if "-v" option
		if ($_ =~ "BEGIN:VEVENT") { $event_nb++; next; }

		$prop =~ s/^(DT(END|START));VALUE=DATE/$1/; # Manage "DTSTART;VALUE=DATE:20141224" (all day events)
		$event{$prop} = $va;
		if ($_ =~ "END:VEVENT") {		# End of the record? => for each wanted property, export each value as a CSV line
			foreach my $v (@props) { ($event{$v}) ? print $EXPORT '"' . $event{$v} . '"' . $sep : print $EXPORT '""' . $sep; }
			print $EXPORT $endofline;	# End of record
		}
	}

	# Output statistics
	print STDOUT "$. lines analysed\n" 										if ($verbosity >= 1);
	print STDOUT "$event_nb events completed in file $outputfile\n\n" 		if ($verbosity >= 1);


	close ($SOURCE); close ($EXPORT);
	unlink <$inputfile.tmp>;
	return 0;
}

#~ sub validurl {
	#~ my $url = $_[0];
	#~ print STDOUT if ($verbosity >= 3);
	#~ if ($url =~ m/^
		#~ (
			#~ (
				#~ (http|https|ftp):\/\/)				# http://
				#~ ([a-zA-Z])+							# at least an alphanetical char (url can't begin with an 0 or a "-" or "."
				#~ ([[a-zA-Z0-9]\-\.])?(\.)				# then zero or more alpha or "-" or
				#~ (\.)								# then a dot
				#~ ([[a-zA-Z]]){2,5}					# then a TLD: io, com, name, ...
				#~ (\/)								# then a slash
				#~ ([[a-zA-Z0-9]\/+=%&_\.~?\-]*)		# then zero or more
		#~ )*$
		#~ /x) { return 1; }
	#~ else { return 0; }
#~ }


1;

__END__

Ressources
* https://en.wikipedia.org/wiki/ICalendar
* https://tools.ietf.org/html/rfc5545 (Obsoletes: RFC 2445)
* https://metacpan.org/search?q=ical&size=20


Point of particular attention:
1. 	CATEGORIES:http://schemas.google.com/g/2005#event --> ":" comes two times

2. 	Lines of text SHOULD NOT be longer than 75 octets, excluding the line
	break.  Long content lines SHOULD be split into a multiple line
	representations using a line "folding" technique.  That is, a long
	line can be split between any two characters by inserting a CRLF
	immediately followed by a single linear white-space character (i.e.,
	SPACE or HTAB).  Any sequence of CRLF followed immediately by a
	single linear white-space character is ignored (i.e., removed) when
	processing the content type.

	The default charset for an iCalendar stream is UTF-8
	as defined in [RFC3629].

	Source: https://tools.ietf.org/html/rfc5545



Example of iCal file produced by Google Calendar -- https://www.google.com/calendar/
Note that the first event is a "all day" event.

BEGIN:VCALENDAR
PRODID:-//Google Inc//Google Calendar 70.9054//EN
VERSION:2.0
CALSCALE:GREGORIAN
METHOD:PUBLISH
X-WR-CALNAME:C Nepote (Fing)
X-WR-TIMEZONE:Europe/Paris
X-WR-CALDESC:Agenda de Charles Nepote à la Fing (2007-...)
BEGIN:VTIMEZONE
TZID:Europe/Paris
X-LIC-LOCATION:Europe/Paris
BEGIN:DAYLIGHT
TZOFFSETFROM:+0100
TZOFFSETTO:+0200
TZNAME:CEST
DTSTART:19700329T020000
RRULE:FREQ=YEARLY;BYMONTH=3;BYDAY=-1SU
END:DAYLIGHT
BEGIN:STANDARD
TZOFFSETFROM:+0200
TZOFFSETTO:+0100
TZNAME:CET
DTSTART:19701025T030000
RRULE:FREQ=YEARLY;BYMONTH=10;BYDAY=-1SU
END:STANDARD
END:VTIMEZONE
BEGIN:VTIMEZONE
TZID:Africa/Johannesburg
X-LIC-LOCATION:Africa/Johannesburg
BEGIN:STANDARD
TZOFFSETFROM:+0200
TZOFFSETTO:+0200
TZNAME:SAST
DTSTART:19700101T000000
END:STANDARD
END:VTIMEZONE
BEGIN:VTIMEZONE
TZID:Europe/Warsaw
X-LIC-LOCATION:Europe/Warsaw
BEGIN:DAYLIGHT
TZOFFSETFROM:+0100
TZOFFSETTO:+0200
TZNAME:CEST
DTSTART:19700329T020000
RRULE:FREQ=YEARLY;BYMONTH=3;BYDAY=-1SU
END:DAYLIGHT
BEGIN:STANDARD
TZOFFSETFROM:+0200
TZOFFSETTO:+0100
TZNAME:CET
DTSTART:19701025T030000
RRULE:FREQ=YEARLY;BYMONTH=10;BYDAY=-1SU
END:STANDARD
END:VTIMEZONE
BEGIN:VTIMEZONE
TZID:Europe/London
X-LIC-LOCATION:Europe/London
BEGIN:DAYLIGHT
TZOFFSETFROM:+0000
TZOFFSETTO:+0100
TZNAME:BST
DTSTART:19700329T010000
RRULE:FREQ=YEARLY;BYMONTH=3;BYDAY=-1SU
END:DAYLIGHT
BEGIN:STANDARD
TZOFFSETFROM:+0100
TZOFFSETTO:+0000
TZNAME:GMT
DTSTART:19701025T020000
RRULE:FREQ=YEARLY;BYMONTH=10;BYDAY=-1SU
END:STANDARD
END:VTIMEZONE

BEGIN:VEVENT
DTSTART;VALUE=DATE:20141224
DTEND;VALUE=DATE:20150105
DTSTAMP:20141216T124541Z
UID:a3q3m58r7eln3q5hdeqm39t1fk@google.com
CREATED:20141216T124228Z
DESCRIPTION:
LAST-MODIFIED:20141216T124228Z
LOCATION:
SEQUENCE:0
STATUS:CONFIRMED
SUMMARY:#congés
TRANSP:TRANSPARENT
END:VEVENT

BEGIN:VEVENT
DTSTART:20141203T130000Z
DTEND:20141203T143000Z
DTSTAMP:20141201T155509Z
UID:7sadjj3qrpso3bpanm2q3d5ib0@google.com
CREATED:20141114T150520Z
DESCRIPTION:
LAST-MODIFIED:20141201T113149Z
LOCATION:
SEQUENCE:1
STATUS:CONFIRMED
SUMMARY:Conférence téléléphonique La Péniche #infolab
TRANSP:OPAQUE
END:VEVENT
