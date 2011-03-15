#!/usr/bin/perl
# run_file.cgi
# Run fetchmail on some config file

use Yaffas;
Yaffas::init_webmin();

require './fetchmail-lib.pl';
&ReadParse();
&header($text{'run_title'}, "");
print "<hr>\n";
