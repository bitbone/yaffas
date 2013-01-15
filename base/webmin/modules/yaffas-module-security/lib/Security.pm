#!/usr/bin/perl -w
package Yaffas::Module::Security;
use strict;
use warnings;
use Yaffas qw(do_back_quote);
use Yaffas::Exception;
use Yaffas::Service qw(POSTFIX CLAMAV POLICYD_WEIGHT AMAVIS CLAMAV SPAMASSASSIN RESTART RELOAD control);
use Yaffas::File;
use Yaffas::Constant;
use Yaffas::Conf;
use Yaffas::Conf::Function;
use Yaffas::Check;
use Yaffas::Module::Proxy;
use Error qw(:try);

sub BEGIN {
	our @ISA = qw/Yaffas::Module/;
	our @EXPORT = qw//;
	our @EXPORT_OK = qw//;
}

=head1 NAME

B<Yaffas::Module::Security> - Manage mail security settings

=head1 SYNOPSIS

  check_policy();
  check_spam();
  check_antivirus();
  ...

=head1 DESCRIPTION

B<Yaffas::Module::Security> lets you manage various settings for amavis,
spamassassin, clamav and policyd-weight.

=cut

=head1 METHODS

=over 4

=cut

my $conf_policy	= Yaffas::Constant::FILE->{'policyd_conf'};
my $conf_clamd	= Yaffas::Constant::FILE->{'clamd_conf'};
my $conf_spam	= Yaffas::Constant::FILE->{'sa_local_conf'};
my $conf_amavis	= Yaffas::Constant::FILE->{'amavis_conf'};

my $app_freshclam = Yaffas::Constant::FILE->{'freshclam'};

my $wl_postfix	= Yaffas::Constant::FILE->{'wl_postfix'};
my $wl_amavis	= Yaffas::Constant::FILE->{'wl_amavis'};



=item check_policy()

Returns 1 if policyd-weight is active. Returns undef is policyd-weight is
B<not> active. 

=cut

sub check_policy {
	my $postfix = _get_postfix("smtpd_recipient_restrictions");
	return undef unless $postfix && $postfix =~ m#check_policy_service inet:[^:]+:12525#;

	return 1;
}

=item check_amavis()

Returns 1 if amavis is activated in postfix. Returns undef if not;

=cut

sub check_amavis {
	my $postfix = _get_postfix("content_filter");
	return undef unless $postfix && $postfix =~ m#amavis#;

	return 1;
}

=item check_spam()

Returns 1 if spamassassin is active. Returns undef if not.

=cut

sub check_spam {
	my %amavis = _get_amavis();
	if(Yaffas::Constant::OS =~ m/RHEL\d/ ) {
		return undef if exists $amavis{'bypass_spam_checks_maps'};
	} else {
		#for Ubuntu has inverted logic
		return undef unless exists $amavis{'bypass_spam_checks_maps'};
	}

	return 1;
}

=item check_antivirus()

Returns 1 if clamav is active. Returns undef if not.

=cut

sub check_antivirus {
	my %amavis = _get_amavis();
	if(Yaffas::Constant::OS =~ m/RHEL\d/ ) {
		return undef if exists $amavis{'bypass_virus_checks_maps'};
	} else {
		#for Ubuntu has inverted logic
		return undef unless exists $amavis{'bypass_virus_checks_maps'};
	}

	return 1;
}

=item enable_policy()

Enables policy-weightd in postfix if it isn't already enabled.

=cut 

sub enable_policy { 
	save_policy_state(1);
}


=item disable_policy()

Disables policyd-weight in postfix if it is enabled.

=cut

sub disable_policy {
	save_policy_state(0);
}

sub save_policy_state {
	my $state = shift;

	if ($state) {
		_set_postfix("smtpd_helo_required", "yes");
		_set_postfix("smtpd_delay_reject", "yes");
		_set_postfix("smtpd_recipient_restrictions", "permit_mynetworks, permit_sasl_authenticated, reject_unauth_destination, reject_unknown_recipient_domain, check_client_access hash:/opt/yaffas/config/postfix/whitelist-postfix, check_policy_service inet:127.0.0.1:12525");

		control(POSTFIX(), RESTART());
	}
	else {
		_set_postfix("smtpd_recipient_restrictions", "permit_mynetworks, permit_sasl_authenticated, reject_unauth_destination, reject_unknown_recipient_domain");
		control(POSTFIX(), RESTART());
	}
}


=item enable_amavis()

