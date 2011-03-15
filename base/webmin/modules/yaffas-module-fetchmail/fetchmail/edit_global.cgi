#!/usr/bin/perl
# edit_global.cgi
# Edit options for all poll sections in a file
use Yaffas::UI qw(start_section end_section section_button $Cgi);
use Yaffas;
use strict;

Yaffas::init_webmin();

require './fetchmail-lib.pl';
require "forms.pl";

ReadParse();
header();

show_global_settings();

footer();
