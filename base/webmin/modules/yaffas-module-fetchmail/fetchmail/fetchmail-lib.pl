# fetchmail-lib.pl
# Functions for parsing fetchmail config files

#%access = &get_module_acl();

if ($module_info{'usermin'}) {
	if ($no_switch_user) {
		@remote_user_info = getpwnam($remote_user);
		}
	else {
		&switch_to_remote_user();
		}
	$cron_user = $remote_user;
	$fetchmail_config = "$remote_user_info[7]/.fetchmailrc";
	}
else {
	$cron_user = "root";
	$fetchmail_config = $config{'config_file'};
	}

# parse_config_file(file, [&global])
# Parses a fetchmail config file into a list of hashes, each representing
# one mail server to poll
sub parse_config_file
{
local $lnum = 0;
local ($line, @rv, @toks);

# Tokenize the file
open(FILE, $_[0]);
while($line = <FILE>) {
	$line =~ s/\r|\n//g;
	$line =~ s/^\s*#.*$//;
	while($line =~ /^[\s:;,]*"([^"]*)"(.*)$/ ||
	      $line =~ /^[\s:;,]*'([^"]*)'(.*)$/ ||
	      $line =~ /^[\s:;,]*([^\s:;,]+)(.*)$/) {
		push(@toks, [ $1, $lnum ]);
		$line = $2;
		}
	$lnum++;
	}
close(FILE);

# Split into poll sections
@toks = grep { $_->[0] !~ /^(and|with|has|wants|options|here)$/i } @toks;
local ($poll, $user, $i);
for($i=0; $i<@toks; $i++) {
	local $t = $toks[$i];

	# Server options
	if ($t->[0] eq 'poll' || $t->[0] eq 'server' ||
	    $t->[0] eq 'skip' || $t->[0] eq 'defaults') {
		# Start of a new poll
		$poll = { 'line' => $t->[1],
			  'file' => $_[0],
			  'index' => scalar(@rv),
			  'skip' => ($t->[0] eq 'skip'),
			  'defaults' => ($t->[0] eq 'defaults') };
		$poll->{'poll'} = $toks[++$i]->[0] if (!$poll->{'defaults'});
		undef($user);
		push(@rv, $poll);
		}
	elsif ($t->[0] eq 'proto' || $t->[0] eq 'protocol') {
		$poll->{'proto'} = $toks[++$i]->[0];
		}
	elsif ($t->[0] eq 'via') {
		$poll->{'via'} = $toks[++$i]->[0];
		}
	elsif ($t->[0] eq 'port') {
		$poll->{'port'} = $toks[++$i]->[0];
		}
	elsif ($t->[0] eq 'timeout') {
		$poll->{'timeout'} = $toks[++$i]->[0];
		}
	elsif ($t->[0] eq 'interface') {
		$poll->{'interface'} = $toks[++$i]->[0];
		}
	elsif ($t->[0] eq 'monitor') {
		$poll->{'monitor'} = $toks[++$i]->[0];
		}
	elsif ($t->[0] eq 'envelope') {
		$poll->{'envelope'} = $toks[++$i]->[0];
		}

	# User options
	elsif ($t->[0] eq 'user' || $t->[0] eq 'username') {
		$user = { 'user' => $toks[++$i]->[0] };
		push(@{$poll->{'users'}}, $user);
		}
	elsif ($t->[0] eq 'pass' || $t->[0] eq 'password') {
		$user->{'pass'} = $toks[++$i]->[0];
		}
	elsif ($t->[0] eq 'is' || $t->[0] eq 'to') {
		$i++;
		while($i < @toks &&
		      $toks[$i]->[1] == $t->[1]) {
			push(@{$user->{'is'}}, $toks[$i]->[0]);
			$i++;
			}
		$i--;
		}
	elsif ($t->[0] eq 'folder') {
		$user->{'folder'} = $toks[++$i]->[0];
		}
	elsif ($t->[0] eq 'keep') { $user->{'keep'} = 1; }
	elsif ($t->[0] eq 'nokeep') { $user->{'keep'} = 0; }
	elsif ($t->[0] eq 'no' && $toks[$i+1]->[0] eq 'keep') {
		$user->{'keep'} = 0;
		$i++;
		}
	elsif ($t->[0] eq 'fetchall') { $user->{'fetchall'} = 1; }
	elsif ($t->[0] eq 'nofetchall') { $user->{'fetchall'} = 0; }
	elsif ($t->[0] eq 'no' && $toks[$i+1]->[0] eq 'fetchall') {
		$user->{'fetchall'} = 0;
		$i++;
		}
	elsif ($t->[0] eq 'ssl') { $user->{'ssl'} = 1; }
	elsif ($t->[0] eq 'nossl') { $user->{'ssl'} = 0; }
	elsif ($t->[0] eq 'no' && $toks[$i+1]->[0] eq 'ssl') {
		$user->{'ssl'} = 0;
		$i++;
		}
	elsif ($t->[0] eq 'preconnect') {
		$user->{'preconnect'} = $toks[++$i]->[0];
		}
	elsif ($t->[0] eq 'postconnect') {
		$user->{'postconnect'} = $toks[++$i]->[0];
		}
	elsif ($t->[0] eq 'aka') {
		$user->{'aka'} = $toks[++$i]->[0];
		}
	elsif ($t->[0] eq 'smtpaddress') {
		$user->{'smtpaddress'} = $toks[++$i]->[0];
		}

	else {
		# Found an unknown option!
		if ($user) {
			push(@{$user->{'unknown'}}, $t->[0]);
			}
		elsif ($poll) {
			push(@{$poll->{'unknown'}}, $t->[0]);
			}
		}

	if ($poll) {
		if ($i<@toks) {
			$poll->{'eline'} = $toks[$i]->[1];
			}
		else {
			$poll->{'eline'} = $toks[$#toks]->[1];
			}
		}
	}

return @rv;
}