Enables amavis in postfix if it isn't already enabled.

=cut

sub enable_amavis {
	_set_postfix("content_filter", "amavis:[127.0.0.1]:10024");
	if (eval { require Yaffas::Module::MailDisclaimers; 1 }) {
		# force config re-patching
		Yaffas::Module::MailDisclaimers::update_service(1);
	}
	control(POSTFIX(), RESTART());
}


=item disable_amavis()

Disables amavis in postfix if it is enabled

=cut

sub disable_amavis {
	_set_postfix("content_filter", "");
	if (eval { require Yaffas::Module::MailDisclaimers; 1 }) {
		# force config re-patching
		Yaffas::Module::MailDisclaimers::update_service(1);
	}
	control(POSTFIX(), RESTART());
}


=item disable_spamassassin()

Disable spamassassin in amavis if it isn't already disabled.

=cut

sub disable_spamassassin {
	save_spamassassin_state(0);
}


=item enable_spamassassin()

Enable spamassassin in amavis if it is disabled.

=cut

sub enable_spamassassin {
	save_spamassassin_state(1);
}

sub save_spamassassin_state {
	my $state = shift;

	if ($state) {
		enable_amavis() unless check_amavis();
	}
	else {
		disable_amavis() unless check_antivirus();
	}

	my $f = Yaffas::File->new($conf_amavis);
	my $num = $f->search_line("\@bypass_spam_checks_maps");

	my $line = $f->get_content($num);

	if ($state) {
		if(Yaffas::Constant::OS =~ m/RHEL\d/ ) {
			$line =~ s/^/#/;
		} else {
			#for Ubuntu has inverted logic
			$line =~ s/^#//;
		}
	}
	else {
		if(Yaffas::Constant::OS =~ m/RHEL\d/ ) {
			$line =~ s/^#//;
		} else {
			#for Ubuntu has inverted logic
			$line =~ s/^/#/;
		}
	}

	$f->splice_line($num, 1, $line);
	$f->write();

	control(AMAVIS(), RESTART());

}


=item disable_clamav()

Disable clamav in amavis if it isn't already disabled

=cut

sub disable_clamav {
	save_clamav_state(0);
}

=item enable_clamav()

Enbale clamav in amavis if it is disabled.

=cut

sub enable_clamav {
	save_clamav_state(1);
}

sub save_clamav_state {
	my $state = shift;

	if ($state) {
		enable_amavis() unless check_amavis();
	}
	else {
		disable_amavis() unless check_spam();
	}


	my $f = Yaffas::File->new($conf_amavis);
	my $num = $f->search_line("\@bypass_virus_checks_maps");

	my $line = $f->get_content($num);
	if ($state) {
		if(Yaffas::Constant::OS =~ m/RHEL\d/ ) {
			$line =~ s/^/#/;
		} else {
			#for Ubuntu has inverted logic
			$line =~ s/^#//;
		}
	}
	else {
		if(Yaffas::Constant::OS =~ m/RHEL\d/ ) {
			$line =~ s/^#//;
		} else {
			#for Ubuntu has inverted logic
			$line =~ s/^/#/;
		}
	}

	$f->splice_line($num, 1, $line);
	$f->write();

	control(AMAVIS(), RESTART());
}

=item sa_tag2_level([level])

Sets the $sa_tag2_level_deflt in 60-yaffas if you provide a value.
If you provide no value, it just quits.

This option adds the 'spam detected' headers.

=cut

sub sa_tag2_level {
	my $set = shift;
	my $y = Yaffas::File->new($conf_amavis) || throw Yaffas::Exception("$conf_amavis: $!");
	my $num = $y->search_line('sa_tag2_level_deflt');

	my $line = $y->get_content($num);
	return undef unless $line =~ m#sa_tag2_level_deflt\s*=\s*([0-9.]+)#;
	return $1 unless $set;

	$line = '$sa_tag2_level_deflt = ' . $set . ';';
	$y->splice_line($num, 1, $line);
	$y->save();

	control(AMAVIS(), RESTART());
}


=item sa_kill_level([level])

Sets the $sa_kill_level_deflt in 60-yaffas if you provide a value.
If you provide no value, it just quits.

This option triggers spam evasive actions.

=cut

