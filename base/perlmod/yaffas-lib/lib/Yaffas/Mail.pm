#!/usr/bin/perl
package Yaffas::Mail;

use warnings;
use strict;

sub BEGIN {
	use Exporter;
	our @ISA = qw(Exporter);
	our @EXPORT_OK = qw(check_alias check_mailbox
						get_quota set_quota del_quota
						set_permissions
						get_mailboxes get_mailbox_with_acl
						create_mailbox delete_mailbox
						get_folder_aliases set_folder_aliases
						get_default_quota get_default_folders
						set_default_quota set_default_folders
					   );
}

use Yaffas::File;
use Yaffas::LDAP;
use Yaffas::File::Config;
use Yaffas::Exception;
use Yaffas::Constant;
use Sort::Naturally;
use Yaffas::Auth;
use Yaffas::Check;
use Yaffas::Service;
use Yaffas::Product;
use autouse 'Cyrus::IMAP::Admin' => qw(Cyrus::IMAP::Admin::new);
use Net::SMTP;
use DBI;

=head1 NAME

Yaffas::Mail - Module for non basic mail functions

=head1 SYNOPSIS

use Yaffas::Mail

=head1 DESCRIPTION

Yaffas::Mail  --todo--

=head1 FUNCTIONS

=cut

sub get_zarafa_quota($) {
	my $login = shift;
	if ((Yaffas::LDAP::search_entry("uid=$login", "zarafaQuotaOverride"))[0] == 0) {
		return "";
	}
	return (Yaffas::LDAP::search_entry("uid=$login", "zarafaQuotaHard"))[0];
}

sub set_zarafa_quota($$) {
	my $login = shift;
	my $quota = shift;

	throw Yaffas::Exception("err_quota_number") unless($quota =~ /^\d+|$/);
	throw Yaffas::Exception("err_quota_negative") if($quota =~ /^-/);

	if ($quota eq "") {
		Yaffas::LDAP::replace_entry($login, "zarafaQuotaOverride", 0);
		Yaffas::LDAP::replace_entry($login, "zarafaQuotaWarn", 0);
		Yaffas::LDAP::replace_entry($login, "zarafaQuotaSoft", 0);
		Yaffas::LDAP::replace_entry($login, "zarafaQuotaHard", 0);
	}
	else {
		my $ret;
		my $quota_warn = sprintf ("%d", $quota * 0.8);
		$quota_warn > 1 or $quota_warn = 1;
		unless ($quota_warn > 1) {
			$quota_warn = 1;
		}
		my $quota_soft = sprintf ("%d", $quota * 0.9);
		unless ($quota_soft > 1) {
			$quota_soft = 1;
		}
		$ret = Yaffas::LDAP::replace_entry($login, "zarafaQuotaWarn", $quota_warn);
		throw Yaffas::Exception("err_ldap_save", $ret) if ($ret);
		$ret = Yaffas::LDAP::replace_entry($login, "zarafaQuotaSoft", $quota_soft);
		throw Yaffas::Exception("err_ldap_save", $ret) if ($ret);
		$ret = Yaffas::LDAP::replace_entry($login, "zarafaQuotaHard", $quota);
		throw Yaffas::Exception("err_ldap_save", $ret) if ($ret);
		$ret = Yaffas::LDAP::replace_entry($login, "zarafaQuotaOverride", 1);
		throw Yaffas::Exception("err_ldap_save", $ret) if ($ret);
	}
}

sub get_zarafa_current_quota($) {
	my $login = shift;

	my $zarafa_server_cfg =
	  Yaffas::File::Config->new( Yaffas::Constant::FILE->{zarafa_server_cfg} );
	my $conf   = $zarafa_server_cfg->get_cfg_values();
	my $dbname = $conf->{"mysql_database"};
	my $user   = $conf->{"mysql_user"};
	my $pass   = $conf->{"mysql_password"};

	my $db = DBI->connect( "dbi:mysql:$dbname", $user, $pass );

	# get hierarchy_id
	my @hierarchy_id;
	my $statement =
	  $db->prepare( "SELECT stores.hierarchy_id"
		  . " FROM stores"
		  . " JOIN users"
		  . " ON users.id = stores.user_id"
		  . " WHERE users.externid = ?" );
	$statement->execute($login);
	if ( my @row = $statement->fetchrow_array() ) {
		push( @hierarchy_id, $row[0] );
	}

	# get store size
	my $size = 0;
	$statement =
	  $db->prepare( "SELECT hierarchy.id, properties.val_ulong, hierarchy.type"
		  . " FROM hierarchy"
		  . " LEFT JOIN properties"
		  . " ON properties.hierarchyid = hierarchy.id AND properties.tag = 0x0e08 AND properties.type = 0x0003"
		  . " WHERE hierarchy.parent = ? AND hierarchy.flags & 0x400 = 0" );
	for ( my $i = 0 ; $i < scalar @hierarchy_id ; $i++ ) {
		$statement->execute( $hierarchy_id[$i] );
		while ( my @row = $statement->fetchrow_array() ) {
			if ( $row[2] == 5 && defined( $row[1] ) ) {
				$size += $row[1];
			}
			elsif ( $row[2] == 3 ) {
				push( @hierarchy_id, $row[0] );
			}
		}
	}

	$db->disconnect();
	return $size;
}

