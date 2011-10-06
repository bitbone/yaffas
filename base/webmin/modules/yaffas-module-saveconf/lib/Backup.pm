#!/usr/bin/perl -w
package Yaffas::Module::Backup;
use strict;
use warnings;
use Yaffas;
use Yaffas::Auth;
use Yaffas::File;
use Yaffas::Conf;
use Yaffas::Conf::Comment;
use Yaffas::Conf::Function;
use Yaffas::Constant;
use Yaffas::Product;
use Yaffas::Service qw(control START STOP RESTART LDAP NSCD MYSQL HYLAFAX CAPI4HYLAFAX SAMBA CYRUS POSTFIX);
use Yaffas::LDAP;
use Yaffas::Exception;
use Error qw(:try);

use File::Temp qw(tempdir tempfile);
use Net::LDAP::LDIF;
use File::Find;

### prototypes
sub new();
sub dump();
sub restore($);
sub check_keys();
sub _get_ldap();
sub _get_mysql();
sub _get_pgsql($);
sub _set_pgsql($$);
sub _get_files();

### globals
#our $LDAP_PASS = Yaffas::LDAP::get_passwd();
our $LDAP_PASS;
try { $LDAP_PASS = Yaffas::Auth::get_local_root_passwd(); } catch Yaffas::Exception with {};
our @ISA = qw(Yaffas::Module);



=pod

=head1 NAME

B<Yaffas::Module::Backup> - Generic routines for the bbsaveconf module.

=head1 SYNOPSIS

use Yaffas::Module::Backup;

    new( )
    dump( )
    restore( YAFFAS_XML )

=head1 DESCRIPTION

This module contains routines for dumping and restoring backups.

=head1 FUNCTIONS

=over

=item new( )

This routine creates a new backup object.

=cut

sub new()
{
	my $class = shift;
	my $self = {};

	bless $self, $class;
	return $self;
}

=item B<check_product_keys ()>

This routine checks if all installed products have a valid key.

=cut

sub check_product_keys()
{
	foreach my $product (Yaffas::Product::get_all_installed_products())
	{
		next if ($product eq 'framework');
		return undef unless Yaffas::Product::check_product_license($product);
	}

	return 1;
}

=item dump( )

This routine returns an array containing our yaffas.xml our user wants to download
and the total size of yaffas.xml.

=cut