# create_poll(&poll, file)
# Add a new poll section to a fetchmail config file
sub create_poll
{
	local $lref = &read_file_lines($_[1]);
	if ($_[0]->{'defaults'})
	{
		# Put a new defaults section at the top
		splice(@$lref, 0, 0, &poll_lines($_[0]));
	}
	else 
	{
		push(@$lref, &poll_lines($_[0]));
	}
	&flush_file_lines();

	# set logfile to seperate log
	my $fm_log = "/var/log/fetchmail.log";
	open FILE, "< $config{config_file}";
	my @content = <FILE>;
	close FILE;

	@content = grep {! /^(set logfile|set no syslog)/} @content;
	@content = ("set logfile $fm_log\n", "set no syslog\n",  @content);
	
	if (!grep {/set\s+daemon\s+\d+/} @content) {
		unshift @content, "set daemon 300\n";
	}

	open FILE, "> $config{config_file}";
	print FILE $_ foreach (@content);
	close FILE;

	# touch log file and change owner to fetchmail
	if (! -f $fm_log )
	{
		open FILE, "> $fm_log";
		print FILE "";
		close FILE;
	}
	
	if( ($login,$pass,$uid,$gid) = getpwnam("fetchmail") )
	{
		chown $uid, -1, $fm_log;
	}
}

# delete_poll(&poll, file)
# Delete a poll section from a fetchmail config file
sub delete_poll
{
local $lref = &read_file_lines($_[1]);
splice(@$lref, $_[0]->{'line'}, $_[0]->{'eline'} - $_[0]->{'line'} + 1);
&flush_file_lines();
}

# modify_poll(&poll, file)
# Modify a poll section in a fetchmail config file
sub modify_poll
{
local $lref = &read_file_lines($_[1]);
splice(@$lref, $_[0]->{'line'}, $_[0]->{'eline'} - $_[0]->{'line'} + 1,
       &poll_lines($_[0]));
&flush_file_lines();
}