=over

=item check_alias ( NAME )

Checks if an alias allready exists.
Returns 1 if it exists, otherwise undef.

=back

=cut

sub check_alias($){
	my $alias = shift;

	open(FILE, "< /etc/aliases");
	my @file = <FILE>;
	close(FILE);
	foreach( @file ){
		s/^\s+//;
		s/\s+$//;
		s/#.*//;
		next unless length;

		my $u = $1 if m/^(.+): .*?$/;
		return 1 if lc $u eq lc $alias;
	}
	return undef;
}

=over

=item get_quota ( MAILBOX | USERNAME )

This routine returns the current quota for B<MAILBOX> if zarafa is not installed otherwise for B<USERNAME>
If there was an error it returns undef.

e.g. cyrus usage: get_quota("user/bibo");

     zarafa usage: get_quota("bibo");

=back

=cut

sub get_quota($){
	my $mailbox = shift;
	my $quotaval = undef;
	my $usedval = undef;
	if (Yaffas::Product::check_product("zarafa")) {
		$quotaval = get_zarafa_quota($mailbox);
		$quotaval *= 1024;
		$usedval = sprintf("%.0f", get_zarafa_current_quota($mailbox) / 1024);
	} else {
		my $client = _connect();
		my %quota = $client->listquota($mailbox);
		if( defined $quota{'STORAGE'} ){
			($usedval, $quotaval) = @{ $quota{'STORAGE'} };
		}
	}
	return ($usedval, $quotaval)
}

=pod

=over

=item set_quota ( MAILBOX, LIMIT )

sets the quota ( in kb ) for the MAILBOX.

=back

=cut

sub set_quota($$){
	my $mailbox = shift;
	my $limit = shift;
	my $client = _connect();

	throw Yaffas::Exception("err_quota_value") unless($limit =~ /^\d+$/g);

	if (_check_mailbox($mailbox, $client)) {
		$client->setquota($mailbox, "STORAGE" , $limit);
	}
}

=pod

=over

=item del_quota ( MAILBOX )

removed the quote from MAILBOX.

=back

=cut

sub del_quota($){
	my $mailbox = shift;
	my $client = _connect();
	if (_check_mailbox($mailbox, $client)) {
		$client->setquota($mailbox);
	}
}

# connect to cyrus
sub _connect(){
	my $client = Cyrus::IMAP::Admin->new('127.0.0.1');
	if( !defined $client ){
		return undef;
	}
	$client->authenticate(
			  'User' => "root",
			  'Password' => Yaffas::Auth::get_local_root_passwd(),
			  'mechanisms' => 'plaintext'
			  ) or return undef;
    return $client;
}

=pod

=over

=item get_mailboxes ( [USER] )

On cyrus:
list of all mailboxes of USER.
if USER is omitted returns all folders.

shared folder have the prefix of Yaffas::Constant::MISC()->{sharedfolder}

On zarafa:
list all public folders

=back

=cut

