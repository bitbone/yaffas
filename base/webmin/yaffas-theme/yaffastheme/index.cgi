#!/usr/bin/perl

use strict;
require './web-lib.pl';
use warnings;

use Yaffas;
use CGI::Carp qw(warningsToBrowser);
use Yaffas::UI;
use Yaffas::File;


use Storable;
init_config();

ReadParse();

# is there already somebody logged in?
my $file = "/var/webmin/logged.stor";
if(-f $file){
	my $h = retrieve $file;
	if($h->{'sid'} ne $main::session_id){
		&redirect("/admin.cgi");
	}
}

header("login");

footer("login");
