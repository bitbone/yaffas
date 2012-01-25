#!/usr/bin/perl

package Yaffas::Module::Proxy;

use strict;
use warnings;
use Yaffas::File;
use Yaffas::Check;
use Yaffas::Exception;
use Yaffas::Product;
use Yaffas::Constant;
use Yaffas::Service qw(CLAMAV_FRESHCLAM RESTART);

our @ISA = ("Yaffas::Module");

my $apt_cpath = Yaffas::Constant::FILE->{"apt_conf"};
my $yum_cpath = Yaffas::Constant::FILE->{"yum_conf"};
my $wget_cpath = Yaffas::Constant::FILE->{"wget_conf"};
my $kav_cpath = Yaffas::Constant::FILE->{"kav_conf"};
my $freshclam_cpath = Yaffas::Constant::FILE->{"freshclam_conf"};

=over

=item get_proxy

get_proxy opens the apt.conf file and reads the proxy configuration.
it returns a array containting the username, password, proxy ip/domain, port.
if no proxy is configured it returns "" for every element.

On a RHEL machine it works with the yum.conf, of course.

=cut

sub get_proxy {
	my ($user, $proxy, $port);

	if(Yaffas::Constant::OS eq "Ubuntu"){
		my $bkf = Yaffas::File->new($apt_cpath) or throw Yaffas::Exception("err_file_read", $apt_cpath);
		my $line_nr = $bkf->search_line("Acquire::http::Proxy");
		if (defined $line_nr) {
			my $line = $bkf->get_content($line_nr);
			if ($line =~ m|"http://(.*)";| ){
				my $interesting_part = $1;
				my ($usr_pass, $url_port) = split /@/, $interesting_part;
				unless ($url_port) {
					$url_port = $usr_pass;
					$usr_pass = ":";
				}

				my ($url, $port) = split /:/, $url_port;
				$port =~ s/[^\d]//g;
				my ($usr, $pass) = split /:/, $usr_pass;
				return ($usr, $pass, $url, $port);
			}

		}
	} else {
		my $pass = "";
		open (FILE, '<', $yum_cpath) || throw Yaffas::Exception("err_file_read", $yum_cpath);
		while(<FILE>){
			chomp;
			if(m#^proxy\s?=\s?http://(.+)\z#ix){
				my $what = $1;
				($proxy, $port) = split(":", $what, 2);
				$port =~ s/[^\d]//g;
			}
			elsif(m#^proxy_username\s?=\s?(.*)\z#ix){
				$user = $1;
			}
			elsif(m#^proxy_password\s?=\s?(.*)\z#ix){
				$pass = $1
			}
		}
		close(FILE);

		return ($user, $pass, $proxy, $port);
	}

	return ("", "", "", "");
}

=item set_proxy ( PROXYIP / PROXYDOMAIN, PORT, USER, PASS )

set_proxy sets the Proxy Configuration in the apt configuration, wget configuration.
if set_proxy is used on a yaffas/MAIL or yaffas/GATE it also sets the proxy for kav.

throws exception on error.

=cut


sub set_proxy($$$$){
	my $proxy = shift;
	my $port = shift;
	my $user = shift;
	my $pass = shift;

	my $exception = Yaffas::Exception->new();

	if (defined($proxy) and $proxy and defined($port)) {
		# addmode

		$exception->add('err_proxy') unless (
										 Yaffas::Check::domainname($proxy) or
										 Yaffas::Check::ip($proxy)
										);
		$exception->add('err_port') unless (Yaffas::Check::port($port));
		$exception->add('err_username') if ($user and !Yaffas::Check::pathetic_username($user));
		$exception->add('err_password') if ($pass and !Yaffas::Check::password($pass));

		throw $exception if $exception;

		my $entry = $proxy;
		$entry = $entry . ":" . $port;
		$entry = $user  . ":" . $pass . "@" .  $entry if ($pass and $user);
		$entry = $user  . "@" . $entry if ($user and !$pass);

		if(Yaffas::Constant::OS eq "Ubuntu"){
			_set_apt($entry);
		} else {
			_set_yum($proxy, $port, $user, $pass);
		}
		_set_wget($entry);
		_set_freshclam($proxy,$port,$user,$pass);

		# muss funktionieren bei einem MAIL, GATE und MAILFAX.
		if (Yaffas::Product::check_product("mailgate")) {
			_set_kav($entry);
		}

	} else {
		# delmode
		_del_freshclam();
		if(Yaffas::Constant::OS eq "Ubuntu"){
			_del_apt();
		} else {
			_del_yum();
		}
		_del_wget();
		if (Yaffas::Product::check_product("mailgate")) {
			_del_kav();
		}
	}
	1;
}

# sets the apc configuration
sub _set_apt($) {
	my $entry = "Acquire::http::Proxy \"http://" . shift() . "\";";
	my $bkf = Yaffas::File->new($apt_cpath) or throw Yaffas::Exception("err_file_read", $apt_cpath);
	my $line_nr = $bkf->search_line("Acquire::http::Proxy");

	if (defined $line_nr) { # replace
		$bkf->splice_line($line_nr, 1, $entry);
	} else { # add
		$bkf->add_line($entry);
	}

	$bkf->write() or throw Yaffas::Exception('err_set_apt');
}

