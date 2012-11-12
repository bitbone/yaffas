package Yaffas::Module::ZarafaConf;

use strict;
use warnings;
use Yaffas::File;
use Yaffas::File::Config;
use Yaffas::Constant;
use Yaffas::Exception;
use Yaffas::Constant;
use Yaffas::Module::AuthSrv;
use Yaffas::Module::Users;
use Yaffas::Module::Mailsrv::Postfix;
use Yaffas::Mail;
use Yaffas::Auth;
use Yaffas::Auth::Type qw(:standard);
use Yaffas::LDAP;
use Yaffas::Service qw(control STOP START RESTART RELOAD ZARAFA_SERVER ZARAFA_GATEWAY ZARAFA_SPOOLER MYSQL EXIM);
use Error qw(:try);
use Sort::Naturally;
use Text::Template;

our $TESTMODE = 0;

use constant {
	FILTERTYPE => {
		DEFAULT => 0,
		ADPLUGIN => 1,
		ADGROUP => 2,
	},
};

sub zarafa_ldap_filter(;$$) {
	my $filter = shift;
	my $value = shift;

	my $file = Yaffas::File::Config->new(Yaffas::Constant::FILE->{zarafa_ldap_cfg});
	my $cfg = $file->get_cfg_values();

	my $auth = Yaffas::Auth::get_auth_type();

	if (defined $filter) {
		if ($filter == FILTERTYPE->{DEFAULT}) {
			delete $cfg->{ldap_user_search_filter};
			Yaffas::Module::AuthSrv::set_zarafa_ldap($cfg);

			my $postfix_settings = {
				'query_filter' => '(&(objectClass=person)(mail=%s))',
			};
			Yaffas::Module::Mailsrv::Postfix::set_postfix_ldap($postfix_settings, "users", 1);
		}
		if ($filter == FILTERTYPE->{ADPLUGIN} && $auth eq ADS) {
			my $rootbasedn = Yaffas::Auth::get_ads_basedn($cfg->{'ldap_uri'}, "rootDomainNamingContext");
			throw Yaffas::Exception("err_no_rootbasedn") unless $rootbasedn;
			$cfg->{'ldap_user_search_filter'} = "(&(objectClass=person)(objectCategory=CN=Person,CN=Schema,CN=Configuration,$rootbasedn)(zarafaAccount=1))";
			Yaffas::Module::AuthSrv::set_zarafa_ldap($cfg);

			my $postfix_settings = {
				'query_filter' => '(&(objectClass=person)(mail=%s)(zarafaAccount=1))',
			};
			Yaffas::Module::Mailsrv::Postfix::set_postfix_ldap($postfix_settings, "users", 1);
		}
		if ($filter == FILTERTYPE->{ADGROUP} && $auth eq ADS) {
			my $rootbasedn = Yaffas::Auth::get_ads_basedn($cfg->{'ldap_uri'}, "rootDomainNamingContext");
			throw Yaffas::Exception("err_no_rootbasedn") unless $rootbasedn;

			my @group = Yaffas::LDAP::search_attribute("user", $value, "dn");
			throw Yaffas::Exception("err_no_group_found") unless scalar @group;
			$cfg->{'ldap_user_search_filter'} = "(&(objectClass=person)(objectCategory=CN=Person,CN=Schema,CN=Configuration,$rootbasedn)(memberOf=$group[0]))";
			Yaffas::Module::AuthSrv::set_zarafa_ldap($cfg);

			my $postfix_settings = {
				'query_filter' => '(&(objectClass=person)(mail=%s)(memberOf='.$group[0].'))',
			};
			Yaffas::Module::Mailsrv::Postfix::set_postfix_ldap($postfix_settings, "users", 1);
		}
	}
	else {
		if ($cfg->{ldap_user_search_filter} =~ /memberOf=CN=(.*?),((OU=.*?,)|(CN=Users,))*.*/) {
			return FILTERTYPE->{ADGROUP}, $1;
		}
		if ($cfg->{ldap_user_search_filter} =~ /\(zarafaAccount=1\)/) {
			return FILTERTYPE->{ADPLUGIN};
		}
		if (
			$cfg->{ldap_user_search_filter} eq "(&(objectClass=posixAccount)(objectClass=zarafa-user))" ||
			$cfg->{ldap_user_search_filter} =~ /\(&\(objectClass=person\)\(objectCategory=CN=Person,CN=Schema,CN=Configuration,(DC=.*?,?)+\)\)/
			) {
			return FILTERTYPE->{DEFAULT};
		}
	}
}