sub dump()
{
	my $self = shift;

	$self->{backup}->{ldap}  = _get_ldap() if (Yaffas::Auth::get_auth_type() eq Yaffas::Auth::Type::LOCAL_LDAP);
	$self->{backup}->{files} = _get_files();
	if (Yaffas::Product::check_product("fax")) {
		$self->{backup}->{mysql} = _get_mysql();
		$self->{backup}->{pgsql_bbfaxconf} = _get_pgsql('bbfaxconf');
	}
	$self->{backup}->{pgsql_bkprint2fax} = _get_pgsql('bkprint2fax');

	my $back = "bkbackup";

	create_config() unless (-r Yaffas::Constant::FILE->{yaffas_config});

	## lets save the product version...
	# first wie need a new section
	my $bkc = Yaffas::Conf->new();
	my $bks_pv = $bkc->section("product_version");

	# lets check for each product..
	for my $product (Yaffas::Product::list_all_possible_products()) {
		my $bool = Yaffas::Product::check_product($product);
		my $pk_comment;
		if($bool){
			my $version = Yaffas::Product::get_version_of($product);
			my $revision = Yaffas::Product::get_revision_of($product);
			$pk_comment = Yaffas::Conf::Comment->new($product, $version . "." . $revision );
		}else{
			$pk_comment = Yaffas::Conf::Comment->new($product, 0);
		}
		$bks_pv->add_comment($pk_comment);
	}


	# now we gonna fill /etc/yaffas.xml with the values of $self->{'backup'}
	# first we need a new section
	my $bks = $bkc->section($back);

	if (Yaffas::Product::check_product("fax")) {
		# add a mysql function
		my $func_mysql = Yaffas::Conf::Function->new('mysql', "Yaffas::Module::Backup::_set_mysql");
		$func_mysql->add_param({type => 'mime', param => $self->{'backup'}->{'mysql'}});
		$bks->add_func($func_mysql);

		# add a function to dump psql bbfaxconf db
		my $func_pgsql_bbfaxconf = Yaffas::Conf::Function->new('pgsql-bbfaxconf', "Yaffas::Module::Backup::_set_pgsql");
		$func_pgsql_bbfaxconf->add_param({type => 'mime', param => 'bbfaxconf'});
		$func_pgsql_bbfaxconf->add_param({type => 'mime', param => $self->{'backup'}->{'pgsql_bbfaxconf'}});
		$bks->add_func($func_pgsql_bbfaxconf);
	}

	chomp(my $dom = Yaffas::do_back_quote(Yaffas::Constant::APPLICATION->{'hostname'}, "-d"));

	if ($dom !~ /\./) {
		$dom = Yaffas::LDAP::dn_to_name(Yaffas::LDAP::get_local_domain());
	}
	if ($dom !~ /\./) {
		$dom = "yaffas.local";
	}

	# FIXME bkprint2fax is a wrong name. also base attributes in this db!
	# add a pgsql function to dump bkprint2fax
	my $func_pgsql_bkprint2fax = Yaffas::Conf::Function->new('pgsql-bkprint2fax', "Yaffas::Module::Backup::_set_pgsql");
	$func_pgsql_bkprint2fax->add_param({type => 'mime', param => 'bkprint2fax'});
	$func_pgsql_bkprint2fax->add_param({type => 'mime', param => $self->{'backup'}->{'pgsql_bkprint2fax'}});
	$bks->add_func($func_pgsql_bkprint2fax);
	
	my $func_ldap = undef;
	if (Yaffas::Auth::get_auth_type() eq Yaffas::Auth::Type::LOCAL_LDAP)
	{
		# add a ldap function
		$func_ldap = Yaffas::Conf::Function->new('ldap', "Yaffas::Module::Backup::_set_ldap");
		$func_ldap->add_param({type => 'scalar', param => $dom});
		$func_ldap->add_param({type => 'mime', param => $self->{'backup'}->{'ldap'}});
	}

	# add a files function
	my $func_files = Yaffas::Conf::Function->new('files', "Yaffas::Module::Backup::_set_files");
	$func_files->add_param({type => 'array', param => $self->{backup}->{files} });

	$bks->add_func($func_ldap) if (Yaffas::Auth::get_auth_type() eq Yaffas::Auth::Type::LOCAL_LDAP);
	$bks->add_func($func_files);

	$bkc->save();

	my $bkfile = Yaffas::File->new(Yaffas::Constant::FILE->{'yaffas_config'});
	my $conffile = $bkfile->get_content_singleline();

	### and now we return the config to it's original state again :)
	$bkc->delete_section($back);
	$bkc->save();

	return $conffile;
}

=item write_config( CONTENT )

This routine writes the given content in our /etc/yaffas.xml. B<CONTENT> has to be
the content of yaffas.xml given from the user. (NOT THE FILENAME - THE CONTENT!!!)

=cut

sub write_config {
	my ($self, $backup) = @_;

	# write the config
	unlink Yaffas::Constant::FILE->{'yaffas_config'} if -f Yaffas::Constant::FILE->{'yaffas_config'};
	open(FILE, ">", Yaffas::Constant::FILE->{'yaffas_config'} . ".upload");
	print FILE $backup;
	close(FILE);

}

=item check_installed_products

returns true if the installed products are the same as descripedd in Yaffas::Constant::FILE->{'yaffas_config'}
else false

=cut

sub check_installed_products{
	my $bkc = Yaffas::Conf->new( Yaffas::Constant::FILE->{'yaffas_config'} . ".upload" );
	return "notconf" unless (defined($bkc));  
	return $bkc->test_products();
}

=item check_faxtype

returns faxtype, defined in uploaded yaffas.xml

=cut

sub check_faxtype{
	my $bkc = Yaffas::Conf->new( Yaffas::Constant::FILE->{'yaffas_config'} . ".upload" );
	return undef unless defined $bkc;
        return (defined($bkc->eicon_defined()))? "EICON" : "AVM";
}

=item B<restore( )>

restores the settings of /etc/yaffas.xml to the system