sub sa_kill_level {
	my $set = shift;
	my $y = Yaffas::File->new($conf_amavis) || throw Yaffas::Exception("$conf_amavis: $!");
	my $num = $y->search_line('sa_kill_level_deflt');

	my $line = $y->get_content($num);
	return undef unless $line =~ m#sa_kill_level_deflt\s*=\s*([0-9.]+)#;
	return $1 unless $set;

	$line = '$sa_kill_level_deflt = ' . $set . ';';
	$y->splice_line($num, 1, $line);
	$y->save();

	control(AMAVIS(), RESTART());
}


=item policy_dns_only([0|1])

Returns the current status of dnsbl_checks_only if
no argument is passed. Sets the status of the variable
if an argument is passed.

=cut

sub policy_dns_only {
	my $x = shift;

	return _policy_dns_only() unless defined $x;
	_policy_dns_only($x);
	control(POLICYD_WEIGHT(), RESTART());
}


=item policy_dnsbl([host, hit, miss, log])

Returns an array containing the current DNSBL settings if
no argument is given. Otherwise it will add the given array to the
list of DNSBL entries.

=cut

sub policy_dnsbl {
	my @x = @_;

	return _policy_dnsbl() unless @x;
	_policy_dnsbl(@x);
	control(POLICYD_WEIGHT(), RESTART());
}


=item policy_delete_dnsbl(host, hit, miss, log)

Deletes the given array from the current DNSBL entries. Please
note that they have to occur in the exact order.

=cut

sub policy_delete_dnsbl {
	_delete_dnsbl(@_);
	control(POLICYD_WEIGHT(), RESTART());
}

sub policy_reset_dnsbl {
	my @values = @_;

	my @dnsbl = policy_dnsbl();
	my @dnsbl_content;

	for my $i (1 .. (@dnsbl / 4)){
		push @dnsbl_content, [splice(@dnsbl, 0, 4)];
	}

	foreach my $i (@dnsbl_content) {
		_delete_dnsbl($i->[0], $i->[1], $i->[2], $i->[3]);
	}

	while (@values) {
		my @v = splice @values, 0, 4;

		_policy_dnsbl(@v);
	}
	control(POLICYD_WEIGHT(), RESTART());
}


=item policy_rhsbl(host, hit, miss, log)

Returns an array containing the current RHSBL settings if
no argument is given. Otherwise it will add the given array to the
list of RHSBL entries.

=cut

sub policy_rhsbl {
	my @x = @_;

	return _policy_rhsbl() unless @x;
	_policy_rhsbl(@x);
	control(POLICYD_WEIGHT(), RESTART());
}


=item delete_policy_rhsbl(host, hit, miss, log)

Deletes the given array from the current RHSBL entries. Please
note that they have to occur in the exact order.

=cut 

sub policy_delete_rhsbl {
	_delete_rhsbl(@_);
	control(POLICYD_WEIGHT(), RESTART());
}

sub policy_reset_rhsbl {
	my @values = @_;

	my @rhsbl = policy_rhsbl();
	my @rhsbl_content;

	for my $i (1 .. (@rhsbl / 4)){
		push @rhsbl_content, [splice(@rhsbl, 0, 4)];
	}

	foreach my $i (@rhsbl_content) {
		_delete_rhsbl($i->[0], $i->[1], $i->[2], $i->[3]);
	}

	while (@values) {
		my @v = splice @values, 0, 4;

		_policy_rhsbl(@v);
	}
	control(POLICYD_WEIGHT(), RESTART());
}


=item clam_scan_archive(1|0|)

This routine returns the current status of the ScanArchive directive
in clamd.conf. If an argument is passed, we well set true (1) or 
false (0) values for this directive.

=cut

sub clam_scan_archive {
	my $set = shift;
	my $y = Yaffas::File->new($conf_clamd) || throw Yaffas::Exception("Could not read '$conf_clamd': $!");

	my $num = $y->search_line(qr/ScanArchive/);
	unless($num >= 0){
		$y->add_line(q/ScanArchive true/);
		$num = $y->search_line(qr/ScanArchive/);
		throw Yaffas::Exception("ScanArchive not found") unless $num >= 0;
	}

	unless(defined $set){
		my $line = $y->get_content($num);
		return undef unless $line =~ m#^ScanArchive\s*(true|false|yes|no)#ix;
		my $ret=$1;

		return 1 if $ret=~ m#^(true|yes)\z#i;
		return undef;
	}

	my $line = "ScanArchive " . ($set && $set >= 1 ? "true" : "false");
	$y->splice_line($num, 1, $line);
	$y->save();

	control(CLAMAV(), RESTART());
}


=item clam_max_length([max])

Returns the current setting for StreamMaxLength. If you pass an argument we will change the value.
Please don't add M or G to the size. We will add M by default.