sub search_deleted_users($$) {
	my $filter = shift;
	my $value = shift;

	my $auth = Yaffas::Auth::get_auth_type();

	my @current_stores = grep {$_ ne "SYSTEM"} Yaffas::Module::Users::get_zarafa_stores();
	my @new_stores;
	my @delete_stores;

	if ($filter == FILTERTYPE->{DEFAULT}) {
		return;
	}

	if ($filter == FILTERTYPE->{ADPLUGIN} && $auth eq ADS) {
		@new_stores = Yaffas::LDAP::search_user_by_attribute("zarafaAccount", 1);
	}

	if ($filter == FILTERTYPE->{ADGROUP} && $auth eq ADS) {
		@new_stores = Yaffas::LDAP::search_attribute("group", $value, "sAMAccountName");
	}

	foreach my $cs (@current_stores) {
		my $found = 0;
		foreach my $ss (@new_stores) {
			if (lc $cs eq lc $ss) {
				$found = 1;
			}
		}
		if ($found == 0) {
			push @delete_stores, $cs;
		}
	}

	return @delete_stores;
}

sub attachment_size(;$) {
	my $size = shift;

	my $file = Yaffas::File->new(Yaffas::Constant::FILE->{webaccess_htaccess});
	throw Yaffas::Exception("err_file_read", Yaffas::Constant::FILE->{webaccess_htaccess}) unless $file;
	my @lines = $file->search_line(qr/^php_value\s+upload_max_filesize\s*(.*)/);

	if (defined $size) {
		throw Yaffas::Exception("err_not_numeric") unless ($size =~ /^\d+$/ and $size > 0);
		$file->splice_line($lines[0], 1, "php_value upload_max_filesize ${size}M");

		$size++;
		@lines = $file->search_line(qr/^php_value\s+post_max_size\s*(.*)/);
		$file->splice_line($lines[0], 1, "php_value post_max_size ${size}M");

		$file->write();
	}
	else {
		my $line = $file->get_content($lines[0]);
		if ($line =~ /^php_value\s+upload_max_filesize\s*(\d+)\s*M/) {
			return $1;
		}
		return undef;
	}
}

