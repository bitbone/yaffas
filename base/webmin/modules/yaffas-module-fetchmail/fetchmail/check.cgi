#!/usr/bin/perl
# check.cgi
# Run a fetchmail config file

use Yaffas;
use Yaffas::UI;
Yaffas::init_webmin();

require './fetchmail-lib.pl';
&ReadParse();
$| = 1;
$theme_no_table = 1;
&header($text{'check_title'}, "");

print Yaffas::UI::start_section($text{check_title});
if ($config{'config_file'}) {
	$file = $config{'config_file'};
	}
else {
	&can_edit_user($in{'user'}) || &error($text{'poll_ecannot'});
	@uinfo = getpwnam($in{'user'});
	$file = "$uinfo[7]/.fetchmailrc";
	}

$cmd = "$config{'fetchmail_path'} -d0 -v -f '$file'";
if ($config{'mda_command'}) {
	$cmd .= " -m '$config{'mda_command'}'";
	}
if (defined($in{'idx'})) {
	@conf = &parse_config_file($file);
	$poll = $conf[$in{'idx'}];
	$cmd .= " $poll->{'poll'}";
	}

print &text('check_exec', "<tt>$cmd</tt>"),"<p>\n";
print "<pre>";
if ($< == 0) {
	open(CMD, "su '$in{'user'}' -c '$cmd' 2>&1 |");
	&additional_log("exec", undef, "su '$in{'user'}' -c '$cmd'");
	}
else {
	# For usermin, which has already switched
	open(CMD, "$cmd 2>&1 |");
	}
while(<CMD>) {
	print &html_escape($_);
	}
close(CMD);
print "</pre>\n";

if ($? > 256) { print "<b>$text{'check_failed'}</b> <p>\n"; }
else { print "$text{'check_ok'} <p>\n"; }

&webmin_log("check", defined($in{'idx'}) ? "server" : "file",
	    $config{'config_file'} ? $file : $in{'user'}, $poll);
print Yaffas::UI::end_section();
footer();