=cut

sub clam_max_length {
	my $set = shift;
	my $y = Yaffas::File->new($conf_clamd) || throw Yaffas::Exception("Could not read '$conf_clamd': $!");

	my $num = $y->search_line(qr/StreamMaxLength/);
	unless($num >= 0){
		$y->add_line(q/StreamMaxLength 25M/);
		$num = $y->search_line(qr/StreamMaxLength/);
		throw Yaffas::Exception("StreamMaxLength not found") unless $num >= 0;
	}

	unless(defined $set){
		my $line = $y->get_content($num);
		# 10 is the default value, if nothing is specified explicitly
		# (from man clamd.conf)
		return "10" unless $line =~ m#^StreamMaxLength\s*(\d+)#ix;
		return $1;
	}

	$set .="M";
	my $line = "StreamMaxLength $set";
	$y->splice_line($num, 1, $line);
	$y->save();

	control(CLAMAV(), RESTART());
}


=item clam_update()

This routine will tell freshclam to update the patterns

NB: Not yet sure how to do this on RHEL.

=cut

sub clam_update {
	my ($out, $err) = Yaffas::backquote_out_err($app_freshclam, "no-daemon");
	push @$err, @$out;
	return @$err;
}


=item spam_update()

Update spamassassins filters...

NB: Currently didn't work with gpg...

=cut

sub spam_update {
	my ($user, $pass, $proxy, $port) = Yaffas::Module::Proxy::get_proxy();
	$ENV{http_proxy} = "http://$user:$pass\@$proxy:$port";

	my @cmd = (Yaffas::Constant::APPLICATION->{sa_update},
			'--channelfile', Yaffas::Constant::FILE->{channels_cf},
# 			'--gpgkeyfile',  Yaffas::Constant::FILE->{channels_keys},
			'--nogpg');

	my ($out, $err) = Yaffas::backquote_out_err(@cmd, "no-daemon");
	push @$err, @$out;
	control(SPAMASSASSIN(), RELOAD());
	return @$err;
}


=item spam_trusted_networks()

Returns an array of hosts mentioned in local.cf
or undef if trusted_networks is not set

=cut

sub spam_trusted_networks {
	my $y = Yaffas::File->new($conf_spam) || throw Yaffas::Exception("open '$conf_spam' failed: $!");
	my $num = $y->search_line(qr/trusted_networks/);
	return () unless $num;

	my $line = $y->get_content($num);
	return () if $line =~ m/#/;
	return () unless $line =~ m#\s*trusted_networks\s+(.+)\z#;
	my $hosts = $1;

	my @ret = split(qr/\s+/, $hosts);
	return @ret;
}


=item spam_add_trusted_network()

Adds your host/net to the trusted_networks of local.cf.
If trusted_networks doesn't exist or is commented out, we
will add or uncomment it.

=cut

sub spam_add_trusted_network {
	my $host = shift;
	my $restart = shift;
	throw Yaffas::Exception('Invalid input') if $host !~ m#^[0-9./!]+\z#;

	my $y = Yaffas::File->new($conf_spam) || throw Yaffas::Exception("open '$conf_spam' failed: $!");
	my $num = $y->search_line(qr/trusted_networks/);
	unless($num){
		$y->add_line("trusted_networks");
		$num = $y->search_line(qr/trusted_networks/);
	}

	my $line = $y->get_content($num);
	$line =~ s/^\s*#//;
	$line .= " $host";
	$y->splice_line($num, 1, $line);
	$y->save();

	if ($restart == undef) {
		control(SPAMASSASSIN(), RESTART());
	}
}


=item spam_del_trusted_network(HOST/NET)

Delete the given host or net from the trusted_networks.

=cut

sub spam_del_trusted_network {
	my $host = shift;
	my $restart = shift;

	chomp($host);
	my $y = Yaffas::File->new($conf_spam) || throw Yaffas::Exception("open '$conf_spam' failed: $!");
	my $num = $y->search_line(qr/trusted_networks/);
	throw Yaffas::Exception("no section: trusted_networks") unless $num;

	my @networks = grep { $_ } map { $host eq $_ ? undef : $_ } spam_trusted_networks();
	my $line = "trusted_networks " . join(" ", @networks);

	$y->splice_line($num, 1, $line);
	$y->save();

	if ($restart == undef) {
		control(SPAMASSASSIN(), RESTART());
	}
}