sub poll_lines
{
use Yaffas::Module::Mailsrv;

local @rv;
if ($_[0]->{'skip'}) {
	push(@rv, "skip $_[0]->{'poll'}");
	}
elsif ($_[0]->{'defaults'}) {
	push(@rv, "defaults $_[0]->{'poll'}");
	}
else {
	push(@rv, "poll $_[0]->{'poll'}");
	}
push(@rv, "\tproto $_[0]->{'proto'}") if ($_[0]->{'proto'});
push(@rv, "\tvia $_[0]->{'via'}") if ($_[0]->{'via'});
push(@rv, "\tport $_[0]->{'port'}") if ($_[0]->{'port'});
push(@rv, "\ttimeout $_[0]->{'timeout'}") if ($_[0]->{'timeout'});
push(@rv, "\tinterface $_[0]->{'interface'}") if ($_[0]->{'interface'});
push(@rv, "\tmonitor $_[0]->{'monitor'}") if ($_[0]->{'monitor'});
push(@rv, "\tenvelope $_[0]->{'envelope'}") if ($_[0]->{'envelope'});
push(@rv, "\t".join(" ", map { /^\S+$/ ? $_ : "\"$_\"" }
			     @{$_[0]->{'unknown'}})) if (@{$_[0]->{'unknown'}});
if ($_[0]->{'aka'})	     
{
	push(@rv, "\taka $_[0]->{'aka'}") if ($_[0]->{'aka'});	     
}
else
{
	push(@rv, "\t#aka ");	     
}

foreach $u (@{$_[0]->{'users'}}) {
	push(@rv, "\tuser \"$u->{'user'}\"");
	push(@rv, "\tpass \"$u->{'pass'}\"") if ($u->{'pass'});
	push(@rv, "\tis ".join(" ", @{$u->{'is'}})) if (@{$u->{'is'}});
	push(@rv, "\tfolder $u->{'folder'}") if ($u->{'folder'});
	push(@rv, "\tkeep") if ($u->{'keep'} eq '1');
	push(@rv, "\tnokeep") if ($u->{'keep'} eq '0');
	push(@rv, "\tfetchall") if ($u->{'fetchall'} eq '1');
	push(@rv, "\tno fetchall") if ($u->{'fetchall'} eq '0');
	push(@rv, "\tssl") if ($u->{'ssl'} eq '1');
	push(@rv, "\tno ssl") if ($u->{'ssl'} eq '0');
	push(@rv, "\tpreconnect \"$u->{'preconnect'}\"")
		if ($u->{'preconnect'});
	push(@rv, "\tpostconnect \"$u->{'postconnect'}\"")
		if ($u->{'postconnect'});
	push(@rv, "\tsmtpaddress \"$u->{'smtpaddress'}\"")
		if ($u->{'smtpaddress'});
	push(@rv, "\t".join(" ", map { /^\S+$/ ? $_ : "\"$_\"" }
			     @{$u->{'unknown'}})) if (@{$u->{'unknown'}});
	}

return @rv;
}

# can_edit_user(user)
=pod
sub can_edit_user
{
local %umap;
map { $umap{$_}++; } split(/\s+/, $access{'users'});
if ($access{'mode'} == 1 && !$umap{$_[0]} ||
    $access{'mode'} == 2 && $umap{$_[0]}) { return 0; }
elsif ($access{'mode'} == 3) {
	return $remote_user eq $_[0];
	}
else {
	return 1;
	}
}
=cut

# get_fetchmail_version([&out])
sub get_fetchmail_version
{
local $out = `$config{'fetchmail_path'} -V 2>&1 </dev/null`;
${$_[0]} = $out if ($_[0]);
return $out =~ /fetchmail\s+release\s+(\S+)/ ? $1 : undef;
}

1;

