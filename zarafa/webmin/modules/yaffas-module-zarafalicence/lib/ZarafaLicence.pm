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

		if($kind eq "archiver") {
			return $key =~ m/A[0-9A-Z]{24}/;
		}

		if($kind eq "acal") {
			return $key =~ m/A[0-9A-Z]{16}/;
		}
	return 1;
}

sub install($) {
    my $key = shift;

    $key = uc $key;

    if ($key =~ /^Z.{24}$/) {
        install_basekey($key);
    }
    elsif ($key =~ /^A.{24}$/) {
        install_archiverkey($key);
    }
    elsif ($key =~ /^Z.{16}$/) {
        install_calkey($key);
    }
    elsif ($key =~ /^A.{16}$/) {
        install_acalkey($key);
    }
    else {
        throw Yaffas::Exception("err_wrong_lic", $key);
    }
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

sub install_archiverkey($) {
	my $key = $_[0];
	my $filename = Yaffas::Constant::DIR->{zarafa_licence}."archiver";
	validate_serial("$key","archiver",get_licence_version) or throw Yaffas::Exception("err_wrong_lic",$filename);
	my $file = Yaffas::File->new($filename, $key) or throw Yaffas::Exception("err_file_write", $filename);
	$file->write();

	Yaffas::Service::control(ZARAFA_LICENSED(), RESTART());
}

sub get_archiverkey {
	my $filename = Yaffas::Constant::DIR->{zarafa_licence}."archiver";
	my $file = Yaffas::File->new($filename) or throw Yaffas::Exception("err_file_read", $filename);
	return $file->get_content_singleline();
}

sub install_acalkey($) {
	my $key = $_[0];
	my $dir = Yaffas::Constant::DIR->{zarafa_licence};
	opendir DIR, $dir or throw Yaffas::Exception("err_file_read", $dir);
	my @dirs = nsort grep(/^acal\d+$/, readdir DIR);
	closedir DIR;

	my $i = $#dirs <= 0 ? 1 : $#dirs;
	$i++ while (-f $dir."acal$i");

	my $filename = $dir."acal$i";
	validate_serial("$key","acal",get_licence_version) or throw Yaffas::Exception("err_wrong_lic",$filename);

	my $file = Yaffas::File->new($filename, $key) or throw Yaffas::Exception("err_file_write", $filename);
	$file->write();
	Yaffas::Service::control(ZARAFA_LICENSED(), RESTART());
}

sub get_log() {
	my $file = Yaffas::File->new("/var/log/zarafa/licensed.log");
	my @lines = $file->get_content();
	return splice @lines, -3, 3;
}

sub get_user_count {
    my @usercount = Yaffas::do_back_quote(Yaffas::Constant::APPLICATION->{zarafa_admin}, "--user-count");
    shift @usercount;
    shift @usercount;
    shift @usercount;

    my @ret;
    my $i = 0;

    foreach my $line (@usercount) {
        my @values = split /\t/, $line;

        if ($line =~ /Active/) {
            push @ret, [$i++, "Active", $values[3], $values[4], $values[5]];
        }
        if ($line =~ /Non-active/) {
            push @ret, [$i++, "Non-Active", $values[2], $values[3], $values[4]];
        }
        if ($line =~ /Users/) {
            push @ret, [$i++, "&nbsp;&nbsp;"."Users", "", $values[4], ""];
        }
        if ($line =~ /Rooms/) {
            push @ret, [$i++, "&nbsp;&nbsp;Rooms", "", $values[4], ""];
        }
        if ($line =~ /Equipment/) {
            push @ret, [$i++, "&nbsp;&nbsp;Equipment", "", $values[3], ""];
        }
        if ($line =~ /Total/) {
            push @ret, [$i++, "Total", "", $values[4], ""];
        }
    }
    return \@ret;

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