sub spam_reset_trusted_network {
	my @new_trusted = @_;
	my @trusted = spam_trusted_networks();

	foreach my $t (@trusted) {
		spam_del_trusted_network($t, 1);
	}

	foreach my $t (@new_trusted) {
		spam_add_trusted_network($t, 1);
	}
	control(SPAMASSASSIN(), RESTART());
}



=item wl_postfix() 

Retrieves all whitelist entries from postfix

=cut

sub wl_postfix {
	my $y = Yaffas::File->new($wl_postfix) || throw Yaffas::Exception("$wl_postfix: $!");
	my @lines = $y->get_content();
	my @entries;

	foreach my $line (@lines){
		chomp $line;
		next unless $line =~ m#^([^ ]+)\s+#;
		push @entries, $1;
	}

	return @entries;
}


=item wl_postfix_delete()

Remove an entry for the postfix/policyd-weight setup

=cut

sub wl_postfix_delete {
	my $what = shift;
	my $y = Yaffas::File->new($wl_postfix) || throw Yaffas::Exception("$wl_postfix: $!");
	my $num = $y->search_line(qr/^$what\s/);
	throw Yaffas::Exception('Entry not found') unless defined $num;

	$y->splice_line($num, 1);

	$y->save();
	system(Yaffas::Constant::APPLICATION->{'postmap'}, $wl_postfix);
	control(POSTFIX(), RESTART());
}


=item wl_postfix_add()

Add an entry to postfix for policy-weight

=cut

sub wl_postfix_add {
	my $what = shift;

	my @list = wl_postfix();
	throw Yaffas::Exception("Host already in  List") if grep { $_ eq $what } @list;

	my $y = Yaffas::File->new($wl_postfix) || throw Yaffas::Exception("$wl_postfix: $!");
	$y->add_line("$what permit_auth_destination");
	$y->save();

	system(Yaffas::Constant::APPLICATION->{'postmap'}, $wl_postfix);
	control(POSTFIX(), RESTART());
}


=item wl_amavis()

Returns all entries from /opt/yaffas/config//opt/yaffas/config/whitelist-amavis
as an array.

=cut

sub wl_amavis {
	my $y = Yaffas::File->new($wl_amavis) || throw Yaffas::Exception("$wl_amavis: $!");
	my @c = $y->get_content();
	return @c;
}


=item wl_amavis_add()

Adds a new line to /opt/yaffas/config//opt/yaffas/config/whitelist-amavis.

=cut

sub wl_amavis_add {
	my $what = shift;

	my @exists = wl_amavis();
	throw Yaffas::Exception('Entry already exists') if grep { $what eq $_ } @exists;

	my $y = Yaffas::File->new($wl_amavis) || throw Yaffas::Exception("$wl_amavis: $!");
	$y->add_line($what);
	$y->save();
	control(AMAVIS(), RESTART());
}


=item wl_amavis_delete(String)

Deletes the given entry from /opt/yaffas/config/whitelist-amavis.

=cut

sub wl_amavis_delete {
	my $what = shift;
	my $y = Yaffas::File->new($wl_amavis) || throw Yaffas::Exception("$wl_amavis: $!");
	my $num = $y->search_line(qr/^$what\z/);

	throw Yaffas::Exception('No entry found.') unless defined $num;

	$y->splice_line($num, 1);
	$y->save();
	control(AMAVIS(), RESTART());
}


=item whitelist()

This is a whitelist wrapper for postfix and amavis.
It will return an array of hashrefs containing the entries
type, where we got it from and the entry itself, of course.

=cut

sub whitelist {
	my @postfix = wl_postfix();
	my @amavis = wl_amavis();
	my %list;

	foreach my $e (@postfix){
		$list{$e} = {type=>_oftype($e), from=>['postfix']};
	}

	foreach my $e (@amavis){
		if(exists($list{$e})){
			push @{ $list{$e}->{'from'} }, 'amavis';
		} else {
			$list{$e} = {type=>_oftype($e), from=>['amavis']};
		}
	}

	return %list;
}


=item whitelist_add(item)

Adds an item to one ore more whitelists, depending on its type.

Email is only for Amavis. All other types are for amavis and 
postfix.
=cut

sub whitelist_add {
	my $what = shift;
	my $type = _oftype($what);

	throw Yaffas::Exception("Unknown type: $what") unless $type;

	my %list = whitelist();
	throw Yaffas::Exception('Entry already exists') if grep { $what eq $_ } keys %list;

	if($type eq "email"){
		wl_amavis_add($what),
	} elsif($type eq "domain" || $type eq "ip" || $type eq "net") {
		wl_postfix_add($what);
		wl_amavis_add($what);
	}
}


