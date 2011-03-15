#!/usr/bin/perl -w

use strict;
use warnings;

use Yaffas;
use Yaffas::UI;
use Yaffas::Module::Backup;
use Data::Dumper;
use Error qw(:try);
use Yaffas::Exception;

Yaffas::init_webmin();

ReadParse();

try {
	Yaffas::Module::Backup::create_config(1);
	my $backup = Yaffas::Module::Backup->new();
	my $content = $backup->dump();

	print "Content-type: application/octet-stream\n";
	print "Content-length: ".(length $content)."\n";
	print "Content-Disposition: attachment; filename=\"yaffas.xml\"";
	print "\n\n";

	print $content;
}
catch Yaffas::Exception with {
	header();
	print Yaffas::UI::all_error_box(shift);
	print Yaffas::UI::yn_confirm(
		{
			-action => "index.cgi",
			-hidden => [ download => 1 ],
			-title  => $main::text{lbl_errors},
			-yes    => $main::text{yes},
			-no     => $main::text{'no'},
		},
		$main::text{lbl_errors_question}
	);
	footer( "", $main::text{'lbl_dump'} );
};
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
