#!/usr/bin/perl -w

use strict;
use warnings;

use Yaffas;
use Yaffas::UI;
use Yaffas::Module::Backup;
use Data::Dumper;
use Error qw(:try);
use Yaffas::Exception;
use Yaffas::Fax;

require './forms.pl';

Yaffas::init_webmin();
ReadParseMime();

# we have recived a yaffas config file.
header();

# all installed products have a correct licence key?!
unless ( $main::in{'backup'} ) {
	print error_box( $main::text{'err_conf_file'} );
	index_dlg();
	footer();
	exit;
}

my $backup = Yaffas::Module::Backup->new();

if ( !$backup->write_config( $main::in{'backup'} ) ) {
	print error_box( $main::text{'err_conf_file'} );
}

if (   Yaffas::Product::check_product("fax")
	&& Yaffas::Module::Backup::check_faxtype() ne Yaffas::Check::faxtype )
{
	print Yaffas::UI::error_box( $main::text{'err_faxtype'} );
	footer();
	exit;
}

## test if the version and file is okee...
#my $status = $backup->check_installed_products();
#if ( $status eq "notconf" ) {
#	print error_box( $main::text{'err_conf_file'} );
#}
#elsif ( !$status ) {
#	## if not, print a waring
#	#### if user accepts, go ahead
#	#### if user dont ac, abort!
#
#	print Yaffas::UI::yn_confirm(
#		{
#			-action => "index.cgi",
#			-hidden => [ force => 1 ],
#			-title  => $main::text{lbl_wrong_version},
#			-yes    => $main::text{yes},
#			-no     => $main::text{'no'},
#		},
#		$main::text{lbl_wrong_version_question}
#	);
#}
#else {
#	## if yes, go ahead
#}
go_ahead($backup);

footer();

sub go_ahead {
	my $backup = shift;

	try {
		$backup->restore();
		Yaffas::Fax::remove_NeedToTakeover_flag();
		print Yaffas::UI::ok_box()
	} catch Yaffas::Exception with {
		my $e = shift;
		print Yaffas::UI::all_error_box($e);
		print Yaffas::UI::section("Error detail", $Cgi->pre(Dumper $backup));;
	};
}

=pod

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