=item whitelist_delete(item)

Deletes an item from one ore more whitelists depending on its type.

=cut

sub whitelist_delete {
	my $what = shift;
	my $type = _oftype($what);

	throw Yaffas::Exception("Unknown type: $what") unless $type;

	my %list = whitelist();
	throw Yaffas::Exception('Unknown entry') unless grep { $what eq $_ } keys %list;

	if($type eq 'email'){
		wl_amavis_delete($what) if grep { 'amavis' eq $_ } @{ $list{$what}->{from} } ;
	} elsif($type eq 'domain' || $type eq 'ip' || $type eq 'net' ){
		wl_postfix_delete($what) if grep { 'postfix' eq $_ } @{ $list{$what}->{from} };
		wl_amavis_delete($what) if grep { 'amavis' eq $_ } @{ $list{$what}->{from} };
	}
}


sub whitelist_reset {
	my @new_whitelist = @_;

	my %whitelist = whitelist();
	my @whitelist = keys %whitelist;

	foreach my $w (@whitelist) {
		whitelist_delete($w);
	}

	foreach my $w (@new_whitelist) {
		whitelist_add($w);
	}
}


### internal functions

sub _oftype {
	my $x = shift;
	return "email" if Yaffas::Check::email($x);
	return "domain" if Yaffas::Check::domainname($x);
	return "ip" if Yaffas::Check::ip($x);
	if ($x =~ m/^([0-9\.]+)\/([0-9\.]+)$/) {
		return "net" if Yaffas::Check::ip($1, $2, "netaddr");
	}
	return undef;
}

sub _policy_dns_only {
	my $set = shift;
	my $ref = {_get_policy_conf()};

	return $ref->{dnsbl_checks_only} unless defined $set;

	throw Yaffas::Exception('only 0 or 1 is valid here...') unless $set =~ m#^(0|1)\z#;
	_write_policy_conf(dnsbl_checks_only => $set);
}

sub _delete_dnsbl {
	my @set = @_;

	throw Yaffas::Exception('we need four items to delete an entry') unless @set == 4;
	my %conf = _get_policy_conf();
	my @current = @{$conf{dnsbl_score}};
	my $where;

	foreach my $i (0 .. $#current){
		if($current[$i] eq $set[0]){
			if($current[$i+1] eq $set[1]){
				if($current[$i+2] eq $set[2]){
					if($current[$i+3] eq $set[3]){
						$where = $i; 
						last;
					}
				}
			}
		}
	}

	throw Yaffas::Exception("Given combination not found") unless defined($where);
	splice(@current, $where, 4);

	_write_policy_conf(dnsbl_score => \@current);

}

sub _policy_dnsbl {
	my @set = @_;
	my $ref = {_get_policy_conf()};

	if (not @set) {
		if ($ref->{dnsbl_score}) {
			return @{ $ref->{dnsbl_score} };
		}
		return ();
	}


	throw Yaffas::Exception("Invalid content provided") if scalar @set != 4;
	foreach(@set){
		throw Yaffas::Exception("no content provided") unless length;
	}

	my %conf = _get_policy_conf();
	my @new;

	if (ref $conf{dnsbl_score} eq "ARRAY") {
		@new = @{$conf{dnsbl_score}};
	}

	push @new, @set;

	_write_policy_conf(dnsbl_score => \@new);
}

sub _delete_rhsbl {
	my @set = @_;

	throw Yaffas::Exception('we need four items to delete an entry') unless @set == 4;
	my %conf = _get_policy_conf();
	my @current = @{$conf{rhsbl_score}};
	my $where;

	foreach my $i (0 .. $#current){
		if($current[$i] eq $set[0]){
			if($current[$i+1] eq $set[1]){
				if($current[$i+2] eq $set[2]){
					if($current[$i+3] eq $set[3]){
						$where = $i; 
						last;
					}
				}
			}
		}
	}

	throw Yaffas::Exception("Given combination not found") unless defined($where);
	splice(@current, $where, 4);

	_write_policy_conf(rhsbl_score => \@current);
}