=cut

sub restore($)
{
	my $self = shift;

	if(Yaffas::Auth::auth_type eq Yaffas::Auth::Type::NOT_SET) {
		throw Yaffas::Exception("err_auth_not_set");
	}

	# apply the config
	my $bkc = Yaffas::Conf->new( Yaffas::Constant::FILE->{yaffas_config} . ".upload");
	return undef if (! defined($bkc) );
	$bkc->apply();
	$self->{'errors'} = $bkc->{'Errors'} if $bkc->{'Errors'};

	control(LDAP, RESTART);
	control(NSCD, RESTART);
	control(POSTFIX, RESTART);

	# mail
	if (Yaffas::Product::check_product("mail"))
	{
		control(CYRUS, RESTART);
	}

	# mail or gate or zarafa
	if (Yaffas::Product::check_product('mail') or Yaffas::Product::check_product('gate') or Yaffas::Product::check_product('zarafa')) 
	{
		my $fetchmailrc = Yaffas::Constant::FILE->{'fetchmailrc'};
		my $mode = 0600;
		chmod $mode, $fetchmailrc;

		my ($login,$pass,$uid,$gid) = getpwnam("fetchmail");
		chown $uid, -1, $fetchmailrc;
	}

	if (Yaffas::Product::check_product("pdf") or Yaffas::Product::check_product("fax")) {
		control(SAMBA, RESTART);
	}

	# fax
	if (Yaffas::Product::check_product("fax"))
	{
		control(MYSQL, RESTART);
		control(HYLAFAX, STOP);
		control(CAPI4HYLAFAX, STOP);
		control(HYLAFAX, START);
		control(CAPI4HYLAFAX, START);
	}

	$bkc->{Errors}->throw() if $bkc->{Errors};

	return 1;
}



### get the ldap data and write it to $self
sub _get_ldap()
{
	my $ldif;
	my $bke=Yaffas::Exception->new();
	my $domain = Yaffas::LDAP::get_domain();
	try {
		$ldif = Yaffas::do_back_quote
			(
			Yaffas::Constant::APPLICATION->{'ldapsearch'}, "-x", "-LLL", "-D", "cn=ldapadmin,ou=People,$domain",
			"-b", $domain, "-w", $LDAP_PASS
			);
		throw Yaffas::Exception("err_no_ldif") if ($ldif =~ /^\s*$/);
	} catch Yaffas::Exception with {
		$bke->append( shift );
	};
	throw $bke if $bke;

	return $ldif;
}

sub _get_pgsql($)
{
	my $db = shift;

	if ($db !~ /[\w\d]+/) {
		return undef;
    }

	my $pgsql = Yaffas::do_back_quote(Yaffas::Constant::APPLICATION->{'su'}, '--', 'postgres', '-c', "pg_dump -c $db");
	return undef unless $? == 0;
	return $pgsql;
}

sub _get_mysql()
{
	my $self = shift;

	my $mysql = Yaffas::do_back_quote(Yaffas::Constant::APPLICATION->{'mysqldump'}, "--skip-tz-utc", "-u", "root", "-p$LDAP_PASS", "Cypheus");
	return undef unless $? == 0;
	return $mysql;
}

