#!/usr/bin/perl

use strict;
use warnings;

use Yaffas;
use Yaffas::UI;
use Yaffas::Exception;
use Yaffas::Constant;
use Error qw(:try);

try{
	my $error = Yaffas::Exception->new();
	$error->add('err_no_lspci') unless( -x Yaffas::Constant::APPLICATION->{'lspci'} );
	$error->add('err_no_lshw') unless( -x Yaffas::Constant::APPLICATION->{'lshw'} );
	throw $error if $error;

		my $lshw = "lshw:\n";
		$lshw .= Yaffas::do_back_quote(Yaffas::Constant::APPLICATION->{'lshw'}, '-xml')
			or throw Yaffas::Exception('err_executing_lshw');

		$lshw .= "\n\nlspci:\n";
		$lshw .= Yaffas::do_back_quote(Yaffas::Constant::APPLICATION->{'lspci'}, '-n')
			or throw Yaffas::Exception('err_executing_lspci');
		
		my $length = length($lshw);
		print "Content-type: application/text\n";
		print "Content-length: $length\n";
		print "Content-Disposition: filename=hardware.txt\n\n";
		print $lshw;

}
catch Yaffas::Exception with{
	my $err = shift;
	Yaffas::init_webmin();
	header($main::text{'lbl_index_header'}, "");
	print Yaffas::UI::all_error_box($err);
	main::footer("/support/", $main::text{lbl_index_header});
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
