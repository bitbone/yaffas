#!/usr/bin/perl
package Yaffas::Product;

use warnings;
use strict;

sub BEGIN {
	use Exporter;
	our @ISA = qw(Exporter);
	our @EXPORT_OK = qw(&check_product
						&get_license_info
						&get_all_license_info
						&get_lincense_info_mail
						&get_lincense_info_gate
						&get_lincense_info_fax
						&get_lincense_info_pdf
						&get_longname_of
						&get_version_of
						&get_revision_of
					   );
}

use Yaffas;
use Yaffas::File::Config;
use Yaffas::Exception;
use Error qw(:try);
use File::Copy;
use File::Temp ();
use Yaffas::Constant;

## prototypes
sub get_license_info($$);
sub get_all_license_info($);
sub check_product ($);

my @products = ("fax", "mail", "pdf", "framework", "zarafa", "mailgate", "fileserver");
my @free_products = ('mail'); # Procucts which need no key

=pod

=head1 NAME

Yaffas::Product --todo--

=head1 SYNOPSIS

use Yaffas::Product

=head1 DESCRIPTION

Yaffas::Product  --todo--

=head1 FUNCTIONS

=over

=item list_all_possible_products()

This returns a list of all possible procucts.

=cut

sub list_all_possible_products(){
	return @products;
}

=item check_product (PRODUCT)

This checks if the PRODUCT is installed or not.

=cut

# returns 1 on success else 0
sub check_product ($){
	my $product = shift;

	my $conf = Yaffas::File::Config->new(
										 Yaffas::Constant::FILE->{bkversion},
										 {-SplitPolicy => 'equalsign'}
										);
	my %value = $conf->get_cfg()->getall();

	return exists $value{$product};
}


=item check_product_license (PRODUCT)

checks if the license is working for the product or not.
returns 0 if the product dosnt exist.
if you call the sub with "" or undef it returns true.

=cut

sub check_product_license($) {

	my @check_products;
	return 0 unless (defined $_[0]);

	if (ref $_[0]) {
		@check_products = @{$_[0]};
	}else {
		@check_products = @_;
	}

	if (scalar @check_products == 1 and $check_products[0] eq "") {
		return 1; # tests deaktiviert
	}

	for my $t (@check_products) {
		return 0 unless (grep {$t eq $_} @products, "all");
		# unbekannter, ungültiger wert drin.
	}

	if (grep {$_ eq "all"} @check_products) {
		@check_products  = @products;
	}

	foreach my $t (@check_products) {
		return 1 if is_free_product( $t );
		my $intime = get_license_info($t, "intime");
		if ($intime > 0) {
			return 1;
		}
	}
	return 0;
}

=item get_longname_of( PRODUCT )

get the longname of the Product

=cut

sub get_longname_of {
	my $product = shift;

	my $conf = Yaffas::File::Config->new(
										 Yaffas::Constant::FILE->{bkversion},
										 {-SplitPolicy => 'equalsign'}
										);
	my %value = $conf->get_cfg()->getall();
	my $longname = $value{$product};
	if($longname =~ m/([\S]+)/){
		return $1
	}else{
		return 0;
	}
}

=item get_version_of( PRODUCT )

returns the version number of a product.

=cut

sub get_version_of($) {
	my $product = shift;


	my $conf = Yaffas::File::Config->new(
										 Yaffas::Constant::FILE->{bkversion},
										 {-SplitPolicy => 'equalsign'}
										);
	my %value = $conf->get_cfg()->getall();
	my $version = $value{$product};

	if ($product eq "zarafa") {
		my $tmp = Yaffas::do_back_quote(Yaffas::Constant::APPLICATION->{zarafa_admin}, "-V");

		if ($tmp =~ /^Product version:\s+(\d+),(\d+),(\d+),(\d+)/) {
			return "$1.$2.$3-$4";
		}
	}

    if ($product eq "framework") {
        my $git = "-unknown";
        my $fn = Yaffas::Constant::FILE->{git_revision};
        if (-r $fn) {
            my $file = Yaffas::File->new($fn);
            $git = $file->get_content();
            $git =~ s#^heads/.*?-0##;
        }

        if (Yaffas::Constant::OS eq "Ubuntu" || Yaffas::Constant::OS eq "Debian") {
            my @tmp = Yaffas::do_back_quote(Yaffas::Constant::APPLICATION->{dpkg}, "-l", "bitkit");

            if ($? ne "0") {
                @tmp = Yaffas::do_back_quote(Yaffas::Constant::APPLICATION->{dpkg}, "-l", "yaffas-core");
            }

            foreach my $line (@tmp) {
                if ($line =~ /^ii\s+.*?\s+(\d+\.\d+\.\d+-\d+)\s+.*/) {
                    return $1.$git;
                }
            }
        }
        elsif (Yaffas::Constant::OS =~ /RHEL./) {
            my @tmp = Yaffas::do_back_quote(Yaffas::Constant::APPLICATION->{rpm}, "-qi", "yaffas-core");
            my $version;
            my $release;

            foreach my $line (@tmp) {
                if ($line =~ /^Version\s+:\s+(\d+\.\d+\.\d+).*/) {
                    $version = $1;
                }
                if ($line =~ /^Release\s+:\s+(.+?)\s+.*/) {
                    $release = $1;
                }
            }
            return $version."-".$release.$git;

        }
    }

	return $1 if $version =~ /v([.\d]+-?.*)/;
	return 0;
}

=item get_revision_of( PRODUCT )

returns the revision number of a product.

=cut

