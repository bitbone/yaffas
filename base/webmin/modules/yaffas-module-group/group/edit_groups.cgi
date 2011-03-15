#!/usr/bin/perl -w
use warnings;
use strict;
use Yaffas;
use Yaffas::UI;
use Yaffas::Check;
use Yaffas::Module::Group;
use Error qw(:try);
use Yaffas::Exception;
use Yaffas::Auth;
use Yaffas::Auth::Type;
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
require "./forms.pl";

Yaffas::init_webmin();
header($main::text{'check_editgroup_header'}, "");
ReadParse();

my $mode = $main::in{showform};
my @groups = split /\0/, $main::in{"groups"};
my @filetypes = split /\0/, $main::in{filetype};

try {
	if (defined $mode) {
		show_edit_groups( \@groups );
	}
	else {
	    Yaffas::Module::Group::set_groups_filetype(@groups, @filetypes);
	    print Yaffas::UI::ok_box();
	}
} catch Yaffas::Exception with {
    my $exception = shift;
    print Yaffas::UI::all_error_box($exception);
};

footer();
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
