#!/usr/bin/perl
package Yaffas::Module::Certificate;

use warnings;
use strict;

sub BEGIN {
	use Exporter;
	our @ISA = qw(Exporter Yaffas::Module);
	our @EXPORT_OK = qw(&delete_cert
						&list_certs
						&import_cert
						validate_gencert
						create_certificate);
}

use Time::Local;
use Yaffas;
use Yaffas::Exception;
use Yaffas::Check;
use Yaffas::Service;
use File::Copy;
use Yaffas::Constant;
use Yaffas::Product qw(check_product);

sub create_certificate($){
	my $in_hashref = shift;
	my $service = $in_hashref->{'service'};
	my $o = $in_hashref->{'o'};
	my $ou = $in_hashref->{'ou'};
	my $cn = $in_hashref->{'cn'};
	my $l = $in_hashref->{'l'};
	my $c = $in_hashref->{'c'};
	my $email = $in_hashref->{'emailAddress'};
	my $st = $in_hashref->{'st'};
	my $bits = $in_hashref->{'keysize'};
	my $days = $in_hashref->{'days'};

	my $TMPFILE = '/tmp/bbcertificate.' . join "" , localtime();
	my $DIR = Yaffas::Constant::DIR->{ssl_certs_org};

	my $CRT = "$service.crt";
	my $KEY = "$service.key";

	if ($service eq "all") {
		$CRT = 'default.crt';
		$KEY = 'default.key';
	}

	$CRT = Yaffas::Constant::DIR->{ssl_certs_org} . $CRT;
	$KEY = Yaffas::Constant::DIR->{ssl_certs_org} . $KEY;

	my $ORS = $\;
	local $\;		## :-) zur sicherzeit.
	$\ = "\n";

	open(TMP, ">" , $TMPFILE) or throw Yaffas::Exception("err_file_write", $TMPFILE);
	print TMP "RANDFILE = ~/.rnd";
	print TMP "[ req ]";
	print TMP " distinguished_name = req_distinguished_name";
	print TMP " prompt = no";
	print TMP "[ req_distinguished_name ]";
	print TMP " CN = $cn";
	print TMP " O = $o";
	print TMP " OU = $ou" if ($ou !~ /^\s*$/);
	print TMP " L = $l";
	print TMP " ST = $st";
	print TMP " C = $c";
	print TMP " emailAddress = $email" if ($email !~ /^\s*$/);
	$\ = $ORS;

	close(TMP) or throw Yaffas::Exception("err_file_write", $TMPFILE);

	my $tmpcrt = Yaffas::Constant::DIR->{ssl_certs_org}."tmpcrt";
	my $tmpkey = Yaffas::Constant::DIR->{ssl_certs_org}."tmpkey";

	rename($KEY, $tmpkey);
	rename($CRT, $tmpcrt);

	my $error = Yaffas::do_back_quote(
		Yaffas::Constant::APPLICATION->{openssl}, 'req', '-nodes', '-config', $TMPFILE,
		'-x509', '-newkey', 'rsa:' . $bits, '-keyout', $KEY,
		'-out', $CRT, '-days', $days, '-utf8'
		);
	unlink $TMPFILE;

	if($error) {
		rename($tmpkey, $KEY);
		rename($tmpcrt, $CRT);
		Yaffas::Exception->throw('e_genfailed', $error) if $error;
	}

	if( (stat($CRT))[9] < time() - 5 ){## letzte aenderung liegt weniger als 5 sec zurueck?
		rename($tmpkey, $KEY);
		rename($tmpcrt, $CRT);
		throw Yaffas::Exception('err_cert_creation');
	}

	unlink $tmpcrt;
	unlink $tmpkey;

	update_symlinks();
	create_merged_certs();
	restart_service($service);
}