sub get_revision_of($){
	my $product = shift;
	my $rev = 0;
	$product = "base" if $product eq "framework";

	if(Yaffas::Constant::OS eq 'Ubuntu' or Yaffas::Constant::OS eq 'Debian' ) {
		foreach my $dpkg (Yaffas::do_back_quote(Yaffas::Constant::APPLICATION->{dpkg}, "-s", "bitkit-update-$product")) {
			$rev = $1 if $dpkg =~ m/^Version:\s*?.*?(\d\d\d)$/;
		}
    }
	elsif(Yaffas::Constant::OS =~ m/RHEL\d/ ) {
		my $rpm = Yaffas::do_back_quote(Yaffas::Constant::APPLICATION->{rpm}, "-q", "--qf", '%{version}', "bitkit-update-$product");
		$rev = $1 if $rpm =~ m/^\d\d\d(\d\d\d)$/;
	}

	return $rev;
}


=item get_lincese_info ( PRODUCT, QUERY )

returns license-informations for PRODUCT

=cut

sub get_license_info($$)
{
	my $product = shift;
	my $query = shift;
	my $cmd = "/usr/bin/get_license_info_$product";
	if (-x $cmd) {
		my $r = Yaffas::do_back_quote($cmd, $query);;
		chomp $r;
		return $r;
	} else {
		return undef;
	}
}

=item get_all_license_info( QUERY )

Returns license-informations for all products in a hash (product=>value).

=cut

sub get_all_license_info($) {
	my $query = shift;
	my %ret;
	foreach my $product (@products) {
		$ret{$product} = get_license_info($product, $query);
	}
	return %ret;
}

=item is_free_product( PRODUCT )

Checks if the given product is in the list of free products.

=cut

sub is_free_product( $ ){
	my $product = shift;
	
	foreach( @free_products ){
		if( $_ eq $product ){
			return 1;
		}
	}
	return 0
}

=item _setup_key (FILE, PRODUCT)

insert key in yaffas and set it up

=cut

sub _setup_key($$) {
	my $key = shift;
	my $product = shift;
	my $location = "/usr/local/lib/libkeybb" . $product . ".so.1.0";
	my $link =     "/usr/local/lib/libkeybb" . $product . ".so.1";

	# rm linkfiles
	unlink($link);

	# cp new key to location
	copy $key, $location or throw Yaffas::Exception("err_copy_failed", $key . " -> " . $location . ": ". $!);

	# make symlinks
	symlink($location, $link);

	# call ldconfig
	my $ret = `/sbin/ldconfig`;
}

=item _decrypt_key (file)

decrypted pgp key

=cut

sub _decrypt_key($) {
	my $key_file = shift;
	my $dec_key = $key_file . ".dec";
	# decrypt new key
	system("/usr/bin/gpg", '-o', $dec_key, '--decrypt', $key_file) and unlink $key_file;
	move $dec_key, $key_file;
}



sub _backup_old_key(){
	move $Yaffas::Product::current_key, $Yaffas::Product::save_file or warn('cant_mv_oldkey: ' . $Yaffas::Product::current_key . " - ". $!);
}

sub _delete_backup(){
	# rm mvedaway key
	unlink($Yaffas::Product::save_file);
	unlink($Yaffas::Product::new_key_file);
}

sub _delete_temp(){
	unlink ( $Yaffas::Product::new_key_file );
}


=item new_licnese ( FILE )

does everything that is needed for a new license file. Returns product on success.
throws Yaffas::Exception

=cut

sub new_license($){
	local $Yaffas::Product::new_key_file = shift;

	my $tmpfile = File::Temp->new(TEMPLATE => 'tempXXXXXX',
								  DIR => "/tmp/",
								  SUFFIX => ".license.bk",
								 );

	# decrypt key
    _decrypt_key($Yaffas::Product::new_key_file) or throw Yaffas::Exception("err_wrong_key");
	my $product = get_product_of_key($Yaffas::Product::new_key_file);

	throw Yaffas::Exception("err_product_not_installed") unless(check_product($product));

	local $Yaffas::Product::current_key = "/usr/local/lib/libkeybb" .  $product . ".so.1.0";
	local $Yaffas::Product::save_file = $tmpfile->filename();


	throw Yaffas::Exception('err_key_loc_invalid', $Yaffas::Product::new_key_file) unless ($Yaffas::Product::new_key_file =~ m#^(/tmp/\w+(\.\w+)?)$#);

	_backup_old_key();
	_setup_key($Yaffas::Product::new_key_file, $product); # setup the new key

	_delete_backup();
	_delete_temp();
	return $product;
}

=item get_product_of_key( FILENAME )

Returns the product name of given FILENAME to product key.
throws Yaffas::Exception

=cut

sub get_product_of_key($) {
	my $file = shift;
	
	throw Yaffas::Exception("err_objdump_not_found") unless(-x "/usr/bin/objdump");
	throw Yaffas::Exception("err_file_read", $file) unless(-r $file);

	my @output = Yaffas::do_back_quote("/usr/bin/objdump", "-p", $file);
	if ($? == 0) {
		my $product;

		foreach (@output) {
			if (/\s*SONAME\s*libkeybb(.*)\.so\.1\s*/) {
				$product = $1;
				last;
			}
		}
		return $product;
	} else {
		throw Yaffas::Exception("err_wrong_key");
	}
}

=item get_all_installed_products ()

Returns all installed product types

=cut

sub get_all_installed_products() {
	my @ret;
	foreach (@products) {
		push @ret, $_ if (check_product($_));
	}
	return @ret;
}

=back

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
