#!/usr/bin/perl

use strict;
use warnings;

use Yaffas;
use Yaffas::Module::ZarafaBackup::Store;
use Sort::Naturally;
use JSON;
use Data::Dumper;
use URI::Escape;
use File::Temp qw(tempfile);
use Error qw(:try);
use Yaffas::Exception;

Yaffas::init_webmin();
ReadParse();
header();

my $days_full = [ split /\0/, $main::in{days_full} ];
my $days_diff = [ split /\0/, $main::in{days_diff} ];
my $hour_full = $main::in{hour_full};
my $min_full = $main::in{min_full};
my $hour_diff = $main::in{hour_diff};
my $min_diff = $main::in{min_diff};

try {
Yaffas::Module::ZarafaBackup::settings({
        "full" => {
            days => $days_full,
            hour => $hour_full,
            min => $min_full,
        },
        "diff" => {
            days => $days_diff,
            hour => $hour_diff,
            min => $min_diff,
        },
        "global" => {
            "backup_dir" => $main::in{backup_dir}
        },
    });
} catch Yaffas::Exception with {
    print Yaffas::UI::all_error_box(shift);
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

