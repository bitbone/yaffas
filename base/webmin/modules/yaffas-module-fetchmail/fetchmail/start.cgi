#!/usr/bin/perl
# start.cgi
# Start the fetchmail daemon

use Yaffas;
Yaffas::init_webmin();

require './fetchmail-lib.pl';
&ReadParse();
&error_setup($text{'start_err'});
$config{'config_file'} || $< || &error($text{'start_ecannot'});


if ($config{'start_cmd'}) {
	$out = &backquote_logged("$config{'start_cmd'} 2>&1");
	}
else {
	$in{'interval'} =~ /^\d+$/ || &error($text{'start_einterval'});

	open FILE, "< $config{config_file}";
	my @content = <FILE>;
	close FILE;

	@content = grep {$_ !~ /set daemon/} @content;
	@content = ("set daemon $in{interval}\n", @content);

	open FILE, "> $config{config_file}";
	print FILE $_ foreach (@content);
	close FILE;


	$mda = " -m '$config{'mda_command'}'" if ($config{'mda_command'});
	if ($< == 0) {
		$out = &backquote_logged("/etc/init.d/fetchmail start 2>&1");
		}
	else {
		$out = &backquote_logged("$config{'fetchmail_path'} -d $in{'interval'} $mda 2>&1");
		}
	}
if ($?) {
	&error("<tt>$out</tt>");
	}
sleep 1;
&webmin_log("start", undef, undef, \%in);
&redirect("");

