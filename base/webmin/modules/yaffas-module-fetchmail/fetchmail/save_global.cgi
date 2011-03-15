#!/usr/bin/perl
# save_global.cgi
# Save global options

use Yaffas;
use Yaffas::Service;

Yaffas::init_webmin();

require './fetchmail-lib.pl';
ReadParse();
header();

$in{'interval'} =~ /^\d+$/ || &error($text{'start_einterval'});

open FILE, "<", $config{config_file};
my @content = <FILE>;
close FILE;

@content = grep {$_ !~ /set daemon/} @content;
@content = ("set daemon $in{interval}\n", @content);

open FILE, "> $config{config_file}";
print FILE $_ foreach (@content);
close FILE;

Yaffas::Service::control(Yaffas::Service::FETCHMAIL(), Yaffas::Service::RESTART());

footer();