sub _policy_rhsbl {
	my @set = @_;
	my $ref = {_get_policy_conf()};

	if (not @set) {
		if ($ref->{rhsbl_score}) {
			return @{ $ref->{rhsbl_score} };
		}
		return ();
	}

	throw Yaffas::Exception("Invalid content provided") if scalar @set != 4;
	foreach(@set){
		throw Yaffas::Exception("no content provided") unless length;
	}

	my %conf = _get_policy_conf();
	my @new;

	if (ref $conf{rhsbl_score} eq "ARRAY") {
		@new = @{$conf{rhsbl_score}};
	}

	push @new, @set;

	_write_policy_conf(rhsbl_score => \@new);
}

# Pass this routine a hash of what you want to change
# e.g. BL_ERROR_SKIP => 1
# or dnsbl_score => [], NTTL => 0
sub _write_policy_conf {
	throw Yaffas::Exception("no such file: $conf_policy") unless -e $conf_policy;
	if(scalar @_ % 2){ die "Odd number of elements passed"; }

	my %tmp = @_;
	my %conf = _get_policy_conf();
	
	while (my ($k,$v) = each %tmp){
		$conf{$k} = $v;
	}

	my $y = Yaffas::File->new($conf_policy);
	my $string = q/# generated by yaffas. do not edit beyond this line./;

	my $num = $y->search_line($string);
	$y->splice_line($num, 2) if $num;

	my $line = q/$dnsbl_checks_only='/ . ($conf{dnsbl_checks_only} ? 1 : 0) ."'; ";

	$line .= q/@dnsbl_score=(/ . join(",", map{"'$_'"} @{$conf{dnsbl_score}})  . q/); /;
	$line .= q/@rhsbl_score=(/ . join(",", map{"'$_'"} @{$conf{rhsbl_score}})  . q/); /;

	$y->add_line($string);
	$y->add_line($line);
	$y->save();
}


# this routine evals the policyd-weight.conf and returns a hash containing
# all the variable names (as scalar keys) and their values as references.
sub _get_policy_conf {

	unless(-e $conf_policy){
		my ($out, undef) = Yaffas::backquote_out_err(Yaffas::Constant::APPLICATION->{'policyd_weight'}, 'defaults');
		open(FILE, '>', $conf_policy) || throw Yaffas::Exception("open failed: $!");
		print FILE @$out;
		close(FILE);
	}

	my $e = "package New;";
	open(FILE, '<', $conf_policy) || throw Yaffas::Exception("open failed: $!");
	$e .= join("", <FILE>);
	close(FILE);

	my %ret;

	my ($dco, @dsc, @rhs);
	{
		no strict;
		eval $e;
		print $@;
		throw Yaffas::Exception("Something went very wrong: $@") if $@;
		
		foreach my $name (%New::){
			if($name && $name !~ m#^\*#){
				my $tmp = "New::$name";

				if(defined $$tmp){
					$ret{$name} = $$tmp;
				} elsif(@$tmp){ $ret{$name} = \@$tmp;
				} elsif(%$tmp){ $ret{$name} = \%$tmp;
				}
			}
		}

		use strict;
		use warnings;
	}

	return %ret;
}

sub _get_amavis {
	return undef unless -e $conf_amavis;

	open(FILE, '<', $conf_amavis) || throw Yaffas::Exception("Could not open $conf_amavis: $!");
	my @tmp = <FILE>;
	close(FILE);

	my %ret;

	foreach(@tmp){
		chomp; next unless length;
		next unless m#^\s*[\%\$\@]([^=\s]+)\s*=\s*(.+)#;
		$ret{$1} = $2;
	}

	return %ret;
}

sub _get_postfix {
	my $type = shift;

	throw Yaffas::Exception('invalid value for type at _get_value') unless $type =~ m#^[A-Za-z0-9_-]+\z#;
	my $out = do_back_quote(Yaffas::Constant::APPLICATION()->{postconf}, $type);
	$out =~ s/[^=]+\s*=\s*//;
	$out =~ s/\n//g;
	$out =~ s/\s{2,}/ /g;
    return undef if ($out eq "");
	return $out;
}

sub _set_postfix {
	my $type = shift;
	my $value = shift;

	throw Yaffas::Exception('invalid first parameter at _set_value')  unless $type =~ m#^[A-Za-z0-9_-]+\z#;
	throw Yaffas::Exception('invalid second parameter at _set_value') if $value =~ m#[`!;]#mg;

	system(Yaffas::Constant::APPLICATION()->{postconf}, "-e", "$type = $value");
	throw Yaffas::Exception('error in postconf -e') if $?;
}

