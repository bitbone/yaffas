#!/usr/bin/perl
# edit_poll.cgi
# Display one server polled by fetchmail
use strict;
use Yaffas;
use Yaffas::UI qw(start_section end_section section_button);
use Yaffas::Product;
use Yaffas::Mail::Mailalias;
use Sort::Naturally;

Yaffas::init_webmin();
our $cgi = $Yaffas::UI::Cgi;

require './fetchmail-lib.pl';
require "forms.pl";

ReadParse();

header();

show_edit(0);

footer();
