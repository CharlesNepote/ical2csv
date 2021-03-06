# NAME

Ical2csv - Converts an iCal file (aka .ics) to a CSV file. __Still early stage__

# VERSION

Version 0.3.4, 20150226.

# SYNOPSYS

Ical2csv.pm --file=`<FILE>` \[--outputfile=<FILE>\] \[--sep=,\] \[--verbosity=0|1|2|3\]

Ical2csv.pm --url=`<url>` \[--outputfile=<FILE>\] \[--sep=,\] \[--verbosity=0|1|2|3\]

Usage: $ perl ./Ical2csv.pm --file=thisical.ics

Usage: $ perl ./Ical2csv.pm --file=thisical.ics --sep=; --vprop=SUMMARY,LOCATION,DTSTART,DTEND,DESCRIPTION

\--> Create a CSV file called thisical.ics.csv

Usage: $ perl ./Ical2csv.pm --url=http://example.com/calendar.ics

\--> Create a CSV fille called basic.ics.csv

Should work with a basic Perl (without particular module). Needs curl tool to import ics file from an URL.

# DESCRIPTION

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
    --vprop           [optional] iCal properties to process, delimited by a comma.
                      Example: --vprop="SUMMARY,DTSTART"
                      List of the possible properties:
                      "SUMMARY", "LOCATION", "DTSTART", "DTEND",
                      "DTSTAMP", "UID",
                      "CREATED", "DESCRIPTION", "LAST-MODIFIED",
                      "SEQUENCE", "STATUS", "CONFIRMED", "TRANSP"
    --v, --verbosity  [optional] verbose mode represented by a number between 0 and 3. Default is "1" which means small verbosity.
                      0 means no verbosity at all.
                      Ex. --v=1



# INSTALLATION

To use this script:

- simply download [https://raw.githubusercontent.com/CharlesNepote/ical2csv/master/lib/Data/Ical2csv.pm](https://raw.githubusercontent.com/CharlesNepote/ical2csv/master/lib/Data/Ical2csv.pm)
- use it with perl interpreter. Example:
    - perl ./Ical2csv.pm --file=thisical.ics



This should work under Linux, MacOS and may be Windows as well (except the --url option).

Alternatively, you can make the script executable, thus you can use it without 'perl' command.

Under Linux:

    chmod a+x Ical2csv.pm
    ./Ical2csv.pm --file=thisical.ics

Under MacOS:

    chmod a+x Ical2csv.pm
    ./Ical2csv.pm --file=thisical.ics



# AUTHOR

Charles Nepote <charles@nepote.org>

# LICENCE

Open Source software under BSD licence.
