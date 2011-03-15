#!/usr/bin/perl
# index.cgi
use strict;
use warnings;
use Yaffas;
use Yaffas::UI;
use Yaffas::Module::Logfiles;

require './forms.pl';

Yaffas::init_webmin();
ReadParse();

if ($main::in{file}) {
	my $file = $main::in{file};
	my $name = (split(/\//, $file))[-1];
	my @files = (Yaffas::Module::Logfiles::get_filenames(), Yaffas::Module::Logfiles::get_old_filenames());
	if (not defined $file) {
		# no files selected
		header();
		print Yaffas::UI::error_box($main::text{err_nothing_selected});
		footer();
	} elsif(grep {$file eq $_} @files ) {
		# file download permitted
		Yaffas::UI::download_to_client($file, $name);
	} else {
		# file download not permitted
		header();
		print Yaffas::UI::error_box($main::text{err_not_permitted});
		footer();
	}
} else {
	header();
	if ($main::in{show_old_logs}) {
		download_form(1);
	} else {
		download_form(0);
	}
	footer();
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