sub _set_yum($$$$){
	my ($host, $port, $user, $pass) = @_;
	my %conf = (
		proxy => "http://$host:$port",
		proxy_username => $user,
		proxy_password => $pass
	);

	my $bkf = Yaffas::File->new($yum_cpath) or throw Yaffas::Exception("err_file_read", $yum_cpath);

	while(my ($k, $v) = each %conf){
		my $num = $bkf->search_line(qr/^$k\s*=/);

		if(defined $num){
			$bkf->splice_line($num, 1, "$k=$v");
		} else {
			$bkf->add_line("$k=$v");
		}
	}

	$bkf->write() or throw Yaffas::Exception('err_set_yum');
}

#delete the apt configuration
sub _del_apt() {
	my $bkf = Yaffas::File->new($apt_cpath) or throw Yaffas::Exception("err_file_read", $apt_cpath);;
	my $line_nr = $bkf->search_line("Acquire::http::Proxy");

	if (defined $line_nr) { # replace
		$bkf->splice_line($line_nr, 1);
		$bkf->write() or throw Yaffas::Exception('err_del_apt');
	}
}

sub _del_yum(){ 
	my $bkf = Yaffas::File->new($yum_cpath) or throw Yaffas::Exception("err_file_read", $yum_cpath);

	foreach my $i (qw/proxy proxy_username proxy_password/){
		my $num = $bkf->search_line(qr/^$i/);
		$bkf->splice_line($num, 1) if $num;
	}

	$bkf->write() or throw Yaffas::Exception('err_del_yum');
}

# set the wget configuration
sub _set_wget($) {
	my $entry = "http://" . shift();
	my $bkf = Yaffas::File->new($wget_cpath) or throw Yaffas::Exception("err_file_read", $wget_cpath);

	my @proxy_type = qw(http_proxy ftp_proxy);
	for my $i (@proxy_type) {
		my $ln = $bkf->search_line($i);
		if (defined $ln) {
			# change
			$bkf->splice_line($ln , 1, $i . " = " . $entry);
		} else {
			# append
			$bkf->splice_line(-1  , 0, $i . " = " . $entry);
		}
	}
	$bkf->write() or throw Yaffas::Exception('err_set_wget');
}

# deletes the wget configuration
sub _del_wget() {
	my $bkf = Yaffas::File->new($wget_cpath) or throw Yaffas::Exception("err_file_read", $wget_cpath);

	my @proxy_type =  qw(http_proxy ftp_proxy);
	for my $i (@proxy_type) {
		my $ln = $bkf->search_line($i);
		if (defined $ln) { # del
			$bkf->splice_line($ln , 1);
		}
	}
	$bkf->write() or throw Yaffas::Exception('err_del_wget');
}

# sets the kav configuration
sub _set_kav($){
	my $entry = shift;
	my $bkf = Yaffas::File->new($kav_cpath) or throw Yaffas::Exception("err_file_read", $kav_cpath);
	my $ln = $bkf->search_line(qr(^ProxyAddress));
	if (defined $ln) {
		$bkf->splice_line($ln, 2, "ProxyAddress=" . $entry, "UseProxy=yes");
		$bkf->write() or throw Yaffas::Exception('err_set_kav');
		return 1;
	}
	# do nothing if no line was found
}

# deletes the kav configuration
sub _del_kav() {
	my $bkf = Yaffas::File->new($kav_cpath) or throw Yaffas::Exception("err_file_read", $kav_cpath);
	my $ln = $bkf->search_line(qr(^ProxyAddress));
	if ($ln) {
		$bkf->splice_line($ln, 2, "ProxyAddress=127.0.0.1", "UseProxy=no");
		$bkf->write() or throw Yaffas::Exception('err_del_kav');
		return 1;
	}
	# do nothing if no line was found
}

# sets the freshclam configuration
sub _set_freshclam($$;$$) {
	my %params;
	$params{'HTTPProxyServer'} = shift;
	$params{'HTTPProxyPort'} = shift;
	$params{'HTTPProxyUsername'} = shift;
	$params{'HTTPProxyPassword'} = shift;
	my $bkf = Yaffas::File->new($freshclam_cpath) or throw Yaffas::Exception("err_file_read", $freshclam_cpath);
	foreach my $key (keys %params) {
		my $ln = $bkf->search_line(qr(^$key));
		if (defined $ln) {
			#param was deleted, e.g. password
			if ($params{$key} eq "") {
				$bkf->splice_line($ln, 1);
			}
			else {
				$bkf->splice_line($ln, 1, "$key $params{$key}");
			}
		} elsif ($params{$key} ne "") {
			$bkf->add_line("$key $params{$key}");
		}
	}
	if(Yaffas::Constant::OS eq "Ubuntu"){
		$bkf->set_permissions("clamav","clamav",0600);
	} elsif (Yaffas::Constant::OS =~ m/RHEL\d/ ) {
		$bkf->set_permissions("clam","clam",0600);
	}
	
	$bkf->write() or throw Yaffas::Exception('err_set_freshclam');

	if(Yaffas::Constant::OS eq "Ubuntu"){
		Yaffas::Service::control(CLAMAV_FRESHCLAM, RESTART);
	}
}

# deletes the freshclam configuration
sub _del_freshclam() {
	my $bkf = Yaffas::File->new($freshclam_cpath) or throw Yaffas::Exception("err_file_read", $freshclam_cpath);
	my @vals =  qw(HTTPProxyUsername HTTPProxyPassword HTTPProxyServer HTTPProxyPort);
	for my $i (@vals) {
		my $ln = $bkf->search_line($i);
		if (defined $ln) { # del
			$bkf->splice_line($ln , 1);
		}
	}
	$bkf->write() or throw Yaffas::Exception('err_del_freshclam');
}

# makes Yaffas::Module happy ;-)
sub conf_dump() {

}

=back

=cut

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