sub get_mailboxes(;$) {
    return () unless -x Yaffas::Constant::APPLICATION->{php5};
	if (Yaffas::Product::check_product("zarafa")) {
		my @tmp = grep {chomp($_); $_} Yaffas::do_back_quote(Yaffas::Constant::APPLICATION->{php5}, Yaffas::Constant::APPLICATION->{zarafa_public_folder_script});
		if ($? != 0) {
			return ();
		}
		return @tmp;
	}
	else {
		my $user = shift;
		my $client = _connect();

		return qw() unless $client;

		my @mailboxes = $client->listmailbox('*');
		@mailboxes = map{ $_->[0] } @mailboxes;
		# 0 = name , 1 = \HasNoChildrin, 2 = kein plan.

		if (defined $user) {
			## only the user
			my @userboxes = nsort grep { /^user\/$user$/ or /^user\/$user\// } @mailboxes;
			return @userboxes if (@userboxes);
			return;
		}
		else {
			## all
			return Yaffas::Constant::MISC()->{sharedfolder}, nsort map {
				if (/^user\//) {
					$_;
			}
				else {
					Yaffas::Constant::MISC()->{sharedfolder} . "/" . $_;
				}} @mailboxes;
		}
	}
}

=pod

=over 

=item get_mailbox_with_acl (MAILBOX)

returns a hash of the ACL of the MAILBOX.

=back

=cut

sub get_mailbox_with_acl($){
    my $mailbox = shift;
    my $client = _connect();
    my %acl = $client->listacl( $mailbox );

    return %acl;
}

=pod

=over

=item set_permissions( MAILBOX , PERMISSIONHASHREF, RECURSIVE, MODE )

PERMISSONHASHREF is a hash containtin the username with its permissions..
If RECURSIVE is set, then all mailboxes under MAILBOX are also changed.
If MODE is set "add", the the permissions are added to the existing ones.

e.q.
	my $perm = {
		anyone => "lam",
		martin => "delete",
		christof => "ls",
		....
	};

for the permissions have a look at the Cyrus documentation.
"delete" means that the user will have No permisssions at all on this mailbox.

=back

=cut

sub set_permissions($$;$$) {
	my $mailbox = shift;
	my $perm = shift; # hashref
	my $recursive = shift;
	my $mode = shift;

    my $client = _connect();
	my $e = Yaffas::Exception->new();

	$e->add('err_mailbox_not_exist', $mailbox) unless (_check_mailbox($mailbox, $client));
	throw $e if $e;

	my @mailboxes = ($mailbox);

	if (defined($recursive) && $recursive) {
		$mailbox .= "/*" if ($recursive);
		push @mailboxes, map {$_->[0]} $client->listmailbox($mailbox);
	}

	foreach my $sel (qw(user group)) {
		foreach my $mailbox (@mailboxes) {
			foreach (keys %{$perm->{$sel}}) {
				my $user = $_;

				if ($sel eq "group") {
					$user = "group:$user";
				}

				if( $perm->{$sel}->{$_} eq "" ){
					## delete
					$client->setaclmailbox($mailbox, $user, "none");
				} else {
					## permission setzten


					if (defined($mode) && $mode eq "add") {
						my %p = $client->listacl($mailbox);
						$perm->{$sel}->{$_} .= $p{$user};
					}

					$client->setaclmailbox($mailbox, $user, $perm->{$sel}->{$_});
					$e->add("err_set_permission", $mailbox.": ".$client->error()) if ($client->error());
				}
			}
		}
	}
	throw $e if $e;
}

=pod

=over

=item create_mailbox( MAILBOX )

creates a new mailbox.
if the mailbox is a shared folder than it has the default permissios for "anyone" to "lrsp".

=back

=cut

sub create_mailbox($) {
	my $mailbox = shift;
	my $client = _connect();
	throw Yaffas::Exception("err_mailbox_name") unless(Yaffas::Check::mailbox($mailbox));
	$client->create($mailbox);
	unless ($mailbox =~  m/^user\//) {
		# p flag adden.
		$client->setaclmailbox($mailbox, "anyone", "lrsp");
	}
	return 1;
}

=pod

=over

=item delete_mailbox (MAILBOX, RECURSIVE )

deletes the MAILBOX and its subfolders if RECURSIVE == TRUE.

=back

=cut

sub delete_mailbox($$){
    my $mailbox = shift;
	my $recursive = shift;
	my $client = _connect();

	unless (_check_mailbox($mailbox, $client)) {
		throw Yaffas::Exception("err_mailbox_not_exist");
	}

	my @delmailbox = ();

	if ($main::gconfig{'product'} ne "webmin") { ## wenn webmin dann nicht abbrechen
		if ( $mailbox =~ m/^user\/\w+$/){
			return ;
		}
	}

	if(defined($recursive) and $recursive){
		push @delmailbox, $client->listmailbox($mailbox . "/*");
	}

	$client->setacl($mailbox, "root", "c");
	$client->delete($mailbox);

	foreach (@delmailbox){
		$client->setacl($_->[0], "root", "c");
		$client->delete($_->[0]);
	}
}

=pod

=over

=item get_folder_aliases (MAILBOX)

return all aliases of a MAILBOX.

=back

=cut

sub get_folder_aliases {
	my $mailbox = shift;

	my $bkc = Yaffas::File::Config->new("/etc/aliases",
										{
										 -SplitPolicy => 'custom',
										 -SplitDelimiter => ':\s*',
										 -StoreDelimiter => ': ',
										});

	my $aliases = $bkc->get_cfg_values();
	my @ret = ();

	foreach my $c (keys %{$aliases}) {
		if (($aliases->{$c}) =~ /^.*\/pipe_folder.sh \\\"$mailbox\\\".*$/) {
			push @ret, $c;
		}
	}
	return @ret;
}

=pod

=over

=item set_folder_aliases ( MAILBOX, ALIASES )

sets new folder ALIASES for the MAILBOX. other aliases of MAILBOx will be deleted.

=back

=cut

sub set_folder_aliases {
	my $mailbox = shift;
	my $aliases = shift;

	unless (defined $mailbox and defined $aliases) {
		throw Yaffas::Exception('err_invalid_parameters');
	}

	unless (check_mailbox($mailbox)) {
		throw Yaffas::Exception('err_mailbox_not_exists');
	}


	my $e = Yaffas::Exception->new();
	my $bkc = Yaffas::File::Config->new("/etc/aliases",
										{
										 -SplitPolicy => 'custom',
										 -SplitDelimiter => ':\s*',
										 -StoreDelimiter => ': ',
										});

	my $cfg = $bkc->get_cfg_values();
	my @values = split /\s*,\s*/, $aliases;

	foreach my $v (@values) {
		$e->add("err_alias_exists", $v) if ($cfg->{$v});
	}

	throw $e if $e;


	my $to = "\"| /usr/local/bin/pipe_folder.sh \\\"$mailbox\\\"\"";

	# clear all
	for (keys %$cfg) {
		if ($cfg->{$_} eq $to) {
			delete $cfg->{$_};
		}
	}

	my (@okee, @err, @to);
	for (@values) {
		if ($_ =~ /^[\w\d]+$/) {
			push @okee, $_;
			push @to, $to; # nur um die gleiche anzahl zu bekommen.
		}else {
			$e->add('err_invalid_mailbox_name', $_);
		}
	}

	# perldoc perllol !!! such nach "slice"
	@{$cfg}{ @okee } = @to if(@okee);

	$bkc->write();
	throw $e if $e;
	1;
}

=pod

=over

=item check_mailbox(

checks whether the mailbox exists or not.

=back

=cut

sub check_mailbox($) {
	my $mailbox = shift;
	if (Yaffas::Product::check_product("zarafa")) {
		return scalar grep { $_ eq $mailbox } get_mailboxes();
	}
	else {
		my $client = _connect();

		_check_mailbox($mailbox, $client);
	}
}

sub _check_mailbox ($$){
	my $mailbox = shift;
	my $client = shift;

	my @mailboxes = $client->listmailbox('*');

	foreach (@mailboxes) {
		return 1 if ($mailbox eq $_->[0]);
	}
	return 0;
}

=pod

=over 

=item get_default_folders

returns the default folder as a string.

=back

=cut

sub get_default_folders() {
	my $cfg = Yaffas::Constant::FILE()->{imap_conf};
	my $bkc = Yaffas::File::Config->new($cfg,
										{
										 -SplitPolicy => 'custom',
										 -SplitDelimiter => ':\s*',
										 -StoreDelimiter => ': ',
										}
									   );
	my $hashref = $bkc->get_cfg_values();

	return $hashref->{autocreateinboxfolders};
}

=pod

=over

=item set_default_foders (FOLDERS)

sets the default folders to the array FOLDERS.

=back

=cut

sub set_default_folders(@) {
	my $cfg = Yaffas::Constant::FILE()->{imap_conf};
	my $bkc = Yaffas::File::Config->new($cfg,
										{
										 -SplitPolicy => 'custom',
										 -SplitDelimiter => ':\s*',
										 -StoreDelimiter => ': ',
										}
									   );
	my $hashref = $bkc->get_cfg_values();

	my @folders = grep {Yaffas::Check::mailbox($_)} @_;
	my @rmfolders = grep {!Yaffas::Check::mailbox($_)} @_;
	
	my $bke = new Yaffas::Exception();
	$bke->add("err_folder_name", @rmfolders) if (@rmfolders);
	if ($#folders > -1 ){
		my $line = join " | ", @folders;
		$hashref->{autocreateinboxfolders} = $line;
		$bkc->save();
	}
	else 
	{
		my $bkf = Yaffas::File->new($cfg);
		if (defined (my $linenr = $bkf->search_line("autocreateinboxfolders"))) 
		{
			$bkf->splice_line($linenr, 1);
			$bkf->write();
		}
	}

	throw $bke if $bke;
	return 1;
}
=pod

=over

=item get_default_quota 

returns the default quota in kb.

=back

=cut

sub get_default_quota() {
	if (Yaffas::Product::check_product("zarafa")) {
		my $bkc = Yaffas::File::Config->new(Yaffas::Constant::FILE->{zarafa_server_cfg},
											{
											-SplitPolicy => 'custom',
											-SplitDelimiter => '\s*=\s*',
											}
											);
		my $hashref = $bkc->get_cfg_values();

		my $value =  $hashref->{quota_hard};
		return -1 if ($value == 0);
		return $value*1024;
	}
	else {
		my $cfg = Yaffas::Constant::FILE()->{imap_conf};
		my $bkc = Yaffas::File::Config->new($cfg,
											{
											-SplitPolicy => 'custom',
											-SplitDelimiter => ':\s*',
											-StoreDelimiter => ': ',
											}
										   );
		my $hashref = $bkc->get_cfg_values();

		return $hashref->{autocreatequota};
	}
}

=pod

=over 

=item set_default_quota (QUOTA)

sets the default Quota to QUOTA.
QUOTA must be a integer value, with Quotasize in kB.

=back

=cut

sub set_default_quota($) {
	my $quota = shift;
	throw Yaffas::Exception("err_quota_value") unless ($quota =~ /^-?\d+$/);

	if (Yaffas::Product::check_product("zarafa")) {
		my $bkc = Yaffas::File::Config->new(Yaffas::Constant::FILE->{zarafa_server_cfg},
											{
											-SplitPolicy => 'custom',
											-SplitDelimiter => '\s*=\s*',
											-StoreDelimiter => '=',
											}
										   );
		my $hashref = $bkc->get_cfg_values();

		if ($quota < 0) {
			$quota = 0;
		}
		$hashref->{quota_hard} = $quota/1024;
		$bkc->save();
		Yaffas::Service::control( Yaffas::Service::ZARAFA_SERVER(), Yaffas::Service::RESTART() );
	}
	else {
		my $cfg = Yaffas::Constant::FILE()->{imap_conf};
		my $bkc = Yaffas::File::Config->new($cfg,
											{
											-SplitPolicy => 'custom',
											-SplitDelimiter => ':\s*',
											-StoreDelimiter => ': ',
											}
										   );
		my $hashref = $bkc->get_cfg_values();

		$hashref->{autocreatequota} = $quota;
		$bkc->save();
		Yaffas::Service::control( Yaffas::Service::CYRUS(), Yaffas::Service::RESTART() );
	}
	return 1;
}

=pod

=over

=item send_email(TO, SUBJECT, BODY)

sends an email

=back

=cut

sub send_email($$$) {
	my $to = shift;
	my $subject = shift;
	my $body = shift;
	my $from="admin\@localhost";
	my $smtp = Net::SMTP->new('localhost');
	$smtp->mail($from);
	$smtp->to($to);
	$smtp->data();
	$smtp->datasend("From: $from\n");
	$smtp->datasend("Subject: $subject\n");
	$smtp->datasend("To: $to\n");
	$smtp->datasend("$body\n");
	$smtp->dataend();
 	$smtp->quit;

	return 1;

}

=over

=item get_mta

Returns the configured MTA (exim4, sendmail or postfix) for RHEL5.

For Ubuntu it will always return "exim4".

=cut

sub get_mta {
	my $mta = "exim4";
	if(Yaffas::Constant::OS eq 'RHEL5') {
		my $mta_link = "/etc/alternatives/mta";
		if(-l $mta_link) {
			my $link = readlink $mta_link;
			SWITCH: {
				$link eq '/usr/sbin/sendmail.sendmail' && do { $mta = 'sendmail'; last SWITCH; };
				$link eq '/usr/sbin/sendmail.postfix'  && do { $mta = 'postfix';  last SWITCH; };
				$link eq '/usr/sbin/sendmail.exim'     && do { $mta = 'exim4';    last SWITCH; };
			}
		}
		else {
			# error, fall back to default;
			$mta = "sendmail";
		}
	}
	return $mta;
}

1;

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
