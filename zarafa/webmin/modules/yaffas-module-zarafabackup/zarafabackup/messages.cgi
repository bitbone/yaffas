#!/usr/bin/perl

use strict;
use warnings;

use Yaffas;
use Yaffas::Module::ZarafaBackup::Store;
use Sort::Naturally;
use JSON;

Yaffas::init_webmin();
Yaffas::json_header();
ReadParse();

my $day = $main::in{day};
my $folder = $main::in{id};
my $user = $main::in{user};
my $backup = $main::in{backup};
my $results = $main::in{results};
my $start = $main::in{startIndex};
my $sort = $main::in{sort} || "date";
my $dir = $main::in{dir};

my $s = Yaffas::Module::ZarafaBackup::Store->new($day, $user);

my @folders = sort { $dir eq "desc" ? ncmp($a->{$sort}, $b->{$sort}) : ncmp($b->{$sort}, $a->{$sort}) } @{$s->getElements($folder)};

my $size = scalar @folders;

my $end = $start+$results-1;
$end = $size - 1 if ($end > $size);

my @f = @folders[$start..$end];

print to_json({"Response" => \@f, "totalRecords" => $size, startIndex => $start, pageSize => $results, "sort" => "sender", dir => "asc", "recordsReturned" => scalar @f  });

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