sub amavis_virusalert {
    my $set = shift;
    my $y = Yaffas::File->new($conf_amavis) || throw Yaffas::Exception("$conf_amavis: $!");
    my $num = $y->search_line('virus_admin');
    my $line = $y->get_content($num);

    if ($set) {
        Yaffas::Check::email($set) or throw Yaffas::Exception("err_mail", $set);
	$set =~ s/@/\\@/;
        $line = '$virus_admin = "' . $set . '";';
        $y->splice_line($num, 1, $line);
        $y->save();
		control(AMAVIS(), RESTART());
    }
    else {
        return undef unless $line =~ m#virus_admin\s*=\s*["'](.+)["']#;
	my $address = $1;
	$address =~ s/\\@/@/;
        return $address;
    }
}

# for Yaffas::Module
sub conf_dump {
	my $conf = Yaffas::Conf->new();
	my $section = $conf->section("security");
	my $function = Yaffas::Conf::Function->new("clamav-state", "Yaffas::Module::Security::save_clamav_state");
	$function->add_param({type=>"scalar", param=>check_antivirus()});
	$section->del_func("clamav-state");
	$section->add_func($function);

	if (check_antivirus()) {
		$function = Yaffas::Conf::Function->new("clamav-scanarchive", "Yaffas::Module::Security::clam_scan_archive");
		$function->add_param({type=>"scalar", param=>clam_scan_archive()});
		$section->del_func("clamav-scanarchive");
		$section->add_func($function);

		$function = Yaffas::Conf::Function->new("clamav-maxlength", "Yaffas::Module::Security::clam_max_length");
		$function->add_param({type=>"scalar", param=>clam_max_length()});
		$section->del_func("clamav-maxlength");
		$section->add_func($function);

		$function = Yaffas::Conf::Function->new("clamav-virusalert", "Yaffas::Module::Security::amavis_virusalert");
		$function->add_param({type=>"scalar", param=>amavis_virusalert()});
		$section->del_func("clamav-virusalert");
		$section->add_func($function);
	}

	$function = Yaffas::Conf::Function->new("spamassassin-state", "Yaffas::Module::Security::save_spamassassin_state");
	$function->add_param({type=>"scalar", param=>check_spam()});
	$section->del_func("spamassassin-state");
	$section->add_func($function);

	if (check_spam()) {
		$function = Yaffas::Conf::Function->new("spamassassin-score", "Yaffas::Module::Security::sa_tag2_level");
		$function->add_param({type=>"scalar", param=>sa_tag2_level()});
		$section->del_func("spamassassin-score");
		$section->add_func($function);

		$function = Yaffas::Conf::Function->new("spamassassin-trusted-net", "Yaffas::Module::Security::spam_reset_trusted_network");
		my @trusted = spam_trusted_networks();
		$function->add_param({type=>"array", param=>\@trusted});
		$section->del_func("spamassassin-trusted-net");
		$section->add_func($function);
	}

	$function = Yaffas::Conf::Function->new("policy-state", "Yaffas::Module::Security::save_policy_state");
	$function->add_param({type=>"scalar", param=>check_policy()});
	$section->del_func("policy-state");
	$section->add_func($function);

	if (check_policy()) {
		$function = Yaffas::Conf::Function->new("policy-dnsbl", "Yaffas::Module::Security::policy_reset_dnsbl");
		my @dnsbl = policy_dnsbl();
		$function->add_param({type=>"array", param=>\@dnsbl});
		$section->del_func("policy-dnsbl");
		$section->add_func($function);

		$function = Yaffas::Conf::Function->new("policy-rhsbl", "Yaffas::Module::Security::policy_reset_rhsbl");
		my @rhsbl = policy_rhsbl();
		$function->add_param({type=>"array", param=>\@rhsbl});
		$section->del_func("policy-rhsbl");
		$section->add_func($function);
	}

	$function = Yaffas::Conf::Function->new("whitelist", "Yaffas::Module::Security::whitelist_reset");
	my %whitelist = whitelist();
	my @whitelist = keys %whitelist;
	$function->add_param({type=>"array", param=>\@whitelist});
	$section->del_func("whitelist");
	$section->add_func($function);


	$conf->save();
}


=back

=head1 AUTHOR

Sebastian Stumpf E<lt>stumpf@bitbone.deE<gt>

=head1 COPYRIGHT

This file is part of yaffas.

yaffas is free software: you can redistribute it and/or modify it
under the terms of the GNU Affero General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

yaffas is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Affero General Public
License for more details.

You should have received a copy of the GNU Affero General Public
License along with yaffas.  If not, see
<http://www.gnu.org/licenses/>.

=cut

return 1;