sub update_symlinks(){
	#these constants already have a trailing /
	#so remove it
	my $org = Yaffas::Constant::DIR->{ssl_certs_org};
	$org =~ s,/$,,;
	my $lnkdest = Yaffas::Constant::DIR->{ssl_certs};
	$lnkdest =~ s,/$,,;
	my $exception = Yaffas::Exception->new();

	my %links = (
				 "exim.crt" => "",
				 "postfix.crt" => "",
				 "cups.crt" => "",
				 "usermin.crt" => "",
				 "cyrus.crt" => "",
				 "webmin.crt" => "",
				 "ldap.crt" => "",
				 "zarafa-ical.crt" => "",
				 "zarafa-webaccess.crt" => "",
				 "zarafa-gateway.crt" => "",
				 "zarafa-server.crt" => "",
				 "mppmanager.crt" => "",
				 "exim.key" => "",
				 "postfix.key" => "",
				 "cups.key" => "",
				 "usermin.key" => "",
				 "cyrus.key" => "",
				 "webmin.key" => "",
				 "ldap.key" => "",
				 "zarafa-ical.key" => "",
				 "zarafa-webaccess.key" => "",
				 "zarafa-gateway.key" => "",
				 "zarafa-server.key" => "",
				 "mppmanager.key" => "",
				);

	opendir(DIR, $org) or throw Yaffas::Exception('err_dir_read', $org);
	my @files = grep{ /\.(crt|key)$/ && -f "$org/$_" } readdir(DIR);
	closedir(DIR) or throw Yaffas::Exception('err_dir_read', $org);


	foreach (keys %links) {
		unlink "$lnkdest/$_";
	}
	throw $exception if $exception;

	foreach (@files) {
		next if /default\.(crt|key)/;
		symlink "$org/$_", "$lnkdest/$_" or $exception->add('err_file_symlink', $_);
		delete $links{$_};
	}

	foreach (keys %links) {
		if (/\.crt/) {
			symlink "$org/default.crt", "$lnkdest/$_" or $exception->add('err_file_symlink', $_);
		}
		elsif (/\.key/) {
			symlink "$org/default.key", "$lnkdest/$_" or $exception->add('err_file_symlink', $_);
		}
	}
	throw $exception if $exception;
	1;
}

