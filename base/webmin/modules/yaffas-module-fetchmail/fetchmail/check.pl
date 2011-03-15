#!/usr/local/bin/perl
# check.pl
# Run fetchmail, and send the output somewhere

$no_acl_check++;
$ENV{'REMOTE_USER'} = getpwuid($<);
require './fetchmail-lib.pl';

# Parse command-line args
while(@ARGV > 0) {
	local $a = shift(@ARGV);
	if ($a eq "--mail") {
		$mail = shift(@ARGV);
		}
	elsif ($a eq "--file") {
		$file = shift(@ARGV);
		}
	elsif ($a eq "--output") {
		$output = 1;
		}
	elsif ($a eq "--user") {
		$user = shift(@ARGV);
		}
	}

# Build the command
$cmd = "$config{'fetchmail_path'} -v -f ".quotemeta($fetchmail_config);
if ($config{'mda_command'}) {
	$cmd .= " -m ".quotemeta($config{'mda_command'});
	}
if ($user && $user ne "root") {
	$cmd = "su ".quotemeta($user)." -c ".quotemeta($cmd);
	}

# Run it
if ($file) {
	# Just write to a file
	system("($cmd) >".quotemeta($file)." 2>&1 </dev/null");
	}
elsif ($mail) {
	# Capture output and email
	$out = `($cmd) 2>&1 </dev/null`;
	$mm = $module_info{'usermin'} ? "mailbox" : "sendmail";
	$fr = $module_info{'usermin'} ? $remote_user_info[0] : "webmin";
	if (&foreign_check($mm)) {
		&foreign_require($mm, "$mm-lib.pl");
		&foreign_require($mm, "boxes-lib.pl");
		$mail = { 'headers' =>
				[ [ 'From', $fr."\@".&get_system_hostname() ],
				  [ 'Subject', "Fetchmail output" ],
				  [ 'To', $mail ] ],
			  'attach'  => [ { 'headers' => [ [ 'Content-type',
							    'text/plain' ] ],
					   'data' => $out } ]
			};
		&foreign_call($mm, "send_mail", $mail);
		}
	else {
		print "$mm module not installed - could not email the following output :\n";
		print $out;
		}
	}
elsif ($output) {
	# Output goes to cron
	system("($cmd) </dev/null");
	}
else {
	# Just throw away output
	system("($cmd) >/dev/null 2>&1 </dev/null");
	}