sub optimized_memory_for(;$) {
	my $value = shift;

	my $mem_installed = 0;
	my $mem_info = Yaffas::File::Config->new("/proc/meminfo");

	$mem_installed = $mem_info->get_cfg_values()->{"MemTotal:"};

	if ($mem_installed =~ /^(\d+)/) {
		$mem_installed = $1;
	}
	else {
		return -1;
	}
	$mem_installed *= 1024;

	if ($value) {
		my $mem_optimized = $mem_installed / 4;
		my $user_count = scalar Yaffas::UGM::get_users();
		$user_count = 16 if ($user_count < 16);
		my $sort_key_size = $user_count * 1024 * 1024;

		if ($sort_key_size > $mem_optimized) {
			$sort_key_size = $mem_optimized;
		}

		my $file = Yaffas::File->new(Yaffas::Constant::FILE->{zarafa_mysql_cnf});
		$file->get_content() or throw Yaffas::Exception("err_file_read", $file->name());
		my $line = $file->search_line(qr/^innodb_buffer_pool_size\s*=\s*(\d+)$/);
		if (defined $line) {
			$file->splice_line($line, 1, "innodb_buffer_pool_size = $mem_optimized");
		}
		else {
			$file->add_line("[mysqld]");
			$file->add_line("innodb_buffer_pool_size = $mem_optimized");
		}
		$file->save() or throw Yaffas::Exception("err_file_write", $file->name());

		$file = Yaffas::File::Config->new(Yaffas::Constant::FILE->{zarafa_server_cfg},
										  {
										  -SplitPolicy => 'custom',
										  -SplitDelimiter => '\s*=\s*',
										  -StoreDelimiter => ' = ',
										  }
										 );
		$file->get_content() or throw Yaffas::Exception("err_file_read", $file->name());
		$file->get_cfg_values()->{cache_cell_size} = $mem_optimized;
		$file->get_cfg_values()->{cache_sortkey_size} = $sort_key_size;
		$file->save() or throw Yaffas::Exception("err_file_write", $file->name());

		unless ($TESTMODE) {
			Yaffas::Service::control(EXIM(), STOP());
			Yaffas::Service::control(ZARAFA_GATEWAY(), STOP());
			Yaffas::Service::control(ZARAFA_SERVER(), STOP());
			Yaffas::Service::control(ZARAFA_SPOOLER(), STOP());
			Yaffas::Service::control(MYSQL(), RESTART());
			Yaffas::Service::control(ZARAFA_SERVER(), START());
			Yaffas::Service::control(ZARAFA_GATEWAY(), START());
			Yaffas::Service::control(ZARAFA_SPOOLER(), START());
			Yaffas::Service::control(EXIM(), START());
		}
	}
	else {
		my $file = Yaffas::File->new(Yaffas::Constant::FILE->{zarafa_mysql_cnf});
		$file->get_content() or throw Yaffas::Exception("err_file_read", $file->name());
		my $line = $file->search_line(qr/^innodb_buffer_pool_size\s*=\s*(\d+)$/);
		my $mem_mysql = 0;
		my $mem_zarafa = 0;

		if (defined $line) {
			my $line = ($file->get_content())[$line];
			if ($line =~ /^innodb_buffer_pool_size\s*=\s*(\d+)$/) {
				$mem_mysql = $1*4;
			}
		}
		else {
			return -1, $mem_installed;
		}

		$file = Yaffas::File::Config->new(Yaffas::Constant::FILE->{zarafa_server_cfg});
		$file->get_content() or throw Yaffas::Exception("err_file_read", $file->name());
		$mem_zarafa = $file->get_cfg_values()->{cache_cell_size} * 4;

		if ($mem_mysql <= 0 || $mem_zarafa != $mem_mysql) {
			return -1, $mem_installed;
		}

		return $mem_mysql, $mem_installed;
	}
}

sub get_quota_message ($) {
	my $type = shift;
	my $mail =
	  Yaffas::File->new(
		Yaffas::Constant::FILE->{ 'zarafa_quota_mail_' . $type } );
	return $mail->get_content_singleline();
}

sub set_quota_message ($$) {
	my ( $type, $content ) = @_;
	my $mail =
	  Yaffas::File->new(
		Yaffas::Constant::FILE->{ 'zarafa_quota_mail_' . $type } );
	$mail->set_content( [$content] );
	$mail->write();
}

sub set_default_quota {
	my $limit = shift; # in MB
	if ($limit > 0) {
		$limit *= 1024;
	}
	elsif ($limit <= 0)
	{
		$limit = -1;
	}
	Yaffas::Mail::set_default_quota($limit);
}

sub get_default_features() {
	my $f = Yaffas::File::Config->new(Yaffas::Constant::FILE->{zarafa_server_cfg});

	my $values = $f->get_cfg_values();

	my %ret;

	if (exists $values->{disabled_features}) {
		%ret = ("imap" => "on", "pop3" => "on");
		foreach my $v (split /\s+/, $values->{disabled_features}) {
			$ret{$v} = "off";
		}
	}
	else {
		%ret = ("imap" => "off", "pop3" => "off");
	}

	return \%ret;
}

sub set_default_features() {
	my %featues = @_;

	foreach my $f (keys %featues) {
		change_default_features($f, $featues{$f} eq "on" ? 1 : 0);
	}
}

sub change_default_features {
	my $feature = shift;
	my $state = shift;

	my $file = Yaffas::File::Config->new(Yaffas::Constant::FILE->{zarafa_server_cfg},
		{
			-SplitPolicy => 'custom',
			-SplitDelimiter => '\s*=\s*',
			-StoreDelimiter => ' = ',
		}
	);
	my $cfg = $file->get_cfg_values();

	my %values;

	if (exists $cfg->{disabled_features}) {
		%values = map { $_ => 1 } split /\s+/, $cfg->{disabled_features};
	}
	else {
		# config not set - all features are disabled
		%values = ( imap => 1, pop3 => 1);
	}

	if ($state == 1) {
		delete $values{$feature};
	}
	else {
		$values{$feature} = 1;
	}

	$cfg->{disabled_features} = join " ", keys %values;

	$file->save();

	control(ZARAFA_SERVER(), RELOAD());
}