sub create_merged_certs() {
	my $dir = Yaffas::Constant::DIR->{ssl_certs};

	opendir(DIR, $dir) or throw Yaffas::Exception('err_dir_read', $dir);
	my %files = map { s/\..*$//; $_ => 1 } grep{ /\.(crt|key)$/ } readdir(DIR);
	closedir(DIR) or throw Yaffas::Exception('err_dir_read', $dir);

	foreach my $f (keys %files) {
		system("cat $dir$f.crt $dir$f.key > $dir$f");
	}
}

sub validate_gencert($){
	my $in_hashref = shift;
	my $bke = Yaffas::Exception->new();

	$bke->add('e_service') if("" eq  $in_hashref->{'service'});
	$bke->add('e_days') unless($in_hashref->{'days'} =~ /^\d+$/);
	$bke->add('e_days') unless( _validate_days($in_hashref->{'days'}) );
	$bke->add('e_cn') if ($in_hashref->{'cn'} eq "" or (!(defined(Yaffas::Check::domainname($in_hashref->{'cn'})) or Yaffas::Check::ip($in_hashref->{'cn'}))));
	#push @errors, $main::text{'e_o'} if("" eq  $in_hashref->{'o'});
	#push @errors, $main::text{'e_ou'} if("" eq  $in_hashref->{'ou'});
	$bke->add('e_l') if("" eq  $in_hashref->{'l'});
	$bke->add('e_st') if("" eq  $in_hashref->{'st'});
	$bke->add('e_c') unless( $in_hashref->{'c'} =~ m/^[a-zA-Z]{2}$/);
	$bke->add('e_emailAddress') if($in_hashref->{'emailAddress'} ne "" and ! Yaffas::Check::email($in_hashref->{'emailAddress'}));
	$bke->add('e_o') unless $in_hashref->{'o'} =~ m/^[A-Za-z0-9. -]+$/;
	$bke->add('e_ou') unless $in_hashref->{'ou'} =~ m/^[A-Za-z0-9. -]+$/;
	throw $bke if ($bke);

	return 1;
}

sub _validate_days($){
	my $days = shift;
	my $days_in_sec = $days * 24 * 60 * 60;
	my $time = time;
	my $a = $time + $days_in_sec;
	my $b = timelocal(localtime($time+ $days_in_sec));
	return($a == $b);
}

sub list_certs(){
	my %certs;

	opendir(DIR, Yaffas::Constant::DIR->{ssl_certs_org}) or return undef;
	@certs{ grep { /.crt$/ } readdir(DIR) } = 1;
	closedir(DIR);

	foreach (keys %certs) {
		my $info = Yaffas::do_back_quote(Yaffas::Constant::APPLICATION->{openssl}, 'x509', '-in', Yaffas::Constant::DIR->{ssl_certs_org} . $_, '-noout', '-dates');
		if ($? == 0 and $info =~ m/notBefore=(.*)\nnotAfter=(.*)/) {
			$certs{$_} = [$1, $2];
		}else {
			$certs{$_} = undef;
		}
	}
	return %certs;
}

sub delete_cert($){
	my $service = shift;
	if ($service =~ /\//) {		## / im parameter, das is gefährlich..
		throw Yaffas::Exception("err_param");
	}

	my $exception = Yaffas::Exception->new();

	my $datei = Yaffas::Constant::DIR->{ssl_certs_org} . $service;
	unlink $datei or $exception->add('err_delete_file', $datei);

	# delete key
	$datei =~ s/\.crt/\.key/;
	unlink $datei or $exception->add('err_delete_file', $datei);

	update_symlinks();
	$service =~ s/\..*$//;
	restart_service($service);
	1;
 }

sub import_cert($$){
	my $upload = shift;
	my $service = shift;

	throw Yaffas::Exception("err_param") unless grep { $service eq $_} get_services();

	unless ($upload && $service) {
		throw Yaffas::Exception("err_param");
	}
	my $CRT = "$service.crt";
	my $KEY = "$service.key";
	my $TMP = "$service.tmp";
	if ($service eq "all") {
		$CRT = 'default.crt';
		$KEY = "default.key";
		$TMP = "default.tmp";
	}

	$CRT = Yaffas::Constant::DIR->{ssl_certs_org} . $CRT;
	$KEY = Yaffas::Constant::DIR->{ssl_certs_org} . $KEY;
	$TMP = Yaffas::Constant::DIR->{ssl_certs_org} . $TMP;

	open(TMP, ">", $TMP) or throw Yaffas::Exception('err_file_write', $TMP);
	print TMP $upload;
	close(TMP) or throw Yaffas::Exception('err_file_write', $TMP);

	unless (check_cert($TMP)) {
		#unlink $TMP;
		throw Yaffas::Exception("err_cert_not_valid");
	}

	unlink $CRT;
	unlink $KEY;
	rename($TMP,$CRT) or throw Yaffas::Exception('err_file_rename', $TMP);
	copy($CRT, $KEY) or throw Yaffas::Exception('err_file_copy', $_);
	unlink $TMP;

	update_symlinks();
	create_merged_certs();
	restart_service($service);

	return 1;
}

sub get_services() {
	my @services = qw(postfix webmin ldap all);
	if (check_product("zarafa")) {
		@services = grep {$_ ne "cyrus"} @services;
		push @services, "zarafa-server", "zarafa-webaccess", "zarafa-gateway", "zarafa-ical";
	}
	if (check_product("mailgate")) {
		push @services, "mppmanager";
	}
	if (check_product("fax") or check_product("pdf")) {
		push @services, "cups";
	}

	return sort @services;
}

sub check_cert($){
	my $file = shift;
	my $stat = undef;
	
	Yaffas::do_back_quote(Yaffas::Constant::APPLICATION->{openssl} , "x509", "-in" , $file);
	return undef if $?;
	
	open(FILE, '<', $file);
	my @data = <FILE>;
	close(FILE);

	foreach (@data)
	{
		$stat++ if m/^[-]+BEGIN\s+CERTIFICATE[-]+$/;
		$stat++ if m/^[-]+BEGIN\s+([^ ]+ )?PRIVATE KEY[-]+$/;
	}

	return undef unless $stat == 2;
	return 1;
}

sub restart_service($) {
	my $service = shift;
	my %services = (
					"exim"    => Yaffas::Service::EXIM(),
					"postfix"    => Yaffas::Service::POSTFIX(),
					"cyrus"   => Yaffas::Service::CYRUS(),
					"webmin"  => Yaffas::Service::WEBMIN(),
					"usermin" => Yaffas::Service::USERMIN(),
					"zarafa-webaccess" => Yaffas::Service::APACHE(),
					"zarafa-gateway" => Yaffas::Service::ZARAFA_GATEWAY(),
					"zarafa-server" => Yaffas::Service::ZARAFA_GATEWAY(),
					"zarafa-ical" => Yaffas::Service::ZARAFA_ICAL(),
					"ldap" => Yaffas::Service::LDAP(),
					"cups" => Yaffas::Service::CUPS(),
					"mppmanager" => Yaffas::Service::MPPMANAGER()
		);

	my @restart;
	if ($service eq "all") {
		push @restart, keys %services;
	} else {
		push @restart, $service if (exists $services{$service});
	}

	if (@restart) {
		foreach my $service (@restart) {
			my $pid = fork();
			throw Yaffas::Exception('err_fork') unless defined $pid;

			if ($pid) {
				# parent
				wait;
				exit 0;
				# wird webmin neu gestartet. so wird das hier gekillt, vom
				# kind. wird ein andere dienst gerestartet, so wird der
				# vater nach dem ende des kindes weiterlaufen, dies wird
				# mit exit 0 verindert. ( oder? )
			}else {
				# child
				Yaffas::Service::control($services{$service}, Yaffas::Service::RESTART());
			}
		}
		return 1;
	}
	throw Yaffas::Exception('err_param');
}

sub conf_dump {
    1;
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