sub _get_files()
{
	### each entry of this array contains files/directories to backup
	# if the entry is a file, it will be sucked in via Yaffas::File
	# if the entry is a directory, it will be packed up with bzip compression via tar
	# at the end of this routine we will return  a hashref containing all files/directories
	# make sure to add the right things to dump() and restore().
	# no remove is needed, you start with a empty file and
	# all setup routings will write its values to the config file.


	my @files =
		(
		 Yaffas::Constant::DIR->{'bkconfig'},
		);

	if (Yaffas::Product::check_product("mailgate")) {
		push @files, Yaffas::Constant::DIR->{mppserver_conf}, Yaffas::Constant::FILE->{mppd_conf_xml};
	}

	### XXX: add more files/entries for product dependent modules here
	#
	# Please make sure to remove abandoned/deprecated entries, if you find some.
	#
	if (Yaffas::Product::check_product('mail') or Yaffas::Product::check_product('gate') or Yaffas::Product::check_product('zarafa')) {
		push @files,  Yaffas::Constant::FILE->{'fetchmailrc'};
	}

	if (Yaffas::Product::check_product('zarafa')) {
		push @files, Yaffas::Constant::FILE->{'zarafa_quota_mail_warn'};
		push @files, Yaffas::Constant::FILE->{'zarafa_quota_mail_soft'};
		push @files, Yaffas::Constant::FILE->{'zarafa_quota_mail_hard'};
	}

	if (Yaffas::Product::check_product('fax') && -d Yaffas::Constant::DIR->{'divasdir'}) {
		push @files, Yaffas::Constant::DIR->{'divasdir'}."/routing.ini";
	}

	my $ret = [];

	foreach my $file (@files)
	{
		next unless -e $file;

		if(-f $file)
		{
			my $bkf = Yaffas::File->new($file) || return undef;
			my $content = $bkf->get_content_singleline() | "";
			push @$ret, {
						 name => $file,
						 content => $content,
						 type => 'file',
						};
		}
		elsif(-d $file)
		{
			push @$ret, {
						 name => $file,
						 type => 'dir',
						 content => scalar Yaffas::do_back_quote(Yaffas::Constant::APPLICATION->{'tar'}, "cjpf", "-", $file),
						};
		}
	}

	return $ret;
}

sub _set_pgsql($$)
{
	my $db = shift;
	my $dump = shift;

#	Yaffas::do_back_quote('/bin/su', 'postgres', 'pg_dump', $db);

	#my $cmd =  Yaffas::Constant::APPLICATION->{'su'}." postgres 'psql $db'";
	open(CMD, "|-", Yaffas::Constant::APPLICATION->{'su'}, "postgres", 'psql', $db) || return undef;
	print CMD $dump;
	return undef unless $? == 0;
	close(CMD);

	return 1;
}

### Just insert the mysql dump
sub _set_mysql($)
{
	my $dump = shift;
	# check if cypheus db exists. quick and dirty. reimplement me!!!
	my @dbs = Yaffas::do_back_quote(Yaffas::Constant::APPLICATION->{'mysqlshow'}, "-uroot", "-p$LDAP_PASS");
	if ( ! grep(/Cypheus/i, @dbs) )
	{
		Yaffas::do_back_quote(Yaffas::Constant::APPLICATION->{'mysqladmin'}, "-uroot", "-p$LDAP_PASS", "create", "Cypheus" );
	}
	else
	{
		Yaffas::do_back_quote(Yaffas::Constant::APPLICATION->{'mysqladmin'}, "-f", "-uroot", "-p$LDAP_PASS", "drop", "Cypheus" );
		Yaffas::do_back_quote(Yaffas::Constant::APPLICATION->{'mysqladmin'}, "-uroot", "-p$LDAP_PASS", "create", "Cypheus" );
 	}
	#my $cmd = Yaffas::Constant::APPLICATION->{'mysql'} . " -uroot -p$LDAP_PASS Cypheus";
	open(CMD, "|-", Yaffas::Constant::APPLICATION->{'mysql'} , "-uroot", "-p$LDAP_PASS", 'Cypheus')|| return undef;
	print CMD $dump;
	return undef unless $? == 0;
	close(CMD);

	return 1;
}