sub get_zarafa_database() {
	print Yaffas::Constant::FILE->{zarafa_server_cfg};
	my $file = new Yaffas::File::Config(Yaffas::Constant::FILE->{zarafa_server_cfg},
		{
			-SplitPolicy => 'custom',
			-SplitDelimiter => '\s*=\s*',
			-StoreDelimiter => "=",
		});

	return {
		host => $file->get_cfg_values()->{mysql_host},
		user => $file->get_cfg_values()->{mysql_user},
		password => $file->get_cfg_values()->{mysql_password},
		database => $file->get_cfg_values()->{mysql_database}
	};
}

=item create_prf ( VALUES )

Creates PRF file from given VALUES hash and returns it. Uses outlook.prf as a
template which is filled with Text::Template.

Possible values are:

  profilename
  mailboxname
  password
  homeserver
  overwriteprofile
  backupprofile

=cut

sub create_prf {
    my $values = shift;
    my $template = Text::Template->new(TYPE => 'FILE',  SOURCE => 'outlook.prf');
    my $text = $template->fill_in(HASH => $values);
    return $text;
}

sub set_zarafa_database($$$$) {
	my $host = shift;
	my $database = shift;
	my $user = shift;
	my $password = shift;

	throw Yaffas::Exception("err_syntax") if ($host =~ /;/ or $database =~ /;/);
	throw Yaffas::Exception("err_password_hash") if ($password =~ /#/);
	throw Yaffas::Exception("err_no_server") unless ($host);

	my $db = DBI->connect("dbi:mysql:host=$host", $user, $password);

	throw Yaffas::Exception("err_mysql_connect") unless defined $db;

	my $file = new Yaffas::File::Config(Yaffas::Constant::FILE->{zarafa_server_cfg},
		{
			-SplitPolicy => 'custom',
			-SplitDelimiter => '\s*=\s*',
			-StoreDelimiter => "=",
		});
	$file->get_cfg_values()->{mysql_user} = $user;
	$file->get_cfg_values()->{mysql_password} = $password;
	$file->get_cfg_values()->{mysql_database} = $database;
	$file->get_cfg_values()->{mysql_host} = $host;

	$file->save();
}

sub conf_dump() {
	my $bkc = Yaffas::Conf->new();
	my $sec = $bkc->section("zarafaconf");
	my $func = Yaffas::Conf::Function->new("attachment_size", "Yaffas::Module::ZarafaConf::attachment_size");
	$func->add_param({type => "scalar", param => attachment_size()});
	$sec->del_func("attachment_size");
	$sec->add_func($func);

	$sec = $bkc->section("mailboxconf");
	$func = Yaffas::Conf::Function->new("quota", "Yaffas::Module::ZarafaConf::set_default_quota");
	$func->add_param({type => "scalar", param => (Yaffas::Mail::get_default_quota()/1024)});
	$sec->del_func("quota");
	$sec->add_func($func);

	$sec = $bkc->section("zarafafeatures");
	$func = Yaffas::Conf::Function->new("setfeatures", "Yaffas::Module::ZarafaConf::set_default_features");
	$func->add_param({type => "hash", param => Yaffas::Module::ZarafaConf::get_default_features()});
	$sec->del_func("setfeatures");
	$sec->add_func($func);

	$sec = $bkc->section("zarafaquota");
	for my $type (qw(warn soft hard)) {
		$func = Yaffas::Conf::Function->new("quota-msg-$type", "Yaffas::Module::ZarafaConf::set_quota_message");
		$func->add_param({type => "scalar", param => $type});
		$func->add_param({type => "scalar", param => get_quota_message($type)});
		$sec->del_func("quota-msg-$type");
		$sec->add_func($func);
	}

	$bkc->save();
	return 1;
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
