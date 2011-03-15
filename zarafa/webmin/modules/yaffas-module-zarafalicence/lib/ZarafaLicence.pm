package Yaffas::Module::ZarafaLicence;

use strict;
use warnings;
use Yaffas;
use Yaffas::File;
use Yaffas::Constant;
use Yaffas::Exception;
use Yaffas::Service qw(RESTART ZARAFA_LICENSED);
use Error qw(:try);
use Sort::Naturally;

our @ISA = qw(Yaffas::Module);

sub conf_dump() {
	# Nothing to save
};

sub get_licence_version() {
	my @version = Yaffas::do_back_quote(Yaffas::Constant::APPLICATION->{zarafa_admin},"-V");
	chomp(my $minor = (split(",",$version[0]))[2]);
	return int($minor);
	}

sub validate_serial($$$) {

	
	my ($key,$kind,$version) = @_;
		if($kind eq "base") {
			if($version==20 || $version==30) { return $key =~ m/[0-9A-Z]{24}/;}
		}

		if($kind eq "cal") {
			if($version==20 || $version==30) { return $key =~ m/[0-9A-Z]{16}/;}
		}
	
	return 1;
}

sub install_basekey($) {
	my $key = $_[0];
	my $filename = Yaffas::Constant::DIR->{zarafa_licence}."base";
	validate_serial("$key","base",get_licence_version) or throw Yaffas::Exception("err_wrong_lic",$filename);
	my $file = Yaffas::File->new($filename, $key) or throw Yaffas::Exception("err_file_write", $filename);

	$file->write();

	Yaffas::Service::control(ZARAFA_LICENSED(), RESTART());
}

sub get_basekey() {
	my $filename = Yaffas::Constant::DIR->{zarafa_licence}."base";
	my $file = Yaffas::File->new($filename) or throw Yaffas::Exception("err_file_read", $filename);
	return $file->get_content_singleline();
}

sub install_calkey($) {
	my $key = $_[0];
	my $dir = Yaffas::Constant::DIR->{zarafa_licence};
	opendir DIR, $dir or throw Yaffas::Exception("err_file_read", $dir);
	my @dirs = nsort grep(/^cal\d+$/, readdir DIR);
	closedir DIR;

	my $i = $#dirs <= 0 ? 1 : $#dirs;
	$i++ while (-f $dir."cal$i");

	my $filename = $dir."cal$i";
	validate_serial("$key","cal",get_licence_version) or throw Yaffas::Exception("err_wrong_lic",$filename);

	my $file = Yaffas::File->new($filename, $key) or throw Yaffas::Exception("err_file_write", $filename);
	$file->write();
	Yaffas::Service::control(ZARAFA_LICENSED(), RESTART());
}

sub get_log() {
	my $file = Yaffas::File->new("/var/log/zarafa/licensed.log");
	my @lines = $file->get_content();
	return splice @lines, -3, 3;
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