### Load the LDAP thingy
sub _set_ldap($)
{
	my $domain = shift;
	my $ldap = shift;

	throw Yaffas::Exception("err_no_domain") if ($domain =~ /^\s*$/);
	throw Yaffas::Exception("err_no_user") if ($ldap =~ /^\s*$/);

	# clear the ldap thingy
	control(LDAP, STOP);
	system(Yaffas::Constant::APPLICATION->{rm}  . ' -f ' . Yaffas::Constant::DIR->{ldap_data} .'*');

	# create a tempfile
	my $file = File::Temp->new()->filename();
	my $bkf = Yaffas::File->new($file);
	$bkf->add_line($ldap);
	$bkf->save();

	my $newfilename = File::Temp->new()->filename();

	my $oldif = Net::LDAP::LDIF->new($file, "r", lowercase=>0);
	my $nldif = Net::LDAP::LDIF->new($newfilename, "w", lowercase=>0);

	# crypt password
	#my $pw = Yaffas::LDAP::get_passwd();
	my $pw = Yaffas::Auth::get_local_root_passwd();
	my $crypt_pw = Yaffas::do_back_quote(Yaffas::Constant::APPLICATION->{slappasswd}, "-c", "crypt", "-s", $pw);
	chomp($crypt_pw);

	while (! $oldif->eof()) {
		my $entry = $oldif->read_entry();
		throw Yaffas::Exception("err_no_user") unless ($entry);

		if ($entry->dn() =~ /^uid=root,.*/) {
			$entry->replace(userPassword=>$crypt_pw);
			$nldif->write_entry($entry);
		} else {
			$nldif->write_entry($entry);
		}
	}

	$file = $newfilename; # exchange old and new file

	# change the dn_name
	chomp(my $dn_new = Yaffas::do_back_quote(Yaffas::Constant::APPLICATION->{'hostname'}, "-d"));

	system(Yaffas::Constant::APPLICATION->{'domrename'}, $domain, $dn_new, $file);
	throw Yaffas::Exception("err_domrename", $?) unless $? == 0;

	system(Yaffas::Constant::APPLICATION->{'slapadd'}, "-f", Yaffas::Constant::FILE->{slapd_conf}, "-c", "-l", Yaffas::Constant::FILE->{'tmpslap'});
	throw Yaffas::Exception("err_ldap_add", $?) unless $? == 0;
	
	my $uid;
	my $gid;
	if(Yaffas::Constant::OS eq 'Ubuntu') {
		$uid = Yaffas::UGM::get_uid_by_username("openldap");
		$gid = Yaffas::UGM::get_gid_by_groupname("openldap");
	} else {
		$uid = Yaffas::UGM::get_uid_by_username("ldap");
		$gid = Yaffas::UGM::get_gid_by_groupname("ldap");
	}

	find(sub{chown $uid, $gid, $File::Find::name}, Yaffas::Constant::DIR->{ldap_data});

	control(LDAP, RESTART);
	control(NSCD, RESTART);

	unlink $file;
	return 1;
}

### This subroutine writes each content to it's destination.
# the array must look like this:
# (file1, content_of_file1, file2, content_of_file2)...
sub _set_files
{
	my $array = \@_;

	my $tar   = Yaffas::Constant::APPLICATION->{'tar'};

	foreach (@{$array}) {
		my $name    = $_->{name};
		my $content = $_->{content};
		my $type    = $_->{type};

		if ($type eq "file") {
			Yaffas::File->new($name, $content)->write();
		}elsif ($type eq "dir") {
			Yaffas::do_back_quote(Yaffas::Constant::APPLICATION->{rm}, "-rf", "${name}/*");
			open(TAR, "|-", $tar, "-xjC", "/" );
			print TAR  $content;
			close(TAR);
		}
	}
}

# creates a new config by calling conf_dump() in each module
# if delete is true it deletes the old file before creating a new one
sub create_config($) {
	my $delete = shift;

	return if(-r Yaffas::Constant::FILE->{yaffas_config} and $delete == 0); # file exists and should not be deleted.
	unlink Yaffas::Constant::FILE->{yaffas_config} if ($delete);

	my @files;
    my $dir = Yaffas::Constant::DIR->{yaffas_module};
	find(sub{push @files, $File::Find::name if /^\w*\.pm$/}, $dir);
	my $prefix = "Yaffas::Module";
	my $bke = Yaffas::Exception->new();

	foreach my $file (@files) {

		my $pkg = $file;
		$pkg =~ s/.pm$//;
		$pkg =~ s/$dir//;
		$pkg =~ s#/#::#g;
		$pkg = $prefix."::".$pkg;

		my $sub = $pkg."::conf_dump";

		try {
			no strict "refs";
			eval "use $pkg;";
			die $@ if $@; # did the eval work? if not cahced by otherwhise()
			if (defined(&{$sub})) {
				&{$sub}();
			}
			use strict;
				

		} catch Yaffas::Exception with{
			$bke->append(shift);
		} otherwise {
			$bke->add("err_syntax", shift);
		};
	}

	throw $bke if $bke;
}

sub conf_dump {
    1;
}

return 1;

=back

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
