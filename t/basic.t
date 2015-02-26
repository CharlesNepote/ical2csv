#!/usr/bin/perl


use strict;
use warnings;
use Test::More;
plan 'no_plan';
# plan tests => 4;

use File::Compare;
use lib '../lib';
use Data::Ical2csv;

my @vprop = ();

# Data::Ical2csv::ical2csv($C{inputfile}, $C{url}, outputfile, $C{dlmtr}, \@vprop, $C{endofline}, $C{verbosity});

# 1. If neither inputfile or url is provided
my $error1 = Data::Ical2csv::ical2csv(
	sep => ",",
	vprop => \@vprop,
	endofline => "\r\n",
	verbosity => 0,
	);
is($error1, 1, "Data::Ical2csv::ical2csv ends correctly (1) if neither inputfile or url is provided");

# 2. If both inputfile and url are provided
my $error_both = Data::Ical2csv::ical2csv(
	inputfile => "basic.ics",
	url => "http://example.com/",
	sep => ",",
	vprop => \@vprop,
	endofline => "\r\n",
	verbosity => 0,
	);
is($error_both, 2, "Data::Ical2csv::ical2csv ends correctly (2) if both inputfile and url are provided");

# 3. If curl can't open the url provided
my $test_url = Data::Ical2csv::ical2csv(
	url=> "http://________",
	sep => ",",
	vprop => \@vprop,
	endofline => "\r\n",
	verbosity => 0,
	);
is($test_url, 3, "Data::Ical2csv::ical2csv ends correctly (3) if curl can't open the url provided");

# 4-5. First range of tests
my $test1 = Data::Ical2csv::ical2csv(
	inputfile => "test.ics",
	sep => ",",
	vprop => \@vprop,
	endofline => "\r\n",
	verbosity => 0,
	);
is($test1, 0, "Data::Ical2csv::ical2csv ends correctly (0)");
is(compare("test.ics.csv", "control.test.ics.csv"), 0, "test.ics.csv et control.test.ics.csv are the same");

# 6-7. Second range of tests: --output="output.csv"
my $test2 = Data::Ical2csv::ical2csv(
	inputfile => "test.ics",
	outputfile => "output.csv",
	sep => ",",
	vprop => \@vprop,
	endofline => "\r\n",
	verbosity => 0,
	);
is($test2, 0, "Data::Ical2csv::ical2csv ends correctly (0)");
is(compare("output.csv", "control.test.ics.csv"), 0, "output.csv et control.test.ics.csv are the same");


# 8-9. Test --file="test.ics" without any other argument
my $only_file_argument = Data::Ical2csv::ical2csv(
	inputfile => "test.ics",
	verbosity => 0,
	);
is($only_file_argument, 0, "Data::Ical2csv::ical2csv ends correctly (0)");
is(compare("test.ics.csv", "control.test.ics.csv"), 0, "test.ics.csv et control.test.ics.csv are the same");


# 10-11. Test --prop argument
my $test_prop = Data::Ical2csv::ical2csv(
	inputfile => "test.ics",
	vprop => ["SUMMARY", "DTSTART"],
	outputfile => "test.prop.ics.csv",
	verbosity => 0,
	);
is($test_prop, 0, "Data::Ical2csv::ical2csv ends correctly (0) with prop argument");
is(compare("test.prop.ics.csv", "control.test.prop.ics.csv"), 0, "test.prop.ics.csv et control.test.prop.ics.csv are the same");



my @dlmtrs = (",", ";", "|", "\t");
my @endoflines = ("\r\n", "\n", "\r");

my ($d, $e, $out);
foreach my $dlmtr (@dlmtrs) {
	$d++;
	foreach my $endofline (@endoflines) {
		$e++;
		$out = "output.".$d.$e.".csv";
		my $test = Data::Ical2csv::ical2csv(
			inputfile => "test.ics",
			outputfile => $out,
			sep => $dlmtr,
			vprop => \@vprop,
			endofline => $endofline,
			verbosity => 0,
			);
		is($test, 0, "Data::Ical2csv::ical2csv ends correctly (0) -- outputfile=$out, dlmtr=$dlmtr, endofline=$endofline");
		is(compare($out, "control.".$out), 0, "$out et control.$out are the same");
	}
}
